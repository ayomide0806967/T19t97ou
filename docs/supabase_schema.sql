-- Minimal Supabase schema for this app (auth + profiles + posts).
-- Assumes you're using Supabase Auth and want `auth.users.id` (UUID) as the
-- canonical user id everywhere.

-- Profiles (public user data)
create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  handle text unique not null,
  full_name text,
  bio text,
  avatar_url text,
  header_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

-- Auto-create profile on sign up
create or replace function public.handle_from_email(email text)
returns text language sql immutable as $$
select '@' || lower(regexp_replace(split_part(email, '@', 1), '[^a-zA-Z0-9_]', '', 'g'));
$$;

create or replace function public.create_profile_for_new_user()
returns trigger language plpgsql security definer as $$
declare
  base_handle text;
  candidate text;
  suffix int := 0;
begin
  base_handle := public.handle_from_email(new.email);
  candidate := base_handle;

  while exists (select 1 from public.profiles p where lower(p.handle) = lower(candidate)) loop
    suffix := suffix + 1;
    candidate := base_handle || suffix::text;
  end loop;

  insert into public.profiles (user_id, handle, full_name)
  values (new.id, candidate, coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)));
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.create_profile_for_new_user();

-- Posts (feed items)
create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(user_id) on delete cascade,
  body text not null,
  tags text[] not null default '{}'::text[],
  media_paths text[] not null default '{}'::text[],
  created_at timestamptz not null default now()
);

create index if not exists posts_author_id_created_at_idx
on public.posts (author_id, created_at desc);

-- Reposts
create table if not exists public.post_reposts (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (post_id, user_id)
);

-- A simple feed view the app expects when SUPABASE_FEED=true
create or replace view public.feed_posts as
select
  p.id::text as id,
  pr.full_name as author,
  pr.handle as handle,
  p.body as body,
  p.tags as tags,
  p.media_paths as media_paths,
  p.created_at as created_at,
  0::int as replies,
  (select count(*) from public.post_reposts r where r.post_id = p.id)::int as reposts,
  0::int as likes,
  0::int as views,
  0::int as bookmarks,
  null::text as reposted_by,
  null::text as original_id
from public.posts p
join public.profiles pr on pr.user_id = p.author_id;

-- RLS policies
alter table public.profiles enable row level security;
alter table public.posts enable row level security;
alter table public.post_reposts enable row level security;

drop policy if exists "profiles_select_public" on public.profiles;
create policy "profiles_select_public"
on public.profiles for select
to authenticated, anon
using (true);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "posts_select_public" on public.posts;
create policy "posts_select_public"
on public.posts for select
to authenticated, anon
using (true);

drop policy if exists "posts_insert_own" on public.posts;
create policy "posts_insert_own"
on public.posts for insert
to authenticated
with check (auth.uid() = author_id);

drop policy if exists "posts_update_own" on public.posts;
create policy "posts_update_own"
on public.posts for update
to authenticated
using (auth.uid() = author_id)
with check (auth.uid() = author_id);

drop policy if exists "posts_delete_own" on public.posts;
create policy "posts_delete_own"
on public.posts for delete
to authenticated
using (auth.uid() = author_id);

drop policy if exists "reposts_select_public" on public.post_reposts;
create policy "reposts_select_public"
on public.post_reposts for select
to authenticated, anon
using (true);

drop policy if exists "reposts_insert_own" on public.post_reposts;
create policy "reposts_insert_own"
on public.post_reposts for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "reposts_delete_own" on public.post_reposts;
create policy "reposts_delete_own"
on public.post_reposts for delete
to authenticated
using (auth.uid() = user_id);


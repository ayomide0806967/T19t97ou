-- Minimal Supabase schema for this app (auth + profiles + posts).
-- Assumes you're using Supabase Auth and want `auth.users.id` (UUID) as the
-- canonical user id everywhere.

-- Profiles (public user data)
create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  handle text unique not null,
  full_name text,
  bio text,
  profession text,
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
  quote_id uuid references public.posts(id) on delete set null,
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
  p.quote_id::text as original_id
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

-- =============================================================================
-- QUIZ SYSTEM
-- =============================================================================
create table if not exists public.quiz_drafts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid references auth.users(id) on delete cascade,
  title text not null,
  question_count int default 0,
  is_timed boolean default false,
  timer_minutes int,
  closing_date timestamptz,
  require_pin boolean default false,
  pin text,
  visibility text default 'public',
  restricted_audience text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.quiz_results (
  id uuid primary key default gen_random_uuid(),
  author_id uuid references auth.users(id) on delete cascade,
  title text not null,
  responses int default 0,
  average_score decimal default 0,
  completion_rate decimal default 0,
  last_updated timestamptz not null default now()
);

create table if not exists public.quiz_questions (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid references public.quiz_results(id) on delete cascade,
  order_index int not null,
  prompt text not null,
  options text[] not null,
  answer_index int not null
);

alter table public.quiz_drafts enable row level security;
alter table public.quiz_results enable row level security;
alter table public.quiz_questions enable row level security;

create policy "quiz_drafts_select" on public.quiz_drafts for select using (auth.uid() = author_id);
create policy "quiz_drafts_insert" on public.quiz_drafts for insert with check (auth.uid() = author_id);
create policy "quiz_drafts_update" on public.quiz_drafts for update using (auth.uid() = author_id);
create policy "quiz_drafts_delete" on public.quiz_drafts for delete using (auth.uid() = author_id);

create policy "quiz_results_select" on public.quiz_results for select using (auth.uid() = author_id);
create policy "quiz_results_insert" on public.quiz_results for insert with check (auth.uid() = author_id);
create policy "quiz_results_update" on public.quiz_results for update using (auth.uid() = author_id);
create policy "quiz_results_delete" on public.quiz_results for delete using (auth.uid() = author_id);

create policy "quiz_questions_select" on public.quiz_questions for select using (true);
create policy "quiz_questions_insert" on public.quiz_questions for insert with check (true);
create policy "quiz_questions_delete" on public.quiz_questions for delete using (true);

-- =============================================================================
-- CLASSES SYSTEM
-- =============================================================================
create table if not exists public.classes (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  name text not null,
  facilitator text,
  delivery_mode text default 'online',
  upcoming_exam text,
  member_count int default 0,
  member_handles text[] default '{}'::text[],
  resources jsonb default '[]'::jsonb,
  lecture_notes jsonb default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.class_invites (
  id uuid primary key default gen_random_uuid(),
  class_code text not null,
  invite_code text unique not null,
  created_at timestamptz not null default now()
);

create table if not exists public.class_memberships (
  id uuid primary key default gen_random_uuid(),
  class_code text not null,
  user_handle text not null,
  joined_at timestamptz not null default now(),
  unique(class_code, user_handle)
);

create table if not exists public.class_roles (
  id uuid primary key default gen_random_uuid(),
  class_code text not null,
  user_handle text not null,
  role text not null default 'member',
  created_at timestamptz not null default now(),
  unique(class_code, user_handle, role)
);

alter table public.classes enable row level security;
alter table public.class_invites enable row level security;
alter table public.class_memberships enable row level security;
alter table public.class_roles enable row level security;

create policy "classes_select" on public.classes for select using (true);
create policy "classes_insert" on public.classes for insert with check (auth.uid() is not null);
create policy "classes_update" on public.classes for update using (auth.uid() is not null);

create policy "class_invites_select" on public.class_invites for select using (true);
create policy "class_invites_insert" on public.class_invites for insert with check (auth.uid() is not null);

create policy "class_memberships_all" on public.class_memberships for all using (auth.uid() is not null);

create policy "class_roles_all" on public.class_roles for all using (auth.uid() is not null);

-- =============================================================================
-- INDEXES
-- =============================================================================
create index if not exists idx_quiz_drafts_author on public.quiz_drafts(author_id);
create index if not exists idx_quiz_results_author on public.quiz_results(author_id);
create index if not exists idx_classes_code on public.classes(code);
create index if not exists idx_class_memberships_class on public.class_memberships(class_code);

-- =============================================================================
-- STORAGE BUCKET (run in Supabase Dashboard > Storage > New Bucket)
-- Name: avatars, Public: true
-- =============================================================================

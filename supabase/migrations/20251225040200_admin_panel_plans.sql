-- ============================================================================
-- Admin panel: roles, audit logs, plans, subscriptions, limits, verification.
-- ============================================================================

create extension if not exists pgcrypto;

-- Admin users and permissions.
create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('support', 'moderator', 'super_admin')),
  is_active boolean not null default true,
  dm_access_enabled boolean not null default false,
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id)
);

create index if not exists admin_users_role_idx on public.admin_users (role);

-- Admin audit logs.
create table if not exists public.admin_audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid references auth.users(id),
  actor_role text,
  action text not null,
  target_type text,
  target_id text,
  before_json jsonb,
  after_json jsonb,
  ip text,
  user_agent text,
  created_at timestamptz not null default now()
);

create index if not exists admin_audit_logs_created_at_idx
on public.admin_audit_logs (created_at desc);

-- Admin settings store (algorithm controls, feature flags).
create table if not exists public.admin_settings (
  key text primary key,
  value jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id)
);

-- Subscription plans (admin-managed).
create table if not exists public.plans (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  name text not null,
  description text,
  limits jsonb not null default '{}'::jsonb,
  features jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- Active subscription per user (manual first; store providers later).
create table if not exists public.user_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  plan_id uuid not null references public.plans(id),
  provider text not null default 'manual',
  provider_ref text,
  status text not null default 'active' check (status in ('active','inactive','canceled','expired')),
  starts_at timestamptz not null default now(),
  ends_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz
);

create unique index if not exists user_subscriptions_one_active_idx
on public.user_subscriptions (user_id)
where status = 'active';

create index if not exists user_subscriptions_user_status_idx
on public.user_subscriptions (user_id, status);

-- Permanent per-user overrides (super admin exceptions).
create table if not exists public.user_overrides (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  limits jsonb not null default '{}'::jsonb,
  features jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id)
);

-- Checkmark / verification fields.
alter table public.profiles
  add column if not exists verified_type text not null default 'none' check (verified_type in ('none','verified','institution','creator')),
  add column if not exists verified_at timestamptz,
  add column if not exists verified_by uuid references auth.users(id);

-- Default free plan (admin can edit later).
insert into public.plans (code, name, description, limits, features, is_active)
values (
  'free',
  'Free',
  'Default free tier',
  jsonb_build_object(
    'max_active_classes', 2,
    'max_members_per_class', 30,
    'max_quiz_participants', 10,
    'max_active_published_quizzes', 10
  ),
  jsonb_build_object(
    'checkmark_eligible', false
  ),
  true
)
on conflict (code) do nothing;

-- ============================================================================
-- Security: enable RLS and add minimal policies.
-- ============================================================================

alter table public.admin_users enable row level security;
alter table public.admin_audit_logs enable row level security;
alter table public.admin_settings enable row level security;
alter table public.plans enable row level security;
alter table public.user_subscriptions enable row level security;
alter table public.user_overrides enable row level security;

-- An admin can see their own admin row (used to gate UI).
drop policy if exists "admin_users_select_self" on public.admin_users;
create policy "admin_users_select_self"
on public.admin_users for select
to authenticated
using (user_id = auth.uid());

-- Plans are readable by everyone (useful for UI).
drop policy if exists "plans_select_public" on public.plans;
create policy "plans_select_public"
on public.plans for select
to authenticated, anon
using (true);

-- Users can view their own subscription record.
drop policy if exists "user_subscriptions_select_own" on public.user_subscriptions;
create policy "user_subscriptions_select_own"
on public.user_subscriptions for select
to authenticated
using (user_id = auth.uid());

-- Users can view their own overrides (optional; keep for debugging).
drop policy if exists "user_overrides_select_own" on public.user_overrides;
create policy "user_overrides_select_own"
on public.user_overrides for select
to authenticated
using (user_id = auth.uid());

-- No direct client access to admin_settings / admin_audit_logs (server uses service role).

-- ============================================================================
-- Effective limits/features helpers (plan defaults + overrides).
-- ============================================================================

create or replace function public.get_effective_limits(p_user_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_plan_id uuid;
  v_plan_limits jsonb;
  v_override jsonb;
begin
  select us.plan_id into v_plan_id
  from public.user_subscriptions us
  where us.user_id = p_user_id and us.status = 'active'
  order by us.created_at desc
  limit 1;

  if v_plan_id is null then
    select p.id into v_plan_id from public.plans p where p.code = 'free' limit 1;
  end if;

  select p.limits into v_plan_limits from public.plans p where p.id = v_plan_id;
  select uo.limits into v_override from public.user_overrides uo where uo.user_id = p_user_id;

  return coalesce(v_plan_limits, '{}'::jsonb) || coalesce(v_override, '{}'::jsonb);
end;
$$;

create or replace function public.get_effective_features(p_user_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_plan_id uuid;
  v_plan_features jsonb;
  v_override jsonb;
begin
  select us.plan_id into v_plan_id
  from public.user_subscriptions us
  where us.user_id = p_user_id and us.status = 'active'
  order by us.created_at desc
  limit 1;

  if v_plan_id is null then
    select p.id into v_plan_id from public.plans p where p.code = 'free' limit 1;
  end if;

  select p.features into v_plan_features from public.plans p where p.id = v_plan_id;
  select uo.features into v_override from public.user_overrides uo where uo.user_id = p_user_id;

  return coalesce(v_plan_features, '{}'::jsonb) || coalesce(v_override, '{}'::jsonb);
end;
$$;

-- ============================================================================
-- Enforcement triggers (best-practice: server-side limits enforcement).
-- ============================================================================

create or replace function public.enforce_class_create_limit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_limits jsonb;
  v_max int;
  v_active_count int;
begin
  v_limits := public.get_effective_limits(new.facilitator_id);
  v_max := nullif(v_limits->>'max_active_classes', '')::int;
  if v_max is null then
    return new;
  end if;

  select count(*)::int into v_active_count
  from public.classes c
  where c.facilitator_id = new.facilitator_id
    and c.archived_at is null;

  if v_active_count >= v_max then
    raise exception 'Class limit reached for this plan';
  end if;

  return new;
end;
$$;

drop trigger if exists on_classes_enforce_limit on public.classes;
create trigger on_classes_enforce_limit
before insert on public.classes
for each row execute function public.enforce_class_create_limit();

create or replace function public.enforce_class_member_limit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_owner_id uuid;
  v_limits jsonb;
  v_max int;
  v_member_count int;
begin
  select c.facilitator_id into v_owner_id from public.classes c where c.id = new.class_id;
  if v_owner_id is null then
    return new;
  end if;

  v_limits := public.get_effective_limits(v_owner_id);
  v_max := nullif(v_limits->>'max_members_per_class', '')::int;
  if v_max is null then
    return new;
  end if;

  select count(*)::int into v_member_count
  from public.class_members cm
  where cm.class_id = new.class_id;

  if v_member_count >= v_max then
    raise exception 'Class member limit reached for this plan';
  end if;

  return new;
end;
$$;

drop trigger if exists on_class_members_enforce_limit on public.class_members;
create trigger on_class_members_enforce_limit
before insert on public.class_members
for each row execute function public.enforce_class_member_limit();

create or replace function public.enforce_quiz_publish_limit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_limits jsonb;
  v_max int;
  v_active_count int;
begin
  if new.status = 'published' and coalesce(old.status, '') <> 'published' then
    v_limits := public.get_effective_limits(new.author_id);
    v_max := nullif(v_limits->>'max_active_published_quizzes', '')::int;
    if v_max is null then
      return new;
    end if;

    select count(*)::int into v_active_count
    from public.quizzes q
    where q.author_id = new.author_id
      and q.status = 'published';

    if v_active_count >= v_max then
      raise exception 'Published quiz limit reached for this plan';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists on_quizzes_enforce_publish_limit on public.quizzes;
create trigger on_quizzes_enforce_publish_limit
before update on public.quizzes
for each row execute function public.enforce_quiz_publish_limit();

create or replace function public.enforce_quiz_participant_limit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_author_id uuid;
  v_limits jsonb;
  v_max int;
  v_distinct_participants int;
begin
  -- If the user already participated before, allow (retakes don't consume capacity).
  if exists (
    select 1 from public.quiz_attempts qa
    where qa.quiz_id = new.quiz_id and qa.user_id = new.user_id
  ) then
    return new;
  end if;

  select q.author_id into v_author_id from public.quizzes q where q.id = new.quiz_id;
  v_limits := public.get_effective_limits(v_author_id);
  v_max := nullif(v_limits->>'max_quiz_participants', '')::int;
  if v_max is null then
    return new;
  end if;

  select count(distinct qa.user_id)::int into v_distinct_participants
  from public.quiz_attempts qa
  where qa.quiz_id = new.quiz_id;

  if v_distinct_participants >= v_max then
    raise exception 'Quiz participant limit reached for this plan';
  end if;

  return new;
end;
$$;

drop trigger if exists on_quiz_attempts_enforce_participants on public.quiz_attempts;
create trigger on_quiz_attempts_enforce_participants
before insert on public.quiz_attempts
for each row execute function public.enforce_quiz_participant_limit();


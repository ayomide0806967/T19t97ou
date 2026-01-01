-- ============================================================================
-- Admin panel: Post moderation + trending overrides + admin views
-- ============================================================================

create table if not exists public.post_moderation (
  post_id uuid primary key references public.posts(id) on delete cascade,
  removed_reason text,
  removed_by uuid references auth.users(id),
  removed_at timestamptz,
  restored_by uuid references auth.users(id),
  restored_at timestamptz
);

create table if not exists public.post_trending_overrides (
  post_id uuid primary key references public.posts(id) on delete cascade,
  trending_multiplier numeric(6,2) not null default 1.00 check (trending_multiplier > 0 and trending_multiplier <= 10),
  exclude_from_trending boolean not null default false,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id)
);

create index if not exists post_trending_overrides_updated_at_idx
on public.post_trending_overrides (updated_at desc);

-- RLS: no direct client access; Edge Functions use service role.
alter table public.post_moderation enable row level security;
alter table public.post_trending_overrides enable row level security;

-- Admin view of posts (includes deleted posts).
create or replace view public.admin_posts_view as
select
  p.id,
  p.author_id,
  pr.handle,
  pr.full_name as author_name,
  pr.avatar_url as author_avatar_url,
  p.body,
  p.tags,
  p.visibility,
  p.class_id,
  p.quote_id,
  p.reply_to_id,
  p.created_at,
  p.updated_at,
  p.deleted_at,

  (select count(*) from public.post_comments where post_id = p.id) as reply_count,
  (select count(*) from public.post_reposts where post_id = p.id) as repost_count,
  (select count(*) from public.post_likes where post_id = p.id) as like_count,
  (select count(*) from public.post_bookmarks where post_id = p.id) as bookmark_count,

  coalesce(
    array(select media_url from public.post_media where post_id = p.id order by order_index),
    '{}'::text[]
  ) as media_urls,

  pm.removed_reason,
  pm.removed_by,
  pm.removed_at,
  pm.restored_by,
  pm.restored_at,

  pto.trending_multiplier,
  pto.exclude_from_trending,
  pto.note as trending_note,
  pto.updated_by as trending_updated_by,
  pto.updated_at as trending_updated_at
from public.posts p
join public.profiles pr on pr.id = p.author_id
left join public.post_moderation pm on pm.post_id = p.id
left join public.post_trending_overrides pto on pto.post_id = p.id;

-- Trending view for admin (public + not deleted + not excluded).
create or replace view public.admin_trending_posts_view as
select
  apv.*,
  (
    (
      apv.like_count::numeric
      + (apv.repost_count::numeric * 2)
      + (apv.reply_count::numeric * 1.5)
      + (apv.bookmark_count::numeric * 0.5)
    )
    * coalesce(apv.trending_multiplier, 1.0)
    * exp(
      -1 * (
        extract(epoch from (now() - apv.created_at)) / 3600.0
      ) / 24.0
    )
  ) as trend_score
from public.admin_posts_view apv
where apv.deleted_at is null
  and apv.visibility = 'public'
  and coalesce(apv.exclude_from_trending, false) = false;


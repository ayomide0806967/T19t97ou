import { handleOptions } from '../_shared/cors.ts'
import { createSupabaseAdmin } from '../_shared/supabase.ts'
import { HttpError, requireAdmin, requireUser } from '../_shared/auth.ts'
import { jsonError, jsonOk } from '../_shared/response.ts'

type Action =
  | { action: 'trending'; limit?: number }
  | { action: 'list'; limit?: number; status?: 'active' | 'removed' | 'all'; query?: string }
  | { action: 'remove'; postId: string; reason: string }
  | { action: 'restore'; postId: string }
  | {
      action: 'set-trending'
      postId: string
      multiplier: number
      excludeFromTrending: boolean
      note?: string | null
    }

type TrendingSettings = {
  like_weight: number
  repost_weight: number
  reply_weight: number
  bookmark_weight: number
  time_decay_hours: number
  min_interactions: number
  max_candidates: number
}

const defaultTrending: TrendingSettings = {
  like_weight: 1.0,
  repost_weight: 2.0,
  reply_weight: 1.5,
  bookmark_weight: 0.5,
  time_decay_hours: 24,
  min_interactions: 5,
  max_candidates: 500,
}

function safeNum(value: unknown, fallback: number): number {
  const n = typeof value === 'number' ? value : Number(value)
  return Number.isFinite(n) ? n : fallback
}

async function loadTrendingSettings(supabaseAdmin: ReturnType<typeof createSupabaseAdmin>): Promise<TrendingSettings> {
  const { data } = await supabaseAdmin.from('admin_settings').select('value').eq('key', 'moderation.trending').maybeSingle()
  const value = (data as { value?: Record<string, unknown> } | null)?.value ?? {}

  return {
    like_weight: safeNum(value.like_weight, defaultTrending.like_weight),
    repost_weight: safeNum(value.repost_weight, defaultTrending.repost_weight),
    reply_weight: safeNum(value.reply_weight, defaultTrending.reply_weight),
    bookmark_weight: safeNum(value.bookmark_weight, defaultTrending.bookmark_weight),
    time_decay_hours: Math.max(1, safeNum(value.time_decay_hours, defaultTrending.time_decay_hours)),
    min_interactions: Math.max(0, safeNum(value.min_interactions, defaultTrending.min_interactions)),
    max_candidates: Math.min(2000, Math.max(50, safeNum(value.max_candidates, defaultTrending.max_candidates))),
  }
}

Deno.serve(async (req) => {
  const preflight = handleOptions(req)
  if (preflight) return preflight

  try {
    if (req.method !== 'POST') throw new HttpError(405, 'Method not allowed')

    const supabaseAdmin = createSupabaseAdmin()
    const authedUser = await requireUser(req, supabaseAdmin)

    const body = (await req.json()) as Action

    if (body.action === 'trending') {
      await requireAdmin(supabaseAdmin, authedUser.id, 'support')
      const limit = Math.min(Math.max(body.limit ?? 10, 1), 100)
      const settings = await loadTrendingSettings(supabaseAdmin)

      const { data, error } = await supabaseAdmin
        .from('admin_posts_view')
        .select(
          'id, handle, author_name, body, created_at, visibility, deleted_at, like_count, repost_count, reply_count, bookmark_count, trending_multiplier, exclude_from_trending',
        )
        .is('deleted_at', null)
        .eq('visibility', 'public')
        .order('created_at', { ascending: false })
        .limit(settings.max_candidates)

      if (error) throw new HttpError(500, error.message)

      const now = Date.now()
      const candidates = (data ?? []) as Array<Record<string, unknown>>

      const scored = candidates
        .filter((p) => !Boolean(p.exclude_from_trending))
        .map((p) => {
          const like = safeNum(p.like_count, 0)
          const repost = safeNum(p.repost_count, 0)
          const reply = safeNum(p.reply_count, 0)
          const bookmark = safeNum(p.bookmark_count, 0)

          const interactions = like + repost + reply + bookmark
          const base =
            like * settings.like_weight +
            repost * settings.repost_weight +
            reply * settings.reply_weight +
            bookmark * settings.bookmark_weight

          const multiplier = Math.max(0.01, safeNum(p.trending_multiplier, 1))
          const createdAt = new Date(String(p.created_at ?? '')).getTime()
          const hours = createdAt ? Math.max(0, (now - createdAt) / 1000 / 3600) : 0
          const decay = Math.exp(-hours / settings.time_decay_hours)
          const score = base * multiplier * decay

          return { ...p, trend_score: score, interactions }
        })
        .filter((p) => safeNum((p as any).interactions, 0) >= settings.min_interactions)
        .sort((a: any, b: any) => safeNum(b.trend_score, 0) - safeNum(a.trend_score, 0))
        .slice(0, limit)
        .map(({ interactions, ...p }) => p)

      return jsonOk(scored)
    }

    if (body.action === 'list') {
      await requireAdmin(supabaseAdmin, authedUser.id, 'support')
      const limit = Math.min(Math.max(body.limit ?? 50, 1), 500)
      const status = body.status ?? 'active'
      const query = (body.query ?? '').trim()

      let q = supabaseAdmin.from('admin_posts_view').select('*').order('created_at', { ascending: false }).limit(limit)
      if (status === 'active') q = q.is('deleted_at', null)
      if (status === 'removed') q = q.not('deleted_at', 'is', null)
      if (query) q = q.or(`body.ilike.%${query}%,handle.ilike.%${query}%`)

      const { data, error } = await q
      if (error) throw new HttpError(500, error.message)
      return jsonOk(data ?? [])
    }

    if (body.action === 'remove') {
      const adminRow = await requireAdmin(supabaseAdmin, authedUser.id, 'moderator')
      const postId = String(body.postId ?? '').trim()
      const reason = String(body.reason ?? '').trim()
      if (!postId) throw new HttpError(400, 'postId is required')
      if (!reason) throw new HttpError(400, 'reason is required')

      const { data: before } = await supabaseAdmin.from('posts').select('*').eq('id', postId).maybeSingle()

      const { error } = await supabaseAdmin
        .from('posts')
        .update({ deleted_at: new Date().toISOString() })
        .eq('id', postId)

      if (error) throw new HttpError(500, error.message)

      await supabaseAdmin.from('post_moderation').upsert(
        {
          post_id: postId,
          removed_reason: reason,
          removed_by: authedUser.id,
          removed_at: new Date().toISOString(),
          restored_by: null,
          restored_at: null,
        },
        { onConflict: 'post_id' },
      )

      await supabaseAdmin.from('admin_audit_logs').insert({
        actor_user_id: authedUser.id,
        actor_role: adminRow.role,
        action: 'remove-post',
        target_type: 'post',
        target_id: postId,
        before_json: before ?? null,
        after_json: { deleted_at: new Date().toISOString(), reason },
      })

      return jsonOk({ ok: true })
    }

    if (body.action === 'restore') {
      const adminRow = await requireAdmin(supabaseAdmin, authedUser.id, 'moderator')
      const postId = String(body.postId ?? '').trim()
      if (!postId) throw new HttpError(400, 'postId is required')

      const { data: before } = await supabaseAdmin.from('posts').select('*').eq('id', postId).maybeSingle()

      const { error } = await supabaseAdmin.from('posts').update({ deleted_at: null }).eq('id', postId)
      if (error) throw new HttpError(500, error.message)

      await supabaseAdmin.from('post_moderation').upsert(
        {
          post_id: postId,
          restored_by: authedUser.id,
          restored_at: new Date().toISOString(),
        },
        { onConflict: 'post_id' },
      )

      await supabaseAdmin.from('admin_audit_logs').insert({
        actor_user_id: authedUser.id,
        actor_role: adminRow.role,
        action: 'restore-post',
        target_type: 'post',
        target_id: postId,
        before_json: before ?? null,
        after_json: { deleted_at: null },
      })

      return jsonOk({ ok: true })
    }

    if (body.action === 'set-trending') {
      const adminRow = await requireAdmin(supabaseAdmin, authedUser.id, 'super_admin')
      const postId = String(body.postId ?? '').trim()
      const multiplier = Number(body.multiplier)
      if (!postId) throw new HttpError(400, 'postId is required')
      if (!Number.isFinite(multiplier) || multiplier <= 0 || multiplier > 10) {
        throw new HttpError(400, 'multiplier must be > 0 and <= 10')
      }

      const exclude = Boolean(body.excludeFromTrending)
      const note = body.note ? String(body.note).trim() : null

      const { data: before } = await supabaseAdmin
        .from('post_trending_overrides')
        .select('*')
        .eq('post_id', postId)
        .maybeSingle()

      const payload = {
        post_id: postId,
        trending_multiplier: multiplier,
        exclude_from_trending: exclude,
        note,
        updated_by: authedUser.id,
        updated_at: new Date().toISOString(),
      }

      const { error } = await supabaseAdmin.from('post_trending_overrides').upsert(payload, { onConflict: 'post_id' })
      if (error) throw new HttpError(500, error.message)

      await supabaseAdmin.from('admin_audit_logs').insert({
        actor_user_id: authedUser.id,
        actor_role: adminRow.role,
        action: 'set-post-trending',
        target_type: 'post',
        target_id: postId,
        before_json: before ?? null,
        after_json: payload,
      })

      return jsonOk({ ok: true })
    }

    throw new HttpError(400, 'Unknown action')
  } catch (err) {
    return jsonError(err)
  }
})

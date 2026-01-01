import { handleOptions } from '../_shared/cors.ts'
import { createSupabaseAdmin } from '../_shared/supabase.ts'
import { HttpError, requireAdmin, requireUser } from '../_shared/auth.ts'
import { jsonError, jsonOk } from '../_shared/response.ts'

type VerificationType = 'none' | 'verified' | 'creator' | 'institution'

type Action =
  | { action: 'set-verification'; userId: string; verificationType: VerificationType; expiresAt?: string | null }
  | { action: 'lock-user'; userId: string; lockUntil: string | null; reason: string }
  | { action: 'unlock-user'; userId: string }
  | { action: 'set-boost'; userId: string; multiplier: number; expiresAt: string | null }
  | { action: 'update-profile'; userId: string; updates: Record<string, unknown> }

Deno.serve(async (req) => {
  const preflight = handleOptions(req)
  if (preflight) return preflight

  try {
    if (req.method !== 'POST') throw new HttpError(405, 'Method not allowed')

    const supabaseAdmin = createSupabaseAdmin()
    const authedUser = await requireUser(req, supabaseAdmin)
    const adminRow = await requireAdmin(supabaseAdmin, authedUser.id, 'moderator')

    const body = (await req.json()) as Action

    if (body.action === 'set-verification') {
      const targetId = body.userId
      const verificationType = body.verificationType
      const expiresAt = body.expiresAt ?? null

      const { data: before } = await supabaseAdmin.from('profiles').select('*').eq('id', targetId).maybeSingle()

      const { error } = await supabaseAdmin
        .from('profiles')
        .update({
          verified_type: verificationType,
          verified_at: verificationType !== 'none' ? new Date().toISOString() : null,
          verified_by: verificationType !== 'none' ? authedUser.id : null,
          verified_expires_at: verificationType !== 'none' ? expiresAt : null,
        })
        .eq('id', targetId)

      if (error) throw new HttpError(500, error.message)

      await supabaseAdmin.from('admin_audit_logs').insert({
        actor_user_id: authedUser.id,
        actor_role: adminRow.role,
        action: 'set-verification',
        target_type: 'user',
        target_id: targetId,
        before_json: before ?? null,
        after_json: { verified_type: verificationType, verified_expires_at: expiresAt },
      })

      return jsonOk({ ok: true })
    }

    if (body.action === 'lock-user') {
      const targetId = body.userId
      const reason = String(body.reason ?? '').trim()
      if (!reason) throw new HttpError(400, 'reason is required')

      const { data: before } = await supabaseAdmin.from('profiles').select('*').eq('id', targetId).maybeSingle()

      const { error } = await supabaseAdmin
        .from('profiles')
        .update({
          is_locked: true,
          locked_reason: reason,
          locked_at: new Date().toISOString(),
          locked_until: body.lockUntil,
          locked_by: authedUser.id,
        })
        .eq('id', targetId)

      if (error) throw new HttpError(500, error.message)

      await supabaseAdmin.from('admin_audit_logs').insert({
        actor_user_id: authedUser.id,
        actor_role: adminRow.role,
        action: 'lock-user',
        target_type: 'user',
        target_id: targetId,
        before_json: before ?? null,
        after_json: { reason, locked_until: body.lockUntil },
      })

      return jsonOk({ ok: true })
    }

    if (body.action === 'unlock-user') {
      const targetId = body.userId
      const { data: before } = await supabaseAdmin.from('profiles').select('*').eq('id', targetId).maybeSingle()

      const { error } = await supabaseAdmin
        .from('profiles')
        .update({ is_locked: false, locked_reason: null, locked_at: null, locked_until: null, locked_by: null })
        .eq('id', targetId)

      if (error) throw new HttpError(500, error.message)

      await supabaseAdmin.from('admin_audit_logs').insert({
        actor_user_id: authedUser.id,
        actor_role: adminRow.role,
        action: 'unlock-user',
        target_type: 'user',
        target_id: targetId,
        before_json: before ?? null,
        after_json: { is_locked: false },
      })

      return jsonOk({ ok: true })
    }

    if (body.action === 'set-boost') {
      const targetId = body.userId
      const multiplier = Number(body.multiplier)
      if (!Number.isFinite(multiplier) || multiplier < 1 || multiplier > 5) {
        throw new HttpError(400, 'multiplier must be between 1 and 5')
      }

      const { data: before } = await supabaseAdmin.from('profiles').select('*').eq('id', targetId).maybeSingle()

      const { error } = await supabaseAdmin
        .from('profiles')
        .update({ boost_multiplier: multiplier, boost_expires_at: body.expiresAt, boosted_by: authedUser.id })
        .eq('id', targetId)

      if (error) throw new HttpError(500, error.message)

      await supabaseAdmin.from('admin_audit_logs').insert({
        actor_user_id: authedUser.id,
        actor_role: adminRow.role,
        action: 'set-boost',
        target_type: 'user',
        target_id: targetId,
        before_json: before ?? null,
        after_json: { boost_multiplier: multiplier, boost_expires_at: body.expiresAt },
      })

      return jsonOk({ ok: true })
    }

    if (body.action === 'update-profile') {
      const targetId = body.userId
      const updates = body.updates ?? {}
      if (!updates || typeof updates !== 'object') throw new HttpError(400, 'updates is required')

      const { data: before } = await supabaseAdmin.from('profiles').select('*').eq('id', targetId).maybeSingle()
      const { error } = await supabaseAdmin.from('profiles').update(updates).eq('id', targetId)
      if (error) throw new HttpError(500, error.message)

      await supabaseAdmin.from('admin_audit_logs').insert({
        actor_user_id: authedUser.id,
        actor_role: adminRow.role,
        action: 'update-profile',
        target_type: 'user',
        target_id: targetId,
        before_json: before ?? null,
        after_json: updates,
      })

      return jsonOk({ ok: true })
    }

    throw new HttpError(400, 'Unknown action')
  } catch (err) {
    return jsonError(err)
  }
})


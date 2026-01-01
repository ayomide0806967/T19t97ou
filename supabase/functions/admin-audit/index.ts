import { handleOptions } from '../_shared/cors.ts'
import { createSupabaseAdmin } from '../_shared/supabase.ts'
import { HttpError, requireAdmin, requireUser } from '../_shared/auth.ts'
import { jsonError, jsonOk } from '../_shared/response.ts'

type Action =
  | { action: 'list'; limit?: number }
  | { action: 'list-for-target'; targetType: string; targetId: string; limit?: number }
  | {
      action: 'log'
      actionName: string
      targetType?: string | null
      targetId?: string | null
      beforeJson?: unknown | null
      afterJson?: unknown | null
    }

Deno.serve(async (req) => {
  const preflight = handleOptions(req)
  if (preflight) return preflight

  try {
    if (req.method !== 'POST') throw new HttpError(405, 'Method not allowed')

    const supabaseAdmin = createSupabaseAdmin()
    const authedUser = await requireUser(req, supabaseAdmin)
    const adminRow = await requireAdmin(supabaseAdmin, authedUser.id, 'support')

    const body = (await req.json()) as Action

    if (body.action === 'log') {
      const name = String(body.actionName ?? '').trim()
      if (!name) throw new HttpError(400, 'actionName is required')

      const { error } = await supabaseAdmin.from('admin_audit_logs').insert({
        actor_user_id: authedUser.id,
        actor_role: adminRow.role,
        action: name,
        target_type: body.targetType ?? null,
        target_id: body.targetId ?? null,
        before_json: body.beforeJson ?? null,
        after_json: body.afterJson ?? null,
      })
      if (error) throw new HttpError(500, error.message)
      return jsonOk({ ok: true })
    }

    const limit = Math.min(Math.max(body.limit ?? 200, 1), 1000)
    let query = supabaseAdmin.from('admin_audit_logs').select('*').order('created_at', { ascending: false }).limit(limit)

    if (body.action === 'list-for-target') {
      if (!body.targetType || !body.targetId) throw new HttpError(400, 'targetType/targetId are required')
      query = query.eq('target_type', body.targetType).eq('target_id', body.targetId)
    } else if (body.action !== 'list') {
      throw new HttpError(400, 'Unknown action')
    }

    const { data, error } = await query
    if (error) throw new HttpError(500, error.message)
    return jsonOk(data ?? [])
  } catch (err) {
    return jsonError(err)
  }
})

import { handleOptions } from '../_shared/cors.ts'
import { createSupabaseAdmin } from '../_shared/supabase.ts'
import { HttpError, requireAdmin, requireUser } from '../_shared/auth.ts'
import { jsonError, jsonOk } from '../_shared/response.ts'

type SettingRow = { key: string; value: Record<string, unknown> }

type Action =
  | { action: 'list'; like: string }
  | { action: 'upsert'; settings: SettingRow[] }

Deno.serve(async (req) => {
  const preflight = handleOptions(req)
  if (preflight) return preflight

  try {
    if (req.method !== 'POST') throw new HttpError(405, 'Method not allowed')

    const supabaseAdmin = createSupabaseAdmin()
    const authedUser = await requireUser(req, supabaseAdmin)
    const adminRow = await requireAdmin(supabaseAdmin, authedUser.id, 'super_admin')

    const body = (await req.json()) as Action

    if (body.action === 'list') {
      const like = body.like?.trim()
      if (!like) throw new HttpError(400, 'like is required')

      const { data, error } = await supabaseAdmin.from('admin_settings').select('*').like('key', like)
      if (error) throw new HttpError(500, error.message)
      return jsonOk(data ?? [])
    }

    if (body.action === 'upsert') {
      const settings = body.settings ?? []
      if (!Array.isArray(settings) || settings.length === 0) throw new HttpError(400, 'settings is required')

      const payload = settings.map((s) => ({
        key: String(s.key),
        value: s.value ?? {},
        updated_by: authedUser.id,
        updated_at: new Date().toISOString(),
      }))

      const { error } = await supabaseAdmin.from('admin_settings').upsert(payload, { onConflict: 'key' })
      if (error) throw new HttpError(500, error.message)

      await supabaseAdmin.from('admin_audit_logs').insert({
        actor_user_id: authedUser.id,
        actor_role: adminRow.role,
        action: 'update-settings',
        target_type: 'admin_settings',
        target_id: 'bulk',
        before_json: null,
        after_json: { keys: settings.map((s) => s.key) },
      })

      return jsonOk({ ok: true })
    }

    throw new HttpError(400, 'Unknown action')
  } catch (err) {
    return jsonError(err)
  }
})


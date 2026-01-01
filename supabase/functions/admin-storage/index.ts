import { handleOptions } from '../_shared/cors.ts'
import { createSupabaseAdmin } from '../_shared/supabase.ts'
import { HttpError, requireAdmin, requireUser } from '../_shared/auth.ts'
import { jsonError, jsonOk } from '../_shared/response.ts'

type Action =
  | { action: 'list-bucket'; bucket: string; path?: string }
  | { action: 'delete-file'; bucket: string; path: string }
  | { action: 'delete-files'; bucket: string; paths: string[] }

Deno.serve(async (req) => {
  const preflight = handleOptions(req)
  if (preflight) return preflight

  try {
    if (req.method !== 'POST') throw new HttpError(405, 'Method not allowed')

    const supabaseAdmin = createSupabaseAdmin()
    const authedUser = await requireUser(req, supabaseAdmin)
    const adminRow = await requireAdmin(supabaseAdmin, authedUser.id, 'super_admin')

    const body = (await req.json()) as Action

    if (body.action === 'list-bucket') {
      if (!body.bucket?.trim()) throw new HttpError(400, 'bucket is required')

      const path = (body.path ?? '').trim()
      const { data, error } = await supabaseAdmin.storage.from(body.bucket).list(path, { limit: 200 })
      if (error) throw new HttpError(500, error.message)
      return jsonOk(data ?? [])
    }

    if (body.action === 'delete-file') {
      if (!body.bucket?.trim()) throw new HttpError(400, 'bucket is required')
      if (!body.path?.trim()) throw new HttpError(400, 'path is required')

      const { error } = await supabaseAdmin.storage.from(body.bucket).remove([body.path])
      if (error) throw new HttpError(500, error.message)

      await supabaseAdmin.from('admin_audit_logs').insert({
        actor_user_id: authedUser.id,
        actor_role: adminRow.role,
        action: 'delete-file',
        target_type: 'storage',
        target_id: `${body.bucket}/${body.path}`,
        before_json: null,
        after_json: null,
      })

      return jsonOk({ ok: true })
    }

    if (body.action === 'delete-files') {
      if (!body.bucket?.trim()) throw new HttpError(400, 'bucket is required')
      const paths = body.paths ?? []
      if (!Array.isArray(paths) || paths.length === 0) throw new HttpError(400, 'paths is required')

      const cleaned = paths.map((p) => String(p)).filter(Boolean)
      const { error } = await supabaseAdmin.storage.from(body.bucket).remove(cleaned)
      if (error) throw new HttpError(500, error.message)

      await supabaseAdmin.from('admin_audit_logs').insert({
        actor_user_id: authedUser.id,
        actor_role: adminRow.role,
        action: 'delete-files',
        target_type: 'storage',
        target_id: body.bucket,
        before_json: null,
        after_json: { count: cleaned.length },
      })

      return jsonOk({ ok: true })
    }

    throw new HttpError(400, 'Unknown action')
  } catch (err) {
    return jsonError(err)
  }
})


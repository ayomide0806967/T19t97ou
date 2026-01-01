import { handleOptions } from '../_shared/cors.ts'
import { createSupabaseAdmin, type AdminRole } from '../_shared/supabase.ts'
import { HttpError, requireAdmin, requireUser } from '../_shared/auth.ts'
import { jsonError, jsonOk } from '../_shared/response.ts'

type AdminUserInsert = {
  user_id: string
  role: AdminRole
  is_active?: boolean
  dm_access_enabled?: boolean
  created_by?: string
}

type Action =
  | { action: 'list' }
  | { action: 'add-admin'; email: string; role: AdminRole }
  | { action: 'set-active'; userId: string; isActive: boolean }
  | { action: 'set-dm-access'; userId: string; enabled: boolean }
  | { action: 'set-role'; userId: string; role: AdminRole }

async function findUserIdByEmail(supabaseAdmin: ReturnType<typeof createSupabaseAdmin>, email: string): Promise<string> {
  const normalized = email.trim().toLowerCase()
  if (!normalized) throw new HttpError(400, 'Email is required')

  let page = 1
  const perPage = 200
  const maxPages = 25

  while (page <= maxPages) {
    const { data, error } = await supabaseAdmin.auth.admin.listUsers({ page, perPage })
    if (error) throw new HttpError(500, error.message)

    const match = data.users.find((u) => (u.email ?? '').toLowerCase() === normalized)
    if (match?.id) return match.id

    if (data.users.length < perPage) break
    page += 1
  }

  throw new HttpError(404, 'User not found for that email')
}

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
      const { data: admins, error } = await supabaseAdmin
        .from('admin_users')
        .select('*')
        .order('created_at', { ascending: true })

      if (error) throw new HttpError(500, error.message)

      const adminRows = (admins ?? []) as Array<{ user_id: string }>
      const ids = adminRows.map((a) => a.user_id)

      const { data: profiles, error: profilesError } = await supabaseAdmin
        .from('profiles')
        .select('id, handle, full_name, avatar_url')
        .in('id', ids)

      if (profilesError) throw new HttpError(500, profilesError.message)

      const profileMap = new Map<string, unknown>()
      ;(profiles ?? []).forEach((p) => profileMap.set((p as { id: string }).id, p))

      return jsonOk(
        (admins ?? []).map((a: any) => ({
          ...a,
          profiles: (profileMap.get(a.user_id) as any) ?? null,
        })),
      )
    }

    if (body.action === 'add-admin') {
      const userId = await findUserIdByEmail(supabaseAdmin, body.email)
      const insert: AdminUserInsert = {
        user_id: userId,
        role: body.role,
        is_active: true,
        dm_access_enabled: false,
        created_by: authedUser.id,
      }

      const { error } = await supabaseAdmin
        .from('admin_users')
        .upsert(insert, { onConflict: 'user_id' })

      if (error) throw new HttpError(500, error.message)

      const { data: createdAdminRow, error: adminRowError } = await supabaseAdmin
        .from('admin_users')
        .select('*')
        .eq('user_id', userId)
        .single()

      if (adminRowError) throw new HttpError(500, adminRowError.message)

      const { data: profileRow } = await supabaseAdmin
        .from('profiles')
        .select('id, handle, full_name, avatar_url')
        .eq('id', userId)
        .maybeSingle()

      await supabaseAdmin.from('admin_audit_logs').insert({
        actor_user_id: authedUser.id,
        actor_role: adminRow.role,
        action: 'add-admin',
        target_type: 'admin_user',
        target_id: userId,
        before_json: null,
        after_json: { role: body.role },
      })

      return jsonOk({
        ...createdAdminRow,
        profiles: profileRow ?? null,
      })
    }

    if (body.action === 'set-active') {
      const { data: before } = await supabaseAdmin
        .from('admin_users')
        .select('*')
        .eq('user_id', body.userId)
        .maybeSingle()

      const { error } = await supabaseAdmin
        .from('admin_users')
        .update({ is_active: body.isActive })
        .eq('user_id', body.userId)

      if (error) throw new HttpError(500, error.message)

      await supabaseAdmin.from('admin_audit_logs').insert({
        actor_user_id: authedUser.id,
        actor_role: adminRow.role,
        action: 'set-admin-active',
        target_type: 'admin_user',
        target_id: body.userId,
        before_json: before ?? null,
        after_json: { is_active: body.isActive },
      })

      return jsonOk({ ok: true })
    }

    if (body.action === 'set-dm-access') {
      const { data: before } = await supabaseAdmin
        .from('admin_users')
        .select('*')
        .eq('user_id', body.userId)
        .maybeSingle()

      const { error } = await supabaseAdmin
        .from('admin_users')
        .update({ dm_access_enabled: body.enabled })
        .eq('user_id', body.userId)

      if (error) throw new HttpError(500, error.message)

      await supabaseAdmin.from('admin_audit_logs').insert({
        actor_user_id: authedUser.id,
        actor_role: adminRow.role,
        action: 'set-admin-dm-access',
        target_type: 'admin_user',
        target_id: body.userId,
        before_json: before ?? null,
        after_json: { dm_access_enabled: body.enabled },
      })

      return jsonOk({ ok: true })
    }

    if (body.action === 'set-role') {
      const { data: before } = await supabaseAdmin
        .from('admin_users')
        .select('*')
        .eq('user_id', body.userId)
        .maybeSingle()

      const { error } = await supabaseAdmin
        .from('admin_users')
        .update({ role: body.role })
        .eq('user_id', body.userId)

      if (error) throw new HttpError(500, error.message)

      await supabaseAdmin.from('admin_audit_logs').insert({
        actor_user_id: authedUser.id,
        actor_role: adminRow.role,
        action: 'set-admin-role',
        target_type: 'admin_user',
        target_id: body.userId,
        before_json: before ?? null,
        after_json: { role: body.role },
      })

      return jsonOk({ ok: true })
    }

    throw new HttpError(400, 'Unknown action')
  } catch (err) {
    return jsonError(err)
  }
})

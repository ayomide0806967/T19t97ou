import { handleOptions } from '../_shared/cors.ts'
import { createSupabaseAdmin } from '../_shared/supabase.ts'
import { HttpError, requireAdmin, requireUser } from '../_shared/auth.ts'
import { jsonError, jsonOk } from '../_shared/response.ts'

type PlanRow = {
  code: string
  name: string
  description: string | null
  limits: Record<string, unknown>
  features: Record<string, unknown>
  is_active: boolean
}

type Action =
  | { action: 'list' }
  | { action: 'create'; plan: PlanRow }
  | { action: 'update'; code: string; patch: Partial<Omit<PlanRow, 'code'>> }
  | { action: 'delete'; code: string }

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
      const { data, error } = await supabaseAdmin.from('plans').select('*').order('created_at', { ascending: true })
      if (error) throw new HttpError(500, error.message)
      return jsonOk(data ?? [])
    }

    if (body.action === 'create') {
      const plan = body.plan
      if (!plan.code?.trim()) throw new HttpError(400, 'Plan code is required')
      if (!plan.name?.trim()) throw new HttpError(400, 'Plan name is required')

      const { error } = await supabaseAdmin.from('plans').insert({
        code: plan.code.trim(),
        name: plan.name.trim(),
        description: plan.description?.trim() || null,
        limits: plan.limits ?? {},
        features: plan.features ?? {},
        is_active: Boolean(plan.is_active),
      })

      if (error) throw new HttpError(500, error.message)

      await supabaseAdmin.from('admin_audit_logs').insert({
        actor_user_id: authedUser.id,
        actor_role: adminRow.role,
        action: 'create-plan',
        target_type: 'plan',
        target_id: plan.code.trim(),
        before_json: null,
        after_json: plan,
      })

      return jsonOk({ ok: true })
    }

    if (body.action === 'update') {
      const code = body.code?.trim()
      if (!code) throw new HttpError(400, 'Plan code is required')

      const { data: before } = await supabaseAdmin.from('plans').select('*').eq('code', code).maybeSingle()

      const { error } = await supabaseAdmin
        .from('plans')
        .update({
          name: body.patch.name?.trim(),
          description: body.patch.description !== undefined ? (body.patch.description?.trim() || null) : undefined,
          limits: body.patch.limits,
          features: body.patch.features,
          is_active: body.patch.is_active,
        })
        .eq('code', code)

      if (error) throw new HttpError(500, error.message)

      await supabaseAdmin.from('admin_audit_logs').insert({
        actor_user_id: authedUser.id,
        actor_role: adminRow.role,
        action: 'update-plan',
        target_type: 'plan',
        target_id: code,
        before_json: before ?? null,
        after_json: body.patch,
      })

      return jsonOk({ ok: true })
    }

    if (body.action === 'delete') {
      const code = body.code?.trim()
      if (!code) throw new HttpError(400, 'Plan code is required')

      const { data: before } = await supabaseAdmin.from('plans').select('*').eq('code', code).maybeSingle()

      const { error } = await supabaseAdmin.from('plans').delete().eq('code', code)
      if (error) throw new HttpError(500, error.message)

      await supabaseAdmin.from('admin_audit_logs').insert({
        actor_user_id: authedUser.id,
        actor_role: adminRow.role,
        action: 'delete-plan',
        target_type: 'plan',
        target_id: code,
        before_json: before ?? null,
        after_json: null,
      })

      return jsonOk({ ok: true })
    }

    throw new HttpError(400, 'Unknown action')
  } catch (err) {
    return jsonError(err)
  }
})


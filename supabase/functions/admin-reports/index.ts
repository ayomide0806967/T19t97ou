import { handleOptions } from '../_shared/cors.ts'
import { createSupabaseAdmin } from '../_shared/supabase.ts'
import { HttpError, requireAdmin, requireUser } from '../_shared/auth.ts'
import { jsonError, jsonOk } from '../_shared/response.ts'

type Action =
    | { action: 'list'; status?: string; limit?: number }
    | { action: 'update-status'; reportId: string; status: string; resolutionNotes?: string; actionTaken?: string }

Deno.serve(async (req) => {
    const preflight = handleOptions(req)
    if (preflight) return preflight

    try {
        if (req.method !== 'POST') throw new HttpError(405, 'Method not allowed')

        const supabaseAdmin = createSupabaseAdmin()
        const authedUser = await requireUser(req, supabaseAdmin)
        const adminRow = await requireAdmin(supabaseAdmin, authedUser.id, 'moderator')

        const body = (await req.json()) as Action

        if (body.action === 'list') {
            const limit = body.limit ?? 100
            const status = body.status

            let query = supabaseAdmin
                .from('reports')
                .select(`
          *,
          reporter:profiles!reporter_id(id, handle, full_name, avatar_url),
          reviewer:profiles!reviewed_by(id, handle, full_name)
        `)
                .order('created_at', { ascending: false })
                .limit(limit)

            if (status && status !== 'all') {
                query = query.eq('status', status)
            }

            const { data, error } = await query

            if (error) throw new HttpError(500, error.message)
            return jsonOk({ data })
        }

        if (body.action === 'update-status') {
            const { reportId, status, resolutionNotes, actionTaken } = body

            if (!reportId) throw new HttpError(400, 'reportId is required')
            if (!status) throw new HttpError(400, 'status is required')

            const { data: before } = await supabaseAdmin
                .from('reports')
                .select('*')
                .eq('id', reportId)
                .maybeSingle()

            const updateData: Record<string, unknown> = {
                status,
                reviewed_by: authedUser.id,
                reviewed_at: new Date().toISOString(),
            }

            if (resolutionNotes) updateData.resolution_notes = resolutionNotes
            if (actionTaken) updateData.action_taken = actionTaken

            const { error } = await supabaseAdmin
                .from('reports')
                .update(updateData)
                .eq('id', reportId)

            if (error) throw new HttpError(500, error.message)

            await supabaseAdmin.from('admin_audit_logs').insert({
                actor_user_id: authedUser.id,
                actor_role: adminRow.role,
                action: `report_${status}`,
                target_type: 'report',
                target_id: reportId,
                before_json: before ?? null,
                after_json: updateData,
            })

            return jsonOk({ ok: true })
        }

        throw new HttpError(400, 'Unknown action')
    } catch (err) {
        return jsonError(err)
    }
})

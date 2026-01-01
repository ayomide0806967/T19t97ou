import { handleOptions } from '../_shared/cors.ts'
import { createSupabaseAdmin } from '../_shared/supabase.ts'
import { HttpError, requireAdmin, requireUser } from '../_shared/auth.ts'
import { jsonError, jsonOk } from '../_shared/response.ts'

type Action =
    | { action: 'list'; limit?: number }
    | { action: 'create'; title: string; body: string; targetType: string; targetId?: string; scheduledAt?: string }
    | { action: 'send'; broadcastId: string }

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
            const limit = body.limit ?? 50

            const { data, error } = await supabaseAdmin
                .from('admin_broadcasts')
                .select('*')
                .order('created_at', { ascending: false })
                .limit(limit)

            if (error) throw new HttpError(500, error.message)
            return jsonOk({ data })
        }

        if (body.action === 'create') {
            const { title, body: msgBody, targetType, targetId, scheduledAt } = body

            if (!title?.trim()) throw new HttpError(400, 'title is required')
            if (!msgBody?.trim()) throw new HttpError(400, 'body is required')

            // Calculate recipient count
            let recipientCount = 0
            if (targetType === 'all') {
                const { count } = await supabaseAdmin
                    .from('profiles')
                    .select('*', { count: 'exact', head: true })
                recipientCount = count ?? 0
            } else if (targetType === 'class' && targetId) {
                const { count } = await supabaseAdmin
                    .from('class_members')
                    .select('*', { count: 'exact', head: true })
                    .eq('class_id', targetId)
                recipientCount = count ?? 0
            } else if (targetType === 'user') {
                recipientCount = 1
            }

            const status = scheduledAt ? 'scheduled' : 'sent'
            const sentAt = scheduledAt ? null : new Date().toISOString()

            const { data: broadcast, error } = await supabaseAdmin
                .from('admin_broadcasts')
                .insert({
                    title,
                    body: msgBody,
                    target_type: targetType,
                    target_id: targetId ?? null,
                    status,
                    scheduled_at: scheduledAt ?? null,
                    sent_at: sentAt,
                    created_by: authedUser.id,
                    recipient_count: recipientCount,
                })
                .select()
                .single()

            if (error) throw new HttpError(500, error.message)

            // If sending immediately, create notifications for all recipients
            if (status === 'sent') {
                if (targetType === 'all') {
                    // Create system notification for all users
                    await supabaseAdmin.rpc('create_broadcast_notifications', {
                        p_title: title,
                        p_body: msgBody,
                        p_broadcast_id: broadcast.id,
                    })
                } else if (targetType === 'user' && targetId) {
                    await supabaseAdmin.from('notifications').insert({
                        user_id: targetId,
                        type: 'system',
                        title,
                        body: msgBody,
                        metadata: { broadcast_id: broadcast.id },
                    })
                }
            }

            // Log action
            await supabaseAdmin.from('admin_audit_logs').insert({
                actor_user_id: authedUser.id,
                actor_role: adminRow.role,
                action: 'broadcast_created',
                target_type: 'broadcast',
                target_id: broadcast.id,
                after_json: { title, target_type: targetType, recipient_count: recipientCount },
            })

            return jsonOk({ data: broadcast })
        }

        throw new HttpError(400, 'Unknown action')
    } catch (err) {
        return jsonError(err)
    }
})

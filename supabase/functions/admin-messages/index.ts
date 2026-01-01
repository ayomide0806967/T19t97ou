import { handleOptions } from '../_shared/cors.ts'
import { createSupabaseAdmin } from '../_shared/supabase.ts'
import { HttpError, requireAdmin, requireUser } from '../_shared/auth.ts'
import { jsonError, jsonOk } from '../_shared/response.ts'

type Action =
    | { action: 'list-conversations'; limit?: number; query?: string }
    | { action: 'get-messages'; conversationId: string; limit?: number }

Deno.serve(async (req) => {
    const preflight = handleOptions(req)
    if (preflight) return preflight

    try {
        if (req.method !== 'POST') throw new HttpError(405, 'Method not allowed')

        const supabaseAdmin = createSupabaseAdmin()
        const authedUser = await requireUser(req, supabaseAdmin)
        const adminRow = await requireAdmin(supabaseAdmin, authedUser.id, 'super_admin')

        // Only super_admins can access DMs
        if (adminRow.role !== 'super_admin') {
            throw new HttpError(403, 'Super admin access required')
        }

        const body = (await req.json()) as Action

        if (body.action === 'list-conversations') {
            const limit = body.limit ?? 50
            const searchQuery = body.query?.toLowerCase() ?? ''

            // Get conversations with participant info
            const { data: conversations, error } = await supabaseAdmin
                .from('conversations')
                .select(`
          id,
          type,
          created_at,
          updated_at,
          participants:conversation_participants(
            user_id,
            joined_at,
            profile:profiles(id, handle, full_name, avatar_url)
          )
        `)
                .order('updated_at', { ascending: false, nullsFirst: false })
                .limit(limit)

            if (error) throw new HttpError(500, error.message)

            // Get last message for each conversation
            const conversationIds = conversations?.map(c => c.id) ?? []

            let lastMessages: Record<string, { body: string; created_at: string }> = {}
            if (conversationIds.length > 0) {
                const { data: messages } = await supabaseAdmin
                    .from('messages')
                    .select('conversation_id, body, created_at')
                    .in('conversation_id', conversationIds)
                    .order('created_at', { ascending: false })

                // Group by conversation, take first (latest) message
                for (const msg of messages ?? []) {
                    if (!lastMessages[msg.conversation_id]) {
                        lastMessages[msg.conversation_id] = { body: msg.body, created_at: msg.created_at }
                    }
                }
            }

            // Get message counts
            const { data: counts } = await supabaseAdmin
                .rpc('get_conversation_message_counts', { conversation_ids: conversationIds })
                .select('*')

            const countMap: Record<string, number> = {}
            for (const c of counts ?? []) {
                countMap[c.conversation_id] = c.count
            }

            // Transform data
            const result = conversations?.map(conv => {
                const participants = conv.participants ?? []
                return {
                    id: conv.id,
                    type: conv.type,
                    created_at: conv.created_at,
                    updated_at: conv.updated_at,
                    participant_1: participants[0]?.profile ?? null,
                    participant_2: participants[1]?.profile ?? null,
                    last_message: lastMessages[conv.id]?.body ?? '',
                    last_message_at: lastMessages[conv.id]?.created_at ?? conv.created_at,
                    message_count: countMap[conv.id] ?? 0,
                }
            }).filter(conv => {
                if (!searchQuery) return true
                const p1 = conv.participant_1
                const p2 = conv.participant_2
                return (
                    p1?.handle?.toLowerCase().includes(searchQuery) ||
                    p1?.full_name?.toLowerCase().includes(searchQuery) ||
                    p2?.handle?.toLowerCase().includes(searchQuery) ||
                    p2?.full_name?.toLowerCase().includes(searchQuery)
                )
            })

            // Log access
            await supabaseAdmin.from('admin_audit_logs').insert({
                actor_user_id: authedUser.id,
                actor_role: adminRow.role,
                action: 'dm_list_viewed',
                target_type: 'system',
                target_id: null,
                after_json: { count: result?.length ?? 0 },
            })

            return jsonOk({ data: result })
        }

        if (body.action === 'get-messages') {
            const { conversationId } = body
            const limit = body.limit ?? 100

            if (!conversationId) throw new HttpError(400, 'conversationId is required')

            const { data: messages, error } = await supabaseAdmin
                .from('messages')
                .select(`
          id,
          sender_id,
          body,
          created_at,
          deleted_at,
          sender:profiles!sender_id(id, handle, full_name, avatar_url)
        `)
                .eq('conversation_id', conversationId)
                .order('created_at', { ascending: true })
                .limit(limit)

            if (error) throw new HttpError(500, error.message)

            // Log access
            await supabaseAdmin.from('admin_audit_logs').insert({
                actor_user_id: authedUser.id,
                actor_role: adminRow.role,
                action: 'dm_conversation_viewed',
                target_type: 'conversation',
                target_id: conversationId,
                after_json: { message_count: messages?.length ?? 0 },
            })

            return jsonOk({ data: messages })
        }

        throw new HttpError(400, 'Unknown action')
    } catch (err) {
        return jsonError(err)
    }
})

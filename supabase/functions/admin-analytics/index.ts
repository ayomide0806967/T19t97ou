import { handleOptions } from '../_shared/cors.ts'
import { createSupabaseAdmin } from '../_shared/supabase.ts'
import { HttpError, requireAdmin, requireUser } from '../_shared/auth.ts'
import { jsonError, jsonOk } from '../_shared/response.ts'

type Action =
    | { action: 'stats' }
    | { action: 'top-content'; limit?: number }
    | { action: 'top-users'; limit?: number }

Deno.serve(async (req) => {
    const preflight = handleOptions(req)
    if (preflight) return preflight

    try {
        if (req.method !== 'POST') throw new HttpError(405, 'Method not allowed')

        const supabaseAdmin = createSupabaseAdmin()
        const authedUser = await requireUser(req, supabaseAdmin)
        await requireAdmin(supabaseAdmin, authedUser.id, 'support')

        const body = (await req.json()) as Action

        if (body.action === 'stats') {
            const now = new Date()
            const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
            const thirtyDaysAgo = new Date(today.getTime() - 30 * 24 * 60 * 60 * 1000)

            // Total users
            const { count: totalUsers } = await supabaseAdmin
                .from('profiles')
                .select('*', { count: 'exact', head: true })

            // Users active today (had any activity)
            const { count: dauCount } = await supabaseAdmin
                .from('profiles')
                .select('*', { count: 'exact', head: true })
                .gte('updated_at', today.toISOString())

            // Users active in last 30 days
            const { count: mauCount } = await supabaseAdmin
                .from('profiles')
                .select('*', { count: 'exact', head: true })
                .gte('updated_at', thirtyDaysAgo.toISOString())

            // Posts created today
            const { count: postsToday } = await supabaseAdmin
                .from('posts')
                .select('*', { count: 'exact', head: true })
                .gte('created_at', today.toISOString())

            // Total posts
            const { count: totalPosts } = await supabaseAdmin
                .from('posts')
                .select('*', { count: 'exact', head: true })

            // Messages today
            const { count: messagesToday } = await supabaseAdmin
                .from('messages')
                .select('*', { count: 'exact', head: true })
                .gte('created_at', today.toISOString())

            return jsonOk({
                data: {
                    totalUsers: totalUsers ?? 0,
                    dau: dauCount ?? 0,
                    mau: mauCount ?? 0,
                    postsToday: postsToday ?? 0,
                    totalPosts: totalPosts ?? 0,
                    messagesToday: messagesToday ?? 0,
                }
            })
        }

        if (body.action === 'top-content') {
            const limit = body.limit ?? 10

            // Get posts with engagement counts
            const { data: posts, error } = await supabaseAdmin
                .from('posts')
                .select(`
          id,
          body,
          created_at,
          author:profiles!author_id(id, handle, full_name),
          likes:post_likes(count),
          reposts:post_reposts(count),
          comments:post_comments(count)
        `)
                .is('removed_at', null)
                .order('created_at', { ascending: false })
                .limit(50)

            if (error) throw new HttpError(500, error.message)

            // Calculate engagement and sort
            const ranked = (posts ?? []).map(p => ({
                id: p.id,
                title: (p.body ?? '').substring(0, 60) + ((p.body?.length ?? 0) > 60 ? '...' : ''),
                author: p.author?.handle ? `@${p.author.handle}` : 'Unknown',
                likes: (p.likes as unknown as { count: number }[])?.[0]?.count ?? 0,
                reposts: (p.reposts as unknown as { count: number }[])?.[0]?.count ?? 0,
                comments: (p.comments as unknown as { count: number }[])?.[0]?.count ?? 0,
                views: 0, // Would need a views table
            })).sort((a, b) => {
                const scoreA = a.likes * 2 + a.reposts * 3 + a.comments * 2
                const scoreB = b.likes * 2 + b.reposts * 3 + b.comments * 2
                return scoreB - scoreA
            }).slice(0, limit)

            return jsonOk({ data: ranked })
        }

        if (body.action === 'top-users') {
            const limit = body.limit ?? 10

            // Get users with follower counts
            const { data: users, error } = await supabaseAdmin
                .from('profiles')
                .select(`
          id,
          handle,
          full_name,
          followers:follows!following_id(count),
          posts:posts!author_id(count)
        `)
                .order('created_at', { ascending: false })
                .limit(100)

            if (error) throw new HttpError(500, error.message)

            // Rank by followers
            const ranked = (users ?? []).map(u => ({
                id: u.id,
                handle: u.handle ?? '',
                full_name: u.full_name ?? '',
                followers: (u.followers as unknown as { count: number }[])?.[0]?.count ?? 0,
                posts: (u.posts as unknown as { count: number }[])?.[0]?.count ?? 0,
                engagement: 0, // Would calculate from actual engagement
            })).sort((a, b) => b.followers - a.followers).slice(0, limit)

            return jsonOk({ data: ranked })
        }

        throw new HttpError(400, 'Unknown action')
    } catch (err) {
        return jsonError(err)
    }
})

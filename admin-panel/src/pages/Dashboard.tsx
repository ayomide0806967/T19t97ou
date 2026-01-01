import { useState, useEffect } from 'react'
import { Users, BookOpen, FileQuestion, MessageCircle, Activity, Flame } from 'lucide-react'
import { StatCard } from '@/components/StatCard'
import { supabase } from '@/lib/supabase'
import { adminAudit } from '@/lib/edge-functions'
import { adminPosts } from '@/lib/edge-functions'
import { formatRelativeTime } from '@/lib/utils'
import type { AuditLog } from '@/types/database'

interface DashboardStats {
    totalUsers: number
    totalClasses: number
    totalQuizzes: number
    totalPosts: number
}

interface RecentUser {
    id: string
    handle: string
    full_name: string
    avatar_url: string | null
    created_at: string
}

interface TrendingPost {
    id: string
    handle: string
    author_name: string
    body: string
    created_at: string
    trend_score: number
}

export function DashboardPage() {
    const [stats, setStats] = useState<DashboardStats>({
        totalUsers: 0,
        totalClasses: 0,
        totalQuizzes: 0,
        totalPosts: 0,
    })
    const [recentActivity, setRecentActivity] = useState<AuditLog[]>([])
    const [recentUsers, setRecentUsers] = useState<RecentUser[]>([])
    const [trendingPosts, setTrendingPosts] = useState<TrendingPost[]>([])
    const [isLoading, setIsLoading] = useState(true)

    useEffect(() => {
        loadDashboardData()
    }, [])

    async function loadDashboardData() {
        setIsLoading(true)
        try {
            // Load stats
            const [usersRes, classesRes, quizzesRes, postsRes] = await Promise.all([
                supabase.from('profiles').select('id', { count: 'exact', head: true }),
                supabase.from('classes').select('id', { count: 'exact', head: true }),
                supabase.from('quizzes').select('id', { count: 'exact', head: true }),
                supabase.from('posts').select('id', { count: 'exact', head: true }).is('deleted_at', null),
            ])

            setStats({
                totalUsers: usersRes.count || 0,
                totalClasses: classesRes.count || 0,
                totalQuizzes: quizzesRes.count || 0,
                totalPosts: postsRes.count || 0,
            })

            // Load recent activity
            const auditRes = await adminAudit.list(5)
            if (auditRes.error) {
                console.error('Failed to load audit logs:', auditRes.error)
                setRecentActivity([])
            } else {
                setRecentActivity(((auditRes.data as AuditLog[]) || []).slice(0, 5))
            }

            // Load trending posts
            const trendingRes = await adminPosts.trending(5)
            if (trendingRes.error) {
                console.error('Failed to load trending posts:', trendingRes.error)
                setTrendingPosts([])
            } else {
                setTrendingPosts((trendingRes.data as TrendingPost[]) || [])
            }

            // Load recent users
            const { data: users } = await supabase
                .from('profiles')
                .select('id, handle, full_name, avatar_url, created_at')
                .order('created_at', { ascending: false })
                .limit(5)

            setRecentUsers((users as RecentUser[]) || [])
        } catch (err) {
            console.error('Failed to load dashboard data:', err)
        } finally {
            setIsLoading(false)
        }
    }

    return (
        <div className="p-8">
            {/* Header */}
            <div className="mb-8">
                <h1 className="text-2xl font-semibold text-[var(--color-text-primary)]">
                    Overview
                </h1>
                <p className="mt-1 text-[var(--color-text-muted)]">
                    Key metrics and recent activity across IN.
                </p>
            </div>

            {/* Stats Grid */}
            <div className="mb-8 grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
                <StatCard
                    title="Total Users"
                    value={stats.totalUsers.toLocaleString()}
                    change="Last 30 days"
                    changeType="neutral"
                    icon={Users}
                    iconColor="var(--color-primary-400)"
                />
                <StatCard
                    title="Active Classes"
                    value={stats.totalClasses.toLocaleString()}
                    change="Last 30 days"
                    changeType="neutral"
                    icon={BookOpen}
                    iconColor="var(--color-success-500)"
                />
                <StatCard
                    title="Total Quizzes"
                    value={stats.totalQuizzes.toLocaleString()}
                    change="Last 30 days"
                    changeType="neutral"
                    icon={FileQuestion}
                    iconColor="var(--color-warning-500)"
                />
                <StatCard
                    title="Total Posts"
                    value={stats.totalPosts.toLocaleString()}
                    change="Last 30 days"
                    changeType="neutral"
                    icon={MessageCircle}
                    iconColor="var(--color-info-500)"
                />
            </div>

            {/* Main Layout */}
            <div className="grid gap-6 lg:grid-cols-3">
                {/* Recent Users */}
                <div className="card p-6">
                    <div className="mb-4 flex items-center justify-between">
                        <h2 className="text-lg font-semibold text-[var(--color-text-primary)]">
                            Recent Users
                        </h2>
                        <a
                            href="/users"
                            className="text-sm text-[var(--color-primary-400)] hover:underline"
                        >
                            View all
                        </a>
                    </div>
                    <div className="space-y-3">
                        {isLoading ? (
                            <div className="flex h-40 items-center justify-center text-[var(--color-text-muted)]">
                                Loading...
                            </div>
                        ) : recentUsers.length === 0 ? (
                            <div className="flex h-40 items-center justify-center text-[var(--color-text-muted)]">
                                <div className="text-center text-sm">
                                    <p className="font-medium text-[var(--color-text-primary)]">
                                        No users yet
                                    </p>
                                    <p className="mt-1 text-[var(--color-text-muted)]">
                                        New signups will appear here as they join.
                                    </p>
                                </div>
                            </div>
                        ) : (
                            recentUsers.map((user) => (
                                <div
                                    key={user.id}
                                    className="flex items-center gap-3 rounded-lg p-2 transition-colors hover:bg-[var(--color-bg-tertiary)]"
                                >
                                    <div className="flex h-10 w-10 items-center justify-center rounded-full bg-gradient-to-br from-[var(--color-primary-600)] to-[var(--color-primary-400)] text-sm font-semibold text-white">
                                        {(user.full_name || user.handle || 'U')[0].toUpperCase()}
                                    </div>
                                    <div className="flex-1 overflow-hidden">
                                        <p className="truncate text-sm font-medium text-[var(--color-text-primary)]">
                                            {user.full_name || user.handle}
                                        </p>
                                        <p className="truncate text-xs text-[var(--color-text-muted)]">
                                            @{user.handle}
                                        </p>
                                    </div>
                                    <div className="text-xs text-[var(--color-text-muted)]">
                                        {formatRelativeTime(user.created_at)}
                                    </div>
                                </div>
                            ))
                        )}
                    </div>
                </div>

                {/* Trending Posts */}
                <div className="card p-6">
                    <div className="mb-4 flex items-center justify-between">
                        <h2 className="text-lg font-semibold text-[var(--color-text-primary)]">
                            Trending Posts
                        </h2>
                        <a
                            href="/posts"
                            className="text-sm text-[var(--color-primary-400)] hover:underline"
                        >
                            Manage
                        </a>
                    </div>
                    <div className="space-y-3">
                        {isLoading ? (
                            <div className="flex h-40 items-center justify-center text-[var(--color-text-muted)]">
                                Loading...
                            </div>
                        ) : trendingPosts.length === 0 ? (
                            <div className="flex h-40 items-center justify-center text-[var(--color-text-muted)]">
                                <div className="text-center text-sm">
                                    <Flame className="mx-auto mb-2 h-8 w-8 opacity-40" />
                                    <p className="font-medium text-[var(--color-text-primary)]">
                                        No trending data yet
                                    </p>
                                    <p className="mt-1 text-[var(--color-text-muted)]">
                                        Once posts gain traction, they&apos;ll surface here.
                                    </p>
                                </div>
                            </div>
                        ) : (
                            trendingPosts.map((post) => (
                                <div
                                    key={post.id}
                                    className="rounded-lg p-2 transition-colors hover:bg-[var(--color-bg-tertiary)]"
                                >
                                    <div className="flex items-center justify-between gap-3">
                                        <div className="min-w-0">
                                            <p className="truncate text-sm font-medium text-[var(--color-text-primary)]">
                                                @{post.handle}
                                            </p>
                                            <p className="truncate text-xs text-[var(--color-text-muted)]">
                                                {post.body}
                                            </p>
                                        </div>
                                        <div className="shrink-0 text-xs text-[var(--color-text-muted)]">
                                            {post.trend_score.toFixed(2)}
                                        </div>
                                    </div>
                                </div>
                            ))
                        )}
                    </div>
                </div>

                {/* Recent Activity */}
                <div className="card p-6">
                    <div className="mb-4 flex items-center justify-between">
                        <h2 className="text-lg font-semibold text-[var(--color-text-primary)]">
                            Admin Activity
                        </h2>
                        <a
                            href="/audit"
                            className="text-sm text-[var(--color-primary-400)] hover:underline"
                        >
                            View all
                        </a>
                    </div>
                    <div className="space-y-3">
                        {isLoading ? (
                            <div className="flex h-40 items-center justify-center text-[var(--color-text-muted)]">
                                Loading...
                            </div>
                        ) : recentActivity.length === 0 ? (
                            <div className="flex h-40 items-center justify-center text-[var(--color-text-muted)]">
                                <div className="text-center text-sm">
                                    <Activity className="mx-auto mb-2 h-8 w-8 opacity-40" />
                                    <p className="font-medium text-[var(--color-text-primary)]">
                                        No admin actions yet
                                    </p>
                                    <p className="mt-1 text-[var(--color-text-muted)]">
                                        As admins moderate content, a trail will appear here.
                                    </p>
                                </div>
                            </div>
                        ) : (
                            recentActivity.map((log) => (
                                <div
                                    key={log.id}
                                    className="flex items-start gap-3 rounded-lg p-2 transition-colors hover:bg-[var(--color-bg-tertiary)]"
                                >
                                    <div className="mt-0.5 flex h-8 w-8 items-center justify-center rounded-lg bg-[var(--color-bg-tertiary)]">
                                        <Activity className="h-4 w-4 text-[var(--color-text-muted)]" />
                                    </div>
                                    <div className="flex-1 overflow-hidden">
                                        <p className="text-sm text-[var(--color-text-primary)]">
                                            <span className="font-medium">{log.action}</span>
                                            {log.target_type && (
                                                <span className="text-[var(--color-text-muted)]">
                                                    {' '}on {log.target_type}
                                                </span>
                                            )}
                                        </p>
                                        <p className="text-xs text-[var(--color-text-muted)]">
                                            {formatRelativeTime(log.created_at)} • {log.actor_role}
                                        </p>
                                    </div>
                                </div>
                            ))
                        )}
                    </div>
                </div>
            </div>
        </div>
    )
}

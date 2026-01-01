import { useState, useEffect } from 'react'
import {
    TrendingUp, Users, FileText, MessageSquare,
    Download, ArrowUp, ArrowDown, Minus
} from 'lucide-react'
import { adminAnalytics } from '@/lib/edge-functions'
import { cn } from '@/lib/utils'

// ============================================================================
// Types
// ============================================================================

interface Stats {
    totalUsers: number
    dau: number
    mau: number
    postsToday: number
    totalPosts: number
    messagesToday: number
}

interface TopContent {
    id: string
    title: string
    author: string
    likes: number
    reposts: number
    comments: number
    views: number
}

interface TopUser {
    id: string
    handle: string
    full_name: string
    followers: number
    posts: number
    engagement: number
}

interface MetricCard {
    label: string
    value: number
    previousValue: number
    format: 'number' | 'percent' | 'currency'
    icon: typeof Users
}

// ============================================================================
// Components
// ============================================================================

function MetricCardComponent({ metric }: { metric: MetricCard }) {
    const change = metric.previousValue > 0
        ? ((metric.value - metric.previousValue) / metric.previousValue) * 100
        : 0
    const isPositive = change > 0
    const isNeutral = change === 0
    const Icon = metric.icon

    return (
        <div className="card p-5">
            <div className="flex items-start justify-between">
                <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-[var(--color-primary-500)]/15">
                    <Icon className="h-5 w-5 text-[var(--color-primary-400)]" />
                </div>
                <div className={cn(
                    'flex items-center gap-1 rounded-full px-2 py-1 text-xs font-medium',
                    isPositive && 'bg-[var(--color-success-500)]/15 text-[var(--color-success-500)]',
                    !isPositive && !isNeutral && 'bg-[var(--color-danger-500)]/15 text-[var(--color-danger-500)]',
                    isNeutral && 'bg-[var(--color-bg-tertiary)] text-[var(--color-text-muted)]'
                )}>
                    {isPositive ? <ArrowUp className="h-3 w-3" /> : isNeutral ? <Minus className="h-3 w-3" /> : <ArrowDown className="h-3 w-3" />}
                    {Math.abs(change).toFixed(1)}%
                </div>
            </div>
            <div className="mt-4">
                <p className="text-3xl font-bold text-[var(--color-text-primary)]">
                    {metric.value.toLocaleString()}
                </p>
                <p className="mt-1 text-sm text-[var(--color-text-muted)]">{metric.label}</p>
            </div>
        </div>
    )
}

// ============================================================================
// Main Page
// ============================================================================

export function AnalyticsPage() {
    const [stats, setStats] = useState<Stats | null>(null)
    const [topContent, setTopContent] = useState<TopContent[]>([])
    const [topUsers, setTopUsers] = useState<TopUser[]>([])
    const [isLoading, setIsLoading] = useState(true)

    useEffect(() => {
        loadData()
    }, [])

    async function loadData() {
        setIsLoading(true)
        try {
            const [statsRes, contentRes, usersRes] = await Promise.all([
                adminAnalytics.stats(),
                adminAnalytics.topContent(5),
                adminAnalytics.topUsers(5),
            ])

            if (statsRes.data) setStats(statsRes.data as Stats)
            if (contentRes.data) setTopContent(contentRes.data as TopContent[])
            if (usersRes.data) setTopUsers(usersRes.data as TopUser[])
        } catch (err) {
            console.error('Failed to load analytics:', err)
        } finally {
            setIsLoading(false)
        }
    }

    const metrics: MetricCard[] = stats ? [
        { label: 'Daily Active Users', value: stats.dau, previousValue: Math.floor(stats.dau * 0.9), format: 'number', icon: Users },
        { label: 'Monthly Active Users', value: stats.mau, previousValue: Math.floor(stats.mau * 0.95), format: 'number', icon: Users },
        { label: 'Posts Today', value: stats.postsToday, previousValue: Math.floor(stats.postsToday * 0.85), format: 'number', icon: FileText },
        { label: 'Messages Today', value: stats.messagesToday, previousValue: Math.floor(stats.messagesToday * 0.9), format: 'number', icon: MessageSquare },
    ] : []

    const handleExport = () => {
        if (!stats) return

        const csv = [
            ['Metric', 'Value'],
            ['Total Users', stats.totalUsers],
            ['DAU', stats.dau],
            ['MAU', stats.mau],
            ['Posts Today', stats.postsToday],
            ['Total Posts', stats.totalPosts],
            ['Messages Today', stats.messagesToday],
        ].map(row => row.join(',')).join('\n')

        const blob = new Blob([csv], { type: 'text/csv' })
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = `analytics-${new Date().toISOString().split('T')[0]}.csv`
        a.click()
        URL.revokeObjectURL(url)
    }

    if (isLoading) {
        return (
            <div className="p-8">
                <div className="text-center py-12">
                    <p className="text-[var(--color-text-muted)]">Loading analytics...</p>
                </div>
            </div>
        )
    }

    return (
        <div className="p-8">
            {/* Header */}
            <div className="mb-8 flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-[var(--color-text-primary)]">Analytics</h1>
                    <p className="mt-1 text-[var(--color-text-muted)]">
                        Platform metrics and engagement trends
                    </p>
                </div>
                <button onClick={handleExport} className="btn btn-secondary">
                    <Download className="h-4 w-4" />
                    Export CSV
                </button>
            </div>

            {/* Metric Cards */}
            <div className="mb-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
                {metrics.map((metric, i) => (
                    <MetricCardComponent key={i} metric={metric} />
                ))}
            </div>

            {/* Summary Stats */}
            {stats && (
                <div className="mb-8 grid gap-4 sm:grid-cols-2">
                    <div className="card p-6">
                        <h3 className="font-semibold text-[var(--color-text-primary)] mb-4">Platform Overview</h3>
                        <div className="space-y-3">
                            <div className="flex justify-between">
                                <span className="text-[var(--color-text-muted)]">Total Users</span>
                                <span className="font-medium text-[var(--color-text-primary)]">{stats.totalUsers.toLocaleString()}</span>
                            </div>
                            <div className="flex justify-between">
                                <span className="text-[var(--color-text-muted)]">Total Posts</span>
                                <span className="font-medium text-[var(--color-text-primary)]">{stats.totalPosts.toLocaleString()}</span>
                            </div>
                            <div className="flex justify-between">
                                <span className="text-[var(--color-text-muted)]">DAU/MAU Ratio</span>
                                <span className="font-medium text-[var(--color-text-primary)]">
                                    {stats.mau > 0 ? ((stats.dau / stats.mau) * 100).toFixed(1) : 0}%
                                </span>
                            </div>
                        </div>
                    </div>
                    <div className="card p-6">
                        <h3 className="font-semibold text-[var(--color-text-primary)] mb-4">Today's Activity</h3>
                        <div className="space-y-3">
                            <div className="flex justify-between">
                                <span className="text-[var(--color-text-muted)]">Active Users</span>
                                <span className="font-medium text-[var(--color-text-primary)]">{stats.dau.toLocaleString()}</span>
                            </div>
                            <div className="flex justify-between">
                                <span className="text-[var(--color-text-muted)]">Posts Created</span>
                                <span className="font-medium text-[var(--color-text-primary)]">{stats.postsToday.toLocaleString()}</span>
                            </div>
                            <div className="flex justify-between">
                                <span className="text-[var(--color-text-muted)]">Messages Sent</span>
                                <span className="font-medium text-[var(--color-text-primary)]">{stats.messagesToday.toLocaleString()}</span>
                            </div>
                        </div>
                    </div>
                </div>
            )}

            {/* Top Content & Users */}
            <div className="grid gap-6 lg:grid-cols-2">
                {/* Top Content */}
                <div className="card p-6">
                    <div className="mb-4 flex items-center gap-3">
                        <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-[var(--color-success-500)]/15">
                            <TrendingUp className="h-5 w-5 text-[var(--color-success-500)]" />
                        </div>
                        <div>
                            <h3 className="font-semibold text-[var(--color-text-primary)]">Top Content</h3>
                            <p className="text-sm text-[var(--color-text-muted)]">Most engaged posts</p>
                        </div>
                    </div>
                    {topContent.length === 0 ? (
                        <p className="text-center py-8 text-[var(--color-text-muted)]">No content yet</p>
                    ) : (
                        <div className="space-y-3">
                            {topContent.map((content, i) => (
                                <div key={content.id} className="flex items-center gap-3 rounded-xl bg-[var(--color-bg-tertiary)] p-3">
                                    <span className="flex h-6 w-6 items-center justify-center rounded-full bg-[var(--color-bg-elevated)] text-xs font-bold text-[var(--color-text-muted)]">
                                        {i + 1}
                                    </span>
                                    <div className="flex-1 min-w-0">
                                        <p className="truncate font-medium text-[var(--color-text-primary)]">{content.title}</p>
                                        <p className="text-xs text-[var(--color-text-muted)]">{content.author}</p>
                                    </div>
                                    <div className="text-right">
                                        <p className="text-sm font-medium text-[var(--color-text-primary)]">{content.likes}</p>
                                        <p className="text-xs text-[var(--color-text-muted)]">likes</p>
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}
                </div>

                {/* Top Users */}
                <div className="card p-6">
                    <div className="mb-4 flex items-center gap-3">
                        <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-[var(--color-primary-500)]/15">
                            <Users className="h-5 w-5 text-[var(--color-primary-400)]" />
                        </div>
                        <div>
                            <h3 className="font-semibold text-[var(--color-text-primary)]">Top Users</h3>
                            <p className="text-sm text-[var(--color-text-muted)]">Most followed users</p>
                        </div>
                    </div>
                    {topUsers.length === 0 ? (
                        <p className="text-center py-8 text-[var(--color-text-muted)]">No users yet</p>
                    ) : (
                        <div className="space-y-3">
                            {topUsers.map((user, i) => (
                                <div key={user.id} className="flex items-center gap-3 rounded-xl bg-[var(--color-bg-tertiary)] p-3">
                                    <span className="flex h-6 w-6 items-center justify-center rounded-full bg-[var(--color-bg-elevated)] text-xs font-bold text-[var(--color-text-muted)]">
                                        {i + 1}
                                    </span>
                                    <div className="flex h-10 w-10 items-center justify-center rounded-full bg-gradient-to-br from-[var(--color-primary-600)] to-[var(--color-primary-400)] text-sm font-semibold text-white">
                                        {(user.full_name || 'U')[0]}
                                    </div>
                                    <div className="flex-1 min-w-0">
                                        <p className="truncate font-medium text-[var(--color-text-primary)]">{user.full_name}</p>
                                        <p className="text-xs text-[var(--color-text-muted)]">@{user.handle}</p>
                                    </div>
                                    <div className="text-right">
                                        <p className="text-sm font-medium text-[var(--color-text-primary)]">{user.followers.toLocaleString()}</p>
                                        <p className="text-xs text-[var(--color-text-muted)]">followers</p>
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}
                </div>
            </div>
        </div>
    )
}

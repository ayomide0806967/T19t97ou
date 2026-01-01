import { useCallback, useEffect, useMemo, useState } from 'react'
import { type ColumnDef } from '@tanstack/react-table'
import { Eye, Flame, RefreshCw, ShieldAlert, Sliders, Trash2, Undo2 } from 'lucide-react'
import { DataTable } from '@/components/DataTable'
import { adminPosts, adminSettings } from '@/lib/edge-functions'
import { cn, formatDate } from '@/lib/utils'
import type { AdminRole } from '@/types/database'
import { moderationDefaults } from '@/lib/moderationDefaults'

type AdminPostRow = {
    id: string
    author_id: string
    handle: string
    author_name: string
    author_avatar_url: string | null
    body: string
    visibility: 'public' | 'followers' | 'class'
    created_at: string
    deleted_at: string | null
    like_count: number
    repost_count: number
    reply_count: number
    bookmark_count: number
    media_urls: string[]
    removed_reason: string | null
    trending_multiplier: number | null
    exclude_from_trending: boolean | null
    trending_note?: string | null
    trend_score?: number
}

export function PostsPage({ role }: { role: AdminRole }) {
    const [tab, setTab] = useState<'trending' | 'all'>('trending')
    const [rows, setRows] = useState<AdminPostRow[]>([])
    const [isLoading, setIsLoading] = useState(true)
    const [status, setStatus] = useState<'active' | 'removed' | 'all'>('active')
    const [query, setQuery] = useState('')

    const [selectedPost, setSelectedPost] = useState<AdminPostRow | null>(null)
    const [postToRemove, setPostToRemove] = useState<AdminPostRow | null>(null)
    const [postToRestore, setPostToRestore] = useState<AdminPostRow | null>(null)
    const [postToTrend, setPostToTrend] = useState<AdminPostRow | null>(null)
    const [removalReasons, setRemovalReasons] = useState<string[]>(moderationDefaults.posts.default_removal_reasons)
    const [allowRestore, setAllowRestore] = useState<boolean>(moderationDefaults.posts.allow_restore_post)
    const [requireReason, setRequireReason] = useState<boolean>(moderationDefaults.posts.require_removal_reason)

    const canModerate = role === 'moderator' || role === 'super_admin'
    const canTrendOverride = role === 'super_admin'

    const loadModerationSettings = useCallback(async () => {
        try {
            const { data, error } = await adminSettings.list('moderation.posts')
            if (error) throw new Error(error)
            const rows = (data as Array<{ key: string; value: Record<string, unknown> }> | null) || []
            const row = rows.find(r => r.key === 'moderation.posts')
            const value = row?.value || {}
            const reasons = Array.isArray(value.default_removal_reasons) ? (value.default_removal_reasons as string[]) : null
            if (reasons && reasons.length > 0) setRemovalReasons(reasons)
            if (typeof value.allow_restore_post === 'boolean') setAllowRestore(value.allow_restore_post)
            if (typeof value.require_removal_reason === 'boolean') setRequireReason(value.require_removal_reason)
        } catch (err) {
            console.error('Failed to load moderation.posts settings:', err)
        }
    }, [])

    const load = useCallback(async () => {
        setIsLoading(true)
        try {
            if (tab === 'trending') {
                const { data, error } = await adminPosts.trending(25)
                if (error) throw new Error(error)
                setRows((data as AdminPostRow[]) || [])
            } else {
                const { data, error } = await adminPosts.list({ limit: 200, status, query: query.trim() || undefined })
                if (error) throw new Error(error)
                setRows((data as AdminPostRow[]) || [])
            }
        } catch (err) {
            console.error('Failed to load posts:', err)
        } finally {
            setIsLoading(false)
        }
    }, [query, status, tab])

    useEffect(() => {
        void load()
    }, [load])

    useEffect(() => {
        void loadModerationSettings()
    }, [loadModerationSettings])

    const columns = useMemo<ColumnDef<AdminPostRow>[]>(() => [
        {
            accessorKey: 'body',
            header: 'Post',
            cell: ({ row }) => (
                <div className="min-w-[340px]">
                    <div className="flex items-center gap-2">
                        <p className="font-medium text-[var(--color-text-primary)]">
                            {row.original.author_name || row.original.handle}
                        </p>
                        <span className="text-xs text-[var(--color-text-muted)]">@{row.original.handle}</span>
                        {row.original.visibility !== 'public' && (
                            <span className="badge badge-info text-xs">{row.original.visibility}</span>
                        )}
                        {row.original.deleted_at && (
                            <span className="badge badge-danger text-xs">Removed</span>
                        )}
                        {row.original.exclude_from_trending && (
                            <span className="badge badge-info text-xs">Excluded</span>
                        )}
                        {row.original.trending_multiplier && row.original.trending_multiplier !== 1 && (
                            <span className="badge badge-warning text-xs">{row.original.trending_multiplier}x</span>
                        )}
                    </div>
                    <p className="mt-1 line-clamp-2 text-sm text-[var(--color-text-secondary)]">
                        {row.original.body}
                    </p>
                    {row.original.removed_reason && (
                        <p className="mt-1 text-xs text-[var(--color-danger-500)]">
                            Reason: {row.original.removed_reason}
                        </p>
                    )}
                </div>
            ),
        },
        {
            id: 'engagement',
            header: 'Engagement',
            cell: ({ row }) => (
                <div className="text-xs text-[var(--color-text-secondary)] space-y-1">
                    <div>Likes: <span className="text-[var(--color-text-primary)]">{row.original.like_count}</span></div>
                    <div>Reposts: <span className="text-[var(--color-text-primary)]">{row.original.repost_count}</span></div>
                    <div>Replies: <span className="text-[var(--color-text-primary)]">{row.original.reply_count}</span></div>
                    <div>Bookmarks: <span className="text-[var(--color-text-primary)]">{row.original.bookmark_count}</span></div>
                </div>
            ),
        },
        {
            accessorKey: 'created_at',
            header: 'Created',
            cell: ({ row }) => (
                <span className="text-sm text-[var(--color-text-muted)]">
                    {formatDate(row.original.created_at)}
                </span>
            ),
        },
        ...(tab === 'trending'
            ? [{
                accessorKey: 'trend_score' as const,
                header: 'Trend',
                cell: ({ row }: { row: { original: AdminPostRow } }) => (
                    <span className="text-sm text-[var(--color-text-secondary)]">
                        {(row.original.trend_score ?? 0).toFixed(2)}
                    </span>
                ),
            } satisfies ColumnDef<AdminPostRow>]
            : []),
        {
            id: 'actions',
            header: '',
            cell: ({ row }) => (
                <div className="flex items-center justify-end gap-1">
                    <button
                        onClick={() => setSelectedPost(row.original)}
                        className="btn-ghost rounded-lg p-2"
                        title="View"
                    >
                        <Eye className="h-4 w-4" />
                    </button>

                    {canTrendOverride && (
                        <button
                            onClick={() => setPostToTrend(row.original)}
                            className="btn-ghost rounded-lg p-2"
                            title="Trending controls"
                        >
                            <Sliders className="h-4 w-4" />
                        </button>
                    )}

                    {canModerate && !row.original.deleted_at && (
                        <button
                            onClick={() => setPostToRemove(row.original)}
                            className="btn-ghost rounded-lg p-2 text-[var(--color-danger-500)]"
                            title="Take down"
                        >
                            <Trash2 className="h-4 w-4" />
                        </button>
                    )}

                    {canModerate && allowRestore && row.original.deleted_at && (
                        <button
                            onClick={() => setPostToRestore(row.original)}
                            className="btn-ghost rounded-lg p-2"
                            title="Restore"
                        >
                            <Undo2 className="h-4 w-4" />
                        </button>
                    )}
                </div>
            ),
        },
    ], [allowRestore, canModerate, canTrendOverride, tab])

    return (
        <div className="p-8">
            <div className="mb-8 flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-[var(--color-text-primary)]">Posts</h1>
                    <p className="mt-1 text-[var(--color-text-muted)]">
                        Trending, moderation, and engagement controls
                    </p>
                </div>

                <div className="flex items-center gap-2">
                    <button
                        onClick={load}
                        className="btn btn-secondary"
                        disabled={isLoading}
                    >
                        <RefreshCw className={cn('h-4 w-4', isLoading && 'animate-spin')} />
                        Refresh
                    </button>
                </div>
            </div>

            <div className="mb-5 flex flex-wrap items-center gap-2">
                <button
                    onClick={() => setTab('trending')}
                    className={cn('btn', tab === 'trending' ? 'btn-primary' : 'btn-secondary')}
                >
                    <Flame className="h-4 w-4" />
                    Trending
                </button>
                <button
                    onClick={() => setTab('all')}
                    className={cn('btn', tab === 'all' ? 'btn-primary' : 'btn-secondary')}
                >
                    All Posts
                </button>

                {tab === 'all' && (
                    <div className="ml-auto flex items-center gap-2">
                        <select
                            value={status}
                            onChange={(e) => setStatus(e.target.value as typeof status)}
                            className="input h-10"
                        >
                            <option value="active">Active</option>
                            <option value="removed">Removed</option>
                            <option value="all">All</option>
                        </select>

                        <input
                            value={query}
                            onChange={(e) => setQuery(e.target.value)}
                            placeholder="Search posts or @handle…"
                            className="input h-10 w-64"
                        />
                        <button onClick={load} className="btn btn-secondary h-10">Search</button>
                    </div>
                )}
            </div>

            <div className="mb-6 rounded-xl border border-[var(--color-warning-500)]/30 bg-[var(--color-warning-500)]/10 p-4">
                <p className="text-sm text-[var(--color-warning-500)]">
                    <strong>Moderator:</strong> can take down / restore posts. <strong>Super Admin:</strong> can adjust trending multiplier and exclude posts from trending.
                </p>
            </div>

            <DataTable
                columns={columns}
                data={rows}
                searchKey="body"
                searchPlaceholder={tab === 'trending' ? 'Search trending posts…' : 'Search loaded posts…'}
                isLoading={isLoading}
            />

            {selectedPost && (
                <PostDetailModal post={selectedPost} onClose={() => setSelectedPost(null)} />
            )}
            {postToRemove && (
                <PostRemoveModal
                    post={postToRemove}
                    requireReason={requireReason}
                    reasons={removalReasons}
                    onClose={() => setPostToRemove(null)}
                    onRemoved={async () => {
                        setPostToRemove(null)
                        await load()
                    }}
                />
            )}
            {postToRestore && (
                <PostRestoreModal
                    post={postToRestore}
                    onClose={() => setPostToRestore(null)}
                    onRestored={async () => {
                        setPostToRestore(null)
                        await load()
                    }}
                />
            )}
            {postToTrend && (
                <PostTrendingModal
                    post={postToTrend}
                    onClose={() => setPostToTrend(null)}
                    onSaved={async () => {
                        setPostToTrend(null)
                        await load()
                    }}
                />
            )}
        </div>
    )
}

function PostDetailModal({ post, onClose }: { post: AdminPostRow; onClose: () => void }) {
    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
            <div className="glass w-full max-w-2xl rounded-2xl p-6 animate-fadeIn max-h-[80vh] overflow-auto">
                <div className="mb-5 flex items-start justify-between gap-4">
                    <div>
                        <h2 className="text-xl font-bold text-[var(--color-text-primary)]">Post</h2>
                        <p className="mt-1 text-sm text-[var(--color-text-muted)]">
                            @{post.handle} • {formatDate(post.created_at)}
                        </p>
                    </div>
                    <button onClick={onClose} className="btn-ghost rounded-lg p-2" title="Close">✕</button>
                </div>

                <div className="space-y-4">
                    {post.deleted_at && (
                        <div className="rounded-xl border border-[var(--color-danger-500)]/30 bg-[var(--color-danger-500)]/10 p-4 text-sm text-[var(--color-danger-500)]">
                            <div className="flex items-center gap-2">
                                <ShieldAlert className="h-4 w-4" />
                                <span>Removed</span>
                            </div>
                            {post.removed_reason && <div className="mt-1">Reason: {post.removed_reason}</div>}
                        </div>
                    )}

                    <div className="rounded-xl bg-[var(--color-bg-tertiary)] p-4">
                        <p className="text-sm text-[var(--color-text-primary)] whitespace-pre-wrap">{post.body}</p>
                    </div>

                    {post.media_urls?.length > 0 && (
                        <div className="grid grid-cols-2 gap-3">
                            {post.media_urls.map((url) => (
                                <a key={url} href={url} target="_blank" rel="noreferrer" className="block">
                                    <img src={url} alt="" className="h-40 w-full rounded-xl object-cover" />
                                </a>
                            ))}
                        </div>
                    )}

                    <div className="grid grid-cols-4 gap-3 text-xs">
                        <div className="rounded-xl bg-[var(--color-bg-tertiary)] p-3">
                            <div className="text-[var(--color-text-muted)]">Likes</div>
                            <div className="mt-1 font-semibold text-[var(--color-text-primary)]">{post.like_count}</div>
                        </div>
                        <div className="rounded-xl bg-[var(--color-bg-tertiary)] p-3">
                            <div className="text-[var(--color-text-muted)]">Reposts</div>
                            <div className="mt-1 font-semibold text-[var(--color-text-primary)]">{post.repost_count}</div>
                        </div>
                        <div className="rounded-xl bg-[var(--color-bg-tertiary)] p-3">
                            <div className="text-[var(--color-text-muted)]">Replies</div>
                            <div className="mt-1 font-semibold text-[var(--color-text-primary)]">{post.reply_count}</div>
                        </div>
                        <div className="rounded-xl bg-[var(--color-bg-tertiary)] p-3">
                            <div className="text-[var(--color-text-muted)]">Bookmarks</div>
                            <div className="mt-1 font-semibold text-[var(--color-text-primary)]">{post.bookmark_count}</div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    )
}

function PostRemoveModal({
    post,
    requireReason,
    reasons,
    onClose,
    onRemoved,
}: {
    post: AdminPostRow
    requireReason: boolean
    reasons: string[]
    onClose: () => void
    onRemoved: () => void | Promise<void>
}) {
    const [reason, setReason] = useState(reasons[0] || '')
    const [customReason, setCustomReason] = useState('')
    const [isSaving, setIsSaving] = useState(false)
    const [error, setError] = useState<string | null>(null)

    async function handleRemove() {
        setError(null)
        const chosen = (reason === '__custom__' ? customReason : reason).trim()
        if (requireReason && !chosen) {
            setError('Reason is required.')
            return
        }
        setIsSaving(true)
        try {
            const { error: apiError } = await adminPosts.remove(post.id, chosen || 'Removed by admin')
            if (apiError) throw new Error(apiError)
            await onRemoved()
        } catch (err) {
            setError(err instanceof Error ? err.message : 'Failed to remove post.')
        } finally {
            setIsSaving(false)
        }
    }

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
            <div className="glass w-full max-w-md rounded-2xl p-6 animate-fadeIn">
                <div className="mb-4 flex items-start justify-between">
                    <h2 className="text-xl font-bold text-[var(--color-text-primary)]">Take Down Post</h2>
                    <button onClick={onClose} className="btn-ghost rounded-lg p-2" disabled={isSaving}>✕</button>
                </div>

                <p className="text-sm text-[var(--color-text-secondary)]">
                    This will remove the post from the app. Provide a reason for the takedown.
                </p>

                {error && (
                    <div className="mt-4 rounded-xl border border-[var(--color-danger-500)]/30 bg-[var(--color-danger-500)]/10 p-3 text-sm text-[var(--color-danger-500)]">
                        {error}
                    </div>
                )}

                <div className="mt-4">
                    <label className="mb-2 block text-sm font-medium text-[var(--color-text-secondary)]">Reason</label>
                    <select
                        value={reason}
                        onChange={(e) => setReason(e.target.value)}
                        className="input"
                        disabled={isSaving}
                    >
                        {reasons.map((r) => (
                            <option key={r} value={r}>{r}</option>
                        ))}
                        <option value="__custom__">Other (custom)</option>
                    </select>
                    {reason === '__custom__' && (
                        <textarea
                            value={customReason}
                            onChange={(e) => setCustomReason(e.target.value)}
                            className="input min-h-[92px] mt-3"
                            placeholder="Write a custom reason…"
                            disabled={isSaving}
                        />
                    )}
                </div>

                <div className="mt-6 flex items-center justify-end gap-3">
                    <button onClick={onClose} className="btn btn-secondary" disabled={isSaving}>Cancel</button>
                    <button
                        onClick={handleRemove}
                        className="btn btn-danger disabled:opacity-50"
                        disabled={isSaving || (requireReason && (reason === '__custom__' ? !customReason.trim() : !reason.trim()))}
                    >
                        {isSaving ? 'Removing…' : 'Take Down'}
                    </button>
                </div>
            </div>
        </div>
    )
}

function PostRestoreModal({
    post,
    onClose,
    onRestored,
}: {
    post: AdminPostRow
    onClose: () => void
    onRestored: () => void | Promise<void>
}) {
    const [isSaving, setIsSaving] = useState(false)
    const [error, setError] = useState<string | null>(null)

    async function handleRestore() {
        setError(null)
        setIsSaving(true)
        try {
            const { error: apiError } = await adminPosts.restore(post.id)
            if (apiError) throw new Error(apiError)
            await onRestored()
        } catch (err) {
            setError(err instanceof Error ? err.message : 'Failed to restore post.')
        } finally {
            setIsSaving(false)
        }
    }

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
            <div className="glass w-full max-w-md rounded-2xl p-6 animate-fadeIn">
                <div className="mb-4 flex items-start justify-between">
                    <h2 className="text-xl font-bold text-[var(--color-text-primary)]">Restore Post</h2>
                    <button onClick={onClose} className="btn-ghost rounded-lg p-2" disabled={isSaving}>✕</button>
                </div>

                <p className="text-sm text-[var(--color-text-secondary)]">
                    Restore this post and make it visible again?
                </p>

                {error && (
                    <div className="mt-4 rounded-xl border border-[var(--color-danger-500)]/30 bg-[var(--color-danger-500)]/10 p-3 text-sm text-[var(--color-danger-500)]">
                        {error}
                    </div>
                )}

                <div className="mt-6 flex items-center justify-end gap-3">
                    <button onClick={onClose} className="btn btn-secondary" disabled={isSaving}>Cancel</button>
                    <button onClick={handleRestore} className="btn btn-primary disabled:opacity-50" disabled={isSaving}>
                        {isSaving ? 'Restoring…' : 'Restore'}
                    </button>
                </div>
            </div>
        </div>
    )
}

function PostTrendingModal({
    post,
    onClose,
    onSaved,
}: {
    post: AdminPostRow
    onClose: () => void
    onSaved: () => void | Promise<void>
}) {
    const [multiplier, setMultiplier] = useState(() => (post.trending_multiplier ?? 1).toString())
    const [exclude, setExclude] = useState(Boolean(post.exclude_from_trending))
    const [note, setNote] = useState(post.trending_note ?? '')
    const [isSaving, setIsSaving] = useState(false)
    const [error, setError] = useState<string | null>(null)

    async function handleSave() {
        setError(null)
        const m = Number(multiplier)
        if (!Number.isFinite(m) || m <= 0 || m > 10) {
            setError('Multiplier must be > 0 and <= 10.')
            return
        }

        setIsSaving(true)
        try {
            const { error: apiError } = await adminPosts.setTrending(post.id, m, exclude, note.trim() || null)
            if (apiError) throw new Error(apiError)
            await onSaved()
        } catch (err) {
            setError(err instanceof Error ? err.message : 'Failed to save trending settings.')
        } finally {
            setIsSaving(false)
        }
    }

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
            <div className="glass w-full max-w-md rounded-2xl p-6 animate-fadeIn">
                <div className="mb-4 flex items-start justify-between">
                    <h2 className="text-xl font-bold text-[var(--color-text-primary)]">Trending Controls</h2>
                    <button onClick={onClose} className="btn-ghost rounded-lg p-2" disabled={isSaving}>✕</button>
                </div>

                <p className="text-sm text-[var(--color-text-secondary)]">
                    Adjust trending boost/downrank and optionally exclude the post from trending.
                </p>

                {error && (
                    <div className="mt-4 rounded-xl border border-[var(--color-danger-500)]/30 bg-[var(--color-danger-500)]/10 p-3 text-sm text-[var(--color-danger-500)]">
                        {error}
                    </div>
                )}

                <div className="mt-4 space-y-4">
                    <div>
                        <label className="mb-2 block text-sm font-medium text-[var(--color-text-secondary)]">
                            Multiplier (0–10)
                        </label>
                        <input
                            type="number"
                            step="0.1"
                            min={0.1}
                            max={10}
                            value={multiplier}
                            onChange={(e) => setMultiplier(e.target.value)}
                            className="input"
                            disabled={isSaving}
                        />
                        <p className="mt-1 text-xs text-[var(--color-text-muted)]">
                            Use 1.0 for neutral, &gt;1 to boost, &lt;1 to downrank.
                        </p>
                    </div>

                    <label className="flex items-center justify-between rounded-xl bg-[var(--color-bg-tertiary)] p-4">
                        <div>
                            <p className="font-medium text-[var(--color-text-primary)]">Exclude From Trending</p>
                            <p className="text-xs text-[var(--color-text-muted)]">Keeps the post out of trending lists.</p>
                        </div>
                        <input type="checkbox" checked={exclude} onChange={(e) => setExclude(e.target.checked)} disabled={isSaving} />
                    </label>

                    <div>
                        <label className="mb-2 block text-sm font-medium text-[var(--color-text-secondary)]">
                            Note (optional)
                        </label>
                        <textarea
                            value={note}
                            onChange={(e) => setNote(e.target.value)}
                            className="input min-h-[80px]"
                            placeholder="Why this override exists…"
                            disabled={isSaving}
                        />
                    </div>
                </div>

                <div className="mt-6 flex items-center justify-end gap-3">
                    <button onClick={onClose} className="btn btn-secondary" disabled={isSaving}>Cancel</button>
                    <button onClick={handleSave} className="btn btn-primary disabled:opacity-50" disabled={isSaving}>
                        {isSaving ? 'Saving…' : 'Save'}
                    </button>
                </div>
            </div>
        </div>
    )
}

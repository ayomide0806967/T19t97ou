import { useState, useEffect } from 'react'
import { type ColumnDef } from '@tanstack/react-table'
import {
    Bell, Send, Users, Calendar, Check, X, Plus,
    Clock, Globe, User, BookOpen
} from 'lucide-react'
import { DataTable } from '@/components/DataTable'
import { adminBroadcasts, adminAudit } from '@/lib/edge-functions'
import { formatDate, cn } from '@/lib/utils'

// ============================================================================
// Types
// ============================================================================

interface Broadcast {
    id: string
    title: string
    body: string
    target_type: 'all' | 'class' | 'segment' | 'user'
    target_id: string | null
    target_name?: string
    status: 'draft' | 'scheduled' | 'sent' | 'failed'
    scheduled_at: string | null
    sent_at: string | null
    created_by: string
    recipient_count: number
    created_at: string
}

type TargetType = 'all' | 'class' | 'segment' | 'user'

// ============================================================================
// Components
// ============================================================================

function StatusBadge({ status }: { status: Broadcast['status'] }) {
    const styles = {
        draft: 'badge-primary',
        scheduled: 'badge-warning',
        sent: 'badge-success',
        failed: 'badge-danger',
    }
    const icons = {
        draft: Clock,
        scheduled: Calendar,
        sent: Check,
        failed: X,
    }
    const Icon = icons[status]
    return (
        <span className={cn('badge', styles[status])}>
            <Icon className="h-3 w-3" />
            {status.charAt(0).toUpperCase() + status.slice(1)}
        </span>
    )
}

function TargetBadge({ type, name }: { type: TargetType; name?: string }) {
    const icons = {
        all: Globe,
        class: BookOpen,
        segment: Users,
        user: User,
    }
    const labels = {
        all: 'All Users',
        class: name || 'Class',
        segment: name || 'Segment',
        user: name || 'User',
    }
    const Icon = icons[type]
    return (
        <span className="flex items-center gap-1.5 text-sm text-[var(--color-text-secondary)]">
            <Icon className="h-4 w-4" />
            {labels[type]}
        </span>
    )
}

interface ComposeModalProps {
    onClose: () => void
    onSend: (title: string, body: string, targetType: string, targetId?: string, scheduledAt?: string) => void
}

function ComposeModal({ onClose, onSend }: ComposeModalProps) {
    const [title, setTitle] = useState('')
    const [body, setBody] = useState('')
    const [targetType, setTargetType] = useState<TargetType>('all')
    const [targetId, setTargetId] = useState('')
    const [scheduleFor, setScheduleFor] = useState('')
    const [isSending, setIsSending] = useState(false)

    const handleSend = async () => {
        setIsSending(true)
        try {
            await onSend(title, body, targetType, targetType === 'all' ? undefined : targetId, scheduleFor || undefined)
            onClose()
        } finally {
            setIsSending(false)
        }
    }

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
            <div className="glass w-full max-w-xl rounded-2xl p-6 animate-fadeIn">
                {/* Header */}
                <div className="mb-6 flex items-start justify-between">
                    <div>
                        <h2 className="text-xl font-bold text-[var(--color-text-primary)]">
                            Compose Notification
                        </h2>
                        <p className="text-sm text-[var(--color-text-muted)]">
                            Send a push notification to users
                        </p>
                    </div>
                    <button onClick={onClose} className="btn-ghost rounded-lg p-2">
                        <X className="h-5 w-5" />
                    </button>
                </div>

                {/* Form */}
                <div className="space-y-4">
                    {/* Title */}
                    <div>
                        <label className="mb-1.5 block text-xs font-medium text-[var(--color-text-secondary)]">
                            Title
                        </label>
                        <input
                            type="text"
                            value={title}
                            onChange={(e) => setTitle(e.target.value)}
                            placeholder="Notification title..."
                            className="input"
                            maxLength={100}
                        />
                    </div>

                    {/* Body */}
                    <div>
                        <label className="mb-1.5 block text-xs font-medium text-[var(--color-text-secondary)]">
                            Message
                        </label>
                        <textarea
                            value={body}
                            onChange={(e) => setBody(e.target.value)}
                            placeholder="Write your message..."
                            className="input min-h-[100px]"
                            maxLength={500}
                        />
                        <p className="mt-1 text-xs text-[var(--color-text-muted)]">
                            {body.length}/500 characters
                        </p>
                    </div>

                    {/* Target */}
                    <div>
                        <label className="mb-1.5 block text-xs font-medium text-[var(--color-text-secondary)]">
                            Target Audience
                        </label>
                        <div className="grid grid-cols-4 gap-2">
                            {(['all', 'class', 'segment', 'user'] as TargetType[]).map((type) => {
                                const icons = { all: Globe, class: BookOpen, segment: Users, user: User }
                                const Icon = icons[type]
                                return (
                                    <button
                                        key={type}
                                        onClick={() => setTargetType(type)}
                                        className={cn(
                                            'flex flex-col items-center gap-1 rounded-xl p-3 transition-all',
                                            targetType === type
                                                ? 'bg-[var(--color-primary-500)]/15 text-[var(--color-primary-400)] ring-1 ring-[var(--color-primary-500)]'
                                                : 'bg-[var(--color-bg-tertiary)] text-[var(--color-text-secondary)] hover:bg-[var(--color-bg-elevated)]'
                                        )}
                                    >
                                        <Icon className="h-5 w-5" />
                                        <span className="text-xs capitalize">{type === 'all' ? 'Everyone' : type}</span>
                                    </button>
                                )
                            })}
                        </div>
                    </div>

                    {/* Target ID (if not all) */}
                    {targetType !== 'all' && (
                        <div>
                            <label className="mb-1.5 block text-xs font-medium text-[var(--color-text-secondary)]">
                                {targetType === 'class' ? 'Class Name/ID' : targetType === 'user' ? 'User Handle' : 'Segment Name'}
                            </label>
                            <input
                                type="text"
                                value={targetId}
                                onChange={(e) => setTargetId(e.target.value)}
                                placeholder={`Enter ${targetType} identifier...`}
                                className="input"
                            />
                        </div>
                    )}

                    {/* Schedule */}
                    <div>
                        <label className="mb-1.5 block text-xs font-medium text-[var(--color-text-secondary)]">
                            Schedule (optional)
                        </label>
                        <input
                            type="datetime-local"
                            value={scheduleFor}
                            onChange={(e) => setScheduleFor(e.target.value)}
                            className="input"
                        />
                        <p className="mt-1 text-xs text-[var(--color-text-muted)]">
                            Leave empty to send immediately
                        </p>
                    </div>
                </div>

                {/* Actions */}
                <div className="mt-6 flex items-center gap-3">
                    <button
                        onClick={handleSend}
                        disabled={!title.trim() || !body.trim() || isSending}
                        className="btn btn-primary disabled:opacity-50"
                    >
                        <Send className="h-4 w-4" />
                        {scheduleFor ? 'Schedule' : 'Send Now'}
                    </button>
                </div>
            </div>
        </div>
    )
}

// ============================================================================
// Main Page
// ============================================================================

export function NotificationsPage() {
    const [broadcasts, setBroadcasts] = useState<Broadcast[]>([])
    const [isLoading, setIsLoading] = useState(true)
    const [isComposeOpen, setIsComposeOpen] = useState(false)

    useEffect(() => {
        loadBroadcasts()
    }, [])

    async function loadBroadcasts() {
        setIsLoading(true)
        try {
            const res = await adminBroadcasts.list(50)
            if (res.data) {
                setBroadcasts(res.data as Broadcast[])
            }
        } catch (err) {
            console.error('Failed to load broadcasts:', err)
        } finally {
            setIsLoading(false)
        }
    }

    const stats = {
        sent: broadcasts.filter(n => n.status === 'sent').length,
        scheduled: broadcasts.filter(n => n.status === 'scheduled').length,
        totalRecipients: broadcasts
            .filter(n => n.status === 'sent')
            .reduce((acc, n) => acc + n.recipient_count, 0),
    }

    async function handleSend(title: string, body: string, targetType: string, targetId?: string, scheduledAt?: string) {
        try {
            await adminBroadcasts.create(title, body, targetType, targetId, scheduledAt)

            // Log action
            await adminAudit.log(
                'broadcast_sent',
                'broadcast',
                null,
                null,
                { title, target_type: targetType }
            )

            await loadBroadcasts()
        } catch (err) {
            console.error('Failed to send broadcast:', err)
        }
    }

    const columns: ColumnDef<Broadcast>[] = [
        {
            accessorKey: 'title',
            header: 'Notification',
            cell: ({ row }) => (
                <div>
                    <p className="font-medium text-[var(--color-text-primary)]">{row.original.title}</p>
                    <p className="text-xs text-[var(--color-text-muted)] line-clamp-1">{row.original.body}</p>
                </div>
            ),
        },
        {
            accessorKey: 'target_type',
            header: 'Target',
            cell: ({ row }) => (
                <TargetBadge type={row.original.target_type} name={row.original.target_name} />
            ),
        },
        {
            accessorKey: 'recipient_count',
            header: 'Recipients',
            cell: ({ row }) => (
                <span className="text-sm text-[var(--color-text-primary)]">
                    {row.original.recipient_count.toLocaleString()}
                </span>
            ),
        },
        {
            accessorKey: 'status',
            header: 'Status',
            cell: ({ row }) => <StatusBadge status={row.original.status} />,
        },
        {
            accessorKey: 'sent_at',
            header: 'Sent',
            cell: ({ row }) => (
                <span className="text-sm text-[var(--color-text-muted)]">
                    {row.original.sent_at
                        ? formatDate(row.original.sent_at)
                        : row.original.scheduled_at
                            ? `Scheduled: ${formatDate(row.original.scheduled_at)}`
                            : '-'}
                </span>
            ),
        },
    ]

    return (
        <div className="p-8">
            {/* Header */}
            <div className="mb-8 flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-[var(--color-text-primary)]">Notifications</h1>
                    <p className="mt-1 text-[var(--color-text-muted)]">
                        Send announcements and targeted messages
                    </p>
                </div>
                <button onClick={() => setIsComposeOpen(true)} className="btn btn-primary">
                    <Plus className="h-4 w-4" />
                    Compose
                </button>
            </div>

            {/* Stats */}
            <div className="mb-6 grid gap-4 sm:grid-cols-3">
                <div className="card p-4">
                    <div className="flex items-center gap-3">
                        <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-[var(--color-success-500)]/15">
                            <Check className="h-5 w-5 text-[var(--color-success-500)]" />
                        </div>
                        <div>
                            <p className="text-2xl font-bold text-[var(--color-text-primary)]">{stats.sent}</p>
                            <p className="text-xs text-[var(--color-text-muted)]">Sent</p>
                        </div>
                    </div>
                </div>
                <div className="card p-4">
                    <div className="flex items-center gap-3">
                        <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-[var(--color-warning-500)]/15">
                            <Calendar className="h-5 w-5 text-[var(--color-warning-500)]" />
                        </div>
                        <div>
                            <p className="text-2xl font-bold text-[var(--color-text-primary)]">{stats.scheduled}</p>
                            <p className="text-xs text-[var(--color-text-muted)]">Scheduled</p>
                        </div>
                    </div>
                </div>
                <div className="card p-4">
                    <div className="flex items-center gap-3">
                        <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-[var(--color-primary-500)]/15">
                            <Users className="h-5 w-5 text-[var(--color-primary-400)]" />
                        </div>
                        <div>
                            <p className="text-2xl font-bold text-[var(--color-text-primary)]">{stats.totalRecipients.toLocaleString()}</p>
                            <p className="text-xs text-[var(--color-text-muted)]">Total Recipients</p>
                        </div>
                    </div>
                </div>
            </div>

            {/* Broadcasts Table */}
            <div className="card p-6">
                <div className="mb-4 flex items-center gap-3">
                    <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-[var(--color-primary-500)]/15">
                        <Bell className="h-5 w-5 text-[var(--color-primary-400)]" />
                    </div>
                    <div>
                        <h2 className="font-semibold text-[var(--color-text-primary)]">Notification History</h2>
                        <p className="text-sm text-[var(--color-text-muted)]">All sent and scheduled notifications</p>
                    </div>
                </div>

                {broadcasts.length === 0 && !isLoading ? (
                    <div className="text-center py-12">
                        <Bell className="mx-auto h-12 w-12 text-[var(--color-text-muted)] opacity-50" />
                        <p className="mt-4 text-[var(--color-text-muted)]">No broadcasts sent yet</p>
                    </div>
                ) : (
                    <DataTable
                        columns={columns}
                        data={broadcasts}
                        searchKey="title"
                        searchPlaceholder="Search notifications..."
                        isLoading={isLoading}
                    />
                )}
            </div>

            {/* Compose Modal */}
            {isComposeOpen && (
                <ComposeModal
                    onClose={() => setIsComposeOpen(false)}
                    onSend={handleSend}
                />
            )}
        </div>
    )
}

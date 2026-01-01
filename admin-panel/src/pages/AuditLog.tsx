import { useState, useEffect } from 'react'
import { type ColumnDef } from '@tanstack/react-table'
import { Activity, User, FileText, Trash2, Edit, Shield, Eye } from 'lucide-react'
import { DataTable } from '@/components/DataTable'
import { adminAudit } from '@/lib/edge-functions'
import { formatDate, cn } from '@/lib/utils'
import type { AuditLog } from '@/types/database'

const actionIcons: Record<string, typeof Activity> = {
    'set-verification': Shield,
    'update-profile': Edit,
    'lock-user': User,
    'unlock-user': User,
    'set-boost': Activity,
    'delete-file': Trash2,
    'delete-files': Trash2,
    'remove-content': Trash2,
    'restore-content': Activity,
    'create-plan': FileText,
    'update-plan': Edit,
    'delete-plan': Trash2,
    'add-admin': Shield,
    'set-admin-active': Shield,
    'set-admin-dm-access': Shield,
    'set-admin-role': Shield,
    'update-settings': Edit,
}

export function AuditLogPage() {
    const [logs, setLogs] = useState<AuditLog[]>([])
    const [isLoading, setIsLoading] = useState(true)
    const [selectedLog, setSelectedLog] = useState<AuditLog | null>(null)

    useEffect(() => {
        loadLogs()
    }, [])

    async function loadLogs() {
        setIsLoading(true)
        try {
            const { data, error } = await adminAudit.list(500)
            if (error) throw new Error(error)
            setLogs((data as AuditLog[]) || [])
        } catch (err) {
            console.error('Failed to load audit logs:', err)
        } finally {
            setIsLoading(false)
        }
    }

    const columns: ColumnDef<AuditLog>[] = [
        {
            accessorKey: 'action',
            header: 'Action',
            cell: ({ row }) => {
                const action = row.original.action
                const Icon = actionIcons[action] || Activity
                return (
                    <div className="flex items-center gap-3">
                        <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-[var(--color-bg-tertiary)]">
                            <Icon className="h-4 w-4 text-[var(--color-text-muted)]" />
                        </div>
                        <span className="font-medium text-[var(--color-text-primary)]">{action}</span>
                    </div>
                )
            },
        },
        {
            accessorKey: 'actor_role',
            header: 'Actor',
            cell: ({ row }) => (
                <div>
                    <span className={cn(
                        'badge',
                        row.original.actor_role === 'super_admin' && 'badge-warning',
                        row.original.actor_role === 'moderator' && 'badge-info',
                        row.original.actor_role === 'support' && 'badge-primary'
                    )}>
                        {row.original.actor_role}
                    </span>
                </div>
            ),
        },
        {
            accessorKey: 'target_type',
            header: 'Target',
            cell: ({ row }) => (
                <div className="text-sm">
                    <span className="text-[var(--color-text-secondary)]">
                        {row.original.target_type || '-'}
                    </span>
                    {row.original.target_id && (
                        <p className="text-xs text-[var(--color-text-muted)] font-mono">
                            {row.original.target_id.substring(0, 8)}...
                        </p>
                    )}
                </div>
            ),
        },
        {
            accessorKey: 'created_at',
            header: 'Time',
            cell: ({ row }) => (
                <span className="text-sm text-[var(--color-text-muted)]">
                    {formatDate(row.original.created_at)}
                </span>
            ),
        },
        {
            id: 'actions',
            header: '',
            cell: ({ row }) => (
                <button
                    onClick={() => setSelectedLog(row.original)}
                    className="btn-ghost rounded-lg p-2"
                    title="View details"
                >
                    <Eye className="h-4 w-4" />
                </button>
            ),
        },
    ]

    return (
        <div className="p-8">
            {/* Header */}
            <div className="mb-8">
                <h1 className="text-2xl font-bold text-[var(--color-text-primary)]">Audit Log</h1>
                <p className="mt-1 text-[var(--color-text-muted)]">
                    Track all admin actions and changes
                </p>
            </div>

            {/* Table */}
            <DataTable
                columns={columns}
                data={logs}
                searchKey="action"
                searchPlaceholder="Search by action..."
                isLoading={isLoading}
            />

            {/* Detail Modal */}
            {selectedLog && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
                    <div className="glass w-full max-w-2xl rounded-2xl p-6 animate-fadeIn max-h-[80vh] overflow-auto">
                        <div className="mb-6 flex items-start justify-between">
                            <div>
                                <h2 className="text-xl font-bold text-[var(--color-text-primary)]">
                                    {selectedLog.action}
                                </h2>
                                <p className="text-sm text-[var(--color-text-muted)]">
                                    {formatDate(selectedLog.created_at)}
                                </p>
                            </div>
                            <button
                                onClick={() => setSelectedLog(null)}
                                className="btn-ghost rounded-lg p-2"
                            >
                                ✕
                            </button>
                        </div>

                        <div className="space-y-4">
                            <div className="grid grid-cols-2 gap-4">
                                <div className="rounded-xl bg-[var(--color-bg-tertiary)] p-4">
                                    <p className="text-xs text-[var(--color-text-muted)]">Actor Role</p>
                                    <p className="mt-1 font-medium text-[var(--color-text-primary)]">
                                        {selectedLog.actor_role}
                                    </p>
                                </div>
                                <div className="rounded-xl bg-[var(--color-bg-tertiary)] p-4">
                                    <p className="text-xs text-[var(--color-text-muted)]">Actor ID</p>
                                    <p className="mt-1 font-mono text-sm text-[var(--color-text-primary)]">
                                        {selectedLog.actor_user_id}
                                    </p>
                                </div>
                            </div>

                            {selectedLog.target_type && (
                                <div className="rounded-xl bg-[var(--color-bg-tertiary)] p-4">
                                    <p className="text-xs text-[var(--color-text-muted)]">Target</p>
                                    <p className="mt-1 text-[var(--color-text-primary)]">
                                        {selectedLog.target_type}: <span className="font-mono text-sm">{selectedLog.target_id}</span>
                                    </p>
                                </div>
                            )}

                            {selectedLog.before_json && (
                                <div className="rounded-xl bg-[var(--color-bg-tertiary)] p-4">
                                    <p className="mb-2 text-xs text-[var(--color-text-muted)]">Before State</p>
                                    <pre className="overflow-auto rounded-lg bg-[var(--color-bg-primary)] p-3 text-xs text-[var(--color-text-secondary)]">
                                        {JSON.stringify(selectedLog.before_json, null, 2)}
                                    </pre>
                                </div>
                            )}

                            {selectedLog.after_json && (
                                <div className="rounded-xl bg-[var(--color-bg-tertiary)] p-4">
                                    <p className="mb-2 text-xs text-[var(--color-text-muted)]">After State</p>
                                    <pre className="overflow-auto rounded-lg bg-[var(--color-bg-primary)] p-3 text-xs text-[var(--color-text-secondary)]">
                                        {JSON.stringify(selectedLog.after_json, null, 2)}
                                    </pre>
                                </div>
                            )}

                            {(selectedLog.ip || selectedLog.user_agent) && (
                                <div className="rounded-xl bg-[var(--color-bg-tertiary)] p-4">
                                    <p className="mb-2 text-xs text-[var(--color-text-muted)]">Request</p>
                                    <div className="space-y-1 text-xs text-[var(--color-text-secondary)]">
                                        {selectedLog.ip && <div>IP: <span className="font-mono">{selectedLog.ip}</span></div>}
                                        {selectedLog.user_agent && <div>User Agent: <span className="font-mono">{selectedLog.user_agent}</span></div>}
                                    </div>
                                </div>
                            )}
                        </div>
                    </div>
                </div>
            )}
        </div>
    )
}

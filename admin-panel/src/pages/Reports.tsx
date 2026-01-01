import { useState, useEffect } from 'react'
import { type ColumnDef } from '@tanstack/react-table'
import {
    Flag, AlertTriangle, Eye, Check, X, Trash2, Ban, MessageSquare, Filter, User, FileText
} from 'lucide-react'
import { DataTable } from '@/components/DataTable'
import { adminReports, adminAudit } from '@/lib/edge-functions'
import { formatDate, cn } from '@/lib/utils'

// ============================================================================
// Types
// ============================================================================

interface Report {
    id: string
    reporter_id: string
    reporter: {
        id: string
        handle: string
        full_name: string
        avatar_url: string | null
    } | null
    content_type: 'post' | 'comment' | 'user' | 'message'
    content_id: string
    reason: string
    description: string | null
    status: 'pending' | 'reviewed' | 'dismissed' | 'actioned'
    reviewed_by: string | null
    reviewed_at: string | null
    created_at: string
    resolution_notes?: string | null
    action_taken?: string | null
}

type ReportStatus = 'all' | 'pending' | 'reviewed' | 'dismissed' | 'actioned'

// ============================================================================
// Components
// ============================================================================

function StatusBadge({ status }: { status: Report['status'] }) {
    const styles = {
        pending: 'badge-warning',
        reviewed: 'badge-info',
        dismissed: 'badge-primary',
        actioned: 'badge-success',
    }
    return (
        <span className={cn('badge', styles[status])}>
            {status.charAt(0).toUpperCase() + status.slice(1)}
        </span>
    )
}

function ContentTypeBadge({ type }: { type: Report['content_type'] }) {
    const icons = {
        post: FileText,
        comment: MessageSquare,
        user: User,
        message: MessageSquare,
    }
    const Icon = icons[type]
    return (
        <span className="flex items-center gap-1 text-xs text-[var(--color-text-muted)]">
            <Icon className="h-3 w-3" />
            {type}
        </span>
    )
}

interface ReportDetailModalProps {
    report: Report
    onClose: () => void
    onAction: (action: 'dismiss' | 'remove_content' | 'warn_user' | 'ban_user') => void
}

function ReportDetailModal({ report, onClose, onAction }: ReportDetailModalProps) {
    const [actionReason, setActionReason] = useState('')

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
            <div className="glass w-full max-w-2xl rounded-2xl p-6 animate-fadeIn max-h-[90vh] overflow-y-auto">
                {/* Header */}
                <div className="mb-6 flex items-start justify-between">
                    <div>
                        <h2 className="text-xl font-bold text-[var(--color-text-primary)]">
                            Report Details
                        </h2>
                        <p className="text-sm text-[var(--color-text-muted)]">
                            Reported {formatDate(report.created_at)}
                        </p>
                    </div>
                    <button onClick={onClose} className="btn-ghost rounded-lg p-2">
                        <X className="h-5 w-5" />
                    </button>
                </div>

                {/* Report Info */}
                <div className="space-y-4">
                    {/* Status & Type */}
                    <div className="flex items-center gap-4">
                        <StatusBadge status={report.status} />
                        <ContentTypeBadge type={report.content_type} />
                        <span className="badge badge-danger">{report.reason}</span>
                    </div>

                    {/* Reporter */}
                    <div className="rounded-xl bg-[var(--color-bg-tertiary)] p-4">
                        <p className="text-xs font-medium text-[var(--color-text-muted)] mb-2">Reported by</p>
                        <div className="flex items-center gap-3">
                            <div className="flex h-10 w-10 items-center justify-center rounded-full bg-gradient-to-br from-[var(--color-primary-600)] to-[var(--color-primary-400)] text-sm font-semibold text-white">
                                {(report.reporter?.full_name || 'U')[0].toUpperCase()}
                            </div>
                            <div>
                                <p className="font-medium text-[var(--color-text-primary)]">
                                    {report.reporter?.full_name || 'Unknown'}
                                </p>
                                <p className="text-xs text-[var(--color-text-muted)]">
                                    @{report.reporter?.handle || 'unknown'}
                                </p>
                            </div>
                        </div>
                    </div>

                    {/* Description */}
                    {report.description && (
                        <div className="rounded-xl bg-[var(--color-bg-tertiary)] p-4">
                            <p className="text-xs font-medium text-[var(--color-text-muted)] mb-2">Description</p>
                            <p className="text-sm text-[var(--color-text-primary)]">{report.description}</p>
                        </div>
                    )}

                    {/* Action Reason */}
                    {report.status === 'pending' && (
                        <div>
                            <label className="mb-1.5 block text-xs font-medium text-[var(--color-text-secondary)]">
                                Action reason (optional)
                            </label>
                            <textarea
                                value={actionReason}
                                onChange={(e) => setActionReason(e.target.value)}
                                placeholder="Add notes about your decision..."
                                className="input min-h-[80px] text-sm"
                            />
                        </div>
                    )}
                </div>

                {/* Actions */}
                {report.status === 'pending' && (
                    <div className="mt-6 flex flex-wrap gap-3">
                        <button
                            onClick={() => onAction('dismiss')}
                            className="btn btn-secondary"
                        >
                            <X className="h-4 w-4" />
                            Dismiss
                        </button>
                        <button
                            onClick={() => onAction('remove_content')}
                            className="btn btn-secondary"
                        >
                            <Trash2 className="h-4 w-4" />
                            Remove Content
                        </button>
                        <button
                            onClick={() => onAction('warn_user')}
                            className="btn btn-secondary"
                        >
                            <AlertTriangle className="h-4 w-4" />
                            Warn User
                        </button>
                        <button
                            onClick={() => onAction('ban_user')}
                            className="btn btn-danger"
                        >
                            <Ban className="h-4 w-4" />
                            Ban User
                        </button>
                    </div>
                )}

                {/* Already Reviewed */}
                {report.status !== 'pending' && (
                    <div className="mt-6 rounded-xl bg-[var(--color-bg-tertiary)] p-4">
                        <p className="text-sm text-[var(--color-text-muted)]">
                            <Check className="inline h-4 w-4 mr-1" />
                            Reviewed {report.reviewed_at ? formatDate(report.reviewed_at) : ''}
                        </p>
                    </div>
                )}
            </div>
        </div>
    )
}

// ============================================================================
// Main Page
// ============================================================================

export function ReportsPage() {
    const [reports, setReports] = useState<Report[]>([])
    const [isLoading, setIsLoading] = useState(true)
    const [statusFilter, setStatusFilter] = useState<ReportStatus>('pending')
    const [selectedReport, setSelectedReport] = useState<Report | null>(null)
    const [selectedReports, setSelectedReports] = useState<Set<string>>(new Set())

    useEffect(() => {
        loadReports()
    }, [statusFilter])

    async function loadReports() {
        setIsLoading(true)
        try {
            const res = await adminReports.list({ status: statusFilter, limit: 100 })
            if (res.data) {
                setReports(res.data as Report[])
            }
        } catch (err) {
            console.error('Failed to load reports:', err)
        } finally {
            setIsLoading(false)
        }
    }

    const pendingCount = reports.filter(r => r.status === 'pending').length

    async function handleAction(reportId: string, action: 'dismiss' | 'remove_content' | 'warn_user' | 'ban_user') {
        const statusMap = {
            dismiss: 'dismissed',
            remove_content: 'actioned',
            warn_user: 'actioned',
            ban_user: 'actioned',
        }
        const actionMap = {
            dismiss: 'none',
            remove_content: 'content_removed',
            warn_user: 'warning_issued',
            ban_user: 'user_banned',
        }

        try {
            await adminReports.updateStatus(reportId, statusMap[action], undefined, actionMap[action])

            // Log the action
            await adminAudit.log(
                `report_${action}`,
                'report',
                reportId,
                null,
                { action }
            )

            // Refresh reports
            await loadReports()
            setSelectedReport(null)
        } catch (err) {
            console.error('Failed to update report:', err)
        }
    }

    async function handleBulkDismiss() {
        const ids = Array.from(selectedReports)
        for (const id of ids) {
            await adminReports.updateStatus(id, 'dismissed', undefined, 'none')
        }
        setSelectedReports(new Set())
        await loadReports()
    }

    const columns: ColumnDef<Report>[] = [
        {
            id: 'select',
            header: ({ table }) => (
                <input
                    type="checkbox"
                    checked={table.getIsAllRowsSelected()}
                    onChange={table.getToggleAllRowsSelectedHandler()}
                    className="rounded"
                />
            ),
            cell: ({ row }) => (
                <input
                    type="checkbox"
                    checked={selectedReports.has(row.original.id)}
                    onChange={() => {
                        const newSet = new Set(selectedReports)
                        if (newSet.has(row.original.id)) {
                            newSet.delete(row.original.id)
                        } else {
                            newSet.add(row.original.id)
                        }
                        setSelectedReports(newSet)
                    }}
                    className="rounded"
                />
            ),
        },
        {
            accessorKey: 'content_type',
            header: 'Type',
            cell: ({ row }) => <ContentTypeBadge type={row.original.content_type} />,
        },
        {
            accessorKey: 'reporter',
            header: 'Reporter',
            cell: ({ row }) => (
                <span className="text-sm text-[var(--color-text-primary)]">
                    @{row.original.reporter?.handle || 'unknown'}
                </span>
            ),
        },
        {
            accessorKey: 'reason',
            header: 'Reason',
            cell: ({ row }) => (
                <span className="badge badge-danger">{row.original.reason}</span>
            ),
        },
        {
            accessorKey: 'status',
            header: 'Status',
            cell: ({ row }) => <StatusBadge status={row.original.status} />,
        },
        {
            accessorKey: 'created_at',
            header: 'Reported',
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
                    onClick={() => setSelectedReport(row.original)}
                    className="btn btn-ghost text-xs"
                >
                    <Eye className="h-4 w-4" />
                    Review
                </button>
            ),
        },
    ]

    return (
        <div className="p-8">
            {/* Header */}
            <div className="mb-8 flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-[var(--color-text-primary)]">Reports</h1>
                    <p className="mt-1 text-[var(--color-text-muted)]">
                        Review and moderate reported content
                    </p>
                </div>
                {pendingCount > 0 && (
                    <div className="flex items-center gap-2 rounded-xl bg-[var(--color-warning-500)]/15 px-4 py-2">
                        <Flag className="h-5 w-5 text-[var(--color-warning-500)]" />
                        <span className="font-semibold text-[var(--color-warning-500)]">
                            {pendingCount} pending
                        </span>
                    </div>
                )}
            </div>

            {/* Filters & Bulk Actions */}
            <div className="mb-6 flex items-center justify-between">
                <div className="flex items-center gap-2">
                    <Filter className="h-4 w-4 text-[var(--color-text-muted)]" />
                    <select
                        value={statusFilter}
                        onChange={(e) => setStatusFilter(e.target.value as ReportStatus)}
                        className="input w-auto text-sm"
                    >
                        <option value="all">All Reports</option>
                        <option value="pending">Pending</option>
                        <option value="reviewed">Reviewed</option>
                        <option value="dismissed">Dismissed</option>
                        <option value="actioned">Actioned</option>
                    </select>
                </div>

                {selectedReports.size > 0 && (
                    <div className="flex items-center gap-3">
                        <span className="text-sm text-[var(--color-text-muted)]">
                            {selectedReports.size} selected
                        </span>
                        <button
                            onClick={handleBulkDismiss}
                            className="btn btn-secondary text-sm"
                        >
                            <X className="h-4 w-4" />
                            Dismiss Selected
                        </button>
                    </div>
                )}
            </div>

            {/* Reports Table */}
            <div className="card p-6">
                {reports.length === 0 && !isLoading ? (
                    <div className="text-center py-12">
                        <Flag className="mx-auto h-12 w-12 text-[var(--color-text-muted)] opacity-50" />
                        <p className="mt-4 text-[var(--color-text-muted)]">No reports found</p>
                    </div>
                ) : (
                    <DataTable
                        columns={columns}
                        data={reports}
                        searchKey="reason"
                        searchPlaceholder="Search by reason..."
                        isLoading={isLoading}
                    />
                )}
            </div>

            {/* Report Detail Modal */}
            {selectedReport && (
                <ReportDetailModal
                    report={selectedReport}
                    onClose={() => setSelectedReport(null)}
                    onAction={(action) => handleAction(selectedReport.id, action)}
                />
            )}
        </div>
    )
}

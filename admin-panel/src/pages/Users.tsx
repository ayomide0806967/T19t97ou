import { useState, useEffect } from 'react'
import { type ColumnDef } from '@tanstack/react-table'
import { ShieldCheck, Ban, TrendingUp, Building, Sparkles } from 'lucide-react'
import { DataTable } from '@/components/DataTable'
import { UserDetailPanel } from '@/components/UserDetailPanel'
import { supabase } from '@/lib/supabase'
import { formatDate, cn } from '@/lib/utils'

interface UserWithDetails {
    id: string
    handle: string
    display_name: string | null
    bio: string | null
    avatar_url: string | null
    cover_url: string | null
    created_at: string
    verified_type?: 'none' | 'verified' | 'institution' | 'creator'
    verified_at?: string | null
    is_locked?: boolean
    locked_reason?: string | null
    locked_at?: string | null
    boost_multiplier?: number
    boost_expires_at?: string | null
    plan_name?: string
}

export function UsersPage() {
    const [users, setUsers] = useState<UserWithDetails[]>([])
    const [isLoading, setIsLoading] = useState(true)
    const [selectedUser, setSelectedUser] = useState<UserWithDetails | null>(null)

    useEffect(() => {
        loadUsers()
    }, [])

	    async function loadUsers() {
	        setIsLoading(true)
	        try {
	            // First try with all fields (after migration)
	            const result = await supabase
	                .from('profiles')
	                .select('*')
	                .order('created_at', { ascending: false })
	                .limit(500)
	            let data = result.data
	            const error = result.error

	            if (error) {
	                console.error('Query error:', error)
	                // Fallback to basic fields only
	                const fallback = await supabase
                    .from('profiles')
	                    .select('id, handle, display_name, bio, avatar_url, cover_url, created_at')
	                    .order('created_at', { ascending: false })
	                    .limit(500)
	                data = fallback.data
	            }

	            setUsers((data as UserWithDetails[]) || [])
	        } catch (err) {
            console.error('Failed to load users:', err)
        } finally {
            setIsLoading(false)
        }
    }

    const columns: ColumnDef<UserWithDetails>[] = [
        {
            accessorKey: 'display_name',
            header: 'User',
            cell: ({ row }) => (
                <div className="flex items-center gap-3">
                    {row.original.avatar_url ? (
                        <img
                            src={row.original.avatar_url}
                            alt=""
                            className="h-10 w-10 rounded-full object-cover"
                        />
                    ) : (
                        <div className="flex h-10 w-10 items-center justify-center rounded-full bg-gradient-to-br from-[var(--color-primary-600)] to-[var(--color-primary-400)] text-sm font-semibold text-white">
                            {(row.original.display_name || row.original.handle)[0].toUpperCase()}
                        </div>
                    )}
                    <div>
                        <div className="flex items-center gap-1.5">
                            <p className="font-medium text-[var(--color-text-primary)]">
                                {row.original.display_name || row.original.handle}
                            </p>
                            {row.original.verified_type && row.original.verified_type !== 'none' && (
                                <VerificationBadge type={row.original.verified_type} />
                            )}
                            {row.original.is_locked && (
                                <Ban className="h-4 w-4 text-[var(--color-danger-500)]" />
                            )}
                            {row.original.boost_multiplier && row.original.boost_multiplier > 1 && (
                                <TrendingUp className="h-4 w-4 text-[var(--color-primary-400)]" />
                            )}
                        </div>
                        <p className="text-xs text-[var(--color-text-muted)]">@{row.original.handle}</p>
                    </div>
                </div>
            ),
        },
        {
            accessorKey: 'verified_type',
            header: 'Status',
            cell: ({ row }) => (
                <div className="flex flex-col gap-1">
                    {row.original.is_locked ? (
                        <span className="badge badge-danger">Banned</span>
                    ) : row.original.verified_type && row.original.verified_type !== 'none' ? (
                        <span className={cn(
                            'badge',
                            row.original.verified_type === 'verified' && 'badge-info',
                            row.original.verified_type === 'institution' && 'badge-warning',
                            row.original.verified_type === 'creator' && 'badge-primary'
                        )}>
                            {row.original.verified_type}
                        </span>
                    ) : (
                        <span className="text-xs text-[var(--color-text-muted)]">—</span>
                    )}
                    {row.original.boost_multiplier && row.original.boost_multiplier > 1 && (
                        <span className="badge badge-primary text-xs">
                            {row.original.boost_multiplier}x boost
                        </span>
                    )}
                </div>
            ),
        },
        {
            accessorKey: 'created_at',
            header: 'Joined',
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
                    onClick={() => setSelectedUser(row.original)}
                    className="btn btn-secondary text-xs"
                >
                    Manage
                </button>
            ),
        },
    ]

    return (
        <div className="p-8">
            {/* Header */}
            <div className="mb-8">
                <h1 className="text-2xl font-bold text-[var(--color-text-primary)]">Users</h1>
                <p className="mt-1 text-[var(--color-text-muted)]">
                    Manage user accounts, verification, and access
                </p>
            </div>

            {/* Stats Row */}
            <div className="grid grid-cols-4 gap-4 mb-6">
                <div className="card p-4">
                    <p className="text-2xl font-bold text-[var(--color-text-primary)]">{users.length}</p>
                    <p className="text-xs text-[var(--color-text-muted)]">Total Users</p>
                </div>
                <div className="card p-4">
                    <p className="text-2xl font-bold text-[var(--color-info-500)]">
                        {users.filter(u => u.verified_type && u.verified_type !== 'none').length}
                    </p>
                    <p className="text-xs text-[var(--color-text-muted)]">Verified</p>
                </div>
                <div className="card p-4">
                    <p className="text-2xl font-bold text-[var(--color-primary-400)]">
                        {users.filter(u => u.boost_multiplier && u.boost_multiplier > 1).length}
                    </p>
                    <p className="text-xs text-[var(--color-text-muted)]">Boosted</p>
                </div>
                <div className="card p-4">
                    <p className="text-2xl font-bold text-[var(--color-danger-500)]">
                        {users.filter(u => u.is_locked).length}
                    </p>
                    <p className="text-xs text-[var(--color-text-muted)]">Banned</p>
                </div>
            </div>

            {/* Table */}
            <DataTable
                columns={columns}
                data={users}
                searchKey="handle"
                searchPlaceholder="Search by handle..."
                isLoading={isLoading}
            />

            {/* User Detail Panel */}
            {selectedUser && (
                <UserDetailPanel
                    user={selectedUser}
                    onClose={() => setSelectedUser(null)}
                    onUpdate={() => {
                        loadUsers()
                        setSelectedUser(null)
                    }}
                />
            )}
        </div>
    )
}

function VerificationBadge({ type }: { type: 'verified' | 'institution' | 'creator' }) {
    const config = {
        verified: { icon: ShieldCheck, color: 'text-[var(--color-info-500)]', title: 'Verified' },
        institution: { icon: Building, color: 'text-[var(--color-warning-500)]', title: 'Institution' },
        creator: { icon: Sparkles, color: 'text-[var(--color-primary-400)]', title: 'Creator' },
    }

    const { icon: Icon, color } = config[type]

    return <Icon className={cn('h-4 w-4', color)} />
}

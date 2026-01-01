import { useState, useEffect } from 'react'
import {
    X,
    Shield,
    ShieldCheck,
    ShieldOff,
    Ban,
    Download,
    TrendingUp,
    Eye,
    MessageCircle,
    FileText,
    Image,
    Calendar,
    Mail,
    AlertTriangle,
    Check,
    Star,
    Building,
    Sparkles,
    Activity,
    StickyNote,
    History,
    Heart,
    Repeat,
    Send,
} from 'lucide-react'
import { supabase } from '@/lib/supabase'
import { adminAudit, adminUsers } from '@/lib/edge-functions'
import { formatDate, formatRelativeTime, cn } from '@/lib/utils'

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
}

interface UserDetailPanelProps {
    user: UserWithDetails
    onClose: () => void
    onUpdate: () => void
}

interface Post {
    id: string
    content: string
    created_at: string
    likes_count?: number
    reposts_count?: number
    comments_count?: number
}

interface AdminNote {
    id: string
    content: string
    created_at: string
    author_id: string
}

const verificationTypes = [
    { value: 'none', label: 'None', icon: ShieldOff, color: 'text-[var(--color-text-muted)]' },
    { value: 'verified', label: 'Verified', icon: ShieldCheck, color: 'text-[var(--color-info-500)]' },
    { value: 'institution', label: 'Institution', icon: Building, color: 'text-[var(--color-warning-500)]' },
    { value: 'creator', label: 'Creator', icon: Sparkles, color: 'text-[var(--color-primary-400)]' },
]

const activityExportOptions = [
    { key: 'posts', label: 'Posts', icon: FileText },
    { key: 'comments', label: 'Comments', icon: MessageCircle },
    { key: 'dms', label: 'Direct Messages', icon: Mail },
    { key: 'media', label: 'Media Uploads', icon: Image },
    { key: 'logins', label: 'Login History', icon: Activity },
]

type TabId = 'overview' | 'verification' | 'moderation' | 'boost' | 'export' | 'content' | 'notes' | 'activity'
type VerificationType = 'none' | 'verified' | 'institution' | 'creator'

export function UserDetailPanel({ user, onClose, onUpdate }: UserDetailPanelProps) {
    const [activeTab, setActiveTab] = useState<TabId>('overview')
    const [isLoading, setIsLoading] = useState(false)
    const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null)

    const [selectedVerification, setSelectedVerification] = useState<VerificationType>(user.verified_type || 'none')
    const [verifyDurationType, setVerifyDurationType] = useState<'preset' | 'custom-days' | 'custom-date' | 'permanent'>('permanent')
    const [verifyPreset, setVerifyPreset] = useState<'30d' | '90d' | '1y'>('1y')
    const [verifyCustomDays, setVerifyCustomDays] = useState(365)
    const [verifyEndDate, setVerifyEndDate] = useState('')
    const [banReason, setBanReason] = useState('')
    const [banDuration, setBanDuration] = useState<'permanent' | '7d' | '30d' | '90d'>('7d')
    const [boostMultiplier, setBoostMultiplier] = useState(user.boost_multiplier || 1)
    const [boostDurationType, setBoostDurationType] = useState<'preset' | 'custom-days' | 'custom-date' | 'permanent'>('preset')
    const [boostPreset, setBoostPreset] = useState<'7d' | '30d' | '90d'>('30d')
    const [boostCustomDays, setBoostCustomDays] = useState(14)
    const [boostEndDate, setBoostEndDate] = useState('')
    const [selectedExports, setSelectedExports] = useState<Set<string>>(new Set())
    const [posts, setPosts] = useState<Post[]>([])
    const [loadingContent, setLoadingContent] = useState(false)
    const [notes, setNotes] = useState<AdminNote[]>([])
    const [newNote, setNewNote] = useState('')
    const [loadingNotes, setLoadingNotes] = useState(false)
    const [activities, setActivities] = useState<{ action: string; timestamp: string; details?: string }[]>([])
    const [loadingActivity, setLoadingActivity] = useState(false)

    const showMessage = (type: 'success' | 'error', text: string) => {
        setMessage({ type, text })
        setTimeout(() => setMessage(null), 3000)
    }

    useEffect(() => {
        if (activeTab === 'content' && posts.length === 0) loadUserContent()
        else if (activeTab === 'notes' && notes.length === 0) loadAdminNotes()
        else if (activeTab === 'activity' && activities.length === 0) loadUserActivity()
    }, [activeTab])

    async function loadUserContent() {
        setLoadingContent(true)
        try {
            const { data } = await supabase
                .from('posts')
                .select('id, content, created_at, likes_count, reposts_count, comments_count')
                .eq('author_id', user.id)
                .order('created_at', { ascending: false })
                .limit(50)
            setPosts((data as Post[]) || [])
        } catch (err) { console.error(err) }
        finally { setLoadingContent(false) }
    }

    async function loadAdminNotes() {
        setLoadingNotes(true)
        try {
            const { data } = await supabase
                .from('admin_user_notes')
                .select('*')
                .eq('user_id', user.id)
                .order('created_at', { ascending: false })
            setNotes((data as AdminNote[]) || [])
        } catch (err) { console.error(err) }
        finally { setLoadingNotes(false) }
    }

    async function loadUserActivity() {
        setLoadingActivity(true)
        try {
            const activityList: { action: string; timestamp: string; details?: string }[] = []
            const { data: recentPosts } = await supabase
                .from('posts')
                .select('created_at, content')
                .eq('author_id', user.id)
                .order('created_at', { ascending: false })
                .limit(10)
            recentPosts?.forEach(post => {
                activityList.push({
                    action: 'Created post',
                    timestamp: post.created_at,
                    details: String(post.content || '').substring(0, 50) + '...'
                })
            })
            const auditRes = await adminAudit.listForTarget('user', user.id, 10)
            const adminActions = (auditRes.data as Array<{ action: string; created_at: string; after_json?: unknown }> | null) || []
            adminActions?.forEach(action => {
                activityList.push({
                    action: 'Admin: ' + action.action,
                    timestamp: action.created_at,
                    details: JSON.stringify(action.after_json)?.substring(0, 50)
                })
            })
            activityList.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime())
            setActivities(activityList.slice(0, 20))
        } catch (err) { console.error(err) }
        finally { setLoadingActivity(false) }
    }

    async function handleAddNote() {
        if (!newNote.trim()) return
        setIsLoading(true)
        try {
            const { data: { user: admin } } = await supabase.auth.getUser()
            await supabase.from('admin_user_notes').insert({
                user_id: user.id,
                content: newNote,
                author_id: admin?.id,
            })
            setNewNote('')
            loadAdminNotes()
            showMessage('success', 'Note added')
        } catch (err) {
            showMessage('error', 'Failed to add note')
            console.error(err)
        } finally { setIsLoading(false) }
    }

    const handleSetVerification = async () => {
        setIsLoading(true)
        try {
            let verifiedExpires: string | null = null

            if (selectedVerification !== 'none') {
                if (verifyDurationType === 'preset') {
                    const days = { '30d': 30, '90d': 90, '1y': 365 }[verifyPreset]
                    verifiedExpires = new Date(Date.now() + days * 24 * 60 * 60 * 1000).toISOString()
                } else if (verifyDurationType === 'custom-days') {
                    verifiedExpires = new Date(Date.now() + verifyCustomDays * 24 * 60 * 60 * 1000).toISOString()
                } else if (verifyDurationType === 'custom-date' && verifyEndDate) {
                    verifiedExpires = new Date(verifyEndDate).toISOString()
                }
                // permanent = verifiedExpires stays null (never expires)
            }

            const { error } = await adminUsers.setVerification(user.id, selectedVerification, verifiedExpires)
            if (error) throw new Error(error)
            showMessage('success', 'Verification updated')
            onUpdate()
        } catch (err) {
            showMessage('error', 'Failed to update verification')
            console.error(err)
        } finally { setIsLoading(false) }
    }

    const handleBanUser = async () => {
        if (!banReason.trim()) { showMessage('error', 'Provide a reason'); return }
        setIsLoading(true)
        try {
            let lockedUntil: string | null = null
            if (banDuration !== 'permanent') {
                const days = { '7d': 7, '30d': 30, '90d': 90 }[banDuration]
                lockedUntil = new Date(Date.now() + days * 24 * 60 * 60 * 1000).toISOString()
            }
            const { error } = await adminUsers.lockUser(user.id, lockedUntil, banReason)
            if (error) throw new Error(error)
            showMessage('success', 'User banned')
            onUpdate()
        } catch (err) { showMessage('error', 'Failed to ban'); console.error(err) }
        finally { setIsLoading(false) }
    }

    const handleUnbanUser = async () => {
        setIsLoading(true)
        try {
            const { error } = await adminUsers.unlockUser(user.id)
            if (error) throw new Error(error)
            showMessage('success', 'User unbanned')
            onUpdate()
        } catch (err) { showMessage('error', 'Failed'); console.error(err) }
        finally { setIsLoading(false) }
    }

    const handleSetBoost = async () => {
        setIsLoading(true)
        try {
            let boostExpires: string | null = null

            if (boostDurationType === 'preset') {
                const days = { '7d': 7, '30d': 30, '90d': 90 }[boostPreset]
                boostExpires = new Date(Date.now() + days * 24 * 60 * 60 * 1000).toISOString()
            } else if (boostDurationType === 'custom-days') {
                boostExpires = new Date(Date.now() + boostCustomDays * 24 * 60 * 60 * 1000).toISOString()
            } else if (boostDurationType === 'custom-date' && boostEndDate) {
                boostExpires = new Date(boostEndDate).toISOString()
            }
            // permanent = boostExpires stays null

            const { error } = await adminUsers.setBoost(user.id, boostMultiplier, boostExpires)
            if (error) throw new Error(error)
            showMessage('success', 'Boost applied')
            onUpdate()
        } catch (err) { showMessage('error', 'Failed'); console.error(err) }
        finally { setIsLoading(false) }
    }

    const handleExportActivities = async () => {
        if (selectedExports.size === 0) { showMessage('error', 'Select data types'); return }
        setIsLoading(true)
        try {
            const exportData: Record<string, unknown[]> = {}
            for (const exportType of selectedExports) {
                if (exportType === 'posts') {
                    const { data } = await supabase.from('posts').select('*').eq('author_id', user.id).limit(1000)
                    exportData[exportType] = data || []
                } else if (exportType === 'comments') {
                    const { data } = await supabase.from('comments').select('*').eq('user_id', user.id).limit(1000)
                    exportData[exportType] = data || []
                } else {
                    exportData[exportType] = []
                }
            }
            const blob = new Blob([JSON.stringify(exportData, null, 2)], { type: 'application/json' })
            const url = URL.createObjectURL(blob)
            const a = document.createElement('a')
            a.href = url
            a.download = 'user_' + user.handle + '_export.json'
            document.body.appendChild(a)
            a.click()
            document.body.removeChild(a)
            URL.revokeObjectURL(url)
            await adminAudit.log('export-user-data', 'user', user.id, null, { types: Array.from(selectedExports) })
            showMessage('success', 'Exported')
        } catch (err) { showMessage('error', 'Export failed'); console.error(err) }
        finally { setIsLoading(false) }
    }

    const tabs = [
        { id: 'overview' as const, label: 'Overview', icon: Eye },
        { id: 'content' as const, label: 'Content', icon: FileText },
        { id: 'activity' as const, label: 'Activity', icon: History },
        { id: 'notes' as const, label: 'Notes', icon: StickyNote },
        { id: 'verification' as const, label: 'Verify', icon: Shield },
        { id: 'moderation' as const, label: 'Ban', icon: Ban },
        { id: 'boost' as const, label: 'Boost', icon: TrendingUp },
        { id: 'export' as const, label: 'Export', icon: Download },
    ]

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
            <div className="glass w-full max-w-4xl rounded-2xl animate-fadeIn max-h-[90vh] flex flex-col">
                {/* Header */}
                <div className="flex items-start justify-between p-6 border-b border-[var(--color-border)]">
                    <div className="flex items-center gap-4">
                        {user.avatar_url ? (
                            <img src={user.avatar_url} alt="" className="h-14 w-14 rounded-full object-cover" />
                        ) : (
                            <div className="h-14 w-14 rounded-full bg-gradient-to-br from-[var(--color-primary-600)] to-[var(--color-primary-400)] flex items-center justify-center text-xl font-bold text-white">
                                {(user.display_name || user.handle)[0].toUpperCase()}
                            </div>
                        )}
                        <div>
                            <div className="flex items-center gap-2">
                                <h2 className="text-xl font-bold text-[var(--color-text-primary)]">
                                    {user.display_name || user.handle}
                                </h2>
                                {user.verified_type && user.verified_type !== 'none' && (
                                    <ShieldCheck className={cn('h-5 w-5',
                                        user.verified_type === 'verified' && 'text-[var(--color-info-500)]',
                                        user.verified_type === 'institution' && 'text-[var(--color-warning-500)]',
                                        user.verified_type === 'creator' && 'text-[var(--color-primary-400)]'
                                    )} />
                                )}
                                {user.is_locked && <span className="badge badge-danger">Banned</span>}
                            </div>
                            <p className="text-sm text-[var(--color-text-muted)]">@{user.handle}</p>
                        </div>
                    </div>
                    <button onClick={onClose} className="btn-ghost rounded-lg p-2"><X className="h-5 w-5" /></button>
                </div>

                {message && (
                    <div className={cn('mx-6 mt-4 p-3 rounded-lg text-sm flex items-center gap-2',
                        message.type === 'success' && 'bg-[var(--color-success-500)]/15 text-[var(--color-success-500)]',
                        message.type === 'error' && 'bg-[var(--color-danger-500)]/15 text-[var(--color-danger-500)]'
                    )}>
                        {message.type === 'success' ? <Check className="h-4 w-4" /> : <AlertTriangle className="h-4 w-4" />}
                        {message.text}
                    </div>
                )}

                {/* Tabs */}
                <div className="flex gap-1 px-6 pt-4 overflow-x-auto">
                    {tabs.map((tab) => (
                        <button
                            key={tab.id}
                            onClick={() => setActiveTab(tab.id)}
                            className={cn('flex items-center gap-2 px-3 py-2 rounded-lg text-xs font-medium transition-all whitespace-nowrap',
                                activeTab === tab.id
                                    ? 'bg-[var(--color-primary-600)]/15 text-[var(--color-primary-400)]'
                                    : 'text-[var(--color-text-secondary)] hover:bg-[var(--color-bg-tertiary)]'
                            )}
                        >
                            <tab.icon className="h-4 w-4" />
                            {tab.label}
                        </button>
                    ))}
                </div>

                {/* Content */}
                <div className="flex-1 overflow-y-auto p-6">
                    {activeTab === 'overview' && (
                        <div className="space-y-4">
                            <div className="grid grid-cols-2 gap-4">
                                <div className="rounded-xl bg-[var(--color-bg-tertiary)] p-4">
                                    <div className="flex items-center gap-2 text-[var(--color-text-muted)] mb-1">
                                        <Calendar className="h-4 w-4" /><span className="text-xs">Joined</span>
                                    </div>
                                    <p className="text-[var(--color-text-primary)]">{formatDate(user.created_at)}</p>
                                </div>
                                <div className="rounded-xl bg-[var(--color-bg-tertiary)] p-4">
                                    <div className="flex items-center gap-2 text-[var(--color-text-muted)] mb-1">
                                        <Star className="h-4 w-4" /><span className="text-xs">Verification</span>
                                    </div>
                                    <p className="text-[var(--color-text-primary)] capitalize">{user.verified_type || 'None'}</p>
                                </div>
                            </div>
                            {user.bio && (
                                <div className="rounded-xl bg-[var(--color-bg-tertiary)] p-4">
                                    <p className="text-xs text-[var(--color-text-muted)] mb-1">Bio</p>
                                    <p className="text-[var(--color-text-secondary)]">{user.bio}</p>
                                </div>
                            )}
                            {user.boost_multiplier && user.boost_multiplier > 1 && (
                                <div className="rounded-xl bg-[var(--color-primary-500)]/10 border border-[var(--color-primary-500)]/30 p-4">
                                    <div className="flex items-center gap-2">
                                        <TrendingUp className="h-5 w-5 text-[var(--color-primary-400)]" />
                                        <span className="text-[var(--color-primary-400)] font-medium">Boosted {user.boost_multiplier}x</span>
                                    </div>
                                </div>
                            )}
                            {user.is_locked && (
                                <div className="rounded-xl bg-[var(--color-danger-500)]/10 border border-[var(--color-danger-500)]/30 p-4">
                                    <div className="flex items-center gap-2">
                                        <Ban className="h-5 w-5 text-[var(--color-danger-500)]" />
                                        <span className="text-[var(--color-danger-500)] font-medium">Banned</span>
                                    </div>
                                    {user.locked_reason && <p className="text-sm text-[var(--color-text-secondary)] mt-1">{user.locked_reason}</p>}
                                </div>
                            )}
                        </div>
                    )}

                    {activeTab === 'content' && (
                        <div className="space-y-4">
                            <p className="text-sm text-[var(--color-text-secondary)]">User posts ({posts.length})</p>
                            {loadingContent ? <p className="text-center py-8 text-[var(--color-text-muted)]">Loading...</p> :
                                posts.length === 0 ? <p className="text-center py-8 text-[var(--color-text-muted)]">No posts</p> :
                                    <div className="space-y-3 max-h-[400px] overflow-y-auto">
                                        {posts.map((post) => (
                                            <div key={post.id} className="rounded-xl bg-[var(--color-bg-tertiary)] p-4">
                                                <p className="text-sm text-[var(--color-text-primary)] whitespace-pre-wrap">{post.content}</p>
                                                <div className="flex items-center gap-4 mt-3 text-xs text-[var(--color-text-muted)]">
                                                    <span className="flex items-center gap-1"><Heart className="h-3 w-3" />{post.likes_count || 0}</span>
                                                    <span className="flex items-center gap-1"><Repeat className="h-3 w-3" />{post.reposts_count || 0}</span>
                                                    <span className="flex items-center gap-1"><MessageCircle className="h-3 w-3" />{post.comments_count || 0}</span>
                                                    <span className="ml-auto">{formatRelativeTime(post.created_at)}</span>
                                                </div>
                                            </div>
                                        ))}
                                    </div>
                            }
                        </div>
                    )}

                    {activeTab === 'activity' && (
                        <div className="space-y-4">
                            <p className="text-sm text-[var(--color-text-secondary)]">Activity timeline</p>
                            {loadingActivity ? <p className="text-center py-8 text-[var(--color-text-muted)]">Loading...</p> :
                                activities.length === 0 ? <p className="text-center py-8 text-[var(--color-text-muted)]">No activity</p> :
                                    <div className="relative pl-8 space-y-4">
                                        <div className="absolute left-3 top-2 bottom-2 w-0.5 bg-[var(--color-border)]" />
                                        {activities.map((act, i) => (
                                            <div key={i} className="relative">
                                                <div className="absolute -left-5 w-3 h-3 rounded-full bg-[var(--color-primary-500)]" />
                                                <div className="rounded-xl bg-[var(--color-bg-tertiary)] p-3">
                                                    <p className="text-sm text-[var(--color-text-primary)]">{act.action}</p>
                                                    {act.details && <p className="text-xs text-[var(--color-text-muted)] truncate">{act.details}</p>}
                                                    <p className="text-xs text-[var(--color-text-muted)] mt-1">{formatRelativeTime(act.timestamp)}</p>
                                                </div>
                                            </div>
                                        ))}
                                    </div>
                            }
                        </div>
                    )}

                    {activeTab === 'notes' && (
                        <div className="space-y-4">
                            <p className="text-sm text-[var(--color-text-secondary)]">Internal notes</p>
                            <div className="flex gap-2">
                                <input type="text" value={newNote} onChange={(e) => setNewNote(e.target.value)}
                                    onKeyDown={(e) => e.key === 'Enter' && handleAddNote()} className="input flex-1" placeholder="Add note..." />
                                <button onClick={handleAddNote} disabled={!newNote.trim()} className="btn btn-primary"><Send className="h-4 w-4" /></button>
                            </div>
                            {loadingNotes ? <p className="text-center py-8 text-[var(--color-text-muted)]">Loading...</p> :
                                notes.length === 0 ? <p className="text-center py-8 text-[var(--color-text-muted)]">No notes</p> :
                                    <div className="space-y-2">{notes.map((note) => (
                                        <div key={note.id} className="rounded-xl bg-[var(--color-bg-tertiary)] p-3">
                                            <p className="text-sm text-[var(--color-text-primary)]">{note.content}</p>
                                            <p className="text-xs text-[var(--color-text-muted)] mt-1">{formatRelativeTime(note.created_at)}</p>
                                        </div>
                                    ))}</div>
                            }
                        </div>
                    )}

                    {activeTab === 'verification' && (
                        <div className="space-y-4">
                            <p className="text-sm text-[var(--color-text-secondary)]">Set verification badge for this user</p>

                            {/* Badge Type */}
                            <div className="grid grid-cols-2 gap-3">
                                {verificationTypes.map((type) => (
                                    <button key={type.value} onClick={() => setSelectedVerification(type.value as typeof selectedVerification)}
                                        className={cn('flex items-center gap-3 p-4 rounded-xl border transition-all',
                                            selectedVerification === type.value
                                                ? 'border-[var(--color-primary-500)] bg-[var(--color-primary-500)]/10'
                                                : 'border-[var(--color-border)]'
                                        )}>
                                        <type.icon className={cn('h-6 w-6', type.color)} />
                                        <span className="text-[var(--color-text-primary)]">{type.label}</span>
                                    </button>
                                ))}
                            </div>

                            {/* Duration - only show when not 'none' */}
                            {selectedVerification !== 'none' && (
                                <>
                                    <div>
                                        <label className="block text-sm text-[var(--color-text-secondary)] mb-2">Duration Type</label>
                                        <div className="grid grid-cols-2 gap-2">
                                            {([
                                                { value: 'preset', label: 'Quick Select' },
                                                { value: 'custom-days', label: 'Custom Days' },
                                                { value: 'custom-date', label: 'End Date' },
                                                { value: 'permanent', label: 'Permanent' },
                                            ] as const).map((opt) => (
                                                <button key={opt.value} onClick={() => setVerifyDurationType(opt.value)} className={cn('py-2 px-3 rounded-lg text-sm border transition-all',
                                                    verifyDurationType === opt.value ? 'border-[var(--color-primary-500)] bg-[var(--color-primary-500)]/10 text-[var(--color-primary-400)]' : 'border-[var(--color-border)] text-[var(--color-text-secondary)]'
                                                )}>{opt.label}</button>
                                            ))}
                                        </div>
                                    </div>

                                    {verifyDurationType === 'preset' && (
                                        <div>
                                            <label className="block text-sm text-[var(--color-text-secondary)] mb-2">Select Duration</label>
                                            <div className="grid grid-cols-3 gap-2">
                                                {(['30d', '90d', '1y'] as const).map((d) => (
                                                    <button key={d} onClick={() => setVerifyPreset(d)} className={cn('py-2 rounded-lg text-sm border',
                                                        verifyPreset === d ? 'border-[var(--color-primary-500)] bg-[var(--color-primary-500)]/10 text-[var(--color-primary-400)]' : 'border-[var(--color-border)]'
                                                    )}>{d === '1y' ? '1 year' : d.replace('d', ' days')}</button>
                                                ))}
                                            </div>
                                        </div>
                                    )}

                                    {verifyDurationType === 'custom-days' && (
                                        <div>
                                            <label className="block text-sm text-[var(--color-text-secondary)] mb-2">Number of Days: {verifyCustomDays}</label>
                                            <input type="number" min="1" max="3650" value={verifyCustomDays}
                                                onChange={(e) => setVerifyCustomDays(parseInt(e.target.value) || 1)}
                                                className="input" placeholder="Enter days..." />
                                        </div>
                                    )}

                                    {verifyDurationType === 'custom-date' && (
                                        <div>
                                            <label className="block text-sm text-[var(--color-text-secondary)] mb-2">Verified Until</label>
                                            <input type="datetime-local" value={verifyEndDate}
                                                onChange={(e) => setVerifyEndDate(e.target.value)}
                                                min={new Date().toISOString().slice(0, 16)}
                                                className="input" />
                                        </div>
                                    )}

                                    {verifyDurationType === 'permanent' && (
                                        <div className="rounded-xl bg-[var(--color-info-500)]/10 border border-[var(--color-info-500)]/30 p-3">
                                            <p className="text-sm text-[var(--color-info-500)]">✓ Verification will not expire</p>
                                        </div>
                                    )}
                                </>
                            )}

                            <button onClick={handleSetVerification}
                                disabled={isLoading || selectedVerification === user.verified_type || (verifyDurationType === 'custom-date' && selectedVerification !== 'none' && !verifyEndDate)}
                                className="btn btn-primary w-full disabled:opacity-50">
                                {isLoading ? 'Updating...' : selectedVerification === 'none' ? 'Remove Verification' : 'Apply Verification'}
                            </button>
                        </div>
                    )}

                    {activeTab === 'moderation' && (
                        <div className="space-y-4">
                            {user.is_locked ? (
                                <>
                                    <div className="rounded-xl bg-[var(--color-danger-500)]/10 border border-[var(--color-danger-500)]/30 p-4">
                                        <p className="font-medium text-[var(--color-danger-500)]">User is banned</p>
                                        <p className="text-sm text-[var(--color-text-secondary)]">{user.locked_reason}</p>
                                    </div>
                                    <button onClick={handleUnbanUser} disabled={isLoading} className="btn btn-secondary w-full">Remove Ban</button>
                                </>
                            ) : (
                                <>
                                    <div className="rounded-xl bg-[var(--color-warning-500)]/10 border border-[var(--color-warning-500)]/30 p-4">
                                        <div className="flex items-center gap-2"><AlertTriangle className="h-5 w-5 text-[var(--color-warning-500)]" />
                                            <span className="font-medium text-[var(--color-warning-500)]">Ban User</span></div>
                                    </div>
                                    <div>
                                        <label className="block text-sm text-[var(--color-text-secondary)] mb-2">Duration</label>
                                        <div className="grid grid-cols-4 gap-2">
                                            {(['7d', '30d', '90d', 'permanent'] as const).map((d) => (
                                                <button key={d} onClick={() => setBanDuration(d)} className={cn('py-2 rounded-lg text-sm border',
                                                    banDuration === d ? 'border-[var(--color-danger-500)] bg-[var(--color-danger-500)]/10 text-[var(--color-danger-500)]' : 'border-[var(--color-border)]'
                                                )}>{d === 'permanent' ? 'Forever' : d}</button>
                                            ))}
                                        </div>
                                    </div>
                                    <div>
                                        <label className="block text-sm text-[var(--color-text-secondary)] mb-2">Reason</label>
                                        <textarea value={banReason} onChange={(e) => setBanReason(e.target.value)} className="input min-h-[80px]" placeholder="Required" />
                                    </div>
                                    <button onClick={handleBanUser} disabled={isLoading || !banReason.trim()} className="btn btn-danger w-full disabled:opacity-50">Ban User</button>
                                </>
                            )}
                        </div>
                    )}

                    {activeTab === 'boost' && (
                        <div className="space-y-4">
                            <p className="text-sm text-[var(--color-text-secondary)]">Boost profile visibility in feeds and recommendations</p>

                            {/* Multiplier */}
                            <div>
                                <label className="block text-sm text-[var(--color-text-secondary)] mb-2">Multiplier: {boostMultiplier}x</label>
                                <input type="range" min="1" max="5" step="0.5" value={boostMultiplier}
                                    onChange={(e) => setBoostMultiplier(parseFloat(e.target.value))} className="w-full accent-[var(--color-primary-500)]" />
                                <div className="flex justify-between text-xs text-[var(--color-text-muted)] mt-1">
                                    <span>1x (Normal)</span>
                                    <span>5x (Maximum)</span>
                                </div>
                            </div>

                            {/* Duration Type */}
                            <div>
                                <label className="block text-sm text-[var(--color-text-secondary)] mb-2">Duration Type</label>
                                <div className="grid grid-cols-2 gap-2">
                                    {([
                                        { value: 'preset', label: 'Quick Select' },
                                        { value: 'custom-days', label: 'Custom Days' },
                                        { value: 'custom-date', label: 'End Date' },
                                        { value: 'permanent', label: 'Permanent' },
                                    ] as const).map((opt) => (
                                        <button key={opt.value} onClick={() => setBoostDurationType(opt.value)} className={cn('py-2 px-3 rounded-lg text-sm border transition-all',
                                            boostDurationType === opt.value ? 'border-[var(--color-primary-500)] bg-[var(--color-primary-500)]/10 text-[var(--color-primary-400)]' : 'border-[var(--color-border)] text-[var(--color-text-secondary)]'
                                        )}>{opt.label}</button>
                                    ))}
                                </div>
                            </div>

                            {/* Duration Value */}
                            {boostDurationType === 'preset' && (
                                <div>
                                    <label className="block text-sm text-[var(--color-text-secondary)] mb-2">Select Duration</label>
                                    <div className="grid grid-cols-3 gap-2">
                                        {(['7d', '30d', '90d'] as const).map((d) => (
                                            <button key={d} onClick={() => setBoostPreset(d)} className={cn('py-2 rounded-lg text-sm border',
                                                boostPreset === d ? 'border-[var(--color-primary-500)] bg-[var(--color-primary-500)]/10 text-[var(--color-primary-400)]' : 'border-[var(--color-border)]'
                                            )}>{d.replace('d', ' days')}</button>
                                        ))}
                                    </div>
                                </div>
                            )}

                            {boostDurationType === 'custom-days' && (
                                <div>
                                    <label className="block text-sm text-[var(--color-text-secondary)] mb-2">Number of Days: {boostCustomDays}</label>
                                    <input type="number" min="1" max="365" value={boostCustomDays}
                                        onChange={(e) => setBoostCustomDays(parseInt(e.target.value) || 1)}
                                        className="input" placeholder="Enter days..." />
                                </div>
                            )}

                            {boostDurationType === 'custom-date' && (
                                <div>
                                    <label className="block text-sm text-[var(--color-text-secondary)] mb-2">Boost Until</label>
                                    <input type="datetime-local" value={boostEndDate}
                                        onChange={(e) => setBoostEndDate(e.target.value)}
                                        min={new Date().toISOString().slice(0, 16)}
                                        className="input" />
                                </div>
                            )}

                            {boostDurationType === 'permanent' && (
                                <div className="rounded-xl bg-[var(--color-warning-500)]/10 border border-[var(--color-warning-500)]/30 p-3">
                                    <p className="text-sm text-[var(--color-warning-500)]">⚠️ Permanent boost will not expire automatically</p>
                                </div>
                            )}

                            <button onClick={handleSetBoost} disabled={isLoading || (boostDurationType === 'custom-date' && !boostEndDate)}
                                className="btn btn-primary w-full disabled:opacity-50">
                                <TrendingUp className="h-4 w-4" />
                                {isLoading ? 'Applying...' : boostMultiplier === 1 ? 'Remove Boost' : 'Apply Boost'}
                            </button>

                            {boostMultiplier === 1 && (
                                <p className="text-xs text-[var(--color-text-muted)] text-center">Setting multiplier to 1x will remove any existing boost</p>
                            )}
                        </div>
                    )}

                    {activeTab === 'export' && (
                        <div className="space-y-4">
                            <p className="text-sm text-[var(--color-text-secondary)]">Export user data</p>
                            <div className="space-y-2">
                                {activityExportOptions.map((opt) => (
                                    <label key={opt.key} className={cn('flex items-center gap-3 p-3 rounded-xl border cursor-pointer',
                                        selectedExports.has(opt.key) ? 'border-[var(--color-primary-500)] bg-[var(--color-primary-500)]/10' : 'border-[var(--color-border)]'
                                    )}>
                                        <input
                                            type="checkbox"
                                            checked={selectedExports.has(opt.key)}
                                            className="sr-only"
                                            onChange={(e) => {
                                                const checked = e.target.checked
                                                setSelectedExports((prev) => {
                                                    const next = new Set(prev)
                                                    if (checked) {
                                                        next.add(opt.key)
                                                    } else {
                                                        next.delete(opt.key)
                                                    }
                                                    return next
                                                })
                                            }}
                                        />
                                        <opt.icon className="h-5 w-5 text-[var(--color-text-muted)]" />
                                        <span className="text-[var(--color-text-primary)]">{opt.label}</span>
                                        {opt.key === 'dms' && <span className="ml-auto text-xs text-[var(--color-warning-500)]">Sensitive</span>}
                                    </label>
                                ))}
                            </div>
                            <button onClick={handleExportActivities} disabled={isLoading || selectedExports.size === 0}
                                className="btn btn-primary w-full disabled:opacity-50">
                                <Download className="h-4 w-4" />Export {selectedExports.size} Types
                            </button>
                        </div>
                    )}
                </div>
            </div>
        </div>
    )
}

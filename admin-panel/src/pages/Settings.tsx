import { useState, useEffect, type ReactNode } from 'react'
import { type ColumnDef } from '@tanstack/react-table'
import {
    Plus, ToggleLeft, ToggleRight, Key, ChevronDown, ChevronRight,
    Save, Check, AlertCircle, X
} from 'lucide-react'
import { DataTable } from '@/components/DataTable'
import { adminAdmins, adminSettings, adminPlans } from '@/lib/edge-functions'
import { formatDate, cn } from '@/lib/utils'
import type { AdminUser } from '@/types/database'

// ============================================================================
// Types
// ============================================================================

interface AppSettings {
    app: {
        name: string
        tagline: string
        support_email: string
        logo_url: string
        terms_url: string
        privacy_url: string
    }
    auth: {
        open_registration: boolean
        require_email_verification: boolean
        allowed_domains: string
        default_plan: string
    }
    content: {
        max_post_length: number
        max_media_per_post: number
        allowed_file_types: string
    }
    features: {
        classes_enabled: boolean
        quizzes_enabled: boolean
        dms_enabled: boolean
        comments_enabled: boolean
        reposts_enabled: boolean
    }
    storage: {
        global_quota_mb: number
        max_file_size_mb: number
    }
    integrations: {
        webhook_url: string
        push_notifications_enabled: boolean
    }
    maintenance: {
        enabled: boolean
        message: string
    }
}

const defaultSettings: AppSettings = {
    app: {
        name: 'IN Institution',
        tagline: 'Learn, Share, Grow',
        support_email: 'support@example.com',
        logo_url: '',
        terms_url: '',
        privacy_url: '',
    },
    auth: {
        open_registration: true,
        require_email_verification: false,
        allowed_domains: '',
        default_plan: 'free',
    },
    content: {
        max_post_length: 500,
        max_media_per_post: 4,
        allowed_file_types: 'jpg,jpeg,png,gif,mp4,webp',
    },
    features: {
        classes_enabled: true,
        quizzes_enabled: true,
        dms_enabled: true,
        comments_enabled: true,
        reposts_enabled: true,
    },
    storage: {
        global_quota_mb: 10240,
        max_file_size_mb: 50,
    },
    integrations: {
        webhook_url: '',
        push_notifications_enabled: false,
    },
    maintenance: {
        enabled: false,
        message: 'We are currently performing maintenance. Please check back soon.',
    },
}

type AdminWithProfile = AdminUser & {
    profiles: {
        id: string
        handle: string
        full_name: string
        avatar_url: string | null
    } | null
}

// ============================================================================
// Accordion Component
// ============================================================================

interface AccordionSectionProps {
    title: string
    description: string
    isOpen: boolean
    onToggle: () => void
    children: ReactNode
    badge?: ReactNode
}

function AccordionSection({ title, description, isOpen, onToggle, children, badge }: AccordionSectionProps) {
    return (
        <div className="border-b border-[var(--color-border)] last:border-b-0">
            <button
                onClick={onToggle}
                className="flex w-full items-center justify-between py-4 text-left transition-colors hover:opacity-80"
            >
                <div>
                    <div className="flex items-center gap-2">
                        <h3 className="font-medium text-[var(--color-text-primary)]">{title}</h3>
                        {badge}
                    </div>
                    <p className="text-sm text-[var(--color-text-muted)]">{description}</p>
                </div>
                {isOpen ? (
                    <ChevronDown className="h-5 w-5 text-[var(--color-text-muted)]" />
                ) : (
                    <ChevronRight className="h-5 w-5 text-[var(--color-text-muted)]" />
                )}
            </button>
            <div
                className={cn(
                    'grid transition-all duration-300 ease-in-out',
                    isOpen ? 'grid-rows-[1fr] opacity-100' : 'grid-rows-[0fr] opacity-0'
                )}
            >
                <div className="overflow-hidden">
                    <div className="card p-5 mb-4">{children}</div>
                </div>
            </div>
        </div>
    )
}

// ============================================================================
// Field Components
// ============================================================================

function TextField({
    label,
    value,
    onChange,
    placeholder,
    type = 'text',
}: {
    label: string
    value: string
    onChange: (v: string) => void
    placeholder?: string
    type?: 'text' | 'email' | 'url'
}) {
    return (
        <div>
            <label className="mb-1.5 block text-xs font-medium text-[var(--color-text-secondary)]">{label}</label>
            <input
                type={type}
                value={value}
                onChange={(e) => onChange(e.target.value)}
                placeholder={placeholder}
                className="input text-sm"
            />
        </div>
    )
}

function NumberField({
    label,
    value,
    onChange,
    min,
    max,
    suffix,
}: {
    label: string
    value: number
    onChange: (v: number) => void
    min?: number
    max?: number
    suffix?: string
}) {
    return (
        <div>
            <label className="mb-1.5 block text-xs font-medium text-[var(--color-text-secondary)]">{label}</label>
            <div className="flex items-center gap-2">
                <input
                    type="number"
                    value={value}
                    onChange={(e) => onChange(Number(e.target.value))}
                    min={min}
                    max={max}
                    className="input text-sm"
                />
                {suffix && <span className="text-sm text-[var(--color-text-muted)]">{suffix}</span>}
            </div>
        </div>
    )
}

function ToggleField({
    label,
    description,
    value,
    onChange,
}: {
    label: string
    description?: string
    value: boolean
    onChange: (v: boolean) => void
}) {
    return (
        <label className="flex cursor-pointer items-center justify-between rounded-xl bg-[var(--color-bg-tertiary)] p-4">
            <div>
                <p className="font-medium text-[var(--color-text-primary)]">{label}</p>
                {description && <p className="text-xs text-[var(--color-text-muted)]">{description}</p>}
            </div>
            <button
                type="button"
                onClick={() => onChange(!value)}
                className={cn(
                    'relative h-6 w-11 rounded-full transition-colors',
                    value ? 'bg-[var(--color-primary-500)]' : 'bg-[var(--color-bg-elevated)]'
                )}
            >
                <span
                    className={cn(
                        'absolute top-0.5 h-5 w-5 rounded-full bg-white shadow transition-transform',
                        value ? 'left-[22px]' : 'left-0.5'
                    )}
                />
            </button>
        </label>
    )
}

function TextAreaField({
    label,
    value,
    onChange,
    placeholder,
    rows = 3,
}: {
    label: string
    value: string
    onChange: (v: string) => void
    placeholder?: string
    rows?: number
}) {
    return (
        <div>
            <label className="mb-1.5 block text-xs font-medium text-[var(--color-text-secondary)]">{label}</label>
            <textarea
                value={value}
                onChange={(e) => onChange(e.target.value)}
                placeholder={placeholder}
                rows={rows}
                className="input text-sm"
            />
        </div>
    )
}

// ============================================================================
// Main Settings Page
// ============================================================================

export function SettingsPage() {
    const [settings, setSettings] = useState<AppSettings>(defaultSettings)
    const [originalSettings, setOriginalSettings] = useState<AppSettings>(defaultSettings)
    const [openSection, setOpenSection] = useState<string | null>(null)
    const [isLoading, setIsLoading] = useState(true)
    const [isSaving, setIsSaving] = useState(false)
    const [saveStatus, setSaveStatus] = useState<'idle' | 'success' | 'error'>('idle')

    // Admin users state
    const [admins, setAdmins] = useState<AdminWithProfile[]>([])
    const [isAddModalOpen, setIsAddModalOpen] = useState(false)
    const [newAdminEmail, setNewAdminEmail] = useState('')
    const [newAdminRole, setNewAdminRole] = useState<'support' | 'moderator' | 'super_admin'>('support')
    const [isAdding, setIsAdding] = useState(false)
    const [addError, setAddError] = useState<string | null>(null)

    // Plans for dropdown
    const [plans, setPlans] = useState<Array<{ code: string; name: string }>>([])

    useEffect(() => {
        loadAll()
    }, [])

    async function loadAll() {
        setIsLoading(true)
        try {
            const [adminsRes, plansRes] = await Promise.all([
                adminAdmins.list(),
                adminPlans.list(),
            ])

            // Load all settings categories
            const allSettingsRes = await Promise.all([
                adminSettings.list('app.%'),
                adminSettings.list('auth.%'),
                adminSettings.list('content.%'),
                adminSettings.list('features.%'),
                adminSettings.list('storage.%'),
                adminSettings.list('integrations.%'),
                adminSettings.list('maintenance.%'),
            ])

            const loaded: AppSettings = JSON.parse(JSON.stringify(defaultSettings))

            // Merge all loaded settings
            for (const res of allSettingsRes) {
                if (!res.error && res.data) {
                    for (const row of res.data as Array<{ key: string; value: unknown }>) {
                        const [category, field] = row.key.split('.')
                        if (category && field && loaded[category as keyof AppSettings]) {
                            (loaded[category as keyof AppSettings] as Record<string, unknown>)[field] = row.value
                        }
                    }
                }
            }

            setSettings(loaded)
            setOriginalSettings(JSON.parse(JSON.stringify(loaded)))

            if (!adminsRes.error) {
                setAdmins((adminsRes.data as AdminWithProfile[]) || [])
            }

            if (!plansRes.error) {
                setPlans((plansRes.data as Array<{ code: string; name: string }>) || [])
            }
        } catch (err) {
            console.error('Failed to load settings:', err)
        } finally {
            setIsLoading(false)
        }
    }

    function updateSetting<K extends keyof AppSettings>(
        category: K,
        field: keyof AppSettings[K],
        value: AppSettings[K][keyof AppSettings[K]]
    ) {
        setSettings((prev) => ({
            ...prev,
            [category]: {
                ...prev[category],
                [field]: value,
            },
        }))
        setSaveStatus('idle')
    }

    async function handleSave() {
        setIsSaving(true)
        setSaveStatus('idle')

        try {
            const rows: Array<{ key: string; value: unknown }> = []

            // Flatten settings into key-value pairs
            for (const [category, values] of Object.entries(settings)) {
                for (const [field, value] of Object.entries(values as Record<string, unknown>)) {
                    rows.push({ key: `${category}.${field}`, value })
                }
            }

            const { error } = await adminSettings.upsert(rows as Array<{ key: string; value: Record<string, unknown> }>)
            if (error) throw new Error(error)

            setOriginalSettings(JSON.parse(JSON.stringify(settings)))
            setSaveStatus('success')
            setTimeout(() => setSaveStatus('idle'), 3000)
        } catch (err) {
            console.error('Failed to save settings:', err)
            setSaveStatus('error')
        } finally {
            setIsSaving(false)
        }
    }

    // Admin user functions
    async function loadAdmins() {
        try {
            const { data, error } = await adminAdmins.list()
            if (error) throw new Error(error)
            setAdmins((data as AdminWithProfile[]) || [])
        } catch (err) {
            console.error('Failed to load admins:', err)
        }
    }

    async function toggleActive(userId: string, currentState: boolean) {
        try {
            const { error } = await adminAdmins.setActive(userId, !currentState)
            if (error) throw new Error(error)
            await loadAdmins()
        } catch (err) {
            console.error('Failed to toggle admin status:', err)
        }
    }

    async function toggleDMAccess(userId: string, currentState: boolean) {
        try {
            const { error } = await adminAdmins.setDmAccess(userId, !currentState)
            if (error) throw new Error(error)
            await loadAdmins()
        } catch (err) {
            console.error('Failed to toggle DM access:', err)
        }
    }

    async function handleAddAdmin() {
        setAddError(null)
        const email = newAdminEmail.trim()
        if (!email) {
            setAddError('User email is required.')
            return
        }

        setIsAdding(true)
        try {
            const { error } = await adminAdmins.add(email, newAdminRole)
            if (error) throw new Error(error)
            setNewAdminEmail('')
            setNewAdminRole('support')
            setIsAddModalOpen(false)
            await loadAdmins()
        } catch (err) {
            setAddError(err instanceof Error ? err.message : 'Failed to add admin.')
        } finally {
            setIsAdding(false)
        }
    }

    const hasChanges = JSON.stringify(settings) !== JSON.stringify(originalSettings)

    const adminColumns: ColumnDef<AdminWithProfile>[] = [
        {
            accessorKey: 'profiles.display_name',
            header: 'Admin',
            cell: ({ row }) => {
                const profile = row.original.profiles
                return (
                    <div className="flex items-center gap-3">
                        <div className="flex h-10 w-10 items-center justify-center rounded-full bg-gradient-to-br from-[var(--color-primary-600)] to-[var(--color-primary-400)] text-sm font-semibold text-white">
                            {(profile?.full_name || profile?.handle || 'A')[0].toUpperCase()}
                        </div>
                        <div>
                            <p className="font-medium text-[var(--color-text-primary)]">
                                {profile?.full_name || profile?.handle || 'Unknown'}
                            </p>
                            <p className="text-xs text-[var(--color-text-muted)]">
                                @{profile?.handle || row.original.user_id.substring(0, 8)}
                            </p>
                        </div>
                    </div>
                )
            },
        },
        {
            accessorKey: 'role',
            header: 'Role',
            cell: ({ row }) => (
                <span className={cn(
                    'badge',
                    row.original.role === 'super_admin' && 'badge-warning',
                    row.original.role === 'moderator' && 'badge-info',
                    row.original.role === 'support' && 'badge-primary'
                )}>
                    {row.original.role.replace('_', ' ')}
                </span>
            ),
        },
        {
            accessorKey: 'is_active',
            header: 'Status',
            cell: ({ row }) => (
                <button onClick={() => toggleActive(row.original.user_id, row.original.is_active)} className="flex items-center gap-2">
                    {row.original.is_active ? (
                        <>
                            <ToggleRight className="h-6 w-6 text-[var(--color-success-500)]" />
                            <span className="text-sm text-[var(--color-success-500)]">Active</span>
                        </>
                    ) : (
                        <>
                            <ToggleLeft className="h-6 w-6 text-[var(--color-text-muted)]" />
                            <span className="text-sm text-[var(--color-text-muted)]">Inactive</span>
                        </>
                    )}
                </button>
            ),
        },
        {
            accessorKey: 'dm_access_enabled',
            header: 'DM Access',
            cell: ({ row }) => (
                <button onClick={() => toggleDMAccess(row.original.user_id, row.original.dm_access_enabled)} className="flex items-center gap-2">
                    {row.original.dm_access_enabled ? (
                        <>
                            <Key className="h-4 w-4 text-[var(--color-warning-500)]" />
                            <span className="text-sm text-[var(--color-warning-500)]">Enabled</span>
                        </>
                    ) : (
                        <>
                            <Key className="h-4 w-4 text-[var(--color-text-muted)]" />
                            <span className="text-sm text-[var(--color-text-muted)]">Disabled</span>
                        </>
                    )}
                </button>
            ),
        },
        {
            accessorKey: 'created_at',
            header: 'Added',
            cell: ({ row }) => (
                <span className="text-sm text-[var(--color-text-muted)]">{formatDate(row.original.created_at)}</span>
            ),
        },
    ]

    const toggleSection = (id: string) => {
        setOpenSection(openSection === id ? null : id)
    }

    if (isLoading) {
        return (
            <div className="flex h-64 items-center justify-center text-[var(--color-text-muted)]">
                Loading settings...
            </div>
        )
    }

    return (
        <div className="p-8">
            {/* Header */}
            <div className="mb-8 flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-[var(--color-text-primary)]">Settings</h1>
                    <p className="mt-1 text-[var(--color-text-muted)]">
                        Configure your platform settings and preferences
                    </p>
                </div>
                <div className="flex items-center gap-3">
                    {saveStatus === 'success' && (
                        <span className="flex items-center gap-1 text-sm text-[var(--color-success-500)]">
                            <Check className="h-4 w-4" /> Saved
                        </span>
                    )}
                    {saveStatus === 'error' && (
                        <span className="flex items-center gap-1 text-sm text-[var(--color-danger-500)]">
                            <AlertCircle className="h-4 w-4" /> Failed to save
                        </span>
                    )}
                    <button
                        onClick={handleSave}
                        disabled={!hasChanges || isSaving}
                        className="btn btn-primary disabled:opacity-50"
                    >
                        <Save className="h-4 w-4" />
                        {isSaving ? 'Saving...' : 'Save Changes'}
                    </button>
                </div>
            </div>

            {/* Accordion Sections */}
            <div className="space-y-3">
                {/* App Configuration */}
                <AccordionSection
                    title="App Configuration"
                    description="Branding, contact info, and legal links"
                    isOpen={openSection === 'app'}
                    onToggle={() => toggleSection('app')}
                >
                    <div className="grid gap-4 sm:grid-cols-2">
                        <TextField label="App Name" value={settings.app.name} onChange={(v) => updateSetting('app', 'name', v)} placeholder="My App" />
                        <TextField label="Tagline" value={settings.app.tagline} onChange={(v) => updateSetting('app', 'tagline', v)} placeholder="Your slogan here" />
                        <TextField label="Support Email" value={settings.app.support_email} onChange={(v) => updateSetting('app', 'support_email', v)} type="email" placeholder="support@example.com" />
                        <TextField label="Logo URL" value={settings.app.logo_url} onChange={(v) => updateSetting('app', 'logo_url', v)} type="url" placeholder="https://..." />
                        <TextField label="Terms of Service URL" value={settings.app.terms_url} onChange={(v) => updateSetting('app', 'terms_url', v)} type="url" placeholder="https://..." />
                        <TextField label="Privacy Policy URL" value={settings.app.privacy_url} onChange={(v) => updateSetting('app', 'privacy_url', v)} type="url" placeholder="https://..." />
                    </div>
                </AccordionSection>

                {/* Registration & Auth */}
                <AccordionSection
                    title="Registration & Authentication"
                    description="Signup modes, verification, and default plan"
                    isOpen={openSection === 'auth'}
                    onToggle={() => toggleSection('auth')}
                >
                    <div className="space-y-4">
                        <div className="grid gap-4 sm:grid-cols-2">
                            <ToggleField label="Open Registration" description="Allow anyone to sign up" value={settings.auth.open_registration} onChange={(v) => updateSetting('auth', 'open_registration', v)} />
                            <ToggleField label="Require Email Verification" description="Users must verify email before accessing app" value={settings.auth.require_email_verification} onChange={(v) => updateSetting('auth', 'require_email_verification', v)} />
                        </div>
                        <div className="grid gap-4 sm:grid-cols-2">
                            <TextField label="Allowed Email Domains" value={settings.auth.allowed_domains} onChange={(v) => updateSetting('auth', 'allowed_domains', v)} placeholder="e.g., school.edu, company.com (blank = all)" />
                            <div>
                                <label className="mb-1.5 block text-xs font-medium text-[var(--color-text-secondary)]">Default Plan</label>
                                <select
                                    value={settings.auth.default_plan}
                                    onChange={(e) => updateSetting('auth', 'default_plan', e.target.value)}
                                    className="input text-sm"
                                >
                                    <option value="">None</option>
                                    {plans.map((p) => (
                                        <option key={p.code} value={p.code}>{p.name || p.code}</option>
                                    ))}
                                </select>
                            </div>
                        </div>
                    </div>
                </AccordionSection>

                {/* Content Limits */}
                <AccordionSection
                    title="Content Limits"
                    description="Post length, media limits, and file types"
                    isOpen={openSection === 'content'}
                    onToggle={() => toggleSection('content')}
                >
                    <div className="grid gap-4 sm:grid-cols-3">
                        <NumberField label="Max Post Length" value={settings.content.max_post_length} onChange={(v) => updateSetting('content', 'max_post_length', v)} min={1} suffix="chars" />
                        <NumberField label="Max Media per Post" value={settings.content.max_media_per_post} onChange={(v) => updateSetting('content', 'max_media_per_post', v)} min={1} max={10} suffix="files" />
                        <TextField label="Allowed File Types" value={settings.content.allowed_file_types} onChange={(v) => updateSetting('content', 'allowed_file_types', v)} placeholder="jpg,png,gif,mp4" />
                    </div>
                </AccordionSection>

                {/* Feature Toggles */}
                <AccordionSection
                    title="Feature Toggles"
                    description="Enable or disable major app features"
                    isOpen={openSection === 'features'}
                    onToggle={() => toggleSection('features')}
                >
                    <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
                        <ToggleField label="Classes" description="Educational classes feature" value={settings.features.classes_enabled} onChange={(v) => updateSetting('features', 'classes_enabled', v)} />
                        <ToggleField label="Quizzes" description="Quiz creation and taking" value={settings.features.quizzes_enabled} onChange={(v) => updateSetting('features', 'quizzes_enabled', v)} />
                        <ToggleField label="Direct Messages" description="Private messaging between users" value={settings.features.dms_enabled} onChange={(v) => updateSetting('features', 'dms_enabled', v)} />
                        <ToggleField label="Comments" description="Comments on posts" value={settings.features.comments_enabled} onChange={(v) => updateSetting('features', 'comments_enabled', v)} />
                        <ToggleField label="Reposts" description="Reposting content" value={settings.features.reposts_enabled} onChange={(v) => updateSetting('features', 'reposts_enabled', v)} />
                    </div>
                </AccordionSection>

                {/* Storage Limits */}
                <AccordionSection
                    title="Storage Limits"
                    description="Global quotas and file size limits"
                    isOpen={openSection === 'storage'}
                    onToggle={() => toggleSection('storage')}
                >
                    <div className="grid gap-4 sm:grid-cols-2">
                        <NumberField label="Global Storage Quota" value={settings.storage.global_quota_mb} onChange={(v) => updateSetting('storage', 'global_quota_mb', v)} min={100} suffix="MB" />
                        <NumberField label="Max File Size" value={settings.storage.max_file_size_mb} onChange={(v) => updateSetting('storage', 'max_file_size_mb', v)} min={1} max={500} suffix="MB" />
                    </div>
                </AccordionSection>

                {/* API & Integrations */}
                <AccordionSection
                    title="API & Integrations"
                    description="Webhooks and push notifications"
                    isOpen={openSection === 'integrations'}
                    onToggle={() => toggleSection('integrations')}
                >
                    <div className="space-y-4">
                        <TextField label="Webhook URL" value={settings.integrations.webhook_url} onChange={(v) => updateSetting('integrations', 'webhook_url', v)} type="url" placeholder="https://your-webhook-endpoint.com" />
                        <ToggleField label="Push Notifications" description="Enable server-side push notification delivery" value={settings.integrations.push_notifications_enabled} onChange={(v) => updateSetting('integrations', 'push_notifications_enabled', v)} />
                    </div>
                </AccordionSection>

                {/* Maintenance Mode */}
                <AccordionSection
                    title="Maintenance Mode"
                    description="Take the app offline for maintenance"
                    isOpen={openSection === 'maintenance'}
                    onToggle={() => toggleSection('maintenance')}
                    badge={settings.maintenance.enabled ? <span className="badge badge-danger">ACTIVE</span> : null}
                >
                    <div className="space-y-4">
                        <ToggleField label="Enable Maintenance Mode" description="Users will see a maintenance page instead of the app" value={settings.maintenance.enabled} onChange={(v) => updateSetting('maintenance', 'enabled', v)} />
                        <TextAreaField label="Maintenance Message" value={settings.maintenance.message} onChange={(v) => updateSetting('maintenance', 'message', v)} placeholder="We're performing scheduled maintenance..." rows={3} />
                    </div>
                </AccordionSection>

                {/* Admin Users */}
                <AccordionSection
                    title="Admin Users"
                    description="Manage who can access this admin panel"
                    isOpen={openSection === 'admins'}
                    onToggle={() => toggleSection('admins')}
                >
                    <div className="space-y-4">
                        <div className="flex justify-end">
                            <button onClick={() => setIsAddModalOpen(true)} className="btn btn-primary">
                                <Plus className="h-4 w-4" /> Add Admin
                            </button>
                        </div>
                        <DataTable
                            columns={adminColumns}
                            data={admins}
                            searchKey="role"
                            searchPlaceholder="Search by role..."
                            isLoading={false}
                        />
                    </div>
                </AccordionSection>
            </div>

            {/* Add Admin Modal */}
            {isAddModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
                    <div className="glass w-full max-w-md rounded-2xl p-6 animate-fadeIn">
                        <div className="mb-6 flex items-start justify-between">
                            <h2 className="text-xl font-bold text-[var(--color-text-primary)]">Add Admin</h2>
                            <button onClick={() => setIsAddModalOpen(false)} className="btn-ghost rounded-lg p-2" disabled={isAdding}>
                                <X className="h-5 w-5" />
                            </button>
                        </div>

                        <div className="space-y-4">
                            {addError && (
                                <div className="rounded-xl border border-[var(--color-danger-500)]/30 bg-[var(--color-danger-500)]/10 p-3 text-sm text-[var(--color-danger-500)]">
                                    {addError}
                                </div>
                            )}
                            <div>
                                <label className="mb-2 block text-sm font-medium text-[var(--color-text-secondary)]">User Email</label>
                                <input
                                    type="email"
                                    value={newAdminEmail}
                                    onChange={(e) => setNewAdminEmail(e.target.value)}
                                    className="input"
                                    placeholder="user@example.com"
                                    disabled={isAdding}
                                />
                            </div>

                            <div>
                                <label className="mb-2 block text-sm font-medium text-[var(--color-text-secondary)]">Role</label>
                                <select
                                    value={newAdminRole}
                                    onChange={(e) => setNewAdminRole(e.target.value as typeof newAdminRole)}
                                    className="input"
                                    disabled={isAdding}
                                >
                                    <option value="support">Support</option>
                                    <option value="moderator">Moderator</option>
                                    <option value="super_admin">Super Admin</option>
                                </select>
                            </div>

                            <div className="rounded-xl bg-[var(--color-bg-tertiary)] p-4 text-sm text-[var(--color-text-secondary)]">
                                <p className="mb-2 font-medium">Role Permissions:</p>
                                <ul className="list-inside list-disc space-y-1 text-xs">
                                    <li><strong>Support:</strong> Read-only access, basic safe actions</li>
                                    <li><strong>Moderator:</strong> Content moderation, lock users</li>
                                    <li><strong>Super Admin:</strong> Full access to everything</li>
                                </ul>
                            </div>

                            <button
                                onClick={handleAddAdmin}
                                className="btn btn-primary w-full disabled:opacity-50"
                                disabled={isAdding || !newAdminEmail.trim()}
                            >
                                {isAdding ? 'Adding…' : 'Add Admin'}
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    )
}

import { useMemo, useState, useEffect } from 'react'
import { type ColumnDef } from '@tanstack/react-table'
import { Plus, Edit, Trash2, Check, X } from 'lucide-react'
import { DataTable } from '@/components/DataTable'
import { adminPlans } from '@/lib/edge-functions'
import { cn } from '@/lib/utils'
import type { Plan } from '@/types/database'

type PlanFormState = {
    code: string
    name: string
    description: string
    is_active: boolean
    limits: {
        max_active_classes: string
        max_members_per_class: string
        max_quiz_participants: string
        max_active_published_quizzes: string
        storage_limit_mb: string
    }
    features: {
        checkmark_eligible: boolean
    }
}

function toPlanFormState(plan?: Plan): PlanFormState {
    return {
        code: plan?.code ?? '',
        name: plan?.name ?? '',
        description: plan?.description ?? '',
        is_active: plan?.is_active ?? true,
        limits: {
            max_active_classes: plan?.limits?.max_active_classes?.toString() ?? '',
            max_members_per_class: plan?.limits?.max_members_per_class?.toString() ?? '',
            max_quiz_participants: plan?.limits?.max_quiz_participants?.toString() ?? '',
            max_active_published_quizzes: plan?.limits?.max_active_published_quizzes?.toString() ?? '',
            storage_limit_mb: plan?.limits?.storage_limit_mb?.toString() ?? '',
        },
        features: {
            checkmark_eligible: Boolean(plan?.features?.checkmark_eligible),
        },
    }
}

function parseOptionalInt(value: string): number | undefined {
    const trimmed = value.trim()
    if (!trimmed) return undefined
    const parsed = Number(trimmed)
    if (!Number.isFinite(parsed)) return undefined
    return Math.trunc(parsed)
}

function hasValue(value: unknown): boolean {
    return value !== undefined && value !== null
}

export function PlansPage() {
    const [plans, setPlans] = useState<Plan[]>([])
    const [isLoading, setIsLoading] = useState(true)
    const [editingPlan, setEditingPlan] = useState<Plan | null>(null)
    const [planToDelete, setPlanToDelete] = useState<Plan | null>(null)
    const [isCreateModalOpen, setIsCreateModalOpen] = useState(false)

    useEffect(() => {
        loadPlans()
    }, [])

    async function loadPlans() {
        setIsLoading(true)
        try {
            const { data, error } = await adminPlans.list()
            if (error) throw new Error(error)
            setPlans((data as Plan[]) || [])
        } catch (err) {
            console.error('Failed to load plans:', err)
        } finally {
            setIsLoading(false)
        }
    }

    const existingCodes = useMemo(() => new Set(plans.map(p => p.code.toLowerCase())), [plans])

    const columns: ColumnDef<Plan>[] = [
        {
            accessorKey: 'name',
            header: 'Plan',
            cell: ({ row }) => (
                <div>
                    <p className="font-medium text-[var(--color-text-primary)]">{row.original.name}</p>
                    <p className="text-xs text-[var(--color-text-muted)]">{row.original.code}</p>
                </div>
            ),
        },
        {
            accessorKey: 'description',
            header: 'Description',
            cell: ({ row }) => (
                <span className="text-sm text-[var(--color-text-secondary)]">
                    {row.original.description || '-'}
                </span>
            ),
        },
        {
            id: 'limits',
            header: 'Limits',
            cell: ({ row }) => {
                const limits = row.original.limits || {}
                return (
                    <div className="space-y-1 text-xs">
                        {hasValue(limits.max_active_classes) && (
                            <div className="text-[var(--color-text-secondary)]">
                                Classes: <span className="text-[var(--color-text-primary)]">{limits.max_active_classes}</span>
                            </div>
                        )}
                        {hasValue(limits.max_members_per_class) && (
                            <div className="text-[var(--color-text-secondary)]">
                                Members: <span className="text-[var(--color-text-primary)]">{limits.max_members_per_class}</span>
                            </div>
                        )}
                        {hasValue(limits.max_quiz_participants) && (
                            <div className="text-[var(--color-text-secondary)]">
                                Quiz participants: <span className="text-[var(--color-text-primary)]">{limits.max_quiz_participants}</span>
                            </div>
                        )}
                        {hasValue(limits.max_active_published_quizzes) && (
                            <div className="text-[var(--color-text-secondary)]">
                                Published quizzes: <span className="text-[var(--color-text-primary)]">{limits.max_active_published_quizzes}</span>
                            </div>
                        )}
                        {hasValue(limits.storage_limit_mb) && (
                            <div className="text-[var(--color-text-secondary)]">
                                Storage: <span className="text-[var(--color-text-primary)]">{limits.storage_limit_mb}MB</span>
                            </div>
                        )}
                    </div>
                )
            },
        },
        {
            id: 'features',
            header: 'Features',
            cell: ({ row }) => {
                const features = row.original.features || {}
                return (
                    <div className="flex items-center gap-2">
                        {features.checkmark_eligible ? (
                            <span className="badge badge-success">
                                <Check className="h-3 w-3" />
                                Checkmark
                            </span>
                        ) : (
                            <span className="badge badge-info">
                                <X className="h-3 w-3" />
                                No Checkmark
                            </span>
                        )}
                    </div>
                )
            },
        },
        {
            accessorKey: 'is_active',
            header: 'Status',
            cell: ({ row }) => (
                <span className={cn(
                    'badge',
                    row.original.is_active ? 'badge-success' : 'badge-danger'
                )}>
                    {row.original.is_active ? 'Active' : 'Inactive'}
                </span>
            ),
        },
        {
            id: 'actions',
            header: '',
            cell: ({ row }) => (
                <div className="flex items-center justify-end gap-1">
                    <button
                        onClick={() => setEditingPlan(row.original)}
                        className="btn-ghost rounded-lg p-2"
                        title="Edit plan"
                    >
                        <Edit className="h-4 w-4" />
                    </button>
                    <button
                        onClick={() => setPlanToDelete(row.original)}
                        className="btn-ghost rounded-lg p-2 text-[var(--color-danger-500)]"
                        title="Delete plan"
                    >
                        <Trash2 className="h-4 w-4" />
                    </button>
                </div>
            ),
        },
    ]

    return (
        <div className="p-8">
            {/* Header */}
            <div className="mb-8 flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-[var(--color-text-primary)]">Plans</h1>
                    <p className="mt-1 text-[var(--color-text-muted)]">
                        Manage subscription plans and limits
                    </p>
                </div>
                <button
                    onClick={() => setIsCreateModalOpen(true)}
                    className="btn btn-primary"
                >
                    <Plus className="h-4 w-4" />
                    New Plan
                </button>
            </div>

            {/* Super Admin Notice */}
            <div className="mb-6 rounded-xl border border-[var(--color-warning-500)]/30 bg-[var(--color-warning-500)]/10 p-4">
                <p className="text-sm text-[var(--color-warning-500)]">
                    <strong>Super Admin Only:</strong> Changes to plans affect all users with that plan. Use with caution.
                </p>
            </div>

            {/* Table */}
            <DataTable
                columns={columns}
                data={plans}
                searchKey="name"
                searchPlaceholder="Search plans..."
                isLoading={isLoading}
            />

            {/* Create/Edit Modal */}
            {(isCreateModalOpen || editingPlan) && (
                <PlanEditorModal
                    mode={editingPlan ? 'edit' : 'create'}
                    existingCodes={existingCodes}
                    initialPlan={editingPlan ?? undefined}
                    onClose={() => {
                        setIsCreateModalOpen(false)
                        setEditingPlan(null)
                    }}
                    onSaved={() => {
                        setIsCreateModalOpen(false)
                        setEditingPlan(null)
                        loadPlans()
                    }}
                />
            )}

            {/* Delete Confirm Modal */}
            {planToDelete && (
                <PlanDeleteModal
                    plan={planToDelete}
                    onClose={() => setPlanToDelete(null)}
                    onDeleted={() => {
                        setPlanToDelete(null)
                        loadPlans()
                    }}
                />
            )}
        </div>
    )
}

function PlanEditorModal({
    mode,
    initialPlan,
    existingCodes,
    onClose,
    onSaved,
}: {
    mode: 'create' | 'edit'
    initialPlan?: Plan
    existingCodes: Set<string>
    onClose: () => void
    onSaved: () => void
}) {
    const [form, setForm] = useState<PlanFormState>(() => toPlanFormState(initialPlan))
    const [isSaving, setIsSaving] = useState(false)
    const [errorMessage, setErrorMessage] = useState<string | null>(null)

    const isEdit = mode === 'edit'

    function updateForm(next: Partial<PlanFormState>) {
        setForm(prev => ({ ...prev, ...next }))
    }

    function updateLimits(next: Partial<PlanFormState['limits']>) {
        setForm(prev => ({ ...prev, limits: { ...prev.limits, ...next } }))
    }

    function updateFeatures(next: Partial<PlanFormState['features']>) {
        setForm(prev => ({ ...prev, features: { ...prev.features, ...next } }))
    }

    async function handleSave() {
        setErrorMessage(null)

        const code = form.code.trim()
        const normalizedCode = code.toLowerCase()
        const name = form.name.trim()
        const description = form.description.trim()

        if (!name) {
            setErrorMessage('Plan name is required.')
            return
        }

        if (!isEdit) {
            if (!code) {
                setErrorMessage('Plan code is required.')
                return
            }
            if (existingCodes.has(normalizedCode)) {
                setErrorMessage('Plan code already exists.')
                return
            }
        }

        const userProvidedInvalid = Object.values(form.limits).some(
            (v) => v.trim().length > 0 && parseOptionalInt(v) === undefined
        )
        if (userProvidedInvalid) {
            setErrorMessage('Limits must be valid numbers (or left blank).')
            return
        }

        const limits = {
            max_active_classes: parseOptionalInt(form.limits.max_active_classes),
            max_members_per_class: parseOptionalInt(form.limits.max_members_per_class),
            max_quiz_participants: parseOptionalInt(form.limits.max_quiz_participants),
            max_active_published_quizzes: parseOptionalInt(form.limits.max_active_published_quizzes),
            storage_limit_mb: parseOptionalInt(form.limits.storage_limit_mb),
        }

        const cleanedLimits = Object.fromEntries(
            Object.entries(limits).filter(([, v]) => v !== undefined)
        )

        const cleanedFeatures = {
            checkmark_eligible: Boolean(form.features.checkmark_eligible),
        }

        setIsSaving(true)
        try {
            if (isEdit) {
                const { error } = await adminPlans.update(initialPlan!.code, {
                    name,
                    description: description || null,
                    limits: cleanedLimits,
                    features: cleanedFeatures,
                    is_active: form.is_active,
                })
                if (error) throw new Error(error)
            } else {
                const { error } = await adminPlans.create({
                    code,
                    name,
                    description: description || null,
                    limits: cleanedLimits,
                    features: cleanedFeatures,
                    is_active: form.is_active,
                })
                if (error) throw new Error(error)
            }
            onSaved()
        } catch (err) {
            const message = err instanceof Error ? err.message : 'Failed to save plan.'
            setErrorMessage(message)
        } finally {
            setIsSaving(false)
        }
    }

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
            <div className="glass w-full max-w-2xl rounded-2xl p-6 animate-fadeIn max-h-[80vh] overflow-auto">
                <div className="mb-6 flex items-start justify-between">
                    <div>
                        <h2 className="text-xl font-bold text-[var(--color-text-primary)]">
                            {isEdit ? 'Edit Plan' : 'New Plan'}
                        </h2>
                        <p className="mt-1 text-sm text-[var(--color-text-muted)]">
                            {isEdit ? `Code: ${initialPlan!.code}` : 'Create a new subscription plan'}
                        </p>
                    </div>
                    <button
                        onClick={onClose}
                        className="btn-ghost rounded-lg p-2"
                        disabled={isSaving}
                        title="Close"
                    >
                        ✕
                    </button>
                </div>

                {errorMessage && (
                    <div className="mb-5 rounded-xl border border-[var(--color-danger-500)]/30 bg-[var(--color-danger-500)]/10 p-4 text-sm text-[var(--color-danger-500)]">
                        {errorMessage}
                    </div>
                )}

                <div className="space-y-5">
                    <div className="grid gap-4 sm:grid-cols-2">
                        <div>
                            <label className="mb-2 block text-sm font-medium text-[var(--color-text-secondary)]">
                                Plan Code
                            </label>
                            <input
                                value={form.code}
                                onChange={(e) => updateForm({ code: e.target.value })}
                                className="input font-mono"
                                placeholder="pro_monthly"
                                disabled={isSaving || isEdit}
                            />
                            <p className="mt-1 text-xs text-[var(--color-text-muted)]">
                                Used as the primary key; avoid changing after launch.
                            </p>
                        </div>

                        <div>
                            <label className="mb-2 block text-sm font-medium text-[var(--color-text-secondary)]">
                                Plan Name
                            </label>
                            <input
                                value={form.name}
                                onChange={(e) => updateForm({ name: e.target.value })}
                                className="input"
                                placeholder="Pro"
                                disabled={isSaving}
                            />
                        </div>
                    </div>

                    <div>
                        <label className="mb-2 block text-sm font-medium text-[var(--color-text-secondary)]">
                            Description (optional)
                        </label>
                        <textarea
                            value={form.description}
                            onChange={(e) => updateForm({ description: e.target.value })}
                            className="input min-h-[88px]"
                            placeholder="Best for active classrooms..."
                            disabled={isSaving}
                        />
                    </div>

                    <div className="flex items-center justify-between rounded-xl bg-[var(--color-bg-tertiary)] p-4">
                        <div>
                            <p className="font-medium text-[var(--color-text-primary)]">Active</p>
                            <p className="text-xs text-[var(--color-text-muted)]">Inactive plans can’t be assigned to new users.</p>
                        </div>
                        <label className="flex items-center gap-2 text-sm text-[var(--color-text-secondary)]">
                            <input
                                type="checkbox"
                                checked={form.is_active}
                                onChange={(e) => updateForm({ is_active: e.target.checked })}
                                disabled={isSaving}
                            />
                            Enabled
                        </label>
                    </div>

                    <div className="card p-5">
                        <h3 className="mb-3 font-semibold text-[var(--color-text-primary)]">Limits</h3>
                        <div className="grid gap-4 sm:grid-cols-2">
                            <LimitField
                                label="Max Active Classes"
                                value={form.limits.max_active_classes}
                                onChange={(v) => updateLimits({ max_active_classes: v })}
                                disabled={isSaving}
                            />
                            <LimitField
                                label="Max Members / Class"
                                value={form.limits.max_members_per_class}
                                onChange={(v) => updateLimits({ max_members_per_class: v })}
                                disabled={isSaving}
                            />
                            <LimitField
                                label="Max Quiz Participants"
                                value={form.limits.max_quiz_participants}
                                onChange={(v) => updateLimits({ max_quiz_participants: v })}
                                disabled={isSaving}
                            />
                            <LimitField
                                label="Max Published Quizzes"
                                value={form.limits.max_active_published_quizzes}
                                onChange={(v) => updateLimits({ max_active_published_quizzes: v })}
                                disabled={isSaving}
                            />
                            <LimitField
                                label="Storage Limit (MB)"
                                value={form.limits.storage_limit_mb}
                                onChange={(v) => updateLimits({ storage_limit_mb: v })}
                                disabled={isSaving}
                            />
                        </div>
                        <p className="mt-3 text-xs text-[var(--color-text-muted)]">
                            Leave blank to omit the limit (treated as “not set”).
                        </p>
                    </div>

                    <div className="card p-5">
                        <h3 className="mb-3 font-semibold text-[var(--color-text-primary)]">Features</h3>
                        <label className="flex items-center justify-between rounded-xl bg-[var(--color-bg-tertiary)] p-4">
                            <div>
                                <p className="font-medium text-[var(--color-text-primary)]">Checkmark Eligible</p>
                                <p className="text-xs text-[var(--color-text-muted)]">Allows users on this plan to get verified.</p>
                            </div>
                            <input
                                type="checkbox"
                                checked={form.features.checkmark_eligible}
                                onChange={(e) => updateFeatures({ checkmark_eligible: e.target.checked })}
                                disabled={isSaving}
                            />
                        </label>
                    </div>

                    <div className="flex items-center justify-end gap-3 pt-2">
                        <button
                            onClick={onClose}
                            className="btn btn-secondary"
                            disabled={isSaving}
                        >
                            Cancel
                        </button>
                        <button
                            onClick={handleSave}
                            className="btn btn-primary"
                            disabled={isSaving}
                        >
                            {isSaving ? 'Saving…' : 'Save Plan'}
                        </button>
                    </div>
                </div>
            </div>
        </div>
    )
}

function LimitField({
    label,
    value,
    onChange,
    disabled,
}: {
    label: string
    value: string
    onChange: (value: string) => void
    disabled: boolean
}) {
    return (
        <div>
            <label className="mb-1.5 block text-xs font-medium text-[var(--color-text-secondary)]">
                {label}
            </label>
            <input
                type="number"
                inputMode="numeric"
                value={value}
                onChange={(e) => onChange(e.target.value)}
                className="input text-sm"
                placeholder="—"
                disabled={disabled}
                min={0}
            />
        </div>
    )
}

function PlanDeleteModal({
    plan,
    onClose,
    onDeleted,
}: {
    plan: Plan
    onClose: () => void
    onDeleted: () => void
}) {
    const [isDeleting, setIsDeleting] = useState(false)
    const [errorMessage, setErrorMessage] = useState<string | null>(null)

    async function handleDelete() {
        setErrorMessage(null)
        setIsDeleting(true)
        try {
            const { error } = await adminPlans.delete(plan.code)
            if (error) throw new Error(error)
            onDeleted()
        } catch (err) {
            const message = err instanceof Error ? err.message : 'Failed to delete plan.'
            setErrorMessage(message)
        } finally {
            setIsDeleting(false)
        }
    }

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
            <div className="glass w-full max-w-md rounded-2xl p-6 animate-fadeIn">
                <div className="mb-4 flex items-start justify-between">
                    <h2 className="text-xl font-bold text-[var(--color-text-primary)]">Delete Plan</h2>
                    <button
                        onClick={onClose}
                        className="btn-ghost rounded-lg p-2"
                        disabled={isDeleting}
                        title="Close"
                    >
                        ✕
                    </button>
                </div>

                <p className="text-sm text-[var(--color-text-secondary)]">
                    Delete <span className="font-medium text-[var(--color-text-primary)]">{plan.name}</span>{' '}
                    (<span className="font-mono">{plan.code}</span>)? This affects any users currently on this plan.
                </p>

                {errorMessage && (
                    <div className="mt-4 rounded-xl border border-[var(--color-danger-500)]/30 bg-[var(--color-danger-500)]/10 p-3 text-sm text-[var(--color-danger-500)]">
                        {errorMessage}
                    </div>
                )}

                <div className="mt-6 flex items-center justify-end gap-3">
                    <button
                        onClick={onClose}
                        className="btn btn-secondary"
                        disabled={isDeleting}
                    >
                        Cancel
                    </button>
                    <button
                        onClick={handleDelete}
                        className="btn btn-danger"
                        disabled={isDeleting}
                    >
                        {isDeleting ? 'Deleting…' : 'Delete'}
                    </button>
                </div>
            </div>
        </div>
    )
}

import { useState, useEffect } from 'react'
import { Save, RotateCcw, AlertCircle, Check, Sliders } from 'lucide-react'
import { adminSettings } from '@/lib/edge-functions'
import { moderationDefaults, type ModerationSettings } from '@/lib/moderationDefaults'

const algorithmCategories = [
    {
        key: 'algo.feed_ranking',
        name: 'Feed Ranking',
        description: 'Control how posts are ranked in the main feed',
        defaultValue: {
            like_weight: 1.0,
            repost_weight: 2.0,
            comment_weight: 1.5,
            view_weight: 0.1,
            time_decay_hours: 24,
            follow_boost: 1.5,
            min_quality_score: 0.3,
        },
    },
    {
        key: 'algo.trending',
        name: 'Trending',
        description: 'Settings for trending content detection',
        defaultValue: {
            velocity_weight: 2.0,
            volume_weight: 1.0,
            timeframe_hours: 24,
            min_interactions: 10,
            spam_threshold: 0.8,
        },
    },
    {
        key: 'algo.recommendations',
        name: 'Recommendations',
        description: 'Control "For You" recommendations',
        defaultValue: {
            follow_graph_weight: 1.5,
            topic_relevance_weight: 1.0,
            diversity_factor: 0.3,
            explore_ratio: 0.2,
        },
    },
    {
        key: 'algo.spam_detection',
        name: 'Spam Detection',
        description: 'Thresholds for spam and abuse detection',
        defaultValue: {
            repeat_post_threshold: 3,
            link_spam_threshold: 5,
            report_threshold: 10,
            shadow_ban_threshold: 20,
        },
    },
]

export function AlgorithmPage() {
    const [settings, setSettings] = useState<Record<string, Record<string, unknown>>>({})
    const [originalSettings, setOriginalSettings] = useState<Record<string, Record<string, unknown>>>({})
    const [isLoading, setIsLoading] = useState(true)
    const [isSaving, setIsSaving] = useState(false)
    const [saveStatus, setSaveStatus] = useState<'idle' | 'success' | 'error'>('idle')

    const [moderationSettings, setModerationSettings] = useState<ModerationSettings>(moderationDefaults)
    const [originalModerationSettings, setOriginalModerationSettings] = useState<ModerationSettings>(moderationDefaults)

    useEffect(() => {
        loadSettings()
    }, [])

    async function loadSettings() {
        setIsLoading(true)
        try {
            const [algoRes, moderationRes] = await Promise.all([
                adminSettings.list('algo.%'),
                adminSettings.list('moderation.%'),
            ])
            if (algoRes.error) throw new Error(algoRes.error)
            if (moderationRes.error) throw new Error(moderationRes.error)

            const loadedSettings: Record<string, Record<string, unknown>> = {}

            // Initialize with defaults
            algorithmCategories.forEach(cat => {
                loadedSettings[cat.key] = { ...cat.defaultValue }
            })

            // Override with saved values
            interface AdminSettingRow { key: string; value: Record<string, unknown> }
            ;(algoRes.data as AdminSettingRow[] || []).forEach((setting) => {
                if (setting.value && typeof setting.value === 'object') {
                    loadedSettings[setting.key] = setting.value
                }
            })

            setSettings(loadedSettings)
            setOriginalSettings(JSON.parse(JSON.stringify(loadedSettings)))

            const merged: ModerationSettings = JSON.parse(JSON.stringify(moderationDefaults))
            const moderationRows = (moderationRes.data as AdminSettingRow[] | null) || []
            for (const row of moderationRows) {
                if (row.key === 'moderation.trending' && row.value && typeof row.value === 'object') {
                    merged.trending = { ...merged.trending, ...row.value } as ModerationSettings['trending']
                }
                if (row.key === 'moderation.posts' && row.value && typeof row.value === 'object') {
                    merged.posts = { ...merged.posts, ...row.value } as ModerationSettings['posts']
                }
            }
            setModerationSettings(merged)
            setOriginalModerationSettings(JSON.parse(JSON.stringify(merged)))
        } catch (err) {
            console.error('Failed to load settings:', err)
        } finally {
            setIsLoading(false)
        }
    }

    function handleValueChange(categoryKey: string, settingKey: string, value: string) {
        const numValue = parseFloat(value)
        if (isNaN(numValue)) return

        setSettings(prev => ({
            ...prev,
            [categoryKey]: {
                ...prev[categoryKey],
                [settingKey]: numValue,
            },
        }))
        setSaveStatus('idle')
    }

    function handleReset(categoryKey: string) {
        const category = algorithmCategories.find(c => c.key === categoryKey)
        if (!category) return

        setSettings(prev => ({
            ...prev,
            [categoryKey]: { ...category.defaultValue },
        }))
        setSaveStatus('idle')
    }

    async function handleSave() {
        setIsSaving(true)
        setSaveStatus('idle')

        try {
            const rows = Object.entries(settings).map(([key, value]) => ({
                key,
                value,
            }))
            rows.push(
                { key: 'moderation.trending', value: moderationSettings.trending as unknown as Record<string, unknown> },
                { key: 'moderation.posts', value: moderationSettings.posts as unknown as Record<string, unknown> },
            )

            const { error } = await adminSettings.upsert(rows)
            if (error) throw new Error(error)

            setOriginalSettings(JSON.parse(JSON.stringify(settings)))
            setOriginalModerationSettings(JSON.parse(JSON.stringify(moderationSettings)))
            setSaveStatus('success')
            setTimeout(() => setSaveStatus('idle'), 3000)
        } catch (err) {
            console.error('Failed to save settings:', err)
            setSaveStatus('error')
        } finally {
            setIsSaving(false)
        }
    }

    const hasAlgoChanges = JSON.stringify(settings) !== JSON.stringify(originalSettings)
    const hasModerationChanges = JSON.stringify(moderationSettings) !== JSON.stringify(originalModerationSettings)
    const hasChanges = hasAlgoChanges || hasModerationChanges

    return (
        <div className="p-8">
            {/* Header */}
            <div className="mb-8 flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-[var(--color-text-primary)]">Algorithm Settings</h1>
                    <p className="mt-1 text-[var(--color-text-muted)]">
                        Fine-tune ranking, trending, and recommendation algorithms
                    </p>
                </div>
                <div className="flex items-center gap-3">
                    {saveStatus === 'success' && (
                        <span className="flex items-center gap-1 text-sm text-[var(--color-success-500)]">
                            <Check className="h-4 w-4" />
                            Saved
                        </span>
                    )}
                    {saveStatus === 'error' && (
                        <span className="flex items-center gap-1 text-sm text-[var(--color-danger-500)]">
                            <AlertCircle className="h-4 w-4" />
                            Failed to save
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

            {/* Warning */}
            <div className="mb-6 rounded-xl border border-[var(--color-warning-500)]/30 bg-[var(--color-warning-500)]/10 p-4">
                <p className="text-sm text-[var(--color-warning-500)]">
                    <strong>Super Admin Only:</strong> Changes to algorithm settings affect all users immediately. Test carefully in staging first.
                </p>
            </div>

            {isLoading ? (
                <div className="flex h-64 items-center justify-center text-[var(--color-text-muted)]">
                    Loading settings...
                </div>
            ) : (
                <div className="space-y-6">
                    {algorithmCategories.map((category) => (
                        <div key={category.key} className="card p-6">
                            <div className="mb-4 flex items-center justify-between">
                                <div className="flex items-center gap-3">
                                    <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-[var(--color-primary-500)]/15">
                                        <Sliders className="h-5 w-5 text-[var(--color-primary-400)]" />
                                    </div>
                                    <div>
                                        <h3 className="font-semibold text-[var(--color-text-primary)]">{category.name}</h3>
                                        <p className="text-sm text-[var(--color-text-muted)]">{category.description}</p>
                                    </div>
                                </div>
                                <button
                                    onClick={() => handleReset(category.key)}
                                    className="btn btn-ghost text-xs"
                                >
                                    <RotateCcw className="h-3 w-3" />
                                    Reset
                                </button>
                            </div>

                            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
                                {Object.entries(settings[category.key] || {}).map(([key, value]) => (
                                    <div key={key}>
                                        <label className="mb-1.5 block text-xs font-medium text-[var(--color-text-secondary)]">
                                            {key.replace(/_/g, ' ')}
                                        </label>
                                        <input
                                            type="number"
                                            step="0.1"
                                            value={value as number}
                                            onChange={(e) => handleValueChange(category.key, key, e.target.value)}
                                            className="input text-sm"
                                        />
                                    </div>
                                ))}
                            </div>
                        </div>
                    ))}

                    <div className="card p-6">
                        <div className="mb-4 flex items-center justify-between">
                            <div className="flex items-center gap-3">
                                <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-[var(--color-primary-500)]/15">
                                    <Sliders className="h-5 w-5 text-[var(--color-primary-400)]" />
                                </div>
                                <div>
                                    <h3 className="font-semibold text-[var(--color-text-primary)]">Moderation Settings</h3>
                                    <p className="text-sm text-[var(--color-text-muted)]">Trending ranking + post takedown defaults</p>
                                </div>
                            </div>
                        </div>

                        <div className="grid gap-6 lg:grid-cols-2">
                            <div className="rounded-xl bg-[var(--color-bg-tertiary)] p-4">
                                <h4 className="mb-3 font-semibold text-[var(--color-text-primary)]">Trending</h4>
                                <div className="grid gap-4 sm:grid-cols-2">
                                    <NumberField
                                        label="Like weight"
                                        value={moderationSettings.trending.like_weight}
                                        onChange={(v) => setModerationSettings((prev) => ({
                                            ...prev,
                                            trending: { ...prev.trending, like_weight: v },
                                        }))}
                                    />
                                    <NumberField
                                        label="Repost weight"
                                        value={moderationSettings.trending.repost_weight}
                                        onChange={(v) => setModerationSettings((prev) => ({
                                            ...prev,
                                            trending: { ...prev.trending, repost_weight: v },
                                        }))}
                                    />
                                    <NumberField
                                        label="Reply weight"
                                        value={moderationSettings.trending.reply_weight}
                                        onChange={(v) => setModerationSettings((prev) => ({
                                            ...prev,
                                            trending: { ...prev.trending, reply_weight: v },
                                        }))}
                                    />
                                    <NumberField
                                        label="Bookmark weight"
                                        value={moderationSettings.trending.bookmark_weight}
                                        onChange={(v) => setModerationSettings((prev) => ({
                                            ...prev,
                                            trending: { ...prev.trending, bookmark_weight: v },
                                        }))}
                                    />
                                    <NumberField
                                        label="Time decay (hours)"
                                        value={moderationSettings.trending.time_decay_hours}
                                        onChange={(v) => setModerationSettings((prev) => ({
                                            ...prev,
                                            trending: { ...prev.trending, time_decay_hours: v },
                                        }))}
                                    />
                                    <NumberField
                                        label="Min interactions"
                                        value={moderationSettings.trending.min_interactions}
                                        onChange={(v) => setModerationSettings((prev) => ({
                                            ...prev,
                                            trending: { ...prev.trending, min_interactions: v },
                                        }))}
                                    />
                                    <NumberField
                                        label="Max candidates"
                                        value={moderationSettings.trending.max_candidates}
                                        onChange={(v) => setModerationSettings((prev) => ({
                                            ...prev,
                                            trending: { ...prev.trending, max_candidates: v },
                                        }))}
                                    />
                                </div>
                                <p className="mt-3 text-xs text-[var(--color-text-muted)]">
                                    Used by Dashboard/Posts trending; per-post overrides are still available on the Posts page.
                                </p>
                            </div>

                            <div className="rounded-xl bg-[var(--color-bg-tertiary)] p-4">
                                <h4 className="mb-3 font-semibold text-[var(--color-text-primary)]">Post Takedowns</h4>
                                <label className="flex items-center justify-between rounded-xl bg-[var(--color-bg-secondary)] p-3">
                                    <div>
                                        <p className="font-medium text-[var(--color-text-primary)]">Require removal reason</p>
                                        <p className="text-xs text-[var(--color-text-muted)]">Forces moderators to provide a reason.</p>
                                    </div>
                                    <input
                                        type="checkbox"
                                        checked={moderationSettings.posts.require_removal_reason}
                                        onChange={(e) => setModerationSettings((prev) => ({
                                            ...prev,
                                            posts: { ...prev.posts, require_removal_reason: e.target.checked },
                                        }))}
                                    />
                                </label>

                                <label className="mt-3 flex items-center justify-between rounded-xl bg-[var(--color-bg-secondary)] p-3">
                                    <div>
                                        <p className="font-medium text-[var(--color-text-primary)]">Allow restoring posts</p>
                                        <p className="text-xs text-[var(--color-text-muted)]">Enables “Restore” action for removed posts.</p>
                                    </div>
                                    <input
                                        type="checkbox"
                                        checked={moderationSettings.posts.allow_restore_post}
                                        onChange={(e) => setModerationSettings((prev) => ({
                                            ...prev,
                                            posts: { ...prev.posts, allow_restore_post: e.target.checked },
                                        }))}
                                    />
                                </label>

                                <div className="mt-4">
                                    <label className="mb-2 block text-sm font-medium text-[var(--color-text-secondary)]">
                                        Default removal reasons (one per line)
                                    </label>
                                    <textarea
                                        value={moderationSettings.posts.default_removal_reasons.join('\n')}
                                        onChange={(e) => setModerationSettings((prev) => ({
                                            ...prev,
                                            posts: {
                                                ...prev.posts,
                                                default_removal_reasons: e.target.value
                                                    .split('\n')
                                                    .map(s => s.trim())
                                                    .filter(Boolean),
                                            },
                                        }))}
                                        className="input min-h-[180px]"
                                        placeholder="Spam\nHarassment\n…"
                                    />
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </div>
    )
}

function NumberField({
    label,
    value,
    onChange,
}: {
    label: string
    value: number
    onChange: (value: number) => void
}) {
    return (
        <div>
            <label className="mb-1.5 block text-xs font-medium text-[var(--color-text-secondary)]">
                {label}
            </label>
            <input
                type="number"
                step="0.1"
                value={value}
                onChange={(e) => onChange(Number(e.target.value))}
                className="input text-sm"
            />
        </div>
    )
}

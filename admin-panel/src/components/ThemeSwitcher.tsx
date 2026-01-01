import { useTheme } from '@/hooks/useTheme'
import { cn } from '@/lib/utils'

export function ThemeSwitcher() {
    const { theme, setTheme, themes } = useTheme()

    return (
        <div className="flex items-center gap-2">
            {themes.map((t) => (
                <button
                    key={t.value}
                    onClick={() => setTheme(t.value)}
                    className={cn(
                        'group relative h-8 w-8 rounded-full transition-all duration-200',
                        'ring-2 ring-offset-2 ring-offset-[var(--color-bg-primary)]',
                        theme === t.value
                            ? 'ring-[var(--color-primary-500)] scale-110'
                            : 'ring-transparent hover:ring-[var(--color-border-hover)]'
                    )}
                    style={{ backgroundColor: t.preview }}
                    title={t.label}
                >
                    {/* Inner border for light themes */}
                    {(t.value === 'white' || t.value === 'offwhite') && (
                        <span className="absolute inset-0 rounded-full border border-gray-300" />
                    )}

                    {/* Checkmark for selected theme */}
                    {theme === t.value && (
                        <span className={cn(
                            'absolute inset-0 flex items-center justify-center',
                            t.value === 'black' || t.value === 'dim' ? 'text-white' : 'text-gray-800'
                        )}>
                            <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={3}>
                                <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                            </svg>
                        </span>
                    )}
                </button>
            ))}
        </div>
    )
}

// Compact version for sidebar
export function ThemeSwitcherCompact() {
    const { theme, setTheme, themes } = useTheme()

    return (
        <div className="flex items-center gap-1.5">
            {themes.map((t) => (
                <button
                    key={t.value}
                    onClick={() => setTheme(t.value)}
                    className={cn(
                        'h-5 w-5 rounded-full transition-all duration-200 border',
                        theme === t.value
                            ? 'ring-2 ring-[var(--color-primary-500)] ring-offset-1 ring-offset-[var(--color-bg-secondary)]'
                            : 'opacity-60 hover:opacity-100',
                        (t.value === 'white' || t.value === 'offwhite') ? 'border-gray-300' : 'border-transparent'
                    )}
                    style={{ backgroundColor: t.preview }}
                    title={t.label}
                />
            ))}
        </div>
    )
}

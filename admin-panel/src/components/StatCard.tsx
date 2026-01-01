import { cn } from '@/lib/utils'
import type { LucideIcon } from 'lucide-react'

interface StatCardProps {
    title: string
    value: string | number
    change?: string
    changeType?: 'positive' | 'negative' | 'neutral'
    icon: LucideIcon
    iconColor?: string
}

export function StatCard({
    title,
    value,
    change,
    changeType = 'neutral',
    icon: Icon,
    iconColor = 'var(--color-primary-400)',
}: StatCardProps) {
    return (
        <div className="card p-6 card-hover">
            <div className="flex items-start justify-between">
                <div>
                    <p className="text-sm font-medium text-[var(--color-text-muted)]">{title}</p>
                    <p className="mt-2 text-3xl font-bold text-[var(--color-text-primary)]">{value}</p>
                    {change && (
                        <p
                            className={cn(
                                'mt-2 text-sm font-medium',
                                changeType === 'positive' && 'text-[var(--color-success-500)]',
                                changeType === 'negative' && 'text-[var(--color-danger-500)]',
                                changeType === 'neutral' && 'text-[var(--color-text-muted)]'
                            )}
                        >
                            {change}
                        </p>
                    )}
                </div>
                <div
                    className="flex h-12 w-12 items-center justify-center rounded-xl"
                    style={{ backgroundColor: `color-mix(in srgb, ${iconColor} 15%, transparent)` }}
                >
                    <Icon className="h-6 w-6" style={{ color: iconColor }} />
                </div>
            </div>
        </div>
    )
}

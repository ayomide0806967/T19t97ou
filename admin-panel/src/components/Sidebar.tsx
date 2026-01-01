import { NavLink, useLocation } from 'react-router-dom'
import { cn } from '@/lib/utils'
import {
    LayoutDashboard,
    Users,
    FileText,
    CreditCard,
    HardDrive,
    Settings,
    ScrollText,
    LogOut,
    Sliders,
    Flag,
    Bell,
    MessageSquare,
    BarChart3,
} from 'lucide-react'
import { supabase } from '@/lib/supabase'
import { ThemeSwitcherCompact } from '@/components/ThemeSwitcher'
import type { AdminRole } from '@/types/database'

interface SidebarProps {
    role: AdminRole | null
}

const navigation = [
    { name: 'Dashboard', href: '/', icon: LayoutDashboard, minRole: 'support' as const },
    { name: 'Users', href: '/users', icon: Users, minRole: 'support' as const },
    { name: 'Posts', href: '/posts', icon: FileText, minRole: 'support' as const },
    { name: 'Reports', href: '/reports', icon: Flag, minRole: 'moderator' as const },
    { name: 'Plans', href: '/plans', icon: CreditCard, minRole: 'super_admin' as const },
    { name: 'Storage', href: '/storage', icon: HardDrive, minRole: 'super_admin' as const },
    { name: 'Algorithm', href: '/algorithm', icon: Sliders, minRole: 'super_admin' as const },
    { name: 'Notifications', href: '/notifications', icon: Bell, minRole: 'super_admin' as const },
    { name: 'Messages', href: '/messages', icon: MessageSquare, minRole: 'super_admin' as const },
    { name: 'Analytics', href: '/analytics', icon: BarChart3, minRole: 'super_admin' as const },
    { name: 'Audit Log', href: '/audit', icon: ScrollText, minRole: 'support' as const },
    { name: 'Settings', href: '/settings', icon: Settings, minRole: 'super_admin' as const },
]

const roleHierarchy = {
    'support': 1,
    'moderator': 2,
    'super_admin': 3,
}

export function Sidebar({ role }: SidebarProps) {
    const location = useLocation()

    const handleLogout = async () => {
        await supabase.auth.signOut()
    }

    const visibleNavigation = navigation.filter(
        item => role && roleHierarchy[role] >= roleHierarchy[item.minRole]
    )

    return (
        <aside className="fixed left-0 top-0 z-40 h-screen w-64 border-r border-[var(--color-border)] bg-[var(--color-bg-secondary)] flex flex-col">
            {/* Logo */}
            <div className="flex h-16 items-center gap-3 border-b border-[var(--color-border)] px-6">
                <img
                    src="/logo.png"
                    alt="IN Logo"
                    className="h-9 w-9 rounded-xl object-cover"
                />
                <div>
                    <h1 className="text-sm font-semibold text-[var(--color-text-primary)]">IN Admin</h1>
                    <p className="text-xs text-[var(--color-text-muted)]">{role?.replace('_', ' ')}</p>
                </div>
            </div>

            {/* Navigation */}
            <nav className="flex-1 space-y-1 px-3 py-4 overflow-y-auto">
                {visibleNavigation.map((item) => {
                    const isActive = location.pathname === item.href
                    return (
                        <NavLink
                            key={item.name}
                            to={item.href}
                            className={cn(
                                'flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-all duration-200',
                                isActive
                                    ? 'bg-[var(--color-primary-600)]/15 text-[var(--color-primary-400)]'
                                    : 'text-[var(--color-text-secondary)] hover:bg-[var(--color-bg-tertiary)] hover:text-[var(--color-text-primary)]'
                            )}
                        >
                            <item.icon className={cn('h-5 w-5', isActive && 'text-[var(--color-primary-400)]')} />
                            {item.name}
                            {/* Removed explicit "SA" badge for super admin routes */}
                        </NavLink>
                    )
                })}
            </nav>

            {/* Theme Switcher */}
            <div className="px-4 py-3 border-t border-[var(--color-border)]">
                <div className="flex items-center justify-between">
                    <span className="text-xs text-[var(--color-text-muted)]">Theme</span>
                    <ThemeSwitcherCompact />
                </div>
            </div>

            {/* Logout */}
            <div className="border-t border-[var(--color-border)] p-3">
                <button
                    onClick={handleLogout}
                    className="flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium text-[var(--color-text-secondary)] transition-all duration-200 hover:bg-[var(--color-danger-500)]/10 hover:text-[var(--color-danger-500)]"
                >
                    <LogOut className="h-5 w-5" />
                    Sign Out
                </button>
            </div>
        </aside>
    )
}

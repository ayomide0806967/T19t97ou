import { Outlet } from 'react-router-dom'
import { Sidebar } from './Sidebar'
import type { AdminRole } from '@/types/database'

interface LayoutProps {
    role: AdminRole | null
}

export function Layout({ role }: LayoutProps) {
    return (
        <div className="min-h-screen bg-[var(--color-bg-primary)]">
            <Sidebar role={role} />
            <main className="pl-64">
                <div className="min-h-screen">
                    <Outlet />
                </div>
            </main>
        </div>
    )
}

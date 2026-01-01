import { useState, useEffect } from 'react'
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { supabase, getAdminRole, isConfigured } from '@/lib/supabase'
import { ThemeProvider } from '@/hooks/ThemeProvider'
import { Layout } from '@/components/Layout'
import { LoginPage } from '@/pages/Login'
import { DashboardPage } from '@/pages/Dashboard'
import { UsersPage } from '@/pages/Users'
import { PostsPage } from '@/pages/Posts'
import { PlansPage } from '@/pages/Plans'
import { StoragePage } from '@/pages/Storage'
import { AlgorithmPage } from '@/pages/Algorithm'
import { AuditLogPage } from '@/pages/AuditLog'
import { SettingsPage } from '@/pages/Settings'
import { ReportsPage } from '@/pages/Reports'
import { NotificationsPage } from '@/pages/Notifications'
import { MessagesPage } from '@/pages/Messages'
import { AnalyticsPage } from '@/pages/Analytics'
import type { AdminRole } from '@/types/database'
import './index.css'

// Configuration error screen
function ConfigurationError() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-[var(--color-bg-primary)] p-4">
      <div className="max-w-md text-center">
        <div className="mb-6 text-6xl">⚠️</div>
        <h1 className="mb-4 text-2xl font-bold text-[var(--color-text-primary)]">
          Configuration Required
        </h1>
        <p className="mb-6 text-[var(--color-text-secondary)]">
          The admin panel needs Supabase credentials to work.
        </p>
        <div className="rounded-xl bg-[var(--color-bg-secondary)] p-4 text-left">
          <p className="mb-2 text-sm font-medium text-[var(--color-text-primary)]">
            Create a <code className="text-[var(--color-primary-400)]">.env</code> file:
          </p>
          <pre className="overflow-x-auto rounded-lg bg-[var(--color-bg-tertiary)] p-3 text-xs text-[var(--color-text-secondary)]">
            {`VITE_SUPABASE_URL=https://xxx.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key`}
          </pre>
          <p className="mt-3 text-xs text-[var(--color-text-muted)]">
            Then restart the dev server: <code>npm run dev</code>
          </p>
        </div>
      </div>
    </div>
  )
}

function AppContent() {
  const [isAuthenticated, setIsAuthenticated] = useState<boolean | null>(null)
  const [adminRole, setAdminRole] = useState<AdminRole | null>(null)

  async function checkAuth() {
    const { data: { session } } = await supabase.auth.getSession()

    if (!session) {
      setIsAuthenticated(false)
      setAdminRole(null)
      return
    }

    const role = await getAdminRole()
    if (!role) {
      // User is logged in but not an admin
      await supabase.auth.signOut()
      setIsAuthenticated(false)
      setAdminRole(null)
      return
    }

    setIsAuthenticated(true)
    setAdminRole(role)
  }

  useEffect(() => {
    if (!isConfigured) return

    // Check initial auth state
    Promise.resolve().then(() => {
      void checkAuth()
    })

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange((event) => {
      if (event === 'SIGNED_OUT') {
        setIsAuthenticated(false)
        setAdminRole(null)
      } else if (event === 'SIGNED_IN') {
        checkAuth()
      }
    })

    return () => subscription.unsubscribe()
  }, [])

  // Show configuration error if env vars missing
  if (!isConfigured) {
    return <ConfigurationError />
  }

  // Loading state
  if (isAuthenticated === null) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-[var(--color-bg-primary)]">
        <div className="text-center">
          <div className="mb-4 h-10 w-10 animate-spin rounded-full border-2 border-[var(--color-primary-500)] border-t-transparent mx-auto" />
          <p className="text-[var(--color-text-muted)]">Loading...</p>
        </div>
      </div>
    )
  }

  // Not authenticated - show login
  if (!isAuthenticated) {
    return <LoginPage onLogin={checkAuth} />
  }

  // Protected role check for certain routes
  const isSuperAdmin = adminRole === 'super_admin'
  const isModerator = adminRole === 'moderator' || adminRole === 'super_admin'
  const isSupport = Boolean(adminRole)

  return (
    <BrowserRouter>
      <Routes>
        <Route element={<Layout role={adminRole} />}>
          <Route path="/" element={<DashboardPage />} />
          <Route path="/users" element={<UsersPage />} />
          <Route path="/audit" element={<AuditLogPage />} />

          {/* Moderator+ routes */}
          <Route
            path="/posts"
            element={isSupport ? <PostsPage role={adminRole!} /> : <Navigate to="/" />}
          />
          <Route
            path="/reports"
            element={isModerator ? <ReportsPage /> : <Navigate to="/" />}
          />

          {/* Super Admin only routes */}
          <Route
            path="/plans"
            element={isSuperAdmin ? <PlansPage /> : <Navigate to="/" />}
          />
          <Route
            path="/storage"
            element={isSuperAdmin ? <StoragePage /> : <Navigate to="/" />}
          />
          <Route
            path="/algorithm"
            element={isSuperAdmin ? <AlgorithmPage /> : <Navigate to="/" />}
          />
          <Route
            path="/notifications"
            element={isSuperAdmin ? <NotificationsPage /> : <Navigate to="/" />}
          />
          <Route
            path="/messages"
            element={isSuperAdmin ? <MessagesPage /> : <Navigate to="/" />}
          />
          <Route
            path="/analytics"
            element={isSuperAdmin ? <AnalyticsPage /> : <Navigate to="/" />}
          />
          <Route
            path="/settings"
            element={isSuperAdmin ? <SettingsPage /> : <Navigate to="/" />}
          />

          {/* Fallback */}
          <Route path="*" element={<Navigate to="/" />} />
        </Route>
      </Routes>
    </BrowserRouter>
  )
}

function App() {
  return (
    <ThemeProvider>
      <AppContent />
    </ThemeProvider>
  )
}

export default App

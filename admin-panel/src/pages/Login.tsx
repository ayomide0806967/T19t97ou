import { useState } from 'react'
import { Shield, Mail, Lock, AlertCircle, Loader2 } from 'lucide-react'
import { supabase } from '@/lib/supabase'

interface LoginPageProps {
    onLogin: () => void
}

export function LoginPage({ onLogin }: LoginPageProps) {
    const [email, setEmail] = useState('')
    const [password, setPassword] = useState('')
    const [error, setError] = useState<string | null>(null)
    const [isLoading, setIsLoading] = useState(false)

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault()
        setError(null)
        setIsLoading(true)

        try {
            const { error: authError } = await supabase.auth.signInWithPassword({
                email,
                password,
            })

            if (authError) throw authError

            // Check if user is an admin
            const { data: { user } } = await supabase.auth.getUser()
            if (!user) throw new Error('Authentication failed')

            const { data: adminUser } = await supabase
                .from('admin_users')
                .select('role, is_active')
                .eq('user_id', user.id)
                .single()

            const admin = adminUser as { role: string; is_active: boolean } | null
            if (!admin || !admin.is_active) {
                await supabase.auth.signOut()
                throw new Error('Access denied. You are not an admin.')
            }

            onLogin()
        } catch (err) {
            setError(err instanceof Error ? err.message : 'Login failed')
        } finally {
            setIsLoading(false)
        }
    }

    return (
        <div className="flex min-h-screen items-center justify-center bg-[var(--color-bg-primary)] p-4">
            {/* Background decoration */}
            <div className="pointer-events-none fixed inset-0 overflow-hidden">
                <div className="absolute -left-1/4 -top-1/4 h-96 w-96 rounded-full bg-white/5 blur-3xl" />
                <div className="absolute -bottom-1/4 -right-1/4 h-96 w-96 rounded-full bg-white/10 blur-3xl" />
            </div>

            <div className="relative w-full max-w-md animate-fadeIn">
                {/* Card */}
                <div className="glass rounded-2xl border border-[var(--color-border)] p-8 shadow-2xl shadow-black/40">
                    {/* Logo */}
                    <div className="mb-8 flex flex-col items-center">
                        <div className="mb-3 inline-flex items-center gap-2 rounded-full border border-[var(--color-border)] bg-[var(--color-bg-secondary)] px-3 py-1 text-xs font-medium uppercase tracking-[0.2em] text-[var(--color-text-muted)]">
                            Admin
                        </div>
                        <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-secondary)] shadow-lg">
                            <Shield className="h-8 w-8 text-white" />
                        </div>
                        <h1 className="text-2xl font-semibold tracking-tight text-[var(--color-text-primary)]">
                            IN Admin Panel
                        </h1>
                        <p className="mt-1 text-sm text-[var(--color-text-muted)]">
                            Sign in to access the dashboard
                        </p>
                    </div>

                    {/* Form */}
                    <form onSubmit={handleSubmit} className="space-y-5">
                        {/* Email */}
                        <div>
                            <label className="mb-2 block text-sm font-medium text-[var(--color-text-secondary)]">
                                Email
                            </label>
                            <div className="relative">
                                <Mail className="absolute left-3 top-1/2 h-5 w-5 -translate-y-1/2 text-[var(--color-text-muted)]" />
                                <input
                                    type="email"
                                    value={email}
                                    onChange={(e) => setEmail(e.target.value)}
                                    className="input pl-10"
                                    placeholder="admin@example.com"
                                    required
                                />
                            </div>
                        </div>

                        {/* Password */}
                        <div>
                            <label className="mb-2 block text-sm font-medium text-[var(--color-text-secondary)]">
                                Password
                            </label>
                            <div className="relative">
                                <Lock className="absolute left-3 top-1/2 h-5 w-5 -translate-y-1/2 text-[var(--color-text-muted)]" />
                                <input
                                    type="password"
                                    value={password}
                                    onChange={(e) => setPassword(e.target.value)}
                                    className="input pl-10"
                                    placeholder="••••••••"
                                    required
                                />
                            </div>
                        </div>

                        {/* Error */}
                        {error && (
                            <div className="flex items-center gap-2 rounded-lg bg-[var(--color-danger-500)]/10 p-3 text-sm text-[var(--color-danger-500)]">
                                <AlertCircle className="h-4 w-4 shrink-0" />
                                {error}
                            </div>
                        )}

                        {/* Submit */}
                        <button
                            type="submit"
                            disabled={isLoading}
                            className="btn btn-primary w-full disabled:opacity-70 disabled:cursor-not-allowed"
                        >
                            {isLoading ? (
                                <>
                                    <Loader2 className="h-4 w-4 animate-spin" />
                                    Signing in...
                                </>
                            ) : (
                                'Sign In'
                            )}
                        </button>
                    </form>
                </div>

                {/* Footer */}
                <p className="mt-6 text-center text-xs text-[var(--color-text-muted)]">
                    IN Institution Admin Panel • Authorized access only
                </p>
            </div>
        </div>
    )
}

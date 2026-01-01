import { createClient, SupabaseClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || ''
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || ''

// Check if environment is configured
export const isConfigured = Boolean(supabaseUrl && supabaseAnonKey)

// Create client (will be null-ish operations if not configured, but won't crash)
export const supabase: SupabaseClient = createClient(
    supabaseUrl || 'https://placeholder.supabase.co',
    supabaseAnonKey || 'placeholder-key',
    {
        auth: {
            persistSession: true,
            autoRefreshToken: true,
        },
    }
)

// Helper to get the current user's admin role
export async function getAdminRole(): Promise<'support' | 'moderator' | 'super_admin' | null> {
    if (!isConfigured) return null

    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return null

    const { data: adminUser } = await supabase
        .from('admin_users')
        .select('role, is_active')
        .eq('user_id', user.id)
        .single()

    const admin = adminUser as { role: string; is_active: boolean } | null
    if (!admin || !admin.is_active) return null
    return admin.role as 'support' | 'moderator' | 'super_admin'
}

// Check if user has at least the required role
export function hasPermission(
    userRole: 'support' | 'moderator' | 'super_admin' | null,
    requiredRole: 'support' | 'moderator' | 'super_admin'
): boolean {
    if (!userRole) return false

    const roleHierarchy = {
        'support': 1,
        'moderator': 2,
        'super_admin': 3,
    }

    return roleHierarchy[userRole] >= roleHierarchy[requiredRole]
}

import { createClient, type SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.89.0?target=deno'

export function createSupabaseAdmin(): SupabaseClient {
  const url = Deno.env.get('SUPABASE_URL')
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

  if (!url || !serviceKey) {
    throw new Error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY')
  }

  return createClient(url, serviceKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  })
}

export type AdminRole = 'support' | 'moderator' | 'super_admin'

export function hasRole(userRole: AdminRole, required: AdminRole): boolean {
  const rank: Record<AdminRole, number> = { support: 1, moderator: 2, super_admin: 3 }
  return rank[userRole] >= rank[required]
}


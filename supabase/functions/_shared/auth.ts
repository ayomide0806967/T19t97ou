import type { SupabaseClient, User } from 'https://esm.sh/@supabase/supabase-js@2.89.0?target=deno'
import { hasRole, type AdminRole } from './supabase.ts'

export type AdminUserRow = {
  user_id: string
  role: AdminRole
  is_active: boolean
}

export async function requireUser(req: Request, supabaseAdmin: SupabaseClient): Promise<User> {
  const authHeader = req.headers.get('Authorization') ?? ''
  const token = authHeader.startsWith('Bearer ') ? authHeader.slice('Bearer '.length) : ''
  if (!token) {
    throw new HttpError(401, 'Missing Authorization bearer token')
  }

  const { data, error } = await supabaseAdmin.auth.getUser(token)
  if (error || !data.user) {
    throw new HttpError(401, 'Invalid token')
  }

  return data.user
}

export async function requireAdmin(
  supabaseAdmin: SupabaseClient,
  userId: string,
  requiredRole: AdminRole,
): Promise<AdminUserRow> {
  const { data, error } = await supabaseAdmin
    .from('admin_users')
    .select('user_id, role, is_active')
    .eq('user_id', userId)
    .maybeSingle()

  if (error || !data) {
    throw new HttpError(403, 'Not an admin')
  }

  const admin = data as AdminUserRow
  if (!admin.is_active) {
    throw new HttpError(403, 'Admin account is inactive')
  }
  if (!hasRole(admin.role, requiredRole)) {
    throw new HttpError(403, 'Insufficient role')
  }
  return admin
}

export class HttpError extends Error {
  status: number
  constructor(status: number, message: string) {
    super(message)
    this.status = status
  }
}


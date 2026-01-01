// Database types - these should be generated from Supabase
// For now, we define them manually based on the migration files

export type Database = {
    public: {
        Tables: {
            profiles: {
                Row: {
                    user_id: string
                    handle: string
                    display_name: string | null
                    bio: string | null
                    avatar_url: string | null
                    cover_url: string | null
                    verified_type: 'none' | 'verified' | 'creator' | 'institution'
                    verified_at: string | null
                    verified_by: string | null
                    is_private: boolean
                    created_at: string
                    updated_at: string
                }
                Insert: Partial<Database['public']['Tables']['profiles']['Row']> & { user_id: string }
                Update: Partial<Database['public']['Tables']['profiles']['Row']>
            }
            admin_users: {
                Row: {
                    user_id: string
                    role: 'support' | 'moderator' | 'super_admin'
                    is_active: boolean
                    dm_access_enabled: boolean
                    created_at: string
                    created_by: string | null
                }
                Insert: {
                    user_id: string
                    role: 'support' | 'moderator' | 'super_admin'
                    is_active?: boolean
                    dm_access_enabled?: boolean
                    created_by?: string
                }
                Update: Partial<Database['public']['Tables']['admin_users']['Row']>
            }
            admin_audit_logs: {
                Row: {
                    id: string
                    actor_user_id: string
                    actor_role: string
                    action: string
                    target_type: string | null
                    target_id: string | null
                    before_json: Record<string, unknown> | null
                    after_json: Record<string, unknown> | null
                    ip: string | null
                    user_agent: string | null
                    created_at: string
                }
                Insert: Omit<Database['public']['Tables']['admin_audit_logs']['Row'], 'id' | 'created_at'>
                Update: never
            }
            admin_settings: {
                Row: {
                    key: string
                    value: Record<string, unknown>
                    updated_by: string | null
                    updated_at: string
                }
                Insert: {
                    key: string
                    value: Record<string, unknown>
                    updated_by?: string
                }
                Update: Partial<Database['public']['Tables']['admin_settings']['Row']>
            }
            plans: {
                Row: {
                    code: string
                    name: string
                    description: string | null
                    limits: {
                        max_active_classes?: number
                        max_members_per_class?: number
                        max_quiz_participants?: number
                        max_active_published_quizzes?: number
                        storage_limit_mb?: number
                    }
                    features: {
                        checkmark_eligible?: boolean
                        [key: string]: boolean | undefined
                    }
                    is_active: boolean
                    created_at: string
                    updated_at: string
                }
                Insert: Omit<Database['public']['Tables']['plans']['Row'], 'created_at' | 'updated_at'>
                Update: Partial<Database['public']['Tables']['plans']['Row']>
            }
            user_subscriptions: {
                Row: {
                    user_id: string
                    plan_code: string
                    status: 'active' | 'canceled' | 'expired' | 'trial'
                    provider: string | null
                    provider_ref: string | null
                    started_at: string
                    expires_at: string | null
                    created_at: string
                }
                Insert: Omit<Database['public']['Tables']['user_subscriptions']['Row'], 'created_at'>
                Update: Partial<Database['public']['Tables']['user_subscriptions']['Row']>
            }
            posts: {
                Row: {
                    id: string
                    author_id: string
                    content: string
                    media_urls: string[]
                    is_removed: boolean
                    removed_reason: string | null
                    created_at: string
                    updated_at: string
                }
                Insert: Omit<Database['public']['Tables']['posts']['Row'], 'id' | 'created_at' | 'updated_at'>
                Update: Partial<Database['public']['Tables']['posts']['Row']>
            }
            classes: {
                Row: {
                    id: string
                    owner_id: string
                    name: string
                    description: string | null
                    type: 'public' | 'private' | 'invite_only'
                    member_count: number
                    is_active: boolean
                    created_at: string
                }
                Insert: Omit<Database['public']['Tables']['classes']['Row'], 'id' | 'created_at' | 'member_count'>
                Update: Partial<Database['public']['Tables']['classes']['Row']>
            }
            quizzes: {
                Row: {
                    id: string
                    creator_id: string
                    title: string
                    description: string | null
                    is_published: boolean
                    attempt_count: number
                    created_at: string
                }
                Insert: Omit<Database['public']['Tables']['quizzes']['Row'], 'id' | 'created_at' | 'attempt_count'>
                Update: Partial<Database['public']['Tables']['quizzes']['Row']>
            }
        }
        Views: Record<string, unknown>
        Functions: Record<string, unknown>
    }
}

// Convenience types
export type Profile = Database['public']['Tables']['profiles']['Row']
export type AdminUser = Database['public']['Tables']['admin_users']['Row']
export type AuditLog = Database['public']['Tables']['admin_audit_logs']['Row']
export type AdminSetting = Database['public']['Tables']['admin_settings']['Row']
export type Plan = Database['public']['Tables']['plans']['Row']
export type UserSubscription = Database['public']['Tables']['user_subscriptions']['Row']
export type Post = Database['public']['Tables']['posts']['Row']
export type Class = Database['public']['Tables']['classes']['Row']
export type Quiz = Database['public']['Tables']['quizzes']['Row']

// Admin role type
export type AdminRole = 'support' | 'moderator' | 'super_admin'

// User with profile and subscription
export type UserWithDetails = Profile & {
    subscription?: UserSubscription | null
    admin?: AdminUser | null
}

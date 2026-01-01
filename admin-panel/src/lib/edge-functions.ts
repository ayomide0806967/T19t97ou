import { supabase } from './supabase'

const EDGE_FUNCTION_URL = import.meta.env.VITE_SUPABASE_URL + '/functions/v1'

interface EdgeFunctionResponse<T = unknown> {
    data: T | null
    error: string | null
}

async function callEdgeFunction<T>(
    functionName: string,
    action: string,
    payload: Record<string, unknown>
): Promise<EdgeFunctionResponse<T>> {
    const { data: { session } } = await supabase.auth.getSession()

    if (!session) {
        return { data: null, error: 'Not authenticated' }
    }

    try {
        const response = await fetch(`${EDGE_FUNCTION_URL}/${functionName}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${session.access_token}`,
            },
            body: JSON.stringify({ action, ...payload }),
        })

        const result = await response.json()

        if (!response.ok) {
            return { data: null, error: result.error || 'Request failed' }
        }

        return { data: result.data, error: null }
    } catch (err) {
        return { data: null, error: err instanceof Error ? err.message : 'Unknown error' }
    }
}

// User Management Functions
export const adminUsers = {
    setVerification: (
        userId: string,
        verificationType: 'none' | 'verified' | 'creator' | 'institution',
        expiresAt?: string | null
    ) =>
        callEdgeFunction('admin-users', 'set-verification', { userId, verificationType, expiresAt }),

    setPlan: (userId: string, planCode: string) =>
        callEdgeFunction('admin-users', 'set-plan', { userId, planCode }),

    updateProfile: (userId: string, updates: Record<string, unknown>) =>
        callEdgeFunction('admin-users', 'update-profile', { userId, updates }),

    lockUser: (userId: string, lockUntil: string | null, reason: string) =>
        callEdgeFunction('admin-users', 'lock-user', { userId, lockUntil, reason }),

    unlockUser: (userId: string) =>
        callEdgeFunction('admin-users', 'unlock-user', { userId }),

    setBoost: (userId: string, multiplier: number, expiresAt: string | null) =>
        callEdgeFunction('admin-users', 'set-boost', { userId, multiplier, expiresAt }),
}

// Storage Management Functions
export const adminStorage = {
    deleteFile: (bucket: string, path: string) =>
        callEdgeFunction('admin-storage', 'delete-file', { bucket, path }),

    deleteFiles: (bucket: string, paths: string[]) =>
        callEdgeFunction('admin-storage', 'delete-files', { bucket, paths }),

    listBucket: (bucket: string, path?: string) =>
        callEdgeFunction('admin-storage', 'list-bucket', { bucket, path }),
}

// Moderation Functions
export const adminModeration = {
    removeContent: (contentType: string, contentId: string, reason: string) =>
        callEdgeFunction('admin-moderation', 'remove-content', { contentType, contentId, reason }),

    restoreContent: (contentType: string, contentId: string) =>
        callEdgeFunction('admin-moderation', 'restore-content', { contentType, contentId }),
}

// Plans Management
export const adminPlans = {
    list: () => callEdgeFunction('admin-plans', 'list', {}),
    create: (plan: Record<string, unknown>) => callEdgeFunction('admin-plans', 'create', { plan }),
    update: (code: string, patch: Record<string, unknown>) => callEdgeFunction('admin-plans', 'update', { code, patch }),
    delete: (code: string) => callEdgeFunction('admin-plans', 'delete', { code }),
}

// Admin Settings
export const adminSettings = {
    list: (like: string) => callEdgeFunction('admin-settings', 'list', { like }),
    upsert: (settings: Array<{ key: string; value: Record<string, unknown> }>) =>
        callEdgeFunction('admin-settings', 'upsert', { settings }),
}

// Audit Logs
export const adminAudit = {
    list: (limit = 500) => callEdgeFunction('admin-audit', 'list', { limit }),
    listForTarget: (targetType: string, targetId: string, limit = 200) =>
        callEdgeFunction('admin-audit', 'list-for-target', { targetType, targetId, limit }),
    log: (actionName: string, targetType?: string | null, targetId?: string | null, beforeJson?: unknown | null, afterJson?: unknown | null) =>
        callEdgeFunction('admin-audit', 'log', { actionName, targetType, targetId, beforeJson, afterJson }),
}

// Admin Users (who can access the panel)
export const adminAdmins = {
    list: () => callEdgeFunction('admin-admins', 'list', {}),
    add: (email: string, role: 'support' | 'moderator' | 'super_admin') =>
        callEdgeFunction('admin-admins', 'add-admin', { email, role }),
    setActive: (userId: string, isActive: boolean) =>
        callEdgeFunction('admin-admins', 'set-active', { userId, isActive }),
    setDmAccess: (userId: string, enabled: boolean) =>
        callEdgeFunction('admin-admins', 'set-dm-access', { userId, enabled }),
    setRole: (userId: string, role: 'support' | 'moderator' | 'super_admin') =>
        callEdgeFunction('admin-admins', 'set-role', { userId, role }),
}

// Posts (trending + moderation)
export const adminPosts = {
    trending: (limit = 10) => callEdgeFunction('admin-posts', 'trending', { limit }),
    list: (params?: { limit?: number; status?: 'active' | 'removed' | 'all'; query?: string }) =>
        callEdgeFunction('admin-posts', 'list', { ...params }),
    remove: (postId: string, reason: string) => callEdgeFunction('admin-posts', 'remove', { postId, reason }),
    restore: (postId: string) => callEdgeFunction('admin-posts', 'restore', { postId }),
    setTrending: (postId: string, multiplier: number, excludeFromTrending: boolean, note?: string | null) =>
        callEdgeFunction('admin-posts', 'set-trending', { postId, multiplier, excludeFromTrending, note }),
}

// Reports (content moderation)
export const adminReports = {
    list: (params?: { status?: string; limit?: number }) =>
        callEdgeFunction('admin-reports', 'list', { ...params }),
    updateStatus: (reportId: string, status: string, resolutionNotes?: string, actionTaken?: string) =>
        callEdgeFunction('admin-reports', 'update-status', { reportId, status, resolutionNotes, actionTaken }),
}

// Messages (DM oversight - super_admin only)
export const adminMessages = {
    listConversations: (params?: { limit?: number; query?: string }) =>
        callEdgeFunction('admin-messages', 'list-conversations', { ...params }),
    getMessages: (conversationId: string, limit?: number) =>
        callEdgeFunction('admin-messages', 'get-messages', { conversationId, limit }),
}

// Analytics
export const adminAnalytics = {
    stats: () => callEdgeFunction('admin-analytics', 'stats', {}),
    topContent: (limit = 10) => callEdgeFunction('admin-analytics', 'top-content', { limit }),
    topUsers: (limit = 10) => callEdgeFunction('admin-analytics', 'top-users', { limit }),
}

// Broadcasts (admin notifications)
export const adminBroadcasts = {
    list: (limit = 50) => callEdgeFunction('admin-broadcasts', 'list', { limit }),
    create: (title: string, body: string, targetType: string, targetId?: string, scheduledAt?: string) =>
        callEdgeFunction('admin-broadcasts', 'create', { title, body, targetType, targetId, scheduledAt }),
}

export type ModerationTrendingSettings = {
    like_weight: number
    repost_weight: number
    reply_weight: number
    bookmark_weight: number
    time_decay_hours: number
    min_interactions: number
    max_candidates: number
}

export type ModerationPostSettings = {
    require_removal_reason: boolean
    allow_restore_post: boolean
    default_removal_reasons: string[]
}

export type ModerationSettings = {
    trending: ModerationTrendingSettings
    posts: ModerationPostSettings
}

export const moderationDefaults: ModerationSettings = {
    trending: {
        like_weight: 1.0,
        repost_weight: 2.0,
        reply_weight: 1.5,
        bookmark_weight: 0.5,
        time_decay_hours: 24,
        min_interactions: 5,
        max_candidates: 500,
    },
    posts: {
        require_removal_reason: true,
        allow_restore_post: true,
        default_removal_reasons: [
            'Spam',
            'Harassment / Hate',
            'Nudity / Sexual content',
            'Violence / Threats',
            'Impersonation',
            'Copyright / IP',
            'Other (see note)',
        ],
    },
}


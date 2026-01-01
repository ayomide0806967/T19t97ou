import { useState, useEffect } from 'react'
import {
    Search, Eye, AlertTriangle,
    ChevronRight, X, Shield
} from 'lucide-react'
import { adminMessages, adminAudit } from '@/lib/edge-functions'
import { formatDate, cn } from '@/lib/utils'

// ============================================================================
// Types
// ============================================================================

interface Conversation {
    id: string
    participant_1: {
        id: string
        handle: string
        full_name: string
        avatar_url: string | null
    } | null
    participant_2: {
        id: string
        handle: string
        full_name: string
        avatar_url: string | null
    } | null
    last_message: string
    last_message_at: string
    message_count: number
}

interface Message {
    id: string
    sender_id: string
    sender: {
        handle: string
        full_name: string
    } | null
    body: string
    created_at: string
    deleted_at: string | null
}

// ============================================================================
// Components
// ============================================================================

function UserAvatar({ name, size = 'md' }: { name: string; size?: 'sm' | 'md' | 'lg' }) {
    const sizes = {
        sm: 'h-8 w-8 text-xs',
        md: 'h-10 w-10 text-sm',
        lg: 'h-12 w-12 text-base',
    }
    return (
        <div className={cn(
            'flex items-center justify-center rounded-full bg-gradient-to-br from-[var(--color-primary-600)] to-[var(--color-primary-400)] font-semibold text-white',
            sizes[size]
        )}>
            {name[0].toUpperCase()}
        </div>
    )
}

interface ConversationViewerProps {
    conversation: Conversation
    messages: Message[]
    onClose: () => void
}

function ConversationViewer({ conversation, messages, onClose }: ConversationViewerProps) {
    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
            <div className="glass w-full max-w-2xl rounded-2xl animate-fadeIn max-h-[85vh] flex flex-col">
                {/* Header */}
                <div className="flex items-center justify-between border-b border-[var(--color-border)] p-4">
                    <div className="flex items-center gap-3">
                        <div className="flex -space-x-2">
                            <UserAvatar name={conversation.participant_1?.full_name || 'U'} size="sm" />
                            <UserAvatar name={conversation.participant_2?.full_name || 'U'} size="sm" />
                        </div>
                        <div>
                            <p className="font-medium text-[var(--color-text-primary)]">
                                @{conversation.participant_1?.handle || 'unknown'} ↔ @{conversation.participant_2?.handle || 'unknown'}
                            </p>
                            <p className="text-xs text-[var(--color-text-muted)]">
                                {messages.length} messages
                            </p>
                        </div>
                    </div>
                    <button onClick={onClose} className="btn-ghost rounded-lg p-2">
                        <X className="h-5 w-5" />
                    </button>
                </div>

                {/* Warning */}
                <div className="border-b border-[var(--color-border)] bg-[var(--color-warning-500)]/10 px-4 py-2">
                    <p className="flex items-center gap-2 text-xs text-[var(--color-warning-500)]">
                        <AlertTriangle className="h-4 w-4" />
                        <span>
                            <strong>Super Admin Access:</strong> This conversation is private. Access is logged for audit purposes.
                        </span>
                    </p>
                </div>

                {/* Messages */}
                <div className="flex-1 overflow-y-auto p-4 space-y-3">
                    {messages.length === 0 ? (
                        <p className="text-center text-[var(--color-text-muted)]">No messages in this conversation</p>
                    ) : (
                        messages.map((msg) => (
                            <div key={msg.id} className="flex gap-3">
                                <UserAvatar name={msg.sender?.full_name || 'U'} size="sm" />
                                <div className="flex-1">
                                    <div className="flex items-center gap-2">
                                        <span className="text-sm font-medium text-[var(--color-text-primary)]">
                                            {msg.sender?.full_name || 'Unknown'}
                                        </span>
                                        <span className="text-xs text-[var(--color-text-muted)]">
                                            @{msg.sender?.handle || 'unknown'}
                                        </span>
                                        <span className="text-xs text-[var(--color-text-muted)]">
                                            {formatDate(msg.created_at)}
                                        </span>
                                    </div>
                                    <p className={cn(
                                        'mt-1 text-sm',
                                        msg.deleted_at
                                            ? 'italic text-[var(--color-text-muted)]'
                                            : 'text-[var(--color-text-secondary)]'
                                    )}>
                                        {msg.deleted_at ? '[Message deleted]' : msg.body}
                                    </p>
                                </div>
                            </div>
                        ))
                    )}
                </div>

                {/* Footer */}
                <div className="border-t border-[var(--color-border)] p-4">
                    <p className="text-xs text-[var(--color-text-muted)] text-center">
                        View-only mode. Messages cannot be sent from admin panel.
                    </p>
                </div>
            </div>
        </div>
    )
}

// ============================================================================
// Main Page
// ============================================================================

export function MessagesPage() {
    const [conversations, setConversations] = useState<Conversation[]>([])
    const [isLoading, setIsLoading] = useState(true)
    const [searchQuery, setSearchQuery] = useState('')
    const [selectedConversation, setSelectedConversation] = useState<Conversation | null>(null)
    const [selectedMessages, setSelectedMessages] = useState<Message[]>([])
    const [hasConfirmedAccess, setHasConfirmedAccess] = useState(false)

    useEffect(() => {
        if (hasConfirmedAccess) {
            loadConversations()
        }
    }, [hasConfirmedAccess])

    async function loadConversations() {
        setIsLoading(true)
        try {
            const res = await adminMessages.listConversations({ limit: 50 })
            if (res.data) {
                setConversations(res.data as Conversation[])
            }
        } catch (err) {
            console.error('Failed to load conversations:', err)
        } finally {
            setIsLoading(false)
        }
    }

    const filteredConversations = conversations.filter(c =>
        c.participant_1?.handle?.toLowerCase().includes(searchQuery.toLowerCase()) ||
        c.participant_2?.handle?.toLowerCase().includes(searchQuery.toLowerCase()) ||
        c.participant_1?.full_name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
        c.participant_2?.full_name?.toLowerCase().includes(searchQuery.toLowerCase())
    )

    async function handleViewConversation(conversation: Conversation) {
        // Log the access
        await adminAudit.log(
            'dm_conversation_viewed',
            'conversation',
            conversation.id,
            null,
            {
                participant_1: conversation.participant_1?.handle,
                participant_2: conversation.participant_2?.handle,
            }
        )

        // Load messages
        try {
            const res = await adminMessages.getMessages(conversation.id, 100)
            if (res.data) {
                setSelectedMessages(res.data as Message[])
            }
        } catch (err) {
            console.error('Failed to load messages:', err)
            setSelectedMessages([])
        }
        setSelectedConversation(conversation)
    }

    // Access confirmation gate
    if (!hasConfirmedAccess) {
        return (
            <div className="flex min-h-[60vh] items-center justify-center p-8">
                <div className="max-w-md text-center">
                    <div className="mx-auto mb-6 flex h-16 w-16 items-center justify-center rounded-2xl bg-[var(--color-warning-500)]/15">
                        <Shield className="h-8 w-8 text-[var(--color-warning-500)]" />
                    </div>
                    <h1 className="mb-2 text-2xl font-bold text-[var(--color-text-primary)]">
                        Direct Message Oversight
                    </h1>
                    <p className="mb-6 text-[var(--color-text-secondary)]">
                        This area allows viewing private conversations between users.
                        All access is logged for audit purposes.
                    </p>
                    <div className="mb-6 rounded-xl border border-[var(--color-warning-500)]/30 bg-[var(--color-warning-500)]/10 p-4 text-left">
                        <p className="text-sm text-[var(--color-warning-500)]">
                            <strong>Important:</strong> Only access messages when required for:
                        </p>
                        <ul className="mt-2 space-y-1 text-sm text-[var(--color-warning-500)]">
                            <li>• Investigating reported content</li>
                            <li>• Responding to legal requests</li>
                            <li>• Addressing safety concerns</li>
                        </ul>
                    </div>
                    <button
                        onClick={() => setHasConfirmedAccess(true)}
                        className="btn btn-primary"
                    >
                        <Eye className="h-4 w-4" />
                        I Understand, Continue
                    </button>
                </div>
            </div>
        )
    }

    return (
        <div className="p-8">
            {/* Header */}
            <div className="mb-8">
                <h1 className="text-2xl font-bold text-[var(--color-text-primary)]">Messages</h1>
                <p className="mt-1 text-[var(--color-text-muted)]">
                    View private conversations (Super Admin only)
                </p>
            </div>

            {/* Warning Banner */}
            <div className="mb-6 rounded-xl border border-[var(--color-warning-500)]/30 bg-[var(--color-warning-500)]/10 p-4">
                <p className="flex items-center gap-2 text-sm text-[var(--color-warning-500)]">
                    <AlertTriangle className="h-5 w-5" />
                    <span>
                        All message access is logged. Only view conversations when necessary for moderation or legal purposes.
                    </span>
                </p>
            </div>

            {/* Search */}
            <div className="mb-6">
                <div className="relative">
                    <Search className="absolute left-3 top-1/2 h-5 w-5 -translate-y-1/2 text-[var(--color-text-muted)]" />
                    <input
                        type="text"
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        placeholder="Search by username or handle..."
                        className="input pl-10"
                    />
                </div>
            </div>

            {/* Conversations List */}
            <div className="card divide-y divide-[var(--color-border)]">
                {isLoading ? (
                    <div className="p-8 text-center text-[var(--color-text-muted)]">
                        Loading conversations...
                    </div>
                ) : filteredConversations.length === 0 ? (
                    <div className="p-8 text-center text-[var(--color-text-muted)]">
                        No conversations found.
                    </div>
                ) : (
                    filteredConversations.map((conversation) => (
                        <button
                            key={conversation.id}
                            onClick={() => handleViewConversation(conversation)}
                            className="flex w-full items-center justify-between p-4 text-left transition-colors hover:bg-[var(--color-bg-tertiary)]"
                        >
                            <div className="flex items-center gap-4">
                                <div className="flex -space-x-2">
                                    <UserAvatar name={conversation.participant_1?.full_name || 'U'} size="md" />
                                    <UserAvatar name={conversation.participant_2?.full_name || 'U'} size="md" />
                                </div>
                                <div>
                                    <p className="font-medium text-[var(--color-text-primary)]">
                                        {conversation.participant_1?.full_name || 'Unknown'} & {conversation.participant_2?.full_name || 'Unknown'}
                                    </p>
                                    <p className="text-sm text-[var(--color-text-muted)]">
                                        @{conversation.participant_1?.handle || 'unknown'} ↔ @{conversation.participant_2?.handle || 'unknown'}
                                    </p>
                                    <p className="mt-1 text-sm text-[var(--color-text-secondary)] line-clamp-1">
                                        {conversation.last_message || 'No messages'}
                                    </p>
                                </div>
                            </div>
                            <div className="flex items-center gap-4">
                                <div className="text-right">
                                    <p className="text-xs text-[var(--color-text-muted)]">
                                        {formatDate(conversation.last_message_at)}
                                    </p>
                                    <p className="text-xs text-[var(--color-text-muted)]">
                                        {conversation.message_count} messages
                                    </p>
                                </div>
                                <ChevronRight className="h-5 w-5 text-[var(--color-text-muted)]" />
                            </div>
                        </button>
                    ))
                )}
            </div>

            {/* Conversation Viewer Modal */}
            {selectedConversation && (
                <ConversationViewer
                    conversation={selectedConversation}
                    messages={selectedMessages}
                    onClose={() => {
                        setSelectedConversation(null)
                        setSelectedMessages([])
                    }}
                />
            )}
        </div>
    )
}

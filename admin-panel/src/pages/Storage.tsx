import { useState, useEffect } from 'react'
import { Folder, File, Trash2, ChevronRight, HardDrive, Image, FileText, RefreshCw } from 'lucide-react'
import { adminStorage } from '@/lib/edge-functions'
import { cn, formatNumber } from '@/lib/utils'

interface StorageItem {
    name: string
    id: string | null
    metadata: {
        size: number
        mimetype: string
    } | null
}

const buckets = [
    { name: 'avatars', icon: Image, description: 'User profile pictures' },
    { name: 'covers', icon: Image, description: 'Profile cover images' },
    { name: 'resources', icon: FileText, description: 'Class resources and files' },
    { name: 'media', icon: Image, description: 'Post media attachments' },
]

export function StoragePage() {
    const [selectedBucket, setSelectedBucket] = useState<string | null>(null)
    const [currentPath, setCurrentPath] = useState<string[]>([])
    const [files, setFiles] = useState<StorageItem[]>([])
    const [isLoading, setIsLoading] = useState(false)
    const [selectedFiles, setSelectedFiles] = useState<Set<string>>(new Set())

    useEffect(() => {
        if (selectedBucket) {
            loadFiles()
        }
    }, [selectedBucket, currentPath])

    async function loadFiles() {
        if (!selectedBucket) return
        setIsLoading(true)
        try {
            const path = currentPath.join('/')
            const { data, error } = await adminStorage.listBucket(selectedBucket, path)
            if (error) throw new Error(error)

            type StorageObject = {
                name: string
                id?: string | null
                metadata?: unknown | null
            }
            const objects: StorageObject[] = Array.isArray(data) ? (data as StorageObject[]) : []
            // Map Supabase FileObject to our StorageItem type
            const mappedFiles: StorageItem[] = objects.map(item => ({
                name: item.name,
                id: item.id || null,
                metadata: item.metadata ? {
                    size: (item.metadata as Record<string, unknown>).size as number || 0,
                    mimetype: (item.metadata as Record<string, unknown>).mimetype as string || 'unknown'
                } : null
            }))
            setFiles(mappedFiles)
        } catch (err) {
            console.error('Failed to load files:', err)
        } finally {
            setIsLoading(false)
        }
    }

    function handleFolderClick(folderName: string) {
        setCurrentPath([...currentPath, folderName])
        setSelectedFiles(new Set())
    }

    function handleBreadcrumbClick(index: number) {
        setCurrentPath(currentPath.slice(0, index))
        setSelectedFiles(new Set())
    }

    function toggleFileSelection(fileName: string) {
        const newSelected = new Set(selectedFiles)
        if (newSelected.has(fileName)) {
            newSelected.delete(fileName)
        } else {
            newSelected.add(fileName)
        }
        setSelectedFiles(newSelected)
    }

    async function handleDelete() {
        if (!selectedBucket || selectedFiles.size === 0) return

        const confirmed = window.confirm(`Delete ${selectedFiles.size} file(s)? This action cannot be undone.`)
        if (!confirmed) return

        try {
            const filesToDelete = Array.from(selectedFiles).map(name =>
                [...currentPath, name].join('/')
            )

            const { error } = await adminStorage.deleteFiles(selectedBucket, filesToDelete)
            if (error) throw new Error(error)

            setSelectedFiles(new Set())
            loadFiles()
        } catch (err) {
            console.error('Failed to delete files:', err)
            alert('Failed to delete files')
        }
    }

    return (
        <div className="p-8">
            {/* Header */}
            <div className="mb-8 flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-[var(--color-text-primary)]">Storage</h1>
                    <p className="mt-1 text-[var(--color-text-muted)]">
                        Browse and manage storage buckets
                    </p>
                </div>
                {selectedBucket && (
                    <div className="flex items-center gap-2">
                        {selectedFiles.size > 0 && (
                            <button onClick={handleDelete} className="btn btn-danger">
                                <Trash2 className="h-4 w-4" />
                                Delete ({selectedFiles.size})
                            </button>
                        )}
                        <button onClick={loadFiles} className="btn btn-secondary">
                            <RefreshCw className="h-4 w-4" />
                            Refresh
                        </button>
                    </div>
                )}
            </div>

            {/* Super Admin Notice */}
            <div className="mb-6 rounded-xl border border-[var(--color-danger-500)]/30 bg-[var(--color-danger-500)]/10 p-4">
                <p className="text-sm text-[var(--color-danger-500)]">
                    <strong>Warning:</strong> Deleting files is permanent and cannot be undone. All deletions are logged.
                </p>
            </div>

            {!selectedBucket ? (
                /* Bucket Selection */
                <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
                    {buckets.map((bucket) => (
                        <button
                            key={bucket.name}
                            onClick={() => setSelectedBucket(bucket.name)}
                            className="card p-6 text-left card-hover"
                        >
                            <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-xl bg-[var(--color-primary-500)]/15">
                                <bucket.icon className="h-6 w-6 text-[var(--color-primary-400)]" />
                            </div>
                            <h3 className="font-semibold text-[var(--color-text-primary)]">{bucket.name}</h3>
                            <p className="mt-1 text-sm text-[var(--color-text-muted)]">{bucket.description}</p>
                        </button>
                    ))}
                </div>
            ) : (
                /* File Browser */
                <div>
                    {/* Breadcrumb */}
                    <div className="mb-4 flex items-center gap-2 text-sm">
                        <button
                            onClick={() => {
                                setSelectedBucket(null)
                                setCurrentPath([])
                                setSelectedFiles(new Set())
                            }}
                            className="text-[var(--color-primary-400)] hover:underline"
                        >
                            Buckets
                        </button>
                        <ChevronRight className="h-4 w-4 text-[var(--color-text-muted)]" />
                        <button
                            onClick={() => handleBreadcrumbClick(0)}
                            className="text-[var(--color-primary-400)] hover:underline"
                        >
                            {selectedBucket}
                        </button>
                        {currentPath.map((folder, index) => (
                            <div key={index} className="flex items-center gap-2">
                                <ChevronRight className="h-4 w-4 text-[var(--color-text-muted)]" />
                                <button
                                    onClick={() => handleBreadcrumbClick(index + 1)}
                                    className="text-[var(--color-primary-400)] hover:underline"
                                >
                                    {folder}
                                </button>
                            </div>
                        ))}
                    </div>

                    {/* Files Grid */}
                    <div className="card overflow-hidden">
                        {isLoading ? (
                            <div className="flex h-64 items-center justify-center text-[var(--color-text-muted)]">
                                <RefreshCw className="mr-2 h-5 w-5 animate-spin" />
                                Loading...
                            </div>
                        ) : files.length === 0 ? (
                            <div className="flex h-64 flex-col items-center justify-center text-[var(--color-text-muted)]">
                                <HardDrive className="mb-2 h-12 w-12 opacity-50" />
                                <p>No files in this location</p>
                            </div>
                        ) : (
                            <div className="divide-y divide-[var(--color-border)]">
                                {files.map((item) => {
                                    const isFolder = item.id === null
                                    const isSelected = selectedFiles.has(item.name)

                                    return (
                                        <div
                                            key={item.name}
                                            className={cn(
                                                'flex items-center gap-4 p-4 transition-colors',
                                                isFolder ? 'cursor-pointer hover:bg-[var(--color-bg-tertiary)]' : '',
                                                isSelected && 'bg-[var(--color-primary-500)]/10'
                                            )}
                                            onClick={() => isFolder && handleFolderClick(item.name)}
                                        >
                                            {!isFolder && (
                                                <input
                                                    type="checkbox"
                                                    checked={isSelected}
                                                    onChange={() => toggleFileSelection(item.name)}
                                                    onClick={(e) => e.stopPropagation()}
                                                    className="h-4 w-4 rounded border-[var(--color-border)] bg-[var(--color-bg-tertiary)]"
                                                />
                                            )}
                                            <div className={cn(
                                                'flex h-10 w-10 items-center justify-center rounded-lg',
                                                isFolder ? 'bg-[var(--color-warning-500)]/15' : 'bg-[var(--color-info-500)]/15'
                                            )}>
                                                {isFolder ? (
                                                    <Folder className="h-5 w-5 text-[var(--color-warning-500)]" />
                                                ) : (
                                                    <File className="h-5 w-5 text-[var(--color-info-500)]" />
                                                )}
                                            </div>
                                            <div className="flex-1">
                                                <p className="font-medium text-[var(--color-text-primary)]">{item.name}</p>
                                                {item.metadata && (
                                                    <p className="text-xs text-[var(--color-text-muted)]">
                                                        {formatNumber(item.metadata.size)} bytes • {item.metadata.mimetype}
                                                    </p>
                                                )}
                                            </div>
                                            {isFolder && (
                                                <ChevronRight className="h-5 w-5 text-[var(--color-text-muted)]" />
                                            )}
                                        </div>
                                    )
                                })}
                            </div>
                        )}
                    </div>
                </div>
            )}
        </div>
    )
}

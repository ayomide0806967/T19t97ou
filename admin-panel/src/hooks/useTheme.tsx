import { createContext, useContext } from 'react'

export type Theme = 'black' | 'dim' | 'offwhite' | 'white'

interface ThemeContextType {
    theme: Theme
    setTheme: (theme: Theme) => void
    themes: { value: Theme; label: string; preview: string }[]
}

export const ThemeContext = createContext<ThemeContextType | null>(null)

export const themes: { value: Theme; label: string; preview: string }[] = [
    { value: 'black', label: 'Black', preview: '#0a0a0a' },
    { value: 'dim', label: 'Dim', preview: '#15202b' },
    { value: 'offwhite', label: 'Off-White', preview: '#f5f3ef' },
    { value: 'white', label: 'White', preview: '#ffffff' },
]

export function useTheme() {
    const context = useContext(ThemeContext)
    if (!context) {
        throw new Error('useTheme must be used within ThemeProvider')
    }
    return context
}

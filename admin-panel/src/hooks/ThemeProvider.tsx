import { useEffect, useState, type ReactNode } from 'react'
import { ThemeContext, themes, type Theme } from '@/hooks/useTheme'

const THEME_KEY = 'admin-theme'

export function ThemeProvider({ children }: { children: ReactNode }) {
    const [theme, setThemeState] = useState<Theme>(() => {
        if (typeof window !== 'undefined') {
            const saved = localStorage.getItem(THEME_KEY) as Theme
            if (saved && themes.some(t => t.value === saved)) {
                return saved
            }
        }
        return 'black'
    })

    useEffect(() => {
        document.documentElement.setAttribute('data-theme', theme)
        localStorage.setItem(THEME_KEY, theme)
    }, [theme])

    const setTheme = (newTheme: Theme) => {
        setThemeState(newTheme)
    }

    return (
        <ThemeContext.Provider value={{ theme, setTheme, themes }}>
            {children}
        </ThemeContext.Provider>
    )
}


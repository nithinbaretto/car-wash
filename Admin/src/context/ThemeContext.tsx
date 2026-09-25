import React, {createContext, useContext, useEffect, useMemo, useState} from 'react';
import {ThemeProvider, CssBaseline} from '@mui/material';
import {createAppTheme} from '../theme';

interface ThemeContextType {
  mode: 'light' | 'dark';
  toggleTheme: () => void;
  setMode: (mode: 'light' | 'dark') => void;
}

const ThemeContext = createContext<ThemeContextType>({
  mode: 'dark',
  toggleTheme: () => {},
  setMode: () => {},
});

export const useAppTheme = () => useContext(ThemeContext);

export const AppThemeProvider: React.FC<{children: React.ReactNode}> = ({children}) => {
  const [mode, setModeState] = useState<'light' | 'dark'>(() => {
    const saved = localStorage.getItem('cw_admin_theme');
    if (saved === 'light' || saved === 'dark') return saved;
    return 'dark'; // Default to sleek dark mode
  });

  const toggleTheme = () => {
    setModeState((prev) => {
      const next = prev === 'dark' ? 'light' : 'dark';
      localStorage.setItem('cw_admin_theme', next);
      return next;
    });
  };

  const setMode = (newMode: 'light' | 'dark') => {
    localStorage.setItem('cw_admin_theme', newMode);
    setModeState(newMode);
  };

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', mode);
  }, [mode]);

  const theme = useMemo(() => createAppTheme(mode), [mode]);

  return (
    <ThemeContext.Provider value={{mode, toggleTheme, setMode}}>
      <ThemeProvider theme={theme}>
        <CssBaseline />
        {children}
      </ThemeProvider>
    </ThemeContext.Provider>
  );
};

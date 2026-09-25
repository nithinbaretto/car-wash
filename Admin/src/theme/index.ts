import {createTheme, responsiveFontSizes, Theme} from '@mui/material/styles';
import {lightPalette, darkPalette} from './palette';

export function createAppTheme(mode: 'light' | 'dark'): Theme {
  const isDark = mode === 'dark';
  const palette = isDark ? darkPalette : lightPalette;

  let theme = createTheme({
    palette,
    typography: {
      fontFamily: "'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
      h1: {fontWeight: 800, letterSpacing: '-0.03em'},
      h2: {fontWeight: 700, letterSpacing: '-0.025em'},
      h3: {fontWeight: 700, letterSpacing: '-0.02em'},
      h4: {fontWeight: 700, letterSpacing: '-0.015em'},
      h5: {fontWeight: 600, letterSpacing: '-0.01em'},
      h6: {fontWeight: 600, letterSpacing: '-0.005em'},
      subtitle1: {fontWeight: 500},
      subtitle2: {fontWeight: 600, fontSize: '0.875rem'},
      body1: {fontSize: '0.925rem', lineHeight: 1.6},
      body2: {fontSize: '0.85rem', lineHeight: 1.5},
      button: {textTransform: 'none', fontWeight: 600, letterSpacing: '0.01em'},
      caption: {fontSize: '0.75rem', fontWeight: 500},
    },
    shape: {
      borderRadius: 12,
    },
    components: {
      MuiCssBaseline: {
        styleOverrides: {
          body: {
            backgroundColor: isDark ? '#0B0F19' : '#F8FAFC',
            color: isDark ? '#F8FAFC' : '#0F172A',
            transition: 'background-color 0.25s ease, color 0.25s ease',
          },
        },
      },
      MuiButton: {
        styleOverrides: {
          root: {
            borderRadius: 10,
            padding: '8px 18px',
            fontSize: '0.875rem',
            transition: 'all 0.2s cubic-bezier(0.4, 0, 0.2, 1)',
            boxShadow: 'none',
            '&:hover': {
              boxShadow: isDark
                ? '0 4px 14px 0 rgba(99, 102, 241, 0.35)'
                : '0 4px 14px 0 rgba(79, 70, 229, 0.25)',
              transform: 'translateY(-1px)',
            },
            '&:active': {
              transform: 'translateY(0)',
            },
          },
          containedPrimary: {
            background: isDark
              ? 'linear-gradient(135deg, #6366F1 0%, #4F46E5 100%)'
              : 'linear-gradient(135deg, #4F46E5 0%, #4338CA 100%)',
          },
        },
      },
      MuiCard: {
        styleOverrides: {
          root: {
            borderRadius: 16,
            backgroundColor: isDark ? '#111827' : '#FFFFFF',
            backgroundImage: 'none',
            border: `1px solid ${isDark ? 'rgba(255, 255, 255, 0.08)' : 'rgba(0, 0, 0, 0.06)'}`,
            boxShadow: isDark
              ? '0 4px 20px -2px rgba(0, 0, 0, 0.5), 0 0 1px 1px rgba(255, 255, 255, 0.05)'
              : '0 4px 20px -2px rgba(15, 23, 42, 0.05), 0 1px 3px 0 rgba(15, 23, 42, 0.03)',
            transition: 'border-color 0.2s ease, box-shadow 0.2s ease',
          },
        },
      },
      MuiPaper: {
        styleOverrides: {
          root: {
            backgroundImage: 'none',
          },
        },
      },
      MuiTableHead: {
        styleOverrides: {
          root: {
            backgroundColor: isDark ? 'rgba(30, 41, 59, 0.5)' : '#F1F5F9',
            '& .MuiTableCell-head': {
              fontWeight: 700,
              fontSize: '0.775rem',
              textTransform: 'uppercase',
              letterSpacing: '0.06em',
              color: isDark ? '#94A3B8' : '#64748B',
              borderBottom: `1px solid ${isDark ? 'rgba(255, 255, 255, 0.08)' : 'rgba(0, 0, 0, 0.06)'}`,
            },
          },
        },
      },
      MuiTableCell: {
        styleOverrides: {
          root: {
            padding: '14px 16px',
            fontSize: '0.875rem',
            borderBottom: `1px solid ${isDark ? 'rgba(255, 255, 255, 0.06)' : 'rgba(0, 0, 0, 0.04)'}`,
          },
        },
      },
      MuiTableRow: {
        styleOverrides: {
          root: {
            transition: 'background-color 0.15s ease',
            '&:hover': {
              backgroundColor: isDark ? 'rgba(255, 255, 255, 0.025)' : 'rgba(0, 0, 0, 0.015)',
            },
          },
        },
      },
      MuiChip: {
        styleOverrides: {
          root: {
            borderRadius: 8,
            fontWeight: 600,
            fontSize: '0.75rem',
            letterSpacing: '0.02em',
          },
        },
      },
      MuiOutlinedInput: {
        styleOverrides: {
          root: {
            borderRadius: 10,
            backgroundColor: isDark ? 'rgba(255, 255, 255, 0.03)' : 'rgba(0, 0, 0, 0.01)',
            '& fieldset': {
              borderColor: isDark ? 'rgba(255, 255, 255, 0.12)' : 'rgba(0, 0, 0, 0.12)',
            },
            '&:hover fieldset': {
              borderColor: isDark ? 'rgba(255, 255, 255, 0.25)' : 'rgba(0, 0, 0, 0.25)',
            },
            '&.Mui-focused fieldset': {
              borderColor: isDark ? '#6366F1' : '#4F46E5',
              borderWidth: '1.5px',
            },
          },
        },
      },
      MuiDialog: {
        styleOverrides: {
          paper: {
            borderRadius: 20,
            backgroundColor: isDark ? '#111827' : '#FFFFFF',
            border: `1px solid ${isDark ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.08)'}`,
            boxShadow: isDark
              ? '0 25px 50px -12px rgba(0, 0, 0, 0.7)'
              : '0 25px 50px -12px rgba(15, 23, 42, 0.25)',
          },
        },
      },
    },
  });

  return responsiveFontSizes(theme);
}

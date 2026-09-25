import {PaletteOptions} from '@mui/material/styles';

export const lightPalette: PaletteOptions = {
  mode: 'light',
  primary: {
    main: '#4F46E5', // Indigo 600
    light: '#6366F1',
    dark: '#3730A3',
    contrastText: '#FFFFFF',
  },
  secondary: {
    main: '#0891B2', // Cyan 600
    light: '#06B6D4',
    dark: '#0E7490',
    contrastText: '#FFFFFF',
  },
  success: {
    main: '#10B981', // Emerald 500
    light: '#34D399',
    dark: '#059669',
    contrastText: '#FFFFFF',
  },
  warning: {
    main: '#F59E0B', // Amber 500
    light: '#FBBF24',
    dark: '#D97706',
    contrastText: '#FFFFFF',
  },
  error: {
    main: '#EF4444', // Rose/Red 500
    light: '#F87171',
    dark: '#DC2626',
    contrastText: '#FFFFFF',
  },
  info: {
    main: '#0284C7', // Sky 600
    light: '#38BDF8',
    dark: '#0369A1',
    contrastText: '#FFFFFF',
  },
  background: {
    default: '#F8FAFC', // Slate 50
    paper: '#FFFFFF',
  },
  text: {
    primary: '#0F172A', // Slate 900
    secondary: '#64748B', // Slate 500
    disabled: '#94A3B8',
  },
  divider: 'rgba(0, 0, 0, 0.07)',
};

export const darkPalette: PaletteOptions = {
  mode: 'dark',
  primary: {
    main: '#6366F1', // Indigo 500
    light: '#818CF8',
    dark: '#4F46E5',
    contrastText: '#FFFFFF',
  },
  secondary: {
    main: '#06B6D4', // Cyan 500
    light: '#22D3EE',
    dark: '#0891B2',
    contrastText: '#FFFFFF',
  },
  success: {
    main: '#10B981', // Emerald 500
    light: '#34D399',
    dark: '#059669',
    contrastText: '#FFFFFF',
  },
  warning: {
    main: '#F59E0B', // Amber 500
    light: '#FBBF24',
    dark: '#D97706',
    contrastText: '#000000',
  },
  error: {
    main: '#F43F5E', // Rose 500
    light: '#FB7185',
    dark: '#E11D48',
    contrastText: '#FFFFFF',
  },
  info: {
    main: '#38BDF8', // Sky 400
    light: '#7DD3FC',
    dark: '#0284C7',
    contrastText: '#000000',
  },
  background: {
    default: '#0B0F19', // Midnight Deep Slate
    paper: '#111827', // Slate 900 Card
  },
  text: {
    primary: '#F8FAFC', // Slate 50
    secondary: '#94A3B8', // Slate 400
    disabled: '#475569',
  },
  divider: 'rgba(255, 255, 255, 0.08)',
};

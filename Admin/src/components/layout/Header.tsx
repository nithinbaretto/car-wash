import React, {useState} from 'react';
import {
  AppBar,
  Toolbar,
  IconButton,
  Typography,
  Box,
  InputBase,
  Menu,
  MenuItem,
  Tooltip,
  Badge,
} from '@mui/material';
import {useTheme} from '@mui/material/styles';
import {
  Menu as MenuIcon,
  Sun,
  Moon,
  Search,
  Bell,
  Radio,
  ExternalLink,
  LifeBuoy,
} from 'lucide-react';
import {useAppTheme} from '../../context/ThemeContext';
import {useAuth} from '../../context/AuthContext';
import {useNavigate} from 'react-router-dom';

interface HeaderProps {
  onMenuClick: () => void;
  drawerWidth?: number;
}

export const Header: React.FC<HeaderProps> = ({onMenuClick, drawerWidth = 260}) => {
  const theme = useTheme();
  const isDark = theme.palette.mode === 'dark';
  const {mode, toggleTheme} = useAppTheme();
  const {user, isDemo, logout} = useAuth();
  const navigate = useNavigate();

  const [searchVal, setSearchVal] = useState('');
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!searchVal.trim()) return;
    const term = searchVal.trim();
    if (term.toLowerCase().startsWith('bk-') || term.length > 8) {
      navigate(`/bookings?id=${encodeURIComponent(term)}`);
    } else {
      navigate(`/shops?id=${encodeURIComponent(term)}`);
    }
  };

  return (
    <AppBar
      position="sticky"
      elevation={0}
      sx={{
        width: {md: `calc(100% - ${drawerWidth}px)`},
        ml: {md: `${drawerWidth}px`},
        backgroundColor: isDark ? 'rgba(11, 15, 25, 0.85)' : 'rgba(255, 255, 255, 0.85)',
        backdropFilter: 'blur(12px)',
        borderBottom: `1px solid ${isDark ? 'rgba(255, 255, 255, 0.08)' : 'rgba(0, 0, 0, 0.06)'}`,
        color: isDark ? '#FFFFFF' : '#0F172A',
      }}
    >
      <Toolbar sx={{px: {xs: 2, sm: 3}, height: 70}}>
        {/* Mobile menu trigger */}
        <IconButton
          color="inherit"
          edge="start"
          onClick={onMenuClick}
          sx={{mr: 2, display: {md: 'none'}}}
        >
          <MenuIcon size={20} />
        </IconButton>

        {/* Global Search Bar */}
        <Box
          component="form"
          onSubmit={handleSearchSubmit}
          sx={{
            display: 'flex',
            alignItems: 'center',
            backgroundColor: isDark ? 'rgba(255, 255, 255, 0.04)' : '#F1F5F9',
            borderRadius: 2.5,
            px: 1.75,
            py: 0.6,
            width: {xs: '100%', sm: 320, md: 380},
            border: `1px solid ${isDark ? 'rgba(255, 255, 255, 0.08)' : 'rgba(0, 0, 0, 0.04)'}`,
            transition: 'border-color 0.2s',
            '&:focus-within': {
              borderColor: isDark ? '#6366F1' : '#4F46E5',
              boxShadow: '0 0 0 3px rgba(99, 102, 241, 0.15)',
            },
          }}
        >
          <Search size={17} color={isDark ? '#94A3B8' : '#64748B'} />
          <InputBase
            placeholder="Quick search shops, booking IDs, users..."
            value={searchVal}
            onChange={(e) => setSearchVal(e.target.value)}
            sx={{
              ml: 1.25,
              flex: 1,
              fontSize: '0.85rem',
              color: isDark ? '#FFFFFF' : '#0F172A',
              '& input::placeholder': {
                color: isDark ? '#64748B' : '#94A3B8',
                opacity: 1,
              },
            }}
          />
        </Box>

        <Box sx={{flexGrow: 1}} />

        {/* Status indicator */}
        <Box
          sx={{
            display: {xs: 'none', lg: 'flex'},
            alignItems: 'center',
            gap: 1,
            mr: 2,
            px: 1.5,
            py: 0.5,
            borderRadius: 9999,
            backgroundColor: isDark ? 'rgba(16, 185, 129, 0.1)' : '#ECFDF5',
            border: `1px solid ${isDark ? 'rgba(16, 185, 129, 0.2)' : '#A7F3D0'}`,
          }}
        >
          <Box
            sx={{
              width: 7,
              height: 7,
              borderRadius: '50%',
              backgroundColor: '#10B981',
              boxShadow: '0 0 6px #10B981',
            }}
          />
          <Typography
            variant="caption"
            sx={{fontWeight: 700, color: isDark ? '#34D399' : '#047857', fontSize: '0.725rem'}}
          >
            {isDemo ? 'Demo Mode (Mock)' : 'Live Engine (asia-south1)'}
          </Typography>
        </Box>

        {/* Theme Mode Toggle */}
        <Tooltip title={isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode'} arrow>
          <IconButton
            onClick={toggleTheme}
            color="inherit"
            sx={{
              p: 1.1,
              borderRadius: 2,
              backgroundColor: isDark ? 'rgba(255, 255, 255, 0.04)' : '#F1F5F9',
              border: `1px solid ${isDark ? 'rgba(255, 255, 255, 0.08)' : 'rgba(0, 0, 0, 0.04)'}`,
              '&:hover': {
                backgroundColor: isDark ? 'rgba(255, 255, 255, 0.08)' : '#E2E8F0',
              },
            }}
          >
            {isDark ? <Sun size={18} color="#FBBF24" /> : <Moon size={18} color="#4F46E5" />}
          </IconButton>
        </Tooltip>

        {/* Notifications */}
        <Tooltip title="Notifications" arrow>
          <IconButton
            color="inherit"
            sx={{
              ml: 1,
              p: 1.1,
              borderRadius: 2,
              backgroundColor: isDark ? 'rgba(255, 255, 255, 0.04)' : '#F1F5F9',
              border: `1px solid ${isDark ? 'rgba(255, 255, 255, 0.08)' : 'rgba(0, 0, 0, 0.04)'}`,
            }}
          >
            <Badge variant="dot" color="primary">
              <Bell size={18} />
            </Badge>
          </IconButton>
        </Tooltip>
      </Toolbar>
    </AppBar>
  );
};

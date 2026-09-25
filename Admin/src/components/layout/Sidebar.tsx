import React from 'react';
import {
  Box,
  Drawer,
  List,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Typography,
  Chip,
  Divider,
  Avatar,
  IconButton,
  Tooltip,
} from '@mui/material';
import {useLocation, useNavigate, Link} from 'react-router-dom';
import {useTheme} from '@mui/material/styles';
import {
  LayoutDashboard,
  CheckSquare,
  Store,
  CalendarCheck,
  Users,
  ShieldCheck,
  LogOut,
  Sparkles,
  ExternalLink,
} from 'lucide-react';
import {useAuth} from '../../context/AuthContext';
import {useQuery} from '@tanstack/react-query';
import {api} from '../../api/client';
import {DashboardStats} from '../../types';

interface SidebarProps {
  mobileOpen: boolean;
  onMobileClose: () => void;
  drawerWidth?: number;
}

export const Sidebar: React.FC<SidebarProps> = ({
  mobileOpen,
  onMobileClose,
  drawerWidth = 260,
}) => {
  const location = useLocation();
  const navigate = useNavigate();
  const theme = useTheme();
  const isDark = theme.palette.mode === 'dark';
  const {user, adminProfile, logout} = useAuth();

  // Fetch pending review count for badge
  const {data: stats} = useQuery({
    queryKey: ['dashboard-quick-stats'],
    queryFn: () => api<DashboardStats>('/v1/admin/dashboard'),
    refetchInterval: 60000,
  });

  const pendingApprovals = stats?.shops?.pending_review ?? 0;

  const navigationItems = [
    {
      path: '/',
      label: 'Overview',
      icon: <LayoutDashboard size={20} />,
      badge: null,
    },
    {
      path: '/approvals',
      label: 'Approvals Queue',
      icon: <CheckSquare size={20} />,
      badge: pendingApprovals > 0 ? pendingApprovals : null,
      badgeColor: 'warning' as const,
    },
    {
      path: '/shops',
      label: 'Shops Directory',
      icon: <Store size={20} />,
      badge: null,
    },
    {
      path: '/bookings',
      label: 'Bookings',
      icon: <CalendarCheck size={20} />,
      badge: null,
    },
    {
      path: '/users',
      label: 'User Accounts',
      icon: <Users size={20} />,
      badge: null,
    },
    {
      path: '/audit',
      label: 'Security & Audit',
      icon: <ShieldCheck size={20} />,
      badge: null,
    },
  ];

  const drawerContent = (
    <Box
      sx={{
        display: 'flex',
        flexDirection: 'column',
        height: '100%',
        backgroundColor: isDark ? '#0D131F' : '#FFFFFF',
        borderRight: `1px solid ${isDark ? 'rgba(255, 255, 255, 0.08)' : 'rgba(0, 0, 0, 0.06)'}`,
      }}
    >
      {/* Brand Header */}
      <Box sx={{p: 2.75, display: 'flex', alignItems: 'center', gap: 1.75}}>
        <Box
          sx={{
            width: 40,
            height: 40,
            borderRadius: 2.5,
            background: 'linear-gradient(135deg, #6366F1 0%, #06B6D4 100%)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: '#FFFFFF',
            boxShadow: '0 4px 12px rgba(99, 102, 241, 0.35)',
          }}
        >
          <Sparkles size={22} />
        </Box>
        <Box>
          <Typography variant="h6" sx={{fontWeight: 800, letterSpacing: '-0.02em', lineHeight: 1.2}}>
            CleanWheel
          </Typography>
          <Box sx={{display: 'flex', alignItems: 'center', gap: 0.75, mt: 0.25}}>
            <Typography variant="caption" sx={{fontWeight: 700, color: '#6366F1', letterSpacing: '0.04em'}}>
              SUPER ADMIN
            </Typography>
          </Box>
        </Box>
      </Box>

      <Divider sx={{opacity: isDark ? 0.08 : 0.06}} />

      {/* Nav List */}
      <Box sx={{flex: 1, px: 1.75, py: 2}}>
        <Typography
          variant="caption"
          sx={{
            px: 1.5,
            mb: 1,
            display: 'block',
            fontWeight: 700,
            letterSpacing: '0.06em',
            color: isDark ? 'text.secondary' : '#94A3B8',
          }}
        >
          MANAGEMENT
        </Typography>

        <List sx={{p: 0, display: 'flex', flexDirection: 'column', gap: 0.75}}>
          {navigationItems.map((item) => {
            const isSelected =
              item.path === '/'
                ? location.pathname === '/'
                : location.pathname.startsWith(item.path);

            return (
              <ListItemButton
                key={item.path}
                component={Link}
                to={item.path}
                onClick={onMobileClose}
                selected={isSelected}
                sx={{
                  borderRadius: 2.25,
                  py: 1.1,
                  px: 1.75,
                  color: isSelected
                    ? isDark
                      ? '#FFFFFF'
                      : '#4F46E5'
                    : isDark
                    ? '#94A3B8'
                    : '#475569',
                  backgroundColor: isSelected
                    ? isDark
                      ? 'rgba(99, 102, 241, 0.14) !important'
                      : 'rgba(79, 70, 229, 0.08) !important'
                    : 'transparent',
                  border: isSelected
                    ? `1px solid ${isDark ? 'rgba(99, 102, 241, 0.3)' : 'rgba(79, 70, 229, 0.2)'}`
                    : '1px solid transparent',
                  '&:hover': {
                    backgroundColor: isDark ? 'rgba(255, 255, 255, 0.04)' : 'rgba(0, 0, 0, 0.03)',
                    color: isDark ? '#FFFFFF' : '#0F172A',
                  },
                  transition: 'all 0.15s ease',
                }}
              >
                <ListItemIcon
                  sx={{
                    minWidth: 36,
                    color: isSelected
                      ? isDark
                        ? '#818CF8'
                        : '#4F46E5'
                      : isDark
                      ? '#64748B'
                      : '#94A3B8',
                  }}
                >
                  {item.icon}
                </ListItemIcon>
                <ListItemText
                  primary={item.label}
                  primaryTypographyProps={{
                    fontSize: '0.875rem',
                    fontWeight: isSelected ? 700 : 500,
                  }}
                />
                {item.badge !== null && (
                  <Chip
                    label={item.badge}
                    size="small"
                    color={item.badgeColor || 'primary'}
                    sx={{
                      height: 20,
                      fontWeight: 700,
                      fontSize: '0.725rem',
                      px: 0.25,
                    }}
                  />
                )}
              </ListItemButton>
            );
          })}
        </List>
      </Box>

      {/* Footer Profile & Logout */}
      <Box sx={{p: 2, borderTop: `1px solid ${isDark ? 'rgba(255, 255, 255, 0.08)' : 'rgba(0, 0, 0, 0.06)'}`}}>
        <Box
          sx={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            p: 1.25,
            borderRadius: 2,
            backgroundColor: isDark ? 'rgba(255, 255, 255, 0.02)' : 'rgba(0, 0, 0, 0.02)',
          }}
        >
          <Box sx={{display: 'flex', alignItems: 'center', gap: 1.25, minWidth: 0}}>
            <Avatar
              sx={{
                width: 34,
                height: 34,
                bgcolor: '#4F46E5',
                fontSize: '0.85rem',
                fontWeight: 700,
              }}
            >
              {(adminProfile?.displayName || user?.email || 'A')[0].toUpperCase()}
            </Avatar>
            <Box sx={{minWidth: 0}}>
              <Typography
                variant="body2"
                noWrap
                sx={{fontWeight: 700, fontSize: '0.825rem', lineHeight: 1.2}}
              >
                {adminProfile?.displayName || user?.displayName || 'Admin'}
              </Typography>
              <Typography
                variant="caption"
                noWrap
                color="text.secondary"
                sx={{fontSize: '0.7rem', display: 'block'}}
              >
                {user?.email || 'super_admin'}
              </Typography>
            </Box>
          </Box>

          <Tooltip title="Sign out" arrow>
            <IconButton
              size="small"
              onClick={async () => {
                await logout();
                navigate('/login');
              }}
              sx={{
                color: isDark ? '#94A3B8' : '#64748B',
                '&:hover': {color: '#EF4444', backgroundColor: 'rgba(239, 68, 68, 0.1)'},
              }}
            >
              <LogOut size={18} />
            </IconButton>
          </Tooltip>
        </Box>
      </Box>
    </Box>
  );

  return (
    <Box component="nav" sx={{width: {md: drawerWidth}, flexShrink: {md: 0}}}>
      {/* Mobile Drawer */}
      <Drawer
        variant="temporary"
        open={mobileOpen}
        onClose={onMobileClose}
        ModalProps={{keepMounted: true}}
        sx={{
          display: {xs: 'block', md: 'none'},
          '& .MuiDrawer-paper': {
            boxSizing: 'border-box',
            width: drawerWidth,
            border: 'none',
          },
        }}
      >
        {drawerContent}
      </Drawer>

      {/* Desktop Persistent Drawer */}
      <Drawer
        variant="permanent"
        sx={{
          display: {xs: 'none', md: 'block'},
          '& .MuiDrawer-paper': {
            boxSizing: 'border-box',
            width: drawerWidth,
            border: 'none',
          },
        }}
        open
      >
        {drawerContent}
      </Drawer>
    </Box>
  );
};

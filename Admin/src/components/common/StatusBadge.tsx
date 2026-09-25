import React from 'react';
import {Box, Typography} from '@mui/material';
import {useTheme} from '@mui/material/styles';

interface StatusBadgeProps {
  status?: string;
  size?: 'small' | 'medium';
  pulse?: boolean;
}

interface StatusConfig {
  label: string;
  bgLight: string;
  bgDark: string;
  textLight: string;
  textDark: string;
  borderLight: string;
  borderDark: string;
  dotColor: string;
  shouldPulse?: boolean;
}

const statusMap: Record<string, StatusConfig> = {
  // Shop & Account Statuses
  active: {
    label: 'Active',
    bgLight: '#ECFDF5',
    bgDark: 'rgba(16, 185, 129, 0.12)',
    textLight: '#047857',
    textDark: '#34D399',
    borderLight: '#A7F3D0',
    borderDark: 'rgba(52, 211, 153, 0.25)',
    dotColor: '#10B981',
  },
  pending_review: {
    label: 'Pending Review',
    bgLight: '#FFFBEB',
    bgDark: 'rgba(245, 158, 11, 0.12)',
    textLight: '#B45309',
    textDark: '#FBBF24',
    borderLight: '#FDE68A',
    borderDark: 'rgba(251, 191, 36, 0.25)',
    dotColor: '#F59E0B',
    shouldPulse: true,
  },
  suspended: {
    label: 'Suspended',
    bgLight: '#FEF2F2',
    bgDark: 'rgba(239, 68, 68, 0.12)',
    textLight: '#B91C1C',
    textDark: '#F87171',
    borderLight: '#FECACA',
    borderDark: 'rgba(248, 113, 113, 0.25)',
    dotColor: '#EF4444',
  },
  rejected: {
    label: 'Rejected',
    bgLight: '#FEF2F2',
    bgDark: 'rgba(244, 63, 94, 0.12)',
    textLight: '#BE123C',
    textDark: '#FB7185',
    borderLight: '#FECDD3',
    borderDark: 'rgba(251, 113, 133, 0.25)',
    dotColor: '#F43F5E',
  },

  // Booking Statuses
  pending: {
    label: 'Pending',
    bgLight: '#FFFBEB',
    bgDark: 'rgba(245, 158, 11, 0.12)',
    textLight: '#B45309',
    textDark: '#FBBF24',
    borderLight: '#FDE68A',
    borderDark: 'rgba(251, 191, 36, 0.25)',
    dotColor: '#F59E0B',
    shouldPulse: true,
  },
  accepted: {
    label: 'Accepted',
    bgLight: '#EFF6FF',
    bgDark: 'rgba(59, 130, 246, 0.12)',
    textLight: '#1D4ED8',
    textDark: '#60A5FA',
    borderLight: '#BFDBFE',
    borderDark: 'rgba(96, 165, 250, 0.25)',
    dotColor: '#3B82F6',
  },
  in_progress: {
    label: 'In Progress',
    bgLight: '#EEF2FF',
    bgDark: 'rgba(99, 102, 241, 0.15)',
    textLight: '#4338CA',
    textDark: '#818CF8',
    borderLight: '#C7D2FE',
    borderDark: 'rgba(129, 140, 248, 0.3)',
    dotColor: '#6366F1',
    shouldPulse: true,
  },
  completed: {
    label: 'Completed',
    bgLight: '#ECFDF5',
    bgDark: 'rgba(16, 185, 129, 0.12)',
    textLight: '#047857',
    textDark: '#34D399',
    borderLight: '#A7F3D0',
    borderDark: 'rgba(52, 211, 153, 0.25)',
    dotColor: '#10B981',
  },
  cancelled: {
    label: 'Cancelled',
    bgLight: '#F1F5F9',
    bgDark: 'rgba(148, 163, 184, 0.12)',
    textLight: '#475569',
    textDark: '#94A3B8',
    borderLight: '#CBD5E1',
    borderDark: 'rgba(148, 163, 184, 0.25)',
    dotColor: '#64748B',
  },

  // User Roles
  owner: {
    label: 'Shop Owner',
    bgLight: '#F5F3FF',
    bgDark: 'rgba(139, 92, 246, 0.12)',
    textLight: '#6D28D9',
    textDark: '#A78BFA',
    borderLight: '#DDD6FE',
    borderDark: 'rgba(167, 139, 250, 0.25)',
    dotColor: '#8B5CF6',
  },
  customer: {
    label: 'Customer',
    bgLight: '#F0F9FF',
    bgDark: 'rgba(14, 165, 233, 0.12)',
    textLight: '#0369A1',
    textDark: '#38BDF8',
    borderLight: '#BAE6FD',
    borderDark: 'rgba(56, 189, 248, 0.25)',
    dotColor: '#0EA5E9',
  },
  super_admin: {
    label: 'Super Admin',
    bgLight: '#FEF3C7',
    bgDark: 'rgba(245, 158, 11, 0.15)',
    textLight: '#B45309',
    textDark: '#FBBF24',
    borderLight: '#FDE68A',
    borderDark: 'rgba(251, 191, 36, 0.3)',
    dotColor: '#F59E0B',
  },
};

export const StatusBadge: React.FC<StatusBadgeProps> = ({
  status = 'unknown',
  size = 'small',
  pulse,
}) => {
  const theme = useTheme();
  const isDark = theme.palette.mode === 'dark';
  const cleanKey = status.toLowerCase();

  const config = statusMap[cleanKey] || {
    label: status.replaceAll('_', ' '),
    bgLight: '#F1F5F9',
    bgDark: 'rgba(148, 163, 184, 0.1)',
    textLight: '#475569',
    textDark: '#94A3B8',
    borderLight: '#E2E8F0',
    borderDark: 'rgba(148, 163, 184, 0.2)',
    dotColor: '#94A3B8',
  };

  const isSmall = size === 'small';
  const shouldPulse = pulse ?? config.shouldPulse;

  return (
    <Box
      sx={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: isSmall ? 0.75 : 1,
        px: isSmall ? 1.2 : 1.5,
        py: isSmall ? 0.35 : 0.6,
        borderRadius: 9999,
        backgroundColor: isDark ? config.bgDark : config.bgLight,
        border: `1px solid ${isDark ? config.borderDark : config.borderLight}`,
        transition: 'all 0.2s ease',
        userSelect: 'none',
      }}
    >
      <Box
        sx={{
          width: isSmall ? 6 : 8,
          height: isSmall ? 6 : 8,
          borderRadius: '50%',
          backgroundColor: config.dotColor,
          boxShadow: `0 0 8px ${config.dotColor}`,
          position: 'relative',
          ...(shouldPulse && {
            '&::after': {
              content: '""',
              position: 'absolute',
              top: 0,
              left: 0,
              width: '100%',
              height: '100%',
              borderRadius: '50%',
              animation: 'ripple 1.5s infinite ease-in-out',
              border: `1.5px solid ${config.dotColor}`,
            },
            '@keyframes ripple': {
              '0%': {transform: 'scale(1)', opacity: 0.9},
              '100%': {transform: 'scale(2.4)', opacity: 0},
            },
          }),
        }}
      />
      <Typography
        sx={{
          fontSize: isSmall ? '0.75rem' : '0.825rem',
          fontWeight: 600,
          color: isDark ? config.textDark : config.textLight,
          lineHeight: 1,
          textTransform: 'capitalize',
        }}
      >
        {config.label}
      </Typography>
    </Box>
  );
};

import React from 'react';
import {Card, CardContent, Box, Typography} from '@mui/material';
import {useTheme} from '@mui/material/styles';

interface StatCardProps {
  title: string;
  value: string | number;
  subtitle?: string;
  icon: React.ReactNode;
  trend?: {
    value: string | number;
    positive?: boolean;
    label?: string;
  };
  accentColor?: string;
  onClick?: () => void;
}

export const StatCard: React.FC<StatCardProps> = ({
  title,
  value,
  subtitle,
  icon,
  trend,
  accentColor = '#6366F1',
  onClick,
}) => {
  const theme = useTheme();
  const isDark = theme.palette.mode === 'dark';

  return (
    <Card
      onClick={onClick}
      sx={{
        position: 'relative',
        overflow: 'hidden',
        cursor: onClick ? 'pointer' : 'default',
        transition: 'all 0.25s cubic-bezier(0.4, 0, 0.2, 1)',
        '&:hover': onClick
          ? {
              transform: 'translateY(-3px)',
              boxShadow: isDark
                ? `0 12px 28px -6px rgba(0, 0, 0, 0.6), 0 0 1px 1px ${accentColor}40`
                : `0 12px 28px -6px rgba(15, 23, 42, 0.12), 0 0 1px 1px ${accentColor}30`,
              borderColor: `${accentColor}60`,
            }
          : {
              transform: 'translateY(-2px)',
            },
      }}
    >
      {/* Decorative top accent glow */}
      <Box
        sx={{
          position: 'absolute',
          top: 0,
          left: 0,
          right: 0,
          height: '3px',
          background: `linear-gradient(90deg, ${accentColor} 0%, ${accentColor}40 100%)`,
        }}
      />

      <CardContent sx={{p: 2.75, '&:last-child': {pb: 2.75}}}>
        <Box sx={{display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start'}}>
          <Box>
            <Typography
              variant="body2"
              sx={{
                fontWeight: 600,
                color: isDark ? 'text.secondary' : '#64748B',
                letterSpacing: '0.02em',
                mb: 0.75,
              }}
            >
              {title}
            </Typography>
            <Typography
              variant="h4"
              sx={{
                fontWeight: 800,
                letterSpacing: '-0.02em',
                color: isDark ? '#FFFFFF' : '#0F172A',
                lineHeight: 1.1,
              }}
            >
              {typeof value === 'number' ? value.toLocaleString() : value}
            </Typography>
          </Box>

          <Box
            sx={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              width: 48,
              height: 48,
              borderRadius: 3,
              backgroundColor: isDark ? `${accentColor}18` : `${accentColor}12`,
              color: accentColor,
              border: `1px solid ${accentColor}30`,
              boxShadow: `0 4px 12px ${accentColor}20`,
            }}
          >
            {icon}
          </Box>
        </Box>

        {(subtitle || trend) && (
          <Box sx={{display: 'flex', alignItems: 'center', gap: 1, mt: 2}}>
            {trend && (
              <Box
                sx={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  px: 0.9,
                  py: 0.25,
                  borderRadius: 1.5,
                  fontSize: '0.725rem',
                  fontWeight: 700,
                  backgroundColor: trend.positive
                    ? isDark
                      ? 'rgba(16, 185, 129, 0.15)'
                      : '#ECFDF5'
                    : isDark
                    ? 'rgba(244, 63, 94, 0.15)'
                    : '#FEF2F2',
                  color: trend.positive
                    ? isDark
                      ? '#34D399'
                      : '#059669'
                    : isDark
                    ? '#FB7185'
                    : '#E11D48',
                }}
              >
                {trend.positive ? '+' : ''}
                {trend.value}
              </Box>
            )}
            <Typography
              variant="caption"
              sx={{
                color: isDark ? 'text.secondary' : '#64748B',
                fontWeight: 500,
              }}
            >
              {trend?.label || subtitle}
            </Typography>
          </Box>
        )}
      </CardContent>
    </Card>
  );
};

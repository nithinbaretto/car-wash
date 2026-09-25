import React from 'react';
import {Box, Typography, Breadcrumbs, Link as MuiLink} from '@mui/material';
import {Link} from 'react-router-dom';
import {ChevronRight} from 'lucide-react';
import {useTheme} from '@mui/material/styles';

interface BreadcrumbItem {
  label: string;
  path?: string;
}

interface PageHeaderProps {
  title: string;
  subtitle?: string;
  breadcrumbs?: BreadcrumbItem[];
  action?: React.ReactNode;
}

export const PageHeader: React.FC<PageHeaderProps> = ({
  title,
  subtitle,
  breadcrumbs,
  action,
}) => {
  const theme = useTheme();
  const isDark = theme.palette.mode === 'dark';

  return (
    <Box sx={{mb: 3.5}}>
      {breadcrumbs && breadcrumbs.length > 0 && (
        <Breadcrumbs
          separator={<ChevronRight size={14} color={isDark ? '#64748B' : '#94A3B8'} />}
          sx={{mb: 1.25}}
        >
          {breadcrumbs.map((crumb, idx) => {
            const isLast = idx === breadcrumbs.length - 1;
            if (isLast || !crumb.path) {
              return (
                <Typography
                  key={crumb.label}
                  variant="caption"
                  sx={{
                    fontWeight: 600,
                    color: isDark ? '#94A3B8' : '#475569',
                    fontSize: '0.8rem',
                  }}
                >
                  {crumb.label}
                </Typography>
              );
            }
            return (
              <MuiLink
                key={crumb.label}
                component={Link}
                to={crumb.path}
                underline="hover"
                sx={{
                  color: isDark ? '#64748B' : '#94A3B8',
                  fontSize: '0.8rem',
                  fontWeight: 500,
                  '&:hover': {color: '#6366F1'},
                }}
              >
                {crumb.label}
              </MuiLink>
            );
          })}
        </Breadcrumbs>
      )}

      <Box
        sx={{
          display: 'flex',
          flexDirection: {xs: 'column', sm: 'row'},
          justifyContent: 'space-between',
          alignItems: {xs: 'flex-start', sm: 'center'},
          gap: 2,
        }}
      >
        <Box>
          <Typography
            variant="h4"
            sx={{
              fontWeight: 800,
              letterSpacing: '-0.025em',
              color: isDark ? '#FFFFFF' : '#0F172A',
            }}
          >
            {title}
          </Typography>
          {subtitle && (
            <Typography
              variant="body2"
              color="text.secondary"
              sx={{mt: 0.5, fontWeight: 500}}
            >
              {subtitle}
            </Typography>
          )}
        </Box>

        {action && <Box sx={{display: 'flex', alignItems: 'center', gap: 1.5}}>{action}</Box>}
      </Box>
    </Box>
  );
};

import React from 'react';
import {Box, Card, CardContent, Typography, Stack} from '@mui/material';
import {useTheme} from '@mui/material/styles';

interface BookingStatusProps {
  stats: {
    pending: number;
    accepted: number;
    in_progress: number;
    completed: number;
    cancelled: number;
  };
}

export const BookingStatusBar: React.FC<BookingStatusProps> = ({stats}) => {
  const theme = useTheme();
  const isDark = theme.palette.mode === 'dark';

  const total =
    (stats.pending || 0) +
    (stats.accepted || 0) +
    (stats.in_progress || 0) +
    (stats.completed || 0) +
    (stats.cancelled || 0);

  const segments = [
    {key: 'completed', label: 'Completed', count: stats.completed || 0, color: '#10B981'},
    {key: 'in_progress', label: 'In Progress', count: stats.in_progress || 0, color: '#6366F1'},
    {key: 'accepted', label: 'Accepted', count: stats.accepted || 0, color: '#06B6D4'},
    {key: 'pending', label: 'Pending', count: stats.pending || 0, color: '#F59E0B'},
    {key: 'cancelled', label: 'Cancelled', count: stats.cancelled || 0, color: '#EF4444'},
  ];

  return (
    <Card sx={{height: '100%'}}>
      <CardContent sx={{p: 2.75}}>
        <Box sx={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2}}>
          <Box>
            <Typography variant="h6" sx={{fontWeight: 700}}>
              Booking Status Distribution
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Total volume across all partner hubs
            </Typography>
          </Box>
          <Typography variant="h5" sx={{fontWeight: 800, color: '#6366F1'}}>
            {total.toLocaleString()}
          </Typography>
        </Box>

        {/* Progress Bar */}
        <Box
          sx={{
            display: 'flex',
            height: 12,
            borderRadius: 9999,
            overflow: 'hidden',
            backgroundColor: isDark ? 'rgba(255, 255, 255, 0.05)' : '#E2E8F0',
            mb: 2.5,
          }}
        >
          {total === 0 ? (
            <Box sx={{width: '100%', backgroundColor: 'transparent'}} />
          ) : (
            segments.map((seg) => {
              const pct = (seg.count / total) * 100;
              if (pct <= 0) return null;
              return (
                <Box
                  key={seg.key}
                  sx={{
                    width: `${pct}%`,
                    backgroundColor: seg.color,
                    transition: 'width 0.6s cubic-bezier(0.4, 0, 0.2, 1)',
                  }}
                  title={`${seg.label}: ${seg.count} (${pct.toFixed(1)}%)`}
                />
              );
            })
          )}
        </Box>

        {/* Legend */}
        <Box sx={{display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(130px, 1fr))', gap: 1.5}}>
          {segments.map((seg) => (
            <Box
              key={seg.key}
              sx={{
                p: 1.25,
                borderRadius: 2,
                backgroundColor: isDark ? 'rgba(255, 255, 255, 0.02)' : 'rgba(0, 0, 0, 0.02)',
                border: `1px solid ${isDark ? 'rgba(255, 255, 255, 0.05)' : 'rgba(0, 0, 0, 0.04)'}`,
              }}
            >
              <Box sx={{display: 'flex', alignItems: 'center', gap: 1, mb: 0.5}}>
                <Box sx={{width: 8, height: 8, borderRadius: '50%', backgroundColor: seg.color}} />
                <Typography variant="caption" color="text.secondary" sx={{fontWeight: 600}}>
                  {seg.label}
                </Typography>
              </Box>
              <Typography variant="body1" sx={{fontWeight: 700, ml: 2}}>
                {seg.count.toLocaleString()}
              </Typography>
            </Box>
          ))}
        </Box>
      </CardContent>
    </Card>
  );
};

export const WeeklyActivityChart: React.FC = () => {
  const theme = useTheme();
  const isDark = theme.palette.mode === 'dark';

  const days = [
    {day: 'Mon', bookings: 42, revenue: 32000},
    {day: 'Tue', bookings: 55, revenue: 41000},
    {day: 'Wed', bookings: 68, revenue: 53000},
    {day: 'Thu', bookings: 61, revenue: 47000},
    {day: 'Fri', bookings: 84, revenue: 68000},
    {day: 'Sat', bookings: 112, revenue: 98000},
    {day: 'Sun', bookings: 128, revenue: 114000},
  ];

  const maxVal = 135;

  return (
    <Card sx={{height: '100%'}}>
      <CardContent sx={{p: 2.75}}>
        <Box sx={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2.5}}>
          <Box>
            <Typography variant="h6" sx={{fontWeight: 700}}>
              Weekly Booking Velocity
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Daily customer appointment volume
            </Typography>
          </Box>
          <Box
            sx={{
              px: 1.5,
              py: 0.5,
              borderRadius: 2,
              backgroundColor: isDark ? 'rgba(99, 102, 241, 0.15)' : '#EEF2FF',
              color: '#6366F1',
              fontWeight: 700,
              fontSize: '0.8rem',
            }}
          >
            Peak: Sunday (128)
          </Box>
        </Box>

        {/* Bar visualization */}
        <Box sx={{display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', height: 160, pt: 2}}>
          {days.map((d) => {
            const heightPct = (d.bookings / maxVal) * 100;
            return (
              <Stack key={d.day} alignItems="center" spacing={1} sx={{flex: 1}}>
                <Typography variant="caption" sx={{fontWeight: 700, color: '#818CF8'}}>
                  {d.bookings}
                </Typography>
                <Box
                  sx={{
                    width: '60%',
                    maxWidth: 32,
                    height: `${heightPct}%`,
                    borderRadius: '6px 6px 0 0',
                    background:
                      d.day === 'Sun' || d.day === 'Sat'
                        ? 'linear-gradient(180deg, #6366F1 0%, #4F46E5 100%)'
                        : isDark
                        ? 'linear-gradient(180deg, rgba(99, 102, 241, 0.6) 0%, rgba(99, 102, 241, 0.2) 100%)'
                        : 'linear-gradient(180deg, #818CF8 0%, #C7D2FE 100%)',
                    transition: 'all 0.3s ease',
                    '&:hover': {
                      transform: 'scaleY(1.04)',
                      filter: 'brightness(1.15)',
                    },
                  }}
                />
                <Typography
                  variant="caption"
                  color="text.secondary"
                  sx={{fontWeight: 600, fontSize: '0.75rem'}}
                >
                  {d.day}
                </Typography>
              </Stack>
            );
          })}
        </Box>
      </CardContent>
    </Card>
  );
};

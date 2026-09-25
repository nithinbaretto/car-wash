import React from 'react';
import {
  Box,
  Grid,
  Card,
  CardContent,
  Typography,
  Button,
  Stack,
  Alert,
  Divider,
} from '@mui/material';
import {useParams, Link} from 'react-router-dom';
import {useQuery} from '@tanstack/react-query';
import {useTheme} from '@mui/material/styles';
import {
  CalendarCheck,
  Store,
  User as UserIcon,
  Phone,
  Mail,
  Clock,
  ArrowLeft,
  CheckCircle,
  Sparkles,
} from 'lucide-react';
import {api, money, toDate} from '../api/client';
import {Booking} from '../types';
import {PageHeader} from '../components/layout/PageHeader';
import {StatusBadge} from '../components/common/StatusBadge';
import {TableSkeleton} from '../components/common/LoadingSkeleton';

export const BookingDetail: React.FC = () => {
  const {id = ''} = useParams();
  const theme = useTheme();
  const isDark = theme.palette.mode === 'dark';

  const {
    data,
    isLoading,
    error,
  } = useQuery({
    queryKey: ['booking', id],
    queryFn: () => api<{booking: Booking}>(`/v1/admin/bookings/${id}`),
  });

  if (isLoading) {
    return (
      <Box>
        <PageHeader title="Loading Booking..." breadcrumbs={[{label: 'Bookings', path: '/bookings'}]} />
        <TableSkeleton rows={3} cols={2} />
      </Box>
    );
  }

  if (error || !data) {
    return (
      <Box>
        <Alert severity="error">
          {error instanceof Error ? error.message : 'Unable to find booking record.'}
        </Alert>
        <Button component={Link} to="/bookings" sx={{mt: 2}} startIcon={<ArrowLeft size={16} />}>
          Back to Bookings
        </Button>
      </Box>
    );
  }

  const {booking} = data;

  return (
    <Box>
      <PageHeader
        title={`Booking #${booking.id}`}
        subtitle={`Scheduled on ${booking.scheduledDate} (${booking.startAt} - ${booking.endAt})`}
        breadcrumbs={[
          {label: 'Overview', path: '/'},
          {label: 'Bookings', path: '/bookings'},
          {label: booking.id},
        ]}
      />

      <Grid container spacing={3}>
        {/* Main Details Card */}
        <Grid size={{xs: 12, md: 8}}>
          <Card sx={{mb: 3}}>
            <CardContent sx={{p: 3.5}}>
              <Box sx={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3}}>
                <Box>
                  <Typography variant="caption" color="text.secondary" sx={{fontWeight: 700}}>
                    STATUS LIFECYCLE
                  </Typography>
                  <Box sx={{mt: 0.5}}>
                    <StatusBadge status={booking.status} size="medium" />
                  </Box>
                </Box>

                <Box sx={{textAlign: 'right'}}>
                  <Typography variant="caption" color="text.secondary" sx={{fontWeight: 700}}>
                    TOTAL CHARGE
                  </Typography>
                  <Typography variant="h4" sx={{fontWeight: 800, color: '#10B981'}}>
                    {money(booking.priceMinor)}
                  </Typography>
                </Box>
              </Box>

              <Divider sx={{my: 2.5}} />

              {/* Service & Hub Breakdown */}
              <Grid container spacing={3}>
                <Grid size={{xs: 12, sm: 6}}>
                  <Typography variant="caption" color="text.secondary" sx={{fontWeight: 700}}>
                    SERVICE PACKAGE
                  </Typography>
                  <Typography variant="h6" sx={{fontWeight: 700, mt: 0.5}}>
                    {booking.service?.name || 'Standard Package'}
                  </Typography>
                  <Typography variant="body2" color="text.secondary" sx={{mt: 0.5}}>
                    Duration: {booking.service?.durationMinutes || '45'} mins
                  </Typography>
                </Grid>

                <Grid size={{xs: 12, sm: 6}}>
                  <Typography variant="caption" color="text.secondary" sx={{fontWeight: 700}}>
                    ASSIGNED SERVICE HUB
                  </Typography>
                  <Typography
                    component={Link}
                    to={`/shops/${booking.carWashId}`}
                    variant="h6"
                    sx={{
                      fontWeight: 700,
                      mt: 0.5,
                      display: 'block',
                      color: 'inherit',
                      textDecoration: 'none',
                      '&:hover': {color: '#6366F1'},
                    }}
                  >
                    {booking.carWash?.name || booking.carWashId}
                  </Typography>
                  <Typography variant="body2" color="text.secondary" sx={{mt: 0.5}}>
                    ID: {booking.carWashId}
                  </Typography>
                </Grid>
              </Grid>

              <Divider sx={{my: 2.5}} />

              {/* Audit Timestamps */}
              <Box sx={{display: 'flex', gap: 3, flexWrap: 'wrap'}}>
                <Box>
                  <Typography variant="caption" color="text.secondary" sx={{fontWeight: 600}}>
                    CREATED AT
                  </Typography>
                  <Typography variant="body2" sx={{fontWeight: 600}}>
                    {toDate(booking.createdAt)}
                  </Typography>
                </Box>
                <Box>
                  <Typography variant="caption" color="text.secondary" sx={{fontWeight: 600}}>
                    LAST UPDATED
                  </Typography>
                  <Typography variant="body2" sx={{fontWeight: 600}}>
                    {toDate(booking.updatedAt)}
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Customer Information Card */}
        <Grid size={{xs: 12, md: 4}}>
          <Card sx={{height: '100%'}}>
            <CardContent sx={{p: 3}}>
              <Typography variant="h6" sx={{fontWeight: 700, mb: 2}}>
                Customer Profile
              </Typography>

              <Box sx={{display: 'flex', alignItems: 'center', gap: 1.5, mb: 2.5}}>
                <Box
                  sx={{
                    width: 44,
                    height: 44,
                    borderRadius: 2.5,
                    backgroundColor: 'rgba(99, 102, 241, 0.1)',
                    color: '#6366F1',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontWeight: 700,
                  }}
                >
                  <UserIcon size={20} />
                </Box>
                <Box>
                  <Typography
                    component={Link}
                    to={`/users/${booking.customerId}`}
                    variant="subtitle1"
                    sx={{
                      fontWeight: 700,
                      color: 'inherit',
                      textDecoration: 'none',
                      '&:hover': {color: '#6366F1'},
                    }}
                  >
                    {booking.customer?.displayName || 'Customer'}
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    UID: {booking.customerId.substring(0, 12)}...
                  </Typography>
                </Box>
              </Box>

              <Stack spacing={1.5}>
                {booking.customer?.phoneNumber && (
                  <Box sx={{display: 'flex', alignItems: 'center', gap: 1.25}}>
                    <Phone size={16} color="#64748B" />
                    <Typography variant="body2" sx={{fontWeight: 600}}>
                      {booking.customer.phoneNumber}
                    </Typography>
                  </Box>
                )}

                {booking.customer?.email && (
                  <Box sx={{display: 'flex', alignItems: 'center', gap: 1.25}}>
                    <Mail size={16} color="#64748B" />
                    <Typography variant="body2" color="text.secondary">
                      {booking.customer.email}
                    </Typography>
                  </Box>
                )}
              </Stack>

              <Button
                component={Link}
                to={`/users/${booking.customerId}`}
                variant="outlined"
                fullWidth
                size="small"
                sx={{mt: 3, borderRadius: 2}}
              >
                Inspect Customer History
              </Button>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

import React, {useState} from 'react';
import {
  Box,
  Grid,
  Card,
  CardContent,
  Typography,
  Button,
  Stack,
  Alert,
  TextField,
  Avatar,
  Divider,
  CircularProgress,
} from '@mui/material';
import {useParams, Link} from 'react-router-dom';
import {useQuery, useMutation, useQueryClient} from '@tanstack/react-query';
import {
  User as UserIcon,
  Phone,
  Mail,
  Shield,
  Store,
  CalendarCheck,
  AlertTriangle,
  ArrowLeft,
  CheckCircle2,
} from 'lucide-react';
import {api, toDate} from '../api/client';
import {User, Shop, Booking} from '../types';
import {PageHeader} from '../components/layout/PageHeader';
import {StatusBadge} from '../components/common/StatusBadge';
import {TableSkeleton} from '../components/common/LoadingSkeleton';
import {useToast} from '../context/ToastContext';

export const UserDetail: React.FC = () => {
  const {id = ''} = useParams();
  const qc = useQueryClient();
  const {showSuccess} = useToast();

  const [reason, setReason] = useState('');
  const [errorMsg, setErrorMsg] = useState('');

  const {
    data,
    isLoading,
    error,
  } = useQuery({
    queryKey: ['user', id],
    queryFn: () => api<{user: User; ownedCarWashes: Shop[]; bookings: Booking[]}>(`/v1/admin/users/${id}`),
  });

  const updateStatusMutation = useMutation({
    mutationFn: async (nextStatus: 'active' | 'suspended') => {
      return api(`/v1/admin/users/${id}/status`, {
        method: 'PATCH',
        body: JSON.stringify({status: nextStatus, reason: reason.trim()}),
      });
    },
    onSuccess: (_, nextStatus) => {
      qc.invalidateQueries({queryKey: ['user', id]});
      qc.invalidateQueries({queryKey: ['users']});
      qc.invalidateQueries({queryKey: ['dashboard']});
      showSuccess(`Account status updated to ${nextStatus}.`);
      setReason('');
      setErrorMsg('');
    },
    onError: (err: any) => {
      setErrorMsg(err instanceof Error ? err.message : 'Failed to update user status.');
    },
  });

  if (isLoading) {
    return (
      <Box>
        <PageHeader title="Loading User Profile..." breadcrumbs={[{label: 'Users', path: '/users'}]} />
        <TableSkeleton rows={3} cols={2} />
      </Box>
    );
  }

  if (error || !data) {
    return (
      <Box>
        <Alert severity="error">
          {error instanceof Error ? error.message : 'Unable to find user account.'}
        </Alert>
        <Button component={Link} to="/users" sx={{mt: 2}} startIcon={<ArrowLeft size={16} />}>
          Back to Users Directory
        </Button>
      </Box>
    );
  }

  const {user, ownedCarWashes = [], bookings = []} = data;
  const isSuspended = user.accountStatus === 'suspended';
  const nextStatus = isSuspended ? 'active' : 'suspended';
  const isActionDisabled = reason.trim().length < 3 || updateStatusMutation.isPending;

  return (
    <Box>
      <PageHeader
        title={user.displayName}
        subtitle={`UID: ${user.uid}`}
        breadcrumbs={[
          {label: 'Overview', path: '/'},
          {label: 'Users', path: '/users'},
          {label: user.displayName},
        ]}
      />

      <Grid container spacing={3}>
        {/* Left Column: Profile & Sanctions */}
        <Grid size={{xs: 12, md: 5}}>
          {/* Profile Card */}
          <Card sx={{mb: 3}}>
            <CardContent sx={{p: 3}}>
              <Box sx={{display: 'flex', alignItems: 'center', gap: 2, mb: 2.5}}>
                <Avatar
                  sx={{
                    width: 56,
                    height: 56,
                    bgcolor: user.roles.includes('owner') ? '#8B5CF6' : '#4F46E5',
                    fontSize: '1.25rem',
                    fontWeight: 700,
                  }}
                >
                  {(user.displayName || 'U')[0].toUpperCase()}
                </Avatar>
                <Box>
                  <Typography variant="h6" sx={{fontWeight: 800}}>
                    {user.displayName}
                  </Typography>
                  <Box sx={{display: 'flex', gap: 1, mt: 0.5, alignItems: 'center'}}>
                    <StatusBadge status={user.accountStatus} size="small" />
                    {user.roles.map((r) => (
                      <StatusBadge key={r} status={r} size="small" />
                    ))}
                  </Box>
                </Box>
              </Box>

              <Divider sx={{my: 2}} />

              <Stack spacing={1.5}>
                <Box sx={{display: 'flex', alignItems: 'center', gap: 1.5}}>
                  <Mail size={16} color="#64748B" />
                  <Typography variant="body2">{user.email || 'No email registered'}</Typography>
                </Box>

                <Box sx={{display: 'flex', alignItems: 'center', gap: 1.5}}>
                  <Phone size={16} color="#64748B" />
                  <Typography variant="body2">{user.phoneNumber || 'No phone registered'}</Typography>
                </Box>

                <Typography variant="caption" color="text.secondary" sx={{mt: 1, display: 'block'}}>
                  Member registered on: {toDate(user.createdAt)}
                </Typography>
              </Stack>
            </CardContent>
          </Card>

          {/* Account Sanctions Card */}
          <Card sx={{border: isSuspended ? '1px solid #10B981' : '1px solid #EF4444'}}>
            <CardContent sx={{p: 3}}>
              <Box sx={{display: 'flex', alignItems: 'center', gap: 1.25, mb: 1}}>
                <AlertTriangle size={20} color={isSuspended ? '#10B981' : '#EF4444'} />
                <Typography variant="h6" sx={{fontWeight: 700}}>
                  {isSuspended ? 'Reactivate Account' : 'Suspend Account'}
                </Typography>
              </Box>

              <Typography variant="body2" color="text.secondary" sx={{mb: 2, lineHeight: 1.5}}>
                {isSuspended
                  ? 'Reactivating will restore login access and allow placing bookings or managing hubs.'
                  : 'Suspension immediately revokes active refresh tokens and blocks login. Registered shops and bookings will not be automatically deleted.'}
              </Typography>

              <TextField
                label="Compliance Reason"
                placeholder="State the regulatory reason for this status change..."
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                multiline
                minRows={2}
                fullWidth
                helperText="Required (min 3 chars) for audit logging."
                sx={{mb: 2}}
              />

              {errorMsg && (
                <Alert severity="error" sx={{mb: 2, borderRadius: 2}}>
                  {errorMsg}
                </Alert>
              )}

              <Button
                variant="contained"
                color={nextStatus === 'suspended' ? 'error' : 'success'}
                disabled={isActionDisabled}
                onClick={() => updateStatusMutation.mutate(nextStatus)}
                fullWidth
                startIcon={
                  updateStatusMutation.isPending ? (
                    <CircularProgress size={16} color="inherit" />
                  ) : null
                }
              >
                {nextStatus === 'suspended' ? 'Confirm Account Suspension' : 'Restore Active Account'}
              </Button>
            </CardContent>
          </Card>
        </Grid>

        {/* Right Column: Owned Shops & Recent Bookings */}
        <Grid size={{xs: 12, md: 7}}>
          {/* Owned Shops */}
          <Card sx={{mb: 3}}>
            <CardContent sx={{p: 3}}>
              <Typography variant="h6" sx={{fontWeight: 700, mb: 2}}>
                Owned Partner Car Washes ({ownedCarWashes.length})
              </Typography>

              {ownedCarWashes.length === 0 ? (
                <Typography variant="body2" color="text.secondary">
                  This user has not registered any car wash facilities.
                </Typography>
              ) : (
                <Stack spacing={1.5}>
                  {ownedCarWashes.map((shop) => (
                    <Box
                      key={shop.id}
                      sx={{
                        p: 2,
                        borderRadius: 2,
                        display: 'flex',
                        justifyContent: 'space-between',
                        alignItems: 'center',
                        backgroundColor: 'rgba(0,0,0,0.02)',
                        border: '1px solid rgba(0,0,0,0.05)',
                      }}
                    >
                      <Box>
                        <Typography
                          component={Link}
                          to={`/shops/${shop.id}`}
                          variant="subtitle2"
                          sx={{
                            fontWeight: 700,
                            color: 'inherit',
                            textDecoration: 'none',
                            '&:hover': {color: '#6366F1'},
                          }}
                        >
                          {shop.name}
                        </Typography>
                        <Typography variant="caption" color="text.secondary" sx={{display: 'block'}}>
                          ID: {shop.id}
                        </Typography>
                      </Box>
                      <StatusBadge status={shop.status} />
                    </Box>
                  ))}
                </Stack>
              )}
            </CardContent>
          </Card>

          {/* Recent Customer Bookings */}
          <Card>
            <CardContent sx={{p: 3}}>
              <Typography variant="h6" sx={{fontWeight: 700, mb: 2}}>
                Recent Appointment History ({bookings.length})
              </Typography>

              {bookings.length === 0 ? (
                <Typography variant="body2" color="text.secondary">
                  No previous bookings found for this customer account.
                </Typography>
              ) : (
                <Stack spacing={1.5}>
                  {bookings.map((booking) => (
                    <Box
                      key={booking.id}
                      sx={{
                        p: 2,
                        borderRadius: 2,
                        display: 'flex',
                        justifyContent: 'space-between',
                        alignItems: 'center',
                        backgroundColor: 'rgba(0,0,0,0.02)',
                        border: '1px solid rgba(0,0,0,0.05)',
                      }}
                    >
                      <Box>
                        <Typography
                          component={Link}
                          to={`/bookings/${booking.id}`}
                          variant="subtitle2"
                          sx={{
                            fontWeight: 700,
                            color: '#6366F1',
                            textDecoration: 'none',
                            '&:hover': {textDecoration: 'underline'},
                          }}
                        >
                          {booking.id}
                        </Typography>
                        <Typography variant="caption" color="text.secondary" sx={{display: 'block'}}>
                          Scheduled: {booking.scheduledDate} {booking.startAt}
                        </Typography>
                      </Box>
                      <StatusBadge status={booking.status} />
                    </Box>
                  ))}
                </Stack>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

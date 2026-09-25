import React from 'react';
import {
  Box,
  Grid,
  Typography,
  Button,
  Card,
  CardContent,
  Alert,
  IconButton,
  Tooltip,
} from '@mui/material';
import {useQuery} from '@tanstack/react-query';
import {useNavigate, Link} from 'react-router-dom';
import {
  Users,
  Store,
  Clock,
  CalendarCheck,
  CheckCircle2,
  AlertCircle,
  TrendingUp,
  ArrowRight,
  RefreshCw,
  ShieldCheck,
  Zap,
} from 'lucide-react';
import {api} from '../api/client';
import {DashboardStats} from '../types';
import {PageHeader} from '../components/layout/PageHeader';
import {StatCard} from '../components/common/StatCard';
import {BookingStatusBar, WeeklyActivityChart} from '../components/common/MetricChart';
import {CardSkeleton} from '../components/common/LoadingSkeleton';

export const Overview: React.FC = () => {
  const navigate = useNavigate();

  const {
    data: stats,
    isLoading,
    error,
    refetch,
    isFetching,
  } = useQuery({
    queryKey: ['dashboard'],
    queryFn: () => api<DashboardStats>('/v1/admin/dashboard'),
    refetchInterval: 60000,
  });

  if (isLoading) {
    return (
      <Box>
        <PageHeader
          title="Executive Dashboard"
          subtitle="Real-time ecosystem metrics across all car wash hubs"
        />
        <CardSkeleton count={6} />
      </Box>
    );
  }

  if (error || !stats) {
    return (
      <Box>
        <Alert
          severity="error"
          action={
            <Button color="inherit" size="small" onClick={() => refetch()}>
              Retry
            </Button>
          }
        >
          {error instanceof Error ? error.message : 'Unable to load dashboard metrics.'}
        </Alert>
      </Box>
    );
  }

  const pendingApprovals = stats.shops?.pending_review ?? 0;

  return (
    <Box>
      <PageHeader
        title="Executive Overview"
        subtitle="Real-time multi-tenant monitoring, partner shop approvals, and booking throughput."
        action={
          <Button
            variant="outlined"
            size="small"
            onClick={() => refetch()}
            startIcon={
              <RefreshCw size={15} className={isFetching ? 'animate-spin' : ''} />
            }
          >
            {isFetching ? 'Refreshing...' : 'Refresh Feed'}
          </Button>
        }
      />

      {/* Urgent Action Banner if shops are waiting for approval */}
      {pendingApprovals > 0 && (
        <Card
          sx={{
            mb: 3.5,
            background:
              'linear-gradient(135deg, rgba(245, 158, 11, 0.12) 0%, rgba(245, 158, 11, 0.04) 100%)',
            border: '1px solid rgba(245, 158, 11, 0.3)',
            borderRadius: 3,
          }}
        >
          <CardContent sx={{p: 2.25, '&:last-child': {pb: 2.25}}}>
            <Box
              sx={{
                display: 'flex',
                flexDirection: {xs: 'column', sm: 'row'},
                alignItems: {xs: 'flex-start', sm: 'center'},
                justifyContent: 'space-between',
                gap: 2,
              }}
            >
              <Box sx={{display: 'flex', alignItems: 'center', gap: 1.75}}>
                <Box
                  sx={{
                    width: 42,
                    height: 42,
                    borderRadius: 2.5,
                    backgroundColor: 'rgba(245, 158, 11, 0.2)',
                    color: '#F59E0B',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  <AlertCircle size={22} />
                </Box>
                <Box>
                  <Typography variant="subtitle1" sx={{fontWeight: 700}}>
                    {pendingApprovals} Partner Hub{pendingApprovals > 1 ? 's' : ''} Awaiting Super Admin Review
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Review licenses, operating capacities, and owner documents to clear the onboarding backlog.
                  </Typography>
                </Box>
              </Box>

              <Button
                component={Link}
                to="/approvals"
                variant="contained"
                color="warning"
                endIcon={<ArrowRight size={16} />}
                sx={{fontWeight: 700, borderRadius: 2}}
              >
                Open Review Queue
              </Button>
            </Box>
          </CardContent>
        </Card>
      )}

      {/* KPI Cards Grid */}
      <Grid container spacing={2.5} sx={{mb: 3.5}}>
        <Grid size={{xs: 12, sm: 6, md: 4}}>
          <StatCard
            title="Total Registered Users"
            value={stats.users}
            subtitle="Customers & shop owners"
            icon={<Users size={22} />}
            trend={{value: '12.4%', positive: true, label: 'MoM Growth'}}
            accentColor="#6366F1"
            onClick={() => navigate('/users')}
          />
        </Grid>

        <Grid size={{xs: 12, sm: 6, md: 4}}>
          <StatCard
            title="Active Service Hubs"
            value={stats.shops.active}
            subtitle="Verified partner facilities"
            icon={<Store size={22} />}
            trend={{value: '4 new', positive: true, label: 'This month'}}
            accentColor="#10B981"
            onClick={() => navigate('/shops?status=active')}
          />
        </Grid>

        <Grid size={{xs: 12, sm: 6, md: 4}}>
          <StatCard
            title="Pending Shop Approvals"
            value={stats.shops.pending_review}
            subtitle="Requires regulatory signoff"
            icon={<Clock size={22} />}
            accentColor="#F59E0B"
            onClick={() => navigate('/approvals')}
          />
        </Grid>

        <Grid size={{xs: 12, sm: 6, md: 4}}>
          <StatCard
            title="Today's Appointments"
            value={stats.todayBookings}
            subtitle="Scheduled for current date"
            icon={<CalendarCheck size={22} />}
            trend={{value: '18%', positive: true, label: 'vs yesterday'}}
            accentColor="#06B6D4"
            onClick={() => navigate('/bookings')}
          />
        </Grid>

        <Grid size={{xs: 12, sm: 6, md: 4}}>
          <StatCard
            title="In-Progress Washes"
            value={stats.bookings.in_progress}
            subtitle="Live vehicles in bays"
            icon={<Zap size={22} />}
            accentColor="#8B5CF6"
            onClick={() => navigate('/bookings?status=in_progress')}
          />
        </Grid>

        <Grid size={{xs: 12, sm: 6, md: 4}}>
          <StatCard
            title="Completed Washes"
            value={stats.bookings.completed}
            subtitle="Successfully fulfilled"
            icon={<CheckCircle2 size={22} />}
            trend={{value: '98.2%', positive: true, label: 'Success rate'}}
            accentColor="#10B981"
            onClick={() => navigate('/bookings?status=completed')}
          />
        </Grid>
      </Grid>

      {/* Visual Charts Grid */}
      <Grid container spacing={2.5}>
        <Grid size={{xs: 12, lg: 6}}>
          <BookingStatusBar stats={stats.bookings} />
        </Grid>
        <Grid size={{xs: 12, lg: 6}}>
          <WeeklyActivityChart />
        </Grid>
      </Grid>
    </Box>
  );
};

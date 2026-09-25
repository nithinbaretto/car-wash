import React, {useState, useMemo} from 'react';
import {
  Box,
  Card,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Typography,
  TextField,
  Button,
  Tabs,
  Tab,
  Alert,
  InputAdornment,
  Stack,
  IconButton,
} from '@mui/material';
import {useQuery} from '@tanstack/react-query';
import {useSearchParams, Link} from 'react-router-dom';
import {
  CalendarCheck,
  Search,
  ExternalLink,
  Clock,
  Store,
  User as UserIcon,
  RefreshCw,
} from 'lucide-react';
import {api, money, query, toDate} from '../api/client';
import {Booking} from '../types';
import {PageHeader} from '../components/layout/PageHeader';
import {StatusBadge} from '../components/common/StatusBadge';
import {TableSkeleton} from '../components/common/LoadingSkeleton';

export const Bookings: React.FC = () => {
  const [searchParams, setSearchParams] = useSearchParams();

  const statusParam = searchParams.get('status') || '';
  const searchId = searchParams.get('id') || '';

  const [searchInput, setSearchInput] = useState(searchId);

  const filters = useMemo(
    () => ({
      status: statusParam || undefined,
      id: searchId || undefined,
    }),
    [statusParam, searchId]
  );

  const {
    data,
    isLoading,
    error,
    refetch,
    isFetching,
  } = useQuery({
    queryKey: ['bookings', filters],
    queryFn: () => api<{bookings: Booking[]}>(`/v1/admin/bookings${query(filters)}`),
  });

  const bookings = data?.bookings || [];

  const handleTabChange = (_: React.SyntheticEvent, newTab: string) => {
    const next = new URLSearchParams(searchParams);
    if (newTab) {
      next.set('status', newTab);
    } else {
      next.delete('status');
    }
    setSearchParams(next);
  };

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const next = new URLSearchParams(searchParams);
    if (searchInput.trim()) {
      next.set('id', searchInput.trim());
    } else {
      next.delete('id');
    }
    setSearchParams(next);
  };

  return (
    <Box>
      <PageHeader
        title="Customer Bookings"
        subtitle="Live feed of customer appointments, operational statuses, and transaction amounts."
        breadcrumbs={[{label: 'Overview', path: '/'}, {label: 'Bookings'}]}
        action={
          <Button
            variant="outlined"
            size="small"
            onClick={() => refetch()}
            startIcon={
              <RefreshCw size={15} className={isFetching ? 'animate-spin' : ''} />
            }
          >
            {isFetching ? 'Refreshing...' : 'Refresh'}
          </Button>
        }
      />

      <Card sx={{mb: 3}}>
        {/* Status Tabs */}
        <Box sx={{borderBottom: '1px solid rgba(0,0,0,0.06)', px: 2, pt: 1}}>
          <Tabs
            value={statusParam}
            onChange={handleTabChange}
            variant="scrollable"
            scrollButtons="auto"
            sx={{
              '& .MuiTab-root': {
                fontWeight: 600,
                fontSize: '0.85rem',
                minHeight: 46,
              },
            }}
          >
            <Tab label="All Bookings" value="" />
            <Tab label="In Progress" value="in_progress" />
            <Tab label="Accepted" value="accepted" />
            <Tab label="Pending" value="pending" />
            <Tab label="Completed" value="completed" />
            <Tab label="Cancelled" value="cancelled" />
          </Tabs>
        </Box>

        {/* Search Toolbar */}
        <Box sx={{p: 2, display: 'flex', gap: 2, flexWrap: 'wrap', alignItems: 'center'}}>
          <Box component="form" onSubmit={handleSearchSubmit} sx={{flex: 1, minWidth: 260}}>
            <TextField
              size="small"
              placeholder="Search by Booking ID (e.g. BK-2026-8941)..."
              value={searchInput}
              onChange={(e) => setSearchInput(e.target.value)}
              fullWidth
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <Search size={16} color="#94A3B8" />
                  </InputAdornment>
                ),
              }}
            />
          </Box>

          <Button type="button" variant="contained" size="small" onClick={handleSearchSubmit}>
            Search
          </Button>

          {searchInput && (
            <Button
              variant="text"
              size="small"
              onClick={() => {
                setSearchInput('');
                const next = new URLSearchParams(searchParams);
                next.delete('id');
                setSearchParams(next);
              }}
            >
              Clear
            </Button>
          )}
        </Box>

        {/* Table Content */}
        {isLoading ? (
          <TableSkeleton rows={5} cols={6} />
        ) : error ? (
          <Box sx={{p: 3}}>
            <Alert severity="error">
              {error instanceof Error ? error.message : 'Failed to fetch bookings.'}
            </Alert>
          </Box>
        ) : bookings.length === 0 ? (
          <Box sx={{p: 6, textAlign: 'center'}}>
            <CalendarCheck size={40} color="#94A3B8" style={{margin: '0 auto 12px'}} />
            <Typography variant="h6" sx={{fontWeight: 700}}>
              No bookings found
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Try changing the status filter or clearing your search.
            </Typography>
          </Box>
        ) : (
          <TableContainer>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Booking Reference</TableCell>
                  <TableCell>Service Center</TableCell>
                  <TableCell>Customer</TableCell>
                  <TableCell>Schedule Slot</TableCell>
                  <TableCell>Price</TableCell>
                  <TableCell>Status</TableCell>
                  <TableCell align="right">View</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {bookings.map((booking) => (
                  <TableRow key={booking.id} hover>
                    <TableCell>
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
                      {booking.service?.name && (
                        <Typography
                          variant="caption"
                          color="text.secondary"
                          sx={{display: 'block', fontSize: '0.725rem'}}
                        >
                          {booking.service.name}
                        </Typography>
                      )}
                    </TableCell>

                    <TableCell>
                      <Box sx={{display: 'flex', alignItems: 'center', gap: 1}}>
                        <Store size={15} color="#94A3B8" />
                        <Typography
                          component={Link}
                          to={`/shops/${booking.carWashId}`}
                          variant="body2"
                          sx={{
                            fontWeight: 600,
                            color: 'inherit',
                            textDecoration: 'none',
                            '&:hover': {color: '#6366F1'},
                          }}
                        >
                          {booking.carWash?.name || booking.carWashId}
                        </Typography>
                      </Box>
                    </TableCell>

                    <TableCell>
                      <Box sx={{display: 'flex', alignItems: 'center', gap: 1}}>
                        <UserIcon size={15} color="#94A3B8" />
                        <Typography
                          component={Link}
                          to={`/users/${booking.customerId}`}
                          variant="body2"
                          sx={{
                            fontWeight: 600,
                            color: 'inherit',
                            textDecoration: 'none',
                            '&:hover': {color: '#6366F1'},
                          }}
                        >
                          {booking.customer?.displayName || booking.customerId}
                        </Typography>
                      </Box>
                    </TableCell>

                    <TableCell>
                      <Box sx={{display: 'flex', alignItems: 'center', gap: 0.75}}>
                        <Clock size={14} color="#94A3B8" />
                        <Typography variant="body2" sx={{fontWeight: 500}}>
                          {booking.scheduledDate} {booking.startAt}
                        </Typography>
                      </Box>
                    </TableCell>

                    <TableCell>
                      <Typography variant="body2" sx={{fontWeight: 700, color: '#10B981'}}>
                        {money(booking.priceMinor)}
                      </Typography>
                    </TableCell>

                    <TableCell>
                      <StatusBadge status={booking.status} />
                    </TableCell>

                    <TableCell align="right">
                      <IconButton
                        component={Link}
                        to={`/bookings/${booking.id}`}
                        size="small"
                        sx={{color: 'text.secondary'}}
                      >
                        <ExternalLink size={16} />
                      </IconButton>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        )}
      </Card>
    </Box>
  );
};

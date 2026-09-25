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
  MenuItem,
  Button,
  Stack,
  Alert,
  Tabs,
  Tab,
  IconButton,
  Tooltip,
  InputAdornment,
  TablePagination,
} from '@mui/material';
import {useQuery} from '@tanstack/react-query';
import {useSearchParams, Link} from 'react-router-dom';
import {
  Store,
  Search,
  ExternalLink,
  Edit3,
  MapPin,
  RefreshCw,
  SlidersHorizontal,
} from 'lucide-react';
import {api, query, toDate} from '../api/client';
import {Shop, ShopStatus} from '../types';
import {PageHeader} from '../components/layout/PageHeader';
import {StatusBadge} from '../components/common/StatusBadge';
import {ReviewModal} from '../components/shops/ReviewModal';
import {TableSkeleton} from '../components/common/LoadingSkeleton';

export const Shops: React.FC = () => {
  const [searchParams, setSearchParams] = useSearchParams();
  const [selectedShop, setSelectedShop] = useState<Shop | null>(null);

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
    queryKey: ['shops', filters],
    queryFn: () => api<{carWashes: Shop[]}>(`/v1/admin/car-washes${query(filters)}`),
  });

  const shops = data?.carWashes || [];

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
        title="Partner Hubs Directory"
        subtitle="Manage all partner car wash locations, verification lifecycle, and operational availability."
        breadcrumbs={[{label: 'Overview', path: '/'}, {label: 'Shops'}]}
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
            <Tab label="All Facilities" value="" />
            <Tab label="Active Hubs" value="active" />
            <Tab label="Pending Review" value="pending_review" />
            <Tab label="Suspended" value="suspended" />
            <Tab label="Rejected" value="rejected" />
          </Tabs>
        </Box>

        {/* Search & Filter Toolbar */}
        <Box sx={{p: 2, display: 'flex', gap: 2, flexWrap: 'wrap', alignItems: 'center'}}>
          <Box component="form" onSubmit={handleSearchSubmit} sx={{flex: 1, minWidth: 260}}>
            <TextField
              size="small"
              placeholder="Search by Shop ID or Name..."
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
          <TableSkeleton rows={5} cols={5} />
        ) : error ? (
          <Box sx={{p: 3}}>
            <Alert severity="error">
              {error instanceof Error ? error.message : 'Failed to fetch shops.'}
            </Alert>
          </Box>
        ) : shops.length === 0 ? (
          <Box sx={{p: 6, textAlign: 'center'}}>
            <Store size={40} color="#94A3B8" style={{margin: '0 auto 12px'}} />
            <Typography variant="h6" sx={{fontWeight: 700}}>
              No partner hubs found
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Try adjusting your search criteria or status filter.
            </Typography>
          </Box>
        ) : (
          <TableContainer>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Shop Name & ID</TableCell>
                  <TableCell>Location / City</TableCell>
                  <TableCell>Owner Account</TableCell>
                  <TableCell>Current Status</TableCell>
                  <TableCell>Registration Date</TableCell>
                  <TableCell align="right">Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {shops.map((shop) => (
                  <TableRow key={shop.id} hover>
                    <TableCell>
                      <Box sx={{display: 'flex', alignItems: 'center', gap: 1.5}}>
                        <Box
                          sx={{
                            width: 38,
                            height: 38,
                            borderRadius: 2,
                            backgroundColor: 'rgba(99, 102, 241, 0.1)',
                            color: '#6366F1',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            flexShrink: 0,
                          }}
                        >
                          <Store size={18} />
                        </Box>
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
                          <Typography
                            variant="caption"
                            color="text.secondary"
                            sx={{display: 'block', fontSize: '0.725rem'}}
                          >
                            {shop.id}
                          </Typography>
                        </Box>
                      </Box>
                    </TableCell>

                    <TableCell>
                      <Box sx={{display: 'flex', alignItems: 'center', gap: 0.75}}>
                        <MapPin size={14} color="#94A3B8" />
                        <Typography variant="body2" noWrap sx={{maxWidth: 220}}>
                          {shop.address?.city || shop.address?.formattedAddress || '—'}
                        </Typography>
                      </Box>
                    </TableCell>

                    <TableCell>
                      {shop.ownerUids.map((uid) => (
                        <Typography
                          key={uid}
                          component={Link}
                          to={`/users/${uid}`}
                          variant="caption"
                          sx={{
                            display: 'inline-block',
                            mr: 1,
                            fontWeight: 600,
                            color: '#6366F1',
                            textDecoration: 'none',
                            '&:hover': {textDecoration: 'underline'},
                          }}
                        >
                          {uid.substring(0, 12)}...
                        </Typography>
                      ))}
                    </TableCell>

                    <TableCell>
                      <StatusBadge status={shop.status} />
                    </TableCell>

                    <TableCell>
                      <Typography variant="body2" color="text.secondary">
                        {toDate(shop.createdAt)}
                      </Typography>
                    </TableCell>

                    <TableCell align="right">
                      <Stack direction="row" spacing={1} justifyContent="flex-end">
                        <Button
                          variant="outlined"
                          size="small"
                          onClick={() => setSelectedShop(shop)}
                          startIcon={<Edit3 size={14} />}
                          sx={{borderRadius: 1.75, py: 0.5}}
                        >
                          Review
                        </Button>
                        <IconButton
                          component={Link}
                          to={`/shops/${shop.id}`}
                          size="small"
                          sx={{color: 'text.secondary'}}
                        >
                          <ExternalLink size={16} />
                        </IconButton>
                      </Stack>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        )}
      </Card>

      {selectedShop && (
        <ReviewModal shop={selectedShop} onClose={() => setSelectedShop(null)} />
      )}
    </Box>
  );
};

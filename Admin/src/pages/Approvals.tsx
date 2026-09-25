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
  IconButton,
  Tooltip,
} from '@mui/material';
import {useQuery} from '@tanstack/react-query';
import {Link} from 'react-router-dom';
import {
  Store,
  MapPin,
  Phone,
  Calendar,
  CheckCircle,
  XCircle,
  ExternalLink,
  ShieldCheck,
  RefreshCw,
  Sparkles,
} from 'lucide-react';
import {api, toDate} from '../api/client';
import {Shop} from '../types';
import {PageHeader} from '../components/layout/PageHeader';
import {StatusBadge} from '../components/common/StatusBadge';
import {ReviewModal} from '../components/shops/ReviewModal';
import {TableSkeleton} from '../components/common/LoadingSkeleton';

export const Approvals: React.FC = () => {
  const [selectedShop, setSelectedShop] = useState<Shop | null>(null);

  const {
    data,
    isLoading,
    error,
    refetch,
    isFetching,
  } = useQuery({
    queryKey: ['shops', {status: 'pending_review'}],
    queryFn: () => api<{carWashes: Shop[]}>('/v1/admin/car-washes?status=pending_review&limit=50'),
    refetchInterval: 30000,
  });

  const pendingShops = data?.carWashes || [];

  return (
    <Box>
      <PageHeader
        title="Partner Approval Queue"
        subtitle="Review new car wash studio onboardings, verify operating licenses, and activate hubs."
        breadcrumbs={[{label: 'Overview', path: '/'}, {label: 'Approvals'}]}
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

      {isLoading ? (
        <TableSkeleton rows={4} cols={4} />
      ) : error ? (
        <Alert severity="error">
          {error instanceof Error ? error.message : 'Unable to load approval queue.'}
        </Alert>
      ) : pendingShops.length === 0 ? (
        <Card
          sx={{
            py: 8,
            textAlign: 'center',
            borderRadius: 4,
            borderStyle: 'dashed',
          }}
        >
          <Box
            sx={{
              width: 64,
              height: 64,
              borderRadius: '50%',
              backgroundColor: 'rgba(16, 185, 129, 0.1)',
              color: '#10B981',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              mx: 'auto',
              mb: 2,
            }}
          >
            <ShieldCheck size={36} />
          </Box>
          <Typography variant="h5" sx={{fontWeight: 700}}>
            Approval Queue Is Clear!
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{maxWidth: 440, mx: 'auto', mt: 1}}>
            All submitted partner studios have been verified and processed. New vendor onboardings will automatically surface here.
          </Typography>
          <Button
            component={Link}
            to="/shops"
            variant="outlined"
            sx={{mt: 3, borderRadius: 2}}
          >
            View All Active Shops
          </Button>
        </Card>
      ) : (
        <Grid container spacing={2.5}>
          {pendingShops.map((shop) => (
            <Grid key={shop.id} size={{xs: 12, md: 6}}>
              <Card
                sx={{
                  height: '100%',
                  display: 'flex',
                  flexDirection: 'column',
                  border: '1px solid rgba(245, 158, 11, 0.3)',
                  transition: 'all 0.2s',
                  '&:hover': {
                    boxShadow: '0 12px 24px -4px rgba(245, 158, 11, 0.15)',
                  },
                }}
              >
                <CardContent sx={{p: 3, flex: 1}}>
                  <Box
                    sx={{
                      display: 'flex',
                      justifyContent: 'space-between',
                      alignItems: 'flex-start',
                      mb: 2,
                    }}
                  >
                    <Box>
                      <Typography variant="h6" sx={{fontWeight: 800, lineHeight: 1.2}}>
                        {shop.name}
                      </Typography>
                      <Typography variant="caption" color="text.secondary">
                        ID: {shop.id}
                      </Typography>
                    </Box>
                    <StatusBadge status={shop.status} />
                  </Box>

                  <Stack spacing={1.5} sx={{my: 2.5}}>
                    <Box sx={{display: 'flex', alignItems: 'flex-start', gap: 1.25}}>
                      <MapPin size={17} color="#64748B" style={{flexShrink: 0, marginTop: 2}} />
                      <Typography variant="body2" color="text.secondary" sx={{lineHeight: 1.4}}>
                        {shop.address?.formattedAddress || 'No formatted address provided'}
                      </Typography>
                    </Box>

                    {shop.contactPhone && (
                      <Box sx={{display: 'flex', alignItems: 'center', gap: 1.25}}>
                        <Phone size={17} color="#64748B" />
                        <Typography variant="body2" sx={{fontWeight: 600}}>
                          {shop.contactPhone}
                        </Typography>
                      </Box>
                    )}

                    <Box sx={{display: 'flex', alignItems: 'center', gap: 1.25}}>
                      <Calendar size={17} color="#64748B" />
                      <Typography variant="caption" color="text.secondary">
                        Submitted: {toDate(shop.createdAt)}
                      </Typography>
                    </Box>
                  </Stack>

                  <Box
                    sx={{
                      pt: 2,
                      borderTop: '1px solid rgba(0,0,0,0.06)',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'space-between',
                      gap: 1.5,
                    }}
                  >
                    <Button
                      component={Link}
                      to={`/shops/${shop.id}`}
                      size="small"
                      color="inherit"
                      endIcon={<ExternalLink size={14} />}
                    >
                      Inspect Profile
                    </Button>

                    <Button
                      variant="contained"
                      color="primary"
                      onClick={() => setSelectedShop(shop)}
                      sx={{borderRadius: 2, fontWeight: 700}}
                    >
                      Review Application
                    </Button>
                  </Box>
                </CardContent>
              </Card>
            </Grid>
          ))}
        </Grid>
      )}

      {selectedShop && (
        <ReviewModal shop={selectedShop} onClose={() => setSelectedShop(null)} />
      )}
    </Box>
  );
};

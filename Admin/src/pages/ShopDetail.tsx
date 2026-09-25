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
  Chip,
  Divider,
  LinearProgress,
} from '@mui/material';
import {useParams, Link} from 'react-router-dom';
import {useQuery} from '@tanstack/react-query';
import {useTheme} from '@mui/material/styles';
import {
  Store,
  MapPin,
  Phone,
  User as UserIcon,
  Calendar,
  Clock,
  DollarSign,
  ArrowLeft,
  Edit3,
  Sparkles,
  ShieldCheck,
} from 'lucide-react';
import {api, money, toDate} from '../api/client';
import {Shop, Service, AvailabilitySlot, User} from '../types';
import {PageHeader} from '../components/layout/PageHeader';
import {StatusBadge} from '../components/common/StatusBadge';
import {ReviewModal} from '../components/shops/ReviewModal';
import {TableSkeleton} from '../components/common/LoadingSkeleton';

export const ShopDetail: React.FC = () => {
  const {id = ''} = useParams();
  const theme = useTheme();
  const isDark = theme.palette.mode === 'dark';

  const [date, setDate] = useState(() => new Date().toISOString().split('T')[0]);
  const [showReview, setShowReview] = useState(false);

  // Shop details + owners
  const {
    data: shopData,
    isLoading: isShopLoading,
    error: shopError,
  } = useQuery({
    queryKey: ['shop', id],
    queryFn: () => api<{carWash: Shop; owners: User[]}>(`/v1/admin/car-washes/${id}`),
  });

  // Services catalog
  const {data: servicesData, isLoading: isServicesLoading} = useQuery({
    queryKey: ['services', id],
    queryFn: () => api<{services: Service[]}>(`/v1/admin/car-washes/${id}/services`),
  });

  // Availability slots for selected date
  const {data: availData, isLoading: isAvailLoading} = useQuery({
    queryKey: ['availability', id, date],
    queryFn: () => api<{date: string; slots: AvailabilitySlot[]}>(`/v1/admin/car-washes/${id}/availability?date=${date}`),
  });

  if (isShopLoading) {
    return (
      <Box>
        <PageHeader title="Loading Hub Details..." breadcrumbs={[{label: 'Shops', path: '/shops'}]} />
        <TableSkeleton rows={4} cols={3} />
      </Box>
    );
  }

  if (shopError || !shopData) {
    return (
      <Box>
        <Alert severity="error">
          {shopError instanceof Error ? shopError.message : 'Unable to find partner hub.'}
        </Alert>
        <Button component={Link} to="/shops" sx={{mt: 2}} startIcon={<ArrowLeft size={16} />}>
          Back to Shops Directory
        </Button>
      </Box>
    );
  }

  const {carWash: shop, owners} = shopData;
  const services = servicesData?.services || [];
  const slots = availData?.slots || [];

  return (
    <Box>
      <PageHeader
        title={shop.name}
        subtitle={`Hub Identifier: ${shop.id}`}
        breadcrumbs={[
          {label: 'Overview', path: '/'},
          {label: 'Shops', path: '/shops'},
          {label: shop.name},
        ]}
        action={
          <Button
            variant="contained"
            color="primary"
            onClick={() => setShowReview(true)}
            startIcon={<Edit3 size={16} />}
            sx={{borderRadius: 2, fontWeight: 700}}
          >
            Review Status
          </Button>
        }
      />

      {/* Hub Hero Card */}
      <Card sx={{mb: 3.5, overflow: 'hidden'}}>
        <Box
          sx={{
            height: 8,
            background: 'linear-gradient(90deg, #6366F1 0%, #06B6D4 100%)',
          }}
        />
        <CardContent sx={{p: {xs: 2.5, md: 3.5}}}>
          <Box
            sx={{
              display: 'flex',
              flexDirection: {xs: 'column', md: 'row'},
              justifyContent: 'space-between',
              alignItems: {xs: 'flex-start', md: 'center'},
              gap: 2.5,
            }}
          >
            <Box sx={{display: 'flex', alignItems: 'center', gap: 2}}>
              <Box
                sx={{
                  width: 56,
                  height: 56,
                  borderRadius: 3,
                  backgroundColor: 'rgba(99, 102, 241, 0.12)',
                  color: '#6366F1',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  flexShrink: 0,
                }}
              >
                <Store size={28} />
              </Box>
              <Box>
                <Box sx={{display: 'flex', alignItems: 'center', gap: 1.5, flexWrap: 'wrap'}}>
                  <Typography variant="h5" sx={{fontWeight: 800}}>
                    {shop.name}
                  </Typography>
                  <StatusBadge status={shop.status} size="medium" />
                </Box>
                <Box sx={{display: 'flex', alignItems: 'center', gap: 1, mt: 0.75}}>
                  <MapPin size={16} color="#64748B" />
                  <Typography variant="body2" color="text.secondary">
                    {shop.address?.formattedAddress || 'Address not registered'}
                  </Typography>
                </Box>
              </Box>
            </Box>

            <Box
              sx={{
                display: 'flex',
                gap: 2,
                flexWrap: 'wrap',
                p: 2,
                borderRadius: 2.5,
                backgroundColor: isDark ? 'rgba(255, 255, 255, 0.02)' : 'rgba(0, 0, 0, 0.02)',
                border: `1px solid ${isDark ? 'rgba(255, 255, 255, 0.06)' : 'rgba(0, 0, 0, 0.05)'}`,
              }}
            >
              <Box>
                <Typography variant="caption" color="text.secondary" sx={{fontWeight: 600}}>
                  CONTACT PHONE
                </Typography>
                <Typography variant="body2" sx={{fontWeight: 700}}>
                  {shop.contactPhone || '—'}
                </Typography>
              </Box>
              <Divider orientation="vertical" flexItem />
              <Box>
                <Typography variant="caption" color="text.secondary" sx={{fontWeight: 600}}>
                  CREATED AT
                </Typography>
                <Typography variant="body2" sx={{fontWeight: 700}}>
                  {toDate(shop.createdAt)}
                </Typography>
              </Box>
            </Box>
          </Box>

          {/* Owner details bar */}
          <Box sx={{mt: 3, pt: 2.5, borderTop: `1px solid ${theme.palette.divider}`}}>
            <Typography variant="caption" color="text.secondary" sx={{fontWeight: 700, letterSpacing: '0.04em'}}>
              AUTHORIZED SHOP OWNERS
            </Typography>
            <Box sx={{display: 'flex', gap: 1.5, flexWrap: 'wrap', mt: 1}}>
              {owners.map((owner) => (
                <Chip
                  key={owner.uid}
                  component={Link}
                  to={`/users/${owner.uid}`}
                  clickable
                  avatar={
                    <Box
                      sx={{
                        width: 24,
                        height: 24,
                        borderRadius: '50%',
                        bgcolor: '#6366F1',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        color: '#fff',
                        fontSize: '0.75rem',
                        fontWeight: 700,
                      }}
                    >
                      {owner.displayName[0].toUpperCase()}
                    </Box>
                  }
                  label={`${owner.displayName} (${owner.email || owner.phoneNumber || owner.uid.substring(0, 8)})`}
                  sx={{
                    py: 1,
                    px: 0.5,
                    borderRadius: 2,
                    fontWeight: 600,
                    border: '1px solid rgba(99, 102, 241, 0.3)',
                  }}
                />
              ))}
            </Box>
          </Box>
        </CardContent>
      </Card>

      {/* Grid: Services Catalog & Operating Slot Availability */}
      <Grid container spacing={3}>
        {/* Services Catalog */}
        <Grid size={{xs: 12, lg: 6}}>
          <Card sx={{height: '100%'}}>
            <CardContent sx={{p: 3}}>
              <Box sx={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2.5}}>
                <Box>
                  <Typography variant="h6" sx={{fontWeight: 700}}>
                    Services Menu & Pricing
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Standard wash packages configured by this hub
                  </Typography>
                </Box>
                <Chip
                  label={`${services.length} services`}
                  size="small"
                  sx={{fontWeight: 700}}
                />
              </Box>

              {services.length === 0 ? (
                <Box sx={{p: 4, textAlign: 'center'}}>
                  <Typography color="text.secondary">No service packages registered yet.</Typography>
                </Box>
              ) : (
                <Stack spacing={2}>
                  {services.map((srv) => (
                    <Box
                      key={srv.id}
                      sx={{
                        p: 2,
                        borderRadius: 2.5,
                        backgroundColor: isDark ? 'rgba(255, 255, 255, 0.02)' : '#F8FAFC',
                        border: `1px solid ${isDark ? 'rgba(255, 255, 255, 0.06)' : 'rgba(0, 0, 0, 0.05)'}`,
                        transition: 'transform 0.15s ease',
                        '&:hover': {transform: 'translateX(4px)'},
                      }}
                    >
                      <Box sx={{display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start'}}>
                        <Typography variant="subtitle1" sx={{fontWeight: 700}}>
                          {srv.name}
                        </Typography>
                        <Typography variant="h6" sx={{fontWeight: 800, color: '#10B981'}}>
                          {money(srv.priceMinor)}
                        </Typography>
                      </Box>
                      {srv.description && (
                        <Typography variant="body2" color="text.secondary" sx={{mt: 0.5, lineHeight: 1.4}}>
                          {srv.description}
                        </Typography>
                      )}
                      <Box sx={{display: 'flex', alignItems: 'center', gap: 1, mt: 1.5}}>
                        <Clock size={15} color="#818CF8" />
                        <Typography variant="caption" sx={{fontWeight: 600, color: '#818CF8'}}>
                          Est. Duration: {srv.durationMinutes} mins
                        </Typography>
                      </Box>
                    </Box>
                  ))}
                </Stack>
              )}
            </CardContent>
          </Card>
        </Grid>

        {/* Operating Slot Availability */}
        <Grid size={{xs: 12, lg: 6}}>
          <Card sx={{height: '100%'}}>
            <CardContent sx={{p: 3}}>
              <Box
                sx={{
                  display: 'flex',
                  flexDirection: {xs: 'column', sm: 'row'},
                  justifyContent: 'space-between',
                  alignItems: {xs: 'flex-start', sm: 'center'},
                  gap: 2,
                  mb: 2.5,
                }}
              >
                <Box>
                  <Typography variant="h6" sx={{fontWeight: 700}}>
                    Bay Capacity & Slots
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Real-time slot utilization by date
                  </Typography>
                </Box>

                <TextField
                  type="date"
                  size="small"
                  value={date}
                  onChange={(e) => setDate(e.target.value)}
                  sx={{minWidth: 160}}
                />
              </Box>

              {slots.length === 0 ? (
                <Box sx={{p: 4, textAlign: 'center'}}>
                  <Typography color="text.secondary">No availability data configured for {date}.</Typography>
                </Box>
              ) : (
                <Stack spacing={2}>
                  {slots.map((slot) => {
                    const pct = slot.capacity > 0 ? (slot.bookedCount / slot.capacity) * 100 : 0;
                    const isFull = slot.bookedCount >= slot.capacity;

                    return (
                      <Box
                        key={slot.startAt}
                        sx={{
                          p: 1.75,
                          borderRadius: 2.5,
                          backgroundColor: isDark ? 'rgba(255, 255, 255, 0.02)' : '#F8FAFC',
                          border: `1px solid ${isDark ? 'rgba(255, 255, 255, 0.06)' : 'rgba(0, 0, 0, 0.05)'}`,
                        }}
                      >
                        <Box sx={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 1}}>
                          <Box sx={{display: 'flex', alignItems: 'center', gap: 1}}>
                            <Clock size={16} color="#6366F1" />
                            <Typography variant="subtitle2" sx={{fontWeight: 700}}>
                              {slot.startAt} – {slot.endAt}
                            </Typography>
                          </Box>

                          <Box sx={{display: 'flex', alignItems: 'center', gap: 1}}>
                            <Typography variant="caption" sx={{fontWeight: 700}}>
                              {slot.bookedCount} / {slot.capacity} Booked
                            </Typography>
                            {isFull && (
                              <Chip
                                label="BUSY"
                                size="small"
                                sx={{
                                  height: 18,
                                  fontSize: '0.625rem',
                                  fontWeight: 800,
                                  backgroundColor: 'rgba(239, 68, 68, 0.15)',
                                  color: '#EF4444',
                                }}
                              />
                            )}
                          </Box>
                        </Box>

                        <LinearProgress
                          variant="determinate"
                          value={Math.min(pct, 100)}
                          sx={{
                            height: 8,
                            borderRadius: 4,
                            backgroundColor: isDark ? 'rgba(255, 255, 255, 0.06)' : '#E2E8F0',
                            '& .MuiLinearProgress-bar': {
                              borderRadius: 4,
                              backgroundColor: isFull ? '#EF4444' : pct > 60 ? '#F59E0B' : '#10B981',
                            },
                          }}
                        />
                      </Box>
                    );
                  })}
                </Stack>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {showReview && (
        <ReviewModal shop={shop} onClose={() => setShowReview(false)} />
      )}
    </Box>
  );
};

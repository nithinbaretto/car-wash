import React, {useEffect} from 'react';
import {Routes, Route, Navigate} from 'react-router-dom';
import {Alert, Box, Button, CircularProgress, Stack, Typography} from '@mui/material';
import {useQuery} from '@tanstack/react-query';
import {Sparkles} from 'lucide-react';
import {useAuth} from './context/AuthContext';
import {api} from './api/client';
import {AdminProfile} from './types';
import {Shell} from './components/layout/Shell';

// Pages
import {Login} from './pages/Login';
import {Overview} from './pages/Overview';
import {Approvals} from './pages/Approvals';
import {Shops} from './pages/Shops';
import {ShopDetail} from './pages/ShopDetail';
import {Bookings} from './pages/Bookings';
import {BookingDetail} from './pages/BookingDetail';
import {Users} from './pages/Users';
import {UserDetail} from './pages/UserDetail';
import {AuditLogs} from './pages/AuditLogs';

const ProtectedRoute: React.FC<{children: React.ReactNode}> = ({children}) => {
  const {user, loading, setAdminProfile, logout} = useAuth();

  const {
    data: profileData,
    isLoading: isProfileLoading,
    error: profileError,
  } = useQuery({
    queryKey: ['admin-me'],
    queryFn: () => api<{admin: AdminProfile}>('/v1/admin/me'),
    enabled: Boolean(user),
  });

  useEffect(() => {
    if (profileData?.admin) {
      setAdminProfile(profileData.admin);
    }
  }, [profileData, setAdminProfile]);

  if (loading || (Boolean(user) && isProfileLoading)) {
    return (
      <Box
        sx={{
          minHeight: '100vh',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          gap: 2.5,
          backgroundColor: 'background.default',
        }}
      >
        <Box
          sx={{
            width: 48,
            height: 48,
            borderRadius: 3,
            background: 'linear-gradient(135deg, #6366F1 0%, #06B6D4 100%)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: '#FFFFFF',
            boxShadow: '0 8px 24px rgba(99, 102, 241, 0.4)',
            animation: 'pulse 2s infinite',
            '@keyframes pulse': {
              '0%': {transform: 'scale(0.96)', opacity: 0.8},
              '50%': {transform: 'scale(1.04)', opacity: 1},
              '100%': {transform: 'scale(0.96)', opacity: 0.8},
            },
          }}
        >
          <Sparkles size={24} />
        </Box>
        <Typography variant="body2" color="text.secondary" sx={{fontWeight: 600}}>
          Authenticating Super Admin Session...
        </Typography>
        <CircularProgress size={24} sx={{color: '#6366F1'}} />
      </Box>
    );
  }

  if (!user) {
    return <Navigate to="/login" replace />;
  }

  if (profileError) {
    return (
      <Box sx={{minHeight: '100vh', display: 'grid', placeItems: 'center', p: 3, backgroundColor: 'background.default'}}>
        <Stack spacing={2} sx={{width: '100%', maxWidth: 460}}>
          <Typography variant="h5" fontWeight={700}>Admin access required</Typography>
          <Alert severity="error">{profileError instanceof Error ? profileError.message : 'Unable to verify super-admin access.'}</Alert>
          <Button variant="contained" onClick={() => logout()}>Sign out</Button>
        </Stack>
      </Box>
    );
  }

  return <Shell>{children}</Shell>;
};

export const App: React.FC = () => {
  const {user} = useAuth();
  const isAuthenticated = Boolean(user);

  return (
    <Routes>
      <Route
        path="/login"
        element={isAuthenticated ? <Navigate to="/" replace /> : <Login />}
      />

      <Route
        path="/"
        element={
          <ProtectedRoute>
            <Overview />
          </ProtectedRoute>
        }
      />

      <Route
        path="/approvals"
        element={
          <ProtectedRoute>
            <Approvals />
          </ProtectedRoute>
        }
      />

      <Route
        path="/shops"
        element={
          <ProtectedRoute>
            <Shops />
          </ProtectedRoute>
        }
      />

      <Route
        path="/shops/:id"
        element={
          <ProtectedRoute>
            <ShopDetail />
          </ProtectedRoute>
        }
      />

      <Route
        path="/bookings"
        element={
          <ProtectedRoute>
            <Bookings />
          </ProtectedRoute>
        }
      />

      <Route
        path="/bookings/:id"
        element={
          <ProtectedRoute>
            <BookingDetail />
          </ProtectedRoute>
        }
      />

      <Route
        path="/users"
        element={
          <ProtectedRoute>
            <Users />
          </ProtectedRoute>
        }
      />

      <Route
        path="/users/:id"
        element={
          <ProtectedRoute>
            <UserDetail />
          </ProtectedRoute>
        }
      />

      <Route
        path="/audit"
        element={
          <ProtectedRoute>
            <AuditLogs />
          </ProtectedRoute>
        }
      />

      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
};

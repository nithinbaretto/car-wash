import React, {useState} from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  TextField,
  Button,
  Stack,
  Alert,
  InputAdornment,
  IconButton,
  Divider,
  Chip,
  CircularProgress,
} from '@mui/material';
import {signInWithEmailAndPassword, sendPasswordResetEmail} from 'firebase/auth';
import {useTheme} from '@mui/material/styles';
import {Eye, EyeOff, Sparkles, Shield, ArrowRight, CheckCircle2} from 'lucide-react';
import {auth, firebaseEnabled, useSessionPersistence} from '../firebase';
import {useAuth} from '../context/AuthContext';
import {useNavigate} from 'react-router-dom';

export const Login: React.FC = () => {
  const theme = useTheme();
  const isDark = theme.palette.mode === 'dark';
  const navigate = useNavigate();
  const {enableDemoMode} = useAuth();

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [sent, setSent] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!firebaseEnabled || !auth) {
      setError('Firebase configuration is missing in Admin/.env.');
      return;
    }

    setError('');
    setSubmitting(true);

    try {
      await useSessionPersistence();
      await signInWithEmailAndPassword(auth, email.trim(), password);
      navigate('/');
    } catch (err: any) {
      setError(err instanceof Error ? err.message : 'Sign-in failed.');
    } finally {
      setSubmitting(false);
    }
  };

  const handleForgotPassword = async () => {
    if (!email.trim()) {
      setError('Enter your registered email address first.');
      return;
    }
    setError('');
    try {
      if (!auth) throw new Error('Firebase Auth not available.');
      await sendPasswordResetEmail(auth, email.trim());
      setSent(true);
    } catch (err: any) {
      setError(err instanceof Error ? err.message : 'Unable to send password reset email.');
    }
  };

  const handleDemoSignIn = () => {
    enableDemoMode();
    navigate('/');
  };

  return (
    <Box
      sx={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        p: 2.5,
        position: 'relative',
        overflow: 'hidden',
        backgroundColor: isDark ? '#080C14' : '#F1F5F9',
      }}
    >
      {/* Background ambient lighting effects */}
      <Box
        sx={{
          position: 'absolute',
          top: '-15%',
          left: '10%',
          width: 500,
          height: 500,
          borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(99, 102, 241, 0.15) 0%, transparent 70%)',
          filter: 'blur(60px)',
          pointerEvents: 'none',
        }}
      />
      <Box
        sx={{
          position: 'absolute',
          bottom: '-15%',
          right: '10%',
          width: 550,
          height: 550,
          borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(6, 182, 212, 0.12) 0%, transparent 70%)',
          filter: 'blur(70px)',
          pointerEvents: 'none',
        }}
      />

      <Card
        sx={{
          width: '100%',
          maxWidth: 440,
          position: 'relative',
          zIndex: 1,
          borderRadius: 4,
          border: `1px solid ${isDark ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.08)'}`,
          boxShadow: isDark
            ? '0 25px 50px -12px rgba(0, 0, 0, 0.7), 0 0 24px -4px rgba(99, 102, 241, 0.15)'
            : '0 20px 40px -10px rgba(15, 23, 42, 0.1)',
        }}
      >
        <CardContent sx={{p: {xs: 3, sm: 4}}}>
          {/* Logo & Header */}
          <Box sx={{textAlign: 'center', mb: 3.5}}>
            <Box
              sx={{
                width: 52,
                height: 52,
                borderRadius: 3,
                mx: 'auto',
                mb: 2,
                background: 'linear-gradient(135deg, #6366F1 0%, #06B6D4 100%)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: '#FFFFFF',
                boxShadow: '0 8px 20px rgba(99, 102, 241, 0.35)',
              }}
            >
              <Sparkles size={28} />
            </Box>

            <Typography variant="h5" sx={{fontWeight: 800, letterSpacing: '-0.02em'}}>
              CleanWheel Admin
            </Typography>
            <Typography variant="body2" color="text.secondary" sx={{mt: 0.5}}>
              Super Admin Authentication & Audit Portal
            </Typography>
          </Box>

          {!firebaseEnabled && (
            <Alert severity="warning" sx={{mb: 2.5, borderRadius: 2}}>
              Firebase credentials missing. You can use <strong>Demo Mode</strong> below to test the full app!
            </Alert>
          )}

          {error && (
            <Alert severity="error" sx={{mb: 2.5, borderRadius: 2}}>
              {error}
            </Alert>
          )}

          {sent && (
            <Alert severity="success" sx={{mb: 2.5, borderRadius: 2}}>
              Password reset link sent to your email. Check your inbox.
            </Alert>
          )}

          <Stack component="form" onSubmit={handleSubmit} spacing={2.25}>
            <TextField
              label="Email Address"
              type="email"
              placeholder="admin@cleanwheel.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              fullWidth
              autoComplete="email"
            />

            <TextField
              label="Password"
              type={showPassword ? 'text' : 'password'}
              placeholder="••••••••"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              fullWidth
              autoComplete="current-password"
              InputProps={{
                endAdornment: (
                  <InputAdornment position="end">
                    <IconButton
                      onClick={() => setShowPassword(!showPassword)}
                      edge="end"
                      size="small"
                    >
                      {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                    </IconButton>
                  </InputAdornment>
                ),
              }}
            />

            <Box sx={{display: 'flex', justifyContent: 'flex-end'}}>
              <Button
                variant="text"
                size="small"
                onClick={handleForgotPassword}
                sx={{fontSize: '0.8rem', color: isDark ? '#818CF8' : '#4F46E5'}}
              >
                Forgot password?
              </Button>
            </Box>

            <Button
              type="submit"
              variant="contained"
              size="large"
              disabled={submitting || !firebaseEnabled}
              sx={{
                py: 1.25,
                fontWeight: 700,
                fontSize: '0.925rem',
              }}
              endIcon={
                submitting ? (
                  <CircularProgress size={18} color="inherit" />
                ) : (
                  <ArrowRight size={18} />
                )
              }
            >
              Sign In to Super Admin
            </Button>

            <Divider sx={{my: 1}}>
              <Typography variant="caption" color="text.secondary" sx={{fontWeight: 600}}>
                OR EXPLORE
              </Typography>
            </Divider>

            {/* Quick Demo Preview Button */}
            <Button
              variant="outlined"
              color="secondary"
              onClick={handleDemoSignIn}
              startIcon={<Shield size={18} />}
              sx={{
                py: 1.1,
                fontWeight: 700,
                borderRadius: 2.5,
                borderWidth: '1.5px',
                '&:hover': {borderWidth: '1.5px'},
              }}
            >
              Preview as Super Admin (Demo Mode)
            </Button>
          </Stack>
        </CardContent>
      </Card>
    </Box>
  );
};

import {Alert, Box, Button, LinearProgress, Typography} from '@mui/material';
import {ShopOnboarding} from '../../types';

interface Props {
  onboarding?: ShopOnboarding;
  loading?: boolean;
  error?: Error | null;
  onRetry?: () => void;
}

export function OnboardingReadiness({onboarding, loading, error, onRetry}: Props) {
  if (loading) return <Box><Typography variant="body2" sx={{mb: 1}}>Checking shop setup…</Typography><LinearProgress /></Box>;
  if (error || !onboarding) return (
    <Alert severity="warning" action={onRetry ? <Button color="inherit" size="small" onClick={onRetry}>Retry</Button> : undefined}>
      {error?.message || 'Shop setup readiness is unavailable. Refresh before approving.'}
    </Alert>
  );
  return (
    <Alert severity={onboarding.complete ? 'success' : 'warning'}>
      <Typography variant="subtitle2">{onboarding.complete ? 'Shop setup is complete' : 'Shop setup needs attention'}</Typography>
      <Typography variant="body2">
        {onboarding.serviceCount} active {onboarding.serviceCount === 1 ? 'service' : 'services'} · {onboarding.availabilityDates.length} scheduled {onboarding.availabilityDates.length === 1 ? 'date' : 'dates'}
      </Typography>
      {onboarding.availabilityDates.length > 0 && <Typography variant="body2">
        {onboarding.availabilityDates[0]} – {onboarding.availabilityDates[onboarding.availabilityDates.length - 1]} (India time)
      </Typography>}
      {onboarding.issues.length > 0 && <Box component="ul" sx={{pl: 2.5, mb: 0.5, mt: 1}}>
        {onboarding.issues.map((issue) => <li key={issue}>{issue}</li>)}
      </Box>}
    </Alert>
  );
}

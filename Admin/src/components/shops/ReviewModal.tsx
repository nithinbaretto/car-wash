import React, {useState} from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  TextField,
  MenuItem,
  Stack,
  Typography,
  Box,
  Alert,
  CircularProgress,
} from '@mui/material';
import {useMutation, useQuery, useQueryClient} from '@tanstack/react-query';
import {CheckCircle2, XCircle, AlertTriangle, RefreshCw} from 'lucide-react';
import {api} from '../../api/client';
import {Shop, ShopOnboarding} from '../../types';
import {OnboardingReadiness} from './OnboardingReadiness';
import {StatusBadge} from '../common/StatusBadge';
import {useToast} from '../../context/ToastContext';

interface ReviewModalProps {
  shop: Shop;
  onClose: () => void;
}

export const ReviewModal: React.FC<ReviewModalProps> = ({shop, onClose}) => {
  const [decision, setDecision] = useState<'approve' | 'reject' | 'suspend' | 'reactivate'>(() => shop.status === 'active' ? 'suspend' : shop.status === 'suspended' ? 'reactivate' : 'approve');
  const [reason, setReason] = useState('');
  const [errorMsg, setErrorMsg] = useState('');

  const qc = useQueryClient();
  const {showSuccess} = useToast();

  const {data: detail, isFetching: checkingSetup, error: setupError, refetch: refreshSetup} = useQuery({
    queryKey: ['shop', shop.id],
    queryFn: () => api<{carWash: Shop; onboarding: ShopOnboarding}>(`/v1/admin/car-washes/${shop.id}`),
    refetchOnMount: 'always',
  });
  const currentShop = detail?.carWash || shop;
  const isPending = currentShop.status === 'pending_review';
  const isActive = currentShop.status === 'active';
  const isSuspended = currentShop.status === 'suspended';

  // Allowed transitions
  const allowedDecisions = isPending
    ? [
        {value: 'approve', label: 'Approve & Activate', icon: <CheckCircle2 size={16} />},
        {value: 'reject', label: 'Reject Application', icon: <XCircle size={16} />},
      ]
    : isActive
    ? [{value: 'suspend', label: 'Suspend Operations', icon: <AlertTriangle size={16} />}]
    : isSuspended
    ? [{value: 'reactivate', label: 'Reactivate to Active', icon: <RefreshCw size={16} />}]
    : [{value: 'approve', label: 'Approve', icon: <CheckCircle2 size={16} />}];

  const reviewMutation = useMutation({
    mutationFn: async () => {
      const payload: any = {
        decision,
        expectedUpdatedAt: currentShop.updatedAt && typeof currentShop.updatedAt !== 'string' ? {
          seconds: currentShop.updatedAt.seconds ?? currentShop.updatedAt._seconds,
          nanoseconds: currentShop.updatedAt.nanoseconds ?? currentShop.updatedAt._nanoseconds ?? 0,
        } : undefined,
      };
      if (decision !== 'approve') {
        payload.reason = reason.trim();
      }
      return api(`/v1/admin/car-washes/${shop.id}/review`, {
        method: 'POST',
        body: JSON.stringify(payload),
      });
    },
    onSuccess: () => {
      qc.invalidateQueries({queryKey: ['shops']});
      qc.invalidateQueries({queryKey: ['shop', shop.id]});
      qc.invalidateQueries({queryKey: ['dashboard']});
      qc.invalidateQueries({queryKey: ['audit']});
      showSuccess(`Shop "${shop.name}" status updated to ${decision}.`);
      onClose();
    },
    onError: (err: any) => {
      setErrorMsg(err instanceof Error ? err.message : 'Failed to update shop review.');
      qc.invalidateQueries({queryKey: ['shop', shop.id]});
    },
  });

  const requiresReason = decision !== 'approve';
  const needsCompleteSetup = decision === 'approve' || decision === 'reactivate';
  const isConfirmDisabled = reviewMutation.isPending || checkingSetup || currentShop.status === 'rejected' ||
    !allowedDecisions.some((option) => option.value === decision) ||
    (needsCompleteSetup && (Boolean(setupError) || detail?.onboarding?.complete !== true)) ||
    (requiresReason && reason.trim().length < 2) || reason.trim().length > 500;

  return (
    <Dialog open onClose={reviewMutation.isPending ? undefined : onClose} fullWidth maxWidth="sm">
      <DialogTitle sx={{pb: 1}}>
        <Box sx={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
          <Typography variant="h6" sx={{fontWeight: 700}}>
            Shop Review: {currentShop.name}
          </Typography>
          <StatusBadge status={currentShop.status} />
        </Box>
        <Typography variant="body2" color="text.secondary" sx={{mt: 0.5}}>
          Shop ID: {shop.id}
        </Typography>
      </DialogTitle>

      <DialogContent dividers sx={{py: 2.5}}>
        <Stack spacing={2.5}>
          {needsCompleteSetup && <OnboardingReadiness onboarding={detail?.onboarding} loading={checkingSetup} error={setupError} onRetry={() => { void refreshSetup(); }} />}
          {currentShop.review?.reason && <Alert severity="info">Previous review: {currentShop.review.reason}</Alert>}
          {currentShop.status === 'rejected' && <Alert severity="info">The owner needs to correct and resubmit this application before it can be approved.</Alert>}
          {currentShop.address?.formattedAddress && (
            <Box
              sx={{
                p: 1.5,
                borderRadius: 2,
                backgroundColor: 'rgba(0,0,0,0.03)',
                border: '1px solid rgba(0,0,0,0.06)',
              }}
            >
              <Typography variant="caption" color="text.secondary" sx={{fontWeight: 600}}>
                LOCATION
              </Typography>
              <Typography variant="body2" sx={{fontWeight: 500, mt: 0.25}}>
                {currentShop.address.formattedAddress}
              </Typography>
            </Box>
          )}

          <TextField
            select
            label="Review Decision"
            value={decision}
            onChange={(e) => {
              setDecision(e.target.value as any);
              setErrorMsg('');
            }}
            fullWidth
          >
            {allowedDecisions.map((opt) => (
              <MenuItem key={opt.value} value={opt.value}>
                <Box sx={{display: 'flex', alignItems: 'center', gap: 1.5}}>
                  {opt.icon}
                  <Typography variant="body2" sx={{fontWeight: 600}}>
                    {opt.label}
                  </Typography>
                </Box>
              </MenuItem>
            ))}
          </TextField>

          {requiresReason && (
            <TextField
              label="Audit Reason"
              placeholder="Explain what the owner needs to correct or why the shop status is changing..."
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              multiline
              minRows={3}
              required
              helperText="The owner can see this reason. It is also saved in the audit log (2–500 characters)."
              fullWidth
            />
          )}

          {errorMsg && (
            <Alert severity="error" sx={{borderRadius: 2}}>
              {errorMsg}
            </Alert>
          )}
        </Stack>
      </DialogContent>

      <DialogActions sx={{px: 3, py: 2}}>
        <Button onClick={onClose} color="inherit" disabled={reviewMutation.isPending}>
          Cancel
        </Button>
        <Button
          variant="contained"
          color={decision === 'reject' || decision === 'suspend' ? 'error' : 'primary'}
          disabled={isConfirmDisabled}
          onClick={() => reviewMutation.mutate()}
          startIcon={reviewMutation.isPending ? <CircularProgress size={16} color="inherit" /> : null}
        >
          Confirm Decision
        </Button>
      </DialogActions>
    </Dialog>
  );
};

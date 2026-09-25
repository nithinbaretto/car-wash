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
import {useMutation, useQueryClient} from '@tanstack/react-query';
import {CheckCircle2, XCircle, AlertTriangle, RefreshCw} from 'lucide-react';
import {api} from '../../api/client';
import {Shop} from '../../types';
import {StatusBadge} from '../common/StatusBadge';
import {useToast} from '../../context/ToastContext';

interface ReviewModalProps {
  shop: Shop;
  onClose: () => void;
}

export const ReviewModal: React.FC<ReviewModalProps> = ({shop, onClose}) => {
  const [decision, setDecision] = useState<'approve' | 'reject' | 'suspend' | 'reactivate'>('approve');
  const [reason, setReason] = useState('');
  const [errorMsg, setErrorMsg] = useState('');

  const qc = useQueryClient();
  const {showSuccess} = useToast();

  const isPending = shop.status === 'pending_review';
  const isActive = shop.status === 'active';
  const isSuspended = shop.status === 'suspended';

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
        expectedUpdatedAt: shop.updatedAt,
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
      showSuccess(`Shop "${shop.name}" status updated to ${decision}.`);
      onClose();
    },
    onError: (err: any) => {
      setErrorMsg(err instanceof Error ? err.message : 'Failed to update shop review.');
    },
  });

  const requiresReason = decision !== 'approve';
  const isConfirmDisabled =
    reviewMutation.isPending || (requiresReason && reason.trim().length < 3);

  return (
    <Dialog open onClose={onClose} fullWidth maxWidth="sm">
      <DialogTitle sx={{pb: 1}}>
        <Box sx={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
          <Typography variant="h6" sx={{fontWeight: 700}}>
            Shop Review: {shop.name}
          </Typography>
          <StatusBadge status={shop.status} />
        </Box>
        <Typography variant="body2" color="text.secondary" sx={{mt: 0.5}}>
          Shop ID: {shop.id}
        </Typography>
      </DialogTitle>

      <DialogContent dividers sx={{py: 2.5}}>
        <Stack spacing={2.5}>
          {shop.address?.formattedAddress && (
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
                {shop.address.formattedAddress}
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
              placeholder="State the regulatory or operational reason for this action..."
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              multiline
              minRows={3}
              required
              helperText="Reason is recorded into compliance audit logs (min 3 characters)."
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

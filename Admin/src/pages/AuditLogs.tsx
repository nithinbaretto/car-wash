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
  Alert,
  Chip,
  InputAdornment,
  Stack,
} from '@mui/material';
import {useQuery} from '@tanstack/react-query';
import {useSearchParams} from 'react-router-dom';
import {
  ShieldCheck,
  Search,
  RefreshCw,
  Clock,
  UserCheck,
  FileText,
} from 'lucide-react';
import {api, query, toDate} from '../api/client';
import {AuditLog} from '../types';
import {PageHeader} from '../components/layout/PageHeader';
import {TableSkeleton} from '../components/common/LoadingSkeleton';

export const AuditLogs: React.FC = () => {
  const [searchParams, setSearchParams] = useSearchParams();

  const actorParam = searchParams.get('actorUid') || '';
  const resourceTypeParam = searchParams.get('resourceType') || '';
  const resourceIdParam = searchParams.get('resourceId') || '';

  const [resourceIdInput, setResourceIdInput] = useState(resourceIdParam);

  const filters = useMemo(
    () => ({
      actorUid: actorParam || undefined,
      resourceType: resourceTypeParam || undefined,
      resourceId: resourceIdParam || undefined,
    }),
    [actorParam, resourceTypeParam, resourceIdParam]
  );

  const {
    data,
    isLoading,
    error,
    refetch,
    isFetching,
  } = useQuery({
    queryKey: ['audit', filters],
    queryFn: () => api<{auditLogs: AuditLog[]}>(`/v1/admin/audit-logs${query(filters)}`),
  });

  const logs = data?.auditLogs || [];

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const next = new URLSearchParams(searchParams);
    if (resourceIdInput.trim()) {
      next.set('resourceId', resourceIdInput.trim());
    } else {
      next.delete('resourceId');
    }
    setSearchParams(next);
  };

  const getActionColor = (action: string) => {
    if (action.includes('approve') || action.includes('active')) return 'success';
    if (action.includes('reject') || action.includes('suspend')) return 'error';
    return 'primary';
  };

  return (
    <Box>
      <PageHeader
        title="Security & Compliance Audit Trail"
        subtitle="Immutable ledger of administrative actions, partner shop state transitions, and user account sanctions."
        breadcrumbs={[{label: 'Overview', path: '/'}, {label: 'Security & Audit'}]}
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
        {/* Filter bar */}
        <Box sx={{p: 2, display: 'flex', gap: 2, flexWrap: 'wrap', alignItems: 'center'}}>
          <Box component="form" onSubmit={handleSearchSubmit} sx={{flex: 1, minWidth: 240}}>
            <TextField
              size="small"
              placeholder="Search by Target Resource ID..."
              value={resourceIdInput}
              onChange={(e) => setResourceIdInput(e.target.value)}
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

          <TextField
            select
            size="small"
            label="Resource Type"
            value={resourceTypeParam}
            onChange={(e) => {
              const next = new URLSearchParams(searchParams);
              if (e.target.value) next.set('resourceType', e.target.value);
              else next.delete('resourceType');
              setSearchParams(next);
            }}
            sx={{minWidth: 160}}
          >
            <MenuItem value="">All Resource Types</MenuItem>
            <MenuItem value="carWash">Car Wash Shop</MenuItem>
            <MenuItem value="user">User Account</MenuItem>
            <MenuItem value="booking">Customer Booking</MenuItem>
          </TextField>

          <Button variant="contained" size="small" onClick={handleSearchSubmit}>
            Filter
          </Button>

          {(resourceIdInput || resourceTypeParam) && (
            <Button
              variant="text"
              size="small"
              onClick={() => {
                setResourceIdInput('');
                setSearchParams({});
              }}
            >
              Reset
            </Button>
          )}
        </Box>

        {/* Table Content */}
        {isLoading ? (
          <TableSkeleton rows={5} cols={5} />
        ) : error ? (
          <Box sx={{p: 3}}>
            <Alert severity="error">
              {error instanceof Error ? error.message : 'Failed to fetch audit records.'}
            </Alert>
          </Box>
        ) : logs.length === 0 ? (
          <Box sx={{p: 6, textAlign: 'center'}}>
            <ShieldCheck size={40} color="#94A3B8" style={{margin: '0 auto 12px'}} />
            <Typography variant="h6" sx={{fontWeight: 700}}>
              No audit records logged
            </Typography>
            <Typography variant="body2" color="text.secondary">
              No matching regulatory records found for the specified filters.
            </Typography>
          </Box>
        ) : (
          <TableContainer>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Timestamp (IST)</TableCell>
                  <TableCell>Administrator</TableCell>
                  <TableCell>Action Executed</TableCell>
                  <TableCell>Target Resource</TableCell>
                  <TableCell>Reason & Audit Payload</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {logs.map((log) => (
                  <TableRow key={log.id} hover>
                    <TableCell>
                      <Box sx={{display: 'flex', alignItems: 'center', gap: 1}}>
                        <Clock size={14} color="#94A3B8" />
                        <Typography variant="body2" sx={{fontWeight: 500}}>
                          {toDate(log.createdAt)}
                        </Typography>
                      </Box>
                    </TableCell>

                    <TableCell>
                      <Box sx={{display: 'flex', alignItems: 'center', gap: 1}}>
                        <UserCheck size={15} color="#6366F1" />
                        <Typography variant="body2" sx={{fontWeight: 600}}>
                          {log.actorUid}
                        </Typography>
                      </Box>
                    </TableCell>

                    <TableCell>
                      <Chip
                        label={log.action}
                        color={getActionColor(log.action) as any}
                        size="small"
                        sx={{fontWeight: 700, fontSize: '0.725rem'}}
                      />
                    </TableCell>

                    <TableCell>
                      <Typography variant="body2" sx={{fontWeight: 600}}>
                        {log.resourceType}:
                      </Typography>
                      <Typography variant="caption" color="text.secondary">
                        {log.resourceId}
                      </Typography>
                    </TableCell>

                    <TableCell>
                      <Typography variant="body2" sx={{fontWeight: 500}}>
                        {log.details?.reason || 'System state change record'}
                      </Typography>
                      {log.details?.beforeStatus && log.details?.afterStatus && (
                        <Typography variant="caption" color="text.secondary" sx={{display: 'block', mt: 0.5}}>
                          Transition: <strong>{log.details.beforeStatus}</strong> → <strong>{log.details.afterStatus}</strong>
                        </Typography>
                      )}
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

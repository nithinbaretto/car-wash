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
  Avatar,
  Stack,
  IconButton,
} from '@mui/material';
import {useQuery} from '@tanstack/react-query';
import {useSearchParams, Link} from 'react-router-dom';
import {
  Users as UsersIcon,
  Search,
  ExternalLink,
  Phone,
  Mail,
  RefreshCw,
  Shield,
} from 'lucide-react';
import {api, query, toDate} from '../api/client';
import {User} from '../types';
import {PageHeader} from '../components/layout/PageHeader';
import {StatusBadge} from '../components/common/StatusBadge';
import {TableSkeleton} from '../components/common/LoadingSkeleton';

export const Users: React.FC = () => {
  const [searchParams, setSearchParams] = useSearchParams();

  const roleParam = searchParams.get('role') || '';
  const statusParam = searchParams.get('status') || '';
  const searchUid = searchParams.get('uid') || '';

  const [searchInput, setSearchInput] = useState(searchUid);

  const filters = useMemo(
    () => ({
      role: roleParam || undefined,
      status: statusParam || undefined,
      uid: searchUid || undefined,
    }),
    [roleParam, statusParam, searchUid]
  );

  const {
    data,
    isLoading,
    error,
    refetch,
    isFetching,
  } = useQuery({
    queryKey: ['users', filters],
    queryFn: () => api<{users: User[]}>(`/v1/admin/users${query(filters)}`),
  });

  const users = data?.users || [];

  const handleRoleTabChange = (_: React.SyntheticEvent, newRole: string) => {
    const next = new URLSearchParams(searchParams);
    if (newRole) {
      next.set('role', newRole);
    } else {
      next.delete('role');
    }
    setSearchParams(next);
  };

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const next = new URLSearchParams(searchParams);
    if (searchInput.trim()) {
      next.set('uid', searchInput.trim());
    } else {
      next.delete('uid');
    }
    setSearchParams(next);
  };

  return (
    <Box>
      <PageHeader
        title="User & Partner Directory"
        subtitle="Manage end-customer accounts, partner shop owners, and regulatory account sanctions."
        breadcrumbs={[{label: 'Overview', path: '/'}, {label: 'Users'}]}
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
        {/* Role Tabs */}
        <Box sx={{borderBottom: '1px solid rgba(0,0,0,0.06)', px: 2, pt: 1}}>
          <Tabs
            value={roleParam}
            onChange={handleRoleTabChange}
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
            <Tab label="All Accounts" value="" />
            <Tab label="Shop Owners" value="owner" />
            <Tab label="Customers" value="customer" />
          </Tabs>
        </Box>

        {/* Search Toolbar */}
        <Box sx={{p: 2, display: 'flex', gap: 2, flexWrap: 'wrap', alignItems: 'center'}}>
          <Box component="form" onSubmit={handleSearchSubmit} sx={{flex: 1, minWidth: 260}}>
            <TextField
              size="small"
              placeholder="Search by User UID..."
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
                next.delete('uid');
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
              {error instanceof Error ? error.message : 'Failed to fetch users.'}
            </Alert>
          </Box>
        ) : users.length === 0 ? (
          <Box sx={{p: 6, textAlign: 'center'}}>
            <UsersIcon size={40} color="#94A3B8" style={{margin: '0 auto 12px'}} />
            <Typography variant="h6" sx={{fontWeight: 700}}>
              No user accounts found
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Try adjusting your role filter or search criteria.
            </Typography>
          </Box>
        ) : (
          <TableContainer>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>User Profile</TableCell>
                  <TableCell>Contact Information</TableCell>
                  <TableCell>Assigned Roles</TableCell>
                  <TableCell>Account Status</TableCell>
                  <TableCell>Joined On</TableCell>
                  <TableCell align="right">Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {users.map((user) => (
                  <TableRow key={user.uid} hover>
                    <TableCell>
                      <Box sx={{display: 'flex', alignItems: 'center', gap: 1.5}}>
                        <Avatar
                          sx={{
                            width: 38,
                            height: 38,
                            bgcolor: user.roles.includes('owner') ? '#8B5CF6' : '#6366F1',
                            fontWeight: 700,
                            fontSize: '0.875rem',
                          }}
                        >
                          {(user.displayName || 'U')[0].toUpperCase()}
                        </Avatar>
                        <Box>
                          <Typography
                            component={Link}
                            to={`/users/${user.uid}`}
                            variant="subtitle2"
                            sx={{
                              fontWeight: 700,
                              color: 'inherit',
                              textDecoration: 'none',
                              '&:hover': {color: '#6366F1'},
                            }}
                          >
                            {user.displayName}
                          </Typography>
                          <Typography
                            variant="caption"
                            color="text.secondary"
                            sx={{display: 'block', fontSize: '0.725rem'}}
                          >
                            {user.uid}
                          </Typography>
                        </Box>
                      </Box>
                    </TableCell>

                    <TableCell>
                      <Stack spacing={0.5}>
                        {user.email && (
                          <Box sx={{display: 'flex', alignItems: 'center', gap: 0.75}}>
                            <Mail size={13} color="#94A3B8" />
                            <Typography variant="body2" color="text.secondary">
                              {user.email}
                            </Typography>
                          </Box>
                        )}
                        {user.phoneNumber && (
                          <Box sx={{display: 'flex', alignItems: 'center', gap: 0.75}}>
                            <Phone size={13} color="#94A3B8" />
                            <Typography variant="body2" color="text.secondary">
                              {user.phoneNumber}
                            </Typography>
                          </Box>
                        )}
                        {!user.email && !user.phoneNumber && (
                          <Typography variant="body2" color="text.secondary">
                            —
                          </Typography>
                        )}
                      </Stack>
                    </TableCell>

                    <TableCell>
                      <Box sx={{display: 'flex', gap: 0.75, flexWrap: 'wrap'}}>
                        {user.roles.map((r) => (
                          <StatusBadge key={r} status={r} />
                        ))}
                      </Box>
                    </TableCell>

                    <TableCell>
                      <StatusBadge status={user.accountStatus} />
                    </TableCell>

                    <TableCell>
                      <Typography variant="body2" color="text.secondary">
                        {toDate(user.createdAt)}
                      </Typography>
                    </TableCell>

                    <TableCell align="right">
                      <Button
                        component={Link}
                        to={`/users/${user.uid}`}
                        variant="outlined"
                        size="small"
                        endIcon={<ExternalLink size={14} />}
                        sx={{borderRadius: 1.75}}
                      >
                        Inspect
                      </Button>
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

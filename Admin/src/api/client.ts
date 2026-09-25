import {auth} from '../firebase';
import {Timestamp} from '../types';
import {
  mockDashboardStats,
  mockShops,
  mockServices,
  mockAvailabilitySlots,
  mockBookings,
  mockUsers,
  mockAuditLogs,
} from './mockData';

const baseUrl = import.meta.env.VITE_API_URL || '';

export const toDate = (value: Timestamp | string | null | undefined): string => {
  if (!value) return '—';
  let date: Date;
  if (typeof value === 'string') {
    date = new Date(value);
  } else {
    date = new Date((value.seconds ?? value._seconds ?? 0) * 1000);
  }

  if (isNaN(date.getTime())) return '—';

  return date.toLocaleString('en-IN', {
    timeZone: 'Asia/Kolkata',
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
};

export const toDateOnly = (value: Timestamp | string | null | undefined): string => {
  if (!value) return '—';
  const date = typeof value === 'string' ? new Date(value) : new Date((value.seconds ?? value._seconds ?? 0) * 1000);
  if (isNaN(date.getTime())) return '—';
  return date.toLocaleDateString('en-IN', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  });
};

export const money = (minor?: number | null): string => {
  if (minor == null) return '—';
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    maximumFractionDigits: 0,
  }).format(minor / 100);
};

export const query = (values: Record<string, string | number | undefined | null>): string => {
  const params = new URLSearchParams();
  Object.entries(values).forEach(([key, value]) => {
    if (value !== undefined && value !== null && value !== '') {
      params.set(key, String(value));
    }
  });
  return params.toString() ? `?${params.toString()}` : '';
};

// Check if demo mode is enabled in localStorage
export const isDemoModeActive = (): boolean => {
  return localStorage.getItem('cw_admin_demo_mode') === 'true';
};

export async function api<T>(path: string, init: RequestInit = {}): Promise<T> {
  const isDemo = isDemoModeActive();

  // If in demo mode, intercept API calls and return realistic mock responses
  if (isDemo) {
    await new Promise((r) => setTimeout(r, 200)); // simulate short network latency
    return handleMockRequest<T>(path, init);
  }

  if (!auth?.currentUser) {
    throw new Error('Sign in is required.');
  }

  const request = async (token: string) => {
    const response = await fetch(`${baseUrl}${path}`, {
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
        ...(init.headers || {}),
      },
      ...init,
    });
    return {response, body: await response.json().catch(() => ({}))};
  };

  let result = await request(await auth.currentUser.getIdToken());
  // Custom claims are minted into new ID tokens. Retry once with a forced
  // refresh so a just-provisioned super-admin account works immediately.
  if (result.response.status === 403 && result.body.error?.code === 'SUPER_ADMIN_REQUIRED') {
    result = await request(await auth.currentUser.getIdToken(true));
  }

  const {response, body} = result;
  if (!response.ok) {
    throw new Error(body.error?.message || 'Request failed.');
  }
  return body.data as T;
}

function handleMockRequest<T>(path: string, init: RequestInit): T {
  const cleanPath = path.split('?')[0];

  if (cleanPath === '/v1/admin/me') {
    return {
      admin: {
        uid: 'super_admin_demo',
        email: 'superadmin@cleanwheel.internal',
        displayName: 'Aayush Shah (Super Admin)',
        permissions: ['super_admin'],
      },
    } as T;
  }

  if (cleanPath === '/v1/admin/dashboard') {
    return mockDashboardStats as T;
  }

  if (cleanPath === '/v1/admin/car-washes') {
    const url = new URL(`http://local${path}`);
    const status = url.searchParams.get('status');
    const id = url.searchParams.get('id');
    let list = [...mockShops];
    if (status) list = list.filter((s) => s.status === status);
    if (id) list = list.filter((s) => s.id.toLowerCase().includes(id.toLowerCase()) || s.name.toLowerCase().includes(id.toLowerCase()));
    return {carWashes: list, hasMore: false, nextCursor: null} as T;
  }

  if (cleanPath.startsWith('/v1/admin/car-washes/') && cleanPath.endsWith('/services')) {
    const shopId = cleanPath.split('/')[4];
    return {services: mockServices[shopId] || mockServices['cw_01']} as T;
  }

  if (cleanPath.startsWith('/v1/admin/car-washes/') && cleanPath.endsWith('/availability')) {
    const url = new URL(`http://local${path}`);
    return {date: url.searchParams.get('date') || 'today', slots: mockAvailabilitySlots} as T;
  }

  if (cleanPath.startsWith('/v1/admin/car-washes/') && cleanPath.endsWith('/review')) {
    return {success: true} as T;
  }

  if (cleanPath.startsWith('/v1/admin/car-washes/')) {
    const shopId = cleanPath.split('/')[4];
    const shop = mockShops.find((s) => s.id === shopId) || mockShops[0];
    const owners = mockUsers.filter((u) => shop.ownerUids.includes(u.uid));
    return {carWash: shop, owners: owners.length ? owners : [mockUsers[0]]} as T;
  }

  if (cleanPath === '/v1/admin/bookings') {
    const url = new URL(`http://local${path}`);
    const status = url.searchParams.get('status');
    const id = url.searchParams.get('id');
    let list = [...mockBookings];
    if (status) list = list.filter((b) => b.status === status);
    if (id) list = list.filter((b) => b.id.toLowerCase().includes(id.toLowerCase()));
    return {bookings: list, hasMore: false, nextCursor: null} as T;
  }

  if (cleanPath.startsWith('/v1/admin/bookings/')) {
    const bookingId = cleanPath.split('/')[4];
    const booking = mockBookings.find((b) => b.id === bookingId) || mockBookings[0];
    return {booking} as T;
  }

  if (cleanPath === '/v1/admin/users') {
    const url = new URL(`http://local${path}`);
    const role = url.searchParams.get('role');
    const status = url.searchParams.get('status');
    let list = [...mockUsers];
    if (role) list = list.filter((u) => u.roles.includes(role));
    if (status) list = list.filter((u) => u.accountStatus === status);
    return {users: list, hasMore: false, nextCursor: null} as T;
  }

  if (cleanPath.startsWith('/v1/admin/users/') && cleanPath.endsWith('/status')) {
    return {success: true} as T;
  }

  if (cleanPath.startsWith('/v1/admin/users/')) {
    const uid = cleanPath.split('/')[4];
    const user = mockUsers.find((u) => u.uid === uid) || mockUsers[0];
    const owned = mockShops.filter((s) => s.ownerUids.includes(user.uid));
    const userBookings = mockBookings.filter((b) => b.customerId === user.uid);
    return {user, ownedCarWashes: owned, bookings: userBookings} as T;
  }

  if (cleanPath === '/v1/admin/audit-logs') {
    return {auditLogs: mockAuditLogs, hasMore: false, nextCursor: null} as T;
  }

  return {} as T;
}

import {auth} from '../firebase';
import {Timestamp} from '../types';
const baseUrl = (import.meta.env.VITE_API_URL || '').replace(/\/+$/, '');

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

export async function api<T>(path: string, init: RequestInit = {}): Promise<T> {
  if (!auth?.currentUser) {
    throw new Error('Sign in is required.');
  }

  const user = auth.currentUser;
  const request = async (token: string) => {
    const headers = new Headers(init.headers);
    headers.set('Authorization', `Bearer ${token}`);
    if (init.body && !headers.has('Content-Type')) headers.set('Content-Type', 'application/json');
    const response = await fetch(`${baseUrl}${path}`, {...init, headers});
    const body = await response.json().catch(() => null);
    if (!body || typeof body !== 'object') {
      throw new Error('The API returned an invalid response. Check the API URL and server configuration.');
    }
    return {response, body};
  };

  let result = await request(await user.getIdToken());
  // Custom claims are minted into new ID tokens. Retry once with a forced
  // refresh so a just-provisioned super-admin account works immediately.
  if (result.response.status === 401 || (result.response.status === 403 && result.body.error?.code === 'SUPER_ADMIN_REQUIRED')) {
    result = await request(await user.getIdToken(true));
  }

  const {response, body} = result;
  if (!response.ok) {
    throw new Error(body.error?.message || 'Request failed.');
  }
  if (auth.currentUser?.uid !== user.uid) throw new Error('The signed-in account changed. Please retry.');
  if (body.success !== true || !('data' in body)) throw new Error('The API returned an invalid response.');
  return body.data as T;
}

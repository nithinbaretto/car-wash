import {auth} from './firebase';

const baseUrl = import.meta.env.VITE_API_URL || '';
export type Timestamp = {seconds?: number; _seconds?: number; nanoseconds?: number};
export const toDate = (value: Timestamp | string | null | undefined) => {
  if (!value) return '—'; if (typeof value === 'string') return new Date(value).toLocaleString('en-IN', {timeZone: 'Asia/Kolkata'});
  return new Date((value.seconds ?? value._seconds ?? 0) * 1000).toLocaleString('en-IN', {timeZone: 'Asia/Kolkata'});
};
export const money = (minor?: number | null) => minor == null ? '—' : new Intl.NumberFormat('en-IN', {style: 'currency', currency: 'INR'}).format(minor / 100);
export async function api<T>(path: string, init: RequestInit = {}): Promise<T> {
  if (!auth?.currentUser) throw new Error('Sign in is required.');
  const token = await auth.currentUser.getIdToken();
  const response = await fetch(`${baseUrl}${path}`, {headers: {'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json', ...(init.headers || {})}, ...init});
  const body = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(body.error?.message || 'Request failed.');
  return body.data as T;
}
export const query = (values: Record<string, string | undefined | null>) => {
  const params = new URLSearchParams(); Object.entries(values).forEach(([key, value]) => { if (value) params.set(key, value); });
  return params.toString() ? `?${params}` : '';
};

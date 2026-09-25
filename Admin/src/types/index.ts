export type Timestamp = {
  seconds?: number;
  _seconds?: number;
  nanoseconds?: number;
};

export type ShopStatus = 'pending_review' | 'active' | 'rejected' | 'suspended';

export type BookingStatus =
  | 'pending'
  | 'accepted'
  | 'rejected'
  | 'in_progress'
  | 'completed'
  | 'cancelled';

export type UserRole = 'customer' | 'owner' | 'super_admin';
export type AccountStatus = 'active' | 'suspended';

export interface ShopAddress {
  formattedAddress: string;
  latitude?: number;
  longitude?: number;
  city?: string;
  state?: string;
  postalCode?: string;
}

export interface Shop {
  id: string;
  name: string;
  status: ShopStatus;
  ownerUids: string[];
  contactPhone?: string;
  address?: ShopAddress;
  createdAt: Timestamp | string;
  updatedAt?: Timestamp | string;
  review?: {
    stateChangedAt?: Timestamp | string;
    stateChangedBy?: string;
    decision?: string;
    reason?: string | null;
  };
}

export interface Service {
  id: string;
  name: string;
  description?: string;
  priceMinor: number;
  durationMinutes: number;
  createdAt?: Timestamp | string;
}

export interface AvailabilitySlot {
  startAt: string;
  endAt: string;
  capacity: number;
  bookedCount: number;
}

export interface Booking {
  id: string;
  status: BookingStatus;
  carWashId: string;
  carWash?: {
    id?: string;
    name?: string;
    address?: ShopAddress;
  };
  customerId: string;
  customer?: {
    uid?: string;
    displayName?: string;
    phoneNumber?: string;
    email?: string;
  };
  serviceId?: string;
  service?: {
    id?: string;
    name?: string;
    priceMinor?: number;
    durationMinutes?: number;
  };
  priceMinor: number;
  scheduledDate: string;
  startAt: string;
  endAt: string;
  scheduledAt?: Timestamp | string;
  createdAt: Timestamp | string;
  updatedAt: Timestamp | string;
  notes?: string;
}

export interface User {
  uid: string;
  displayName: string;
  email?: string;
  phoneNumber?: string;
  roles: string[];
  accountStatus: AccountStatus;
  createdAt: Timestamp | string;
  updatedAt?: Timestamp | string;
}

export interface AuditLog {
  id: string;
  actorUid: string;
  action: string;
  resourceType: string;
  resourceId: string;
  details?: {
    reason?: string;
    beforeStatus?: string;
    afterStatus?: string;
    [key: string]: any;
  };
  createdAt: Timestamp | string;
}

export interface DashboardStats {
  users: number;
  shops: {
    pending_review: number;
    active: number;
    rejected: number;
    suspended: number;
  };
  bookings: {
    pending: number;
    accepted: number;
    rejected: number;
    in_progress: number;
    completed: number;
    cancelled: number;
  };
  todayBookings: number;
  generatedAt?: Timestamp | string;
}

export interface AdminProfile {
  uid: string;
  email: string | null;
  displayName: string | null;
  permissions: string[];
}

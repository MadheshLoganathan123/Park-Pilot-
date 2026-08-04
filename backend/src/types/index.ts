import { UserRole, ParkingType, ParkingStatus, BookingStatus, PaymentMethod } from './enums';

export * from './enums';

export interface ApiResponse<T = any> {
  success: boolean;
  message: string;
  data?: T;
  error?: any;
}

export interface NearbyQueryParams {
  lat: number;
  lng: number;
  radius?: number; // in kilometers (default 5km)
  parkingType?: ParkingType;
  minPrice?: number;
  maxPrice?: number;
}

export interface CreateBookingDTO {
  parkingSpaceId: string;
  bookingDate: string; // ISO date string
  startTime: string; // ISO date string
  endTime: string; // ISO date string
  paymentMethod?: PaymentMethod;
}

export interface VerifyQrDTO {
  qrCode: string;
}

export interface SyncUserDTO {
  firebaseUid: string;
  email: string;
  name: string;
  phone?: string;
  profileImage?: string;
  role?: UserRole;
}

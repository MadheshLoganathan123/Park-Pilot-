import { Router } from 'express';
import {
  createBooking,
  getBookingById,
  getCustomerBookings,
  getProviderBookings,
  cancelBooking,
  verifyQrCode,
  checkInBooking,
} from '../controllers/bookingController';
import { authenticateFirebaseToken } from '../middleware/auth';
import { authorizeRoles } from '../middleware/rbac';
import { validateBody } from '../middleware/validate';
import { z } from 'zod';
import { UserRole, PaymentMethod } from '../types/enums';

const router = Router();

const createBookingSchema = z.object({
  parkingSpaceId: z.string().uuid(),
  bookingDate: z.string().datetime().or(z.string()),
  startTime: z.string().datetime().or(z.string()),
  endTime: z.string().datetime().or(z.string()),
  paymentMethod: z.nativeEnum(PaymentMethod).optional(),
});

const verifyQrSchema = z.object({
  qrCode: z.string().min(1),
});

// QR verification endpoint for parking providers & scanners
router.post('/verify-qr', authenticateFirebaseToken, validateBody(verifyQrSchema), verifyQrCode);

// Customer reservation endpoint
router.post(
  '/',
  authenticateFirebaseToken,
  authorizeRoles(UserRole.CUSTOMER, UserRole.BOTH),
  validateBody(createBookingSchema),
  createBooking
);

// Booking queries
router.get('/customer/:customerId', authenticateFirebaseToken, getCustomerBookings);
router.get('/provider/:providerId', authenticateFirebaseToken, getProviderBookings);
router.get('/:id', authenticateFirebaseToken, getBookingById);

// Booking Cancellation & Check-In
router.put('/:id/cancel', authenticateFirebaseToken, cancelBooking);
router.put('/:id/check-in', authenticateFirebaseToken, checkInBooking);

export default router;


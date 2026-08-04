import { Router } from 'express';
import {
  getAllParkingSpaces,
  getNearbyParkingSpaces,
  getParkingSpaceById,
  createParkingSpace,
  updateParkingSpace,
  deleteParkingSpace,
  calculateRouteToParking,
} from '../controllers/parkingController';
import { authenticateFirebaseToken } from '../middleware/auth';
import { authorizeRoles } from '../middleware/rbac';
import { validateBody } from '../middleware/validate';
import { z } from 'zod';
import { UserRole, ParkingType, ParkingStatus } from '../types/enums';

const router = Router();

const createParkingSchema = z.object({
  name: z.string().min(3),
  description: z.string().optional(),
  address: z.string().min(5),
  latitude: z.number(),
  longitude: z.number(),
  parkingType: z.nativeEnum(ParkingType).optional(),
  totalSlots: z.number().int().positive(),
  availableSlots: z.number().int().nonnegative().optional(),
  pricePerHour: z.number().positive(),
  operatingHours: z.string().optional(),
});

const updateParkingSchema = createParkingSchema.partial().extend({
  status: z.nativeEnum(ParkingStatus).optional(),
});

// Public Discovery Endpoints
router.get('/', getAllParkingSpaces);
router.get('/nearby', getNearbyParkingSpaces);
router.get('/:id', getParkingSpaceById);
router.get('/:id/route', calculateRouteToParking);

// Protected Provider Operations
router.post(
  '/',
  authenticateFirebaseToken,
  authorizeRoles(UserRole.PROVIDER, UserRole.BOTH),
  validateBody(createParkingSchema),
  createParkingSpace
);

router.put(
  '/:id',
  authenticateFirebaseToken,
  authorizeRoles(UserRole.PROVIDER, UserRole.BOTH),
  validateBody(updateParkingSchema),
  updateParkingSpace
);

router.delete(
  '/:id',
  authenticateFirebaseToken,
  authorizeRoles(UserRole.PROVIDER, UserRole.BOTH),
  deleteParkingSpace
);

export default router;

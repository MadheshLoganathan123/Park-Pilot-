import { Router } from 'express';
import {
  getProviderParkingSpaces,
  getProviderBookings,
  getProviderRevenueStats,
} from '../controllers/providerController';
import { authenticateFirebaseToken, requireParkPilotUser } from '../middleware/auth';
import { authorizeRoles } from '../middleware/rbac';
import { UserRole } from '../types/enums';

const router = Router();

router.use(authenticateFirebaseToken);
router.use(requireParkPilotUser);
router.use(authorizeRoles(UserRole.PROVIDER, UserRole.BOTH));

router.get('/:id/parking', getProviderParkingSpaces);
router.get('/:id/bookings', getProviderBookings);
router.get('/:id/revenue', getProviderRevenueStats);

export default router;

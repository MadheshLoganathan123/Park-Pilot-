import { Router } from 'express';
import {
  getProviderParkingSpaces,
  getProviderBookings,
  getProviderRevenueStats,
  updateProviderSettings,
  updateSlotStatus,
} from '../controllers/providerController';
import { authenticateFirebaseToken, requireParkPilotUser } from '../middleware/auth';
import { authorizeRoles } from '../middleware/rbac';
import { UserRole } from '../types/enums';

const router = Router();

router.use(authenticateFirebaseToken);
router.use(requireParkPilotUser);
router.use(authorizeRoles(UserRole.PROVIDER, UserRole.BOTH));

router.get('/:id/parking', getProviderParkingSpaces);
router.get('/:id/spaces', getProviderParkingSpaces);
router.get('/:id/bookings', getProviderBookings);
router.get('/:id/revenue', getProviderRevenueStats);
router.get('/:id/stats', getProviderRevenueStats);
router.put('/:id/settings', updateProviderSettings);
router.put('/spaces/:spaceId/slots/:slotId/status', updateSlotStatus);

export default router;

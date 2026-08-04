import { Router } from 'express';
import healthRoutes from './healthRoutes';
import userRoutes from './userRoutes';
import parkingRoutes from './parkingRoutes';
import bookingRoutes from './bookingRoutes';
import providerRoutes from './providerRoutes';

const router = Router();

router.use('/', healthRoutes);
router.use('/users', userRoutes);
router.use('/parking', parkingRoutes);
router.use('/bookings', bookingRoutes);
router.use('/providers', providerRoutes);

export default router;

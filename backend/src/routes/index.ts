import { Router } from 'express';
import healthRoutes from './healthRoutes';
import userRoutes from './userRoutes';
import parkingRoutes from './parkingRoutes';
import bookingRoutes from './bookingRoutes';
import providerRoutes from './providerRoutes';
import authRoutes from './authRoutes';
import profileRoutes from './profileRoutes';

const router = Router();

router.use('/', healthRoutes);
router.use('/users', userRoutes);
router.use('/auth', authRoutes);
router.use('/profile', profileRoutes);
router.use('/parking', parkingRoutes);
router.use('/bookings', bookingRoutes);
router.use('/providers', providerRoutes);

export default router;

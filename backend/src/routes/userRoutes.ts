import { Router } from 'express';
import { getUserById, updateUser } from '../controllers/userController';
import { authenticateFirebaseToken, requireParkPilotUser } from '../middleware/auth';
import { validateBody } from '../middleware/validate';
import { z } from 'zod';

const router = Router();

const updateUserSchema = z.object({
  name: z.string().min(2).optional(),
  phone: z.string().optional(),
  profileImage: z.string().url().optional(),
  role: z.enum(['CUSTOMER', 'PROVIDER', 'BOTH']).optional(),
});

// Protected User endpoints
router.get('/:id', authenticateFirebaseToken, requireParkPilotUser, getUserById);
router.put('/:id', authenticateFirebaseToken, requireParkPilotUser, validateBody(updateUserSchema), updateUser);

export default router;

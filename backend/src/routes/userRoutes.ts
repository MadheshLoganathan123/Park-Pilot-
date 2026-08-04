import { Router } from 'express';
import { getUserById, updateUser, syncUser } from '../controllers/userController';
import { authenticateFirebaseToken } from '../middleware/auth';
import { validateBody } from '../middleware/validate';
import { z } from 'zod';
import { UserRole } from '../types/enums';

const router = Router();

const updateUserSchema = z.object({
  name: z.string().min(2).optional(),
  phone: z.string().optional(),
  profileImage: z.string().url().optional(),
  role: z.nativeEnum(UserRole).optional(),
});

const syncUserSchema = z.object({
  firebaseUid: z.string().min(1),
  email: z.string().email(),
  name: z.string().min(1),
  phone: z.string().optional(),
  profileImage: z.string().optional(),
  role: z.nativeEnum(UserRole).optional(),
});

// Sync User endpoint (Open / Authenticated)
router.post('/sync', validateBody(syncUserSchema), syncUser);

// Protected User endpoints
router.get('/:id', authenticateFirebaseToken, getUserById);
router.put('/:id', authenticateFirebaseToken, validateBody(updateUserSchema), updateUser);

export default router;

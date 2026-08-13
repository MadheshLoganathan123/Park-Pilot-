import { Router } from 'express';
import { z } from 'zod';
import { syncAuthenticatedUser } from '../controllers/authController';
import { authenticateFirebaseToken } from '../middleware/auth';
import { validateBody } from '../middleware/validate';
import { UserRole } from '../types/enums';
const router = Router();
router.post('/sync', authenticateFirebaseToken, validateBody(z.object({ role: z.nativeEnum(UserRole).optional() }).strict()), syncAuthenticatedUser);
export default router;

import { Router } from 'express';
import { z } from 'zod';
import { getProfile, updateProfile } from '../controllers/profileController';
import { authenticateFirebaseToken, ensureParkPilotUser } from '../middleware/auth';
import { validateBody } from '../middleware/validate';
import { UserRole } from '../types/enums';
const router = Router();

const supportedImageUrl = z.string()
  .url()
  .max(2048)
  .refine((value) => {
    const protocol = new URL(value).protocol;
    return protocol === 'https:' || protocol === 'http:';
  }, 'Profile image must use an HTTP(S) URL.');

const optionalPhone = z.preprocess(
  (value) => (typeof value === 'string' && value.trim() === '' ? null : value),
  z.string().trim().regex(/^[+0-9()\-\s]{5,30}$/, 'Phone must contain only digits and common phone punctuation.').nullable().optional(),
);

const profileSchema = z.object({
  name: z.string().trim().min(2).max(100).optional(),
  phone: optionalPhone,
  profileImage: supportedImageUrl.optional().nullable(),
  role: z.nativeEnum(UserRole).optional(),
}).strict().refine((value) => Object.keys(value).length > 0, {
  message: 'Provide at least one profile field to update.',
});
router.use(authenticateFirebaseToken, ensureParkPilotUser);
router.get('/', getProfile);
router.put('/', validateBody(profileSchema), updateProfile);
export default router;

import { Request, Response, NextFunction } from 'express';
import { userService } from '../services/userService';
import { sendSuccess } from '../utils/response';
import { AppError } from '../middleware/errorHandler';

export async function getProfile(req: Request, res: Response, next: NextFunction) {
  try {
    const firebaseUid = req.firebaseUser?.firebaseUid;
    if (!firebaseUid) throw new AppError('Unauthenticated user request.', 401);
    const user = await userService.getProfileByFirebaseUid(firebaseUid);
    if (!user) throw new AppError('User not found', 404);
    return sendSuccess(res, { user }, 'Profile retrieved successfully');
  } catch (error) { next(error); }
}

export async function updateProfile(req: Request, res: Response, next: NextFunction) {
  try {
    const firebaseUid = req.firebaseUser?.firebaseUid;
    if (!firebaseUid) throw new AppError('Unauthenticated user request.', 401);
    const user = await userService.updateProfileByFirebaseUid(firebaseUid, req.body);
    return sendSuccess(res, { user }, 'Profile updated successfully');
  } catch (error) { next(error); }
}

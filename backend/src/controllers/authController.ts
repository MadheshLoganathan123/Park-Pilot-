import { Request, Response, NextFunction } from 'express';
import { userService } from '../services/userService';
import { sendSuccess } from '../utils/response';
import { AppError } from '../middleware/errorHandler';

export async function syncAuthenticatedUser(req: Request, res: Response, next: NextFunction) {
  try {
    const firebaseUser = req.firebaseUser;
    if (!firebaseUser?.email) throw new AppError('A verified Firebase email is required to create a ParkPilot profile.', 400);
    await userService.syncAuthenticatedUser({
      firebaseUid: firebaseUser.firebaseUid,
      email: firebaseUser.email,
      name: firebaseUser.name,
      profileImage: firebaseUser.profileImage,
      role: req.body.role,
    });
    const user = await userService.getProfileByFirebaseUid(firebaseUser.firebaseUid);
    if (!user) throw new AppError('User not found after sync.', 404);
    return sendSuccess(res, { user }, 'User synchronized successfully');
  } catch (error) { next(error); }
}

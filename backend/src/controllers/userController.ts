import { Request, Response, NextFunction } from 'express';
import { userService } from '../services/userService';
import { sendSuccess, sendError } from '../utils/response';
import { AppError } from '../middleware/errorHandler';

export async function getUserById(req: Request, res: Response, next: NextFunction) {
  try {
    const { id } = req.params;
    if (req.user?.id !== id) throw new AppError('You can only view your own profile.', 403);
    const user = await userService.getUserById(id);

    if (!user) {
      throw new AppError('User not found', 404);
    }

    return sendSuccess(res, user, 'User details retrieved successfully');
  } catch (error) {
    next(error);
  }
}

export async function updateUser(req: Request, res: Response, next: NextFunction) {
  try {
    const { id } = req.params;
    if (req.user?.id !== id) throw new AppError('You can only update your own profile.', 403);
    const { name, phone, profileImage, role } = req.body;

    const existingUser = await userService.getUserById(id);
    if (!existingUser) {
      throw new AppError('User not found', 404);
    }

    const updatedUser = await userService.updateUser(id, { name, phone, profileImage, role });
    return sendSuccess(res, updatedUser, 'User profile updated successfully');
  } catch (error) {
    next(error);
  }
}

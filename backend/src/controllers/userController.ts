import { Request, Response, NextFunction } from 'express';
import { userService } from '../services/userService';
import { sendSuccess, sendError } from '../utils/response';
import { AppError } from '../middleware/errorHandler';

export async function getUserById(req: Request, res: Response, next: NextFunction) {
  try {
    const { id } = req.params;
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

export async function syncUser(req: Request, res: Response, next: NextFunction) {
  try {
    const { firebaseUid, email, name, phone, profileImage, role } = req.body;

    if (!firebaseUid || !email) {
      throw new AppError('firebaseUid and email are required fields', 400);
    }

    const syncedUser = await userService.syncUser({
      firebaseUid,
      email,
      name: name || email.split('@')[0],
      phone,
      profileImage,
      role,
    });

    return sendSuccess(res, syncedUser, 'User synchronized successfully', 201);
  } catch (error) {
    next(error);
  }
}

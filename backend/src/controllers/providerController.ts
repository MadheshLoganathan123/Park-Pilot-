import { Request, Response, NextFunction } from 'express';
import { providerService } from '../services/providerService';
import { sendSuccess } from '../utils/response';
import { AppError } from '../middleware/errorHandler';

export async function getProviderParkingSpaces(req: Request, res: Response, next: NextFunction) {
  try {
    const { id: providerId } = req.params;

    if (req.user?.id !== providerId) {
      throw new AppError('Unauthorized: You can only view your own provider spaces.', 403);
    }

    const spaces = await providerService.getProviderParkingSpaces(providerId);
    return sendSuccess(res, spaces, 'Provider parking spaces retrieved successfully');
  } catch (error) {
    next(error);
  }
}

export async function getProviderBookings(req: Request, res: Response, next: NextFunction) {
  try {
    const { id: providerId } = req.params;

    if (req.user?.id !== providerId) {
      throw new AppError('Unauthorized: You can only view bookings for your parking spaces.', 403);
    }

    const bookings = await providerService.getProviderBookings(providerId);
    return sendSuccess(res, bookings, 'Provider bookings retrieved successfully');
  } catch (error) {
    next(error);
  }
}

export async function getProviderRevenueStats(req: Request, res: Response, next: NextFunction) {
  try {
    const { id: providerId } = req.params;

    if (req.user?.id !== providerId) {
      throw new AppError('Unauthorized: You can only view revenue statistics for your account.', 403);
    }

    const stats = await providerService.getProviderRevenueStats(providerId);
    return sendSuccess(res, stats, 'Provider revenue & occupancy statistics calculated successfully');
  } catch (error) {
    next(error);
  }
}

export async function updateProviderSettings(req: Request, res: Response, next: NextFunction) {
  try {
    const { id: providerId } = req.params;

    if (req.user?.id !== providerId) {
      throw new AppError('Unauthorized: You can only update settings for your own provider account.', 403);
    }

    const result = await providerService.updateProviderSettings(providerId, req.body);
    return sendSuccess(res, result, 'Provider settings updated successfully');
  } catch (error) {
    next(error);
  }
}

export async function updateSlotStatus(req: Request, res: Response, next: NextFunction) {
  try {
    const { spaceId, slotId } = req.params;
    const { status } = req.body;

    const result = await providerService.updateSlotStatus(spaceId, slotId, status);
    return sendSuccess(res, result, 'Slot status updated successfully');
  } catch (error) {
    next(error);
  }
}

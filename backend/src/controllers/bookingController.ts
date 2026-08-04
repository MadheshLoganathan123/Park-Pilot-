import { Request, Response, NextFunction } from 'express';
import { bookingService } from '../services/bookingService';
import { sendSuccess, sendError } from '../utils/response';
import { AppError } from '../middleware/errorHandler';

export async function createBooking(req: Request, res: Response, next: NextFunction) {
  try {
    const customerId = req.user?.id;
    if (!customerId) {
      throw new AppError('Unauthenticated user request', 401);
    }

    const { parkingSpaceId, bookingDate, startTime, endTime, paymentMethod } = req.body;

    const result = await bookingService.createBooking({
      customerId,
      parkingSpaceId,
      bookingDate: new Date(bookingDate),
      startTime: new Date(startTime),
      endTime: new Date(endTime),
      paymentMethod,
    });

    return sendSuccess(res, result, 'Booking created and confirmed successfully', 201);
  } catch (error) {
    next(error);
  }
}

export async function getBookingById(req: Request, res: Response, next: NextFunction) {
  try {
    const { id } = req.params;
    const booking = await bookingService.getBookingById(id);

    // Authorization check
    if (
      req.user?.role !== 'PROVIDER' &&
      booking.customerId !== req.user?.id &&
      booking.parkingSpace.providerId !== req.user?.id
    ) {
      throw new AppError('Unauthorized access to booking information', 403);
    }

    return sendSuccess(res, booking, 'Booking details retrieved successfully');
  } catch (error) {
    next(error);
  }
}

export async function getCustomerBookings(req: Request, res: Response, next: NextFunction) {
  try {
    const { customerId } = req.params;

    if (req.user?.id !== customerId && req.user?.role !== 'BOTH') {
      throw new AppError('Unauthorized: You can only view your own customer bookings.', 403);
    }

    const bookings = await bookingService.getCustomerBookings(customerId);
    return sendSuccess(res, bookings, 'Customer bookings retrieved successfully');
  } catch (error) {
    next(error);
  }
}

export async function getProviderBookings(req: Request, res: Response, next: NextFunction) {
  try {
    const { providerId } = req.params;

    if (req.user?.id !== providerId && req.user?.role !== 'BOTH') {
      throw new AppError('Unauthorized: You can only view bookings for your parking spaces.', 403);
    }

    const bookings = await bookingService.getProviderBookings(providerId);
    return sendSuccess(res, bookings, 'Provider bookings retrieved successfully');
  } catch (error) {
    next(error);
  }
}

export async function cancelBooking(req: Request, res: Response, next: NextFunction) {
  try {
    const { id } = req.params;
    const userId = req.user?.id;

    if (!userId) {
      throw new AppError('Unauthenticated request', 401);
    }

    const cancelledBooking = await bookingService.cancelBooking(id, userId);
    return sendSuccess(res, cancelledBooking, 'Booking cancelled successfully');
  } catch (error) {
    next(error);
  }
}

export async function verifyQrCode(req: Request, res: Response, next: NextFunction) {
  try {
    const { qrCode } = req.body;

    if (!qrCode) {
      throw new AppError('qrCode parameter is required.', 400);
    }

    const verificationResult = await bookingService.verifyQrCode(qrCode);
    return sendSuccess(res, verificationResult, 'QR Code verification completed');
  } catch (error) {
    next(error);
  }
}

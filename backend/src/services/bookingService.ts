import { prisma } from '../config/prisma';
import { Prisma } from '@prisma/client';
import { generateBookingQrCode } from '../utils/qrGenerator';
import { AppError } from '../middleware/errorHandler';
import { BookingStatus, PaymentMethod, PaymentStatus, NotificationType } from '../types/enums';

export interface CreateBookingInput {
  customerId: string;
  parkingSpaceId: string;
  bookingDate: Date;
  startTime: Date;
  endTime: Date;
  paymentMethod?: PaymentMethod;
}

export class BookingService {
  async createBooking(input: CreateBookingInput) {
    const { customerId, parkingSpaceId, bookingDate, startTime, endTime, paymentMethod = PaymentMethod.UPI } = input;

    // 1. Basic time validation
    const startMs = new Date(startTime).getTime();
    const endMs = new Date(endTime).getTime();

    if (isNaN(startMs) || isNaN(endMs) || endMs <= startMs) {
      throw new AppError('Invalid booking duration. End time must be after start time.', 400);
    }

    const durationHours = Math.round(((endMs - startMs) / (1000 * 60 * 60)) * 100) / 100;
    if (durationHours <= 0) {
      throw new AppError('Duration must be greater than 0 hours.', 400);
    }

    // 2. Fetch parking space details
    const parkingSpace = await prisma.parkingSpace.findUnique({
      where: { id: parkingSpaceId },
    });

    if (!parkingSpace) {
      throw new AppError('Parking space not found.', 404);
    }

    if (parkingSpace.status !== 'ACTIVE') {
      throw new AppError('Parking space is currently inactive or under maintenance.', 400);
    }

    if (parkingSpace.availableSlots <= 0) {
      throw new AppError('Sorry, no parking slots are currently available at this location.', 400);
    }

    const totalAmount = Math.round(durationHours * parkingSpace.pricePerHour * 100) / 100;
    const { qrCode, qrCodeDataUrl } = await generateBookingQrCode();

    // Assign slot identifier (e.g. S-12)
    const slotNumber = `S-${Math.floor(Math.random() * parkingSpace.totalSlots) + 1}`;

    // 3. Execute atomic transaction to prevent overbooking
    const result = await prisma.$transaction(async (tx: Prisma.TransactionClient) => {
      // Re-verify availability inside atomic lock
      const currentSpace = await tx.parkingSpace.findUnique({
        where: { id: parkingSpaceId },
      });

      if (!currentSpace || currentSpace.availableSlots <= 0) {
        throw new AppError('Parking slot was just reserved by another user. Please try again.', 409);
      }

      // Decrement available slots by 1
      await tx.parkingSpace.update({
        where: { id: parkingSpaceId },
        data: {
          availableSlots: { decrement: 1 },
        },
      });

      // Create Booking record
      const booking = await tx.booking.create({
        data: {
          customerId,
          parkingSpaceId,
          bookingDate: new Date(bookingDate),
          startTime: new Date(startTime),
          endTime: new Date(endTime),
          duration: durationHours,
          slotNumber,
          totalAmount,
          status: BookingStatus.CONFIRMED,
          qrCode,
        },
        include: {
          parkingSpace: {
            select: { id: true, name: true, address: true, latitude: true, longitude: true },
          },
          customer: {
            select: { id: true, name: true, email: true, phone: true },
          },
        },
      });

      // Create Payment record
      await tx.payment.create({
        data: {
          bookingId: booking.id,
          amount: totalAmount,
          paymentMethod,
          status: PaymentStatus.COMPLETED,
          transactionId: `TXN_${Date.now()}`,
        },
      });

      // Create Notification for Customer
      await tx.notification.create({
        data: {
          userId: customerId,
          title: 'Booking Confirmed!',
          message: `Your booking at ${parkingSpace.name} for slot ${slotNumber} is confirmed.`,
          type: NotificationType.BOOKING_CONFIRMATION,
        },
      });

      return {
        booking,
        qrCodeDataUrl,
      };
    });

    return result;
  }

  async getBookingById(id: string) {
    const booking = await prisma.booking.findUnique({
      where: { id },
      include: {
        parkingSpace: true,
        customer: { select: { id: true, name: true, email: true, phone: true } },
        payment: true,
      },
    });

    if (!booking) {
      throw new AppError('Booking not found.', 404);
    }

    return booking;
  }

  async getCustomerBookings(customerId: string) {
    return prisma.booking.findMany({
      where: { customerId },
      include: {
        parkingSpace: {
          select: { id: true, name: true, address: true, latitude: true, longitude: true, pricePerHour: true },
        },
        payment: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getProviderBookings(providerId: string) {
    return prisma.booking.findMany({
      where: {
        parkingSpace: {
          providerId,
        },
      },
      include: {
        customer: { select: { id: true, name: true, email: true, phone: true } },
        parkingSpace: { select: { id: true, name: true, address: true } },
        payment: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async cancelBooking(bookingId: string, userId: string) {
    const booking = await prisma.booking.findUnique({
      where: { id: bookingId },
      include: { parkingSpace: true },
    });

    if (!booking) {
      throw new AppError('Booking not found.', 404);
    }

    if (booking.customerId !== userId) {
      throw new AppError('Unauthorized: You can only cancel your own bookings.', 403);
    }

    if (booking.status === BookingStatus.CANCELLED) {
      throw new AppError('Booking is already cancelled.', 400);
    }

    if (booking.status === BookingStatus.COMPLETED) {
      throw new AppError('Completed bookings cannot be cancelled.', 400);
    }

    // Atomic transaction to update booking status and restore slot
    return prisma.$transaction(async (tx: Prisma.TransactionClient) => {
      const updatedBooking = await tx.booking.update({
        where: { id: bookingId },
        data: { status: BookingStatus.CANCELLED },
      });

      // Increment available slots back
      await tx.parkingSpace.update({
        where: { id: booking.parkingSpaceId },
        data: {
          availableSlots: { increment: 1 },
        },
      });

      // Update payment status if exists
      await tx.payment.updateMany({
        where: { bookingId },
        data: { status: PaymentStatus.REFUNDED },
      });

      // Send cancellation notification
      await tx.notification.create({
        data: {
          userId: booking.customerId,
          title: 'Booking Cancelled',
          message: `Your booking at ${booking.parkingSpace.name} has been cancelled successfully.`,
          type: NotificationType.CANCELLATION,
        },
      });

      return updatedBooking;
    });
  }

  async verifyQrCode(qrCode: string) {
    const booking = await prisma.booking.findUnique({
      where: { qrCode },
      include: {
        customer: { select: { id: true, name: true, email: true, phone: true } },
        parkingSpace: { select: { id: true, name: true, address: true, providerId: true } },
        payment: true,
      },
    });

    if (!booking) {
      throw new AppError('Invalid QR Code: Booking record not found.', 404);
    }

    const isValid = booking.status === BookingStatus.CONFIRMED || booking.status === BookingStatus.CHECKED_IN;

    return {
      isValid,
      status: booking.status,
      booking,
    };
  }
}

export const bookingService = new BookingService();

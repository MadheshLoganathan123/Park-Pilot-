import { prisma } from '../config/prisma';
import { BookingStatus, PaymentStatus } from '../types/enums';

export class ProviderService {
  async getProviderParkingSpaces(providerId: string) {
    return prisma.parkingSpace.findMany({
      where: { providerId },
      include: {
        _count: { select: { bookings: true, reviews: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getProviderBookings(providerId: string) {
    return prisma.booking.findMany({
      where: {
        parkingSpace: { providerId },
      },
      include: {
        customer: { select: { id: true, name: true, phone: true, email: true, profileImage: true } },
        parkingSpace: { select: { id: true, name: true, address: true } },
        payment: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getProviderRevenueStats(providerId: string) {
    // 1. Fetch provider parking spaces
    const parkingSpaces = await prisma.parkingSpace.findMany({
      where: { providerId },
      select: {
        id: true,
        name: true,
        totalSlots: true,
        availableSlots: true,
        pricePerHour: true,
      },
    });

    const spaceIds = parkingSpaces.map((s: { id: string }) => s.id);

    // 2. Fetch completed/confirmed payments for these spaces
    const completedPayments = await prisma.payment.aggregate({
      where: {
        status: PaymentStatus.COMPLETED,
        booking: {
          parkingSpaceId: { in: spaceIds },
        },
      },
      _sum: { amount: true },
      _count: { id: true },
    });

    // 3. Calculate booking metrics
    const totalBookingsCount = await prisma.booking.count({
      where: { parkingSpaceId: { in: spaceIds } },
    });

    const activeBookingsCount = await prisma.booking.count({
      where: {
        parkingSpaceId: { in: spaceIds },
        status: { in: [BookingStatus.CONFIRMED, BookingStatus.CHECKED_IN] },
      },
    });

    // 4. Calculate overall occupancy rate
    const totalCapacity = parkingSpaces.reduce((acc: number, s: { totalSlots: number }) => acc + s.totalSlots, 0);
    const totalAvailable = parkingSpaces.reduce((acc: number, s: { availableSlots: number }) => acc + s.availableSlots, 0);
    const totalOccupied = totalCapacity - totalAvailable;
    const occupancyRate = totalCapacity > 0 ? Math.round((totalOccupied / totalCapacity) * 100) : 0;

    return {
      totalRevenue: completedPayments._sum.amount || 0.0,
      totalTransactions: completedPayments._count.id || 0,
      totalParkingSpaces: parkingSpaces.length,
      totalSlotsCapacity: totalCapacity,
      currentlyOccupiedSlots: totalOccupied,
      currentlyAvailableSlots: totalAvailable,
      occupancyRatePercentage: occupancyRate,
      totalBookingsCount,
      activeBookingsCount,
      parkingSpacesSummary: parkingSpaces.map((space: { id: string; name: string; totalSlots: number; availableSlots: number; pricePerHour: number }) => ({
        id: space.id,
        name: space.name,
        totalSlots: space.totalSlots,
        availableSlots: space.availableSlots,
        occupiedSlots: space.totalSlots - space.availableSlots,
        pricePerHour: space.pricePerHour,
      })),
    };
  }
}

export const providerService = new ProviderService();

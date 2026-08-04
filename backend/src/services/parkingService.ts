import { prisma } from '../config/prisma';
import { calculateHaversineDistance } from '../utils/geo';
import { ParkingType, ParkingStatus } from '../types/enums';

export interface CreateParkingSpaceDTO {
  providerId: string;
  name: string;
  description?: string;
  address: string;
  latitude: number;
  longitude: number;
  parkingType?: ParkingType;
  totalSlots: number;
  availableSlots?: number;
  pricePerHour: number;
  operatingHours?: string;
}

export interface UpdateParkingSpaceDTO {
  name?: string;
  description?: string;
  address?: string;
  latitude?: number;
  longitude?: number;
  parkingType?: ParkingType;
  totalSlots?: number;
  availableSlots?: number;
  pricePerHour?: number;
  operatingHours?: string;
  status?: ParkingStatus;
}

export class ParkingService {
  async getAllParkingSpaces(search?: string, status?: ParkingStatus) {
    return prisma.parkingSpace.findMany({
      where: {
        ...(status ? { status } : { status: ParkingStatus.ACTIVE }),
        ...(search
          ? {
              OR: [
                { name: { contains: search, mode: 'insensitive' } },
                { address: { contains: search, mode: 'insensitive' } },
                { description: { contains: search, mode: 'insensitive' } },
              ],
            }
          : {}),
      },
      include: {
        provider: {
          select: { id: true, name: true, phone: true, email: true },
        },
        _count: { select: { reviews: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getNearbyParkingSpaces(userLat: number, userLng: number, radiusKm = 5.0) {
    // Fetch all active parking spaces
    const spaces = await prisma.parkingSpace.findMany({
      where: { status: ParkingStatus.ACTIVE },
      include: {
        provider: {
          select: { id: true, name: true, phone: true, email: true },
        },
        _count: { select: { reviews: true } },
      },
    });

    // Calculate distance for each parking space and filter within radius
    const spacesWithDistance = spaces
      .map((space: any) => {
        const distanceKm = calculateHaversineDistance(userLat, userLng, space.latitude, space.longitude);
        return {
          ...space,
          distanceKm,
        };
      })
      .filter((space: { distanceKm: number }) => space.distanceKm <= radiusKm)
      .sort((a: { distanceKm: number }, b: { distanceKm: number }) => a.distanceKm - b.distanceKm);

    return spacesWithDistance;
  }

  async getParkingSpaceById(id: string) {
    return prisma.parkingSpace.findUnique({
      where: { id },
      include: {
        provider: {
          select: { id: true, name: true, phone: true, email: true },
        },
        reviews: {
          include: {
            customer: { select: { id: true, name: true, profileImage: true } },
          },
          orderBy: { createdAt: 'desc' },
          take: 10,
        },
      },
    });
  }

  async createParkingSpace(dto: CreateParkingSpaceDTO) {
    return prisma.parkingSpace.create({
      data: {
        providerId: dto.providerId,
        name: dto.name,
        description: dto.description,
        address: dto.address,
        latitude: dto.latitude,
        longitude: dto.longitude,
        parkingType: dto.parkingType || ParkingType.COVERED,
        totalSlots: dto.totalSlots,
        availableSlots: dto.availableSlots !== undefined ? dto.availableSlots : dto.totalSlots,
        pricePerHour: dto.pricePerHour,
        operatingHours: dto.operatingHours || '24/7',
        status: ParkingStatus.ACTIVE,
      },
    });
  }

  async updateParkingSpace(id: string, dto: UpdateParkingSpaceDTO) {
    return prisma.parkingSpace.update({
      where: { id },
      data: dto,
    });
  }

  async deleteParkingSpace(id: string) {
    return prisma.parkingSpace.delete({
      where: { id },
    });
  }
}

export const parkingService = new ParkingService();

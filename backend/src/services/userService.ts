import { prisma } from '../config/prisma';
import { UserRole } from '../types/enums';

export class UserService {
  /**
   * Finds a profile by the UID decoded from a verified Firebase ID token.
   * This is the only identifier used to associate an authenticated account
   * with a ParkPilot database record.
   */
  async getUserById(id: string) {
    return prisma.user.findUnique({
      where: { id },
      include: {
        parkingSpaces: { select: { id: true, name: true, address: true } },
        _count: { select: { bookings: true, reviews: true } },
      },
    });
  }

  async getUserByFirebaseUid(firebaseUid: string) {
    return prisma.user.findUnique({
      where: { firebaseUid },
    });
  }

  async getProfileByFirebaseUid(firebaseUid: string) {
    return prisma.user.findUnique({
      where: { firebaseUid },
      include: {
        parkingSpaces: { select: { id: true, name: true, address: true } },
        _count: { select: { bookings: true, reviews: true } },
      },
    });
  }

  async syncAuthenticatedUser(dto: { firebaseUid: string; email: string; name?: string; profileImage?: string; role?: UserRole }) {
    const existingUser = await prisma.user.findUnique({
      where: { firebaseUid: dto.firebaseUid },
    });

    if (existingUser) {
      // Firebase is the source of truth for email. Do not overwrite app profile fields on sign-in.
      return prisma.user.update({ where: { firebaseUid: dto.firebaseUid }, data: { email: dto.email } });
    }

    return prisma.user.create({
      data: {
        firebaseUid: dto.firebaseUid,
        email: dto.email,
        name: dto.name?.trim() || dto.email.split('@')[0],
        profileImage: dto.profileImage,
        role: dto.role || UserRole.CUSTOMER,
      },
    });
  }

  async ensureAuthenticatedUser(dto: { firebaseUid: string; email?: string; name?: string; profileImage?: string }) {
    const email = dto.email?.trim();
    if (!email) {
      throw new Error('A Firebase email is required to create a ParkPilot profile.');
    }

    // The Firebase UID is the only lookup key. Updating the Firebase-sourced
    // email here keeps the local account aligned if it changes upstream while
    // preserving app-owned profile fields and role.
    return prisma.user.upsert({
      where: { firebaseUid: dto.firebaseUid },
      update: { email },
      create: {
        firebaseUid: dto.firebaseUid,
        email,
        name: dto.name?.trim() || email.split('@')[0],
        profileImage: dto.profileImage,
        role: UserRole.CUSTOMER,
      },
    });
  }

  async updateUser(id: string, data: { name?: string; phone?: string; profileImage?: string; role?: UserRole }) {
    return prisma.user.update({
      where: { id },
      data,
    });
  }

  async updateProfileByFirebaseUid(
    firebaseUid: string,
    data: { name?: string; phone?: string | null; profileImage?: string | null; role?: UserRole },
  ) {
    return prisma.user.update({
      where: { firebaseUid },
      data,
    });
  }
}

export const userService = new UserService();

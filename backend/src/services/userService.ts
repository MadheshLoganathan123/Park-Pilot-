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
    const email = dto.email.trim().toLowerCase();

    // 1. Check if user with this firebaseUid exists
    const userByUid = await prisma.user.findUnique({
      where: { firebaseUid: dto.firebaseUid },
    });

    if (userByUid) {
      return prisma.user.update({
        where: { id: userByUid.id },
        data: {
          email,
          ...(dto.role ? { role: dto.role } : {}),
          // Only fill name/profileImage from Firebase token if the user hasn't
          // set their own value yet — prevents login from overwriting profile edits.
          ...(dto.name?.trim() && !userByUid.name ? { name: dto.name.trim() } : {}),
          ...(dto.profileImage && !userByUid.profileImage ? { profileImage: dto.profileImage } : {}),
        },
      });
    }

    // 2. Check if user with this email already exists in DB (e.g. from seed or re-registering in Firebase)
    const userByEmail = await prisma.user.findUnique({
      where: { email },
    });

    if (userByEmail) {
      return prisma.user.update({
        where: { id: userByEmail.id },
        data: {
          firebaseUid: dto.firebaseUid,
          ...(dto.role ? { role: dto.role } : {}),
          // Same guard: only fill from Firebase token if DB fields are empty.
          ...(dto.name?.trim() && !userByEmail.name ? { name: dto.name.trim() } : {}),
          ...(dto.profileImage && !userByEmail.profileImage ? { profileImage: dto.profileImage } : {}),
        },
      });
    }

    // 3. Brand new user
    return prisma.user.create({
      data: {
        firebaseUid: dto.firebaseUid,
        email,
        name: dto.name?.trim() || email.split('@')[0],
        profileImage: dto.profileImage,
        role: dto.role || UserRole.CUSTOMER,
      },
    });
  }

  async ensureAuthenticatedUser(dto: { firebaseUid: string; email?: string; name?: string; profileImage?: string }) {
    const email = dto.email?.trim().toLowerCase();
    if (!email) {
      throw new Error('A Firebase email is required to create a ParkPilot profile.');
    }

    const userByUid = await prisma.user.findUnique({
      where: { firebaseUid: dto.firebaseUid },
    });

    if (userByUid) {
      return prisma.user.update({
        where: { id: userByUid.id },
        data: {
          email,
          ...(dto.name?.trim() && !userByUid.name ? { name: dto.name.trim() } : {}),
          ...(dto.profileImage && !userByUid.profileImage ? { profileImage: dto.profileImage } : {}),
        },
      });
    }

    const userByEmail = await prisma.user.findUnique({
      where: { email },
    });

    if (userByEmail) {
      return prisma.user.update({
        where: { id: userByEmail.id },
        data: {
          firebaseUid: dto.firebaseUid,
          ...(dto.name?.trim() && !userByEmail.name ? { name: dto.name.trim() } : {}),
          ...(dto.profileImage && !userByEmail.profileImage ? { profileImage: dto.profileImage } : {}),
        },
      });
    }

    return prisma.user.create({
      data: {
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

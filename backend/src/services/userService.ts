import { prisma } from '../config/prisma';
import { SyncUserDTO } from '../types';
import { UserRole } from '../types/enums';

export class UserService {
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

  async syncUser(dto: SyncUserDTO) {
    const existingUser = await prisma.user.findUnique({
      where: { firebaseUid: dto.firebaseUid },
    });

    if (existingUser) {
      return prisma.user.update({
        where: { firebaseUid: dto.firebaseUid },
        data: {
          name: dto.name || existingUser.name,
          email: dto.email || existingUser.email,
          phone: dto.phone || existingUser.phone,
          profileImage: dto.profileImage || existingUser.profileImage,
          role: dto.role || (existingUser.role as UserRole),
        },
      });
    }

    return prisma.user.create({
      data: {
        firebaseUid: dto.firebaseUid,
        email: dto.email,
        name: dto.name,
        phone: dto.phone,
        profileImage: dto.profileImage,
        role: dto.role || UserRole.CUSTOMER,
      },
    });
  }

  async updateUser(id: string, data: { name?: string; phone?: string; profileImage?: string; role?: UserRole }) {
    return prisma.user.update({
      where: { id },
      data,
    });
  }
}

export const userService = new UserService();

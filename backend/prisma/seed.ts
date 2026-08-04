import { PrismaClient } from '@prisma/client';
import {
  UserRole,
  ParkingType,
  ParkingStatus,
  BookingStatus,
  PaymentMethod,
  PaymentStatus,
} from '../src/types/enums';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting ParkPilot Database Seeding...');

  // 1. Clean existing records
  await prisma.payment.deleteMany();
  await prisma.booking.deleteMany();
  await prisma.review.deleteMany();
  await prisma.notification.deleteMany();
  await prisma.parkingSpace.deleteMany();
  await prisma.user.deleteMany();

  // 2. Create Users
  const providerUser = await prisma.user.create({
    data: {
      firebaseUid: 'provider_firebase_uid_001',
      name: 'Chennai Metro Parking Services',
      email: 'provider@parkpilot.com',
      phone: '+91 98765 43210',
      profileImage: 'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=150',
      role: UserRole.PROVIDER,
    },
  });

  const customerUser = await prisma.user.create({
    data: {
      firebaseUid: 'customer_firebase_uid_001',
      name: 'Madhesh Loganathan',
      email: 'customer@parkpilot.com',
      phone: '+91 91234 56789',
      profileImage: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      role: UserRole.CUSTOMER,
    },
  });

  const dualRoleUser = await prisma.user.create({
    data: {
      firebaseUid: 'dual_firebase_uid_001',
      name: 'Anand Kumar',
      email: 'anand@parkpilot.com',
      phone: '+91 99887 76655',
      profileImage: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      role: UserRole.BOTH,
    },
  });

  console.log(`✅ Seeded ${3} users.`);

  // 3. Create Parking Spaces in Chennai, India
  const parkingSpaces = await Promise.all([
    prisma.parkingSpace.create({
      data: {
        providerId: providerUser.id,
        name: 'Express Avenue Mall Parking',
        description: 'Multi-level covered basement parking with 24/7 security and EV charging stations.',
        address: 'No. 2, Club House Road, Royapettah, Chennai, Tamil Nadu 600002',
        latitude: 13.0587,
        longitude: 80.2641,
        parkingType: ParkingType.MULTI_LEVEL,
        totalSlots: 150,
        availableSlots: 42,
        pricePerHour: 50.0,
        operatingHours: '09:00 - 23:00',
        status: ParkingStatus.ACTIVE,
      },
    }),
    prisma.parkingSpace.create({
      data: {
        providerId: providerUser.id,
        name: 'T. Nagar Smart MLP Complex',
        description: 'Automated multi-level car parking facility in the heart of commercial T. Nagar.',
        address: 'Thanikachalam Road, T. Nagar, Chennai, Tamil Nadu 600017',
        latitude: 13.0418,
        longitude: 80.2341,
        parkingType: ParkingType.MULTI_LEVEL,
        totalSlots: 200,
        availableSlots: 85,
        pricePerHour: 40.0,
        operatingHours: '08:00 - 22:30',
        status: ParkingStatus.ACTIVE,
      },
    }),
    prisma.parkingSpace.create({
      data: {
        providerId: providerUser.id,
        name: 'Phoenix Marketcity Parking',
        description: 'Spacious covered parking with automated ANPR cameras and valet assistance.',
        address: '142, Velachery Rd, Indira Gandhi Nagar, Velachery, Chennai, Tamil Nadu 600042',
        latitude: 12.9915,
        longitude: 80.2170,
        parkingType: ParkingType.COVERED,
        totalSlots: 250,
        availableSlots: 110,
        pricePerHour: 60.0,
        operatingHours: '10:00 - 23:00',
        status: ParkingStatus.ACTIVE,
      },
    }),
    prisma.parkingSpace.create({
      data: {
        providerId: dualRoleUser.id,
        name: 'Marina Beach Visitor Parking Hub',
        description: 'Open air beachfront parking lot with CCTV surveillance.',
        address: 'Kamalar Salai, Marina Beach, Triplicane, Chennai, Tamil Nadu 600005',
        latitude: 13.0500,
        longitude: 80.2824,
        parkingType: ParkingType.OPEN,
        totalSlots: 100,
        availableSlots: 25,
        pricePerHour: 30.0,
        operatingHours: '24/7',
        status: ParkingStatus.ACTIVE,
      },
    }),
    prisma.parkingSpace.create({
      data: {
        providerId: providerUser.id,
        name: 'Chennai Central Station Parking',
        description: 'Convenient parking right next to Dr. M.G.R. Chennai Central Railway Station.',
        address: 'EVR Periyar Salai, Park Town, Chennai, Tamil Nadu 600003',
        latitude: 13.0827,
        longitude: 80.2707,
        parkingType: ParkingType.COVERED,
        totalSlots: 180,
        availableSlots: 60,
        pricePerHour: 45.0,
        operatingHours: '24/7',
        status: ParkingStatus.ACTIVE,
      },
    }),
  ]);

  console.log(`✅ Seeded ${parkingSpaces.length} Chennai parking spaces.`);

  // 4. Create Sample Booking & Payment
  const sampleBooking = await prisma.booking.create({
    data: {
      customerId: customerUser.id,
      parkingSpaceId: parkingSpaces[0].id,
      bookingDate: new Date(),
      startTime: new Date(),
      endTime: new Date(Date.now() + 2 * 60 * 60 * 1000), // 2 hours later
      duration: 2.0,
      slotNumber: 'A-42',
      totalAmount: 100.0,
      status: BookingStatus.CONFIRMED,
      qrCode: 'PARKPILOT-EA-MALL-A42-TESTQR',
    },
  });

  await prisma.payment.create({
    data: {
      bookingId: sampleBooking.id,
      amount: 100.0,
      paymentMethod: PaymentMethod.UPI,
      status: PaymentStatus.COMPLETED,
      transactionId: 'TXN_UPI_9876543210',
    },
  });

  await prisma.review.create({
    data: {
      customerId: customerUser.id,
      parkingSpaceId: parkingSpaces[0].id,
      rating: 5,
      comment: 'Excellent security and smooth entry via ParkPilot QR scanner!',
    },
  });

  await prisma.notification.create({
    data: {
      userId: customerUser.id,
      title: 'Booking Confirmed!',
      message: 'Your slot A-42 at Express Avenue Mall Parking is reserved for 2 hours.',
      type: 'BOOKING_CONFIRMATION',
    },
  });

  console.log('🎉 ParkPilot Database Seeding Completed Successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Error during seeding:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

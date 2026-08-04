import { PrismaClient } from '@prisma/client';

export const prisma = new PrismaClient({
  log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
});

export async function connectPrisma() {
  try {
    await prisma.$connect();
    console.log('⚡ Prisma ORM connected successfully to PostgreSQL database.');
  } catch (error) {
    console.error('❌ Failed to connect to database via Prisma ORM:', error);
  }
}

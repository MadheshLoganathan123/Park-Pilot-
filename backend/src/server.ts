import app from './app';
import { env } from './config/env';
import { connectPrisma, prisma } from './config/prisma';

async function bootstrap() {
  try {
    // 1. Connect to PostgreSQL via Prisma
    await connectPrisma();

    // 2. Start Express HTTP Server
    const server = app.listen(env.PORT, () => {
      console.log(`
=========================================================
  🚗 ParkPilot Backend API Server is Running!
  -------------------------------------------------------
  📡 Server Listening on : http://localhost:${env.PORT}
  🏥 Health Endpoint     : http://localhost:${env.PORT}/api/health
  🌍 Environment         : ${env.NODE_ENV}
=========================================================
      `);
    });

    // Handle Graceful Shutdown
    const shutdown = async (signal: string) => {
      console.log(`\n🛑 Received ${signal}. Shutting down server gracefully...`);
      server.close(async () => {
        await prisma.$disconnect();
        console.log('⚡ Prisma database connection closed.');
        process.exit(0);
      });
    };

    process.on('SIGTERM', () => shutdown('SIGTERM'));
    process.on('SIGINT', () => shutdown('SIGINT'));
  } catch (error) {
    console.error('❌ Emergency bootstrap failure:', error);
    process.exit(1);
  }
}

bootstrap();

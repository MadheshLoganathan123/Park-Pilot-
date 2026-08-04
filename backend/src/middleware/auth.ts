import { Request, Response, NextFunction } from 'express';
import { admin, isFirebaseInitialized } from '../config/firebase';
import { prisma } from '../config/prisma';
import { sendError } from '../utils/response';
import { UserRole } from '../types/enums';

export async function authenticateFirebaseToken(req: Request, res: Response, next: NextFunction) {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return sendError(res, 'Authentication token missing or invalid format. Header should be Bearer <token>', 401);
    }

    const token = authHeader.split('Bearer ')[1].trim();

    let firebaseUid: string;
    let email: string = '';

    // Development & Testing Mock Bypass
    if (token.startsWith('test-token-') || token.startsWith('dev-token-') || !isFirebaseInitialized) {
      if (token.includes('provider')) {
        firebaseUid = 'provider_firebase_uid_001';
        email = 'provider@parkpilot.com';
      } else {
        firebaseUid = 'customer_firebase_uid_001';
        email = 'customer@parkpilot.com';
      }
    } else {
      // Real Firebase Verification
      const decodedToken = await admin.auth().verifyIdToken(token);
      firebaseUid = decodedToken.uid;
      email = decodedToken.email || '';
    }

    // Lookup user in PostgreSQL database
    let user = await prisma.user.findUnique({
      where: { firebaseUid },
    });

    // Auto-sync / register user if not found yet in database
    if (!user) {
      user = await prisma.user.create({
        data: {
          firebaseUid,
          email: email || `${firebaseUid}@parkpilot-user.com`,
          name: email ? email.split('@')[0] : 'ParkPilot User',
          role: UserRole.CUSTOMER,
        },
      });
    }

    req.user = {
      id: user.id,
      firebaseUid: user.firebaseUid,
      email: user.email,
      role: user.role as UserRole,
      name: user.name,
    };

    return next();
  } catch (error: any) {
    console.error('❌ Firebase Auth Middleware Error:', error.message);
    return sendError(res, 'Unauthorized access. Invalid or expired Firebase token.', 401, error.message);
  }
}

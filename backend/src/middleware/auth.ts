import { Request, Response, NextFunction } from 'express';
import { admin, isFirebaseInitialized } from '../config/firebase';
import { prisma } from '../config/prisma';
import { sendError } from '../utils/response';
import { UserRole } from '../types/enums';
import { AppError } from './errorHandler';
import { userService } from '../services/userService';

/** Verifies a Firebase ID token. It deliberately does not trust client user ids. */
export async function authenticateFirebaseToken(req: Request, res: Response, next: NextFunction) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith('Bearer ')) {
      return sendError(res, 'Authentication token missing or invalid format.', 401);
    }
    const token = authHeader.substring('Bearer '.length).trim();
    if (!token) return sendError(res, 'Authentication token is missing.', 401);
    if (!isFirebaseInitialized) return sendError(res, 'Authentication service is not configured.', 503);

    const decodedToken = await admin.auth().verifyIdToken(token);
    req.firebaseUser = {
      firebaseUid: decodedToken.uid,
      email: decodedToken.email,
      name: decodedToken.name,
      profileImage: decodedToken.picture,
    };
    return next();
  } catch (error: any) {
    console.error('Firebase Auth Middleware Error:', error.message);
    return sendError(res, 'Unauthorized access. Invalid or expired Firebase token.', 401);
  }
}

/** Requires an already-synced ParkPilot profile for normal application APIs. */
export async function requireParkPilotUser(req: Request, res: Response, next: NextFunction) {
  try {
    const firebaseUid = req.firebaseUser?.firebaseUid;
    if (!firebaseUid) return sendError(res, 'Unauthenticated user request.', 401);
    const user = await prisma.user.findUnique({ where: { firebaseUid } });
    if (!user) return sendError(res, 'ParkPilot profile not found. Call /api/auth/sync first.', 404);
    req.user = { id: user.id, firebaseUid: user.firebaseUid, email: user.email, role: user.role as UserRole, name: user.name };
    return next();
  } catch (error) { return next(error); }
}

/**
 * Resolves the current database profile from the verified Firebase UID and
 * provisions a default customer profile for a newly authenticated account.
 * This lets GET /api/profile be safe to call immediately after sign-in.
 */
export async function ensureParkPilotUser(req: Request, res: Response, next: NextFunction) {
  try {
    const firebaseUser = req.firebaseUser;
    if (!firebaseUser?.firebaseUid) return sendError(res, 'Unauthenticated user request.', 401);

    if (!firebaseUser.email?.trim()) {
      throw new AppError('A verified Firebase email is required to create a ParkPilot profile.', 400);
    }

    const user = await userService.ensureAuthenticatedUser(firebaseUser);

    req.user = { id: user.id, firebaseUid: user.firebaseUid, email: user.email, role: user.role as UserRole, name: user.name };
    return next();
  } catch (error: any) {
    return next(error);
  }
}

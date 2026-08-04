import { Request, Response, NextFunction } from 'express';
import { UserRole } from '../types/enums';
import { sendError } from '../utils/response';

export function authorizeRoles(...allowedRoles: UserRole[]) {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user) {
      return sendError(res, 'Unauthenticated user request.', 401);
    }

    const userRole = req.user.role;

    // Users with BOTH role can access both CUSTOMER and PROVIDER operations
    if (userRole === UserRole.BOTH) {
      return next();
    }

    if (allowedRoles.includes(userRole)) {
      return next();
    }

    return sendError(
      res,
      `Forbidden: Action requires one of [${allowedRoles.join(', ')}] roles. Your role is '${userRole}'.`,
      403
    );
  };
}

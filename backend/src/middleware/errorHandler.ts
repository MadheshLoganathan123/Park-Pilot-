import { Request, Response, NextFunction } from 'express';
import { sendError } from '../utils/response';
import { logger } from '../utils/logger';

export class AppError extends Error {
  public statusCode: number;
  public details: any;

  constructor(message: string, statusCode = 500, details: any = null) {
    super(message);
    this.statusCode = statusCode;
    this.details = details;
    Object.setPrototypeOf(this, new.target.prototype);
  }
}

export function globalErrorHandler(
  err: any,
  req: Request,
  res: Response,
  _next: NextFunction
) {
  logger.error(`Error processing ${req.method} ${req.originalUrl}:`, err);

  if (err instanceof AppError) {
    return sendError(res, err.message, err.statusCode, err.details);
  }

  // Handle Zod validation errors if caught directly
  if (err.name === 'ZodError') {
    return sendError(res, 'Validation Error', 400, err.errors);
  }

  // Handle Prisma errors
  if (err.code === 'P2002') {
    return sendError(res, 'A record with this unique identifier already exists.', 409, {
      meta: err.meta,
    });
  }

  if (err.code === 'P2025') {
    return sendError(res, 'Resource not found in database.', 404);
  }

  const statusCode = res.statusCode !== 200 ? res.statusCode : 500;
  return sendError(
    res,
    err.message || 'Internal Server Error',
    statusCode,
    process.env.NODE_ENV === 'development' ? err.stack : undefined
  );
}

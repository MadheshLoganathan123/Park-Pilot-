import { Request, Response } from 'express';
import { sendSuccess } from '../utils/response';

export function getHealthStatus(req: Request, res: Response) {
  return sendSuccess(res, {
    status: 'UP',
    system: 'ParkPilot Backend API',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  }, 'ParkPilot API is operational');
}

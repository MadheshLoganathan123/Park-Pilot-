import express, { Application, Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { env } from './config/env';
import { requestLogger } from './middleware/logger';
import { globalErrorHandler } from './middleware/errorHandler';
import routes from './routes';

const app: Application = express();

// Security Headers
app.use(helmet());

// CORS Configuration
app.use(
  cors({
    origin: env.CORS_ORIGIN === '*' ? true : env.CORS_ORIGIN,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  })
);

// Body Parsing Middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request Logger
app.use(requestLogger);

// Mount API Routes
app.use('/api', routes);

// Root Welcome Endpoint
app.get('/', (req: Request, res: Response) => {
  res.json({
    message: '🚀 Welcome to ParkPilot API – Intelligent Parking Navigation & Reservation System',
    healthCheck: '/api/health',
    documentation: '/README.md',
  });
});

// 404 Handler
app.use((req: Request, res: Response) => {
  res.status(404).json({
    success: false,
    message: `Cannot ${req.method} ${req.originalUrl}. Route not found on ParkPilot server.`,
  });
});

// Centralized Error Handling Middleware
app.use(globalErrorHandler);

export default app;

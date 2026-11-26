import cors from 'cors';
import express from 'express';
import { rateLimit } from 'express-rate-limit';
import helmet from 'helmet';
import { pinoHttp } from 'pino-http';
import { env } from './config/env.ts';
import { logger } from './config/logger.ts';
import authRoutes from './modules/auth/auth.routes.ts';
import itemRoutes from './modules/items/item.routes.ts';
import claimRoutes from './modules/claims/claim.routes.ts';
import messageRoutes from './modules/messages/message.routes.ts';
import adminRoutes from './modules/admin/admin.routes.ts';
import { AppError } from './shared/errors.ts';
import { errorHandler } from './shared/error-handler.ts';

export function createApp() {
  const app = express();
  app.set('trust proxy', 1);

  app.use(helmet());
  app.use(
    cors({
      origin:
        env.CORS_ORIGIN === '*'
          ? '*'
          : env.CORS_ORIGIN.split(',').map((origin) => origin.trim()),
    }),
  );
  app.use(pinoHttp({ logger, autoLogging: env.NODE_ENV !== 'test' }));
  const skipInTests = () => env.NODE_ENV === 'test';
  app.use(
    rateLimit({
      windowMs: 15 * 60 * 1000,
      max: 100,
      standardHeaders: true,
      legacyHeaders: false,
      skip: skipInTests,
    }),
  );
  app.use(
    '/api/v1/auth',
    rateLimit({
      windowMs: 15 * 60 * 1000,
      max: 30,
      standardHeaders: true,
      legacyHeaders: false,
      skip: skipInTests,
    }),
  );
  app.use(express.json({ limit: '1.2mb' }));

  app.get('/api/v1/health', (_req, res) => {
    res.status(200).json({ status: 'OK', timestamp: new Date().toISOString() });
  });
  app.use('/api/v1/auth', authRoutes);
  app.use('/api/v1/items', itemRoutes);
  app.use('/api/v1/claims', claimRoutes);
  app.use('/api/v1/messages', messageRoutes);
  app.use('/api/v1/admin', adminRoutes);

  app.use((_req, _res, next) => {
    next(new AppError('Route introuvable.', 404, 'NOT_FOUND'));
  });
  app.use(errorHandler);
  return app;
}

export const app = createApp();

import type { ErrorRequestHandler } from 'express';
import { logger } from '../config/logger.ts';
import { AppError } from './errors.ts';

export const errorHandler: ErrorRequestHandler = (error, _req, res, _next) => {
  if (error instanceof AppError) {
    res.status(error.statusCode).json({
      error: error.code,
      message: error.message,
      ...(error.details !== undefined && { details: error.details }),
    });
    return;
  }

  logger.error({ error }, 'Unhandled API error');
  res.status(500).json({
    error: 'INTERNAL_SERVER_ERROR',
    message: 'Une erreur serveur est survenue.',
  });
};

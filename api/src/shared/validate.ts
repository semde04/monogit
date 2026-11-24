import type { RequestHandler } from 'express';
import type { ZodType } from 'zod';
import { AppError } from './errors.ts';

export function validateBody(schema: ZodType): RequestHandler {
  return (req, _res, next) => {
    const result = schema.safeParse(req.body);
    if (!result.success) {
      next(
        new AppError(
          'Les données envoyées sont invalides.',
          400,
          'VALIDATION_ERROR',
          result.error.flatten(),
        ),
      );
      return;
    }
    req.body = result.data;
    next();
  };
}

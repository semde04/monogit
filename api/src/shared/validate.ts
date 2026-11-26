import type { RequestHandler } from 'express';
import type { ZodType } from 'zod';
import { AppError } from './errors.ts';

function validate(source: 'body' | 'params', schema: ZodType): RequestHandler {
  return (req, _res, next) => {
    const result = schema.safeParse(req[source]);
    if (!result.success) {
      next(
        new AppError(
          'Les données envoyées sont invalides.',
          422,
          'VALIDATION_ERROR',
          result.error.flatten(),
        ),
      );
      return;
    }
    req[source] = result.data;
    next();
  };
}

export function validateBody(schema: ZodType): RequestHandler {
  return validate('body', schema);
}

export function validateParams(schema: ZodType): RequestHandler {
  return validate('params', schema);
}

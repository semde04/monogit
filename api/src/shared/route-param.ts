import type { Request } from 'express';
import { AppError } from './errors.ts';

export function routeParam(req: Request, name: string): string {
  const value = req.params[name];
  if (typeof value !== 'string' || value.length === 0) {
    throw new AppError('Paramètre de route invalide.', 400, 'INVALID_ROUTE_PARAMETER');
  }
  return value;
}

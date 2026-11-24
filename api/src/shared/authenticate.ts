import type { RequestHandler } from 'express';
import { jwtVerify } from 'jose';
import { env } from '../config/env.ts';
import { AppError } from './errors.ts';

export const authenticate: RequestHandler = async (req, _res, next) => {
  const [scheme, token] = req.header('authorization')?.split(' ') ?? [];

  if (scheme !== 'Bearer' || !token) {
    next(new AppError('Authentification requise.', 401, 'UNAUTHORIZED'));
    return;
  }

  try {
    const { payload } = await jwtVerify(
      token,
      new TextEncoder().encode(env.JWT_ACCESS_SECRET),
    );
    if (typeof payload.sub !== 'string') {
      throw new Error('Invalid token subject');
    }
    req.auth = { userId: payload.sub };
    next();
  } catch {
    next(new AppError('Jeton invalide ou expiré.', 401, 'INVALID_TOKEN'));
  }
};

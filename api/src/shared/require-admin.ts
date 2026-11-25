import type { RequestHandler } from 'express';
import { UserModel } from '../modules/auth/user.model.ts';
import { AppError } from './errors.ts';

export const requireAdmin: RequestHandler = async (req, _res, next) => {
  if (!req.auth) {
    next(new AppError('Authentification requise.', 401, 'UNAUTHORIZED'));
    return;
  }

  const user = await UserModel.findById(req.auth.userId).select('role');
  if (!user || user.role !== 'admin') {
    next(new AppError('Accès réservé à l’administration.', 403, 'FORBIDDEN'));
    return;
  }

  next();
};

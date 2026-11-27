import type { RequestHandler } from 'express';
import { UserModel } from '../modules/auth/user.model.ts';
import { AppError } from './errors.ts';

export const requireActiveUser: RequestHandler = async (req, _res, next) => {
  if (!req.auth) {
    next(new AppError('Authentification requise.', 401, 'UNAUTHORIZED'));
    return;
  }

  const user = await UserModel.findById(req.auth.userId).select('isSuspended');
  if (!user) {
    next(new AppError('Utilisateur introuvable.', 404, 'USER_NOT_FOUND'));
    return;
  }
  if (user.isSuspended) {
    next(new AppError('Compte suspendu.', 403, 'ACCOUNT_SUSPENDED'));
    return;
  }

  next();
};

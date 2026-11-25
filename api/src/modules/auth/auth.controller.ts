import type { RequestHandler } from 'express';
import { AppError } from '../../shared/errors.ts';
import {
  addDeviceInstallation,
  loginUser,
  registerUser,
  getCurrentUser,
  removeDeviceInstallation,
} from './auth.service.ts';
import { revokeRefreshToken, rotateRefreshToken } from './token.service.ts';

export const register: RequestHandler = async (req, res) => {
  res.status(201).json({ data: await registerUser(req.body) });
};

export const login: RequestHandler = async (req, res) => {
  res.json({ data: await loginUser(req.body) });
};

export const refresh: RequestHandler = async (req, res) => {
  res.json({ data: await rotateRefreshToken(req.body.refreshToken) });
};

export const logout: RequestHandler = async (req, res) => {
  await revokeRefreshToken(req.body.refreshToken);
  res.status(204).end();
};

export const me: RequestHandler = async (req, res) => {
  if (!req.auth) throw new AppError('Authentification requise.', 401, 'UNAUTHORIZED');
  res.json({ data: await getCurrentUser(req.auth.userId) });
};

export const registerDeviceInstallation: RequestHandler = async (req, res) => {
  if (!req.auth) throw new AppError('Authentification requise.', 401, 'UNAUTHORIZED');
  await addDeviceInstallation(req.auth.userId, req.body.installationId);
  res.status(204).end();
};

export const unregisterDeviceInstallation: RequestHandler = async (req, res) => {
  if (!req.auth) throw new AppError('Authentification requise.', 401, 'UNAUTHORIZED');
  await removeDeviceInstallation(req.auth.userId, req.body.installationId);
  res.status(204).end();
};

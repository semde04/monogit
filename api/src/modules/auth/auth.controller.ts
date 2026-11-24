import type { RequestHandler } from 'express';
import { loginUser, registerUser } from './auth.service.ts';
import { revokeRefreshToken, rotateRefreshToken } from './token.service.ts';

export const register: RequestHandler = async (req, res) => {
  res.status(201).json(await registerUser(req.body));
};

export const login: RequestHandler = async (req, res) => {
  res.json(await loginUser(req.body));
};

export const refresh: RequestHandler = async (req, res) => {
  res.json(await rotateRefreshToken(req.body.refreshToken));
};

export const logout: RequestHandler = async (req, res) => {
  await revokeRefreshToken(req.body.refreshToken);
  res.status(204).end();
};

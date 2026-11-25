import type { RequestHandler } from 'express';
import { AppError } from '../../shared/errors.ts';
import { routeParam } from '../../shared/route-param.ts';
import { getAdminOverview, moderateItem } from './admin.service.ts';

function currentUserId(req: Parameters<RequestHandler>[0]): string {
  if (!req.auth) throw new AppError('Authentification requise.', 401, 'UNAUTHORIZED');
  return req.auth.userId;
}

export const getOverview: RequestHandler = async (_req, res) => {
  res.json({ data: await getAdminOverview() });
};

export const patchItemModeration: RequestHandler = async (req, res) => {
  const item = await moderateItem(
    routeParam(req, 'itemId'),
    currentUserId(req),
    req.body,
  );
  res.json({ data: item });
};

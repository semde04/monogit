import type { RequestHandler } from 'express';
import { AppError } from '../../shared/errors.ts';
import { paginationMeta, paginationSchema } from '../../shared/pagination.ts';
import { routeParam } from '../../shared/route-param.ts';
import { getAdminOverview, moderateItem } from './admin.service.ts';

function currentUserId(req: Parameters<RequestHandler>[0]): string {
  if (!req.auth) throw new AppError('Authentification requise.', 401, 'UNAUTHORIZED');
  return req.auth.userId;
}

export const getOverview: RequestHandler = async (req, res) => {
  const query = paginationSchema.safeParse(req.query);
  if (!query.success) {
    throw new AppError('Paramètres de pagination invalides.', 422, 'VALIDATION_ERROR', query.error.flatten());
  }
  const data = await getAdminOverview(query.data);
  res.json({
    data,
    meta: {
      users: paginationMeta(data.totals.users, query.data),
      items: paginationMeta(data.totals.items, query.data),
    },
  });
};

export const patchItemModeration: RequestHandler = async (req, res) => {
  const item = await moderateItem(
    routeParam(req, 'itemId'),
    currentUserId(req),
    req.body,
  );
  res.json({ data: item });
};

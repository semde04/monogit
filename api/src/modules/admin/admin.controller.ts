import type { RequestHandler } from 'express';
import { AppError } from '../../shared/errors.ts';
import { paginationMeta, paginationSchema } from '../../shared/pagination.ts';
import { routeParam } from '../../shared/route-param.ts';
import { getActivity, getAdminOverview, listAdminItems, moderateItem, suspendUser } from './admin.service.ts';
import { activityQuerySchema, adminItemQuerySchema } from './admin.schemas.ts';

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

export const getAdminActivity: RequestHandler = async (req, res) => {
  const query = activityQuerySchema.safeParse(req.query);
  if (!query.success) {
    throw new AppError('Paramètres de requête invalides.', 422, 'VALIDATION_ERROR', query.error.flatten());
  }
  const { activities, total } = await getActivity(query.data);
  res.json({
    data: activities,
    meta: paginationMeta(total, query.data),
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

export const getAdminItems: RequestHandler = async (req, res) => {
  const query = adminItemQuerySchema.safeParse(req.query);
  if (!query.success) {
    throw new AppError('Filtres de recherche invalides.', 422, 'VALIDATION_ERROR', query.error.flatten());
  }
  const { items, total } = await listAdminItems(query.data);
  res.json({ data: items, meta: paginationMeta(total, query.data) });
};

export const patchUserSuspension: RequestHandler = async (req, res) => {
  const user = await suspendUser(
    routeParam(req, 'userId'),
    currentUserId(req),
    req.body,
  );
  res.json({ data: user });
};

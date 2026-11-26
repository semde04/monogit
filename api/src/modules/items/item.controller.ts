import type { RequestHandler } from 'express';
import { AppError } from '../../shared/errors.ts';
import { paginationMeta } from '../../shared/pagination.ts';
import { routeParam } from '../../shared/route-param.ts';
import { itemQuerySchema } from './item.schemas.ts';
import {
  createItem,
  closeItem,
  deleteItem,
  getItem,
  listItems,
  updateItem,
} from './item.service.ts';

function currentUserId(req: Parameters<RequestHandler>[0]): string {
  if (!req.auth) throw new AppError('Authentification requise.', 401, 'UNAUTHORIZED');
  return req.auth.userId;
}

export const getItems: RequestHandler = async (req, res) => {
  const filters = itemQuerySchema.safeParse(req.query);
  if (!filters.success) {
    throw new AppError(
      'Filtres de recherche invalides.',
      422,
      'VALIDATION_ERROR',
      filters.error.flatten(),
    );
  }
  const { items, total } = await listItems(filters.data);
  res.json({ data: items, meta: paginationMeta(total, filters.data) });
};

export const getItemById: RequestHandler = async (req, res) => {
  res.json({ data: { item: await getItem(routeParam(req, 'id')) } });
};

export const postItem: RequestHandler = async (req, res) => {
  const item = await createItem(req.body, currentUserId(req));
  res.status(201).json({ data: item });
};

export const patchItem: RequestHandler = async (req, res) => {
  const item = await updateItem(routeParam(req, 'id'), currentUserId(req), req.body);
  res.json({ data: item });
};

export const removeItem: RequestHandler = async (req, res) => {
  await deleteItem(routeParam(req, 'id'), currentUserId(req));
  res.status(204).end();
};

export const closeItemById: RequestHandler = async (req, res) => {
  const item = await closeItem(routeParam(req, 'id'), currentUserId(req));
  res.json({ data: item });
};

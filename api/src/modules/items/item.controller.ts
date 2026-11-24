import type { RequestHandler } from 'express';
import { AppError } from '../../shared/errors.ts';
import { routeParam } from '../../shared/route-param.ts';
import {
  createItem,
  deleteItem,
  getItem,
  listItems,
  updateItem,
} from './item.service.ts';

function currentUserId(req: Parameters<RequestHandler>[0]): string {
  if (!req.auth) throw new AppError('Authentification requise.', 401, 'UNAUTHORIZED');
  return req.auth.userId;
}

export const getItems: RequestHandler = async (_req, res) => {
  res.json({ items: await listItems() });
};

export const getItemById: RequestHandler = async (req, res) => {
  res.json({ item: await getItem(routeParam(req, 'id')) });
};

export const postItem: RequestHandler = async (req, res) => {
  const item = await createItem(req.body, currentUserId(req));
  res.status(201).json({ item });
};

export const patchItem: RequestHandler = async (req, res) => {
  const item = await updateItem(routeParam(req, 'id'), currentUserId(req), req.body);
  res.json({ item });
};

export const removeItem: RequestHandler = async (req, res) => {
  await deleteItem(routeParam(req, 'id'), currentUserId(req));
  res.status(204).end();
};

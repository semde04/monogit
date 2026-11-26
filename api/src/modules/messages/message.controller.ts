import type { RequestHandler } from 'express';
import { AppError } from '../../shared/errors.ts';
import { paginationMeta } from '../../shared/pagination.ts';
import { routeParam } from '../../shared/route-param.ts';
import { messageQuerySchema } from './message.schemas.ts';
import { createMessage, listMessages } from './message.service.ts';

function currentUserId(req: Parameters<RequestHandler>[0]): string {
  if (!req.auth) throw new AppError('Authentification requise.', 401, 'UNAUTHORIZED');
  return req.auth.userId;
}

export const getMessages: RequestHandler = async (req, res) => {
  const query = messageQuerySchema.safeParse(req.query);
  if (!query.success) {
    throw new AppError('Paramètres de pagination invalides.', 422, 'VALIDATION_ERROR', query.error.flatten());
  }
  const { messages, total } = await listMessages(
    routeParam(req, 'claimId'),
    currentUserId(req),
    query.data,
  );
  res.json({ data: { messages }, meta: paginationMeta(total, query.data) });
};

export const postMessage: RequestHandler = async (req, res) => {
  const message = await createMessage(
    req.body.claimId,
    currentUserId(req),
    req.body,
  );
  res.status(201).json({ data: message });
};

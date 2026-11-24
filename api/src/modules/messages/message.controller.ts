import type { RequestHandler } from 'express';
import { AppError } from '../../shared/errors.ts';
import { routeParam } from '../../shared/route-param.ts';
import { createMessage, listMessages } from './message.service.ts';

function currentUserId(req: Parameters<RequestHandler>[0]): string {
  if (!req.auth) throw new AppError('Authentification requise.', 401, 'UNAUTHORIZED');
  return req.auth.userId;
}

export const getMessages: RequestHandler = async (req, res) => {
  res.json({ data: { messages: await listMessages(routeParam(req, 'claimId'), currentUserId(req)) } });
};

export const postMessage: RequestHandler = async (req, res) => {
  const message = await createMessage(
    req.body.claimId,
    currentUserId(req),
    req.body,
  );
  res.status(201).json({ data: message });
};

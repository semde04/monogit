import type { RequestHandler } from 'express';
import { AppError } from '../../shared/errors.ts';
import { paginationMeta } from '../../shared/pagination.ts';
import { routeParam } from '../../shared/route-param.ts';
import { claimQuerySchema } from './claim.schemas.ts';
import { confirmClaimReturn, createClaim, listClaimsForUser, updateClaimStatus } from './claim.service.ts';

function currentUserId(req: Parameters<RequestHandler>[0]): string {
  if (!req.auth) throw new AppError('Authentification requise.', 401, 'UNAUTHORIZED');
  return req.auth.userId;
}

export const getClaims: RequestHandler = async (req, res) => {
  const query = claimQuerySchema.safeParse(req.query);
  if (!query.success) {
    throw new AppError('Paramètres de pagination invalides.', 422, 'VALIDATION_ERROR', query.error.flatten());
  }
  const { claims, total } = await listClaimsForUser(currentUserId(req), query.data);
  res.json({ data: { claims }, meta: paginationMeta(total, query.data) });
};

export const postClaim: RequestHandler = async (req, res) => {
  const claim = await createClaim(currentUserId(req), req.body);
  res.status(201).json({ data: claim });
};

export const patchClaimStatus: RequestHandler = async (req, res) => {
  const claim = await updateClaimStatus(routeParam(req, 'claimId'), currentUserId(req), req.body);
  res.json({ data: claim });
};

export const postConfirmClaimReturn: RequestHandler = async (req, res) => {
  const claim = await confirmClaimReturn(routeParam(req, 'claimId'), currentUserId(req));
  res.json({ data: claim });
};

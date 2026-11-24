import type { RequestHandler } from 'express';
import { AppError } from '../../shared/errors.ts';
import { routeParam } from '../../shared/route-param.ts';
import { createClaim, listClaimsForUser, updateClaimStatus } from './claim.service.ts';

function currentUserId(req: Parameters<RequestHandler>[0]): string {
  if (!req.auth) throw new AppError('Authentification requise.', 401, 'UNAUTHORIZED');
  return req.auth.userId;
}

export const getClaims: RequestHandler = async (req, res) => {
  res.json({ data: { claims: await listClaimsForUser(currentUserId(req)) } });
};

export const postClaim: RequestHandler = async (req, res) => {
  const claim = await createClaim(currentUserId(req), req.body);
  res.status(201).json({ data: claim });
};

export const patchClaimStatus: RequestHandler = async (req, res) => {
  const claim = await updateClaimStatus(routeParam(req, 'claimId'), currentUserId(req), req.body);
  res.json({ data: claim });
};

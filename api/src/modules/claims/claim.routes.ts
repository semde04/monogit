import { Router } from 'express';
import { authenticate } from '../../shared/authenticate.ts';
import { requireActiveUser } from '../../shared/require-active-user.ts';
import { paramsWithClaimId } from '../../shared/params.ts';
import { validateBody, validateParams } from '../../shared/validate.ts';
import { postClaim, getClaims, patchClaimStatus, postConfirmClaimReturn } from './claim.controller.ts';
import { createClaimSchema, updateClaimStatusSchema } from './claim.schemas.ts';

const router = Router();

router.use(authenticate, requireActiveUser);
router.get('/', getClaims);
router.post('/', validateBody(createClaimSchema), postClaim);
router.patch(
  '/:claimId/status',
  validateParams(paramsWithClaimId),
  validateBody(updateClaimStatusSchema),
  patchClaimStatus,
);
router.post(
  '/:claimId/confirm-return',
  validateParams(paramsWithClaimId),
  postConfirmClaimReturn,
);

export default router;

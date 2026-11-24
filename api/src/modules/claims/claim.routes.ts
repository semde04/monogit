import { Router } from 'express';
import { authenticate } from '../../shared/authenticate.ts';
import { validateBody } from '../../shared/validate.ts';
import { postClaim, getClaims, patchClaimStatus } from './claim.controller.ts';
import { createClaimSchema, updateClaimStatusSchema } from './claim.schemas.ts';

const router = Router();

router.use(authenticate);
router.get('/', getClaims);
router.post('/items/:itemId', validateBody(createClaimSchema), postClaim);
router.patch('/:claimId/status', validateBody(updateClaimStatusSchema), patchClaimStatus);

export default router;

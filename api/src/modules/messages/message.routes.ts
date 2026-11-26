import { Router } from 'express';
import { authenticate } from '../../shared/authenticate.ts';
import { paramsWithClaimId } from '../../shared/params.ts';
import { validateBody, validateParams } from '../../shared/validate.ts';
import { getMessages, postMessage } from './message.controller.ts';
import { createMessageSchema } from './message.schemas.ts';

const router = Router();

router.use(authenticate);
router.get(
  '/claims/:claimId',
  validateParams(paramsWithClaimId),
  getMessages,
);
router.post('/', validateBody(createMessageSchema), postMessage);

export default router;

import { Router } from 'express';
import { authenticate } from '../../shared/authenticate.ts';
import { requireAdmin } from '../../shared/require-admin.ts';
import { paramsWithItemId } from '../../shared/params.ts';
import { validateBody, validateParams } from '../../shared/validate.ts';
import { getOverview, patchItemModeration } from './admin.controller.ts';
import { moderateItemSchema } from './admin.schemas.ts';

const router = Router();

router.use(authenticate, requireAdmin);
router.get('/overview', getOverview);
router.patch(
  '/items/:itemId/moderation',
  validateParams(paramsWithItemId),
  validateBody(moderateItemSchema),
  patchItemModeration,
);

export default router;

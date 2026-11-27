import { Router } from 'express';
import { authenticate } from '../../shared/authenticate.ts';
import { requireAdmin } from '../../shared/require-admin.ts';
import { paramsWithItemId, paramsWithUserId } from '../../shared/params.ts';
import { validateBody, validateParams } from '../../shared/validate.ts';
import {
  getAdminActivity,
  getAdminItems,
  getOverview,
  patchItemModeration,
  patchUserSuspension,
} from './admin.controller.ts';
import { moderateItemSchema, suspensionSchema } from './admin.schemas.ts';

const router = Router();

router.use(authenticate, requireAdmin);
router.get('/overview', getOverview);
router.get('/activity', getAdminActivity);
router.get('/items', getAdminItems);
router.patch(
  '/users/:userId/suspension',
  validateParams(paramsWithUserId),
  validateBody(suspensionSchema),
  patchUserSuspension,
);
router.patch(
  '/items/:itemId/moderation',
  validateParams(paramsWithItemId),
  validateBody(moderateItemSchema),
  patchItemModeration,
);

export default router;

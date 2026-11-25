import { Router } from 'express';
import { authenticate } from '../../shared/authenticate.ts';
import { requireAdmin } from '../../shared/require-admin.ts';
import { validateBody } from '../../shared/validate.ts';
import { getOverview, patchItemModeration } from './admin.controller.ts';
import { moderateItemSchema } from './admin.schemas.ts';

const router = Router();

router.use(authenticate, requireAdmin);
router.get('/overview', getOverview);
router.patch('/items/:itemId/moderation', validateBody(moderateItemSchema), patchItemModeration);

export default router;

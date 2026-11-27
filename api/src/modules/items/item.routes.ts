import { Router } from 'express';
import { authenticate } from '../../shared/authenticate.ts';
import { requireActiveUser } from '../../shared/require-active-user.ts';
import { paramsWithId } from '../../shared/params.ts';
import { validateBody, validateParams } from '../../shared/validate.ts';
import {
  getItemById,
  getItems,
  closeItemById,
  patchItem,
  postItem,
  removeItem,
} from './item.controller.ts';
import { createItemSchema, updateItemSchema } from './item.schemas.ts';

const router = Router();

router.get('/', getItems);
router.get('/:id', validateParams(paramsWithId), getItemById);
router.post('/', authenticate, requireActiveUser, validateBody(createItemSchema), postItem);
router.patch(
  '/:id/close',
  authenticate,
  requireActiveUser,
  validateParams(paramsWithId),
  closeItemById,
);
router.patch(
  '/:id',
  authenticate,
  requireActiveUser,
  validateParams(paramsWithId),
  validateBody(updateItemSchema),
  patchItem,
);
router.delete(
  '/:id',
  authenticate,
  requireActiveUser,
  validateParams(paramsWithId),
  removeItem,
);

export default router;

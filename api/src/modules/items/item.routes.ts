import { Router } from 'express';
import { authenticate } from '../../shared/authenticate.ts';
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
router.post('/', authenticate, validateBody(createItemSchema), postItem);
router.patch(
  '/:id/close',
  authenticate,
  validateParams(paramsWithId),
  closeItemById,
);
router.patch(
  '/:id',
  authenticate,
  validateParams(paramsWithId),
  validateBody(updateItemSchema),
  patchItem,
);
router.delete(
  '/:id',
  authenticate,
  validateParams(paramsWithId),
  removeItem,
);

export default router;

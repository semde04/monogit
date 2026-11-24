import { Router } from 'express';
import { authenticate } from '../../shared/authenticate.ts';
import { validateBody } from '../../shared/validate.ts';
import {
  getItemById,
  getItems,
  patchItem,
  postItem,
  removeItem,
} from './item.controller.ts';
import { createItemSchema, updateItemSchema } from './item.schemas.ts';

const router = Router();

router.get('/', getItems);
router.get('/:id', getItemById);
router.post('/', authenticate, validateBody(createItemSchema), postItem);
router.patch('/:id', authenticate, validateBody(updateItemSchema), patchItem);
router.delete('/:id', authenticate, removeItem);

export default router;

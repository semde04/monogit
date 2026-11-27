import { z } from 'zod';
import { paginationSchema } from '../../shared/pagination.ts';
import { itemQuerySchema } from '../items/item.schemas.ts';
import { activityTypes } from './activity.model.ts';

const queryBoolean = z.enum(['true', 'false']).transform((value) => value === 'true');

export const moderateItemSchema = z.object({
  isRemoved: z.boolean(),
  reason: z.string().trim().min(3).max(300).optional(),
});

export const adminItemQuerySchema = itemQuerySchema.extend({
  isClosed: queryBoolean.optional(),
  isRemoved: queryBoolean.optional(),
  isReturned: queryBoolean.optional(),
});

export const suspensionSchema = z.object({
  isSuspended: z.boolean(),
  reason: z.string().trim().max(300).optional(),
}).refine(
  (data) => !data.isSuspended || (data.reason?.length ?? 0) >= 3,
  {
    message: 'Un motif d’au moins 3 caractères est obligatoire pour suspendre un compte.',
    path: ['reason'],
  },
);

export const activityQuerySchema = paginationSchema.extend({
  type: z.enum(activityTypes).optional(),
});

export type ModerateItemInput = z.infer<typeof moderateItemSchema>;
export type AdminItemQueryInput = z.infer<typeof adminItemQuerySchema>;
export type SuspensionInput = z.infer<typeof suspensionSchema>;
export type ActivityQueryInput = z.infer<typeof activityQuerySchema>;

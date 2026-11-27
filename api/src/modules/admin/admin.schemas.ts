import { z } from 'zod';
import { paginationSchema } from '../../shared/pagination.ts';
import { activityTypes } from './activity.model.ts';

export const moderateItemSchema = z.object({
  isRemoved: z.boolean(),
  reason: z.string().trim().min(3).max(300).optional(),
});

export const activityQuerySchema = paginationSchema.extend({
  type: z.enum(activityTypes).optional(),
});

export type ModerateItemInput = z.infer<typeof moderateItemSchema>;
export type ActivityQueryInput = z.infer<typeof activityQuerySchema>;

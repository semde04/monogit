import { z } from 'zod';

export const moderateItemSchema = z.object({
  isRemoved: z.boolean(),
  reason: z.string().trim().min(3).max(300).optional(),
});

export type ModerateItemInput = z.infer<typeof moderateItemSchema>;

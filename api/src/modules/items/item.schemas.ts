import { z } from 'zod';

export const createItemSchema = z.object({
  title: z.string().trim().min(1).max(160),
  description: z.string().trim().min(1).max(5000),
  category: z.string().trim().min(1).max(100),
  location: z.string().trim().min(1).max(200),
  status: z.enum(['lost', 'found']),
});

export const updateItemSchema = createItemSchema.partial().refine(
  (data) => Object.keys(data).length > 0,
  'Au moins un champ doit être fourni.',
);

export type CreateItemInput = z.infer<typeof createItemSchema>;
export type UpdateItemInput = z.infer<typeof updateItemSchema>;

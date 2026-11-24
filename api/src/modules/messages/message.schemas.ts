import { z } from 'zod';

export const createMessageSchema = z.object({
  body: z.string().trim().min(1).max(5000),
});

export type CreateMessageInput = z.infer<typeof createMessageSchema>;

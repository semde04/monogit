import { z } from 'zod';

export const createMessageSchema = z.object({
  claimId: z.string().regex(/^[a-f\d]{24}$/i),
  text: z.string().trim().min(1).max(5000),
});

export type CreateMessageInput = z.infer<typeof createMessageSchema>;

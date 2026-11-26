import { z } from 'zod';
import { paginationSchema } from '../../shared/pagination.ts';

export const createMessageSchema = z.object({
  claimId: z.string().regex(/^[a-f\d]{24}$/i),
  text: z.string().trim().min(1).max(5000),
});

export const messageQuerySchema = paginationSchema;

export type CreateMessageInput = z.infer<typeof createMessageSchema>;

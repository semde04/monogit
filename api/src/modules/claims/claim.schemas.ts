import { z } from 'zod';

export const createClaimSchema = z.object({
  itemId: z.string().regex(/^[a-f\d]{24}$/i),
  proofAnswer: z.string().trim().min(1).max(2000),
});

export const updateClaimStatusSchema = z.object({
  status: z.enum(['accepted', 'rejected']),
});

export type CreateClaimInput = z.infer<typeof createClaimSchema>;
export type UpdateClaimStatusInput = z.infer<typeof updateClaimStatusSchema>;

import { z } from 'zod';

export const paginationSchema = z.object({
  page: z.coerce.number().int().min(1).max(10_000).default(1),
  limit: z.coerce.number().int().min(1).max(50).default(20),
});

export type PaginationInput = z.infer<typeof paginationSchema>;

export function paginationMeta(total: number, pagination: PaginationInput) {
  return {
    page: pagination.page,
    limit: pagination.limit,
    total,
    pages: Math.max(1, Math.ceil(total / pagination.limit)),
  };
}

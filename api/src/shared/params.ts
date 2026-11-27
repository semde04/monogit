import { z } from 'zod';

export const objectIdSchema = z
  .string()
  .regex(/^[a-f\d]{24}$/i, 'Identifiant invalide.');

export const paramsWithId = z.object({ id: objectIdSchema });
export const paramsWithClaimId = z.object({ claimId: objectIdSchema });
export const paramsWithItemId = z.object({ itemId: objectIdSchema });
export const paramsWithUserId = z.object({ userId: objectIdSchema });

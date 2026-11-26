import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().positive().default(5000),
  MONGO_URI: z.url().refine(
    (uri) => uri.startsWith('mongodb://') || uri.startsWith('mongodb+srv://'),
    'MONGO_URI doit être une URI MongoDB.',
  ),
  JWT_ACCESS_SECRET: z.string().min(32),
  JWT_ISSUER: z.string().min(1).default('lostfound-api'),
  JWT_AUDIENCE: z.string().min(1).default('lostfound-app'),
  ACCESS_TOKEN_TTL: z.string().regex(/^\d+[smhdw]$/).default('15m'),
  REFRESH_TOKEN_TTL_DAYS: z.coerce.number().int().positive().max(90).default(30),
  CORS_ORIGIN: z.string().default('*'),
  FIREBASE_PROJECT_ID: z.string().optional(),
}).superRefine((data, ctx) => {
  if (data.NODE_ENV === 'production' && data.CORS_ORIGIN === '*') {
    ctx.addIssue({
      code: 'custom',
      path: ['CORS_ORIGIN'],
      message: 'CORS_ORIGIN doit être une liste explicite en production.',
    });
  }
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  throw new Error(
    `Variables d'environnement invalides : ${JSON.stringify(parsed.error.flatten().fieldErrors)}`,
  );
}

export const env = parsed.data;

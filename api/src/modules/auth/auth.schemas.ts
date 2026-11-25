import { z } from 'zod';

export const registerSchema = z.object({
  name: z.string().trim().min(1).max(100),
  email: z.string().trim().email().max(254),
  matricule: z.string().trim().min(3).max(32).transform((value) => value.toUpperCase()),
  password: z.string().min(12).max(128),
});

export const loginSchema = z.object({
  email: z.string().trim().email().max(254),
  password: z.string().min(1).max(128),
});

export const refreshSchema = z.object({
  refreshToken: z.string().min(1),
});

export const deviceInstallationSchema = z.object({
  installationId: z.string().trim().min(20).max(512),
});

export type RegisterInput = z.infer<typeof registerSchema>;
export type LoginInput = z.infer<typeof loginSchema>;

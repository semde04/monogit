import { z } from 'zod';
import { env } from '../config/env.ts';
import { hashPassword } from '../shared/password.ts';
import { UserModel } from '../modules/auth/user.model.ts';
import mongoose from 'mongoose';

const adminSchema = z.object({
  ADMIN_NAME: z.string().trim().min(1).max(100),
  ADMIN_EMAIL: z.string().trim().email().max(254),
  ADMIN_PASSWORD: z.string().min(12).max(128),
});

async function createAdmin() {
  const config = adminSchema.parse(process.env);
  await mongoose.connect(env.MONGO_URI);

  const email = config.ADMIN_EMAIL.toLowerCase();
  if (await UserModel.exists({ email })) {
    throw new Error('Un compte existe déjà avec cette adresse. Aucune modification effectuée.');
  }

  await UserModel.create({
    name: config.ADMIN_NAME,
    email,
    passwordHash: await hashPassword(config.ADMIN_PASSWORD),
    role: 'admin',
  });
  console.log(`Compte administrateur créé pour ${email}.`);
}

createAdmin()
  .catch((error: unknown) => {
    console.error('Création du compte administrateur impossible.', error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await mongoose.disconnect();
  });

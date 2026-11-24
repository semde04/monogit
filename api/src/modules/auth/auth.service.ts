import argon2 from 'argon2';
import { AppError } from '../../shared/errors.ts';
import { UserModel } from './user.model.ts';
import { issueTokenPair } from './token.service.ts';
import type { LoginInput, RegisterInput } from './auth.schemas.ts';

export async function registerUser(input: RegisterInput) {
  const email = input.email.toLowerCase();
  if (await UserModel.exists({ email })) {
    throw new AppError('Cette adresse courriel est déjà utilisée.', 409, 'EMAIL_TAKEN');
  }

  const passwordHash = await argon2.hash(input.password);
  let user;
  try {
    user = await UserModel.create({
      name: input.name,
      email,
      passwordHash,
    });
  } catch (error) {
    if (
      typeof error === 'object' &&
      error !== null &&
      'code' in error &&
      error.code === 11000
    ) {
      throw new AppError('Cette adresse courriel est déjà utilisée.', 409, 'EMAIL_TAKEN');
    }
    throw error;
  }

  const tokens = await issueTokenPair(user.id);
  return {
    ...tokens,
    user: { id: user.id, name: user.name, email: user.email },
  };
}

export async function loginUser(input: LoginInput) {
  const user = await UserModel.findOne({ email: input.email.toLowerCase() }).select('+passwordHash');
  if (!user || !(await argon2.verify(user.passwordHash, input.password))) {
    throw new AppError('Identifiants invalides.', 401, 'INVALID_CREDENTIALS');
  }

  const tokens = await issueTokenPair(user.id);
  return {
    ...tokens,
    user: { id: user.id, name: user.name, email: user.email },
  };
}

export async function getCurrentUser(userId: string) {
  const user = await UserModel.findById(userId).select('_id name email role').lean();
  if (!user) throw new AppError('Utilisateur introuvable.', 404, 'USER_NOT_FOUND');
  return user;
}

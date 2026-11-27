import argon2 from 'argon2';
import { AppError } from '../../shared/errors.ts';
import { hashPassword } from '../../shared/password.ts';
import { UserModel } from './user.model.ts';
import { issueTokenPair } from './token.service.ts';
import { recordActivity } from '../admin/activity.service.ts';
import type { LoginInput, RegisterInput } from './auth.schemas.ts';

export async function registerUser(input: RegisterInput) {
  const email = input.email.toLowerCase();
  if (await UserModel.exists({ email })) {
    throw new AppError('Cette adresse courriel est déjà utilisée.', 409, 'EMAIL_TAKEN');
  }
  if (await UserModel.exists({ matricule: input.matricule })) {
    throw new AppError('Ce matricule est déjà associé à un compte.', 409, 'MATRICULE_TAKEN');
  }

  const passwordHash = await hashPassword(input.password);
  let user;
  try {
    user = await UserModel.create({
      name: input.name,
      email,
      matricule: input.matricule,
      passwordHash,
    });
  } catch (error) {
    if (
      typeof error === 'object' &&
      error !== null &&
      'code' in error &&
      error.code === 11000 && 'keyPattern' in error &&
      typeof error.keyPattern === 'object' && error.keyPattern !== null &&
      'matricule' in error.keyPattern
    ) {
      throw new AppError('Ce matricule est déjà associé à un compte.', 409, 'MATRICULE_TAKEN');
    }
    if (
      typeof error === 'object' && error !== null && 'code' in error && error.code === 11000
    ) {
      throw new AppError('Cette adresse courriel est déjà utilisée.', 409, 'EMAIL_TAKEN');
    }
    throw error;
  }

  const tokens = await issueTokenPair(user.id);
  await recordActivity({
    type: 'auth.register',
    actorId: user.id,
    summary: `Nouveau compte créé : ${user.name}`,
    targetType: 'user',
    targetId: user.id,
  });
  return {
    ...tokens,
    user: { id: user.id, name: user.name, email: user.email, matricule: user.matricule, role: user.role },
  };
}

export async function loginUser(input: LoginInput) {
  const user = await UserModel.findOne({ email: input.email.toLowerCase() }).select('+passwordHash');
  if (!user || !(await argon2.verify(user.passwordHash, input.password))) {
    throw new AppError('Identifiants invalides.', 401, 'INVALID_CREDENTIALS');
  }

  const tokens = await issueTokenPair(user.id);
  await recordActivity({
    type: 'auth.login',
    actorId: user.id,
    summary: `Connexion de ${user.name}`,
    targetType: 'user',
    targetId: user.id,
  });
  return {
    ...tokens,
    user: { id: user.id, name: user.name, email: user.email, matricule: user.matricule, role: user.role },
  };
}

export async function getCurrentUser(userId: string) {
  const user = await UserModel.findById(userId).select('_id name email matricule role').lean();
  if (!user) throw new AppError('Utilisateur introuvable.', 404, 'USER_NOT_FOUND');
  return user;
}

export async function addDeviceInstallation(userId: string, installationId: string) {
  await UserModel.updateOne(
    { _id: userId },
    [
      {
        $set: {
          firebaseInstallationIds: {
            $slice: [
              {
                $cond: [
                  { $in: [installationId, '$firebaseInstallationIds'] },
                  '$firebaseInstallationIds',
                  { $concatArrays: ['$firebaseInstallationIds', [installationId]] },
                ],
              },
              -10,
            ],
          },
        },
      },
    ],
  );
}

export async function removeDeviceInstallation(userId: string, installationId: string) {
  await UserModel.updateOne(
    { _id: userId },
    { $pull: { firebaseInstallationIds: installationId } },
  );
}

import { createHash, randomBytes } from 'node:crypto';
import { Types } from 'mongoose';
import { SignJWT } from 'jose';
import { env } from '../../config/env.ts';
import { AppError } from '../../shared/errors.ts';
import { RefreshTokenModel } from './refresh-token.model.ts';

function hashToken(token: string): string {
  return createHash('sha256').update(token).digest('hex');
}

export async function issueTokenPair(userId: string) {
  const accessToken = await new SignJWT({})
    .setProtectedHeader({ alg: 'HS256' })
    .setSubject(userId)
    .setIssuedAt()
    .setExpirationTime(env.ACCESS_TOKEN_TTL)
    .sign(new TextEncoder().encode(env.JWT_ACCESS_SECRET));

  const refreshToken = randomBytes(48).toString('base64url');
  const expiresAt = new Date(
    Date.now() + env.REFRESH_TOKEN_TTL_DAYS * 24 * 60 * 60 * 1000,
  );

  await RefreshTokenModel.create({
    userId: new Types.ObjectId(userId),
    tokenHash: hashToken(refreshToken),
    expiresAt,
  });

  return { accessToken, refreshToken };
}

export async function rotateRefreshToken(refreshToken: string) {
  const storedToken = await RefreshTokenModel.findOneAndDelete({
    tokenHash: hashToken(refreshToken),
    expiresAt: { $gt: new Date() },
  });

  if (!storedToken) {
    throw new AppError('Jeton de rafraîchissement invalide ou expiré.', 401, 'INVALID_REFRESH_TOKEN');
  }

  return issueTokenPair(storedToken.userId.toString());
}

export async function revokeRefreshToken(refreshToken: string): Promise<void> {
  await RefreshTokenModel.deleteOne({ tokenHash: hashToken(refreshToken) });
}

import mongoose from 'mongoose';
import request from 'supertest';
import { createApp } from '../src/app.ts';
import { env } from '../src/config/env.ts';

export const api = request(createApp());

function assertSafeTestDatabaseUri(): void {
  let uri: URL;
  try {
    uri = new URL(env.MONGO_URI);
  } catch {
    throw new Error('Sécurité : URI MongoDB de test invalide.');
  }

  const localHosts = new Set(['localhost', '127.0.0.1', '::1', '[::1]']);
  const databaseName = decodeURIComponent(uri.pathname.replace(/^\/+/, ''));
  if (!localHosts.has(uri.hostname.toLowerCase()) || !databaseName.endsWith('_test')) {
    throw new Error(
      'Sécurité : les tests exigent une base locale dont le nom se termine par _test.',
    );
  }
}

export async function connectTestDatabase() {
  assertSafeTestDatabaseUri();
  await mongoose.connect(env.MONGO_URI);
}

export async function resetDatabase() {
  assertSafeTestDatabaseUri();
  await mongoose.connection.dropDatabase();
  await Promise.all(
    Object.values(mongoose.models).map((model) => model.syncIndexes()),
  );
}

export async function closeTestDatabase() {
  assertSafeTestDatabaseUri();
  await mongoose.connection.dropDatabase();
  await mongoose.disconnect();
}

export async function registerUser(email = 'user1@univ.fr') {
  const response = await api
    .post('/api/v1/auth/register')
    .send({ name: 'Test User', email, password: 'Password123!' });
  return response.body.data as {
    user: { id: string; email: string };
    accessToken: string;
    refreshToken: string;
  };
}

export const bearer = (token: string) => ({ Authorization: `Bearer ${token}` });

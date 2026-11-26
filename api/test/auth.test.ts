import assert from 'node:assert/strict';
import { after, before, beforeEach, describe, it } from 'node:test';
import {
  api,
  bearer,
  closeTestDatabase,
  connectTestDatabase,
  registerUser,
  resetDatabase,
} from './helpers.ts';

describe('Auth API', () => {
  before(connectTestDatabase);
  beforeEach(resetDatabase);
  after(closeTestDatabase);

  it('connecte un utilisateur et retourne son profil authentifié', async () => {
    await registerUser('login@univ.fr');

    const login = await api
      .post('/api/v1/auth/login')
      .send({ email: 'login@univ.fr', password: 'Password123!' });

    assert.equal(login.status, 200);
    assert.equal(typeof login.body.data.accessToken, 'string');

    const profile = await api
      .get('/api/v1/auth/me')
      .set(bearer(login.body.data.accessToken));

    assert.equal(profile.status, 200);
    assert.equal(profile.body.data.email, 'login@univ.fr');
  });

  it('fait tourner le jeton de rafraîchissement et invalide l’ancien', async () => {
    const tokens = await registerUser('refresh@univ.fr');

    const refreshed = await api
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: tokens.refreshToken });

    assert.equal(refreshed.status, 200);
    assert.notEqual(refreshed.body.data.refreshToken, tokens.refreshToken);

    const reused = await api
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: tokens.refreshToken });

    assert.equal(reused.status, 401);
    assert.equal(reused.body.error, 'REFRESH_TOKEN_REUSED');

    const rotatedNowInvalid = await api
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: refreshed.body.data.refreshToken });
    assert.equal(rotatedNowInvalid.status, 401);
  });

  it('normalise le matricule, garde le rôle utilisateur et refuse les doublons', async () => {
    const first = await api.post('/api/v1/auth/register').send({
      name: 'Étudiant',
      email: 'student@univ.fr',
      matricule: '  ab-123  ',
      password: 'Password123!',
      role: 'admin',
    });

    assert.equal(first.status, 201);
    assert.equal(first.body.data.user.matricule, 'AB-123');
    assert.equal(first.body.data.user.role, 'user');

    const duplicate = await api.post('/api/v1/auth/register').send({
      name: 'Autre étudiant',
      email: 'other@univ.fr',
      matricule: 'ab-123',
      password: 'Password123!',
    });

    assert.equal(duplicate.status, 409);
    assert.equal(duplicate.body.error, 'MATRICULE_TAKEN');
  });
});

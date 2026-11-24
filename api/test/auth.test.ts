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
  });
});

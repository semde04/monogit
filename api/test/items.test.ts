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

describe('Items API & Security BOLA', () => {
  let token1: string;

  before(connectTestDatabase);
  beforeEach(async () => {
    await resetDatabase();
    token1 = (await registerUser('user1@univ.fr')).accessToken;
  });
  after(closeTestDatabase);

  it('exige un jeton d’accès pour créer un objet', async () => {
    const response = await api.post('/api/v1/items').send({ title: 'Clés' });
    assert.equal(response.status, 401);
  });

  it('crée et recherche un objet dans l’API', async () => {
    const created = await api
      .post('/api/v1/items')
      .set(bearer(token1))
      .send({
        title: 'Casque Audio Sony',
        description: 'Trouvé en Amphi C',
        type: 'FOUND',
        category: 'ELECTRONICS',
        location: 'Amphi C',
      });

    assert.equal(created.status, 201);
    assert.equal(created.body.data.title, 'Casque Audio Sony');

    const search = await api.get('/api/v1/items?search=Casque');
    assert.equal(search.status, 200);
    assert.equal(search.body.data.length, 1);
  });

  it('interdit à un utilisateur B de clôturer l’annonce de l’utilisateur A', async () => {
    const created = await api
      .post('/api/v1/items')
      .set(bearer(token1))
      .send({
        title: 'Portefeuille marron',
        description: 'Perdu au resto U',
        type: 'LOST',
        category: 'PAPERS',
        location: 'Resto U',
      });

    assert.equal(created.status, 201);
    const itemId = created.body.data._id as string;
    const token2 = (await registerUser('user2@univ.fr')).accessToken;

    const response = await api
      .patch(`/api/v1/items/${itemId}/close`)
      .set(bearer(token2));

    assert.equal(response.status, 403);
  });
});

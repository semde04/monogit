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

describe('Claims and private messages API', () => {
  let ownerToken: string;
  let claimantToken: string;
  let itemId: string;
  let claimId: string;

  before(connectTestDatabase);
  beforeEach(async () => {
    await resetDatabase();

    ownerToken = (await registerUser('owner@univ.fr')).accessToken;
    const item = await api
      .post('/api/v1/items')
      .set(bearer(ownerToken))
      .send({
        title: 'Sac bleu',
        description: 'Trouvé près de la bibliothèque',
        type: 'FOUND',
        category: 'BAGS',
        location: 'Bibliothèque',
        proofQuestion: 'Que contient la poche avant ?',
      });
    assert.equal(item.status, 201);
    itemId = item.body.data._id as string;

    claimantToken = (await registerUser('claimant@univ.fr')).accessToken;
    const claim = await api
      .post('/api/v1/claims')
      .set(bearer(claimantToken))
      .send({ itemId, proofAnswer: 'Un carnet rouge' });
    assert.equal(claim.status, 201);
    claimId = claim.body.data._id as string;

    const accepted = await api
      .patch(`/api/v1/claims/${claimId}/status`)
      .set(bearer(ownerToken))
      .send({ status: 'accepted' });
    assert.equal(accepted.status, 200);
  });
  after(closeTestDatabase);

  it('enregistre la réponse de preuve et la rend visible au propriétaire', async () => {
    const claims = await api
      .get('/api/v1/claims')
      .set(bearer(ownerToken));

    assert.equal(claims.status, 200);
    assert.equal(claims.body.data.claims.length, 1);
    assert.equal(claims.body.data.claims[0].proofAnswer, 'Un carnet rouge');
  });

  it('permet aux participants de discuter et refuse l’accès aux autres utilisateurs', async () => {
    const sent = await api
      .post('/api/v1/messages')
      .set(bearer(claimantToken))
      .send({ claimId, text: 'Bonjour, quand puis-je récupérer le sac ?' });

    assert.equal(sent.status, 201);
    assert.equal(sent.body.data.body, 'Bonjour, quand puis-je récupérer le sac ?');

    const history = await api
      .get(`/api/v1/messages/claims/${claimId}`)
      .set(bearer(ownerToken));
    assert.equal(history.status, 200);
    assert.equal(history.body.data.messages.length, 1);

    const outsiderToken = (await registerUser('outsider@univ.fr')).accessToken;
    const forbidden = await api
      .get(`/api/v1/messages/claims/${claimId}`)
      .set(bearer(outsiderToken));
    assert.equal(forbidden.status, 404);
  });

  it('refuse à un tiers l’accès à une réclamation restituée', async () => {
    const ownerConfirmation = await api
      .post(`/api/v1/claims/${claimId}/confirm-return`)
      .set(bearer(ownerToken));
    assert.equal(ownerConfirmation.status, 200);
    const claimantConfirmation = await api
      .post(`/api/v1/claims/${claimId}/confirm-return`)
      .set(bearer(claimantToken));
    assert.equal(claimantConfirmation.status, 200);

    const outsiderToken = (await registerUser('reader@univ.fr')).accessToken;
    const forbidden = await api
      .post(`/api/v1/claims/${claimId}/confirm-return`)
      .set(bearer(outsiderToken));
    assert.equal(forbidden.status, 404);
  });

  it('borne la taille des pages de réclamations', async () => {
    const response = await api
      .get('/api/v1/claims?limit=100')
      .set(bearer(ownerToken));
    assert.equal(response.status, 422);
  });
});

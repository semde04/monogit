import assert from 'node:assert/strict';
import { after, before, beforeEach, describe, it } from 'node:test';
import { UserModel } from '../src/modules/auth/user.model.ts';
import {
  api,
  bearer,
  closeTestDatabase,
  connectTestDatabase,
  registerUser,
  resetDatabase,
} from './helpers.ts';

describe('Admin API', () => {
  before(connectTestDatabase);
  beforeEach(resetDatabase);
  after(closeTestDatabase);

  it('refuse l’accès au tableau de bord pour un compte étudiant', async () => {
    const student = await registerUser('student@univ.fr');
    const response = await api
      .get('/api/v1/admin/overview')
      .set(bearer(student.accessToken));

    assert.equal(response.status, 403);
  });

  it('permet à un administrateur de retirer puis rétablir une annonce', async () => {
    const owner = await registerUser('owner@univ.fr');
    const created = await api
      .post('/api/v1/items')
      .set(bearer(owner.accessToken))
      .send({
        title: 'Sac à dos bleu',
        description: 'Trouvé près de la bibliothèque',
        type: 'FOUND',
        category: 'OTHER',
        location: 'Bibliothèque',
      });
    assert.equal(created.status, 201);

    const admin = await registerUser('admin@univ.fr');
    await UserModel.updateOne({ email: 'admin@univ.fr' }, { $set: { role: 'admin' } });

    const overview = await api
      .get('/api/v1/admin/overview')
      .set(bearer(admin.accessToken));
    assert.equal(overview.status, 200);
    assert.equal(overview.body.data.stats.users, 2);

    const removed = await api
      .patch(`/api/v1/admin/items/${created.body.data._id}/moderation`)
      .set(bearer(admin.accessToken))
      .send({ isRemoved: true, reason: 'Annonce à vérifier' });
    assert.equal(removed.status, 200);
    assert.equal(removed.body.data.isRemoved, true);

    const publicList = await api.get('/api/v1/items');
    assert.equal(publicList.status, 200);
    assert.equal(publicList.body.data.length, 0);

    const restored = await api
      .patch(`/api/v1/admin/items/${created.body.data._id}/moderation`)
      .set(bearer(admin.accessToken))
      .send({ isRemoved: false });
    assert.equal(restored.status, 200);
    assert.equal(restored.body.data.isRemoved, false);
  });

  it('journalise les activités et expose les dates de création des comptes', async () => {
    const student = await registerUser('student@univ.fr');
    await api
      .post('/api/v1/items')
      .set(bearer(student.accessToken))
      .send({
        title: 'Carnet vert',
        description: 'Trouvé en cours',
        type: 'LOST',
        category: 'OTHER',
        location: 'Amphi A',
      });

    const admin = await registerUser('admin@univ.fr');
    await UserModel.updateOne({ email: 'admin@univ.fr' }, { $set: { role: 'admin' } });

    const overview = await api
      .get('/api/v1/admin/overview')
      .set(bearer(admin.accessToken));
    assert.equal(overview.status, 200);
    assert.ok(overview.body.data.stats.newUsersToday >= 2);
    assert.ok(overview.body.data.stats.actionsToday >= 3);
    assert.ok(overview.body.data.recentUsers[0].createdAt);

    const activity = await api
      .get('/api/v1/admin/activity?page=1&limit=20')
      .set(bearer(admin.accessToken));
    assert.equal(activity.status, 200);
    assert.equal(activity.body.meta.limit, 20);
    const types = activity.body.data.map((entry: { type: string }) => entry.type);
    assert.ok(types.includes('auth.register'));
    assert.ok(types.includes('item.created'));

    const filtered = await api
      .get('/api/v1/admin/activity?type=item.created')
      .set(bearer(admin.accessToken));
    assert.equal(filtered.status, 200);
    assert.ok(filtered.body.data.length >= 1);
    assert.ok(
      filtered.body.data.every((entry: { type: string }) => entry.type === 'item.created'),
    );
  });
});

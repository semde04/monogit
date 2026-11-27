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

  async function registerAdmin(email = 'admin@univ.fr') {
    const admin = await registerUser(email);
    await UserModel.updateOne({ email }, { $set: { role: 'admin' } });
    return admin;
  }

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

  it('liste toutes les annonces avec pagination et filtres administrateur', async () => {
    const admin = await registerAdmin();
    const owner = await registerUser('owner-list@univ.fr');
    const itemIds: string[] = [];
    for (const [title, type] of [
      ['Clés neuves', 'FOUND'],
      ['Clés rouillées', 'FOUND'],
      ['Portefeuille noir', 'LOST'],
    ] as const) {
      const created = await api
        .post('/api/v1/items')
        .set(bearer(owner.accessToken))
        .send({ title, description: `Description de ${title}`, type, category: 'OTHER', location: 'Campus' });
      assert.equal(created.status, 201);
      itemIds.push(created.body.data._id);
    }

    const removed = await api
      .patch(`/api/v1/admin/items/${itemIds[2]}/moderation`)
      .set(bearer(admin.accessToken))
      .send({ isRemoved: true, reason: 'Annonce suspecte' });
    assert.equal(removed.status, 200);
    const closed = await api
      .patch(`/api/v1/items/${itemIds[1]}/close`)
      .set(bearer(owner.accessToken));
    assert.equal(closed.status, 200);

    const firstPage = await api
      .get('/api/v1/admin/items?page=1&limit=2')
      .set(bearer(admin.accessToken));
    assert.equal(firstPage.status, 200);
    assert.deepEqual(firstPage.body.meta, { page: 1, limit: 2, total: 3, pages: 2 });
    assert.equal(firstPage.body.data.length, 2);
    const firstItem = firstPage.body.data[0];
    assert.equal(firstItem.title, 'Portefeuille noir');
    assert.equal(firstItem.owner.name, 'Test User');
    assert.equal(firstItem.owner.matricule, owner.user.matricule);
    assert.equal(firstItem.isReturned, false);
    assert.ok(firstItem.createdAt);
    for (const field of [
      '_id', 'title', 'description', 'location', 'type', 'category', 'imageData',
      'isClosed', 'isRemoved', 'moderationReason', 'isReturned', 'createdAt', 'owner',
    ]) {
      assert.ok(field in firstItem, `Champ admin manquant : ${field}`);
    }

    const secondPage = await api
      .get('/api/v1/admin/items?page=2&limit=2')
      .set(bearer(admin.accessToken));
    assert.equal(secondPage.status, 200);
    assert.equal(secondPage.body.data.length, 1);

    const removedItems = await api
      .get('/api/v1/admin/items?isRemoved=true')
      .set(bearer(admin.accessToken));
    assert.equal(removedItems.status, 200);
    assert.equal(removedItems.body.data.length, 1);
    assert.equal(removedItems.body.data[0].moderationReason, 'Annonce suspecte');

    const closedItems = await api
      .get('/api/v1/admin/items?isClosed=true')
      .set(bearer(admin.accessToken));
    assert.equal(closedItems.body.data.length, 1);
    assert.equal(closedItems.body.data[0].title, 'Clés rouillées');

    const searched = await api
      .get('/api/v1/admin/items?search=Clés&type=FOUND')
      .set(bearer(admin.accessToken));
    assert.equal(searched.body.meta.total, 2);

    const invalidFilter = await api
      .get('/api/v1/admin/items?isClosed=peut-etre')
      .set(bearer(admin.accessToken));
    assert.equal(invalidFilter.status, 422);

    const forbidden = await api
      .get('/api/v1/admin/items')
      .set(bearer(owner.accessToken));
    assert.equal(forbidden.status, 403);
  });

  it('filtre les annonces restituées et expose les statistiques de restitution', async () => {
    const admin = await registerAdmin();
    const owner = await registerUser('owner-return@univ.fr');
    const claimant = await registerUser('claimant-return@univ.fr');
    const created = await api
      .post('/api/v1/items')
      .set(bearer(owner.accessToken))
      .send({
        title: 'Montre argentée',
        description: 'Trouvée au sport',
        type: 'FOUND',
        category: 'OTHER',
        location: 'Gymnase',
      });
    assert.equal(created.status, 201);
    const itemId = created.body.data._id as string;
    const claim = await api
      .post('/api/v1/claims')
      .set(bearer(claimant.accessToken))
      .send({ itemId, proofAnswer: 'Gravure au dos' });
    assert.equal(claim.status, 201);
    const accepted = await api
      .patch(`/api/v1/claims/${claim.body.data._id}/status`)
      .set(bearer(owner.accessToken))
      .send({ status: 'accepted' });
    assert.equal(accepted.status, 200);

    const partial = await api
      .post(`/api/v1/claims/${claim.body.data._id}/confirm-return`)
      .set(bearer(claimant.accessToken));
    assert.equal(partial.status, 200);
    const beforeReturn = await api
      .get('/api/v1/admin/items?isReturned=true')
      .set(bearer(admin.accessToken));
    assert.equal(beforeReturn.body.meta.total, 0);

    const complete = await api
      .post(`/api/v1/claims/${claim.body.data._id}/confirm-return`)
      .set(bearer(owner.accessToken));
    assert.equal(complete.status, 200);

    const returned = await api
      .get('/api/v1/admin/items?isReturned=true')
      .set(bearer(admin.accessToken));
    assert.equal(returned.status, 200);
    assert.equal(returned.body.meta.total, 1);
    assert.equal(returned.body.data[0]._id, itemId);
    assert.equal(returned.body.data[0].isReturned, true);
    assert.equal(returned.body.data[0].isClosed, true);

    const notReturned = await api
      .get('/api/v1/admin/items?isReturned=false')
      .set(bearer(admin.accessToken));
    assert.equal(notReturned.body.meta.total, 0);

    const overview = await api
      .get('/api/v1/admin/overview')
      .set(bearer(admin.accessToken));
    assert.equal(overview.status, 200);
    assert.equal(overview.body.data.stats.foundReportsToday, 1);
    assert.equal(overview.body.data.stats.returnedItems, 1);
  });

  it('suspend un étudiant avec un motif et journalise l’action', async () => {
    const admin = await registerAdmin();
    const otherAdmin = await registerAdmin('other-admin@univ.fr');
    const student = await registerUser('student-suspended@univ.fr');
    const studentId = student.user.id;

    const missingReason = await api
      .patch(`/api/v1/admin/users/${studentId}/suspension`)
      .set(bearer(admin.accessToken))
      .send({ isSuspended: true });
    assert.equal(missingReason.status, 422);

    const shortReason = await api
      .patch(`/api/v1/admin/users/${studentId}/suspension`)
      .set(bearer(admin.accessToken))
      .send({ isSuspended: true, reason: 'ab' });
    assert.equal(shortReason.status, 422);

    const selfSuspension = await api
      .patch(`/api/v1/admin/users/${admin.user.id}/suspension`)
      .set(bearer(admin.accessToken))
      .send({ isSuspended: true, reason: 'Auto-suspension' });
    assert.equal(selfSuspension.status, 403);
    assert.equal(selfSuspension.body.error, 'FORBIDDEN');

    const adminSuspension = await api
      .patch(`/api/v1/admin/users/${otherAdmin.user.id}/suspension`)
      .set(bearer(admin.accessToken))
      .send({ isSuspended: true, reason: 'Compte privilégié' });
    assert.equal(adminSuspension.status, 403);
    assert.equal(adminSuspension.body.error, 'FORBIDDEN');

    const suspended = await api
      .patch(`/api/v1/admin/users/${studentId}/suspension`)
      .set(bearer(admin.accessToken))
      .send({ isSuspended: true, reason: 'Triche avérée' });
    assert.equal(suspended.status, 200);
    assert.equal(suspended.body.data._id, studentId);
    assert.equal(suspended.body.data.isSuspended, true);
    assert.equal(suspended.body.data.email, 'student-suspended@univ.fr');
    assert.ok(suspended.body.data.createdAt);

    const profile = await api
      .get('/api/v1/auth/me')
      .set(bearer(student.accessToken));
    assert.equal(profile.status, 200);
    assert.equal(profile.body.data.isSuspended, true);

    const activity = await api
      .get('/api/v1/admin/activity?type=admin.user.suspension')
      .set(bearer(admin.accessToken));
    assert.equal(activity.status, 200);
    assert.equal(activity.body.data.length, 1);
    assert.equal(activity.body.data[0].targetType, 'user');
    assert.equal(activity.body.data[0].targetId, studentId);
    assert.match(activity.body.data[0].summary, /A suspendu le compte de Test User/);

    const reactivated = await api
      .patch(`/api/v1/admin/users/${studentId}/suspension`)
      .set(bearer(admin.accessToken))
      .send({ isSuspended: false });
    assert.equal(reactivated.status, 200);
    assert.equal(reactivated.body.data.isSuspended, false);
    const stored = await UserModel.findById(studentId).lean();
    assert.equal(stored?.isSuspended, false);
    assert.equal(stored?.suspensionReason, null);
    assert.equal(stored?.suspendedBy, null);
    assert.equal(stored?.suspendedAt, null);
  });
});

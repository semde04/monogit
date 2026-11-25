import { applicationDefault, getApps, initializeApp } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import { UserModel } from '../modules/auth/user.model.ts';
import { env } from '../config/env.ts';
import { logger } from '../config/logger.ts';

function firebaseMessaging() {
  if (!env.FIREBASE_PROJECT_ID) return null;

  const app =
    getApps().find((entry) => entry.name === 'lostfound-push') ??
    initializeApp(
      {
        credential: applicationDefault(),
        projectId: env.FIREBASE_PROJECT_ID,
      },
      'lostfound-push',
    );
  return getMessaging(app);
}

export async function sendPushToUser(
  userId: string,
  notification: { title: string; body: string },
  data: Record<string, string>,
) {
  try {
    const messaging = firebaseMessaging();
    if (!messaging) return;

    const user = await UserModel.findById(userId)
      .select('+firebaseInstallationIds')
      .lean();
    const fids = user?.firebaseInstallationIds ?? [];
    if (fids.length === 0) return;

    const results = await Promise.allSettled(
      fids.map((fid) =>
        messaging.send({ fid, notification, data, android: { priority: 'high' } }),
      ),
    );
    const invalidFids = results.flatMap((result, index) => {
      if (result.status === 'fulfilled') return [];
      const code = result.reason?.code;
      return code === 'messaging/registration-token-not-registered' ||
        code === 'messaging/invalid-registration-token'
        ? [fids[index]]
        : [];
    });
    if (invalidFids.length > 0) {
      await UserModel.updateOne(
        { _id: userId },
        { $pull: { firebaseInstallationIds: { $in: invalidFids } } },
      );
    }
  } catch (error) {
    logger.warn({ error, userId }, 'Push notification could not be sent');
  }
}

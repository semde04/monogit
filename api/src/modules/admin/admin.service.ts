import { isValidObjectId, Types } from 'mongoose';
import { UserModel } from '../auth/user.model.ts';
import { ClaimModel } from '../claims/claim.model.ts';
import { ItemModel } from '../items/item.model.ts';
import { AppError } from '../../shared/errors.ts';
import { ActivityModel } from './activity.model.ts';
import { recordActivity } from './activity.service.ts';
import type { ActivityQueryInput, ModerateItemInput } from './admin.schemas.ts';
import type { PaginationInput } from '../../shared/pagination.ts';
import { listActivity } from './activity.service.ts';

function startOfToday(): Date {
  const now = new Date();
  return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
}

export async function getAdminOverview(pagination: PaginationInput) {
  const skip = (pagination.page - 1) * pagination.limit;
  const since = startOfToday();
  const [users, items, claims, pendingClaims, newUsersToday, actionsToday, recentUsers, recentItems] =
    await Promise.all([
      UserModel.countDocuments(),
      ItemModel.countDocuments(),
      ClaimModel.countDocuments(),
      ClaimModel.countDocuments({ status: 'pending' }),
      UserModel.countDocuments({ createdAt: { $gte: since } }),
      ActivityModel.countDocuments({ createdAt: { $gte: since } }),
      UserModel.find()
        .select('_id name email matricule role createdAt')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(pagination.limit)
        .lean(),
      ItemModel.find()
        .select('title description category location type imageData isClosed isRemoved moderationReason moderatedAt owner createdAt')
        .populate('owner', 'name matricule')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(pagination.limit)
        .lean(),
    ]);

  return {
    stats: { users, items, claims, pendingClaims, newUsersToday, actionsToday },
    recentUsers,
    recentItems,
    totals: { users, items },
  };
}

export async function getActivity(query: ActivityQueryInput) {
  return listActivity(query, query.type);
}

export async function moderateItem(
  itemId: string,
  adminId: string,
  input: ModerateItemInput,
) {
  if (!isValidObjectId(itemId)) {
    throw new AppError('Annonce introuvable.', 404, 'ITEM_NOT_FOUND');
  }
  if (input.isRemoved && !input.reason) {
    throw new AppError(
      'Un motif est obligatoire pour retirer une annonce.',
      400,
      'VALIDATION_ERROR',
      { fieldErrors: { reason: ['Indiquez le motif du retrait.'] } },
    );
  }

  const item = await ItemModel.findById(itemId);
  if (!item) throw new AppError('Annonce introuvable.', 404, 'ITEM_NOT_FOUND');

  item.isRemoved = input.isRemoved;
  item.moderationReason = input.isRemoved ? input.reason : undefined;
  item.moderatedBy = input.isRemoved ? new Types.ObjectId(adminId) : undefined;
  item.moderatedAt = input.isRemoved ? new Date() : undefined;
  await item.save();
  await recordActivity({
    type: 'admin.moderation',
    actorId: adminId,
    summary: input.isRemoved
      ? `A masqué l’annonce « ${item.title} » (${input.reason})`
      : `A rétabli l’annonce « ${item.title} »`,
    targetType: 'item',
    targetId: item.id,
  });
  return item;
}

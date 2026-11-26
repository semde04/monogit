import { isValidObjectId, Types } from 'mongoose';
import { UserModel } from '../auth/user.model.ts';
import { ClaimModel } from '../claims/claim.model.ts';
import { ItemModel } from '../items/item.model.ts';
import { AppError } from '../../shared/errors.ts';
import type { ModerateItemInput } from './admin.schemas.ts';

export async function getAdminOverview() {
  const [users, items, claims, pendingClaims, recentUsers, recentItems] =
    await Promise.all([
      UserModel.countDocuments(),
      ItemModel.countDocuments(),
      ClaimModel.countDocuments(),
      ClaimModel.countDocuments({ status: 'pending' }),
      UserModel.find()
        .select('_id name email matricule role createdAt')
        .sort({ createdAt: -1 })
        .lean(),
      ItemModel.find()
        .select('title description category location type imageData isClosed isRemoved moderationReason moderatedAt owner createdAt')
        .populate('owner', 'name matricule')
        .sort({ createdAt: -1 })
        .limit(12)
        .lean(),
    ]);

  return {
    stats: { users, items, claims, pendingClaims },
    recentUsers,
    recentItems,
  };
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
  return item;
}

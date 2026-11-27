import { isValidObjectId, Types } from 'mongoose';
import { UserModel } from '../auth/user.model.ts';
import { ClaimModel } from '../claims/claim.model.ts';
import { ItemModel } from '../items/item.model.ts';
import { AppError } from '../../shared/errors.ts';
import { ActivityModel } from './activity.model.ts';
import { recordActivity } from './activity.service.ts';
import type {
  ActivityQueryInput,
  AdminItemQueryInput,
  ModerateItemInput,
  SuspensionInput,
} from './admin.schemas.ts';
import type { PaginationInput } from '../../shared/pagination.ts';
import { listActivity } from './activity.service.ts';

type AdminItemOwner = { _id: Types.ObjectId; name: string; matricule?: string };

function startOfToday(): Date {
  const now = new Date();
  return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
}

export async function getAdminOverview(pagination: PaginationInput) {
  const skip = (pagination.page - 1) * pagination.limit;
  const since = startOfToday();
  const [users, items, claims, pendingClaims, newUsersToday, actionsToday, foundReportsToday, returnedItems, recentUsers, recentItems] =
    await Promise.all([
      UserModel.countDocuments(),
      ItemModel.countDocuments(),
      ClaimModel.countDocuments(),
      ClaimModel.countDocuments({ status: 'pending' }),
      UserModel.countDocuments({ createdAt: { $gte: since } }),
      ActivityModel.countDocuments({ createdAt: { $gte: since } }),
      ActivityModel.countDocuments({ type: 'item.returned', createdAt: { $gte: since } }),
      ClaimModel.countDocuments({ status: 'returned' }),
      UserModel.find()
        .select('_id name email matricule role isSuspended createdAt')
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
    stats: { users, items, claims, pendingClaims, newUsersToday, actionsToday, foundReportsToday, returnedItems },
    recentUsers,
    recentItems,
    totals: { users, items },
  };
}

export async function getActivity(query: ActivityQueryInput) {
  return listActivity(query, query.type);
}

export async function listAdminItems(filters: AdminItemQueryInput) {
  const query: Record<string, unknown> = {};
  if (filters.category) query.category = filters.category;
  if (filters.type) query.type = filters.type;
  if (filters.isClosed !== undefined) query.isClosed = filters.isClosed;
  if (filters.isRemoved !== undefined) query.isRemoved = filters.isRemoved;
  if (filters.search) {
    const escapedSearch = filters.search.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const expression = new RegExp(escapedSearch, 'i');
    query.$or = [
      { title: expression },
      { description: expression },
      { category: expression },
      { location: expression },
    ];
  }

  const returnedItemIds = await ClaimModel.distinct('item', { status: 'returned' });
  const returnedIds = new Set(returnedItemIds.map((id) => id.toString()));
  if (filters.isReturned !== undefined) {
    query._id = { [filters.isReturned ? '$in' : '$nin']: returnedItemIds };
  }

  const [documents, total] = await Promise.all([
    ItemModel.find(query)
      .select('_id title description location type category imageData isClosed isRemoved moderationReason createdAt owner')
      .populate('owner', '_id name matricule')
      .sort({ createdAt: -1 })
      .skip((filters.page - 1) * filters.limit)
      .limit(filters.limit)
      .lean(),
    ItemModel.countDocuments(query),
  ]);

  const items = documents.map((document) => {
    const owner = document.owner as unknown as AdminItemOwner;
    return {
      _id: document._id,
      title: document.title,
      description: document.description,
      location: document.location,
      type: document.type,
      category: document.category,
      imageData: document.imageData ?? null,
      isClosed: document.isClosed,
      isRemoved: document.isRemoved,
      moderationReason: document.moderationReason ?? null,
      isReturned: returnedIds.has(document._id.toString()),
      createdAt: document.createdAt,
      owner: {
        _id: owner._id,
        name: owner.name,
        matricule: owner.matricule,
      },
    };
  });
  return { items, total };
}

export async function suspendUser(
  userId: string,
  adminId: string,
  input: SuspensionInput,
) {
  if (!isValidObjectId(userId)) {
    throw new AppError('Utilisateur introuvable.', 404, 'USER_NOT_FOUND');
  }
  if (userId === adminId) {
    throw new AppError('Vous ne pouvez pas modifier la suspension de votre propre compte.', 403, 'FORBIDDEN');
  }

  const user = await UserModel.findById(userId).select('_id name email matricule role isSuspended createdAt');
  if (!user) throw new AppError('Utilisateur introuvable.', 404, 'USER_NOT_FOUND');
  if (user.role === 'admin') {
    throw new AppError('Impossible de suspendre un compte administrateur.', 403, 'FORBIDDEN');
  }

  user.isSuspended = input.isSuspended;
  user.suspensionReason = input.isSuspended ? input.reason : null;
  user.suspendedBy = input.isSuspended ? new Types.ObjectId(adminId) : null;
  user.suspendedAt = input.isSuspended ? new Date() : null;
  await user.save();
  await recordActivity({
    type: 'admin.user.suspension',
    actorId: adminId,
    summary: input.isSuspended
      ? `A suspendu le compte de ${user.name} (${input.reason})`
      : `A réactivé le compte de ${user.name}`,
    targetType: 'user',
    targetId: user.id,
  });

  return {
    _id: user._id,
    name: user.name,
    email: user.email,
    matricule: user.matricule,
    role: user.role,
    isSuspended: user.isSuspended,
    createdAt: user.createdAt,
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

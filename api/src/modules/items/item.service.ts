import { isValidObjectId, type Types } from 'mongoose';
import { AppError } from '../../shared/errors.ts';
import { ItemModel, type Item } from './item.model.ts';
import { ClaimModel } from '../claims/claim.model.ts';
import { sendPushToUser } from '../../shared/push-notifications.ts';
import { recordActivity } from '../admin/activity.service.ts';
import type { CreateItemInput, UpdateItemInput } from './item.schemas.ts';

type ItemFilters = {
  search?: string;
  category?: string;
  type?: 'FOUND' | 'LOST';
  page: number;
  limit: number;
};
type ItemForMatching = Item & { _id: Types.ObjectId };
const publicFields = '-proofQuestion -moderationReason -moderatedBy -moderatedAt';

export async function listItems(filters: ItemFilters) {
  const query: Record<string, unknown> = {};
  if (filters.category) query.category = filters.category;
  if (filters.type) query.type = filters.type;
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
  query.isClosed = { $ne: true };
  query.isRemoved = { $ne: true };
  const [items, total] = await Promise.all([
    ItemModel.find(query)
      .select(publicFields)
      .sort({ createdAt: -1 })
      .skip((filters.page - 1) * filters.limit)
      .limit(filters.limit)
      .lean(),
    ItemModel.countDocuments(query),
  ]);
  return { items, total };
}

export async function getItem(itemId: string) {
  if (!isValidObjectId(itemId)) {
    throw new AppError('Objet introuvable.', 404, 'ITEM_NOT_FOUND');
  }
  const item = await ItemModel.findById(itemId).select(publicFields).lean();
  if (!item || item.isRemoved) {
    throw new AppError('Objet introuvable.', 404, 'ITEM_NOT_FOUND');
  }
  return item;
}

const ignoredMatchWords = new Set([
  'avec', 'dans', 'elle', 'elles', 'est', 'et', 'les', 'leur', 'mes', 'mon',
  'notre', 'objet', 'pour', 'que', 'qui', 'son', 'sur', 'une', 'des', 'the',
  'and', 'for', 'with', 'this', 'that', 'from', 'lost', 'found',
]);

function searchTerms(value: string): Set<string> {
  return new Set(
    value.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase()
      .split(/[^a-z0-9]+/)
      .filter((word) => word.length > 2 && !ignoredMatchWords.has(word)),
  );
}

async function notifyPossibleMatches(found: ItemForMatching) {
  const foundTerms = searchTerms(`${found.title} ${found.description}`);
  if (foundTerms.size === 0) return;
  const lostItems = await ItemModel.find({
    type: 'LOST',
    category: found.category,
    owner: { $ne: found.owner },
    isClosed: { $ne: true },
    isRemoved: { $ne: true },
  }).select('_id title description owner').lean();

  const bestMatches = new Map<string, { itemId: string; title: string; score: number }>();
  for (const lost of lostItems) {
    const terms = searchTerms(`${lost.title} ${lost.description}`);
    if (terms.size === 0) continue;
    const common = [...terms].filter((term) => foundTerms.has(term)).length;
    const required = Math.min(2, Math.ceil(Math.min(terms.size, foundTerms.size) / 2));
    if (common < required) continue;
    const ownerId = lost.owner.toString();
    const match = { itemId: found._id.toString(), title: lost.title, score: common / terms.size };
    if (!bestMatches.has(ownerId) || bestMatches.get(ownerId)!.score < match.score) {
      bestMatches.set(ownerId, match);
    }
  }

  for (const [ownerId, match] of bestMatches) {
    void sendPushToUser(ownerId, {
      title: 'Objet trouvé correspondant',
      body: `Un objet trouvé pourrait correspondre à votre déclaration « ${match.title} ». Vérifiez l’annonce dans LostFound.`,
    }, { type: 'possible_match', itemId: match.itemId });
  }
}

export async function createItem(input: CreateItemInput, ownerId: string) {
  const item = await ItemModel.create({ ...input, owner: ownerId });
  if (item.type === 'FOUND') {
    void notifyPossibleMatches(item).catch(() => undefined);
  }
  await recordActivity({
    type: 'item.created',
    actorId: ownerId,
    summary: `A publié une annonce ${item.type.toLowerCase()} : « ${item.title} »`,
    targetType: 'item',
    targetId: item.id,
  });
  return item;
}

export async function updateItem(
  itemId: string,
  ownerId: string,
  input: UpdateItemInput,
) {
  if (!isValidObjectId(itemId)) {
    throw new AppError('Objet introuvable.', 404, 'ITEM_NOT_FOUND');
  }
  const item = await ItemModel.findOneAndUpdate(
    { _id: itemId, owner: ownerId },
    { $set: input },
    { new: true, runValidators: true },
  );
  if (!item) throw new AppError('Objet introuvable.', 404, 'ITEM_NOT_FOUND');
  await recordActivity({
    type: 'item.updated',
    actorId: ownerId,
    summary: `A modifié l’annonce « ${item.title} »`,
    targetType: 'item',
    targetId: item.id,
  });
  return item;
}

export async function deleteItem(itemId: string, ownerId: string): Promise<void> {
  if (!isValidObjectId(itemId)) {
    throw new AppError('Objet introuvable.', 404, 'ITEM_NOT_FOUND');
  }
  if (await ClaimModel.exists({ item: itemId, status: 'accepted' })) {
    throw new AppError('Terminez la réclamation et confirmez la restitution avant de supprimer cette annonce.', 409, 'CLAIM_IN_PROGRESS');
  }
  const deleted = await ItemModel.findOneAndDelete(
    { _id: itemId, owner: ownerId },
  ).select('title');
  if (!deleted) {
    throw new AppError('Objet introuvable.', 404, 'ITEM_NOT_FOUND');
  }
  await recordActivity({
    type: 'item.deleted',
    actorId: ownerId,
    summary: `A supprimé l’annonce « ${deleted.title} »`,
    targetType: 'item',
    targetId: itemId,
  });
}

export async function closeItem(itemId: string, userId: string) {
  if (!isValidObjectId(itemId)) {
    throw new AppError('Objet introuvable.', 404, 'ITEM_NOT_FOUND');
  }
  const item = await ItemModel.findById(itemId);
  if (!item) throw new AppError('Objet introuvable.', 404, 'ITEM_NOT_FOUND');
  if (item.owner.toString() !== userId) {
    throw new AppError('Vous ne pouvez pas clôturer cet objet.', 403, 'FORBIDDEN');
  }
  item.isClosed = true;
  await item.save();
  await recordActivity({
    type: 'item.closed',
    actorId: userId,
    summary: `A clôturé l’annonce « ${item.title} »`,
    targetType: 'item',
    targetId: item.id,
  });
  return item;
}

import { isValidObjectId } from 'mongoose';
import { AppError } from '../../shared/errors.ts';
import { ItemModel } from './item.model.ts';
import type { CreateItemInput, UpdateItemInput } from './item.schemas.ts';

type ItemFilters = { search?: string; category?: string; type?: 'FOUND' | 'LOST' };

export function listItems(filters: ItemFilters = {}) {
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
  return ItemModel.find(query).sort({ createdAt: -1 }).lean();
}

export async function getItem(itemId: string) {
  if (!isValidObjectId(itemId)) {
    throw new AppError('Objet introuvable.', 404, 'ITEM_NOT_FOUND');
  }
  const item = await ItemModel.findById(itemId).lean();
  if (!item || item.isRemoved) {
    throw new AppError('Objet introuvable.', 404, 'ITEM_NOT_FOUND');
  }
  return item;
}

export function createItem(input: CreateItemInput, ownerId: string) {
  return ItemModel.create({ ...input, owner: ownerId });
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
  return item;
}

export async function deleteItem(itemId: string, ownerId: string): Promise<void> {
  if (!isValidObjectId(itemId)) {
    throw new AppError('Objet introuvable.', 404, 'ITEM_NOT_FOUND');
  }
  const result = await ItemModel.deleteOne({ _id: itemId, owner: ownerId });
  if (result.deletedCount === 0) {
    throw new AppError('Objet introuvable.', 404, 'ITEM_NOT_FOUND');
  }
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
  return item;
}

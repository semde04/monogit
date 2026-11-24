import { isValidObjectId } from 'mongoose';
import { AppError } from '../../shared/errors.ts';
import { ItemModel } from './item.model.ts';
import type { CreateItemInput, UpdateItemInput } from './item.schemas.ts';

export function listItems() {
  return ItemModel.find().sort({ createdAt: -1 }).lean();
}

export async function getItem(itemId: string) {
  if (!isValidObjectId(itemId)) {
    throw new AppError('Objet introuvable.', 404, 'ITEM_NOT_FOUND');
  }
  const item = await ItemModel.findById(itemId).lean();
  if (!item) throw new AppError('Objet introuvable.', 404, 'ITEM_NOT_FOUND');
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

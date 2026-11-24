import { isValidObjectId } from 'mongoose';
import { AppError } from '../../shared/errors.ts';
import { ItemModel } from '../items/item.model.ts';
import { ClaimModel } from './claim.model.ts';
import type { CreateClaimInput, UpdateClaimStatusInput } from './claim.schemas.ts';

export async function createClaim(claimantId: string, input: CreateClaimInput) {
  const { itemId } = input;
  if (!isValidObjectId(itemId)) {
    throw new AppError('Objet introuvable.', 404, 'ITEM_NOT_FOUND');
  }
  const item = await ItemModel.findById(itemId).select('_id owner');
  if (!item) throw new AppError('Objet introuvable.', 404, 'ITEM_NOT_FOUND');
  if (item.owner.toString() === claimantId) {
    throw new AppError('Vous ne pouvez pas réclamer votre propre objet.', 400, 'SELF_CLAIM');
  }

  const existingClaim = await ClaimModel.exists({
    item: itemId,
    claimant: claimantId,
    status: 'pending',
  });
  if (existingClaim) {
    throw new AppError('Une réclamation est déjà en attente.', 409, 'CLAIM_ALREADY_EXISTS');
  }

  return ClaimModel.create({
    item: itemId,
    claimant: claimantId,
    proofAnswer: input.proofAnswer,
  });
}

export async function listClaimsForUser(userId: string) {
  const ownedItems = await ItemModel.find({ owner: userId }).distinct('_id');
  return ClaimModel.find({
    $or: [{ claimant: userId }, { item: { $in: ownedItems } }],
  })
    .populate('item', 'title type owner proofQuestion')
    .populate('claimant', 'name')
    .sort({ createdAt: -1 })
    .lean();
}

export async function updateClaimStatus(
  claimId: string,
  ownerId: string,
  input: UpdateClaimStatusInput,
) {
  if (!isValidObjectId(claimId)) {
    throw new AppError('Réclamation introuvable.', 404, 'CLAIM_NOT_FOUND');
  }
  const claim = await ClaimModel.findById(claimId).select('item status');
  if (!claim) throw new AppError('Réclamation introuvable.', 404, 'CLAIM_NOT_FOUND');

  const ownsItem = await ItemModel.exists({ _id: claim.item, owner: ownerId });
  if (!ownsItem) throw new AppError('Réclamation introuvable.', 404, 'CLAIM_NOT_FOUND');
  if (claim.status !== 'pending') {
    throw new AppError('Cette réclamation a déjà été traitée.', 409, 'CLAIM_ALREADY_RESOLVED');
  }

  claim.status = input.status;
  await claim.save();
  return claim;
}

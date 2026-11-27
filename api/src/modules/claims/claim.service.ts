import { isValidObjectId } from 'mongoose';
import { AppError } from '../../shared/errors.ts';
import { ItemModel } from '../items/item.model.ts';
import { ClaimModel } from './claim.model.ts';
import { UserModel } from '../auth/user.model.ts';
import { sendPushToUser } from '../../shared/push-notifications.ts';
import { recordActivity } from '../admin/activity.service.ts';
import type { CreateClaimInput, UpdateClaimStatusInput } from './claim.schemas.ts';
import type { PaginationInput } from '../../shared/pagination.ts';

export async function createClaim(claimantId: string, input: CreateClaimInput) {
  const { itemId } = input;
  if (!isValidObjectId(itemId)) {
    throw new AppError('Objet introuvable.', 404, 'ITEM_NOT_FOUND');
  }
  const item = await ItemModel.findById(itemId).select('_id owner isRemoved isClosed title type');
  if (!item) throw new AppError('Objet introuvable.', 404, 'ITEM_NOT_FOUND');
  if (item.isRemoved) {
    throw new AppError('Cette annonce a été retirée par la modération.', 404, 'ITEM_NOT_FOUND');
  }
  if (item.isClosed) {
    throw new AppError('Cet objet a déjà été clôturé.', 409, 'ITEM_CLOSED');
  }
  if (await ClaimModel.exists({ item: itemId, status: 'accepted' })) {
    throw new AppError('Une réclamation est déjà en cours pour cet objet.', 409, 'CLAIM_IN_PROGRESS');
  }
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

  let claim;
  try {
    claim = await ClaimModel.create({
      item: itemId,
      claimant: claimantId,
      proofAnswer: input.proofAnswer,
      itemTitleSnapshot: item.title,
      itemTypeSnapshot: item.type,
      itemOwnerSnapshot: item.owner,
    });
  } catch (error) {
    if (
      typeof error === 'object' && error !== null &&
      'code' in error && error.code === 11000
    ) {
      throw new AppError('Une réclamation est déjà en attente.', 409, 'CLAIM_ALREADY_EXISTS');
    }
    throw error;
  }

  await recordActivity({
    type: 'claim.created',
    actorId: claimantId,
    summary: `A réclamé l’objet « ${item.title} »`,
    targetType: 'claim',
    targetId: claim.id,
  });
  const claimant = await UserModel.findById(claimantId).select('name').lean();
  if (claimant) {
    void sendPushToUser(
      item.owner.toString(),
      {
        title: 'Nouvelle réclamation',
        body: `${claimant.name} a réclamé « ${item.title} »`,
      },
      { type: 'claim', claimId: claim.id, itemId: item.id },
    );
  }
  return claim;
}

export async function listClaimsForUser(userId: string, pagination: PaginationInput) {
  const ownedItems = await ItemModel.find({ owner: userId }).distinct('_id');
  const filter = {
    $or: [{ claimant: userId }, { item: { $in: ownedItems } }, { itemOwnerSnapshot: userId }],
  };
  const [claims, total] = await Promise.all([
    ClaimModel.find(filter)
      .populate('item', 'title type owner proofQuestion')
      .populate('returnReceipt.finder', 'name')
      .populate('returnReceipt.recipient', 'name')
      .populate('claimant', 'name')
      .sort({ createdAt: -1 })
      .skip((pagination.page - 1) * pagination.limit)
      .limit(pagination.limit)
      .lean(),
    ClaimModel.countDocuments(filter),
  ]);
  return { claims, total };
}

export async function updateClaimStatus(
  claimId: string,
  ownerId: string,
  input: UpdateClaimStatusInput,
) {
  if (!isValidObjectId(claimId)) {
    throw new AppError('Réclamation introuvable.', 404, 'CLAIM_NOT_FOUND');
  }
  const claim = await ClaimModel.findById(claimId).select('item claimant status');
  if (!claim) throw new AppError('Réclamation introuvable.', 404, 'CLAIM_NOT_FOUND');

  const ownsItem = await ItemModel.exists({ _id: claim.item, owner: ownerId });
  if (!ownsItem) throw new AppError('Réclamation introuvable.', 404, 'CLAIM_NOT_FOUND');
  if (claim.status !== 'pending') {
    throw new AppError('Cette réclamation a déjà été traitée.', 409, 'CLAIM_ALREADY_RESOLVED');
  }

  const updated = await ClaimModel.findOneAndUpdate(
    { _id: claimId, status: 'pending' },
    { $set: { status: input.status } },
    { new: true },
  );
  if (!updated) {
    throw new AppError('Cette réclamation a déjà été traitée.', 409, 'CLAIM_ALREADY_RESOLVED');
  }
  await recordActivity({
    type: 'claim.status',
    actorId: ownerId,
    summary: `A ${input.status === 'accepted' ? 'accepté' : 'refusé'} une réclamation pour « ${claim.itemTitleSnapshot ?? 'un objet'} »`,
    targetType: 'claim',
    targetId: updated.id,
  });
  if (input.status === 'accepted') {
    const item = await ItemModel.findById(claim.item).select('title owner');
    void sendPushToUser(claim.claimant.toString(), {
      title: 'Réclamation acceptée',
      body: `Vous pouvez maintenant contacter le trouveur au sujet de « ${item?.title ?? 'votre objet'} »`,
    }, { type: 'claim_accepted', claimId: updated.id });
    await ClaimModel.updateMany(
      { item: claim.item, _id: { $ne: claim._id }, status: 'pending' },
      { $set: { status: 'rejected' } },
    );
  }
  return updated;
}

export async function confirmClaimReturn(claimId: string, userId: string) {
  if (!isValidObjectId(claimId)) {
    throw new AppError('Réclamation introuvable.', 404, 'CLAIM_NOT_FOUND');
  }
  const claim = await ClaimModel.findById(claimId);
  if (!claim) throw new AppError('Réclamation introuvable.', 404, 'CLAIM_NOT_FOUND');
  const item = await ItemModel.findById(claim.item).select('title type owner');
  if (!item) throw new AppError('Annonce introuvable.', 404, 'ITEM_NOT_FOUND');
  const ownerId = item.owner.toString();
  const isOwner = userId === ownerId;
  const isClaimant = userId === claim.claimant.toString();
  if (!isOwner && !isClaimant) {
    throw new AppError('Réclamation introuvable.', 404, 'CLAIM_NOT_FOUND');
  }
  if (claim.status === 'returned') return claim;
  if (claim.status !== 'accepted') {
    throw new AppError('La réclamation doit être acceptée avant de confirmer la remise.', 409, 'CLAIM_NOT_ACCEPTED');
  }
  if (isOwner) {
    if (claim.ownerConfirmedReturnAt) throw new AppError('Votre confirmation est déjà enregistrée.', 409, 'RETURN_ALREADY_CONFIRMED');
    claim.ownerConfirmedReturnAt = new Date();
  } else {
    if (claim.claimantConfirmedReturnAt) throw new AppError('Votre confirmation est déjà enregistrée.', 409, 'RETURN_ALREADY_CONFIRMED');
    claim.claimantConfirmedReturnAt = new Date();
  }

  const otherId = userId === ownerId ? claim.claimant.toString() : ownerId;
  if (claim.ownerConfirmedReturnAt && claim.claimantConfirmedReturnAt) {
    const [owner, claimant] = await Promise.all([
      UserModel.findById(ownerId).select('name').lean(),
      UserModel.findById(claim.claimant).select('name').lean(),
    ]);
    const finderIsOwner = item.type === 'FOUND';
    const confirmedAt = new Date();
    claim.status = 'returned';
    claim.returnedAt = confirmedAt;
    claim.returnReceipt = {
      itemTitle: item.title,
      itemType: item.type,
      finder: finderIsOwner ? item.owner : claim.claimant,
      finderName: finderIsOwner ? owner?.name ?? 'Utilisateur' : claimant?.name ?? 'Utilisateur',
      recipient: finderIsOwner ? claim.claimant : item.owner,
      recipientName: finderIsOwner ? claimant?.name ?? 'Utilisateur' : owner?.name ?? 'Utilisateur',
      confirmedAt,
    };
    item.isClosed = true;
    await item.save();
    await claim.save();
    await recordActivity({
      type: 'item.returned',
      actorId: userId,
      summary: `Objet retrouvé : « ${item.title} »`,
      targetType: 'item',
      targetId: item.id,
    });
    await recordActivity({
      type: 'claim.returned',
      actorId: userId,
      summary: `Restitution confirmée pour « ${item.title} »`,
      targetType: 'claim',
      targetId: claim.id,
    });
    void sendPushToUser(otherId, {
      title: 'Restitution confirmée',
      body: `La remise de « ${item.title} » est confirmée par les deux personnes.`,
    }, { type: 'item_returned', claimId: claim.id, itemId: item.id });
    return claim;
  }

  await claim.save();
  await recordActivity({
    type: 'claim.returned',
    actorId: userId,
    summary: `A confirmé la remise de « ${item.title} »`,
    targetType: 'claim',
    targetId: claim.id,
  });
  void sendPushToUser(otherId, {
    title: 'Confirmation de restitution',
    body: `L’autre participant confirme la remise de « ${item.title} ». Confirmez à votre tour quand vous l’avez reçu/remis.`,
  }, { type: 'return_confirmation', claimId: claim.id, itemId: item.id });
  return claim;
}

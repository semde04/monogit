import { isValidObjectId } from 'mongoose';
import { AppError } from '../../shared/errors.ts';
import { ItemModel } from '../items/item.model.ts';
import { ClaimModel } from '../claims/claim.model.ts';
import { MessageModel } from './message.model.ts';
import type { CreateMessageInput } from './message.schemas.ts';

async function assertClaimParticipant(claimId: string, userId: string): Promise<void> {
  if (!isValidObjectId(claimId)) {
    throw new AppError('Réclamation introuvable.', 404, 'CLAIM_NOT_FOUND');
  }
  const claim = await ClaimModel.findById(claimId).select('item claimant status');
  if (!claim) throw new AppError('Réclamation introuvable.', 404, 'CLAIM_NOT_FOUND');

  const isClaimant = claim.claimant.toString() === userId;
  const ownsItem = await ItemModel.exists({ _id: claim.item, owner: userId });
  if (!isClaimant && !ownsItem) {
    throw new AppError('Réclamation introuvable.', 404, 'CLAIM_NOT_FOUND');
  }
  if (!['accepted', 'returned'].includes(claim.status)) {
    throw new AppError('La discussion sera disponible après acceptation de la réclamation.', 409, 'CLAIM_NOT_ACCEPTED');
  }
}

export async function listMessages(claimId: string, userId: string) {
  await assertClaimParticipant(claimId, userId);
  return MessageModel.find({ claim: claimId })
    .populate('sender', 'name')
    .sort({ createdAt: 1 })
    .lean();
}

export async function createMessage(
  claimId: string,
  senderId: string,
  input: CreateMessageInput,
) {
  await assertClaimParticipant(claimId, senderId);
  const claim = await ClaimModel.findById(claimId).select('status');
  if (claim?.status !== 'accepted') {
    throw new AppError('Cette conversation est en lecture seule car l’objet a été restitué.', 409, 'CONVERSATION_CLOSED');
  }
  return MessageModel.create({
    claim: claimId,
    sender: senderId,
    body: input.text,
  });
}

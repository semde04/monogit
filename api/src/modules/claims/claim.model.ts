import { model, Schema, type InferSchemaType } from 'mongoose';

const claimSchema = new Schema(
  {
    item: { type: Schema.Types.ObjectId, ref: 'Item', required: true, index: true },
    claimant: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    proofAnswer: { type: String, required: true, trim: true, maxlength: 2000 },
    status: { type: String, enum: ['pending', 'accepted', 'rejected', 'returned'], default: 'pending' },
    itemTitleSnapshot: { type: String, required: true },
    itemTypeSnapshot: { type: String, enum: ['FOUND', 'LOST'], required: true },
    itemOwnerSnapshot: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    ownerConfirmedReturnAt: { type: Date },
    claimantConfirmedReturnAt: { type: Date },
    returnedAt: { type: Date },
    returnReceipt: {
      itemTitle: { type: String },
      itemType: { type: String, enum: ['FOUND', 'LOST'] },
      finder: { type: Schema.Types.ObjectId, ref: 'User' },
      finderName: { type: String },
      recipient: { type: Schema.Types.ObjectId, ref: 'User' },
      recipientName: { type: String },
      confirmedAt: { type: Date },
    },
  },
  { timestamps: true },
);

export type Claim = InferSchemaType<typeof claimSchema>;
export const ClaimModel = model('Claim', claimSchema);

import { model, Schema, type InferSchemaType } from 'mongoose';

const claimSchema = new Schema(
  {
    item: { type: Schema.Types.ObjectId, ref: 'Item', required: true, index: true },
    claimant: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    message: { type: String, required: true, trim: true, maxlength: 2000 },
    status: { type: String, enum: ['pending', 'accepted', 'rejected'], default: 'pending' },
  },
  { timestamps: true },
);

export type Claim = InferSchemaType<typeof claimSchema>;
export const ClaimModel = model('Claim', claimSchema);

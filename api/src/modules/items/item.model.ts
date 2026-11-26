import { model, Schema, type InferSchemaType } from 'mongoose';

const itemSchema = new Schema(
  {
    title: { type: String, required: true, trim: true, maxlength: 160 },
    description: { type: String, required: true, trim: true, maxlength: 5000 },
    category: { type: String, required: true, trim: true },
    location: { type: String, required: true, trim: true },
    type: { type: String, enum: ['FOUND', 'LOST'], required: true, index: true },
    proofQuestion: { type: String, trim: true, maxlength: 500 },
    imageData: { type: String, maxlength: 800_000 },
    isClosed: { type: Boolean, default: false, index: true },
    isRemoved: { type: Boolean, default: false, index: true },
    moderationReason: { type: String, trim: true, maxlength: 300 },
    moderatedBy: { type: Schema.Types.ObjectId, ref: 'User' },
    moderatedAt: { type: Date },
    owner: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  },
  { timestamps: true },
);

itemSchema.index({ isRemoved: 1, isClosed: 1, createdAt: -1 });
itemSchema.index({ category: 1, type: 1, createdAt: -1 });

export type Item = InferSchemaType<typeof itemSchema>;
export const ItemModel = model('Item', itemSchema);

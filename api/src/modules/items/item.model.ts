import { model, Schema, type InferSchemaType } from 'mongoose';

const itemSchema = new Schema(
  {
    title: { type: String, required: true, trim: true, maxlength: 160 },
    description: { type: String, required: true, trim: true, maxlength: 5000 },
    category: { type: String, required: true, trim: true },
    location: { type: String, required: true, trim: true },
    type: { type: String, enum: ['FOUND', 'LOST'], required: true, index: true },
    proofQuestion: { type: String, trim: true, maxlength: 500 },
    isClosed: { type: Boolean, default: false, index: true },
    owner: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  },
  { timestamps: true },
);

export type Item = InferSchemaType<typeof itemSchema>;
export const ItemModel = model('Item', itemSchema);

import { model, Schema, type InferSchemaType } from 'mongoose';

const itemSchema = new Schema(
  {
    title: { type: String, required: true, trim: true, maxlength: 160 },
    description: { type: String, required: true, trim: true, maxlength: 5000 },
    category: { type: String, required: true, trim: true },
    location: { type: String, required: true, trim: true },
    status: { type: String, enum: ['lost', 'found'], required: true },
    owner: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  },
  { timestamps: true },
);

export type Item = InferSchemaType<typeof itemSchema>;
export const ItemModel = model('Item', itemSchema);

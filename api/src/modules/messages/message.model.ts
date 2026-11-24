import { model, Schema, type InferSchemaType } from 'mongoose';

const messageSchema = new Schema(
  {
    claim: { type: Schema.Types.ObjectId, ref: 'Claim', required: true, index: true },
    sender: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    body: { type: String, required: true, trim: true, maxlength: 5000 },
  },
  { timestamps: true },
);

export type Message = InferSchemaType<typeof messageSchema>;
export const MessageModel = model('Message', messageSchema);

import { model, Schema } from 'mongoose';

const consumedRefreshTokenSchema = new Schema({
  userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  tokenHash: { type: String, required: true, unique: true },
  expiresAt: { type: Date, required: true, expires: 0 },
});

export const ConsumedRefreshTokenModel = model('ConsumedRefreshToken', consumedRefreshTokenSchema);

import { model, Schema } from 'mongoose';

export const activityTypes = [
  'auth.register',
  'auth.login',
  'item.created',
  'item.updated',
  'item.closed',
  'item.deleted',
  'claim.created',
  'claim.status',
  'claim.returned',
  'message.sent',
  'admin.moderation',
] as const;

export type ActivityType = (typeof activityTypes)[number];

const activitySchema = new Schema(
  {
    type: { type: String, required: true, enum: activityTypes },
    actorId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    actorName: { type: String, required: true },
    summary: { type: String, required: true, maxlength: 300 },
    targetType: { type: String },
    targetId: { type: String },
  },
  { timestamps: true },
);

activitySchema.index({ createdAt: -1 });
activitySchema.index({ type: 1, createdAt: -1 });
activitySchema.index({ createdAt: 1 }, { expireAfterSeconds: 180 * 24 * 60 * 60 });

export const ActivityModel = model('Activity', activitySchema);

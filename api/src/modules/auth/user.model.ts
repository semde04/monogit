import { model, Schema, type InferSchemaType } from 'mongoose';

const userSchema = new Schema(
  {
    name: { type: String, required: true, trim: true, maxlength: 100 },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    matricule: {
      type: String,
      trim: true,
      uppercase: true,
      unique: true,
      sparse: true,
    },
    firebaseInstallationIds: { type: [String], default: [], select: false },
    passwordHash: { type: String, required: true, select: false },
    role: { type: String, enum: ['user', 'admin'], default: 'user' },
    isSuspended: { type: Boolean, default: false, index: true },
    suspensionReason: { type: String, trim: true, maxlength: 300 },
    suspendedBy: { type: Schema.Types.ObjectId, ref: 'User' },
    suspendedAt: { type: Date },
  },
  { timestamps: true },
);

export type User = InferSchemaType<typeof userSchema>;
export const UserModel = model('User', userSchema);

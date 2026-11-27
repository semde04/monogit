import { UserModel } from '../auth/user.model.ts';
import { ActivityModel, type ActivityType } from './activity.model.ts';
import type { PaginationInput } from '../../shared/pagination.ts';

type ActivityEntry = {
  type: ActivityType;
  actorId: string;
  summary: string;
  targetType?: string;
  targetId?: string;
};

export async function recordActivity(entry: ActivityEntry): Promise<void> {
  try {
    const actor = await UserModel.findById(entry.actorId).select('name').lean();
    await ActivityModel.create({
      ...entry,
      actorName: actor?.name ?? 'Utilisateur',
    });
  } catch {
    return;
  }
}

export async function listActivity(
  pagination: PaginationInput,
  type?: ActivityType,
) {
  const filter = type ? { type } : {};
  const [activities, total] = await Promise.all([
    ActivityModel.find(filter)
      .sort({ createdAt: -1 })
      .skip((pagination.page - 1) * pagination.limit)
      .limit(pagination.limit)
      .lean(),
    ActivityModel.countDocuments(filter),
  ]);
  return { activities, total };
}

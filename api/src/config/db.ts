import mongoose from 'mongoose';
import { env } from './env.ts';
import { logger } from './logger.ts';

export async function connectDatabase(): Promise<void> {
  await mongoose.connect(env.MONGO_URI);
  logger.info({ host: mongoose.connection.host }, 'MongoDB connected');
}

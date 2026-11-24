import { app } from './app.ts';
import { connectDatabase } from './config/db.ts';
import { env } from './config/env.ts';
import { logger } from './config/logger.ts';

async function startServer(): Promise<void> {
  await connectDatabase();
  app.listen(env.PORT, () => {
    logger.info({ port: env.PORT, environment: env.NODE_ENV }, 'API started');
  });
}

void startServer().catch((error: unknown) => {
  logger.fatal({ error }, 'API failed to start');
  process.exitCode = 1;
});

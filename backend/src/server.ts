import { buildApp } from './app.js';
import { loadConfig } from './config.js';
import { PgDb, type Db } from './db.js';
import { createEmailSender } from './email.js';
import { runCommunityJobs, runCommunityRetention } from './jobs/community.js';
import { runRetention } from './jobs/retention.js';
import { createLogger } from './logging.js';
import { migrate } from './migrate.js';
import { RateLimiter } from './rateLimit.js';

async function main(): Promise<void> {
  const config = loadConfig(process.env);
  const logger = createLogger(config);

  let db: Db;
  if (config.databaseUrl) {
    db = new PgDb(config.databaseUrl);
  } else {
    // Local development with no DATABASE_URL: an in-memory database that
    // disappears on exit. loadConfig() already refused this in production.
    const { PgliteDb } = await import('./dev/pglite.js');
    db = await PgliteDb.create();
    await migrate(db);
    logger.warn('no DATABASE_URL: using a throwaway in-memory database');
  }

  const app = await buildApp({
    deps: {
      config,
      db,
      email: createEmailSender(config, logger),
      limiter: new RateLimiter(),
      now: () => new Date(),
    },
    logger,
  });

  const timer = setInterval(() => {
    runRetention(db, new Date()).then(
      (r) => logger.info({ removed: r }, 'retention run'),
      (err: unknown) => logger.error({ err: String(err) }, 'retention failed'),
    );
  }, 3_600_000);
  timer.unref();

  const jobs = setInterval(() => {
    runCommunityJobs(db, new Date()).then(
      (r) => logger.info({ done: r }, 'community jobs'),
      (err: unknown) => logger.error({ err: String(err) }, 'community jobs failed'),
    );
  }, 600_000);
  jobs.unref();
  const community = setInterval(() => {
    runCommunityRetention(db, new Date()).then(
      (r) => logger.info({ removed: r }, 'community retention run'),
      (err: unknown) => logger.error({ err: String(err) }, 'community retention failed'),
    );
  }, 3_600_000);
  community.unref();

  const stop = async (signal: string) => {
    logger.info({ signal }, 'shutting down');
    clearInterval(timer);
    clearInterval(jobs);
    clearInterval(community);
    await app.close();
    await db.close();
    process.exit(0);
  };
  process.on('SIGTERM', () => void stop('SIGTERM'));
  process.on('SIGINT', () => void stop('SIGINT'));

  await app.listen({ port: config.port, host: config.host });
}

main().catch((err: unknown) => {
  process.stderr.write(`${JSON.stringify({ msg: 'startup failed', error: String(err) })}\n`);
  process.exit(1);
});

import { createHash } from 'node:crypto';
import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { PgDb, type Db } from './db.js';
import { loadConfig } from './config.js';

const here = path.dirname(fileURLToPath(import.meta.url));

/** backend/migrations, both when run from src/ (tsx) and from dist/ (node). */
export const MIGRATIONS_DIR = path.resolve(here, '..', 'migrations');

export interface MigrationResult {
  applied: string[];
  skipped: string[];
}

/**
 * Applies every migrations/NNNN_name.sql not yet recorded, in filename order,
 * each in its own transaction. A migration that was already applied and has
 * since been edited is an error (checksum mismatch): add a new file instead.
 */
export async function migrate(db: Db, dir: string = MIGRATIONS_DIR): Promise<MigrationResult> {
  const files = (await readdir(dir)).filter((f) => /^\d{4}_[a-z0-9_]+\.sql$/.test(f)).sort();
  return db.withLock(async () => {
    await db.exec(`
      create table if not exists schema_migrations (
        name        text primary key,
        checksum    text not null,
        applied_at  timestamptz not null default now()
      )`);
    const done = new Map<string, string>();
    const existing = await db.query<{ name: string; checksum: string }>(
      'select name, checksum from schema_migrations',
    );
    for (const r of existing.rows) done.set(r.name, r.checksum);

    const result: MigrationResult = { applied: [], skipped: [] };
    for (const file of files) {
      const sql = await readFile(path.join(dir, file), 'utf8');
      const checksum = createHash('sha256').update(sql).digest('hex');
      const prior = done.get(file);
      if (prior !== undefined) {
        if (prior !== checksum) {
          throw new Error(`Migration ${file} was edited after it was applied (checksum mismatch)`);
        }
        result.skipped.push(file);
        continue;
      }
      await db.tx(async (q) => {
        await q.exec(sql);
        await q.query('insert into schema_migrations (name, checksum) values ($1, $2)', [
          file,
          checksum,
        ]);
      });
      result.applied.push(file);
    }
    return result;
  });
}

async function main(): Promise<void> {
  const config = loadConfig(process.env);
  if (!config.databaseUrl) throw new Error('DATABASE_URL is required to migrate');
  const db = new PgDb(config.databaseUrl, 2);
  try {
    const r = await migrate(db);
    process.stdout.write(
      `${JSON.stringify({ msg: 'migrations', applied: r.applied, skipped: r.skipped.length })}\n`,
    );
  } finally {
    await db.close();
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch((err: unknown) => {
    process.stderr.write(`${JSON.stringify({ msg: 'migration failed', error: String(err) })}\n`);
    process.exit(1);
  });
}

import pg from 'pg';

/**
 * The only database surface the application code sees. Two implementations:
 *  - PgDb: node-postgres against a real PostgreSQL (Render, CI service
 *    container, local).
 *  - PgliteDb (src/dev/pglite.ts): in-memory PostgreSQL compiled to WASM, so
 *    the test suite and local development need no server.
 */
export type Row = Record<string, unknown>;

export interface QueryResult<T extends object = Row> {
  rows: T[];
  rowCount: number;
}

export interface Queryable {
  query<T extends object = Row>(sql: string, params?: unknown[]): Promise<QueryResult<T>>;
  /** Run one or more statements with no parameters (migrations). */
  exec(sql: string): Promise<void>;
}

export interface Db extends Queryable {
  readonly kind: 'pg' | 'pglite';
  /** Runs [fn] inside a transaction; rolls back if it throws. */
  tx<T>(fn: (q: Queryable) => Promise<T>): Promise<T>;
  /** Runs [fn] while holding a cross-process lock (used by migrations). */
  withLock<T>(fn: () => Promise<T>): Promise<T>;
  close(): Promise<void>;
}

const MIGRATION_LOCK_KEY = 7_201_605;

export class PgDb implements Db {
  readonly kind = 'pg' as const;
  private readonly pool: pg.Pool;

  constructor(connectionString: string, max = 10) {
    this.pool = new pg.Pool({ connectionString, max, idleTimeoutMillis: 30_000 });
    // An idle client erroring must not crash the process.
    this.pool.on('error', () => undefined);
  }

  async query<T extends object = Row>(sql: string, params: unknown[] = []): Promise<QueryResult<T>> {
    const r = await this.pool.query(sql, params);
    return { rows: r.rows as T[], rowCount: r.rowCount ?? 0 };
  }

  async exec(sql: string): Promise<void> {
    await this.pool.query(sql);
  }

  async tx<T>(fn: (q: Queryable) => Promise<T>): Promise<T> {
    const client = await this.pool.connect();
    const q: Queryable = {
      async query<R extends object = Row>(sql: string, params: unknown[] = []) {
        const r = await client.query(sql, params);
        return { rows: r.rows as R[], rowCount: r.rowCount ?? 0 };
      },
      async exec(sql: string) {
        await client.query(sql);
      },
    };
    try {
      await client.query('begin');
      const out = await fn(q);
      await client.query('commit');
      return out;
    } catch (err) {
      try {
        await client.query('rollback');
      } catch {
        // The original error is the one that matters.
      }
      throw err;
    } finally {
      client.release();
    }
  }

  async withLock<T>(fn: () => Promise<T>): Promise<T> {
    const client = await this.pool.connect();
    try {
      await client.query('select pg_advisory_lock($1)', [MIGRATION_LOCK_KEY]);
      return await fn();
    } finally {
      try {
        await client.query('select pg_advisory_unlock($1)', [MIGRATION_LOCK_KEY]);
      } finally {
        client.release();
      }
    }
  }

  async close(): Promise<void> {
    await this.pool.end();
  }
}

/** SQLSTATE of an error thrown by either driver, if any. */
export function sqlState(err: unknown): string | undefined {
  if (typeof err === 'object' && err !== null && 'code' in err) {
    const code = (err as { code?: unknown }).code;
    if (typeof code === 'string') return code;
  }
  return undefined;
}

export const UNIQUE_VIOLATION = '23505';
export const CHECK_VIOLATION = '23514';

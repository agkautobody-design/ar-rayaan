import { PGlite } from '@electric-sql/pglite';
import type { Db, Queryable, QueryResult, Row } from '../db.js';

/**
 * In-memory PostgreSQL (WASM). Used by the test suite and for local
 * development without a server. Imported dynamically so production images,
 * which omit dev dependencies, never load it.
 */
export class PgliteDb implements Db {
  readonly kind = 'pglite' as const;
  private constructor(private readonly db: PGlite) {}

  static async create(): Promise<PgliteDb> {
    const db = new PGlite();
    await db.waitReady;
    return new PgliteDb(db);
  }

  async query<T extends object = Row>(sql: string, params: unknown[] = []): Promise<QueryResult<T>> {
    const r = await this.db.query<T>(sql, params);
    return { rows: r.rows, rowCount: r.rows.length > 0 ? r.rows.length : (r.affectedRows ?? 0) };
  }

  async exec(sql: string): Promise<void> {
    await this.db.exec(sql);
  }

  async tx<T>(fn: (q: Queryable) => Promise<T>): Promise<T> {
    return this.db.transaction(async (t) => {
      const q: Queryable = {
        async query<R extends object = Row>(sql: string, params: unknown[] = []) {
          const r = await t.query<R>(sql, params);
          return { rows: r.rows, rowCount: r.rows.length > 0 ? r.rows.length : (r.affectedRows ?? 0) };
        },
        async exec(sql: string) {
          await t.exec(sql);
        },
      };
      return fn(q);
    });
  }

  async withLock<T>(fn: () => Promise<T>): Promise<T> {
    return fn();
  }

  async close(): Promise<void> {
    await this.db.close();
  }
}

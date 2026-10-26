import type { Db } from '../db.js';

/**
 * Deletes data we no longer need. Runs hourly inside the service (one
 * instance) and can be invoked by a test. Windows are the ones promised in
 * the plan, section 8 (data minimisation).
 */
export interface RetentionResult {
  authCodes: number;
  sessions: number;
  invites: number;
  notifications: number;
}

const DAY = 86_400_000;

export async function runRetention(db: Db, now: Date): Promise<RetentionResult> {
  const ago = (days: number) => new Date(now.getTime() - days * DAY);
  const n = async (sql: string, p: unknown[]) => (await db.query(sql, p)).rowCount;
  return {
    // Sign-in codes: a day is plenty to investigate abuse.
    authCodes: await n('delete from auth_codes where created_at < $1', [ago(1)]),
    sessions: await n(
      'delete from sessions where expires_at < $1 or (revoked_at is not null and revoked_at < $2)',
      [ago(7), ago(7)],
    ),
    invites: await n('delete from invites where expires_at < $1 or revoked_at < $1', [ago(30)]),
    notifications: await n(
      'delete from notifications where created_at < $1 or (read_at is not null and read_at < $2)',
      [ago(90), ago(14)],
    ),
  };
}

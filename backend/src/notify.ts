import type { Queryable } from './db.js';

/** Payloads hold ids and short codes only; the client writes the words. */
export async function notify(
  q: Queryable,
  userId: string,
  kind: string,
  payload: Record<string, unknown>,
): Promise<void> {
  await q.query('insert into notifications (user_id, kind, payload) values ($1, $2, $3::jsonb)', [
    userId,
    kind,
    JSON.stringify(payload),
  ]);
}

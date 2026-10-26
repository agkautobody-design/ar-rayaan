import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import type { Deps } from './context.js';
import { unauthorized } from './errors.js';
import { limit, requireAuth } from './guards.js';
import { toIso } from './profiles.js';
import { parse } from './validate.js';

/**
 * In-app notifications, read by polling. A notification is a short code and
 * ids; the app writes the words. Nothing here carries a name, a message, a
 * reporter or a reaction: there are no notifications for "helpful" marks, so
 * nothing nudges people back to count them.
 */

const listQuery = z.object({
  after: z.string().datetime().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(50),
  unreadOnly: z.enum(['true', 'false']).optional(),
});

const readBody = z.object({
  ids: z.array(z.string().regex(/^[0-9a-f-]{36}$/)).max(100).optional(),
  all: z.literal(true).optional(),
});

export async function registerNotificationRoutes(app: FastifyInstance, deps: Deps): Promise<void> {
  const { db } = deps;
  const auth = requireAuth(deps, { allowRestricted: true });
  // Polling every 30 seconds is 120 requests an hour; leave room for two tabs.
  const poll = limit(deps, { name: 'notif_poll', max: 300, windowSec: 3600, by: 'user' });

  app.get('/v1/notifications', { preHandler: [auth, poll] }, async (request) => {
    const a = request.auth;
    if (!a) throw unauthorized();
    const q = parse(listQuery, request.query);
    const rows = await db.query<{
      id: string;
      kind: string;
      payload: Record<string, unknown>;
      read_at: Date | null;
      created_at: Date;
    }>(
      `select id, kind, payload, read_at, created_at from notifications
        where user_id = $1
          and ($2::timestamptz is null or created_at > $2::timestamptz)
          and ($3::boolean is not true or read_at is null)
        order by created_at desc, id
        limit $4`,
      [a.userId, q.after ?? null, q.unreadOnly === 'true', q.limit],
    );
    const unread = await db.query<{ n: string }>(
      'select count(*)::text as n from notifications where user_id = $1 and read_at is null',
      [a.userId],
    );
    return {
      serverTime: deps.now().toISOString(),
      unreadCount: Number(unread.rows[0]?.n ?? '0'),
      notifications: rows.rows.map((n) => ({
        id: n.id,
        kind: n.kind,
        payload: n.payload,
        readAt: n.read_at ? toIso(n.read_at) : null,
        createdAt: toIso(n.created_at),
      })),
    };
  });

  app.post(
    '/v1/notifications/read',
    { preHandler: [auth, limit(deps, { name: 'notif_read', max: 120, windowSec: 3600, by: 'user' })] },
    async (request, reply) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      const body = parse(readBody, request.body);
      const now = deps.now();
      if (body.all) {
        await db.query('update notifications set read_at = $2 where user_id = $1 and read_at is null', [a.userId, now]);
      } else if (body.ids && body.ids.length > 0) {
        await db.query(
          'update notifications set read_at = $3 where user_id = $1 and id = any($2::uuid[]) and read_at is null',
          [a.userId, body.ids, now],
        );
      }
      void reply.code(204);
    },
  );
}

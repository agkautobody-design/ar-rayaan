import type { ZodType } from 'zod';
import { badRequest } from './errors.js';

/** Parses [data]; on failure throws a 400 listing field paths, never values. */
export function parse<T>(schema: ZodType<T>, data: unknown): T {
  const r = schema.safeParse(data ?? {});
  if (r.success) return r.data;
  throw badRequest('validation_failed', 'Some fields are missing or not valid.', {
    fields: r.error.issues.map((i) => ({ path: i.path.join('.'), problem: i.code })),
  });
}

export const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

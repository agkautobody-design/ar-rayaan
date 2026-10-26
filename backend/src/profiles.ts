import type { Queryable, Row } from './db.js';
import { forbidden, notFound } from './errors.js';
import type { ProfileKind } from './policy/age.js';
import { UUID_RE } from './validate.js';

export interface ProfileRow extends Row {
  id: string;
  kind: ProfileKind;
  user_id: string | null;
  managed_by: string | null;
  display_name: string;
  handle: string | null;
  bio: string | null;
  visibility: 'private' | 'handle' | 'community';
  created_at: Date;
  erased_at: Date | null;
}

export const PROFILE_COLUMNS =
  'id, kind, user_id, managed_by, display_name, handle, bio, visibility, created_at, erased_at';

export function toIso(d: Date | string): string {
  return new Date(d).toISOString();
}

export function mapProfile(p: ProfileRow) {
  return {
    id: p.id,
    kind: p.kind,
    displayName: p.display_name,
    handle: p.handle,
    bio: p.bio,
    visibility: p.visibility,
    createdAt: toIso(p.created_at),
  };
}

export async function ownAdultProfile(q: Queryable, userId: string): Promise<ProfileRow | undefined> {
  const r = await q.query<ProfileRow>(
    `select ${PROFILE_COLUMNS} from profiles where user_id = $1 and kind = 'adult'`,
    [userId],
  );
  return r.rows[0];
}

/**
 * The profile a request acts as: the caller's own adult profile by default, or
 * a child/teen profile the caller manages when [profileId] names one. Anything
 * else is "not found" (no hint that the id exists).
 */
export async function actingProfile(
  q: Queryable,
  userId: string,
  profileId?: string,
): Promise<ProfileRow> {
  if (profileId === undefined) {
    const own = await ownAdultProfile(q, userId);
    if (!own) throw forbidden('profile_required', 'Create your profile first.');
    return own;
  }
  if (!UUID_RE.test(profileId)) throw notFound();
  const r = await q.query<ProfileRow>(
    `select ${PROFILE_COLUMNS} from profiles
      where id = $1 and (user_id = $2 or managed_by = $2) and erased_at is null`,
    [profileId, userId],
  );
  const p = r.rows[0];
  if (!p) throw notFound();
  return p;
}

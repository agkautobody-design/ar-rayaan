/**
 * What each kind of profile may do. This is the single place the child-safety
 * rules live; routes ask these functions rather than re-deciding. The rules
 * follow docs/product/backend_community_plan.md section 8.
 */

export type ProfileKind = 'adult' | 'teen' | 'child';

export interface Capabilities {
  /** Can have a handle, a bio, and be found by exact handle. */
  publicProfile: boolean;
  /** Can send or receive a friend request by handle. */
  friendRequestsByHandle: boolean;
  /** Can post in forums. */
  forums: boolean;
  /** Can organise or RSVP to a meet-up on their own (a minor needs a guardian RSVP). */
  meetupsOwnRsvp: boolean;
  /** Can send direct messages. (No profile can in phase 1.) */
  directMessages: boolean;
  /** Friends are limited to other minors whose guardians approved. */
  friendsNeedGuardian: boolean;
}

const ADULT: Capabilities = {
  publicProfile: true,
  friendRequestsByHandle: true,
  forums: true,
  meetupsOwnRsvp: true,
  directMessages: false,
  friendsNeedGuardian: false,
};

const MINOR: Capabilities = {
  publicProfile: false,
  friendRequestsByHandle: false,
  forums: false,
  meetupsOwnRsvp: false,
  directMessages: false,
  friendsNeedGuardian: true,
};

export function capabilities(kind: ProfileKind): Capabilities {
  return kind === 'adult' ? ADULT : MINOR;
}

export const isMinor = (kind: ProfileKind): boolean => kind !== 'adult';

/** Friendships never cross the adult/minor line (also enforced by a DB trigger). */
export function mayBeFriends(a: ProfileKind, b: ProfileKind): boolean {
  return isMinor(a) === isMinor(b);
}

export const MAX_CHILD_PROFILES_PER_GUARDIAN = 8;
export const MAX_FRIENDS_ADULT = 200;
export const MAX_FRIENDS_MINOR = 30;

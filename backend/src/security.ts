import { createHash, createHmac, randomBytes, randomInt, timingSafeEqual } from 'node:crypto';

/** Keyed hash with a label so the same input hashed for two purposes differs. */
export function keyedHash(pepper: string, label: string, value: string): string {
  return createHmac('sha256', pepper).update(`${label}\u0000${value}`).digest('hex');
}

export function normaliseEmail(raw: string): string {
  return raw.normalize('NFKC').trim().toLowerCase();
}

export function emailHash(pepper: string, email: string): string {
  return keyedHash(pepper, 'email', normaliseEmail(email));
}

/** Short stable id for logs: enough to correlate, not enough to reverse. */
export function logId(pepper: string, id: string): string {
  return keyedHash(pepper, 'log', id).slice(0, 12);
}

export function safeEqualHex(a: string, b: string): boolean {
  const ba = Buffer.from(a, 'hex');
  const bb = Buffer.from(b, 'hex');
  return ba.length === bb.length && ba.length > 0 && timingSafeEqual(ba, bb);
}

export const SESSION_TOKEN_PREFIX = 'ar_';

export function newSessionToken(): string {
  return SESSION_TOKEN_PREFIX + randomBytes(32).toString('base64url');
}

/** Bearer tokens are 256-bit random, so a plain SHA-256 is enough. */
export function hashToken(token: string): string {
  return createHash('sha256').update(token).digest('hex');
}

/** Six digits, uniformly random. */
export function newSignInCode(): string {
  return String(randomInt(0, 1_000_000)).padStart(6, '0');
}

export function codeHash(pepper: string, email: string, code: string): string {
  return keyedHash(pepper, 'signin', `${normaliseEmail(email)}\u0000${code}`);
}

/** No 0/O/1/I/L/U so a code read aloud or typed from a screenshot survives. */
const INVITE_ALPHABET = '23456789ABCDEFGHJKMNPQRSTVWXYZ';

/** Ten characters shown as XXXXX-XXXXX (about 49 bits). */
export function newInviteCode(): string {
  let s = '';
  for (let i = 0; i < 10; i += 1) s += INVITE_ALPHABET[randomInt(0, INVITE_ALPHABET.length)];
  return `${s.slice(0, 5)}-${s.slice(5)}`;
}

/** Upper-case and strip separators; returns null if it cannot be a code. */
export function normaliseInviteCode(raw: string): string | null {
  const s = raw.toUpperCase().replace(/[\s-]/g, '');
  if (s.length !== 10) return null;
  for (const ch of s) if (!INVITE_ALPHABET.includes(ch)) return null;
  return s;
}

export function inviteCodeHash(pepper: string, normalised: string): string {
  return keyedHash(pepper, 'invite', normalised);
}

/**
 * Moderation numbers in one place. All of them are DRAFT proposals for the
 * owner to set (docs/product/moderation_handbook.md).
 */
import type { ReportReasonCode } from './content.js';

export const STRIKE_LIFETIME_DAYS = 90;

/** Active strike points at which an automatic step is taken. */
export const STRIKE_LADDER: ReadonlyArray<{
  points: number;
  sanction: 'mute' | 'suspend';
  /** null = until an admin decides. */
  days: number | null;
}> = [
  { points: 3, sanction: 'mute', days: 7 },
  { points: 6, sanction: 'suspend', days: 7 },
  // Never an automatic permanent ban: an admin reads the case first.
  { points: 10, sanction: 'suspend', days: null },
];

/** Points a moderator may give in one action. */
export const MAX_STRIKE_MODERATOR = 5;
export const MAX_STRIKE_ADMIN = 10;
export const DEFAULT_STRIKES: Readonly<Record<string, number>> = { warn: 1, remove: 2 };

/** Longest mute a moderator can set; admins can go further. */
export const MAX_MUTE_DAYS_MODERATOR = 7;
export const MAX_MUTE_DAYS_ADMIN = 30;
export const MAX_SUSPEND_DAYS = 365;

/** Distinct reporters that hide something until a person reviews it. */
export const AUTO_HIDE_REPORTERS = 3;

export const REPORT_PRIORITY: Readonly<Record<ReportReasonCode, number>> = {
  child_safety: 100,
  sexual: 40,
  harassment: 20,
  hate: 20,
  abuse: 15,
  sectarian: 15,
  privacy: 15,
  religious_misinformation: 10,
  scam: 10,
  spam: 5,
  other: 5,
};

/** A post may be edited by its author for this long. */
export const EDIT_WINDOW_MINUTES = 15;
/** The same text by the same person within this window is refused. */
export const DUPLICATE_WINDOW_MINUTES = 10;
/** Appeals must be made within this many days of the action. */
export const APPEAL_WINDOW_DAYS = 30;

/** An account is "new" for the stricter limits and link rules. */
export const NEW_ACCOUNT_DAYS = 7;
export const NEW_ACCOUNT_MIN_APPROVED_POSTS = 3;

export const REPORT_REASONS = [
  'abuse', 'harassment', 'hate', 'sectarian', 'religious_misinformation', 'sexual',
  'child_safety', 'spam', 'privacy', 'scam', 'other',
] as const satisfies readonly ReportReasonCode[];

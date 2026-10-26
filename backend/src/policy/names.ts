/**
 * Display-name and handle rules. These mirror the app's Majlis rules
 * (lib/features/majlis/domain/majlis_policy.dart) so a name accepted in one
 * place is accepted in the other, and so nobody can pose as the app, its
 * assistants, staff, or a scholar. Keep the two in step.
 */

export const NAME_MIN = 2;
export const NAME_MAX = 30;

/** ASCII letters and digits, space, . _ ' - and Arabic-script letters. */
const NAME_CHARS = /^[A-Za-z0-9 ._'ء-ۓ-]+$/;

export const RESERVED_WORDS: ReadonlySet<string> = new Set([
  'hadi', 'sakina', 'noor', 'wasia', 'admin', 'administrator', 'moderator', 'mod',
  'staff', 'team', 'official', 'support', 'founder', 'shaykh', 'sheikh', 'sheik',
  'shaikh', 'imam', 'mufti', 'scholar', 'ustadh', 'ustaz', 'allama', 'hafiz',
]);

export const RESERVED_FRAGMENTS: readonly string[] = [
  'arrayaan', 'arrayyan', 'rayaanapp', 'arrayaanteam',
];

const FOLD: Readonly<Record<string, string>> = {
  '0': 'o', '1': 'i', '3': 'e', '4': 'a', '5': 's', '7': 't', '@': 'a', $: 's',
};

export function nameWords(name: string): string[] {
  let folded = '';
  for (const ch of name.toLowerCase()) folded += FOLD[ch] ?? ch;
  return folded.split(/[^a-z؀-ۿ]+/).filter((w) => w.length > 0);
}

function isReserved(words: string[]): boolean {
  if (words.some((w) => RESERVED_WORDS.has(w))) return true;
  const collapsed = words.join('');
  return RESERVED_FRAGMENTS.some((f) => collapsed.includes(f));
}

/** Null when [name] may be used, else a message safe to show a person. */
export function validateDisplayName(name: string): string | null {
  const t = name.trim();
  if (t.length < NAME_MIN) return `Please choose a display name of at least ${NAME_MIN} characters.`;
  if (t.length > NAME_MAX) return `Display names can be at most ${NAME_MAX} characters.`;
  if (!NAME_CHARS.test(t)) {
    return "Display names can use letters, numbers, spaces and . _ ' - only (no accents or emoji).";
  }
  if (isReserved(nameWords(t))) return 'That name is reserved. Please choose another display name.';
  return null;
}

const HANDLE_SHAPE = /^[a-z0-9_]{3,20}$/;

export function validateHandle(handle: string): string | null {
  if (!HANDLE_SHAPE.test(handle)) {
    return 'A handle is 3 to 20 lower-case letters, numbers or underscores.';
  }
  if (isReserved(nameWords(handle.replace(/_/g, ' ')))) {
    return 'That handle is reserved. Please choose another.';
  }
  return null;
}

/** A nickname for a child: letters, numbers, spaces, no reserved words. */
export function validateChildNickname(name: string): string | null {
  return validateDisplayName(name);
}

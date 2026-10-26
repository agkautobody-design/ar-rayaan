/**
 * Content filters for forum posts, meet-up text and similar free text.
 *
 * DRAFT: the built-in lists below are a starting point for the owner and a
 * scholar to review (docs/product/community_rules_draft.md). They are
 * deliberately conservative about WHAT THEY DO:
 *   - block   : the text is refused with a kind message (nothing is stored);
 *   - review  : the text is held for a moderator (a person decides);
 *   - flag    : the text is allowed but a high-priority report is filed so a
 *               moderator can look at once (used for possible risk to life).
 * Nothing here decides a religious question. Words that could be part of an
 * honest conversation (for example a question about a ruling) are never
 * blocked, only held for a person to read.
 *
 * Admins can add more rules at runtime through the `content_filters` table.
 * Patterns there are plain text (never regular expressions) so a typo cannot
 * make a filter slow or crash.
 */

export interface DbFilter {
  kind: 'block_word' | 'review_word' | 'block_link' | 'allow_domain';
  pattern: string;
}

export type ReportReasonCode =
  | 'abuse'
  | 'harassment'
  | 'hate'
  | 'sectarian'
  | 'religious_misinformation'
  | 'sexual'
  | 'child_safety'
  | 'spam'
  | 'privacy'
  | 'scam'
  | 'other';

export interface AutoReport {
  reason: ReportReasonCode;
  priority: number;
  details: string;
}

export type Verdict =
  | { kind: 'allow' }
  | { kind: 'review'; reasons: string[]; autoReport?: AutoReport }
  | { kind: 'flag'; reasons: string[]; autoReport: AutoReport; showHelp: boolean }
  | {
      kind: 'block';
      code: string;
      message: string;
      /** Filed against the author's profile when set (for example child safety). */
      autoReport?: AutoReport;
    };

export interface FilterOptions {
  /** Accounts under a week old, or with fewer than three approved posts. */
  accountIsNew: boolean;
  filters: readonly DbFilter[];
  /** meetup: homes are refused; venue: an address field, where a street address is expected. */
  surface: 'forum' | 'meetup' | 'venue' | 'profile';
}

const FOLD: Readonly<Record<string, string>> = {
  '0': 'o', '1': 'i', '3': 'e', '4': 'a', '5': 's', '7': 't', '@': 'a', $: 's', '!': 'i',
};

/** Lower-case, NFKC, drop zero-width marks, collapse whitespace. */
export function normalise(text: string): string {
  return text
    .normalize('NFKC')
    .replace(/[​-‏‪-‮⁠﻿]/g, '')
    .toLowerCase()
    .replace(/\s+/g, ' ')
    .trim();
}

/** Look-alike folding for word lists (a person writing "k@fir"). */
function fold(text: string): string {
  let out = '';
  for (const ch of text) out += FOLD[ch] ?? ch;
  return out;
}

// ---------------------------------------------------------------- patterns

const EMAIL_RE = /[a-z0-9._%+-]+\s?(@|\(at\)|\[at\])\s?[a-z0-9-]+(\.|\s?\(dot\)\s?)[a-z]{2,}/i;
const PHONE_RE = /(\+?\d[\d\s().-]{7,}\d)/;
const OFF_PLATFORM_RE =
  /\b(whats\s?app|telegram|signal app|snap\s?chat|insta(gram)?|facebook messenger|kik|wechat|viber|discord)\b|\b(dm|pm) me\b|\b(inbox|message|text|call|ring) me\b|\bcontact me (on|at|via)\b|\badd me on\b|\bmy (number|phone|email|e-mail|insta|snap)\b/;

// Homes and street addresses. Meet-ups are public venues only; the forum never
// carries anyone's address.
// An invitation to a private place, or giving one's address, is refused
// everywhere. Merely mentioning "my home" is refused only in meet-up text.
const HOME_INVITE_RE =
  /\b(come|coming|meet|meeting|gather|gathering|held|hosted|host(ing)?) (to|at|in) (my|our|a|the)? ?(home|house|flat|apartment|basement|residence|private)\b|\bat (my|our) (place|home|house)\b|\bprivate (home|house|residence|address|residential)\b|\bhouse (meet|gathering|party|visit)\b|\bmy address\b/;
const HOME_MENTION_RE =
  /\b(my|our|his|her|their) (home|house|flat|apartment|apt|basement|condo|residence)\b/;
const STREET_RE =
  /\b\d{1,5}\s+[a-z0-9.' -]{2,30}\s+(street|st|road|rd|avenue|ave|drive|dr|lane|ln|crescent|cres|court|ct|boulevard|blvd|way|place|pl)\b/;

const IMAGE_RE = /!\[|data:image|\.(jpe?g|png|gif|webp|heic|bmp)(\?|\b)/;

const URL_RE =
  /\b((?:https?:\/\/|www\.)[^\s<>"')]+|[a-z0-9-]+(?:\.[a-z0-9-]+)*\.(?:com|net|org|io|me|co|app|ly|link|info|biz|xyz|ca|uk|us|de|tv|gl|gg|to|sh|cc|ru|cn|top|site|online|click|live)(?:\/[^\s<>"')]*)?)/gi;

const BLOCKED_LINK_DOMAINS = [
  'bit.ly', 'tinyurl.com', 't.co', 'goo.gl', 'is.gd', 'cutt.ly', 'rb.gy', 'ow.ly',
  'wa.me', 'chat.whatsapp.com', 't.me', 'telegram.me', 'discord.gg', 'snapchat.com', 'instagram.com',
];

const SEXUAL_RE = /\b(porn\w*|nudes?|xxx|sex ?chat|onlyfans|hookup|hook up|sexting)\b/;
const MINOR_CONTACT_RE =
  /\b(how old are you|what('s| is) your age|send (me )?(a )?(pic|photo|selfie|picture)s?|a\/s\/l|are you (alone|home alone)|don'?t tell your (parents|mum|mom|dad))\b/;
const VIOLENCE_RE =
  /\b(kill|behead|bomb|shoot|stab|lynch|burn)\s+(them|him|her|all|every|the (jews|christians|muslims|shia|sunnis|hindus|kuffar|kaffirs))\b|\bdeath to\b|\bwe will (kill|destroy)\b/;

// Held for a person to read, never blocked.
const TAKFIR_RE =
  /\b(takfir\w*|takfeer|takfiri|kaf[iy]r|kaafir|kuffar|kufr|murtad|mushrik\w*|apostates?)\b|\b(not|no longer) (a )?(real |true )?muslims?\b|\bout of (the (fold|folds) of )?islam\b|\bleft (the fold of )?islam\b|\bgo(ing)? to (hell|jahannam)\b/;
const FATWA_RE =
  /\bfat(wa|awa|wah)s?\b|\bit (is|was|'s) (haram|halal|wajib|fard|makruh|bid'?ah)\b|\b(this|that) (is|are) (haram|halal|bid'?ah|shirk)\b|\bi (declare|rule|judge) (that )?(it|this)\b|\byou (must|have to|are obliged to) (not )?(do|pray|fast|pay)\b/;
const SECTARIAN_RE =
  /\b(wahh?abi\w*|rafid\w*|nawasib|khawarij|khariji\w*|qadiani\w*|ahmadi\w* (are|is)|bid'?ah\w*|innovators?|deviants?|grave[- ]worshipp\w*|sufi\w* (are|is) (kuffar|kafir|mushrik)|salafi\w* (are|is) (extremists?|deviants?))\b/;
const SCAM_RE =
  /\b(send (me )?money|wire (me )?money|western union|bitcoin|crypto(currency)?|forex|invest(ment)? opportunit\w*|double your (money|investment)|donate to my|zakat to (my|this)|give me your (bank|card))\b/;
const RISK_RE =
  /\b(suicid\w*|kill myself|end my life|ending it all|want to die|better off dead|self[- ]?harm\w*|hurt myself|cut myself|no reason to live)\b/;

const MAX_LINKS = 2;

// ------------------------------------------------------------------ helpers

export function linkDomain(raw: string): string {
  let s = raw.toLowerCase().replace(/^https?:\/\//, '').replace(/^www\./, '');
  s = s.split(/[/?#]/)[0] ?? '';
  return s.replace(/:\d+$/, '');
}

function domainMatches(domain: string, pattern: string): boolean {
  const p = pattern.toLowerCase().replace(/^\*\./, '').replace(/^www\./, '');
  return domain === p || domain.endsWith(`.${p}`);
}

function containsPhrase(haystack: string, folded: string, phrase: string): boolean {
  const p = normalise(phrase);
  if (p.length === 0) return false;
  return haystack.includes(p) || folded.includes(fold(p));
}

function digitCount(s: string): number {
  return (s.match(/\d/g) ?? []).length;
}

// -------------------------------------------------------------------- main

/**
 * Judges [text]. Order: hard safety blocks first, then privacy and contact
 * rules, then links, then spam shape, then "hold for a person", then "flag".
 */
export function evaluateContent(text: string, opts: FilterOptions): Verdict {
  const t = normalise(text);
  const folded = fold(t);

  // --- child safety and sexual content: refuse, and tell the moderators.
  if (MINOR_CONTACT_RE.test(t)) {
    return {
      kind: 'block',
      code: 'child_safety',
      message: 'That cannot be posted here.',
      autoReport: { reason: 'child_safety', priority: 100, details: 'auto: blocked by the child-safety filter' },
    };
  }
  if (SEXUAL_RE.test(t) || SEXUAL_RE.test(folded)) {
    return {
      kind: 'block',
      code: 'sexual_content',
      message: 'That cannot be posted here.',
      autoReport: { reason: 'sexual', priority: 40, details: 'auto: blocked by the sexual-content filter' },
    };
  }
  if (VIOLENCE_RE.test(t)) {
    return {
      kind: 'block',
      code: 'violence',
      message: 'Threats and calls for violence are never allowed.',
      autoReport: { reason: 'abuse', priority: 60, details: 'auto: blocked by the violence filter' },
    };
  }

  // --- privacy: no contact details, no talking elsewhere, no homes.
  const noDates = t.replace(/\b\d{4}-\d{2}-\d{2}\b/g, ' ');
  if (EMAIL_RE.test(t) || (PHONE_RE.test(noDates) && digitCount(noDates.match(PHONE_RE)?.[0] ?? '') >= 9)) {
    return {
      kind: 'block',
      code: 'contact_details',
      message: 'Please leave phone numbers and e-mail addresses out. They keep everyone safer when kept private.',
    };
  }
  if (OFF_PLATFORM_RE.test(t)) {
    return {
      kind: 'block',
      code: 'off_platform_contact',
      message: 'Please keep the conversation here. Asking to talk privately or on another app is not allowed.',
    };
  }
  const meetupText = opts.surface === 'meetup' || opts.surface === 'venue';
  if (HOME_INVITE_RE.test(t) || (opts.surface !== 'venue' && STREET_RE.test(t)) || (meetupText && HOME_MENTION_RE.test(t))) {
    return {
      kind: 'block',
      code: 'private_address',
      message:
        meetupText
          ? 'Meet-ups must be in a public place such as a mosque, community centre, library, halal cafe or park, never a home.'
          : 'Please do not share a home address or invite people to a private home.',
    };
  }
  if (IMAGE_RE.test(t)) {
    return {
      kind: 'block',
      code: 'no_images',
      message: 'Photos and image links are not allowed.',
    };
  }

  // --- links
  const links = [...text.matchAll(URL_RE)].map((m) => linkDomain(m[0]));
  if (links.length > MAX_LINKS) {
    return { kind: 'block', code: 'too_many_links', message: 'Please use at most two links.' };
  }
  let linkNeedsReview = false;
  for (const d of links) {
    if (
      BLOCKED_LINK_DOMAINS.some((b) => domainMatches(d, b)) ||
      opts.filters.some((f) => f.kind === 'block_link' && domainMatches(d, f.pattern))
    ) {
      return { kind: 'block', code: 'link_blocked', message: 'That link cannot be shared here.' };
    }
    const allowed = opts.filters.some((f) => f.kind === 'allow_domain' && domainMatches(d, f.pattern));
    if (!allowed) {
      if (opts.accountIsNew) {
        return {
          kind: 'block',
          code: 'links_new_account',
          message: 'New members cannot share links yet. Please try again in a few days.',
        };
      }
      linkNeedsReview = true;
    }
  }

  // --- admin block words
  for (const f of opts.filters) {
    if (f.kind === 'block_word' && containsPhrase(t, folded, f.pattern)) {
      return { kind: 'block', code: 'blocked_word', message: 'That wording is not allowed here.' };
    }
  }

  // --- spam shape
  const letters = text.replace(/[^\p{L}]/gu, '');
  const upper = letters.replace(/[^\p{Lu}]/gu, '');
  if (letters.length >= 30 && upper.length / letters.length > 0.7) {
    return { kind: 'block', code: 'shouting', message: 'Please do not write in all capitals.' };
  }
  if (/(.)\1{11,}/u.test(text)) {
    return { kind: 'block', code: 'repeated_characters', message: 'That looks like spam. Please rewrite it.' };
  }
  const words = t.split(/\s+/).filter((w) => w.length > 2);
  if (words.length >= 12) {
    const counts = new Map<string, number>();
    for (const w of words) counts.set(w, (counts.get(w) ?? 0) + 1);
    const top = Math.max(...counts.values());
    if (top / words.length > 0.5) {
      return { kind: 'block', code: 'repeated_words', message: 'That looks like spam. Please rewrite it.' };
    }
  }

  // --- hold for a person
  const reasons: string[] = [];
  let reviewReport: AutoReport | undefined;
  if (linkNeedsReview) reasons.push('link');
  if (TAKFIR_RE.test(t) || TAKFIR_RE.test(folded)) {
    reasons.push('takfir');
    reviewReport = { reason: 'sectarian', priority: 15, details: 'auto: held by the takfir filter' };
  }
  if (SECTARIAN_RE.test(t) || SECTARIAN_RE.test(folded)) {
    reasons.push('sectarian');
    reviewReport ??= { reason: 'sectarian', priority: 15, details: 'auto: held by the sectarian filter' };
  }
  if (FATWA_RE.test(t)) {
    reasons.push('ruling');
    reviewReport ??= {
      reason: 'religious_misinformation',
      priority: 10,
      details: 'auto: held by the personal-ruling filter',
    };
  }
  if (SCAM_RE.test(t)) {
    reasons.push('money');
    reviewReport ??= { reason: 'scam', priority: 10, details: 'auto: held by the money filter' };
  }
  for (const f of opts.filters) {
    if (f.kind === 'review_word' && containsPhrase(t, folded, f.pattern)) {
      reasons.push('review_word');
      break;
    }
  }
  if (reasons.length > 0) {
    return { kind: 'review', reasons, ...(reviewReport ? { autoReport: reviewReport } : {}) };
  }

  // --- allow but tell the moderators now
  if (RISK_RE.test(t) || RISK_RE.test(folded)) {
    return {
      kind: 'flag',
      reasons: ['risk'],
      showHelp: true,
      autoReport: { reason: 'other', priority: 80, details: 'auto: possible risk to life, please look now' },
    };
  }
  return { kind: 'allow' };
}

/** Both the title and the body of a thread are judged together. */
export function evaluateMany(texts: readonly string[], opts: FilterOptions): Verdict {
  return evaluateContent(texts.join('\n'), opts);
}

/** Validates a pattern an admin wants to add. Null when fine. */
export function validateFilterPattern(kind: DbFilter['kind'], pattern: string): string | null {
  const p = pattern.trim();
  if (p.length < 1 || p.length > 200) return 'A pattern is 1 to 200 characters.';
  if (kind === 'block_link' || kind === 'allow_domain') {
    if (!/^(\*\.)?[a-z0-9-]+(\.[a-z0-9-]+)+$/i.test(p)) return 'Use a domain such as example.org.';
  }
  return null;
}

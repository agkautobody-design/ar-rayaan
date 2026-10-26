import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import {
  activeCredential,
  blockedEitherWaySql,
  fileAutoReport,
  hasAcceptedRules,
  hitLimit,
  loadFilters,
  meetsStanding,
  recountThread,
  requireMember,
  activeSanction,
  type Member,
  type Standing,
} from './community.js';
import type { Deps } from './context.js';
import type { Queryable } from './db.js';
import { ApiError, conflict, forbidden, notFound, unauthorized } from './errors.js';
import { limit, requireAuth } from './guards.js';
import { notify } from './notify.js';
import { evaluateMany, type FilterOptions, type Verdict } from './policy/content.js';
import { DUPLICATE_WINDOW_MINUTES, EDIT_WINDOW_MINUTES } from './policy/moderation.js';
import { toIso } from './profiles.js';
import { parse, UUID_RE } from './validate.js';
import { COMMUNITY_RULES_VERSION } from './versions.js';
import { ownAdultProfile } from './profiles.js';
import { audit } from './context.js';

/**
 * Forums: categories, threads, posts, one gentle "helpful" reaction.
 *
 * Rules built in (docs/product/community_rules_draft.md, DRAFT):
 *  - adults only: no route here takes a child profile, and the database
 *    refuses a minor's row as well;
 *  - every post carries a label; a member's post is always "community
 *    opinion", and only a verified scholar answers in "Ask a scholar";
 *  - posts are listed oldest first and threads by recent activity. There is
 *    no popularity sort, no downvote, and a reaction count is shown to the
 *    author only, so nothing rewards outrage;
 *  - strict categories and filter hits hold a post for a moderator;
 *  - community content is never given to Hadi as guidance (it lives only in
 *    this database and nothing in the app's assistant code reads it).
 */

interface CategoryRow {
  id: string;
  slug: string;
  title: string;
  description: string;
  kind: string;
  who_can_post: Standing;
  who_can_reply: Standing;
  strict_moderation: boolean;
  rules_note: string;
  thread_count?: string;
}

const CATEGORY_COLUMNS =
  'c.id, c.slug, c.title, c.description, c.kind, c.who_can_post, c.who_can_reply, c.strict_moderation, c.rules_note';

interface ThreadRow {
  id: string;
  category_id: string;
  category_slug: string;
  category_kind: string;
  strict_moderation: boolean;
  who_can_reply: Standing;
  title: string;
  status: 'open' | 'locked' | 'hidden' | 'removed' | 'pending_review';
  pinned: boolean;
  post_count: number;
  created_at: Date;
  last_post_at: Date;
  author_profile_id: string;
  author_name: string;
  answered: boolean;
}

interface PostRow {
  id: string;
  thread_id: string;
  author_profile_id: string;
  author_name: string;
  reply_to: string | null;
  body: string;
  label: string;
  status: 'visible' | 'hidden' | 'removed' | 'pending_review';
  edited_at: Date | null;
  created_at: Date;
  scholar_org: string | null;
  helpful_count: number;
  helpful_by_me: boolean;
  blocked: boolean;
  hidden_by_me: boolean;
}

const THREAD_SELECT = `
  select t.id, t.category_id, c.slug as category_slug, c.kind as category_kind,
         c.strict_moderation, c.who_can_reply, t.title, t.status, t.pinned, t.post_count,
         t.created_at, t.last_post_at, t.author_profile_id, p.display_name as author_name,
         exists (select 1 from forum_posts fp
                  where fp.thread_id = t.id and fp.label = 'scholar_answer' and fp.status = 'visible') as answered
    from forum_threads t
    join forum_categories c on c.id = t.category_id
    join profiles p on p.id = t.author_profile_id`;

const idParam = z.object({ id: z.string().regex(/^[0-9a-f-]{36}$/) });
const slugParam = z.object({ slug: z.string().regex(/^[a-z0-9-]{2,40}$/) });
const pageQuery = z.object({
  before: z.string().datetime().optional(),
  limit: z.coerce.number().int().min(1).max(50).default(20),
});
const postsQuery = z.object({
  after: z.string().regex(/^[0-9T:.\-+Z]+~[0-9a-f-]{36}$/).optional(),
  limit: z.coerce.number().int().min(1).max(100).default(50),
});

const newThread = z.object({
  title: z.string().trim().min(4).max(140),
  body: z.string().trim().min(1).max(4000),
});
const newPost = z.object({
  body: z.string().trim().min(1).max(4000),
  replyTo: z.string().regex(/^[0-9a-f-]{36}$/).optional(),
});
const editPost = z.object({ body: z.string().trim().min(1).max(4000) });
const acceptRules = z.object({ version: z.string().max(40) });

export const isStaff = (role: string): boolean => role === 'moderator' || role === 'admin';

export function mapThread(t: ThreadRow, meProfileId: string | null) {
  return {
    id: t.id,
    categoryId: t.category_id,
    categorySlug: t.category_slug,
    title: t.title,
    authorName: t.author_name,
    authorProfileId: t.author_profile_id,
    postCount: t.post_count,
    createdAt: toIso(t.created_at),
    lastPostAt: toIso(t.last_post_at),
    pinned: t.pinned,
    locked: t.status === 'locked',
    pendingReview: t.status === 'pending_review',
    status: t.status,
    answered: t.answered,
    mine: meProfileId !== null && t.author_profile_id === meProfileId,
  };
}

export function mapPost(p: PostRow, meProfileId: string | null, staff: boolean) {
  const mine = meProfileId !== null && p.author_profile_id === meProfileId;
  const base = {
    id: p.id,
    threadId: p.thread_id,
    replyTo: p.reply_to,
    label: p.label,
    createdAt: toIso(p.created_at),
    mine,
  };
  if (!staff && (p.blocked || p.hidden_by_me)) {
    return {
      ...base, status: 'hidden_by_you', authorName: '', authorProfileId: null, body: '',
      editedAt: null, helpfulByMe: false, helpfulCount: null, scholarOrg: null,
    };
  }
  if (!staff && !mine && (p.status === 'hidden' || p.status === 'removed')) {
    return {
      ...base, status: p.status, authorName: '', authorProfileId: null, body: '',
      editedAt: null, helpfulByMe: false, helpfulCount: null, scholarOrg: null,
    };
  }
  return {
    ...base,
    status: p.status,
    authorName: p.author_name,
    authorProfileId: p.author_profile_id,
    body: p.body,
    editedAt: p.edited_at ? toIso(p.edited_at) : null,
    helpfulByMe: p.helpful_by_me,
    // The count is private to the author: it is encouragement, not a score.
    helpfulCount: mine ? p.helpful_count : null,
    scholarOrg: p.scholar_org,
  };
}

/** Runs the content filters. Throws 422 for a refusal (and files any auto-report). */
export async function judge(
  deps: Deps,
  member: Member,
  texts: readonly string[],
  surface: FilterOptions['surface'],
): Promise<Verdict> {
  const filters = await loadFilters(deps.db);
  const v = evaluateMany(texts, { accountIsNew: member.newAccount, filters, surface });
  if (v.kind === 'block') {
    if (v.autoReport) await fileAutoReport(deps.db, { type: 'profile', id: member.profile.id }, v.autoReport);
    throw new ApiError(422, 'content_blocked', v.message, { reason: v.code });
  }
  return v;
}

export async function registerForumRoutes(app: FastifyInstance, deps: Deps): Promise<void> {
  const { db } = deps;
  const auth = requireAuth(deps);

  async function viewer(userId: string) {
    const p = await ownAdultProfile(db, userId);
    return p && p.erased_at === null ? p.id : null;
  }

  // --------------------------------------------------------------- rules
  app.get('/v1/community/rules', { preHandler: [auth] }, async (request) => {
    const a = request.auth;
    if (!a) throw unauthorized();
    const profile = await ownAdultProfile(db, a.userId);
    const mute = await activeSanction(db, a.userId, ['mute'], deps.now());
    return {
      version: COMMUNITY_RULES_VERSION,
      accepted: await hasAcceptedRules(db, a.userId),
      hasProfile: profile !== undefined,
      communityVisible: profile?.visibility === 'community',
      mutedUntil: mute ? (mute.ends_at ? toIso(mute.ends_at) : 'indefinite') : null,
    };
  });

  app.post(
    '/v1/community/rules/accept',
    { preHandler: [auth, limit(deps, { name: 'rules_accept', max: 20, windowSec: 3600, by: 'user' })] },
    async (request, reply) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      const body = parse(acceptRules, request.body);
      if (body.version !== COMMUNITY_RULES_VERSION) {
        throw new ApiError(422, 'rules_outdated', 'Please read the current community rules.');
      }
      if (!(await ownAdultProfile(db, a.userId))) {
        throw forbidden('profile_required', 'Create your profile first.');
      }
      await db.tx(async (q) => {
        if (await hasAcceptedRules(q, a.userId)) return;
        await q.query(
          `insert into consents (user_id, kind, version, given_at) values ($1, 'community_rules', $2, $3)`,
          [a.userId, COMMUNITY_RULES_VERSION, deps.now()],
        );
        await audit(q, { actorUserId: a.userId, action: 'rules.accepted', meta: { version: COMMUNITY_RULES_VERSION } });
      });
      void reply.code(204);
    },
  );

  // ---------------------------------------------------------- categories
  app.get('/v1/forum/categories', { preHandler: [auth] }, async (request) => {
    const a = request.auth;
    if (!a) throw unauthorized();
    const r = await db.query<CategoryRow>(
      `select ${CATEGORY_COLUMNS},
              (select count(*) from forum_threads t
                where t.category_id = c.id and t.status in ('open', 'locked'))::text as thread_count
         from forum_categories c where not c.archived order by c.sort_order, c.title`,
    );
    const now = deps.now();
    const m = { userId: a.userId, role: a.role };
    const out = [];
    for (const c of r.rows) {
      out.push({
        id: c.id,
        slug: c.slug,
        title: c.title,
        description: c.description,
        kind: c.kind,
        strictModeration: c.strict_moderation,
        rulesNote: c.rules_note,
        whoCanPost: c.who_can_post,
        whoCanReply: c.who_can_reply,
        canStart: await meetsStanding(db, m, c.who_can_post, now),
        canReply: await meetsStanding(db, m, c.who_can_reply, now),
        threadCount: Number(c.thread_count ?? '0'),
      });
    }
    return { rulesVersion: COMMUNITY_RULES_VERSION, categories: out };
  });

  // ------------------------------------------------------------- threads
  async function category(slug: string): Promise<CategoryRow> {
    const r = await db.query<CategoryRow>(
      `select ${CATEGORY_COLUMNS} from forum_categories c where c.slug = $1 and not c.archived`,
      [slug],
    );
    const c = r.rows[0];
    if (!c) throw notFound();
    return c;
  }

  app.get<{ Params: { slug: string } }>(
    '/v1/forum/categories/:slug/threads',
    { preHandler: [auth] },
    async (request) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      const { slug } = parse(slugParam, request.params);
      const { before, limit: lim } = parse(pageQuery, request.query);
      const c = await category(slug);
      const me = await viewer(a.userId);
      const staff = isStaff(a.role);
      const r = await db.query<ThreadRow>(
        `${THREAD_SELECT}
          where t.category_id = $1
            and (t.status in ('open', 'locked')
                 or (t.status = 'pending_review' and t.author_profile_id = $2))
            and ($3::timestamptz is null or (t.last_post_at < $3::timestamptz and not t.pinned))
            and not (${staff ? 'false' : blockedEitherWaySql('$2', 't.author_profile_id')})
            and not exists (select 1 from user_hidden h
                             where h.profile_id = $2 and h.target_type = 'thread' and h.target_id = t.id)
          order by t.pinned desc, t.last_post_at desc, t.id
          limit $4`,
        [c.id, me, before ?? null, lim + 1],
      );
      const rows = r.rows.slice(0, lim);
      return {
        category: { id: c.id, slug: c.slug, title: c.title, kind: c.kind, strictModeration: c.strict_moderation },
        threads: rows.map((t) => mapThread(t, me)),
        hasMore: r.rows.length > lim,
      };
    },
  );

  async function visibleThread(id: string, userId: string, staff: boolean): Promise<{ t: ThreadRow; me: string | null }> {
    if (!UUID_RE.test(id)) throw notFound();
    const me = await viewer(userId);
    const r = await db.query<ThreadRow>(
      `${THREAD_SELECT}
        where t.id = $1
          and ($3::boolean
               or (t.status in ('open', 'locked')
                   and not ${blockedEitherWaySql('$2', 't.author_profile_id')})
               or (t.status = 'pending_review' and t.author_profile_id = $2))`,
      [id, me, staff],
    );
    const t = r.rows[0];
    if (!t) throw notFound();
    return { t, me };
  }

  app.get<{ Params: { id: string } }>(
    '/v1/forum/threads/:id',
    { preHandler: [auth] },
    async (request) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      const { id } = parse(idParam, request.params);
      const { after, limit: lim } = parse(postsQuery, request.query);
      const staff = isStaff(a.role);
      const { t, me } = await visibleThread(id, a.userId, staff);
      const [afterAt, afterId] = after ? after.split('~') : [null, null];
      const r = await db.query<PostRow>(
        `select fp.id, fp.thread_id, fp.author_profile_id, pr.display_name as author_name, fp.reply_to,
                fp.body, fp.label, fp.status, fp.edited_at, fp.created_at, cr.org_name as scholar_org,
                (select count(*) from forum_reactions r
                  where r.post_id = fp.id and r.kind = 'helpful')::int as helpful_count,
                exists (select 1 from forum_reactions r
                         where r.post_id = fp.id and r.profile_id = $2 and r.kind = 'helpful') as helpful_by_me,
                ${blockedEitherWaySql('$2', 'fp.author_profile_id')} as blocked,
                exists (select 1 from user_hidden h
                         where h.profile_id = $2 and h.target_type = 'post' and h.target_id = fp.id) as hidden_by_me
           from forum_posts fp
           join profiles pr on pr.id = fp.author_profile_id
           left join credentials cr on cr.id = fp.credential_id
          where fp.thread_id = $1
            and (fp.status in ('visible', 'hidden', 'removed')
                 or (fp.status = 'pending_review' and (fp.author_profile_id = $2 or $5::boolean)))
            and ($3::timestamptz is null or (fp.created_at, fp.id) > ($3::timestamptz, $4::uuid))
          order by fp.created_at, fp.id
          limit $6`,
        [t.id, me, afterAt, afterId, staff, lim + 1],
      );
      const rows = r.rows.slice(0, lim);
      const last = rows[rows.length - 1];
      return {
        thread: mapThread(t, me),
        posts: rows.map((p) => mapPost(p, me, staff)),
        hasMore: r.rows.length > lim,
        next: r.rows.length > lim && last ? `${toIso(last.created_at)}~${last.id}` : null,
      };
    },
  );

  async function assertNoDuplicate(q: Queryable, profileId: string, body: string, now: Date): Promise<void> {
    const since = new Date(now.getTime() - DUPLICATE_WINDOW_MINUTES * 60_000);
    const d = await q.query(
      `select 1 from forum_posts where author_profile_id = $1 and body = $2 and created_at > $3
          and status <> 'removed' limit 1`,
      [profileId, body, since],
    );
    if (d.rowCount > 0) throw conflict('duplicate_post', 'You already posted that.');
  }

  app.post<{ Params: { slug: string } }>(
    '/v1/forum/categories/:slug/threads',
    { preHandler: [auth] },
    async (request, reply) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      const { slug } = parse(slugParam, request.params);
      const body = parse(newThread, request.body);
      const member = await requireMember(db, deps, a, { visible: true, rules: true, notMuted: true });
      hitLimit(deps, `thread_day:${a.userId}`, member.newAccount ? 2 : 6, 86_400);
      hitLimit(deps, `post_burst:${a.userId}`, 3, 60);
      const c = await category(slug);
      if (!(await meetsStanding(db, member, c.who_can_post, deps.now()))) {
        throw forbidden('not_allowed_here', 'You cannot start a thread in this category.');
      }
      const verdict = await judge(deps, member, [body.title, body.body], 'forum');
      const label = c.kind === 'ask_scholar' ? 'question' : c.kind === 'announcements' ? 'announcement' : 'community_opinion';
      const skipReview = c.kind === 'announcements' && isStaff(a.role);
      const pending = !skipReview && (c.strict_moderation || verdict.kind === 'review');
      const now = deps.now();
      const out = await db.tx(async (q) => {
        await assertNoDuplicate(q, member.profile.id, body.body, now);
        const t = await q.query<{ id: string }>(
          `insert into forum_threads (category_id, author_profile_id, title, status, created_at, last_post_at)
           values ($1, $2, $3, $4, $5, $5) returning id`,
          [c.id, member.profile.id, body.title, pending ? 'pending_review' : 'open', now],
        );
        const threadId = t.rows[0]?.id ?? '';
        const p = await q.query<{ id: string }>(
          `insert into forum_posts (thread_id, author_profile_id, body, label, status, created_at)
           values ($1, $2, $3, $4, $5, $6) returning id`,
          [threadId, member.profile.id, body.body, label, pending ? 'pending_review' : 'visible', now],
        );
        const postId = p.rows[0]?.id ?? '';
        await recountThread(q, threadId);
        if (verdict.kind !== 'allow' && verdict.autoReport) {
          await fileAutoReport(q, { type: 'post', id: postId }, verdict.autoReport);
        }
        return { threadId, postId };
      });
      const rr = await db.query<ThreadRow>(`${THREAD_SELECT} where t.id = $1`, [out.threadId]);
      const row = rr.rows[0];
      if (!row) throw notFound();
      void reply.code(201);
      return {
        thread: mapThread(row, member.profile.id),
        postId: out.postId,
        pendingReview: pending,
        showHelp: verdict.kind === 'flag' && verdict.showHelp,
      };
    },
  );

  // --------------------------------------------------------------- posts
  app.post<{ Params: { id: string } }>(
    '/v1/forum/threads/:id/posts',
    { preHandler: [auth] },
    async (request, reply) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      const { id } = parse(idParam, request.params);
      const body = parse(newPost, request.body);
      const member = await requireMember(db, deps, a, { visible: true, rules: true, notMuted: true });
      hitLimit(deps, `post_hour:${a.userId}`, member.newAccount ? 6 : 30, 3600);
      hitLimit(deps, `post_burst:${a.userId}`, 3, 60);
      const { t } = await visibleThread(id, a.userId, false);
      if (t.status === 'pending_review') throw notFound();
      if (t.status === 'locked') throw conflict('thread_locked', 'This thread is closed to new replies.');
      if (!(await meetsStanding(db, member, t.who_can_reply, deps.now()))) {
        throw forbidden(
          t.category_kind === 'ask_scholar' ? 'scholars_only' : 'not_allowed_here',
          t.category_kind === 'ask_scholar'
            ? 'Only verified scholars answer in Ask a scholar. For community conversation, try Learning together.'
            : 'You cannot reply in this category.',
        );
      }
      const verdict = await judge(deps, member, [body.body], 'forum');
      const now = deps.now();
      const scholar = t.category_kind === 'ask_scholar' ? await activeCredential(db, a.userId, 'scholar', now) : undefined;
      const label = scholar ? 'scholar_answer' : t.category_kind === 'announcements' ? 'announcement' : 'community_opinion';
      const pending = verdict.kind === 'review' || (t.strict_moderation && !scholar && !(t.category_kind === 'announcements' && isStaff(a.role)));
      const postId = await db.tx(async (q) => {
        await assertNoDuplicate(q, member.profile.id, body.body, now);
        if (body.replyTo) {
          const rt = await q.query(
            `select 1 from forum_posts where id = $1 and thread_id = $2 and status = 'visible'`,
            [body.replyTo, t.id],
          );
          if (rt.rowCount === 0) throw notFound();
        }
        // The thread row is locked so a moderator locking it cannot race a reply.
        const lock = await q.query<{ status: string }>('select status from forum_threads where id = $1 for update', [t.id]);
        if (lock.rows[0]?.status !== 'open') throw conflict('thread_locked', 'This thread is closed to new replies.');
        const p = await q.query<{ id: string }>(
          `insert into forum_posts (thread_id, author_profile_id, reply_to, body, label, status, credential_id, created_at)
           values ($1, $2, $3, $4, $5, $6, $7, $8) returning id`,
          [t.id, member.profile.id, body.replyTo ?? null, body.body, label, pending ? 'pending_review' : 'visible',
           scholar?.id ?? null, now],
        );
        const pid = p.rows[0]?.id ?? '';
        await recountThread(q, t.id);
        if (verdict.kind !== 'allow' && verdict.autoReport) {
          await fileAutoReport(q, { type: 'post', id: pid }, verdict.autoReport);
        }
        if (!pending) await notifyThreadAuthor(q, t.id, t.author_profile_id, member.profile.id, pid);
        return pid;
      });
      void reply.code(201);
      return {
        post: { id: postId, threadId: t.id, label, status: pending ? 'pending_review' : 'visible' },
        pendingReview: pending,
        showHelp: verdict.kind === 'flag' && verdict.showHelp,
      };
    },
  );

  app.patch<{ Params: { id: string } }>(
    '/v1/forum/posts/:id',
    { preHandler: [auth, limit(deps, { name: 'post_edit', max: 30, windowSec: 3600, by: 'user' })] },
    async (request) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      const { id } = parse(idParam, request.params);
      const body = parse(editPost, request.body);
      const member = await requireMember(db, deps, a, { visible: true, rules: true, notMuted: true });
      const r = await db.query<{
        id: string; thread_id: string; body: string; status: string; label: string; created_at: Date;
        strict: boolean; kind: string; tstatus: string;
      }>(
        `select fp.id, fp.thread_id, fp.body, fp.status, fp.label, fp.created_at,
                c.strict_moderation as strict, c.kind, t.status as tstatus
           from forum_posts fp join forum_threads t on t.id = fp.thread_id
           join forum_categories c on c.id = t.category_id
          where fp.id = $1 and fp.author_profile_id = $2`,
        [id, member.profile.id],
      );
      const p = r.rows[0];
      if (!p || (p.status !== 'visible' && p.status !== 'pending_review')) throw notFound();
      const now = deps.now();
      if (now.getTime() - new Date(p.created_at).getTime() > EDIT_WINDOW_MINUTES * 60_000) {
        throw conflict('edit_window_closed', `Posts can be edited for ${EDIT_WINDOW_MINUTES} minutes.`);
      }
      if (p.tstatus === 'locked') throw conflict('thread_locked', 'This thread is closed.');
      const verdict = await judge(deps, member, [body.body], 'forum');
      // An approved post that is edited in a reviewed category is reviewed again,
      // so approval cannot be used to smuggle in different words.
      const pending = verdict.kind === 'review' || (p.strict && p.label !== 'scholar_answer') || p.status === 'pending_review';
      await db.tx(async (q) => {
        await q.query(
          `update forum_posts set body = $2, edited_at = $3, status = $4 where id = $1`,
          [p.id, body.body, now, pending ? 'pending_review' : 'visible'],
        );
        await recountThread(q, p.thread_id);
        if (verdict.kind !== 'allow' && verdict.autoReport) {
          await fileAutoReport(q, { type: 'post', id: p.id }, verdict.autoReport);
        }
      });
      return { post: { id: p.id, status: pending ? 'pending_review' : 'visible' }, pendingReview: pending };
    },
  );

  app.delete<{ Params: { id: string } }>(
    '/v1/forum/posts/:id',
    { preHandler: [auth] },
    async (request, reply) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      const { id } = parse(idParam, request.params);
      const me = await viewer(a.userId);
      if (!me) throw notFound();
      await db.tx(async (q) => {
        const r = await q.query<{ thread_id: string; first_id: string }>(
          `select fp.thread_id,
                  (select f2.id from forum_posts f2 where f2.thread_id = fp.thread_id
                    order by f2.created_at, f2.id limit 1) as first_id
             from forum_posts fp
            where fp.id = $1 and fp.author_profile_id = $2 and fp.status in ('visible', 'pending_review')`,
          [id, me],
        );
        const p = r.rows[0];
        if (!p) throw notFound();
        await q.query(
          `update forum_posts set status = 'removed', body = '[removed by author]', edited_at = $2 where id = $1`,
          [id, deps.now()],
        );
        if (p.first_id === id) {
          await q.query(`update forum_threads set status = 'removed' where id = $1`, [p.thread_id]);
        }
        await recountThread(q, p.thread_id);
      });
      void reply.code(204);
    },
  );

  // ----------------------------------------------------------- reactions
  const react = (on: boolean) =>
    async (request: { auth?: { userId: string }; params: { id: string } }, reply: { code: (n: number) => unknown }) => {
      const a = request.auth;
      if (!a) throw unauthorized();
      if (!UUID_RE.test(request.params.id)) throw notFound();
      const me = await viewer(a.userId);
      if (!me) throw forbidden('profile_required', 'Create your profile first.');
      hitLimit(deps, `react:${a.userId}`, 120, 3600);
      const r = await db.query<{ author: string; status: string; tstatus: string; blocked: boolean }>(
        `select fp.author_profile_id as author, fp.status, t.status as tstatus,
                ${blockedEitherWaySql('$2', 'fp.author_profile_id')} as blocked
           from forum_posts fp join forum_threads t on t.id = fp.thread_id where fp.id = $1`,
        [request.params.id, me],
      );
      const p = r.rows[0];
      if (!p || p.blocked || p.status !== 'visible' || (p.tstatus !== 'open' && p.tstatus !== 'locked')) throw notFound();
      if (p.author === me) throw conflict('own_post', 'You cannot mark your own post.');
      if (on) {
        await db.query(
          `insert into forum_reactions (post_id, profile_id, kind, created_at) values ($1, $2, 'helpful', $3)
           on conflict do nothing`,
          [request.params.id, me, deps.now()],
        );
      } else {
        await db.query(`delete from forum_reactions where post_id = $1 and profile_id = $2 and kind = 'helpful'`, [
          request.params.id,
          me,
        ]);
      }
      void reply.code(204);
    };
  app.put<{ Params: { id: string } }>('/v1/forum/posts/:id/helpful', { preHandler: [auth] }, react(true));
  app.delete<{ Params: { id: string } }>('/v1/forum/posts/:id/helpful', { preHandler: [auth] }, react(false));
}

/** A reply notifies the thread's author (never for their own post, never across a block). */
export async function notifyThreadAuthor(
  q: Queryable,
  threadId: string,
  threadAuthorProfile: string,
  replierProfile: string,
  postId: string,
): Promise<void> {
  if (threadAuthorProfile === replierProfile) return;
  const b = await q.query(
    `select 1 from blocks where (blocker_profile = $1 and blocked_profile = $2)
        or (blocker_profile = $2 and blocked_profile = $1) limit 1`,
    [threadAuthorProfile, replierProfile],
  );
  if (b.rowCount > 0) return;
  const u = await q.query<{ user_id: string | null }>('select user_id from profiles where id = $1', [threadAuthorProfile]);
  const uid = u.rows[0]?.user_id;
  if (uid) await notify(q, uid, 'forum_reply', { threadId, postId });
}

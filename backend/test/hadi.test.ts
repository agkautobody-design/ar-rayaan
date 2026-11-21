import assert from 'node:assert/strict';
import { after, before, describe, it } from 'node:test';
import { AnthropicHadiModel, HadiModelError, memoryLine, type HadiModel, type HadiModelRequest } from '../src/hadi.js';
import { call, makeCtx, signUp, type Ctx } from './helpers.js';

class FakeModel implements HadiModel {
  calls: HadiModelRequest[] = [];
  fail = false;
  async complete(req: HadiModelRequest): Promise<string> {
    this.calls.push(req);
    if (this.fail) throw new HadiModelError('boom');
    return 'A friendly answer.';
  }
}

describe('Hadi live-AI route', () => {
  const model = new FakeModel();
  let ctx: Ctx;
  before(async () => {
    ctx = await makeCtx({ hadiModel: model, env: { HADI_AI_DAILY_CAP: '3' } });
  });
  after(async () => {
    await ctx.close();
  });

  it('needs a signed-in person', async () => {
    const r = await call(ctx, 'POST', '/v1/hadi/ask', { body: { question: 'hello there' } });
    assert.equal(r.status, 401);
  });

  it('answers, and puts the guardrail and a plain memory line in the system prompt', async () => {
    const s = await signUp(ctx);
    const r = await call(ctx, 'POST', '/v1/hadi/ask', {
      token: s.token,
      body: {
        question: 'What is the wisdom of fasting on Mondays?',
        history: [{ from: 'user', text: 'hi' }, { from: 'hadi', text: 'salam' }],
        memory: { roles: ['parent'], topics: ['fasting'], covered: ['tarawih-prayer'] },
      },
    });
    assert.equal(r.status, 200);
    assert.equal(r.json.text, 'A friendly answer.');
    const sent = model.calls.at(-1)!;
    assert.match(sent.system, /Never invent a Qur’an verse/);
    assert.match(sent.system, /has children/);
    assert.match(sent.system, /fasting and Ramadan/);
    assert.match(sent.system, /tarawih prayer/);
    assert.equal(sent.messages.at(-1)!.role, 'user');
    assert.equal(sent.messages[0]!.role, 'user');
  });

  it('refuses memory that is not from the fixed lists', async () => {
    const s = await signUp(ctx);
    const r = await call(ctx, 'POST', '/v1/hadi/ask', {
      token: s.token,
      body: { question: 'a fair question', memory: { roles: ['depressed'] } },
    });
    assert.equal(r.status, 400);
    const r2 = await call(ctx, 'POST', '/v1/hadi/ask', {
      token: s.token,
      body: { question: 'a fair question', memory: { covered: ['My secret words!'] } },
    });
    assert.equal(r2.status, 400);
  });

  it('enforces the daily cap on the server, per person, and resets the next day', async () => {
    const a = await signUp(ctx);
    const b = await signUp(ctx);
    for (let i = 0; i < 3; i++) {
      assert.equal((await call(ctx, 'POST', '/v1/hadi/ask', { token: a.token, body: { question: `question ${i} here` } })).status, 200);
      ctx.clock.advanceMs(7_000); // stay under the per-minute limiter
    }
    ctx.clock.advanceMs(60_000);
    const over = await call(ctx, 'POST', '/v1/hadi/ask', { token: a.token, body: { question: 'one more please' } });
    assert.equal(over.status, 429);
    assert.equal(over.json.error.code, 'hadi_cap_reached');
    assert.equal((await call(ctx, 'POST', '/v1/hadi/ask', { token: b.token, body: { question: 'my first today' } })).status, 200);
    ctx.clock.advanceMs(24 * 3_600_000);
    assert.equal((await call(ctx, 'POST', '/v1/hadi/ask', { token: a.token, body: { question: 'a new day now' } })).status, 200);
  });

  it('does not charge a failed model call', async () => {
    const s = await signUp(ctx);
    model.fail = true;
    for (let i = 0; i < 4; i++) {
      const r = await call(ctx, 'POST', '/v1/hadi/ask', { token: s.token, body: { question: `failing ${i} one` } });
      assert.equal(r.status, 502);
      ctx.clock.advanceMs(7_000);
    }
    model.fail = false;
    ctx.clock.advanceMs(60_000);
    assert.equal((await call(ctx, 'POST', '/v1/hadi/ask', { token: s.token, body: { question: 'now it works' } })).status, 200);
  });

  it('stores no words: the usage table holds only counts', async () => {
    const cols = await ctx.db.query<{ column_name: string }>(
      `select column_name from information_schema.columns where table_name = 'hadi_ai_usage' order by 1`,
    );
    assert.deepEqual(cols.rows.map((c) => c.column_name), ['count', 'day', 'user_id']);
  });
});

describe('Hadi route without a key', () => {
  it('answers 503, never a guess', async () => {
    const ctx = await makeCtx();
    const s = await signUp(ctx);
    const r = await call(ctx, 'POST', '/v1/hadi/ask', { token: s.token, body: { question: 'a question here' } });
    assert.equal(r.status, 503);
    assert.equal(r.json.error.code, 'hadi_unavailable');
    await ctx.close();
  });
});

describe('AnthropicHadiModel', () => {
  it('sends the key as a header only and reads the text blocks', async () => {
    let seen: { url: string; init: RequestInit } | undefined;
    const m = new AnthropicHadiModel('k-test', 'small-model', 'https://example.test/v1/messages', (async (url: string, init: RequestInit) => {
      seen = { url, init };
      return new Response(JSON.stringify({ content: [{ type: 'text', text: ' Hello ' }] }), { status: 200 });
    }) as unknown as typeof fetch);
    const out = await m.complete({ system: 's', messages: [{ role: 'user', content: 'q' }], maxTokens: 50, preferSmall: true });
    assert.equal(out, 'Hello');
    assert.equal((seen!.init.headers as Record<string, string>)['x-api-key'], 'k-test');
    assert.ok(!String(seen!.init.body).includes('k-test'));
  });
  it('turns a provider error into a model error', async () => {
    const m = new AnthropicHadiModel('k', 'm', 'https://example.test', (async () => new Response('no', { status: 500 })) as unknown as typeof fetch);
    await assert.rejects(m.complete({ system: 's', messages: [], maxTokens: 50, preferSmall: true }), HadiModelError);
  });
});

describe('memoryLine', () => {
  it('is empty with nothing known', () => {
    assert.equal(memoryLine({ roles: [], topics: [], covered: [] }), '');
  });
});

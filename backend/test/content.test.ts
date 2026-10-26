import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { evaluateContent, validateFilterPattern, type FilterOptions } from '../src/policy/content.js';

const base: FilterOptions = { accountIsNew: false, filters: [], surface: 'forum' };
const verdict = (text: string, o: Partial<FilterOptions> = {}) => evaluateContent(text, { ...base, ...o });

describe('content filters', () => {
  it('allows ordinary kind words, including Arabic', () => {
    assert.equal(verdict('Assalamu alaikum, I am new here and learning tajweed. Any tips for makharij?').kind, 'allow');
    assert.equal(verdict('السلام عليكم ورحمة الله، أنا أتعلم التجويد').kind, 'allow');
    assert.equal(verdict('Meet on 2026-11-14 at the mosque after Asr').kind, 'allow');
  });

  it('blocks contact details and talking elsewhere', () => {
    for (const t of [
      'call me on +1 416 555 0199',
      'email me at someone@example.com',
      'add me on whatsapp',
      'dm me please',
      'message me privately',
      'my insta is something',
    ]) {
      const v = verdict(t);
      assert.equal(v.kind, 'block', t);
    }
  });

  it('blocks homes and street addresses; allows a street address in the venue field only', () => {
    assert.equal(verdict('come to my house after isha').kind, 'block');
    assert.equal(verdict('we meet at my place').kind, 'block');
    assert.equal(verdict('house gathering this weekend').kind, 'block');
    assert.equal(verdict('I live at 42 Maple Street').kind, 'block');
    assert.equal(verdict('at my home', { surface: 'meetup' }).kind, 'block');
    assert.equal(verdict('I love my home town of Lahore').kind, 'allow', 'a mention is fine in a forum post');
    assert.equal(verdict('100 Main Street, Toronto', { surface: 'venue' }).kind, 'allow');
    assert.equal(verdict('my home', { surface: 'venue' }).kind, 'block');
  });

  it('blocks photos and image links', () => {
    assert.equal(verdict('look ![x](a)').kind, 'block');
    assert.equal(verdict('see pic.example.org/a.jpg', { accountIsNew: false }).kind, 'block');
  });

  it('refuses sexual content and approaches to minors, and files a report', () => {
    const a = verdict('send me a pic');
    assert.equal(a.kind, 'block');
    assert.equal(a.kind === 'block' && a.autoReport?.reason, 'child_safety');
    assert.equal(a.kind === 'block' && a.autoReport?.priority, 100);
    const b = verdict('free porn here');
    assert.equal(b.kind === 'block' && b.autoReport?.reason, 'sexual');
  });

  it('refuses threats of violence', () => {
    assert.equal(verdict('we should kill them all').kind, 'block');
  });

  it('holds takfir, rulings, sectarian labels and money for a person, never blocks them', () => {
    for (const [t, reason] of [
      ['you are a kafir', 'takfir'],
      ['he is out of the fold of islam', 'takfir'],
      ['this fatwa says otherwise', 'ruling'],
      ['it is haram to do that', 'ruling'],
      ['those deviants and innovators', 'sectarian'],
      ['send me money and double your investment', 'money'],
    ] as const) {
      const v = verdict(t);
      assert.equal(v.kind, 'review', t);
      assert.ok(v.kind === 'review' && v.reasons.includes(reason), `${t} -> ${reason}`);
    }
  });

  it('folds look-alike characters in word lists', () => {
    assert.equal(verdict('you are a k@fir').kind, 'review');
  });

  it('allows an honest question about a ruling to be asked (held, not blocked)', () => {
    const v = verdict('Is it halal to eat at a restaurant that serves alcohol? Any fatwa?');
    assert.equal(v.kind, 'review');
  });

  it('flags possible risk to life: allowed, reported at once, help shown', () => {
    const v = verdict('I feel I want to die and I cannot go on');
    assert.equal(v.kind, 'flag');
    assert.ok(v.kind === 'flag' && v.showHelp && v.autoReport.priority >= 80);
  });

  it('link rules: new accounts cannot, others are reviewed unless the domain is allowed', () => {
    assert.equal(verdict('see https://example.org/a', { accountIsNew: true }).kind, 'block');
    assert.equal(verdict('see https://example.org/a').kind, 'review');
    assert.equal(
      verdict('see https://www.example.org/a', { filters: [{ kind: 'allow_domain', pattern: 'example.org' }] }).kind,
      'allow',
    );
    assert.equal(verdict('see https://sub.example.org/a', { filters: [{ kind: 'allow_domain', pattern: 'example.org' }] }).kind, 'allow');
    assert.equal(verdict('see https://bit.ly/abc').kind, 'block');
    assert.equal(verdict('join t.me/somechannel').kind, 'block');
    assert.equal(verdict('see https://bad.example.org', { filters: [{ kind: 'block_link', pattern: 'bad.example.org' }] }).kind, 'block');
    assert.equal(verdict('https://a.org https://b.org https://c.org').kind, 'block');
  });

  it('admin word lists are plain text', () => {
    const f: FilterOptions['filters'] = [
      { kind: 'block_word', pattern: 'secretword' },
      { kind: 'review_word', pattern: 'borderline phrase' },
    ];
    assert.equal(verdict('has a SecretWord inside', { filters: f }).kind, 'block');
    assert.equal(verdict('a borderline phrase here', { filters: f }).kind, 'review');
    assert.equal(verdict('harmless words only', { filters: [{ kind: 'block_word', pattern: '(.*)+' }] }).kind, 'allow');
  });

  it('spam shape', () => {
    assert.equal(verdict('THIS IS ALL IN CAPITAL LETTERS AND VERY LOUD INDEED').kind, 'block');
    assert.equal(verdict('aaaaaaaaaaaaaaaaaaaa').kind, 'block');
    assert.equal(verdict('buy buy buy buy buy buy buy buy buy buy buy buy buy').kind, 'block');
  });

  it('validates admin patterns', () => {
    assert.equal(validateFilterPattern('block_link', 'example.org'), null);
    assert.ok(validateFilterPattern('allow_domain', 'not a domain'));
    assert.ok(validateFilterPattern('block_word', ''));
  });
});

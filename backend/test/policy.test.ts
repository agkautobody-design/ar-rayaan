import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { capabilities, mayBeFriends } from '../src/policy/age.js';
import { validateChildNickname, validateDisplayName, validateHandle } from '../src/policy/names.js';
import {
  inviteCodeHash,
  newInviteCode,
  newSignInCode,
  normaliseInviteCode,
  safeEqualHex,
} from '../src/security.js';

describe('names', () => {
  it('accepts ordinary names, including Arabic script', () => {
    assert.equal(validateDisplayName('Amina K.'), null);
    assert.equal(validateDisplayName('عبد الله'), null);
    assert.equal(validateChildNickname('Little Yusuf'), null);
  });

  it('rejects reserved words, look-alike digits and fragments', () => {
    for (const bad of ['Hadi', 'h4di', 'Admin', 'Sheikh Ali', 'Im@m', 'Ar-Rayaan', 'ar rayaan team', 'MOD']) {
      assert.notEqual(validateDisplayName(bad), null, bad);
    }
  });

  it('rejects accents, emoji, length problems', () => {
    assert.notEqual(validateDisplayName('Ámina'), null);
    assert.notEqual(validateDisplayName('Sara 🌙'), null);
    assert.notEqual(validateDisplayName('A'), null);
    assert.notEqual(validateDisplayName('x'.repeat(31)), null);
  });

  it('validates handles', () => {
    assert.equal(validateHandle('amina_k'), null);
    for (const bad of ['ab', 'Has Caps', 'a'.repeat(21), 'x-y', 'hadi', 'the_imam', 'admin_1']) {
      assert.notEqual(validateHandle(bad), null, bad);
    }
  });
});

describe('age policy', () => {
  it('gives minors no public profile, forums, DMs or handle requests', () => {
    for (const k of ['child', 'teen'] as const) {
      const c = capabilities(k);
      assert.equal(c.publicProfile, false);
      assert.equal(c.forums, false);
      assert.equal(c.directMessages, false);
      assert.equal(c.friendRequestsByHandle, false);
      assert.equal(c.friendsNeedGuardian, true);
    }
    assert.equal(capabilities('adult').directMessages, false);
  });

  it('keeps friendships on one side of the adult/minor line', () => {
    assert.equal(mayBeFriends('adult', 'adult'), true);
    assert.equal(mayBeFriends('child', 'teen'), true);
    assert.equal(mayBeFriends('adult', 'child'), false);
    assert.equal(mayBeFriends('teen', 'adult'), false);
  });
});

describe('security helpers', () => {
  it('makes invite codes that survive normalisation', () => {
    for (let i = 0; i < 200; i += 1) {
      const c = newInviteCode();
      assert.match(c, /^[2-9A-Z]{5}-[2-9A-Z]{5}$/);
      assert.equal(normaliseInviteCode(c.toLowerCase().replace('-', ' ')), c.replace('-', ''));
    }
    assert.equal(normaliseInviteCode('0000000000'), null);
    assert.equal(normaliseInviteCode('short'), null);
  });

  it('hashes with the pepper', () => {
    assert.notEqual(inviteCodeHash('a'.repeat(32), 'ABCDEFGHJK'), inviteCodeHash('b'.repeat(32), 'ABCDEFGHJK'));
  });

  it('makes six-digit sign-in codes and compares in constant time', () => {
    for (let i = 0; i < 100; i += 1) assert.match(newSignInCode(), /^\d{6}$/);
    assert.equal(safeEqualHex('ab12', 'ab12'), true);
    assert.equal(safeEqualHex('ab12', 'ab13'), false);
    assert.equal(safeEqualHex('ab12', 'ab1234'), false);
    assert.equal(safeEqualHex('', ''), false);
  });
});

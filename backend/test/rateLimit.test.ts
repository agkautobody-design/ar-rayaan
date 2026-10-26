import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { RateLimiter } from '../src/rateLimit.js';

describe('RateLimiter', () => {
  it('allows up to max, then blocks with a retry time, then resets', () => {
    let t = 1_000;
    const rl = new RateLimiter(() => t);
    for (let i = 0; i < 3; i += 1) assert.equal(rl.hit('k', 3, 10_000).allowed, true);
    const blocked = rl.hit('k', 3, 10_000);
    assert.equal(blocked.allowed, false);
    assert.equal(blocked.retryAfterSec, 10);
    t += 10_001;
    assert.equal(rl.hit('k', 3, 10_000).allowed, true);
  });

  it('keeps keys separate and reports exhaustion without counting', () => {
    const rl = new RateLimiter(() => 0);
    rl.hit('a', 1, 1000);
    rl.hit('a', 1, 1000);
    assert.equal(rl.isExhausted('a', 1), true);
    assert.equal(rl.isExhausted('b', 1), false);
    assert.equal(rl.hit('b', 1, 1000).allowed, true);
  });

  it('stays bounded', () => {
    const rl = new RateLimiter(() => 0, 100);
    for (let i = 0; i < 1000; i += 1) rl.hit(`k${i}`, 1, 1000);
    assert.ok(rl.size <= 100);
  });
});

import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { ConfigError, DEV_PEPPER, loadConfig } from '../src/config.js';

const prod = {
  NODE_ENV: 'production',
  DATABASE_URL: 'postgres://u:p@h/db',
  PEPPER: 'x'.repeat(40),
  EMAIL_PROVIDER: 'resend',
  RESEND_API_KEY: 'key-123',
  CORS_ORIGINS: 'https://ar-rayaan.onrender.com',
};

describe('config', () => {
  it('has safe development defaults', () => {
    const c = loadConfig({});
    assert.equal(c.env, 'development');
    assert.equal(c.port, 8080);
    assert.equal(c.pepper, DEV_PEPPER);
    assert.equal(c.emailProvider, 'console');
    assert.equal(c.trustProxy, false);
  });

  it('accepts a complete production config and trusts the proxy', () => {
    const c = loadConfig(prod);
    assert.equal(c.trustProxy, true);
    assert.deepEqual(c.corsOrigins, ['https://ar-rayaan.onrender.com']);
  });

  it('refuses production without the required secrets and with the console mailer', () => {
    assert.throws(() => loadConfig({ NODE_ENV: 'production' }), ConfigError);
    assert.throws(() => loadConfig({ ...prod, EMAIL_PROVIDER: 'console' }), /console/);
    assert.throws(() => loadConfig({ ...prod, PEPPER: undefined }), /PEPPER/);
    assert.throws(() => loadConfig({ ...prod, RESEND_API_KEY: undefined }), /RESEND_API_KEY/);
  });

  it('allows firebase-only production with no mail provider, and needs the project id', () => {
    const base = { ...prod, EMAIL_PROVIDER: 'console', RESEND_API_KEY: undefined };
    assert.throws(() => loadConfig({ ...base, AUTH_MODE: 'firebase' }), /FIREBASE_PROJECT_ID/);
    const c = loadConfig({ ...base, AUTH_MODE: 'firebase', FIREBASE_PROJECT_ID: 'my-proj' });
    assert.equal(c.authMode, 'firebase');
    assert.throws(() => loadConfig({ ...base, AUTH_MODE: 'both', FIREBASE_PROJECT_ID: 'my-proj' }), /console/);
  });

  it('refuses wildcard and malformed CORS origins', () => {
    assert.throws(() => loadConfig({ ...prod, CORS_ORIGINS: '*' }), /not allowed/);
    assert.throws(() => loadConfig({ ...prod, CORS_ORIGINS: 'https://a.test/path' }), /bare origins/);
    assert.throws(() => loadConfig({ ...prod, CORS_ORIGINS: 'nonsense' }), /valid origin/);
  });

  it('never puts a secret value in an error message', () => {
    const secret = 'super-secret-pepper-value-1234567890abcd';
    try {
      loadConfig({ ...prod, PEPPER: secret, EMAIL_PROVIDER: 'console', PORT: 'abc' });
      assert.fail('should throw');
    } catch (e) {
      assert.ok(e instanceof ConfigError);
      assert.ok(!e.message.includes(secret));
      assert.ok(!e.message.includes('postgres://'));
    }
  });
});

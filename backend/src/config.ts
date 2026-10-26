import { z } from 'zod';

/**
 * All configuration comes from environment variables. Nothing secret lives in
 * the repository: see ../.env.example for the names, and ../README.md for who
 * supplies each value.
 *
 * Errors name the variable that is wrong, never its value.
 */

export interface Config {
  env: 'development' | 'test' | 'production';
  port: number;
  host: string;
  databaseUrl: string | undefined;
  /** Server secret for keyed hashes (emails, codes, invite codes). Never rotate casually. */
  pepper: string;
  /** Which sign-in routes exist: the app's Firebase identity, e-mail codes, or both. */
  authMode: 'firebase' | 'email_code' | 'both';
  /** Firebase project whose ID tokens are accepted (authMode firebase/both). */
  firebaseProjectId: string | undefined;
  emailProvider: 'console' | 'resend';
  emailFrom: string;
  resendApiKey: string | undefined;
  corsOrigins: string[];
  publicAppUrl: string;
  sessionTtlDays: number;
  logLevel: 'fatal' | 'error' | 'warn' | 'info' | 'debug' | 'trace' | 'silent';
  trustProxy: boolean;
}

export class ConfigError extends Error {
  constructor(public readonly problems: string[]) {
    super(`Invalid configuration:\n- ${problems.join('\n- ')}`);
    this.name = 'ConfigError';
  }
}

/** Used only outside production when PEPPER is not set. Public on purpose. */
export const DEV_PEPPER = 'dev-only-pepper-not-secret-0123456789abcdef';

const schema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().min(1).max(65535).default(8080),
  HOST: z.string().min(1).default('0.0.0.0'),
  DATABASE_URL: z.string().min(1).optional(),
  PEPPER: z.string().min(32).optional(),
  AUTH_MODE: z.enum(['firebase', 'email_code', 'both']).default('email_code'),
  FIREBASE_PROJECT_ID: z.string().min(1).optional(),
  EMAIL_PROVIDER: z.enum(['console', 'resend']).default('console'),
  EMAIL_FROM: z.string().min(3).default('Ar-Rayaan <no-reply@example.invalid>'),
  RESEND_API_KEY: z.string().min(1).optional(),
  CORS_ORIGINS: z.string().default(''),
  PUBLIC_APP_URL: z.string().url().default('http://localhost:8099'),
  SESSION_TTL_DAYS: z.coerce.number().int().min(1).max(90).default(30),
  LOG_LEVEL: z
    .enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent'])
    .default('info'),
  TRUST_PROXY: z
    .enum(['true', 'false'])
    .optional(),
});

export function loadConfig(env: Record<string, string | undefined>): Config {
  const parsed = schema.safeParse(env);
  const problems: string[] = [];
  if (!parsed.success) {
    for (const issue of parsed.error.issues) {
      problems.push(`${issue.path.join('.') || '(root)'}: ${issue.message}`);
    }
    throw new ConfigError(problems);
  }
  const e = parsed.data;
  const production = e.NODE_ENV === 'production';

  if (production) {
    if (!e.DATABASE_URL) problems.push('DATABASE_URL: required in production');
    if (!e.PEPPER) problems.push('PEPPER: required in production (32+ random characters)');
    if (e.AUTH_MODE !== 'firebase' && e.EMAIL_PROVIDER === 'console') {
      problems.push('EMAIL_PROVIDER: "console" is not allowed in production');
    }
  }
  if (e.AUTH_MODE !== 'email_code' && !e.FIREBASE_PROJECT_ID) {
    problems.push('FIREBASE_PROJECT_ID: required when AUTH_MODE is firebase or both');
  }
  if (e.EMAIL_PROVIDER === 'resend' && !e.RESEND_API_KEY) {
    problems.push('RESEND_API_KEY: required when EMAIL_PROVIDER=resend');
  }
  const corsOrigins = e.CORS_ORIGINS.split(',')
    .map((s) => s.trim())
    .filter((s) => s.length > 0);
  for (const o of corsOrigins) {
    if (o === '*') problems.push('CORS_ORIGINS: "*" is not allowed');
    else {
      try {
        const u = new URL(o);
        if (u.origin !== o) problems.push('CORS_ORIGINS: entries must be bare origins');
      } catch {
        problems.push('CORS_ORIGINS: an entry is not a valid origin');
      }
    }
  }
  if (production && corsOrigins.length === 0) {
    problems.push('CORS_ORIGINS: required in production (comma-separated origins)');
  }
  if (problems.length > 0) throw new ConfigError(problems);

  return {
    env: e.NODE_ENV,
    port: e.PORT,
    host: e.HOST,
    databaseUrl: e.DATABASE_URL,
    pepper: e.PEPPER ?? DEV_PEPPER,
    authMode: e.AUTH_MODE,
    firebaseProjectId: e.FIREBASE_PROJECT_ID,
    emailProvider: e.EMAIL_PROVIDER,
    emailFrom: e.EMAIL_FROM,
    resendApiKey: e.RESEND_API_KEY,
    corsOrigins,
    publicAppUrl: e.PUBLIC_APP_URL.replace(/\/+$/, ''),
    sessionTtlDays: e.SESSION_TTL_DAYS,
    logLevel: e.LOG_LEVEL,
    // Render terminates TLS in front of the service, so the client address
    // arrives in X-Forwarded-For. Trust it in production only by default.
    trustProxy: e.TRUST_PROXY ? e.TRUST_PROXY === 'true' : production,
  };
}

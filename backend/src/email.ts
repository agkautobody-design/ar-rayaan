import type { FastifyBaseLogger } from 'fastify';
import type { Config } from './config.js';
import { emailHash } from './security.js';

/**
 * Sends the one-time sign-in code. The provider is pluggable: implement this
 * interface to add another (Postmark, SES, SMTP). The message is plain text
 * with NO links, so it cannot be mistaken for a phishing mail.
 */
export interface EmailSender {
  sendSignInCode(to: string, code: string, ttlMinutes: number): Promise<void>;
}

export function signInMessage(code: string, ttlMinutes: number): { subject: string; text: string } {
  return {
    subject: 'Your Ar-Rayaan sign-in code',
    text:
      `Your Ar-Rayaan sign-in code is ${code}\n\n` +
      `It works for ${ttlMinutes} minutes and only once. ` +
      'If you did not ask for it, ignore this message; nobody can sign in without the code.\n' +
      'We will never ask you for this code in a message or a call.',
  };
}

/** Tests: keeps messages in memory. */
export class MemoryEmailSender implements EmailSender {
  readonly outbox: Array<{ to: string; code: string }> = [];
  failNext = false;

  async sendSignInCode(to: string, code: string): Promise<void> {
    if (this.failNext) {
      this.failNext = false;
      throw new Error('simulated provider failure');
    }
    this.outbox.push({ to, code });
  }

  lastCodeFor(to: string): string | undefined {
    for (let i = this.outbox.length - 1; i >= 0; i -= 1) {
      const m = this.outbox[i];
      if (m && m.to === to) return m.code;
    }
    return undefined;
  }
}

/**
 * Development only: prints the code to the server log so a developer can sign
 * in without a mail provider. Refused in production by loadConfig().
 */
export class ConsoleEmailSender implements EmailSender {
  constructor(
    private readonly log: FastifyBaseLogger,
    private readonly pepper: string,
  ) {}

  async sendSignInCode(to: string, code: string): Promise<void> {
    this.log.warn(
      { who: emailHash(this.pepper, to).slice(0, 8), code },
      'DEV ONLY: sign-in code (not sent by e-mail)',
    );
  }
}

/**
 * Resend (https://resend.com) over HTTPS. Written against the documented
 * POST /emails endpoint; NOT exercised against the live service in CI (no
 * key). The owner's first real send is the integration test.
 */
export class ResendEmailSender implements EmailSender {
  constructor(
    private readonly apiKey: string,
    private readonly from: string,
    private readonly fetchImpl: typeof fetch = fetch,
  ) {}

  async sendSignInCode(to: string, code: string, ttlMinutes: number): Promise<void> {
    const { subject, text } = signInMessage(code, ttlMinutes);
    const res = await this.fetchImpl('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        authorization: `Bearer ${this.apiKey}`,
        'content-type': 'application/json',
      },
      body: JSON.stringify({ from: this.from, to: [to], subject, text }),
      signal: AbortSignal.timeout(10_000),
    });
    if (!res.ok) {
      // Status only. The response body can echo the address.
      throw new Error(`email provider returned HTTP ${res.status}`);
    }
  }
}

export function createEmailSender(config: Config, log: FastifyBaseLogger): EmailSender {
  if (config.emailProvider === 'resend') {
    return new ResendEmailSender(config.resendApiKey ?? '', config.emailFrom);
  }
  return new ConsoleEmailSender(log, config.pepper);
}

import pino, { type DestinationStream, type Logger } from 'pino';
import type { Config } from './config.js';

/**
 * Structured JSON logs with no personal data:
 *  - request logging is done by hand (see app.ts) from route patterns, never
 *    raw URLs, and never bodies, headers, e-mail addresses or IP addresses;
 *  - the redaction list is a second line of defence if someone logs an object.
 */
export const REDACT_PATHS = [
  'req.headers.authorization',
  'req.headers.cookie',
  'headers.authorization',
  'headers.cookie',
  '*.email',
  '*.to',
  '*.code',
  '*.token',
  '*.authorization',
  'email',
  'token',
  'authorization',
];

export function createLogger(config: Config, stream?: DestinationStream): Logger {
  return pino(
    {
      level: config.logLevel,
      base: { service: 'ar-rayaan-backend' },
      redact: { paths: REDACT_PATHS, censor: '[redacted]' },
      timestamp: pino.stdTimeFunctions.isoTime,
    },
    stream,
  );
}

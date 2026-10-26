import { randomUUID } from 'node:crypto';
import Fastify, { LogController, type FastifyBaseLogger, type FastifyInstance } from 'fastify';
import { ZodError } from 'zod';
import { registerAuthRoutes } from './auth.js';
import type { Deps } from './context.js';
import { ApiError } from './errors.js';
import { registerFriendRoutes } from './friends.js';
import { registerGuardianRoutes } from './guardian.js';
import { registerInviteRoutes } from './invites.js';
import { registerMeRoutes } from './me.js';
import { logId } from './security.js';

export interface RouteEntry {
  method: string;
  url: string;
}

declare module 'fastify' {
  interface FastifyInstance {
    /** Every registered route (used by the OpenAPI drift test). */
    routeTable: RouteEntry[];
  }
}

export interface BuildOptions {
  deps: Deps;
  logger: FastifyBaseLogger;
}

/** Request bodies are tiny JSON; anything bigger is refused. */
export const BODY_LIMIT_BYTES = 16 * 1024;

export async function buildApp({ deps, logger }: BuildOptions): Promise<FastifyInstance> {
  const { config } = deps;
  const app = Fastify({
    loggerInstance: logger,
    // Fastify's own request lines include the client address; we log by hand.
    logController: new LogController({ disableRequestLogging: true }),
    bodyLimit: BODY_LIMIT_BYTES,
    trustProxy: config.trustProxy,
    genReqId: () => randomUUID(),
    requestIdHeader: false,
  });

  const routeTable: RouteEntry[] = [];
  app.decorate('routeTable', routeTable);
  app.addHook('onRoute', (route) => {
    for (const method of Array.isArray(route.method) ? route.method : [route.method]) {
      routeTable.push({ method, url: route.url });
    }
  });

  // --- CORS: exact origins only (the app's own site). No wildcard, no cookies.
  const allowed = new Set(config.corsOrigins);
  app.addHook('onRequest', async (request, reply) => {
    const origin = request.headers.origin;
    void reply.header('vary', 'Origin');
    if (typeof origin === 'string' && allowed.has(origin)) {
      void reply.header('access-control-allow-origin', origin);
      void reply.header('access-control-allow-headers', 'authorization, content-type');
      void reply.header('access-control-allow-methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
      void reply.header('access-control-max-age', '600');
    }
    if (request.method === 'OPTIONS') {
      return reply.code(204).send();
    }
    return undefined;
  });

  // --- Security headers on every response (an API, so very strict).
  app.addHook('onSend', async (_request, reply) => {
    void reply.header('x-content-type-options', 'nosniff');
    void reply.header('cache-control', 'no-store');
    void reply.header('referrer-policy', 'no-referrer');
    void reply.header('content-security-policy', "default-src 'none'; frame-ancestors 'none'");
    void reply.header('strict-transport-security', 'max-age=15552000; includeSubDomains');
  });

  // --- One access-log line per request. Route pattern, status, timing, and a
  // keyed short id for the account. No URL parameters, bodies, headers, e-mail
  // addresses or IP addresses.
  app.addHook('onResponse', async (request, reply) => {
    request.log.info(
      {
        method: request.method,
        route: request.routeOptions.url ?? 'unmatched',
        status: reply.statusCode,
        ms: Math.round(reply.elapsedTime),
        actor: request.auth ? logId(config.pepper, request.auth.userId) : undefined,
      },
      'request',
    );
  });

  app.setErrorHandler((err, request, reply) => {
    if (err instanceof ApiError) {
      void reply.code(err.status).send({
        error: { code: err.code, message: err.message, ...err.extra },
      });
      return;
    }
    if (err instanceof ZodError) {
      void reply.code(400).send({
        error: { code: 'validation_failed', message: 'Some fields are missing or not valid.' },
      });
      return;
    }
    const fe = err as { statusCode?: number; code?: string };
    if (typeof fe.statusCode === 'number' && fe.statusCode >= 400 && fe.statusCode < 500) {
      const tooBig = fe.code === 'FST_ERR_CTP_BODY_TOO_LARGE';
      void reply.code(fe.statusCode).send({
        error: {
          code: tooBig ? 'payload_too_large' : 'bad_request',
          message: tooBig ? 'That request is too large.' : 'The request could not be read.',
        },
      });
      return;
    }
    // Unexpected: log the error class and message, never the request.
    request.log.error({ err: { type: (err as Error).name, message: (err as Error).message } }, 'unhandled error');
    void reply.code(500).send({ error: { code: 'internal', message: 'Something went wrong on our side.' } });
  });

  app.setNotFoundHandler((_request, reply) => {
    void reply.code(404).send({ error: { code: 'not_found', message: 'Not found.' } });
  });

  // --- Health. /healthz never touches the database (Render restarts the
  // service when it fails); /readyz does.
  app.get('/healthz', async () => ({ status: 'ok' }));
  app.get('/readyz', async (_request, reply) => {
    try {
      await deps.db.query('select 1');
      return { status: 'ready' };
    } catch {
      void reply.code(503);
      return { status: 'database_unavailable' };
    }
  });

  await registerAuthRoutes(app, deps);
  await registerMeRoutes(app, deps);
  await registerGuardianRoutes(app, deps);
  await registerFriendRoutes(app, deps);
  await registerInviteRoutes(app, deps);
  return app;
}

# Ar-Rayaan community backend (skeleton, OFF by default)

Node 22 + TypeScript + Fastify 5 + PostgreSQL 16. Design and decisions:
`docs/product/backend_community_plan.md`. Nothing here is deployed.

Firebase Auth stays the identity provider; Firestore game tables stay.
This service holds the relational, child-safety and moderation data.

## Run locally (no database needed)

    cd backend && npm ci
    npm test                 # in-memory Postgres (PGlite)
    TEST_DATABASE_URL=postgres://... npm test   # real PostgreSQL
    npm run typecheck && npm run build

Development server: copy `.env.example` to `.env` (never commit it), then
`npm run dev`. Migrations are plain SQL in `migrations/`; `npm run migrate`.

## Configuration

See `.env.example`. Secrets (`PEPPER`, `DATABASE_URL`, `RESEND_API_KEY`) are
set only in the hosting dashboard. `AUTH_MODE=firebase` needs
`FIREBASE_PROJECT_ID` and sends no email.

## Layout

- `src/` routes (auth, me, guardian, friends, invites), policy, jobs
- `migrations/` schema (SQL), `openapi.yaml` API contract (drift-tested)
- `render.yaml` Render blueprint, NOT applied; `Dockerfile` multi-stage build

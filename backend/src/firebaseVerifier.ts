import { createPublicKey, createVerify, type KeyObject } from 'node:crypto';

/**
 * Verifies a Firebase Authentication ID token without the Admin SDK, using
 * only the published Google signing keys (JWKS). The app already signs people
 * in with Firebase (lib/features/auth); the backend trusts that identity
 * instead of running a second login system in production.
 *
 * Checks, per Google's documentation for verifying ID tokens: RS256 with a
 * key from the JWKS, `iss` = https://securetoken.google.com/<project>,
 * `aud` = <project>, not expired, issued in the past, non-empty `sub`.
 * On top of that we REQUIRE a real e-mail identity: anonymous Firebase users
 * (which the online game tables use) can never become community accounts.
 */
export const JWKS_URL =
  'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com';

export interface FirebaseIdentity {
  uid: string;
  email: string;
  emailVerified: boolean;
}

export class TokenRejected extends Error {
  constructor(public readonly reason: string) {
    super(reason);
    this.name = 'TokenRejected';
  }
}

interface Jwk {
  kid: string;
  kty: string;
  n: string;
  e: string;
}

type FetchLike = (url: string) => Promise<Response>;

export class FirebaseVerifier {
  private keys = new Map<string, KeyObject>();
  private expiresAt = 0;

  constructor(
    private readonly projectId: string,
    private readonly now: () => Date = () => new Date(),
    private readonly fetchImpl: FetchLike = (u) => fetch(u, { signal: AbortSignal.timeout(5000) }),
  ) {}

  private async keyFor(kid: string): Promise<KeyObject> {
    const stale = this.now().getTime() >= this.expiresAt;
    if (stale || !this.keys.has(kid)) {
      // Refresh at most when stale or when an unknown key id shows up.
      const res = await this.fetchImpl(JWKS_URL);
      if (!res.ok) throw new TokenRejected('key_fetch_failed');
      const body = (await res.json()) as { keys?: Jwk[] };
      const next = new Map<string, KeyObject>();
      for (const k of body.keys ?? []) {
        if (k.kty === 'RSA') {
          next.set(k.kid, createPublicKey({ key: k as unknown as import('node:crypto').JsonWebKey, format: 'jwk' }));
        }
      }
      this.keys = next;
      const m = /max-age=(\d+)/.exec(res.headers.get('cache-control') ?? '');
      this.expiresAt = this.now().getTime() + (m ? Number(m[1]) : 3600) * 1000;
    }
    const key = this.keys.get(kid);
    if (!key) throw new TokenRejected('unknown_key');
    return key;
  }

  async verify(idToken: string): Promise<FirebaseIdentity> {
    const parts = idToken.split('.');
    if (parts.length !== 3 || idToken.length > 4096) throw new TokenRejected('malformed');
    const [h, p, sig] = parts as [string, string, string];
    let header: { alg?: string; kid?: string };
    let claims: Record<string, unknown>;
    try {
      header = JSON.parse(Buffer.from(h, 'base64url').toString('utf8'));
      claims = JSON.parse(Buffer.from(p, 'base64url').toString('utf8'));
    } catch {
      throw new TokenRejected('malformed');
    }
    if (header.alg !== 'RS256' || typeof header.kid !== 'string') throw new TokenRejected('bad_alg');

    const key = await this.keyFor(header.kid);
    const ok = createVerify('RSA-SHA256')
      .update(`${h}.${p}`)
      .verify(key, Buffer.from(sig, 'base64url'));
    if (!ok) throw new TokenRejected('bad_signature');

    const nowSec = Math.floor(this.now().getTime() / 1000);
    const skew = 60;
    if (claims.iss !== `https://securetoken.google.com/${this.projectId}`) throw new TokenRejected('bad_issuer');
    if (claims.aud !== this.projectId) throw new TokenRejected('bad_audience');
    if (typeof claims.exp !== 'number' || claims.exp + skew < nowSec) throw new TokenRejected('expired');
    if (typeof claims.iat !== 'number' || claims.iat - skew > nowSec) throw new TokenRejected('issued_in_future');
    if (typeof claims.sub !== 'string' || claims.sub.length === 0 || claims.sub.length > 128) {
      throw new TokenRejected('bad_subject');
    }
    const fb = claims.firebase as { sign_in_provider?: string } | undefined;
    if (!fb || fb.sign_in_provider === 'anonymous') throw new TokenRejected('anonymous');
    if (typeof claims.email !== 'string' || claims.email.length === 0) throw new TokenRejected('no_email');
    return { uid: claims.sub, email: claims.email, emailVerified: claims.email_verified === true };
  }
}

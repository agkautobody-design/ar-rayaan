/**
 * Fixed-window rate limiter held in memory. Correct for ONE service instance
 * (the Render starter plan). If the service is ever scaled to several
 * instances, move the counters to PostgreSQL or Redis; the interface stays.
 * Keys are never logged.
 */
export interface HitResult {
  allowed: boolean;
  remaining: number;
  retryAfterSec: number;
}

interface Bucket {
  count: number;
  resetAt: number;
}

export class RateLimiter {
  private readonly buckets = new Map<string, Bucket>();

  constructor(
    private readonly now: () => number = Date.now,
    private readonly maxKeys = 100_000,
  ) {}

  hit(key: string, max: number, windowMs: number): HitResult {
    const t = this.now();
    let b = this.buckets.get(key);
    if (b === undefined || b.resetAt <= t) {
      if (this.buckets.size >= this.maxKeys) this.sweep();
      b = { count: 0, resetAt: t + windowMs };
      this.buckets.set(key, b);
    }
    b.count += 1;
    const allowed = b.count <= max;
    return {
      allowed,
      remaining: Math.max(0, max - b.count),
      retryAfterSec: allowed ? 0 : Math.max(1, Math.ceil((b.resetAt - t) / 1000)),
    };
  }

  /** True when [key] has already used up [max] hits in its current window. */
  isExhausted(key: string, max: number): boolean {
    const b = this.buckets.get(key);
    return b !== undefined && b.resetAt > this.now() && b.count >= max;
  }

  /** Drops expired buckets; if still full, drops the oldest half. */
  sweep(): void {
    const t = this.now();
    for (const [k, b] of this.buckets) if (b.resetAt <= t) this.buckets.delete(k);
    if (this.buckets.size >= this.maxKeys) {
      let i = 0;
      const drop = Math.floor(this.buckets.size / 2);
      for (const k of this.buckets.keys()) {
        if (i++ >= drop) break;
        this.buckets.delete(k);
      }
    }
  }

  get size(): number {
    return this.buckets.size;
  }
}

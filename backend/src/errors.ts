/** An error the API returns on purpose. [message] is safe to show a person. */
export class ApiError extends Error {
  constructor(
    public readonly status: number,
    public readonly code: string,
    message: string,
    public readonly extra?: Record<string, unknown>,
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

export const badRequest = (code: string, message: string, extra?: Record<string, unknown>) =>
  new ApiError(400, code, message, extra);
export const unauthorized = (message = 'Please sign in again.') =>
  new ApiError(401, 'unauthorized', message);
export const forbidden = (code: string, message: string) => new ApiError(403, code, message);
export const notFound = (message = 'Not found.') => new ApiError(404, 'not_found', message);
export const conflict = (code: string, message: string) => new ApiError(409, code, message);
export const unprocessable = (code: string, message: string) => new ApiError(422, code, message);
export const tooMany = (retryAfterSec: number) =>
  new ApiError(429, 'rate_limited', 'Too many attempts. Please wait a little and try again.', {
    retryAfterSec,
  });

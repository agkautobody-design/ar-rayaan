"""Ar-Rayaan Vault — the small guardian that holds the Quran Foundation
client secret server-side (never in any browser) and serves Content API
data to the app.

Endpoints:
  GET /healthz            -> {"ok": true}
  GET /qf/content/<path>  -> proxied JSON from apis.quran.foundation
                             (read-only Quran content paths only)

The access token itself is never handed out: anyone could reuse it under
Ar-Rayaan's Quran Foundation identity.

Env (set in Render, never in git):
  QF_CLIENT_ID      public client id
  QF_CLIENT_SECRET  the qfcs_... secret (Rotate at any time in QF console)
  VAULT_ORIGIN      the app's origin; requests from other sites are refused
                    (default https://ar-rayaan.onrender.com)
"""
import os
import time

import requests
from flask import Flask, jsonify, request, Response

app = Flask(__name__)

# Production token and production content together (the token used to
# come from the test "prelive" server while content came from production).
QF_TOKEN_URL = "https://oauth2.quran.foundation/oauth2/token"
QF_CONTENT = "https://apis.quran.foundation/content/api/v4/"

# Only the read-only content the app needs; anything else is refused so the
# vault is not an open proxy.
_ALLOWED_PREFIXES = (
    "chapters", "verses", "juzs", "recitations", "resources",
    "tafsirs", "translations", "quran", "audio",
)

_client_id = os.environ["QF_CLIENT_ID"]
_client_secret = os.environ["QF_CLIENT_SECRET"]
_vault_origin = os.environ.get("VAULT_ORIGIN", "https://ar-rayaan.onrender.com")

_cache = {"token": None, "expires_at": 0.0}


def _token():
    if _cache["token"] and time.time() < _cache["expires_at"] - 120:
        return _cache["token"]
    r = requests.post(
        QF_TOKEN_URL,
        auth=(_client_id, _client_secret),
        data={"grant_type": "client_credentials", "scope": "content"},
        timeout=20,
    )
    r.raise_for_status()
    body = r.json()
    _cache["token"] = body["access_token"]
    _cache["expires_at"] = time.time() + int(body.get("expires_in", 3600))
    return _cache["token"]


@app.after_request
def _cors(resp):
    resp.headers["Access-Control-Allow-Origin"] = _vault_origin
    resp.headers["Access-Control-Allow-Methods"] = "GET, OPTIONS"
    return resp


@app.get("/healthz")
def healthz():
    return jsonify(ok=True)


@app.get("/qf/content/<path:sub>")
def content(sub):
    origin = request.headers.get("Origin")
    if origin is not None and origin != _vault_origin:
        return jsonify(error="origin not allowed"), 403
    # Match whole path segments ("quran" but not "quranX"); no traversal.
    first = sub.split("/", 1)[0]
    if ".." in sub or first not in _ALLOWED_PREFIXES:
        return jsonify(error="path not allowed"), 404
    try:
        upstream = requests.get(
            QF_CONTENT + sub,
            params={k: v for k, v in request.args.items()},
            headers={
                "x-auth-token": _token(),
                "x-client-id": _client_id,
                "Accept": "application/json",
            },
            timeout=30,
        )
    except requests.RequestException:
        return jsonify(error="upstream unavailable"), 502
    return Response(
        upstream.content,
        status=upstream.status_code,
        content_type="application/json",
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 10000)))

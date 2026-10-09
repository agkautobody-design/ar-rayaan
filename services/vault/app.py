"""Ar-Rayaan Vault — the small guardian that holds the Quran Foundation
client secret server-side (never in any browser) and serves Content API
data to the app.

Endpoints:
  GET /healthz            -> {"ok": true}
  GET /qf/token           -> {"token": "...", "expires_in": 3600}
  GET /qf/content/<path>  -> proxied JSON from apis.quran.foundation

Env (set in Render, never in git):
  QF_CLIENT_ID      public client id
  QF_CLIENT_SECRET  the qfcs_... secret (Rotate at any time in QF console)
  VAULT_ORIGIN      optional; when set, CORS is restricted to it
"""
import os
import time

import requests
from flask import Flask, jsonify, request, Response

app = Flask(__name__)

QF_TOKEN_URL = "https://prelive-oauth2.quran.foundation/oauth2/token"
QF_CONTENT = "https://apis.quran.foundation/content/api/v4/"

_client_id = os.environ["QF_CLIENT_ID"]
_client_secret = os.environ["QF_CLIENT_SECRET"]
_vault_origin = os.environ.get("VAULT_ORIGIN", "*")

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


@app.get("/qf/token")
def token():
    return jsonify(token=_token(), expires_in=3600)


@app.get("/qf/content/<path:sub>")
def content(sub):
    upstream = requests.get(
        QF_CONTENT + sub,
        params={k: v for k, v in request.args.items()},
        headers={
            "x-auth-token": _token(),
            "Accept": "application/json",
        },
        timeout=30,
    )
    return Response(
        upstream.content,
        status=upstream.status_code,
        content_type="application/json",
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 10000)))

# Audio CDN CORS check (web build at https://ar-rayaan.onrender.com)

Status: NOT MEASURED from the CI/agent sandbox. Every outbound connection to
the audio hosts is refused by the sandbox proxy, so no header was observed.
This file records what was tried, what the app actually uses, and the exact
test to run in a real browser.

## Hosts the app plays audio from

| Host | Used by | Notes |
| --- | --- | --- |
| everyayah.com | `lib/features/academy/domain/recitation_audio.dart` (every reciter: `ayahBaseUrl`), `lib/app/core/sound/sound_services.dart` | per-ayah mp3, e.g. `https://everyayah.com/data/Alafasy_128kbps/001001.mp3` |
| server13.mp3quran.net | same file, `surahBaseUrl` of the Husary entry | whole-surah mp3, `https://server13.mp3quran.net/husr/001.mp3`; used only by `recitation_audio_repository.dart` (offline download), so not on the web playback path |

`assets/academy/player_catalog.json` contains only bundled files
(`assets/assets/audio/adhan_mecca.mp3`, `ambient.mp3`, same origin, no CORS
question) and `officialUrl` links to youtube.com that open in a new tab (not
fetched). `cdn.islamic.network` and `api.aladhan.com` appear in the platform
audit; in `lib` only `api.aladhan.com` (prayer-times JSON, a `fetch`, so CORS
does apply there) is used, not for audio.

## What was tried

`curl -I -H "Origin: https://ar-rayaan.onrender.com" https://everyayah.com/...`
returns `CONNECT tunnel failed, response 403` from the agent proxy; the same
for `server13.mp3quran.net` and `cdn.islamic.network`. The proxy only allows
specific hosts, so no response headers could be read. Nothing was bypassed.

## Why it matters (and what is not known)

A plain `<audio src>` element (what a simple web audio player uses) can play
a cross-origin mp3 without any CORS header; CORS is required only when the
page reads the bytes (`fetch`/XHR, Web Audio `MediaElementSource` on a
`crossorigin` element, canvas visualisation, caching to IndexedDB). Whether
the `audioplayers` web implementation sets `crossorigin` on its element was
not verified here (package source is not available in this sandbox), so this
must be confirmed in the browser test below. The app does not cache audio on
web (`recitation_player_provider.dart` returns the URL directly when `kIsWeb`).

## Exact test to run in a real browser

1. Open https://ar-rayaan.onrender.com in Chrome, open DevTools, Network tab,
   tick "Disable cache".
2. Quran > pick any ayah > play. Repeat with each reciter in the picker.
   (Web streams per-ayah files from everyayah.com only.)
3. For each request to everyayah.com or server13.mp3quran.net check: status
   200/206, the audio plays, no red "CORS" or "blocked" entry in Console.
4. In the Console of the app tab run this, once per host:

```js
for (const u of [
  'https://everyayah.com/data/Alafasy_128kbps/001001.mp3',
  'https://server13.mp3quran.net/husr/001.mp3',
]) {
  fetch(u, { method: 'HEAD' })
    .then(r => console.log(u, r.status,
      'ACAO=', r.headers.get('access-control-allow-origin')))
    .catch(e => console.log(u, 'BLOCKED by CORS/network:', e.message));
}
```

   `ACAO` of `*` or `https://ar-rayaan.onrender.com` means fetch-level access
   works (needed if offline caching of audio on web is ever added). A
   `BLOCKED` result with audio still playing from the Network tab means
   playback works only because `<audio>` does not need CORS; keep web audio
   caching off in that case.
5. From a terminal with unrestricted network:

```sh
curl -sI -H 'Origin: https://ar-rayaan.onrender.com' \
  https://everyayah.com/data/Alafasy_128kbps/001001.mp3 | grep -i '^access-control'
curl -sI -H 'Origin: https://ar-rayaan.onrender.com' \
  https://server13.mp3quran.net/husr/001.mp3 | grep -i '^access-control'
```

Record the results below when run.

| Host | Playback in browser | ACAO header | Date / by |
| --- | --- | --- | --- |
| everyayah.com | untested | untested | |
| server13.mp3quran.net | untested | untested | |

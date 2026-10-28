'use strict';

/*
 * Ar-Rayaan offline shell.
 *
 * What it does: after the app has been opened once online in this browser, it
 * opens again with no connection, because the files that make up the app (the
 * page, the script, the renderer, fonts, images) are kept in this cache.
 *
 * What it must never do: serve an old build while a network is available. So
 * every request goes to the network FIRST and the cached copy is used only
 * when the network fails or is very slow (more than 6 seconds). Each good
 * network answer replaces the cached copy, so the cache always holds the
 * newest build this browser has seen, and a new deploy is picked up the next
 * time the app opens online. The earlier decision not to register a caching
 * worker (a stale build means stale safety text) is kept by this rule.
 *
 * One other site is handled: the Firebase script from www.gstatic.com, kept
 * so the app can start offline (see isFirebaseScript).
 *
 * Not handled here, on purpose: other sites (recitation audio, maps, APIs),
 * partial (Range) requests, and anything that is not a GET. Recitation the
 * person chose to save lives in its own cache (ar-dl-audio-v1) and the saved
 * Qur'an and lesson text in ar-content-v1; this worker never touches those.
 */

const CACHE = 'ar-app-v1';
const SLOW_MS = 6000;

// Fetched on install so a first visit that goes offline straight afterwards
// still has the core. Everything else is added as it is used (see 'fetch')
// and from the list of files the page reports after it has drawn (see
// 'message').
const SHELL = [
  './',
  'index.html',
  'flutter_bootstrap.js',
  'flutter.js',
  'main.dart.js',
  'manifest.json',
  'favicon.png',
  'icons/Icon-192.png',
  'assets/FontManifest.json',
  'assets/AssetManifest.bin.json',
  'canvaskit/canvaskit.js',
  'canvaskit/canvaskit.wasm',
  'canvaskit/chromium/canvaskit.js',
  'canvaskit/chromium/canvaskit.wasm',
];

function shellKey() {
  return new Request(new URL('index.html', self.registration.scope).href);
}

self.addEventListener('install', (event) => {
  event.waitUntil(
    (async () => {
      const cache = await caches.open(CACHE);
      await Promise.all(
        SHELL.map((path) =>
          cache
            .add(new Request(new URL(path, self.registration.scope).href, { cache: 'reload' }))
            .catch(() => {})
        )
      );
      await self.skipWaiting();
    })()
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const keys = await caches.keys();
      await Promise.all(
        keys
          .filter((k) => k.indexOf('ar-app-') === 0 && k !== CACHE)
          .map((k) => caches.delete(k))
      );
      await self.clients.claim();
    })()
  );
});

// The Firebase web SDK is a script the app loads from Google at start-up
// (www.gstatic.com/firebasejs/<version>/...). Without a kept copy the app
// could not start with no internet, even though everything else is cached.
// These files are versioned by their address and never change under the same
// address, so a kept copy is used first and the network only fills the cache.
function isFirebaseScript(url) {
  return (
    url.protocol === 'https:' &&
    url.hostname === 'www.gstatic.com' &&
    url.pathname.indexOf('/firebasejs/') === 0 &&
    url.pathname.endsWith('.js')
  );
}

async function handleFirebaseScript(request) {
  const cache = await caches.open(CACHE);
  const cached = await cache.match(request.url);
  if (cached) return cached;
  const response = await fetch(request);
  // A module import is a CORS request, so a good answer is type 'cors'.
  if (response && response.ok && (response.type === 'cors' || response.type === 'basic')) {
    try {
      await cache.put(request.url, response.clone());
    } catch (e) {
      // Storage full or blocked: the response is still used now.
    }
  }
  return response;
}

function cacheable(request, url) {
  if (request.method !== 'GET') return false;
  if (url.origin !== self.location.origin) return false;
  if (request.headers.has('range')) return false;
  // The version check must always see the network (or fail), never a copy.
  if (url.pathname.endsWith('/version.json')) return false;
  if (url.pathname.endsWith('/ar_sw.js')) return false;
  return true;
}

async function handle(request) {
  const url = new URL(request.url);
  const key = request.mode === 'navigate' ? shellKey() : request;
  const cache = await caches.open(CACHE);
  const cached = await cache.match(key, { ignoreSearch: request.mode !== 'navigate' });

  const network = fetch(request).then(async (response) => {
    if (response && response.ok && response.type === 'basic') {
      try {
        await cache.put(key, response.clone());
      } catch (e) {
        // Storage full or blocked: the response is still used now.
      }
    }
    return response;
  });

  network.catch(() => {}); // a late failure after the copy was served is fine
  if (!cached) return network;

  // A copy exists: the network wins when it answers in time; otherwise the
  // copy is used and the network answer still refreshes the cache for later.
  const slow = new Promise((resolve) => setTimeout(() => resolve(cached), SLOW_MS));
  try {
    return await Promise.race([network, slow]);
  } catch (e) {
    return cached;
  }
}

self.addEventListener('fetch', (event) => {
  const request = event.request;
  const url = new URL(request.url);
  if (request.method === 'GET' && !request.headers.has('range') && isFirebaseScript(url)) {
    event.respondWith(handleFirebaseScript(request));
    return;
  }
  if (!cacheable(request, url)) return;
  event.respondWith(
    handle(request).catch(() => Response.error())
  );
});

// The page lists the files it used while drawing; keep any that are missing.
self.addEventListener('message', (event) => {
  const data = event.data;
  if (!data || data.type !== 'cache-urls' || !Array.isArray(data.urls)) return;
  event.waitUntil(
    (async () => {
      const cache = await caches.open(CACHE);
      const todo = [];
      for (const raw of data.urls) {
        let u;
        try {
          u = new URL(raw);
        } catch (e) {
          continue;
        }
        if (isFirebaseScript(u)) {
          if (!(await cache.match(u.href))) todo.push(u.href);
          continue;
        }
        if (u.origin !== self.location.origin) continue;
        if (u.pathname.endsWith('/version.json') || u.pathname.endsWith('/ar_sw.js')) continue;
        if (await cache.match(u.href, { ignoreSearch: true })) continue;
        todo.push(u.href);
      }
      // A few at a time, so a slow phone is not flooded.
      for (let i = 0; i < todo.length; i += 4) {
        await Promise.all(
          todo.slice(i, i + 4).map((href) => cache.add(href).catch(() => {}))
        );
      }
    })()
  );
});

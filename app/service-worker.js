const CACHE_NAME = "direcao-turma-v5";
const PRECACHE = [
  "./",
  "index.html",
  "login.html",
  "css/styles.css",
  "js/core/config.js",
  "js/core/session.js",
  "js/core/auth.js",
  "js/core/permissions.js",
  "js/services/turmas.service.js",
  "js/services/alunos.service.js",
  "js/services/encarregados.service.js",
  "js/services/registos.service.js",
  "js/services/documentos.service.js",
  "js/services/reunioes.service.js",
  "js/utils/dates.js",
  "manifest.json",
  "assets/logo.png",
  "https://cdn.jsdelivr.net/npm/@supabase/supabase-js",
];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return Promise.allSettled(
        PRECACHE.map((url) =>
          cache.add(url).catch((err) => {
            console.warn(`Precache falhou para: ${url}`, err);
          }),
        ),
      );
    }),
  );
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys.map((key) => {
          if (key !== CACHE_NAME) return caches.delete(key);
        }),
      ),
    ),
  );
  self.clients.claim();
});

self.addEventListener("fetch", (event) => {
  const req = event.request;
  const url = new URL(req.url);

  if (
    req.mode === "navigate" ||
    (req.method === "GET" && req.headers.get("accept")?.includes("text/html"))
  ) {
    event.respondWith(
      fetch(req)
        .then((res) => {
          if (res && res.status === 200) {
            const copy = res.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(req, copy));
          }
          return res;
        })
        .catch(() => caches.match(req).then((r) => r || caches.match("index.html"))),
    );
    return;
  }

  event.respondWith(
    caches.match(req).then((cached) => {
      const networkFetch = fetch(req)
        .then((res) => {
          if (req.method === "GET" && res && res.status === 200) {
            const resClone = res.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(req, resClone));
          }
          return res;
        })
        .catch(() => null);
      return cached || networkFetch;
    }),
  );
});

self.addEventListener("message", (event) => {
  if (event.data && event.data.type === "SKIP_WAITING") {
    self.skipWaiting();
  }
});

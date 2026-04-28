// FitTrack Pro Service Worker v4
// 策略修正：HTML/JS 同源 → network-first（保证新版立即生效）
//          静态资源 → cache-first
//          外部 CDN → stale-while-revalidate
const CACHE = 'fittrack-pro-v15';
const CORE = [
  './',
  './index.html',
  './fit-app-pro.html',
  './manifest.webmanifest',
  './icon.svg',
  './icon-192.png',
  './icon-512.png',
  './apple-touch-icon.png'
];

self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open(CACHE).then((c) => c.addAll(CORE)).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

// 判断是否为应用页面/脚本（需要总是拿最新）
function isAppFile(url) {
  return /\.(html|js|webmanifest)$/.test(url.pathname) || url.pathname === '/' || url.pathname.endsWith('/');
}

self.addEventListener('fetch', (e) => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);

  // 同源
  if (url.origin === location.origin) {
    if (isAppFile(url)) {
      // network-first：先尝试网络，失败再用缓存
      e.respondWith(
        fetch(req).then((res) => {
          const copy = res.clone();
          caches.open(CACHE).then((c) => c.put(req, copy));
          return res;
        }).catch(() => caches.match(req))
      );
    } else {
      // 静态资源（图标等）cache-first
      e.respondWith(
        caches.match(req).then((cached) =>
          cached || fetch(req).then((res) => {
            const copy = res.clone();
            caches.open(CACHE).then((c) => c.put(req, copy));
            return res;
          })
        )
      );
    }
    return;
  }

  // 跨域 CDN：stale-while-revalidate
  e.respondWith(
    caches.match(req).then((cached) => {
      const network = fetch(req).then((res) => {
        const copy = res.clone();
        caches.open(CACHE).then((c) => c.put(req, copy));
        return res;
      }).catch(() => cached);
      return cached || network;
    })
  );
});

// 接收页面消息：立即激活
self.addEventListener('message', (e) => {
  if (e.data === 'SKIP_WAITING') self.skipWaiting();
});

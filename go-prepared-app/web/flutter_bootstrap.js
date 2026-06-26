{{flutter_js}}
{{flutter_build_config}}

(function () {
  const VERSION_KEY = 'goprepared.app.version';
  const VERSION_POLL_MS = 5 * 60 * 1000;

  async function bustCacheIfNewRelease() {
    try {
      const res = await fetch('/version.json?t=' + Date.now(), { cache: 'no-store' });
      if (!res.ok) return false;
      const data = await res.json();
      const label = `${data.version}+${data.build_number}`;
      const prev = localStorage.getItem(VERSION_KEY);
      if (prev && prev !== label) {
        if ('caches' in window) {
          const names = await caches.keys();
          await Promise.all(names.map((n) => caches.delete(n)));
        }
        localStorage.setItem(VERSION_KEY, label);
        location.reload();
        return true;
      }
      if (!prev) localStorage.setItem(VERSION_KEY, label);
    } catch (err) {
      console.warn('[GoPrepared] version check failed', err);
    }
    return false;
  }

  function listenForWaitingWorker() {
    if (!('serviceWorker' in navigator)) return;

    navigator.serviceWorker.addEventListener('controllerchange', () => {
      location.reload();
    });

    const activateWaiting = (reg) => {
      if (reg.waiting && navigator.serviceWorker.controller) {
        reg.waiting.postMessage({ type: 'skipWaiting' });
      }
    };

    navigator.serviceWorker.getRegistration().then((reg) => {
      if (!reg) return;
      activateWaiting(reg);
      reg.addEventListener('updatefound', () => {
        const worker = reg.installing;
        if (!worker) return;
        worker.addEventListener('statechange', () => {
          if (worker.state === 'installed' && navigator.serviceWorker.controller) {
            worker.postMessage({ type: 'skipWaiting' });
          }
        });
      });
    });

    // Re-check when user returns to a backgrounded tab
    document.addEventListener('visibilitychange', () => {
      if (document.visibilityState === 'visible') {
        bustCacheIfNewRelease();
        navigator.serviceWorker.getRegistration().then(activateWaiting);
      }
    });
  }

  window.addEventListener('load', async () => {
    listenForWaitingWorker();
    if (await bustCacheIfNewRelease()) return;

    _flutter.loader.load({
      serviceWorkerSettings: {
        serviceWorkerVersion: {{flutter_service_worker_version}},
      },
    });

    setInterval(() => bustCacheIfNewRelease(), VERSION_POLL_MS);
  });
})();

{{flutter_js}}
{{flutter_build_config}}

(function () {
  const VERSION_KEY = 'goprepared.app.version';
  const VERSION_POLL_MS = 5 * 60 * 1000;

  function isLocalDev() {
    const h = location.hostname;
    return h === 'localhost' || h === '127.0.0.1' || h === '[::1]';
  }

  function releaseLabel(data) {
    let label = `${data.version}+${data.build_number}`;
    if (data.build_id) label += `+${data.build_id}`;
    return label;
  }

  async function unregisterServiceWorkers() {
    if (!('serviceWorker' in navigator)) return;
    const registrations = await navigator.serviceWorker.getRegistrations();
    await Promise.all(registrations.map((reg) => reg.unregister()));
  }

  async function clearAllCaches() {
    if (!('caches' in window)) return;
    const names = await caches.keys();
    await Promise.all(names.map((name) => caches.delete(name)));
  }

  async function purgeClientCaches() {
    await unregisterServiceWorkers();
    await clearAllCaches();
  }

  async function fetchReleaseLabel() {
    const res = await fetch('/version.json?t=' + Date.now(), { cache: 'no-store' });
    if (!res.ok) return null;
    const data = await res.json();
    return releaseLabel(data);
  }

  async function bustCacheIfNewRelease() {
    try {
      const label = await fetchReleaseLabel();
      if (!label) return false;

      const prev = localStorage.getItem(VERSION_KEY);
      if (prev && prev !== label) {
        await purgeClientCaches();
        // Keep the old label until the next load fetches fresh assets.
        localStorage.removeItem(VERSION_KEY);
        const url = new URL(location.href);
        url.searchParams.set('_gp', String(Date.now()));
        location.replace(url.toString());
        return true;
      }
      if (!prev) localStorage.setItem(VERSION_KEY, label);
    } catch (err) {
      console.warn('[GoPrepared] version check failed', err);
    }
    return false;
  }

  function listenForWaitingWorker() {
    if (isLocalDev() || !('serviceWorker' in navigator)) return;

    let refreshing = false;
    navigator.serviceWorker.addEventListener('controllerchange', () => {
      if (refreshing) return;
      refreshing = true;
      location.reload();
    });

    const activateWaiting = (reg) => {
      const worker = reg?.waiting || reg?.installing;
      if (worker && navigator.serviceWorker.controller) {
        worker.postMessage({ type: 'skipWaiting' });
      }
    };

    navigator.serviceWorker.getRegistration().then((reg) => {
      if (!reg) return;
      reg.update().catch(() => {});
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

    document.addEventListener('visibilitychange', () => {
      if (document.visibilityState !== 'visible') return;
      bustCacheIfNewRelease();
      navigator.serviceWorker.getRegistration().then((reg) => {
        if (!reg) return;
        reg.update().catch(() => {});
        activateWaiting(reg);
      });
    });
  }

  async function startFlutter() {
    const loadConfig = {};
    if (!isLocalDev()) {
      loadConfig.serviceWorkerSettings = {
        serviceWorkerVersion: {{flutter_service_worker_version}},
      };
    }
    _flutter.loader.load(loadConfig);
    if (!isLocalDev()) {
      setInterval(() => bustCacheIfNewRelease(), VERSION_POLL_MS);
    }
  }

  async function boot() {
    listenForWaitingWorker();
    if (!isLocalDev() && (await bustCacheIfNewRelease())) return;
    await startFlutter();
  }

  boot();
})();

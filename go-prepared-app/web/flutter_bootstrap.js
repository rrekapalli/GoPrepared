{{flutter_js}}
{{flutter_build_config}}

(function () {
  const VERSION_KEY = 'goprepared.app.version';
  const VERSION_POLL_MS = 60 * 1000;

  function isLocalDev() {
    const h = location.hostname;
    return h === 'localhost' || h === '127.0.0.1' || h === '[::1]';
  }

  function versionUrl() {
    return new URL('version.json', document.baseURI).toString();
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
    const res = await fetch(versionUrl() + '?t=' + Date.now(), {
      cache: 'no-store',
      headers: { 'Cache-Control': 'no-cache', Pragma: 'no-cache' },
    });
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
        localStorage.setItem(VERSION_KEY, label);
        const url = new URL(location.href);
        url.searchParams.set('_gp', String(Date.now()));
        location.replace(url.toString());
        return true;
      }
      if (!prev || prev !== label) localStorage.setItem(VERSION_KEY, label);
    } catch (err) {
      console.warn('[GoPrepared] version check failed', err);
    }
    return false;
  }

  function scheduleVersionChecks() {
    if (isLocalDev()) return;

    const check = () => {
      bustCacheIfNewRelease();
    };

    setInterval(check, VERSION_POLL_MS);
    window.addEventListener('focus', check);
    window.addEventListener('pageshow', (event) => {
      if (event.persisted) check();
    });
    document.addEventListener('visibilitychange', () => {
      if (document.visibilityState === 'visible') check();
    });
  }

  async function startFlutter() {
    _flutter.loader.load({});
    scheduleVersionChecks();
  }

  async function boot() {
    if (!isLocalDev() && (await bustCacheIfNewRelease())) return;
    await startFlutter();
  }

  boot();
})();

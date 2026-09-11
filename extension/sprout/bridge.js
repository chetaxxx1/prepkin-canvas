// The one thing added to Sprout's page: a way for the content script to ask
// for an emote from outside the frame. The frame is the extension's own
// origin and the page it sits on is the school's, so nothing crosses except
// these few words, and the frame never answers with anything but "ready".
(function () {
  const ok = (v) => typeof v === 'string' && /^[a-z]+$/.test(v);
  window.addEventListener('message', (e) => {
    const m = e.data;
    const S = window.RiverSprite;
    if (!m || m.prepkin !== 'sprout' || !S) return;
    switch (m.do) {
      case 'play': if (ok(m.emote)) S.play(m.emote); break;
      case 'signature': S.signature(); break;
      case 'wake': if (S.isSleeping()) S.wake(); break;
      case 'paused': S.setPaused(!!m.value); break;
      case 'reduceMotion': S.setReduceMotion(!!m.value); break;
    }
  });
  // Tell the host once the character is up, so its first request is not lost.
  const tick = () => {
    if (window.RiverSprite) window.parent.postMessage({ prepkin: 'sprout', event: 'ready' }, '*');
    else setTimeout(tick, 50);
  };
  tick();
})();

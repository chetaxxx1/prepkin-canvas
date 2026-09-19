// Runs at document_start, before Canvas paints, so a dark paper never flashes
// white and a page never paints the school's theme first and ours second.
// Only the classes go on here; everything that needs the DOM waits for
// content.js at document_end.
(async () => {
  try {
    if (isLoginPath(location.pathname) || isQuizTake(location.pathname) || isSubmissionPath(location.pathname, location.hash)) return;
    const s = await chrome.storage.local.get(['skin', 'wallet', 'putBack', 'flags', 'lastPayload', 'ownArt']);
    if (remoteKill(s.flags, {
      host: location.host,
      page: pageName(location.pathname),
      version: chrome.runtime.getManifest().version,
      now: Date.now(),
    })) return;
    const skin = { dark: false, cards: true, mascot: true, ...(s.skin ?? {}) };
    if (skin.mode === 'auto') skin.dark = matchMedia('(prefers-color-scheme: dark)').matches;
    // On a synced dashboard the rail will replace Canvas's To Do, so its box
    // is folded from the first paint rather than after its spinner has shown.
    // content.js checks the real page and takes the class back if the rail
    // turns out not to draw.
    const putBack = s.putBack ?? {};
    const todoFold = /^\/(dashboard)?\/?$/.test(location.pathname) && !!s.lastPayload?.at && !putBack.week && !putBack['todo-fold'];
    // "Your picture" is a look only with a photo behind it; the photo's own
    // colours ride on the look. content.js `wornLook()` is the same answer.
    const base = LOOKS_BY_ID[s.wallet?.wearing] ?? LOOKS_BY_ID.classic;
    const look = base.art !== 'own' ? base : (s.ownArt?.src ? { ...base, ...(s.ownArt.palette ?? {}) } : LOOKS_BY_ID.classic);
    const classes = skinClasses({
      on: !!skin.cards, dark: !!skin.dark, dense: !!skin.dense, hidePast: !!skin.hidePast, gradeHover: !!skin.cardGradesHover,
      look,
      putBack, detect: { todoFold },
    });
    document.documentElement.classList.add(...classes);
    if (classes.length) {
      const art = artFor(look, ART_AVAILABLE, (f) => chrome.runtime.getURL(f), s.ownArt ?? null);
      const style = document.getElementById('pk-theme-vars') ?? document.createElement('style');
      style.id = 'pk-theme-vars';
      style.textContent = themeStyle(look, textureImage, art);
      document.documentElement.append(style);
      // The wall and the four banners are asked for now, so the cards wear
      // them the moment they render: a dashboard once showed four seconds of
      // Canvas's flat bands while the pictures were still being read
      // (the tour of 2026-09-19). Extension files, no request leaves.
      if (art && /^\/(dashboard)?\/?$/.test(location.pathname)) {
        for (const src of [art.wallpaper, ...(art.cards ?? [])]) { const img = new Image(); img.decoding = 'async'; img.src = src; }
      }
    }
  } catch {
    // No storage, no skin. The page is Canvas, unchanged.
    for (const name of [...document.documentElement.classList]) if (name.startsWith('pk-')) document.documentElement.classList.remove(name);
    document.querySelectorAll('#pk-theme-vars').forEach((el) => el.remove());
  }
})();

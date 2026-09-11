// Runs at document_start, before Canvas paints, so a dark paper never flashes
// white and a page never paints the school's theme first and ours second.
// Only the classes go on here; everything that needs the DOM waits for
// content.js at document_end.
(async () => {
  try {
    if (isLoginPath(location.pathname) || isQuizTake(location.pathname) || isSubmissionPath(location.pathname, location.hash)) return;
    const s = await chrome.storage.local.get(['skin', 'wallet', 'putBack', 'flags']);
    if (remoteKill(s.flags, {
      host: location.host,
      page: pageName(location.pathname),
      version: chrome.runtime.getManifest().version,
      now: Date.now(),
    })) return;
    const skin = { dark: false, cards: true, mascot: true, ...(s.skin ?? {}) };
    if (skin.mode === 'auto') skin.dark = matchMedia('(prefers-color-scheme: dark)').matches;
    const classes = skinClasses({
      on: !!skin.cards, dark: !!skin.dark, dense: !!skin.dense, hidePast: !!skin.hidePast,
      look: LOOKS_BY_ID[s.wallet?.wearing] ?? LOOKS_BY_ID.classic,
      putBack: s.putBack ?? {},
    });
    document.documentElement.classList.add(...classes);
    if (classes.length) {
      const style = document.getElementById('pk-theme-vars') ?? document.createElement('style');
      style.id = 'pk-theme-vars';
      const look = LOOKS_BY_ID[s.wallet?.wearing] ?? LOOKS_BY_ID.classic;
      style.textContent = themeStyle(look, textureImage, artFor(look, ART_AVAILABLE, (f) => chrome.runtime.getURL(f)));
      document.documentElement.append(style);
    }
  } catch {
    // No storage, no skin. The page is Canvas, unchanged.
    for (const name of [...document.documentElement.classList]) if (name.startsWith('pk-')) document.documentElement.classList.remove(name);
    document.querySelectorAll('#pk-theme-vars').forEach((el) => el.remove());
  }
})();

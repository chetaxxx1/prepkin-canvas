const codeInput = document.getElementById('code');
const statusEl = document.getElementById('status');
const connectBtn = document.getElementById('connect');
const sitesEl = document.getElementById('sites');

// The same slime the app and the page overlay draw, at popup size.
document.getElementById('slime').innerHTML = `
  <svg width="36" height="${36 * SLIME_ASPECT}" viewBox="0 0 1 ${SLIME_ASPECT}" aria-hidden="true">
    <g transform="scale(1, ${SLIME_ASPECT})">
      <path d="${SLIME_PATHS.body}" fill="${SLIME_PALETTE.body}"/>
      <path d="${SLIME_PATHS.belly}" fill="${SLIME_PALETTE.belly}"/>
      <path d="${SLIME_PATHS.faceIdle}" fill="${SLIME_PALETTE.ink}"/>
    </g>
  </svg>`;
document.getElementById('version').textContent = `v${chrome.runtime.getManifest().version}`;

const CHECK_SVG = `
  <svg width="16" height="16" viewBox="0 0 16 16" aria-hidden="true">
    <circle cx="8" cy="8" r="8" fill="#51CFA0"/>
    <path d="M4.6 8.3 L7 10.6 L11.4 5.6" stroke="#101820" stroke-width="1.9"
          fill="none" stroke-linecap="round" stroke-linejoin="round"/>
  </svg>`;

// Same alphabet as the app: no O/0 or I/1, because people type this by hand.
const ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

// Worked out when the popup opens, so the Connect click can call
// permissions.request() with no await in front of it. Chrome only accepts that
// request during a real user gesture, and an await spends the gesture.
let tabOrigin = null;

function normalize(input) {
  const cleaned = [...input.toUpperCase()].filter((c) => ALPHABET.includes(c)).join('');
  if (cleaned.length !== 8) return null;
  return `${cleaned.slice(0, 4)}-${cleaned.slice(4)}`;
}

function show(message, kind) {
  statusEl.textContent = message;
  statusEl.className = kind ?? '';
}

function report(result) {
  if (!result) return;
  if (result.ok) show(`Sent ${result.count ?? 0} assignments.`, 'ok');
  else show(result.error ?? 'Something went wrong.', 'bad');
}

async function connectedOrigins() {
  const { origins = [] } = await chrome.storage.local.get('origins');
  const live = [];
  for (const origin of origins) {
    if (await chrome.permissions.contains({ origins: [`${origin}/*`] })) live.push(origin);
  }
  return live;
}

async function render() {
  const origins = await connectedOrigins();
  sitesEl.replaceChildren(
    ...(origins.length
      ? origins.map((origin) => {
          const li = document.createElement('li');
          const icon = document.createElement('span');
          icon.innerHTML = CHECK_SVG; // our own SVG constant, not page data
          const who = document.createElement('div');
          who.className = 'who';
          const name = document.createElement('b');
          name.textContent = new URL(origin).hostname;
          const meta = document.createElement('small');
          meta.textContent = 'Connected';
          who.append(name, meta);
          const remove = document.createElement('button');
          remove.className = 'x';
          remove.textContent = '×';
          remove.title = 'Disconnect this school';
          remove.addEventListener('click', () => forget(origin));
          li.append(icon, who, remove);
          return li;
        })
      : [Object.assign(document.createElement('li'), {
          textContent: 'None yet. Open your school’s Canvas and connect it below.',
          className: 'none',
        })])
  );

  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  tabOrigin = tab?.url?.startsWith('https://') ? new URL(tab.url).origin : null;

  if (tabOrigin && !origins.includes(tabOrigin)) {
    connectBtn.hidden = false;
    connectBtn.textContent = `Connect ${new URL(tabOrigin).hostname}`;
  } else {
    connectBtn.hidden = true;
  }
}

async function forget(origin) {
  await chrome.runtime.sendMessage({ type: 'unregister', origin });
  await chrome.permissions.remove({ origins: [`${origin}/*`] });
  const { origins = [] } = await chrome.storage.local.get('origins');
  await chrome.storage.local.set({ origins: origins.filter((o) => o !== origin) });
  render();
}

connectBtn.addEventListener('click', () => {
  if (!tabOrigin) return;
  // No await before this line — see the note on tabOrigin above.
  chrome.permissions.request({ origins: [`${tabOrigin}/*`] }, async (granted) => {
    if (!granted) return show('Chrome did not grant access to that site.', 'bad');

    const check = await chrome.runtime.sendMessage({ type: 'verify-canvas', origin: tabOrigin });
    if (!check.ok) {
      await chrome.permissions.remove({ origins: [`${tabOrigin}/*`] });
      return show(check.error, 'bad');
    }

    const { origins = [] } = await chrome.storage.local.get('origins');
    await chrome.storage.local.set({ origins: [...new Set([...origins, tabOrigin])] });
    // Now that Chrome has granted the origin, the skin can be injected there.
    await chrome.runtime.sendMessage({ type: 'register', origin: tabOrigin });
    show(`Connected as ${check.name}. Syncing…`);
    await render();
    report(await chrome.runtime.sendMessage({ type: 'sync-now', origin: tabOrigin }));
  });
});

document.getElementById('save').addEventListener('click', async () => {
  const code = normalize(codeInput.value);
  if (!code) return show('That code should be 8 letters and numbers.', 'bad');
  codeInput.value = code;
  await chrome.storage.local.set({ pairingCode: code });
  show('Saved. Syncing…');
  report(await chrome.runtime.sendMessage({ type: 'sync-now' }));
});

document.getElementById('resync').addEventListener('click', async () => {
  show('Syncing…');
  report(await chrome.runtime.sendMessage({ type: 'sync-now' }));
});

// The page overlay reads these live, so a tick takes effect on any open Canvas
// tab without a reload. No dark key any more: the warm theme is the theme, and
// dark mode returns when it has been designed.
const SKIN_DEFAULTS = { cards: true, tidy: true, mascot: true };

document.querySelectorAll('[data-skin]').forEach((box) => {
  box.addEventListener('change', async () => {
    const { skin } = await chrome.storage.local.get('skin');
    await chrome.storage.local.set({
      skin: { ...SKIN_DEFAULTS, ...(skin ?? {}), [box.dataset.skin]: box.checked },
    });
  });
});

chrome.storage.local.get('skin').then(({ skin }) => {
  const current = { ...SKIN_DEFAULTS, ...(skin ?? {}) };
  document.querySelectorAll('[data-skin]').forEach((box) => {
    box.checked = !!current[box.dataset.skin];
  });
});

chrome.storage.local.get(['pairingCode', 'lastSync']).then(({ pairingCode, lastSync }) => {
  if (pairingCode) codeInput.value = pairingCode;
  report(lastSync);
});

render();

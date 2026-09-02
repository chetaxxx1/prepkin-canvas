const codeInput = document.getElementById('code');
const statusEl = document.getElementById('status');
const connectBtn = document.getElementById('connect');
const sitesEl = document.getElementById('sites');

// The same slime the app and the page overlay draw, at popup size.
document.getElementById('slime').innerHTML = slimeAt(36);
document.getElementById('version').textContent = `v${chrome.runtime.getManifest().version}`;

const CHECK_SVG = `
  <svg width="16" height="16" viewBox="0 0 16 16" aria-hidden="true">
    <circle cx="8" cy="8" r="8" fill="#51CFA0"/>
    <path d="M4.6 8.3 L7 10.6 L11.4 5.6" stroke="#101820" stroke-width="1.9"
          fill="none" stroke-linecap="round" stroke-linejoin="round"/>
  </svg>`;

const COIN_SVG = `
  <svg width="13" height="13" viewBox="0 0 14 14" aria-hidden="true">
    <circle cx="7" cy="7" r="6.4" fill="#DE9A22"/>
    <circle cx="7" cy="7" r="3.4" fill="none" stroke="#FFF9EC" stroke-width="1.6"/>
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

// The whole disconnect lives in the background worker, so the permission, the
// stored origin list, and the school's already-synced tasks all go together —
// including a fresh push, so the phone drops them too.
async function forget(origin) {
  await chrome.runtime.sendMessage({ type: 'forget', origin });
  render();
}

/// Asks Chrome for the current site and wires it up. Must be called straight
/// from a click: `permissions.request` only counts during a real user gesture,
/// and an await before it spends that gesture.
function requestSite(after) {
  if (!tabOrigin) return;
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
    after?.();
    report(await chrome.runtime.sendMessage({ type: 'sync-now', origin: tabOrigin }));
  });
}

connectBtn.addEventListener('click', () => requestSite());

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
// tab without a reload.
const SKIN_DEFAULTS = { dark: false, cards: true, tidy: true, mascot: true, focusMinutes: 25 };

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

// MARK: - Coin balance

/// Only ever shown when the phone has actually told us a number. A wallet the
/// extension made up would be worse than no wallet at all.
chrome.storage.local.get('wallet').then(({ wallet }) => {
  if (typeof wallet?.coins !== 'number') return;
  const chip = document.getElementById('coins');
  chip.innerHTML = COIN_SVG;
  chip.append(String(wallet.coins));
  chip.hidden = false;
  document.getElementById('version').hidden = true;
});

// MARK: - First run
//
// Three steps, every one skippable, and re-reachable later from the popup.
// Nothing here asks for an account, because there is no account.

const onbEl = document.getElementById('onboarding');
const mainEl = document.getElementById('main');

/// `size` is the width; height follows from the app's aspect (width / height),
/// so the popup slime has the same proportions as the one on the phone.
function slimeAt(size, face = 'faceIdle') {
  return `<svg width="${size}" height="${size / SLIME_ASPECT}" viewBox="0 0 1 1"
               preserveAspectRatio="none" aria-hidden="true">
    <path d="${SLIME_PATHS.body}" fill="${SLIME_PALETTE.body}"/>
    <path d="${SLIME_PATHS.belly}" fill="${SLIME_PALETTE.belly}"/>
    <path d="${SLIME_PATHS[face]}" fill="${SLIME_PALETTE.ink}"/>
  </svg>`;
}

function dots(step) {
  return `<div class="dots">${[0, 1, 2].map((i) =>
    `<i class="${i === step ? 'on' : ''}"></i>`).join('')}</div>`;
}

async function finishOnboarding() {
  await chrome.storage.local.set({ onboarded: true });
  onbEl.hidden = true;
  mainEl.hidden = false;
  render();
}

function onboardingStep(step) {
  if (step === 0) {
    onbEl.innerHTML = `<div class="onb">
      ${slimeAt(72, 'faceDelight')}
      <h2>Hi, I'm your buddy</h2>
      <p>I keep your Canvas due dates, grades and progress in one calm place.</p>
      <button class="mint wide" id="onb-next" style="margin:0">Let's set up</button>
      <small style="font-size:11px;font-weight:600;color:#a8977f">Free · no account needed</small>
      ${dots(0)}
    </div>`;
    document.getElementById('onb-next').addEventListener('click', () => onboardingStep(1));
    return;
  }
  if (step === 1) {
    const host = tabOrigin ? new URL(tabOrigin).hostname : null;
    onbEl.innerHTML = `<div class="onb">
      <h2>Connect your school</h2>
      <p>So Prepkin can read your assignments — nothing gets changed or posted.</p>
      ${host
        ? `<div class="detected"><i></i><div><b>You're on ${host}</b>
             <small>We'll ask Chrome for permission next.</small></div></div>
           <button class="mint wide" id="onb-connect" style="margin:0">Connect</button>`
        : `<div class="detected"><i style="background:#c9bca4"></i><div>
             <b>Open your school's Canvas first</b>
             <small>Then reopen Prepkin and we'll spot it.</small></div></div>`}
      <button class="skip" id="onb-skip">Skip for now</button>
      ${dots(1)}
    </div>`;
    // Same gesture rule as the main Connect button: no await before request().
    document.getElementById('onb-connect')?.addEventListener('click', () => {
      requestSite(() => onboardingStep(2));
    });
    document.getElementById('onb-skip').addEventListener('click', () => onboardingStep(2));
    return;
  }
  onbEl.innerHTML = `<div class="onb">
    <h2>Link your phone</h2>
    <p>Coins and focus sessions sync with the Prepkin app. Optional.</p>
    <div class="detected" style="justify-content:center;gap:12px">
      ${slimeAt(40)}
      <small style="max-width:150px">The code lives in the app under Today → the sliders button.</small>
    </div>
    <div class="pair">
      <input id="onb-code" placeholder="XXXX-XXXX" maxlength="9" autocomplete="off" spellcheck="false"
             style="flex-grow:1;min-width:0;padding:10px 12px;font-size:13px;font-weight:700;
                    font-family:ui-monospace,Menlo,monospace;letter-spacing:.18em;text-align:center;
                    text-transform:uppercase;background:#fff;border:0;box-shadow:inset 0 0 0 1px #eae5da;
                    border-radius:12px;color:#33291f;outline:none" />
      <button class="mint" id="onb-link">Link</button>
    </div>
    <button class="skip" id="onb-done">Skip for now</button>
    ${dots(2)}
  </div>`;
  document.getElementById('onb-link').addEventListener('click', async () => {
    const code = normalize(document.getElementById('onb-code').value);
    if (code) await chrome.storage.local.set({ pairingCode: code });
    await finishOnboarding();
    if (code) report(await chrome.runtime.sendMessage({ type: 'sync-now' }));
  });
  document.getElementById('onb-done').addEventListener('click', finishOnboarding);
}

// render() is what works out tabOrigin, so step 2 can name the school.
Promise.all([chrome.storage.local.get('onboarded'), render()]).then(([{ onboarded }]) => {
  if (onboarded) return;
  mainEl.hidden = true;
  onbEl.hidden = false;
  onboardingStep(0);
});

const codeInput = document.getElementById('code');
const statusEl = document.getElementById('status');
const connectBtn = document.getElementById('connect');
const sitesEl = document.getElementById('sites');

// The same slime the app and the page overlay draw, at popup size.
document.getElementById('slime').innerHTML = slimeAt(36);
document.getElementById('version').textContent = `v${chrome.runtime.getManifest().version}`;

// For testing: five taps on the version number own every theme. A paired
// phone's wallet replaces this the next time it syncs.
let versionTaps = 0;
document.getElementById('version').addEventListener('click', async () => {
  if (++versionTaps < 5) return;
  versionTaps = 0;
  const { wallet } = await chrome.storage.local.get('wallet');
  await chrome.storage.local.set({ wallet: { ...(wallet ?? {}), coins: 9999, owned: LOOKS.map((l) => l.id), wearing: wallet?.wearing ?? 'classic' } });
  show('Testing: every theme unlocked.', 'ok');
});

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
  show('Pairing…');
  // The code is traded for this laptop's own token, once. After that the code
  // is spent, and nobody who guesses it later can read or change anything.
  const paired = await chrome.runtime.sendMessage({ type: 'pair', code });
  if (!paired?.ok) return show(paired?.error ?? 'Could not pair.', 'bad');
  show('Paired. Syncing…');
  report(await chrome.runtime.sendMessage({ type: 'sync-now' }));
  showPairing();
  loadBuddy();
  speak();
});

document.getElementById('resync').addEventListener('click', async () => {
  show('Syncing…');
  report(await chrome.runtime.sendMessage({ type: 'sync-now' }));
});

// The page overlay reads these live, so a tick takes effect on any open Canvas
// tab without a reload.
const SKIN_DEFAULTS = { dark: false, cards: true, tidy: true, mascot: true, focusMinutes: 25, search: true };

document.querySelectorAll('[data-skin]').forEach((box) => {
  box.addEventListener('change', async () => {
    const { skin } = await chrome.storage.local.get('skin');
    await chrome.storage.local.set({
      skin: { ...SKIN_DEFAULTS, ...(skin ?? {}), [box.dataset.skin]: box.checked },
    });
    applyPopupSkin();
    setTimeout(loadReceipt, 250);
  });
});

async function syncToggles() {
  const { skin } = await chrome.storage.local.get('skin');
  const current = { ...SKIN_DEFAULTS, ...(skin ?? {}) };
  document.querySelectorAll('[data-skin]').forEach((box) => {
    box.checked = !!current[box.dataset.skin];
  });
  const mode = current.mode ?? (current.dark ? 'dark' : 'light');
  document.querySelectorAll('#mode [data-mode]').forEach((b) => b.setAttribute('aria-checked', String(b.dataset.mode === mode)));
}
syncToggles();

/// Light, dark, or the OS's choice. The resolved `dark` is written alongside
/// so every reader keeps its one boolean.
document.querySelectorAll('#mode [data-mode]').forEach((b) => b.addEventListener('click', async () => {
  const mode = b.dataset.mode;
  const { skin } = await chrome.storage.local.get('skin');
  const dark = mode === 'auto' ? matchMedia('(prefers-color-scheme: dark)').matches : mode === 'dark';
  await chrome.storage.local.set({ skin: { ...SKIN_DEFAULTS, ...(skin ?? {}), mode, dark } });
  await syncToggles();
  applyPopupSkin();
  setTimeout(loadReceipt, 250);
}));

// MARK: - Due next
//
// Today across every class, from what the laptop last synced. The one screen
// worth opening; the pairing card sits under it. Amber says "still counts";
// nothing here is ever red.

/// "in 2h 10m" for the next thing due within a day. Never a countdown that
/// alarms: past due reads "still counts", not a negative number.
/// The buddy is on the page, not in here. When the front tab is a connected
/// Canvas with the buddy on, one button opens its panel and closes this.
async function loadBuddy() {
  const el = document.getElementById('buddy');
  const tab = await activeCanvasTab();
  const { skin } = await chrome.storage.local.get('skin');
  el.hidden = !tab || skin?.mascot === false;
  el.dataset.tab = tab?.id ?? '';
}
document.getElementById('open-buddy').addEventListener('click', async () => {
  const id = Number(document.getElementById('buddy').dataset.tab);
  if (!id) return;
  const r = await chrome.tabs.sendMessage(id, { type: 'open-buddy' }).catch(() => null);
  if (r?.ok) window.close(); else show('Reload the Canvas tab first.', 'bad');
});
loadBuddy();

// MARK: - The receipt
//
// The page in front of the student lists what Prepkin took, fixed and added
// there. Every row has one button that reverses it, and the choice is kept.

const receiptEl = document.getElementById('receipt');

async function activeCanvasTab() {
  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  if (!tab?.id || !tab.url?.startsWith('https://')) return null;
  const origins = await connectedOrigins();
  return origins.includes(new URL(tab.url).origin) ? tab : null;
}

async function loadReceipt() {
  const tab = await activeCanvasTab();
  let r = null;
  if (tab) {
    try { r = await chrome.tabs.sendMessage(tab.id, { type: 'receipt' }); } catch { r = null; }
  }
  receiptEl.hidden = !r;
  if (!r) return;
  document.getElementById('receipt-page').textContent = r.page;
  document.getElementById('show-me').hidden = !r.rows.length || !!r.off;
  const off = document.getElementById('receipt-off');
  const lists = document.getElementById('receipt-lists');
  if (r.off || !r.on) {
    off.textContent = r.off ?? 'Quiet Canvas is off. Turn it on below and this page gets its receipt.';
    off.hidden = false;
    lists.hidden = true;
    return;
  }
  off.hidden = true;
  lists.hidden = false;

  // The one decision, first: how much is live, and one button for all of it.
  const live = r.rows.filter((x) => !x.back).length;
  document.getElementById('receipt-count').textContent =
    live === 0 ? 'Nothing changed on this page' : `${live} change${live === 1 ? '' : 's'} on this page`;
  const putAll = document.getElementById('put-all');
  putAll.textContent = live ? 'Put it all back' : 'Take it all again';
  putAll.onclick = () => putAllBack(r.rows, live > 0);

  const sections = [
    ['taken', 'receipt-taken', 'Nothing was taken from this page.'],
    ['fixed', 'receipt-fixed', 'Nothing to fix here.'],
    ['added', 'receipt-added', null],
  ];
  // The first group with a live row opens; the rest fold to a header and count.
  if (!receiptOpen.size) {
    const first = sections.find(([kind]) => r.rows.some((x) => x.kind === kind && !x.back)) ?? sections[0];
    receiptOpen.add(first[0]);
  }
  for (const [kind, id, empty] of sections) {
    const ul = document.getElementById(id);
    ul.replaceChildren();
    const rows = r.rows.filter((x) => x.kind === kind);
    const grp = ul.parentElement;
    grp.hidden = kind === 'added' && !rows.length;
    grp.classList.toggle('open', receiptOpen.has(kind));
    const head = grp.querySelector('.grp-head');
    head.setAttribute('aria-expanded', String(receiptOpen.has(kind)));
    head.querySelector('em').textContent = rows.length ? String(rows.filter((x) => !x.back).length) : '';
    head.onclick = () => {
      if (receiptOpen.has(kind)) receiptOpen.delete(kind); else receiptOpen.add(kind);
      grp.classList.toggle('open', receiptOpen.has(kind));
      head.setAttribute('aria-expanded', String(receiptOpen.has(kind)));
    };
    if (!rows.length) {
      ul.append(Object.assign(document.createElement('li'), { className: 'none', textContent: empty }));
      continue;
    }
    for (const row of rows) {
      const li = document.createElement('li');
      li.className = row.back ? 'back' : '';
      li.dataset.key = row.key;
      const span = document.createElement('span');
      span.textContent = row.label;
      const btn = document.createElement('button');
      btn.className = 'put';
      btn.textContent = row.back ? row.undo : row.putBack;
      btn.addEventListener('click', () => putBack(row, !row.back));
      li.append(span, btn);
      ul.append(li);
    }
  }
}

/// Which receipt groups are unfolded, for as long as the popup is open.
const receiptOpen = new Set();

/// Remembered forever, per key. A row with `opt` is one of the student's own
/// switches (grades on cards, compact pages, the buddy): "back" means off.
async function putBack(row, back) {
  if (row.opt) {
    const { skin } = await chrome.storage.local.get('skin');
    await chrome.storage.local.set({ skin: { ...SKIN_DEFAULTS, ...(skin ?? {}), [row.opt]: !back } });
    await syncToggles();
  } else {
    const { putBack: map = {} } = await chrome.storage.local.get('putBack');
    const next = { ...map };
    if (back) next[row.key] = true; else delete next[row.key];
    await chrome.storage.local.set({ putBack: next });
  }
  setTimeout(loadReceipt, 250);
}

/// Every live row on this page at once, and the exact reverse. What was live is
/// kept as a snapshot so "Take it all again" restores that, not a default set.
async function putAllBack(rows, back) {
  const stored = await chrome.storage.local.get(['putBack', 'skin', 'putAllUndo']);
  const map = { ...(stored.putBack ?? {}) };
  const skin = { ...SKIN_DEFAULTS, ...(stored.skin ?? {}) };
  if (back) {
    const snapshot = { keys: [], opts: [] };
    for (const row of rows) {
      if (row.back) continue;
      if (row.opt) { snapshot.opts.push(row.opt); skin[row.opt] = false; }
      else { snapshot.keys.push(row.key); map[row.key] = true; }
    }
    await chrome.storage.local.set({ putBack: map, skin, putAllUndo: snapshot });
  } else {
    const undo = stored.putAllUndo ?? {};
    const keys = undo.keys ?? rows.filter((r) => !r.opt).map((r) => r.key);
    const opts = undo.opts ?? rows.filter((r) => r.opt && SKIN_DEFAULTS[r.opt]).map((r) => r.opt);
    for (const k of keys) delete map[k];
    for (const o of opts) skin[o] = true;
    await chrome.storage.local.set({ putBack: map, skin, putAllUndo: null });
  }
  await syncToggles();
  applyPopupSkin();
  setTimeout(loadReceipt, 250);
}

document.getElementById('show-me').addEventListener('click', async () => {
  const tab = await activeCanvasTab();
  if (tab) chrome.tabs.sendMessage(tab.id, { type: 'show-me' }).catch(() => {});
});

loadReceipt();

/// Linked phones do not need the field in the way; a new code is one click.
async function showPairing() {
  const { pairingCode, writerToken, lastSync } = await chrome.storage.local.get(['pairingCode', 'writerToken', 'lastSync']);
  if (pairingCode) codeInput.value = pairingCode;
  const linked = !!(pairingCode && writerToken);
  document.getElementById('linked').hidden = !linked;
  document.getElementById('pair-box').hidden = linked;
  document.getElementById('relink').hidden = !linked;
  report(lastSync);
}
showPairing();
document.getElementById('relink').addEventListener('click', () => {
  document.getElementById('linked').hidden = true;
  document.getElementById('pair-box').hidden = false;
  document.getElementById('relink').hidden = true;
  codeInput.value = '';
  codeInput.focus();
});

// MARK: - Dark, and the buddy's voice

async function applyPopupSkin() {
  const { skin } = await chrome.storage.local.get('skin');
  const dark = skin?.mode === 'auto' ? matchMedia('(prefers-color-scheme: dark)').matches : !!skin?.dark;
  document.body.classList.toggle('dark', dark);
}
applyPopupSkin();

/// `YYYY-MM-DD` from storage to a local Date, and nothing else. Same rule as
/// the panel's dayFromKey: a date that does not read back the same is not one.
function planDayOf(key) {
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(String(key ?? ''));
  if (!m) return null;
  const [y, mo, d] = [Number(m[1]), Number(m[2]), Number(m[3])];
  const day = new Date(y, mo - 1, d);
  return day.getFullYear() === y && day.getMonth() === mo - 1 && day.getDate() === d ? day : null;
}

/// The same words the panel uses, from the same day.
async function speak() {
  const { lastPayload, onboarded, plans = {} } = await chrome.storage.local.get(['lastPayload', 'onboarded', 'plans']);
  if (!lastPayload?.tasks || !onboarded) return;
  // The panel's day, not a second opinion: a student who moved two things to
  // today should not read a different sentence in the toolbar.
  const said = voice(buckets(lastPayload.tasks, new Date(), (t) => planDayOf(plans[t.id])));
  document.getElementById('say-head').textContent = said.headline;
  document.getElementById('say-sub').textContent = said.subline;
  document.getElementById('slime').innerHTML = slimeAt(36, said.face);
}
speak();

// MARK: - Coin balance

/// Only ever shown when the phone has actually told us a number. A wallet the
/// extension made up would be worse than no wallet at all.
chrome.storage.local.get('wallet').then(({ wallet }) => {
  if (typeof wallet?.coins !== 'number') return;
  const chip = document.getElementById('coins');
  chip.innerHTML = COIN_SVG;
  chip.append(String(wallet.coins));
  chip.hidden = false;
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
      <p>So Prepkin can read your assignments. Nothing gets changed or posted.</p>
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
    <p>Coins and focus time go to the Prepkin app. Optional.</p>
    <div class="detected" style="justify-content:center;gap:12px">
      ${slimeAt(40)}
      <small style="max-width:150px">In the app: Today, then the sliders button.</small>
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
    await finishOnboarding();
    speak();
    if (!code) return show('That code should be 8 letters and numbers.', 'bad');
    codeInput.value = code;
    // Same trade as the Save button: the code buys this laptop's token, once.
    const paired = await chrome.runtime.sendMessage({ type: 'pair', code });
    if (!paired?.ok) return show(paired?.error ?? 'Could not pair.', 'bad');
    // The moment it worked: the buddy, a line, a tick, the phone.
    onbEl.hidden = false; mainEl.hidden = true;
    onbEl.innerHTML = `<div class="onb">
      <div class="linked-moment">${slimeAt(48, 'faceDelight')}<span class="line"></span>
        <span class="tick"><svg width="16" height="16" viewBox="0 0 16 16" aria-hidden="true"><path d="M3.5 8.5 L6.5 11.5 L12.5 5" stroke="#101820" stroke-width="2.2" fill="none" stroke-linecap="round" stroke-linejoin="round"/></svg></span>
        <span class="line"></span><svg width="26" height="40" viewBox="0 0 26 40" aria-hidden="true"><rect x="1" y="1" width="24" height="38" rx="5" fill="none" stroke="#51cfa0" stroke-width="2"/><rect x="9" y="33" width="8" height="2" rx="1" fill="#51cfa0"/></svg></div>
      <h2>Linked</h2><p>Coins and focus time now go to your phone.</p></div>`;
    await new Promise((r) => setTimeout(r, 1100));
    onbEl.hidden = true; mainEl.hidden = false;
    show('Paired. Syncing…');
    report(await chrome.runtime.sendMessage({ type: 'sync-now' }));
    showPairing();
    loadBuddy();
    speak();
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

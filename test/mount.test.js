// Mount time on a slow laptop: the real sandbox Canvas under a 4x CPU throttle,
// four pages, skin on against skin off, the median of three. B8 on 2026-09-14
// was "9–20 s under load, flaky, needs a number"; this is the number.
//
//   ssh -N -L 3000:localhost:3000 canvas@<VM IP>      (in another terminal)
//   PREPKIN_PORT=8446 node --test test/mount.test.js
//   RATE=6 RUNS=5 PAGES=dashboard,files node --test test/mount.test.js
//
// Needs the tunnel on :3000 and PREPKIN_PORT free. The ceiling: with the skin
// on, a page mounts within 1.5x of plain Canvas plus one second.

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

const test = require('node:test');
const assert = require('node:assert');
const { FakeServer } = require('./fake-canvas');
const { launch, SCHOOL_A } = require('./harness');

const UPSTREAM = process.env.CANVAS_UPSTREAM || 'http://127.0.0.1:3000';
const PORT = Number(process.env.PREPKIN_PORT) || 8446;
const STUDENT = { login: 'alex@prepkin.test', password: 'PrepkinSandbox!2026' };
const RATE = Number(process.env.RATE) || 4;
const RUNS = Number(process.env.RUNS) || 3;
const ONLY = process.env.PAGES ? process.env.PAGES.split(',') : null;

/// The pages a student lands on most, with the element that says each has mounted.
const PAGES = [
  ['dashboard', '/', '.ic-DashboardCard'],
  ['modules', '/courses/4/modules', '.context_module'],
  // The new InstUI Files page has no .ef-* nodes; its search button is what says it mounted.
  ['files', '/courses/4/files', '[data-testid="files-search-button"], .ef-directory, .ef-item-row, .ic-Table'],
  ['page', '/courses/4/pages/rotation-the-short-version', '.show-content, #wiki_page_show'],
].filter(([name]) => !ONLY || ONLY.includes(name));

const skin = (on) => ({ dark: false, cards: on, mascot: on, focusMinutes: 25 });
const wallet = { coins: 480, owned: ['classic', 'deepsea'], wearing: 'deepsea', kin: { species: 'mint', level: 2, skin: '' } };
const median = (xs) => { const s = [...xs].sort((a, b) => a - b); return s[Math.floor(s.length / 2)]; };

let server, h, page, cdp;

test.before(async () => {
  server = await new FakeServer({ upstream: UPSTREAM }).start(PORT);
  h = await launch();
  page = await h.context.newPage();
  await page.setViewportSize({ width: 1280, height: 860 });
  page.setDefaultNavigationTimeout(180_000);
  page.setDefaultTimeout(120_000);
  await page.goto(`${SCHOOL_A}/login/canvas`, { waitUntil: 'domcontentloaded' });
  await page.fill('#pseudonym_session_unique_id', STUDENT.login);
  await page.fill('#pseudonym_session_password', STUDENT.password);
  await page.press('#pseudonym_session_password', 'Enter');
  await page.waitForURL((u) => !u.pathname.startsWith('/login'), { waitUntil: 'domcontentloaded' });
  await h.setStorage({ onboarded: true, origins: [SCHOOL_A], skin: skin(true), wallet });
  await h.connect(SCHOOL_A);
  try { await h.sw((o) => syncNow(o), SCHOOL_A); } catch {}
  // One warm pass so the browser cache holds Canvas's bundles for both arms.
  for (const [, url, ready] of PAGES) await mount(url, ready);
  cdp = await h.context.newCDPSession(page);
  await cdp.send('Emulation.setCPUThrottlingRate', { rate: RATE });
});

test.after(async () => {
  try { await cdp?.send('Emulation.setCPUThrottlingRate', { rate: 1 }); } catch {}
  await h?.close();
  await server?.stop();
});

/// From the navigation to the page's own element being in the DOM.
async function mount(url, ready) {
  const t0 = Date.now();
  await page.goto(`${SCHOOL_A}${url}`, { waitUntil: 'domcontentloaded' });
  await page.waitForSelector(ready, { timeout: 90_000, state: 'attached' });
  const t = Date.now() - t0;
  await page.waitForLoadState('networkidle', { timeout: 15_000 }).catch(() => {});
  return t;
}

const rows = [];
for (const [name, url, ready] of PAGES) {
  test(`${name} mounts under a ${RATE}x throttle within 1.5x of plain Canvas + 1 s`, async () => {
    const on = []; const off = [];
    // Interleaved, so drift on the sandbox lands on both arms alike.
    for (let i = 0; i < RUNS; i += 1) {
      await h.setStorage({ skin: skin(false) }); off.push(await mount(url, ready));
      await h.setStorage({ skin: skin(true) }); on.push(await mount(url, ready));
    }
    const row = { page: name, off: median(off), on: median(on) };
    row.ratio = Math.round((row.on / row.off) * 100) / 100;
    rows.push(row);
    console.log(`  ${name.padEnd(10)} plain ${String(row.off).padStart(6)} ms   skin ${String(row.on).padStart(6)} ms   ${row.ratio}x   (${off.join('/')} vs ${on.join('/')})`);
    assert.ok(row.on <= row.off * 1.5 + 1000, `${name}: skin on ${row.on} ms, plain ${row.off} ms`);
  });
}

test('the table', () => {
  console.log(`\n  CPU ${RATE}x, median of ${RUNS}, 1280 wide, Deep Sea worn\n  ` + rows.map((r) => `${r.page}: ${r.off} → ${r.on} ms (${r.ratio}x)`).join('\n  '));
});

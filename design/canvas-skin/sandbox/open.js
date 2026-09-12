// Opens the sandbox Canvas in a real, visible Chromium with the extension
// loaded, the seeded student logged in, the school connected, and a wallet
// with a league so every surface has something to show. Then it stays open
// until you press Ctrl-C. For looking, not for tests.
//
//   ssh -N -L 3000:localhost:3000 canvas@<VM IP>     (in another terminal)
//   node design/canvas-skin/sandbox/open.js
//
// Same plumbing as design/site-shots/shoot.js: the extension is staged with
// the proxy's origin granted, and Canvas is proxied from the tunnel onto
// https://localhost:8443. The wallet here is pretend; nothing pairs.

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

const fs = require('fs');
const os = require('os');
const path = require('path');
const { FakeServer } = require('../../../test/fake-canvas');
const { stageExtension, DEPS, SCHOOL_A } = require('../../../test/harness');
const { chromium } = require(path.join(DEPS, 'node_modules/playwright'));

const UPSTREAM = process.env.CANVAS_UPSTREAM || 'http://127.0.0.1:3000';
// The seeded sandbox student from seed.py.
const STUDENT = { login: 'alex@prepkin.test', password: 'PrepkinSandbox!2026' };

(async () => {
  const server = await new FakeServer({ upstream: UPSTREAM }).start(8443);
  const tmp = fs.mkdtempSync(path.join(process.env.PREPKIN_TMP || os.tmpdir(), 'prepkin-open-'));
  const ext = stageExtension(tmp);
  const context = await chromium.launchPersistentContext(path.join(tmp, 'profile'), {
    channel: 'chromium',
    headless: false,
    ignoreHTTPSErrors: true,
    viewport: null,
    timeout: 600_000,
    args: [`--disable-extensions-except=${ext}`, `--load-extension=${ext}`,
      '--ignore-certificate-errors', '--no-first-run', '--window-size=1440,900', '--remote-debugging-port=0'],
  });
  await context.route('**/rest/v1/rpc/fetch_flags', (route) => route.fulfill({
    status: 200, contentType: 'application/json',
    body: JSON.stringify({ at: new Date().toISOString(), rules: [] }),
  }));
  let worker = context.serviceWorkers()[0];
  if (!worker) worker = await context.waitForEvent('serviceworker');

  const page = context.pages()[0] ?? await context.newPage();
  page.setDefaultNavigationTimeout(180_000);
  page.setDefaultTimeout(120_000);

  await page.goto(`${SCHOOL_A}/login/canvas`, { waitUntil: 'domcontentloaded' });
  await page.fill('#pseudonym_session_unique_id', STUDENT.login);
  await page.fill('#pseudonym_session_password', STUDENT.password);
  await page.press('#pseudonym_session_password', 'Enter');
  await page.waitForURL((u) => !u.pathname.startsWith('/login'), { waitUntil: 'domcontentloaded' });

  // Connected, with a pretend wallet so the coins, the shop and the league show.
  const monday = new Date(); monday.setDate(monday.getDate() - ((monday.getDay() + 6) % 7)); monday.setHours(0, 0, 0, 0);
  await worker.evaluate(async ({ o, week }) => {
    await chrome.storage.local.set({
      onboarded: true, origins: [o], dashTab: 'planner',
      skin: { dark: false, cards: true, mascot: true, focusMinutes: 25 },
      wallet: {
        coins: 480, owned: ['classic', 'deepsea'], wearing: 'classic',
        kin: { species: 'mint', level: 2, skin: '' },
        league: { tier: 1, points: 90, bar: 150, week, pennants: [0], board: [
          { you: false, adjective: 3, noun: 7, points: 140, level: 2, species: 'coral', look: 'classic' },
          { you: true, adjective: 1, noun: 2, points: 90, level: 2, species: 'mint', look: 'classic' },
          { you: false, adjective: 9, noun: 4, points: 60, level: 1, species: 'sky', look: 'classic' },
        ] },
      },
    });
    await registerFor(o);
  }, { o: SCHOOL_A, week: monday.toISOString().slice(0, 10) });
  await page.goto(`${SCHOOL_A}/`, { waitUntil: 'domcontentloaded' });
  console.log('open: the dashboard is up with the extension on. Ctrl-C closes it.');

  const bye = async () => { try { await context.close(); } catch {} try { await server.stop(); } catch {} process.exit(0); };
  process.on('SIGINT', bye);
  process.on('SIGTERM', bye);
  context.on('close', bye);
})().catch((e) => { console.error(e); process.exit(1); });

// Shoots the two Canvas frames the website wants: the seeded student's real
// dashboard on the sandbox, once as plain Canvas and once with the extension
// on. Same page, same session, same scroll. compose.py turns them into the
// hero image and the card image, and turns the raw PNGs into WebP so the
// repo does not carry 40 MB of screenshots.
//
//   ssh -N -L 3000:localhost:3000 canvas@<VM IP>     (in another terminal)
//   node design/site-shots/shoot.js
//
// Reuses test/harness.js: the extension is staged with the proxy's origin
// granted, and Canvas is proxied from the tunnel onto https://localhost:8443.

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

const fs = require('fs');
const os = require('os');
const path = require('path');
const { FakeServer } = require('../../test/fake-canvas');
const { stageExtension, DEPS, SCHOOL_A } = require('../../test/harness');
const { chromium } = require(path.join(DEPS, 'node_modules/playwright'));

const OUT = __dirname;
const UPSTREAM = process.env.CANVAS_UPSTREAM || 'http://127.0.0.1:3000';
// The seeded sandbox student from design/canvas-skin/sandbox/seed.py.
const STUDENT = { login: 'alex@prepkin.test', password: 'PrepkinSandbox!2026' };
const VIEW = { width: 1280, height: 860 };

(async () => {
  const server = await new FakeServer({ upstream: UPSTREAM }).start(8443);
  const tmp = fs.mkdtempSync(path.join(process.env.PREPKIN_TMP || os.tmpdir(), 'prepkin-shoot-'));
  const ext = stageExtension(tmp);
  const context = await chromium.launchPersistentContext(path.join(tmp, 'profile'), {
    channel: 'chromium',
    headless: !process.env.HEADED,
    ignoreHTTPSErrors: true,
    viewport: VIEW,
    deviceScaleFactor: 2,
    // The Mac may be carrying several simulators; give Chromium time to start.
    timeout: 600_000,
    args: [`--disable-extensions-except=${ext}`, `--load-extension=${ext}`,
      '--ignore-certificate-errors', '--no-first-run', '--hide-scrollbars'],
  });
  await context.route('**/rest/v1/rpc/fetch_flags', (route) => route.fulfill({
    status: 200, contentType: 'application/json',
    body: JSON.stringify({ at: new Date().toISOString(), rules: [] }),
  }));
  let worker = context.serviceWorkers()[0];
  if (!worker) worker = await context.waitForEvent('serviceworker');

  const page = await context.newPage();
  page.setDefaultNavigationTimeout(180_000);
  page.setDefaultTimeout(120_000);

  // Log the seeded student in, the same way test/live.test.js does.
  await page.goto(`${SCHOOL_A}/login/canvas`, { waitUntil: 'domcontentloaded' });
  await page.fill('#pseudonym_session_unique_id', STUDENT.login);
  await page.fill('#pseudonym_session_password', STUDENT.password);
  await page.press('#pseudonym_session_password', 'Enter');
  await page.waitForURL((u) => !u.pathname.startsWith('/login'), { waitUntil: 'domcontentloaded' });

  const settle = async () => {
    // Canvas paints skeleton cards first; wait for a real title, or the
    // banners come out blank (Spring Day did, once).
    await page.waitForSelector('.ic-DashboardCard__header-title', { timeout: 120_000 });
    // Cards, the side list and web fonts arrive after the DOM. Give them a beat.
    await page.waitForLoadState('networkidle').catch(() => {});
    await page.waitForTimeout(2500);
  };

  // Before: the extension is installed but has not been granted this Canvas,
  // so no script and no stylesheet of ours touches the page.
  await page.goto(`${SCHOOL_A}/`, { waitUntil: 'domcontentloaded' });
  await settle();
  await page.screenshot({ path: path.join(OUT, 'before.png') });
  console.log('before.png');

  // After: grant the origin, which registers the skin and the panel, then
  // load the same page again.
  await worker.evaluate(async (o) => {
    await chrome.storage.local.set({ onboarded: true, origins: [o] });
    await registerFor(o);
  }, SCHOOL_A);
  await page.goto(`${SCHOOL_A}/`, { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('html.pk-on', { timeout: 120_000 });
  await page.waitForSelector('#prepkin-buddy', { state: 'attached', timeout: 120_000 });
  await settle();
  await page.screenshot({ path: path.join(OUT, 'after.png') });
  console.log('after.png');

  // And the dark paper, which is the one toggle in the popup the site's
  // "look at it at 11pm" line is about.
  await worker.evaluate(() => chrome.storage.local.set({ skin: { dark: true, cards: true, mascot: true } }));
  await page.goto(`${SCHOOL_A}/`, { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('html.pk-on.pk-dark', { timeout: 120_000 });
  await page.waitForSelector('#prepkin-buddy', { state: 'attached', timeout: 120_000 });
  await settle();
  await page.screenshot({ path: path.join(OUT, 'after-dark.png') });
  console.log('after-dark.png');

  // Every image theme, light and dark. Wearing one is a storage write; the
  // banners take turns across the cards on their own.
  const { ART_AVAILABLE } = require('../../extension/art/manifest');
  for (const id of ART_AVAILABLE) {
    for (const dark of [false, true]) {
      await worker.evaluate(async ([look, isDark]) => {
        await chrome.storage.local.set({
          skin: { dark: isDark, cards: true, mascot: true },
          wallet: { coins: 0, owned: ['classic', look], wearing: look },
        });
      }, [id, dark]);
      await page.goto(`${SCHOOL_A}/`, { waitUntil: 'domcontentloaded' });
      await page.waitForSelector(`html.pk-on.pk-theme-${id}${dark ? '.pk-dark' : ':not(.pk-dark)'}`, { timeout: 120_000 });
      await settle();
      const name = `theme-${id}${dark ? '-dark' : ''}.png`;
      await page.screenshot({ path: path.join(OUT, name) });
      console.log(name);
    }
  }

  await context.close();
  await server.stop();
})().catch((e) => { console.error(e); process.exit(1); });

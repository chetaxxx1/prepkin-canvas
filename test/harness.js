// Launches real Chrome with the real extension, pointed at the fake Canvas and
// fake bridge, and hands back a handle on the service worker so a test can call
// syncNow(), bindWriter(), focusDone() and friends directly.
//
// Playwright lives outside the repo (~/Desktop syncs to iCloud, and
// node_modules is thousands of files): ~/Library/Developer/prepkin-canvas-test-deps.

const fs = require('fs');
const os = require('os');
const path = require('path');

const DEPS = process.env.PREPKIN_TEST_DEPS
  || path.join(os.homedir(), 'Library/Developer/prepkin-canvas-test-deps');
const { chromium } = require(path.join(DEPS, 'node_modules/playwright'));

const ROOT = path.join(__dirname, '..');
const SCHOOL_A = 'https://localhost:8443';
const SCHOOL_B = 'https://127.0.0.1:8443';
const BRIDGE = 'https://localhost:8443';

/// A copy of extension/ with two test-only changes: the fake origins are granted
/// up front (a permission prompt cannot be clicked from a test), and config.js
/// points at the fake bridge.
function stageExtension(tmp) {
  const ext = path.join(tmp, 'ext');
  fs.cpSync(path.join(ROOT, 'extension'), ext, {
    recursive: true,
    filter: (src) => !src.endsWith('.test.js') && !src.endsWith('README.md'),
  });
  const manifestPath = path.join(ext, 'manifest.json');
  const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  manifest.host_permissions = [...manifest.host_permissions, `${SCHOOL_A}/*`, `${SCHOOL_B}/*`];
  fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2));
  fs.writeFileSync(path.join(ext, 'config.js'),
    `const PREPKIN_BRIDGE = ${JSON.stringify({ url: BRIDGE, key: 'test-key' })};\n`);
  return ext;
}

async function launch({ headless = !process.env.HEADED } = {}) {
  const tmp = fs.mkdtempSync(path.join(process.env.PREPKIN_TMP || os.tmpdir(), 'prepkin-e2e-'));
  const ext = stageExtension(tmp);
  const context = await chromium.launchPersistentContext(path.join(tmp, 'profile'), {
    channel: 'chromium',
    headless,
    ignoreHTTPSErrors: true,
    args: [
      `--disable-extensions-except=${ext}`,
      `--load-extension=${ext}`,
      '--ignore-certificate-errors',
      '--no-first-run',
      '--window-size=1200,900',
      // A second door for the action popup, which Playwright does not attach to.
      '--remote-debugging-port=0',
    ],
  });
  await context.route('**/rest/v1/rpc/fetch_flags', (route) => route.fulfill({
    status: 200,
    contentType: 'application/json',
    body: JSON.stringify({ at: new Date().toISOString(), rules: [] }),
  }));
  let worker = context.serviceWorkers()[0];
  if (!worker) worker = await context.waitForEvent('serviceworker');
  const id = new URL(worker.url()).host;

  const h = {
    context, worker, id, tmp,
    /// Run `fn(arg)` inside the service worker. Top-level functions in
    /// background.js are globals there, so `sw((o) => syncNow(o), origin)` works.
    sw: (fn, arg) => worker.evaluate(fn, arg),
    storage: () => worker.evaluate(() => chrome.storage.local.get(null)),
    setStorage: (obj) => worker.evaluate((o) => chrome.storage.local.set(o), obj),
    clearStorage: () => worker.evaluate(() => chrome.storage.local.clear()),
    /// What the popup does after Chrome grants a site, minus the click.
    connect: async (origin) => {
      await worker.evaluate(async (o) => {
        const { origins = [] } = await chrome.storage.local.get('origins');
        await chrome.storage.local.set({ origins: [...new Set([...origins, o])] });
        await registerFor(o);
      }, origin);
    },
    close: async () => {
      await context.close();
      fs.rmSync(tmp, { recursive: true, force: true });
    },
  };
  return h;
}

module.exports = { launch, stageExtension, DEPS, SCHOOL_A, SCHOOL_B, BRIDGE };

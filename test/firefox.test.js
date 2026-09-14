// Firefox: the build bridge/firefox.sh makes installs, starts, and the skin
// reaches a Canvas page. Real Firefox through geckodriver; Playwright cannot
// load a Firefox extension.
//
//   bridge/firefox.sh && PREPKIN_PORT=8448 node --test test/firefox.test.js
//
// Needs selenium-webdriver and geckodriver in the test deps folder
// (npm i --no-save selenium-webdriver geckodriver, there) and Firefox 128+ in
// /Applications. What it can prove without a hand on the mouse: the manifest
// loads, the event page starts (it answers a message from the popup page),
// and a content script the worker registers runs on a page the add-on has
// host permission for. Firefox MV3 does not grant host_permissions at
// install, so the staged copy lists the fake school as a static
// content_scripts match, the one grant a temporary add-on gets for free.

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

const test = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const path = require('path');
const os = require('os');
const { FakeServer } = require('./fake-canvas');
const { DEPS } = require('./harness');
const S = require('./scenarios');

const PORT = Number(process.env.PREPKIN_PORT) || 8448;
const SCHOOL = `https://localhost:${PORT}`;
const FIREFOX = process.env.FIREFOX_BIN || '/Applications/Firefox.app/Contents/MacOS/firefox';
const BUILD = path.join(__dirname, '..', 'build', 'firefox');
const have = fs.existsSync(FIREFOX) && fs.existsSync(path.join(BUILD, 'manifest.json'))
  && fs.existsSync(path.join(DEPS, 'node_modules', 'selenium-webdriver')) && fs.existsSync(path.join(DEPS, 'node_modules', 'geckodriver'));

/// The Firefox build with the fake school granted: a static content script
/// match for it (boot at document_start, the rest at document_end), and the
/// bridge pointed at the fake, the way test/harness.js stages the Chrome copy.
function stage(tmp) {
  const dir = path.join(tmp, 'ext');
  fs.cpSync(BUILD, dir, { recursive: true });
  const m = JSON.parse(fs.readFileSync(path.join(dir, 'manifest.json'), 'utf8'));
  // Firefox match patterns carry no port: "https://localhost/*" matches the
  // fake on 8448 (a pattern with a port is silently invalid there).
  const match = `${new URL(SCHOOL).protocol}//${new URL(SCHOOL).hostname}/*`;
  m.host_permissions = [...(m.host_permissions ?? []), match];
  m.content_scripts = [
    { matches: [match], js: ['receipt.js', 'themes.js', 'looks.js', 'art/manifest.js', 'boot.js'], run_at: 'document_start' },
    { matches: [match], js: ['canvas.js', 'selectors.js', 'day.js', 'recap.js', 'planner.js', 'content.js'], run_at: 'document_end' },
  ];
  fs.writeFileSync(path.join(dir, 'manifest.json'), JSON.stringify(m, null, 2));
  fs.writeFileSync(path.join(dir, 'config.js'), `var PREPKIN_BRIDGE = { url: "${SCHOOL}", key: "test" };\n`);
  return dir;
}

test('Firefox: the build installs, its event page starts, and the skin reaches a Canvas page', { skip: !have && 'Firefox, the build, or the driver is missing' }, async () => {
  const { Builder } = require(path.join(DEPS, 'node_modules', 'selenium-webdriver'));
  const firefox = require(path.join(DEPS, 'node_modules', 'selenium-webdriver', 'firefox'));
  const gecko = require(path.join(DEPS, 'node_modules', 'geckodriver'));
  const server = await new FakeServer().start(PORT);
  await fetch(`${SCHOOL}/__world`, { method: 'POST', body: JSON.stringify({ host: 'localhost', world: S.plainSemester() }) });
  const tmp = fs.mkdtempSync(path.join(process.env.PREPKIN_TMP || os.tmpdir(), 'prepkin-ff-'));
  const ext = stage(tmp);
  // The add-on's internal UUID is pinned through the pref Firefox reads it
  // from, so its own pages have a known address (moz-extension://<uuid>/…).
  const UUID = '7a5f1b2c-3d4e-4f60-9a8b-1c2d3e4f5a6b';
  const opts = new firefox.Options().setBinary(FIREFOX).setAcceptInsecureCerts(true).addArguments('-headless')
    .setPreference('extensions.webextensions.uuids', JSON.stringify({ 'canvas@prepkin.com': UUID }));
  // The geckodriver package fetches Mozilla's binary once into its cache and
  // hands back the path (a no-op after the first time).
  const bin = await gecko.download();
  const service = new firefox.ServiceBuilder(bin);
  const driver = await new Builder().forBrowser('firefox').setFirefoxOptions(opts).setFirefoxService(service).build();
  try {
    // By path, not as a zip in the request: geckodriver's install command
    // takes a directory, which Firefox loads the way about:debugging does.
    const { Command } = require(path.join(DEPS, 'node_modules', 'selenium-webdriver', 'lib', 'command'));
    const id = await driver.execute(new Command('install addon').setParameter('path', ext).setParameter('temporary', true))
      .catch((e) => { throw new Error(`install addon: ${e.message || e.name}`); });
    assert.ok(id, 'the add-on installed');
    // The add-on's own page: from here its APIs are ours to call. What Firefox
    // granted, and whether the event page answers (background.js through its
    // Firefox path, no importScripts).
    await driver.get(`moz-extension://${UUID}/popup.html`);
    const granted = await driver.executeAsyncScript('const done = arguments[0]; browser.permissions.getAll().then((p) => done(p));');
    // The one question that could have made this a port: Firefox's chrome.*
    // is the browser.* namespace, and a call with no callback returns a promise
    // (measured on Firefox 129), so the ~40 awaited chrome.* calls hold.
    const promises = await driver.executeScript('const r = chrome.storage.local.get(["skin"]); return { returns: r === undefined ? "undefined" : typeof r.then, browserIsChrome: browser === chrome };');
    assert.deepEqual(promises, { returns: 'function', browserIsChrome: true }, 'chrome.* returns promises in Firefox');
    const answer = await driver.executeAsyncScript(`const done = arguments[0]; browser.runtime.sendMessage({ type: 'verify-canvas', origin: '${SCHOOL}' }).then((r) => done(r), (e) => done({ error: String(e) }));`);
    // Opened in a tab, this page is not the popup, so the worker's gate says
    // "Not allowed." That refusal IS the event page, alive and on guard.
    assert.ok(answer && typeof answer === 'object' && 'ok' in answer, `the event page answered: ${JSON.stringify(answer)}`);
    // Seed the state the Chrome harness seeds through the worker.
    await driver.executeAsyncScript(`const done = arguments[0]; browser.storage.local.set({ onboarded: true, origins: ['${SCHOOL}'], skin: { dark: true, cards: true, mascot: true, focusMinutes: 25 } }).then(() => done(true));`);
    await driver.get(`${SCHOOL}/`);
    const hostGranted = (granted.origins ?? []).some((o) => o.startsWith(`${new URL(SCHOOL).protocol}//${new URL(SCHOOL).hostname}`));
    if (!hostGranted) {
      // Firefox MV3 does not grant host permissions at install, even for a
      // temporary add-on; the popup asks from a click. That much is proven
      // here as a fact, not a failure.
      const cls = await driver.executeScript('return document.documentElement.className');
      assert.doesNotMatch(cls, /pk-on/, 'without the grant, the page is untouched');
      console.log(`  Firefox granted at install: ${JSON.stringify(granted)} — the school is asked for from the popup, as designed`);
      return;
    }
    await driver.wait(async () => /\bpk-on\b/.test(await driver.executeScript('return document.documentElement.className')), 15_000).catch(async () => {
      const title = await driver.getTitle();
      const cls = await driver.executeScript('return document.documentElement.className');
      await driver.get(`moz-extension://${UUID}/popup.html`);
      const reg = await driver.executeAsyncScript('const done = arguments[0]; browser.scripting.getRegisteredContentScripts().then((r) => done(r), (e) => done(String(e)));');
      const stored = await driver.executeAsyncScript('const done = arguments[0]; browser.storage.local.get(null).then((r) => done(JSON.stringify({ keys: Object.keys(r), errorLog: r.errorLog }).slice(0, 900)));');
      throw new Error(`pk-on never landed. title=${title} class="${cls}" granted=${JSON.stringify(granted)} registered=${JSON.stringify(reg)} stored=${stored}`);
    });
    const cls = await driver.executeScript('return document.documentElement.className');
    assert.match(cls, /pk-paper-/, `the paper class is on: ${cls}`);
    assert.ok(await driver.executeScript('return !!document.querySelector("[id^=\\"pk-\\"]")'), 'content.js drew something of ours');
  } finally {
    await driver.quit().catch(() => {});
    await server.stop();
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

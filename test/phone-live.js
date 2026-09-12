// Holds the fake Canvas and the REAL extension open, with the extension pointed
// at the REAL bridge (extension/config.js, the one bridge/apply-config.sh wrote),
// so the real iOS app on a simulator can be paired end to end without the
// sandbox VM. The only fake thing here is Canvas itself.
//
//   PREPKIN_CERT_DIR=~/Library/Developer/prepkin-canvas-test-deps/certs node test/phone-live.js
//
// Then, in the app: Home → the Canvas card → copy the code, and write it to
// $PREPKIN_TMP/pair-code.txt (or pass PAIR_CODE_FILE=...). This binds the
// extension to it on the live bridge and syncs. Commands go in phone-cmd.txt:
// sync, submit (Alex hands in Problem Set 7), storage, quit.
//
// PREPKIN_PORT (default 8444) keeps it off 8443, which the suites use.

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';
const fs = require('fs');
const os = require('os');
const path = require('path');
const { FakeServer } = require('./fake-canvas');
const { stageExtension, DEPS } = require('./harness');
const { chromium } = require(path.join(DEPS, 'node_modules/playwright'));
const S = require('./scenarios');

const PORT = Number(process.env.PREPKIN_PORT || 8444);
const SCHOOL = `https://localhost:${PORT}`;
const ROOT = path.join(__dirname, '..');
const CODE_FILE = process.env.PAIR_CODE_FILE || path.join(process.env.PREPKIN_TMP || os.tmpdir(), 'pair-code.txt');
const CMD_FILE = CODE_FILE.replace('pair-code', 'phone-cmd');

(async () => {
  const server = await new FakeServer().start(PORT);
  server.world('localhost'); Object.assign(server.worlds.localhost, S.plainSemester());

  // The harness's copy, then the two things that make it live: the real
  // config.js back in, and this port granted.
  const tmp = fs.mkdtempSync(path.join(process.env.PREPKIN_TMP || os.tmpdir(), 'prepkin-live-'));
  const ext = stageExtension(tmp);
  fs.copyFileSync(path.join(ROOT, 'extension', 'config.js'), path.join(ext, 'config.js'));
  const manifestPath = path.join(ext, 'manifest.json');
  const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  manifest.host_permissions = [...manifest.host_permissions, `${SCHOOL}/*`];
  fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2));

  const context = await chromium.launchPersistentContext(path.join(tmp, 'profile'), {
    channel: 'chromium', headless: !process.env.HEADED, ignoreHTTPSErrors: true,
    args: [`--disable-extensions-except=${ext}`, `--load-extension=${ext}`,
      '--ignore-certificate-errors', '--no-first-run', '--window-size=1200,900'],
  });
  let worker = context.serviceWorkers()[0];
  if (!worker) worker = await context.waitForEvent('serviceworker');
  const sw = (fn, arg) => worker.evaluate(fn, arg);
  await sw(() => chrome.storage.local.set({ onboarded: true }));
  await sw(async (o) => {
    const { origins = [] } = await chrome.storage.local.get('origins');
    await chrome.storage.local.set({ origins: [...new Set([...origins, o])] });
    await registerFor(o);
  }, SCHOOL);
  console.log(`ready: fake Canvas on ${SCHOOL}, extension on the live bridge; waiting for ${CODE_FILE}`);

  const tick = async () => {
    if (fs.existsSync(CODE_FILE)) {
      const code = fs.readFileSync(CODE_FILE, 'utf8').trim();
      fs.unlinkSync(CODE_FILE);
      console.log('bindWriter', code, JSON.stringify(await sw((c) => bindWriter(c), code)));
      console.log('syncNow', JSON.stringify(await sw((o) => syncNow(o), SCHOOL)));
    }
    if (fs.existsSync(CMD_FILE)) {
      const cmd = fs.readFileSync(CMD_FILE, 'utf8').trim();
      fs.unlinkSync(CMD_FILE);
      if (cmd === 'sync') console.log('syncNow', JSON.stringify(await sw((o) => syncNow(o), SCHOOL)));
      if (cmd === 'submit') {
        const a = server.worlds.localhost.assignments[1].find((x) => x.id === 11);
        a.submission = S.submitted(-0.01);
        console.log('syncNow after submit', JSON.stringify(await sw((o) => syncNow(o), SCHOOL)));
      }
      if (cmd === 'storage') console.log('extension storage', JSON.stringify(await sw(() => chrome.storage.local.get(null))).slice(0, 800));
      if (cmd === 'quit') { await context.close(); await server.stop(); fs.rmSync(tmp, { recursive: true, force: true }); process.exit(0); }
    }
  };
  setInterval(() => tick().catch((e) => console.error('tick', e.message)), 1000);
})().catch((e) => { console.error('ERR', e); process.exit(1); });

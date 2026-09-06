// Holds the fake bridge and the real extension open so the real iOS app, on a
// simulator that trusts test/make-cert.sh's certificate, can be paired by hand:
//
//   PREPKIN_CERT_DIR=~/Library/Developer/prepkin-canvas-test-deps/certs node test/phone-loop.js
//
// Then, in the app: Today → sliders → copy the code, and write it to
// $SCRATCH/pair-code.txt (or pass PAIR_CODE=...). This script binds the
// extension to it, syncs, and prints every bridge call the phone makes.

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';
const fs = require('fs');
const path = require('path');
const { FakeServer } = require('./fake-canvas');
const { launch, SCHOOL_A } = require('./harness');
const S = require('./scenarios');

const CODE_FILE = process.env.PAIR_CODE_FILE || path.join(process.env.PREPKIN_TMP || require('os').tmpdir(), 'pair-code.txt');
const CMD_FILE = CODE_FILE.replace('pair-code', 'phone-cmd');

(async () => {
  const server = await new FakeServer().start(8443);
  server.world('localhost'); Object.assign(server.worlds.localhost, S.plainSemester());
  const h = await launch();
  await h.setStorage({ onboarded: true });
  await h.connect(SCHOOL_A);
  console.log('ready: fake bridge + extension on https://localhost:8443; waiting for', CODE_FILE);

  let seen = 0;
  const tick = async () => {
    // Echo the phone's traffic as it happens.
    while (seen < server.bridge.calls.length) {
      const { fn, body } = server.bridge.calls[seen++];
      const brief = { ...body }; delete brief.p_token; if (brief.p_todo) brief.p_todo = `${brief.p_todo.tasks?.length} tasks`;
      console.log(`bridge ${fn}`, JSON.stringify(brief).slice(0, 200));
    }
    if (fs.existsSync(CODE_FILE)) {
      const code = fs.readFileSync(CODE_FILE, 'utf8').trim();
      fs.unlinkSync(CODE_FILE);
      const bound = await h.sw((c) => bindWriter(c), code);
      console.log('bindWriter', code, JSON.stringify(bound));
      console.log('syncNow', JSON.stringify(await h.sw((o) => syncNow(o), SCHOOL_A)));
    }
    if (fs.existsSync(CMD_FILE)) {
      const cmd = fs.readFileSync(CMD_FILE, 'utf8').trim();
      fs.unlinkSync(CMD_FILE);
      if (cmd === 'sync') console.log('syncNow', JSON.stringify(await h.sw((o) => syncNow(o), SCHOOL_A)));
      if (cmd === 'focus') {
        await h.sw((a) => focusStart(a), { taskId: 'c-localhost-a11', title: 'Problem Set 7', url: '', minutes: 25 });
        await h.sw(() => focusDone());
        console.log('focus session finished and queued');
      }
      if (cmd === 'submit') {
        // Alex hands in Problem Set 7 for real (well, in the fake).
        const w = server.worlds.localhost;
        const a = w.assignments[1].find((x) => x.id === 11);
        a.submission = S.submitted(-0.01);
        console.log('syncNow after submit', JSON.stringify(await h.sw((o) => syncNow(o), SCHOOL_A)));
      }
      if (cmd === 'storage') console.log('extension storage', JSON.stringify(await h.storage()).slice(0, 600));
      if (cmd === 'rows') console.log('bridge rows', JSON.stringify(Object.fromEntries(server.bridge.rows)).slice(0, 800));
      if (cmd === 'quit') { await h.close(); await server.stop(); process.exit(0); }
    }
  };
  setInterval(() => tick().catch((e) => console.error('tick', e.message)), 1000);
})().catch((e) => { console.error('ERR', e); process.exit(1); });

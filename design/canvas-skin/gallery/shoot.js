// Screenshots the HTML that build.js wrote. ONLY=focus,looks picks views; H=<px>
// sets the viewport height. Uses the same Playwright the e2e suite uses.
const path = require('path');
const { DEPS } = require(path.resolve(__dirname, '../../../test/harness'));
const { chromium } = require(path.join(DEPS, 'node_modules/playwright'));
const S = process.env.OUT || path.join(require('os').tmpdir(), 'prepkin-gallery');
(async () => {
  const b = await chromium.launch({ channel: 'chromium', timeout: 300_000 });
  for (const v of (process.env.ONLY ? process.env.ONLY.split(',') : ['panel', 'week', 'whatif', 'course', 'looks', 'addtask', 'focus', 'focusdone'])) {
    const p = await b.newPage({ viewport: { width: 420, height: (process.env.H ? +process.env.H : 900) }, deviceScaleFactor: 2 });
    await p.goto('file://' + S + '/' + v + '.html'); await p.waitForTimeout(300);
    await p.screenshot({ path: `${S}/${v}.png`, fullPage: true }); await p.close();
  }
  await b.close(); console.log('shot');
})().catch((e) => { console.error(e); process.exit(1); });

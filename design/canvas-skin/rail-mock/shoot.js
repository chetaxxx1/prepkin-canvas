// Renders mock.html to mock.png at 2x. node design/canvas-skin/rail-mock/shoot.js
const path = require('path');
const { DEPS } = require('../../../test/harness');
const { chromium } = require(path.join(DEPS, 'node_modules/playwright'));
(async () => {
  const b = await chromium.launch({ channel: 'chromium', timeout: 300_000 });
  const p = await b.newPage({ viewport: { width: 1500, height: 900 }, deviceScaleFactor: 2 });
  await p.goto('file://' + path.join(__dirname, 'mock.html'));
  await p.waitForTimeout(600);
  await p.screenshot({ path: path.join(__dirname, 'mock.png'), fullPage: true });
  await b.close();
  console.log('mock.png');
})().catch((e) => { console.error(e); process.exit(1); });

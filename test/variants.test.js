// The settings a student can change on any Canvas that change the page under
// the extension: their language (Spanish; Arabic, which flips the page to
// right-to-left), the dashboard view (cards, list, recent activity), the
// colour-overlay preference on cards, a collapsed global nav, and High
// Contrast. Real Canvas, real extension, the student's own settings — nothing
// here needs an admin.
//
//   ssh -N -L 3000:localhost:3000 canvas@VM
//   node --test test/variants.test.js
//
// Screenshots go to design/signoff/canvas-variants/.

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

const test = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const path = require('path');
const { FakeServer } = require('./fake-canvas');
const { launch, SCHOOL_A } = require('./harness');
const { SELECTORS } = require('../extension/selectors');

const UPSTREAM = process.env.CANVAS_UPSTREAM || 'http://127.0.0.1:3000';
const OUT = path.join(__dirname, '..', 'design', 'signoff', 'canvas-variants');
const STUDENT = { login: 'alex@prepkin.test', password: 'PrepkinSandbox!2026' };
const LIGHT = [[247, 246, 243], [255, 255, 255]];

let server, h, page, physics;

async function pixelAt(x, y) {
  const png = await page.screenshot({ clip: { x, y, width: 1, height: 1 } });
  let off = 8; const idat = [];
  while (off < png.length) {
    const len = png.readUInt32BE(off); const type = png.toString('ascii', off + 4, off + 8);
    if (type === 'IDAT') idat.push(png.subarray(off + 8, off + 8 + len));
    off += 12 + len;
  }
  const raw = require('zlib').inflateSync(Buffer.concat(idat));
  return [raw[1], raw[2], raw[3]];
}
const isPaper = (rgb) => LIGHT.some((t) => t.join() === rgb.join());

/// The student's own settings, changed the way the profile page changes them:
/// the session cookie plus Canvas's CSRF token, which it leaves readable.
async function asStudent(method, p, body) {
  return page.evaluate(async ({ method, p, body }) => {
    const token = decodeURIComponent((document.cookie.match(/(?:^|; )_csrf_token=([^;]+)/) || [])[1] || '');
    const r = await fetch(p, { method, headers: { 'Content-Type': 'application/json', Accept: 'application/json', 'X-CSRF-Token': token }, body: body ? JSON.stringify(body) : undefined });
    const text = (await r.text()).replace(/^while\(1\);/, '');
    let json = null; try { json = JSON.parse(text); } catch {}
    return { status: r.status, json, text: text.slice(0, 200) };
  }, { method, p, body });
}

async function open(p) {
  await page.goto(`${SCHOOL_A}${p}`, { waitUntil: 'domcontentloaded' });
  await page.waitForLoadState('networkidle', { timeout: 30_000 }).catch(() => {});
  if (p.startsWith('/?') || p === '/') await page.waitForSelector('.ic-DashboardCard__header_hero, .PlannerApp, #dashboard-activity, .planner-container', { state: 'attached', timeout: 90_000 }).catch(() => {});
  await page.waitForTimeout(1800);
}

/// What every variant must keep: the classes on, the buddy there, the paper
/// under the content, and the hooks that carry rules on this page.
async function measure(name, keys) {
  const on = await page.evaluate(() => document.documentElement.classList.contains('pk-on'));
  const buddy = await page.evaluate(() => !!document.getElementById('prepkin-buddy'));
  const hooks = {};
  for (const key of keys) hooks[key] = await page.evaluate((q) => document.querySelectorAll(q).length, SELECTORS[key].sel);
  const at = await page.evaluate(() => { const r = (document.getElementById('content') ?? document.body).getBoundingClientRect(); return [Math.max(1, Math.round(r.left + 6)), Math.max(1, Math.round(Math.min(r.top + 150, innerHeight - 3, r.bottom - 3)))]; });
  const content = await pixelAt(...at);
  await page.screenshot({ path: path.join(OUT, `${name}.png`) });
  return { on, buddy, hooks, content, paper: isPaper(content), dir: await page.evaluate(() => document.documentElement.dir || getComputedStyle(document.body).direction) };
}

async function noErrors() {
  const { errorLog = [] } = await h.storage();
  await h.sw(() => chrome.storage.local.remove('errorLog'));
  return errorLog.map((e) => `${e.where}: ${e.message}`);
}

test.before(async () => {
  fs.mkdirSync(OUT, { recursive: true });
  server = await new FakeServer({ upstream: UPSTREAM }).start(8443);
  h = await launch();
  page = await h.context.newPage();
  page.setDefaultNavigationTimeout(120_000);
  page.setDefaultTimeout(60_000);
  await h.setStorage({ onboarded: true, skin: { dark: false, cards: true, mascot: true, focusMinutes: 25 } });
  await page.goto(`${SCHOOL_A}/login/canvas`, { waitUntil: 'domcontentloaded' });
  await page.fill('#pseudonym_session_unique_id', STUDENT.login);
  await page.fill('#pseudonym_session_password', STUDENT.password);
  await page.press('#pseudonym_session_password', 'Enter');
  await page.waitForURL((u) => !u.pathname.startsWith('/login'), { timeout: 120_000, waitUntil: 'domcontentloaded' });
  const courses = (await asStudent('GET', '/api/v1/courses?enrollment_state=active&per_page=100')).json;
  physics = courses.find((c) => /AP Physics/.test(c.name)) ?? courses[0];
  assert.ok(physics, 'seed.py has not run on this sandbox');
  await h.connect(SCHOOL_A);
});

test.after(async () => {
  // Alex back the way the seed left them, whatever happened above.
  await asStudent('PUT', '/api/v1/users/self', { user: { locale: 'en' } }).catch(() => {});
  await asStudent('PUT', '/api/v1/users/self/dashboard_view', { dashboard_view: 'cards' }).catch(() => {});
  await asStudent('PUT', '/api/v1/users/self/settings', { hide_dashcard_color_overlays: false, collapse_global_nav: false }).catch(() => {});
  await asStudent('DELETE', '/api/v1/users/self/features/flags/high_contrast').catch(() => {});
  await h?.close(); await server?.stop();
});

for (const locale of ['es', 'ar']) {
  test(`V1 the page in ${locale === 'es' ? 'Spanish' : 'Arabic, right-to-left'}: the same hooks, the same paper, the buddy`, { timeout: 600_000 }, async () => {
    const set = await asStudent('PUT', '/api/v1/users/self', { user: { locale } });
    assert.equal(set.status, 200, set.text);
    try {
      await open('/');
      const dash = await measure(`locale-${locale}-dashboard`, ['navRail', 'headerLogo', 'card', 'cardHero']);
      await open(`/courses/${physics.id}/modules`);
      const mods = await measure(`locale-${locale}-modules`, ['courseNav', 'courseNavLowUse', 'moduleHeader', 'moduleDue']);
      for (const [name, m] of [['dashboard', dash], ['modules', mods]]) {
        assert.ok(m.on && m.buddy, `${name}: skin on and buddy there`);
        for (const [k, n] of Object.entries(m.hooks)) assert.ok(n > 0, `${name}: ${k} still matches in ${locale}`);
        assert.ok(m.paper, `${name}: ground is ${m.content}`);
      }
      if (locale === 'ar') assert.equal(dash.dir, 'rtl', 'Canvas really went right-to-left');
      assert.deepEqual(await noErrors(), []);
    } finally {
      await asStudent('PUT', '/api/v1/users/self', { user: { locale: 'en' } });
    }
  });
}

for (const view of ['planner', 'activity']) {
  test(`V2 the ${view === 'planner' ? 'List View' : 'Recent Activity'} dashboard: skin on, buddy there, nothing errors`, { timeout: 600_000 }, async () => {
    const set = await asStudent('PUT', '/api/v1/users/self/dashboard_view', { dashboard_view: view });
    assert.equal(set.status, 200, set.text);
    try {
      await open('/');
      const m = await measure(`dashboard-${view}`, ['navRail', 'headerLogo']);
      assert.ok(m.on && m.buddy, 'skin on and buddy there');
      assert.ok(m.paper, `ground is ${m.content}`);
      assert.deepEqual(await noErrors(), []);
    } finally {
      await asStudent('PUT', '/api/v1/users/self/dashboard_view', { dashboard_view: 'cards' });
    }
  });
}

test('V3 colour overlays hidden: the card hero keeps whatever opacity Canvas gave it, and the course colour stays on the title', { timeout: 600_000 }, async () => {
  const set = await asStudent('PUT', '/api/v1/users/self/settings', { hide_dashcard_color_overlays: true });
  assert.equal(set.status, 200, set.text);
  try {
    await open('/');
    const m = await measure('overlays-hidden', ['card', 'cardHero']);
    assert.ok(m.on && m.buddy && m.paper, JSON.stringify(m));
    // Canvas writes the opacity inline (0 under a course image with overlays
    // hidden; nothing on a plain colour card, as on George's own Dartmouth
    // dashboard). Whatever it wrote is what the student must still see.
    const hero = await page.evaluate(() => [...document.querySelectorAll('.ic-DashboardCard__header_hero')].map((el) => [el.style.opacity || '1', getComputedStyle(el).opacity]));
    assert.ok(hero.length && hero.every(([theirs, shown]) => Number(theirs) === Number(shown)), `hero opacity is the student's setting, not ours: ${JSON.stringify(hero)}`);
    const titles = await page.evaluate(() => [...document.querySelectorAll('.ic-DashboardCard__header-title span[style]')].map((el) => el.style.color).filter(Boolean));
    assert.ok(titles.length > 0, 'the course colour is still on the title');
    assert.deepEqual(await noErrors(), []);
  } finally {
    await asStudent('PUT', '/api/v1/users/self/settings', { hide_dashcard_color_overlays: false });
  }
});

test('V4 a collapsed global nav: skin on, buddy clear of the rail', { timeout: 600_000 }, async () => {
  const set = await asStudent('PUT', '/api/v1/users/self/settings', { collapse_global_nav: true });
  assert.equal(set.status, 200, set.text);
  try {
    await open('/');
    const m = await measure('nav-collapsed', ['navRail', 'headerLogo', 'card']);
    assert.ok(m.on && m.buddy && m.paper, JSON.stringify(m));
    assert.deepEqual(await noErrors(), []);
  } finally {
    await asStudent('PUT', '/api/v1/users/self/settings', { collapse_global_nav: false });
  }
});

test('V6 a narrow window: Canvas folds its sidebar and rail away; skin on, buddy there, nothing errors', { timeout: 600_000 }, async () => {
  await page.setViewportSize({ width: 620, height: 800 });
  try {
    await open('/');
    const m = await measure('narrow-dashboard', ['navRail', 'card']);
    assert.ok(m.on && m.buddy, JSON.stringify(m));
    assert.deepEqual(await noErrors(), []);
    await open(`/courses/${physics.id}/modules`);
    const mods = await measure('narrow-modules', ['moduleHeader']);
    assert.ok(mods.on && mods.buddy, JSON.stringify(mods));
    assert.deepEqual(await noErrors(), []);
  } finally {
    await page.setViewportSize({ width: 1280, height: 720 });
  }
});

test('V5 High Contrast on: the skin takes itself off entirely on a real page', { timeout: 600_000 }, async () => {
  const set = await asStudent('PUT', '/api/v1/users/self/features/flags/high_contrast', { state: 'on' });
  assert.equal(set.status, 200, set.text);
  try {
    await open('/');
    const hc = await page.evaluate(() => ({
      env: /"use_high_contrast"\s*:\s*true/.test([...document.querySelectorAll('script:not([src])')].map((s) => s.textContent).join('')),
      pk: [...document.documentElement.classList].filter((c) => c.startsWith('pk-')),
      vars: !!document.getElementById('pk-theme-vars'),
    }));
    await page.screenshot({ path: path.join(OUT, 'high-contrast.png') });
    assert.ok(hc.env, 'Canvas really turned High Contrast on');
    assert.deepEqual(hc.pk.filter((c) => c !== 'pk-show'), [], `no skin classes under High Contrast: ${hc.pk}`);
    assert.equal(hc.vars, false, 'no stylesheet of ours either');
    assert.deepEqual(await noErrors(), []);
  } finally {
    await asStudent('DELETE', '/api/v1/users/self/features/flags/high_contrast');
  }
});

// The real extension against the real, self-hosted Canvas sandbox.
//
//   ssh -N -L 3000:localhost:3000 canvas@VM   (in another terminal)
//   CANVAS_TOKEN=<admin token> node --test test/live.test.js
//
// The fake bridge and fake phone stay; only Canvas is real, proxied from the
// tunnel onto https://localhost:8443 so the extension sees the origin it
// already trusts. Every API reply is recorded into test/recorded/ for
// compare-shapes.js. Screenshots land in design/signoff/canvas-live/.
//
// Assumes design/canvas-skin/sandbox/seed.py has run.

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

const test = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const path = require('path');
const { FakeServer } = require('./fake-canvas');
const { FakePhone } = require('./fake-phone');
const { launch, SCHOOL_A, BRIDGE } = require('./harness');
const { openPopup } = require('./popup');
const { SELECTORS } = require('../extension/selectors');

const UPSTREAM = process.env.CANVAS_UPSTREAM || 'http://127.0.0.1:3000';
const TOKEN = process.env.CANVAS_TOKEN;
const RECORD = path.join(__dirname, 'recorded');
const SHOTS = path.join(__dirname, '..', 'design', 'signoff', 'canvas-live');
const STUDENT = { login: 'alex@prepkin.test', password: 'PrepkinSandbox!2026' };

let server, h, phone, page, physics, english, alex;

/// Admin calls straight to the tunnel, the same way seed.py does.
async function api(method, p, params = null, asUser = null) {
  const url = new URL(`/api/v1/${p.replace(/^\//, '')}`, UPSTREAM);
  if (asUser) url.searchParams.set('as_user_id', asUser);
  const body = params ? new URLSearchParams(params) : undefined;
  const res = await fetch(url, { method, headers: { Authorization: `Bearer ${TOKEN}` }, body });
  const text = (await res.text()).replace(/^while\(1\);/, '');
  if (!res.ok) throw new Error(`${method} ${p} -> ${res.status}: ${text.slice(0, 300)}`);
  return text ? JSON.parse(text) : null;
}

const sync = () => h.sw((o) => syncNow(o), SCHOOL_A);
const byTitle = (todo, title) => todo.tasks.find((t) => t.title === title);
const shot = (name) => page.screenshot({ path: path.join(SHOTS, `${name}.png`), fullPage: false });
/// The rendered colour at one point of the page — what the student sees, not
/// what a stylesheet says. A 1x1 PNG is eight bytes past its IDAT.
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

test.before(async () => {
  assert.ok(TOKEN, 'set CANVAS_TOKEN to an admin access token');
  fs.mkdirSync(SHOTS, { recursive: true });
  server = await new FakeServer({ upstream: UPSTREAM, record: RECORD }).start(8443);
  h = await launch();
  // Log the student in for real, so the extension's cookie session is Alex's.
  page = await h.context.newPage();
  // Through the proxy a page's `load` can wait on straggling assets, and a
  // freshly started Canvas serves its first pages slowly. The DOM is enough.
  page.setDefaultNavigationTimeout(60_000);
  page.setDefaultTimeout(30_000);
  // The DOM is all the login needs; `load` can wait on a straggling asset.
  await page.goto(`${SCHOOL_A}/login/canvas`, { waitUntil: 'domcontentloaded', timeout: 60_000 });
  await page.fill('#pseudonym_session_unique_id', STUDENT.login);
  await page.fill('#pseudonym_session_password', STUDENT.password);
  await page.press('#pseudonym_session_password', 'Enter');
  await page.waitForURL((u) => !u.pathname.startsWith('/login'), { timeout: 60_000, waitUntil: 'domcontentloaded' });
  const courses = await api('GET', 'accounts/1/courses?per_page=100');
  physics = courses.find((c) => c.name.startsWith('AP Physics'));
  english = courses.find((c) => c.name.startsWith('English 11'));
  alex = (await api('GET', `accounts/1/users?search_term=${STUDENT.login}`)).find((u) => u.login_id === STUDENT.login);
  assert.ok(physics && english && alex, 'seed.py has not run');
});
test.after(async () => { await h?.close(); await server?.stop(); });

test('L1 the real Canvas is recognised and the panel mounts on a real page', async () => {
  await h.setStorage({ onboarded: true });
  const check = await h.sw((o) => isCanvas(o), SCHOOL_A);
  assert.deepEqual(check, { ok: true, name: 'Alex Rivera' });
  await h.connect(SCHOOL_A);
  await page.goto(`${SCHOOL_A}/`, { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('#prepkin-buddy', { state: 'attached', timeout: 20_000 });
  await shot('01-dashboard');
});

test('L2 pairing and the first sync carry the seeded states', async () => {
  phone = new FakePhone(BRIDGE);
  const code = await phone.claim();
  assert.deepEqual(await h.sw((c) => bindWriter(c), code), { ok: true });
  const status = await sync();
  assert.equal(status.ok, true, JSON.stringify(status));
  const todo = await phone.fetchTodo();
  fs.writeFileSync(path.join(RECORD, '_first-push.json'), JSON.stringify(todo, null, 2));

  const owed = (t) => { const x = byTitle(todo, t); assert.ok(x, `${t} missing`); assert.equal(x.submittedAt, null, `${t} should be owed`); return x; };
  const handedIn = (t) => { const x = byTitle(todo, t); assert.ok(x, `${t} missing`); assert.ok(x.submittedAt, `${t} should be handed in`); return x; };
  const absent = (t) => assert.equal(byTitle(todo, t), undefined, `${t} should be off the list`);

  // Problem Set 8 and the Lab writeup are left out on purpose: earlier runs
  // of L3/L4 used to grade and excuse them. Every other seeded state is fixed.
  owed('Problem Set 7: Rotational Inertia');
  absent('Unit 4 project proposal');                       // 27 days out
  owed('Extra practice (optional)');                       // undated, has points
  handedIn('Close reading: Song of Myself');               // submitted, ungraded
  // Seeded as "5 days ago", but a student cannot backdate a submission, so
  // Canvas dated it today: inside the three-day grace, graded 54.
  assert.equal(handedIn('Rhetorical analysis: Letter from Birmingham Jail').score, 54);
  handedIn('Problem Set 6: Work and Energy');              // late, accepted
  assert.equal(handedIn('Problem Set 6: Work and Energy').score, 41);
  absent('Reading check: Chapter 9');                      // missing, zero, 8 days overdue
  absent('Quiz corrections');                              // excused
  handedIn('Problem Set 5: Kinematics');                   // resubmitted
  handedIn('In-class derivation check');                   // on paper
  assert.equal(handedIn('In-class derivation check').score, 18);
  const ov = owed('Reading response: Chapter 10');         // section override
  assert.ok(ov.dueAt, 'the override date is mine, not undated');
  owed('Graded: one sentence on Douglass\'s audience');
  owed('Unit 4 concept check');
  assert.equal(todo.tasks.filter((t) => t.title === 'Unit 4 concept check').length, 1, 'the quiz appears once');
  absent('Lab 1 report');                                  // TA course: marking, not homework
  assert.equal(todo.courses.find((c) => c.name.startsWith('Intro Lab')), undefined, 'the TA course is not yours');
  assert.ok(todo.courses.find((c) => c.name.startsWith('AP Physics')).score !== undefined);
});

/// L2's pairing and sync, for rows that run on their own.
async function ensurePaired() {
  if (phone) return;
  await h.setStorage({ onboarded: true, skin: { dark: false, cards: true, mascot: true, focusMinutes: 25 } });
  await h.connect(SCHOOL_A);
  phone = new FakePhone(BRIDGE);
  const code = await phone.claim();
  assert.deepEqual(await h.sw((c) => bindWriter(c), code), { ok: true });
  assert.equal((await sync()).ok, true);
}

/// A fresh assignment per run, so the live test can run again and again.
/// (Not a seeded one: Problem Set 7 sits behind a must-view page in a
/// sequential module and Canvas refuses submissions to locked work with 403 —
/// real behaviour worth knowing: a locked assignment still lists.)
async function freshAssignment(label) {
  const title = `${label} ${new Date().toISOString().slice(11, 19)}`;
  const a = await api('POST', `courses/${physics.id}/assignments`, {
    'assignment[name]': title, 'assignment[points_possible]': '50', 'assignment[published]': 'true',
    'assignment[submission_types][]': 'online_text_entry',
    'assignment[due_at]': new Date(Date.now() + 86_400_000).toISOString(),
  });
  return { title, a };
}

test('L3 submitting for real turns into "handed in" on the next sync', async () => {
  await ensurePaired();
  const { title, a } = await freshAssignment('Live: submit then grade');
  await sync();
  assert.equal(byTitle(await phone.fetchTodo(), title).submittedAt, null, 'owed to start with');
  await api('POST', `courses/${physics.id}/assignments/${a.id}/submissions`,
    { 'submission[submission_type]': 'online_text_entry', 'submission[body]': '<p>Done via the live test.</p>' }, alex.id);
  await sync();
  let t = byTitle(await phone.fetchTodo(), title);
  assert.ok(t.submittedAt, 'handed in');
  assert.equal(t.score, null, 'not graded yet');
  await api('PUT', `courses/${physics.id}/assignments/${a.id}/submissions/${alex.id}`, { 'submission[posted_grade]': '47' });
  await sync();
  t = byTitle(await phone.fetchTodo(), title);
  assert.equal(t.score, 47);
});

test('L4 a zero for missing work stays owed; excusing it takes it off the list', async () => {
  await ensurePaired();
  const { title, a } = await freshAssignment('Live: zero then excuse');
  await api('PUT', `courses/${physics.id}/assignments/${a.id}/submissions/${alex.id}`, { 'submission[posted_grade]': '0' });
  await sync();
  let t = byTitle(await phone.fetchTodo(), title);
  assert.ok(t, 'still on the list');
  assert.equal(t.submittedAt, null, 'a teacher-entered zero is not a submission');
  await api('PUT', `courses/${physics.id}/assignments/${a.id}/submissions/${alex.id}`, { 'submission[excuse]': 'true' });
  await sync();
  assert.equal(byTitle(await phone.fetchTodo(), title), undefined, 'excused leaves the list');
});

test('L5 the skin and panel on every page that matters', async () => {
  await ensurePaired();
  // The panel is in a closed shadow root, so open it by clicking where the
  // mascot sits, bottom right. After L2–L4 it has real synced data to show.
  await page.goto(`${SCHOOL_A}/`, { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('#prepkin-buddy', { state: 'attached', timeout: 20_000 });
  const box = await page.evaluate(() => { const r = document.getElementById('prepkin-buddy').getBoundingClientRect(); return { x: r.x + r.width - 40, y: r.y + r.height - 40 }; });
  await page.mouse.click(box.x, box.y);
  await page.waitForTimeout(800);
  await shot('01b-panel-open');
  for (const [name, p] of [
    ['02-assignments', `/courses/${physics.id}/assignments`],
    ['03-grades', `/courses/${physics.id}/grades`],
    ['04-modules', `/courses/${physics.id}/modules`],
    ['05-planner', '/?dashboard_view=planner'],
    ['06-empty-course', `/courses/${(await api('GET', 'accounts/1/courses?per_page=100')).find((c) => c.name === 'Ceramics I').id}`],
  ]) {
    await page.goto(`${SCHOOL_A}${p}`, { waitUntil: 'domcontentloaded' });
    await page.waitForLoadState('networkidle').catch(() => {});
    await shot(name);
  }
  // The dashboard cards carry the next due line, from real synced data.
  await page.goto(`${SCHOOL_A}/`, { waitUntil: 'domcontentloaded' });
  // React redraws the cards after the sidebar lands; wait until the student's
  // own courses all carry their line (the TA course never does).
  await page.waitForFunction(() => { const cards = [...document.querySelectorAll('.ic-DashboardCard')].filter((c) => !/TA\)/.test(c.textContent)); return cards.length > 0 && cards.every((c) => c.querySelector('.pk-card-due')); }, null, { timeout: 30_000 });
  const lines = await page.$$eval('.ic-DashboardCard', (cards) => cards.map((c) => `${c.querySelector('.ic-DashboardCard__header-title')?.textContent}: ${c.querySelector('.pk-card-due')?.textContent}`));
  console.log(lines);
  assert.ok(lines.some((l) => /AP Physics.*Problem Set 7/.test(l)), lines.join(' | '));
  await shot('07-dashboard-cards');
  // Dark mode on an assignment page: the submit button must stay visible.
  const a = (await api('GET', `courses/${physics.id}/assignments?per_page=100`)).find((x) => x.name.startsWith('Problem Set 8'));
  await h.setStorage({ skin: { dark: true, cards: true, tidy: true, mascot: true, focusMinutes: 25 } });
  await page.goto(`${SCHOOL_A}/courses/${physics.id}/assignments/${a.id}`, { waitUntil: 'domcontentloaded' });
  await page.waitForLoadState('networkidle').catch(() => {});
  await shot('08-dark-assignment');
  await h.setStorage({ skin: { dark: false, cards: true, tidy: true, mascot: true, focusMinutes: 25 } });
});

test('L6 the feature flags that rewrite markup, as this Canvas build names them', async () => {
  // The names in RESEARCH.md were from Instructure's hosted release notes.
  // This build (April 2026 source) only carries these two as flags; the nav
  // and top-bar rewrites have shipped and are no longer switchable.
  const flags = [
    ['modules_page_rewrite_student_view', `courses/${physics.id}`, `/courses/${physics.id}/modules`],
    ['responsive_student_grades_page', 'accounts/1', `/courses/${physics.id}/grades`],
  ];
  const report = {};
  for (const [flag, scope, target] of flags) {
    const known = (await api('GET', `${scope}/features?per_page=200`)).map((f) => f.feature);
    if (!known.includes(flag)) { report[flag] = 'not in this Canvas'; continue; }
    await api('PUT', `${scope}/features/flags/${flag}`, { state: 'on' });
    try {
      await page.goto(`${SCHOOL_A}${target}`, { waitUntil: 'domcontentloaded' });
      await page.waitForLoadState('networkidle').catch(() => {});
      await shot(`flag-${flag}`);
      report[flag] = 'screenshot';
    } finally {
      // Whatever happened above, the sandbox goes back to the classic pages.
      await api('DELETE', `${scope}/features/flags/${flag}`).catch(() => api('PUT', `${scope}/features/flags/${flag}`, { state: 'off' }));
    }
  }
  fs.writeFileSync(path.join(SHOTS, 'flags.json'), JSON.stringify(report, null, 2));
});

// MARK: - L7: the selector smoke check and the Receipt on real pages

test('L7 every load-bearing selector still matches on this Canvas, and the receipt reads the real pages', async () => {
  const pages = {
    any: '/', dashboard: '/', course: `/courses/${physics.id}`, modules: `/courses/${physics.id}/modules`,
    // An unlocked one: a page behind a sequential module shows no prose at all.
    assignment: `/courses/${physics.id}/assignments/${(await api('GET', `courses/${physics.id}/assignments?per_page=100`)).find((a) => a.name.startsWith('Problem Set 8')).id}`,
    grades: `/courses/${physics.id}/grades`,
  };
  // Self-sufficient, so it can run on its own with --test-name-pattern L7.
  await h.setStorage({ onboarded: true, skin: { dark: false, cards: true, mascot: true, focusMinutes: 25 } });
  await h.connect(SCHOOL_A);
  const report = {};
  for (const [key, { sel, page: where, never }] of Object.entries(SELECTORS)) {
    if (!pages[where]) { report[key] = `skipped (${where})`; continue; }
    await page.goto(`${SCHOOL_A}${pages[where]}`, { waitUntil: 'domcontentloaded' });
    await page.waitForLoadState('networkidle').catch(() => {});
    await page.waitForTimeout(500);
    const n = await page.evaluate((q) => document.querySelectorAll(q).length, sel);
    report[key] = n ? `${n} match${n > 1 ? 'es' : ''}` : 'NO MATCH';
  }
  console.log(report);
  fs.writeFileSync(path.join(SHOTS, 'selectors.json'), JSON.stringify(report, null, 2));
  // These carry rules today; a miss means a Canvas deploy moved the ground.
  for (const key of ['navRail', 'headerLogo', 'card', 'cardHero', 'courseNav', 'courseNavLowUse', 'moduleHeader', 'moduleDue', 'userContent']) {
    assert.notEqual(report[key], 'NO MATCH', key);
  }
  // The receipt, on the real dashboard and modules page, in both papers.
  for (const [name, p, dark] of [['10-receipt-dashboard', '/', false], ['11-receipt-modules', `/courses/${physics.id}/modules`, false], ['12-carbon-dashboard', '/', true], ['13-carbon-modules', `/courses/${physics.id}/modules`, true]]) {
    await h.setStorage({ skin: { dark, cards: true, mascot: true, focusMinutes: 25 } });
    await page.goto(`${SCHOOL_A}${p}`, { waitUntil: 'domcontentloaded' });
    await page.waitForLoadState('networkidle').catch(() => {});
    // The dashboard sidebar arrives by XHR and paints white for a moment
    // before Canvas's own styles settle; measure after it has.
    await page.waitForTimeout(1800);
    await shot(name);
    // Rendered pixels, not stylesheet claims: the page ground and, on the
    // dashboard, the sidebar column, must be one of the paper's two tones
    // (a sample can land on a row, which is paper-2).
    const tones = dark ? [[23, 25, 29], [30, 33, 38]] : [[247, 246, 243], [255, 255, 255]];
    // Only the dashboard has a sidebar column worth sampling; course pages keep
    // an empty aside whose pixels are whatever sits there.
    const side = p === '/' ? await page.evaluate(() => { const r = document.getElementById('right-side')?.getBoundingClientRect(); return r ? [Math.round(r.left + 30), Math.round(r.top + 300)] : null; }) : null;
    const samples = { content: await pixelAt(700, 600) };
    if (side) samples.sidebar = await pixelAt(...side);
    for (const [where, rgb] of Object.entries(samples)) {
      assert.ok(tones.some((t) => t.join() === rgb.join()), `${name}: ${where} pixel is ${rgb}, paper tones are ${JSON.stringify(tones)}`);
    }
    if (!dark) {
      await page.bringToFront();
      const popup = await openPopup(h);
      try {
        await popup.waitFor('#receipt-fixed li');
      } catch (e) {
        console.log('popup state', await popup.evaluate(`JSON.stringify({ hidden: document.getElementById('receipt').hidden, off: document.getElementById('receipt-off').textContent, onboarding: !document.getElementById('onboarding').hidden, url: location.href })`));
        console.log('tab', await h.sw(() => chrome.tabs.query({ active: true, currentWindow: true }).then((t) => t.map((x) => x.url))));
        throw e;
      }
      const rows = await popup.evaluate(`[...document.querySelectorAll('#receipt li')].map((li) => li.textContent.trim())`);
      console.log(name, rows);
      fs.writeFileSync(path.join(SHOTS, `${name}.json`), JSON.stringify(rows, null, 2));
      await popup.screenshot(path.join(SHOTS, `${name}-popup.png`));
      await popup.close();
    }
  }
  await h.setStorage({ skin: { dark: false, cards: true, mascot: true, focusMinutes: 25 } });
});

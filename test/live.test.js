// The real extension against the real, self-hosted Canvas sandbox.
//
//   ssh -N -L 3000:localhost:3000 canvas@VM   (in another terminal)
//   CANVAS_TOKEN=<admin token> node --test test/live.test.js
//   node --test test/live.test.js                (no token: the seeded teacher
//                                                 and student log in instead)
//
// Without an admin token every call goes through a real login session
// (test/live-clean.js): the teacher makes, grades and excuses assignments,
// the student hands work in, and the account-level feature flag in L6 is
// reported as needing an admin rather than switched.
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
const { teacherSession, deleteAssignments } = require('./live-clean');

const UPSTREAM = process.env.CANVAS_UPSTREAM || 'http://127.0.0.1:3000';
const TOKEN = process.env.CANVAS_TOKEN;
const RECORD = path.join(__dirname, 'recorded');
const SHOTS = path.join(__dirname, '..', 'design', 'signoff', 'canvas-live');
const STUDENT = { login: 'alex@prepkin.test', password: 'PrepkinSandbox!2026' };

let server, h, phone, page, physics, english, alex;
// What this run made on the sandbox; test.after deletes it (teacher session
// + _csrf_token, no admin needed), so the "Live:" rows never pile up in
// course 4. `node test/live-clean.js` sweeps leftovers from a killed run.
const made = [];

const TEACHER = { login: 'teacher@prepkin.test', password: 'PrepkinSandbox!2026' };
let sessions = null;

/// Admin calls straight to the tunnel, the same way seed.py does — or, with
/// no token, the same calls as the teacher or the student, logged in.
async function api(method, p, params = null, asUser = null) {
  if (!TOKEN) return sessionApi(method, p, params, asUser);
  const url = new URL(`/api/v1/${p.replace(/^\//, '')}`, UPSTREAM);
  if (asUser) url.searchParams.set('as_user_id', asUser);
  const body = params ? new URLSearchParams(params) : undefined;
  const res = await fetch(url, { method, headers: { Authorization: `Bearer ${TOKEN}` }, body });
  const text = (await res.text()).replace(/^while\(1\);/, '');
  if (!res.ok) throw new Error(`${method} ${p} -> ${res.status}: ${text.slice(0, 300)}`);
  return text ? JSON.parse(text) : null;
}

/// The admin-only paths the test uses, said the way a teacher or the student
/// can say them: the account's course list is the student's own (Alex is in
/// every course the test names), the user search is `users/self`, and a call
/// made as Alex is made by Alex.
async function sessionApi(method, p, params, asUser) {
  if (!sessions) sessions = { teacher: await teacherSession(UPSTREAM, TEACHER), student: await teacherSession(UPSTREAM, STUDENT) };
  if (/^accounts\/1\/courses/.test(p)) return sessions.student.api('GET', 'courses?per_page=100&enrollment_state=active');
  // `users/self` carries no login_id; the caller matches on it, so it is added.
  if (/^accounts\/1\/users\?search_term=/.test(p)) return [{ ...await sessions.student.api('GET', 'users/self'), login_id: STUDENT.login }];
  if (/^accounts\/1\/features/.test(p)) throw new Error('account feature flags need an admin token');
  return (asUser ? sessions.student : sessions.teacher).api(method, p, params);
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
  if (!TOKEN) console.log('no CANVAS_TOKEN: running as the seeded teacher and student');
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
test.after(async () => {
  await h?.close(); await server?.stop();
  if (made.length) {
    const gone = await deleteAssignments(sessions?.teacher ?? await teacherSession(UPSTREAM), physics.id, made).catch((e) => { console.log(`live-clean failed: ${e.message}`); return []; });
    console.log(`live-clean: ${gone.length}/${made.length} of this run's assignments deleted`);
  }
});

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

  // Owed work older than DAYS_OVERDUE (7) days is the panel's Missing list,
  // not the phone's push, so what the seed dated relative to its own day
  // reads by its due date: within the week, owed; before it, gone.
  const dues = Object.fromEntries((await Promise.all([physics, english].map((c) => api('GET', `courses/${c.id}/assignments?per_page=100`)))).flat().map((a) => [a.name, a.due_at]));
  const owed = (t) => {
    const x = byTitle(todo, t);
    const due = dues[t] ? Date.parse(dues[t]) : NaN;
    if (Number.isFinite(due) && Date.now() - due > 7 * 86_400_000) { assert.equal(x, undefined, `${t} was due ${dues[t]} and should be off the phone's list`); return { dueAt: dues[t] }; }
    assert.ok(x, `${t} missing`); assert.equal(x.submittedAt, null, `${t} should be owed`); return x;
  };
  // Canvas dates every seeded submission at seed time (a student cannot
  // backdate), and handed-in work leaves the list DAYS_AFTER_SUBMIT (3) days
  // later. The courses were made at the same moment, so their age says which
  // reading is right: within three days of the seed, handed in; after, gone.
  const seedAge = (Date.now() - Date.parse(physics.created_at)) / 86_400_000;
  const settled = seedAge > 3;
  const handedIn = (t) => {
    const x = byTitle(todo, t);
    if (settled) { assert.equal(x, undefined, `${t} was handed in ${Math.floor(seedAge)} days ago and should be off the list`); return { score: undefined }; }
    assert.ok(x, `${t} missing`); assert.ok(x.submittedAt, `${t} should be handed in`); return x;
  };
  const scored = (t, n) => { const x = handedIn(t); if (!settled) assert.equal(x.score, n); };
  const absent = (t) => assert.equal(byTitle(todo, t), undefined, `${t} should be off the list`);

  // Problem Set 7, Problem Set 8 and the Lab writeup are left out on purpose:
  // earlier runs of L3/L4 used to grade and excuse them, and by 2026-09-14 all
  // three carried scores on the sandbox. Every other seeded state is fixed.
  absent('Unit 4 project proposal');                       // 27 days out
  owed('Extra practice (optional)');                       // undated, has points
  handedIn('Close reading: Song of Myself');               // submitted, ungraded
  // Seeded as "5 days ago", but a student cannot backdate a submission, so
  // Canvas dated it today: inside the three-day grace, graded 54.
  scored('Rhetorical analysis: Letter from Birmingham Jail', 54);
  scored('Problem Set 6: Work and Energy', 41);             // late, accepted
  absent('Reading check: Chapter 9');                      // missing, zero, 8 days overdue
  absent('Quiz corrections');                              // excused
  handedIn('Problem Set 5: Kinematics');                   // resubmitted
  scored('In-class derivation check', 18);                 // on paper
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
  made.push(a.id);
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
  // The line is cut at a word to fit the card, so match the shape, not a title.
  assert.ok(lines.some((l) => /^AP Physics.*(due|Start)/.test(l)), lines.join(' | '));
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
    let known;
    try { known = (await api('GET', `${scope}/features?per_page=200`)).map((f) => f.feature); }
    catch (e) { report[flag] = `not switched: ${e.message}`; continue; }
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
    // Below our rail card, which now sits at the top of the column.
    const side = p === '/' ? await page.evaluate(() => { const r = document.getElementById('right-side')?.getBoundingClientRect(); const w = document.getElementById('pk-week')?.getBoundingClientRect(); return r ? [Math.round(r.left + 30), Math.round((w ? w.bottom : r.top) + 40)] : null; }) : null;
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

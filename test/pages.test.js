// The visual floor: every student-facing page, light and dark, with the skin
// on, on the real sandbox Canvas. What a student sees, not what a stylesheet
// says. Found the seven bugs of 2026-09-14 (a white "Show by date" toggle, dark
// labels on dark, a white mini calendar frame, a white file row, a white wiki
// footer, a card in three boxes, planner titles broken four letters a line).
//
//   ssh -N -L 3000:localhost:3000 canvas@<VM IP>      (in another terminal)
//   PREPKIN_PORT=8445 node --test test/pages.test.js
//   PAGES=dashboard,files MODES=dark node --test test/pages.test.js   (a subset)
//   BASELINE=1 node --test test/pages.test.js   (skin off: records Canvas's own
//        failures into test/pages-baseline.json so only what we add counts)
//
// Screens land in design/signoff/canvas-pages/<page>-<mode>.jpg and the numbers
// in design/signoff/canvas-pages/report.json.

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

const test = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const path = require('path');
const { FakeServer } = require('./fake-canvas');
const { launch, SCHOOL_A } = require('./harness');
const { auditSource } = require('./page-audit');

const UPSTREAM = process.env.CANVAS_UPSTREAM || 'http://127.0.0.1:3000';
const PORT = Number(process.env.PREPKIN_PORT) || 8443;
const STUDENT = { login: 'alex@prepkin.test', password: 'PrepkinSandbox!2026' };
const SHOTS = path.join(__dirname, '..', 'design', 'signoff', 'canvas-pages');
const BASELINE_FILE = path.join(__dirname, 'pages-baseline.json');
const BASELINE = !!process.env.BASELINE;
const ONLY = process.env.PAGES ? process.env.PAGES.split(',') : null;
const MODES = (process.env.MODES || 'light,dark').split(',');

/// Every page a student meets, with the element that says it has mounted.
const PAGES = [
  ['dashboard', '/', '.ic-DashboardCard'],
  ['courses', '/courses', '#my_courses_table, .ic-Table'],
  ['course-home', '/courses/4', '#course_home_content, .context_module'],
  ['modules', '/courses/4/modules', '.context_module'],
  ['assignments', '/courses/4/assignments', '.ig-row, #ag-list'],
  ['assignment', '/courses/4/assignments/12', '#assignment_show'],
  ['grades', '/courses/4/grades', '#grades_summary'],
  ['all-grades', '/grades', '#content table'],
  ['calendar', '/calendar', '.fc-view, #calendar-app'],
  ['inbox', '/conversations', '[data-testid="conversation-list-container"], #inbox-conversation-holder, [class*="conversation"]'],
  ['announcements', '/courses/4/announcements', '#content [class*="announcement"], .ic-announcement-row, .ic-item-row'],
  ['discussions', '/courses/4/discussion_topics', '.discussions-v2__wrapper, #content [data-testid], .ic-item-row'],
  ['files', '/courses/4/files', '.ef-directory, .ef-item-row, .ic-Table'],
  ['page', '/courses/4/pages/rotation-the-short-version', '.show-content, #wiki_page_show'],
  ['quizzes', '/courses/4/quizzes', '.ig-row, #assignment-quizzes, .quiz'],
  ['quiz', '/courses/4/quizzes/1', '#quiz_show'],
  ['people', '/courses/4/users', '.roster, .rosterTable, [data-testid="course-people"], .ic-Table'],
  ['syllabus', '/courses/4/assignments/syllabus', '#syllabusContainer, #course_syllabus'],
  ['settings', '/profile/settings', '#content .ic-Form-control, #content form, .profile_table'],
];

const wallet = () => ({
  coins: 480, owned: ['classic', 'deepsea'], wearing: 'classic',
  kin: { species: 'mint', level: 2, skin: '' },
});

let server, h, page;
const report = {};
const baseline = fs.existsSync(BASELINE_FILE) ? JSON.parse(fs.readFileSync(BASELINE_FILE, 'utf8')) : {};
const key = (f) => `${f.path}|${f.text || f.word || f.size || f.prop || ''}`;
/// Our own findings always count; Canvas's own only when the skin-off baseline
/// did not already have them.
const counts = (name, kind, list) => list.filter((f) => f.pk || !(baseline[name]?.[kind] || []).includes(key(f)));

/// Known and left alone, on purpose. Empty since the button carve-out
/// (extension/receipt.test.js TEXT_BUTTON_OK) landed; a row here is a debt
/// with its reason, never a way to make a run green.
const KNOWN = [];
const known = (name, f) => KNOWN.some((k) => k.page.test(name) && k.path.test(f.path));

test.before(async () => {
  fs.mkdirSync(SHOTS, { recursive: true });
  server = await new FakeServer({ upstream: UPSTREAM }).start(PORT);
  h = await launch();
  page = await h.context.newPage();
  await page.setViewportSize({ width: 1280, height: 860 });
  page.setDefaultNavigationTimeout(180_000);
  page.setDefaultTimeout(120_000);
  await page.goto(`${SCHOOL_A}/login/canvas`, { waitUntil: 'domcontentloaded' });
  await page.fill('#pseudonym_session_unique_id', STUDENT.login);
  await page.fill('#pseudonym_session_password', STUDENT.password);
  await page.press('#pseudonym_session_password', 'Enter');
  await page.waitForURL((u) => !u.pathname.startsWith('/login'), { waitUntil: 'domcontentloaded' });
  await h.setStorage({
    onboarded: true, origins: [SCHOOL_A],
    skin: { dark: false, cards: !BASELINE, mascot: !BASELINE, focusMinutes: 25 },
    wallet: wallet(),
  });
  await h.connect(SCHOOL_A);
  try { await h.sw((o) => syncNow(o), SCHOOL_A); } catch {}
});

test.after(async () => {
  fs.writeFileSync(path.join(SHOTS, 'report.json'), JSON.stringify(report, null, 2));
  if (BASELINE) {
    // Merged, so a re-run on a subset (PAGES=…) keeps the rest.
    const out = { ...baseline };
    for (const [name, r] of Object.entries(report)) {
      out[name] = {};
      for (const kind of ['text', 'controls']) out[name][kind] = (r.findings?.[kind] || []).map(key);
    }
    fs.writeFileSync(BASELINE_FILE, JSON.stringify(out, null, 1));
  }
  await h?.close();
  await server?.stop();
});

async function open(url, ready) {
  const t0 = Date.now();
  await page.goto(`${SCHOOL_A}${url}`, { waitUntil: 'domcontentloaded' });
  await page.waitForSelector(ready, { timeout: 60_000, state: 'attached' }).catch(() => {});
  const mount = Date.now() - t0;
  await page.waitForLoadState('networkidle', { timeout: 15_000 }).catch(() => {});
  await page.waitForTimeout(1200);
  return mount;
}

for (const mode of MODES) {
  const dark = mode === 'dark';
  test(`${mode}: paper set`, async () => {
    const { skin } = await h.storage();
    await h.setStorage({ skin: { ...skin, dark } });
  });
  for (const [name, url, ready] of PAGES) {
    if (ONLY && !ONLY.includes(name)) continue;
    test(`${mode}: ${name} reads`, async () => {
      const mount = await open(url, ready);
      const findings = await page.evaluate(auditSource({ dark }));
      await page.screenshot({ path: path.join(SHOTS, `${name}-${mode}.jpg`), type: 'jpeg', quality: 80 });
      const id = `${name}-${mode}`;
      report[id] = { mount, findings };
      if (BASELINE) return;
      const text = counts(id, 'text', findings.text).filter((f) => !known(id, f));
      // A light block on a dark page is always ours: the skin's promise is to
      // paint every surface, so no baseline excuses one.
      const blocks = findings.blocks;
      const controls = counts(id, 'controls', findings.controls).filter((f) => !known(id, f));
      const say = (list, n = 6) => list.slice(0, n).map((f) => `  ${f.path} — "${f.text ?? f.word ?? f.size ?? f.value}" ${f.ratio ?? f.bg ?? ''}`).join('\n');
      assert.equal(text.length, 0, `${id}: ${text.length} text nodes below the contrast floor (of ${findings.counted} read):\n${say(text)}`);
      assert.equal(controls.length, 0, `${id}: ${controls.length} controls whose label does not read:\n${say(controls)}`);
      if (dark) assert.equal(blocks.length, 0, `${id}: ${blocks.length} light blocks on a dark page:\n${say(blocks)}`);
      assert.equal(findings.words.length, 0, `${id}: a word wider than its box breaks mid-word:\n${say(findings.words)}`);
      assert.equal(findings.uppercase.length, 0, `${id}: uppercase tracking labels:\n${say(findings.uppercase)}`);
      assert.equal(findings.red.length, 0, `${id}: red on our own elements:\n${say(findings.red)}`);
    });
  }
}

/// One place per fact: on the dashboard, a course card carries one due line
/// and the rail carries the rest; the count is said once.
test('dashboard: what is due is said once per place', { skip: !!(BASELINE || (ONLY && !ONLY.includes('dashboard'))) }, async () => {
  await open('/', '.ic-DashboardCard');
  await page.waitForSelector('#pk-week', { timeout: 30_000 }).catch(() => {});
  const seen = await page.evaluate(() => {
    const cards = [...document.querySelectorAll('.ic-DashboardCard')];
    const perCard = cards.map((c) => c.querySelectorAll('.pk-card-due .pk-due-row, .pk-card-due li, a.pk-due-row').length);
    const rail = document.querySelectorAll('#pk-week li, #pk-week .pk-row').length;
    const counts = [...document.querySelectorAll('#pk-week, .pk-card-due')].map((e) => e.innerText).join('\n').match(/\b\d+\s*(of|\/)\s*\d+\b/g) || [];
    return { perCard, rail, counts };
  });
  assert.ok(seen.perCard.every((n) => n <= 1), `a card shows more than one due line: ${seen.perCard.join(', ')}`);
  assert.ok(seen.rail <= 5, `the rail lists ${seen.rail} rows; five things is the rail`);
  assert.ok(seen.counts.length <= 1, `a count is said ${seen.counts.length} times: ${seen.counts.join(' · ')}`);
});

/// Canvas's own To Do (with its spinner) is folded from the first paint: boot.js
/// adds the fold class at document_start on a synced dashboard, so the student
/// never sees Canvas's list flash before the rail replaces it.
test('dashboard: Canvas\'s To Do never shows before the rail folds it', { skip: !!(BASELINE || (ONLY && !ONLY.includes('dashboard'))) }, async () => {
  const p = await h.context.newPage();
  await p.setViewportSize({ width: 1280, height: 860 });
  await p.addInitScript(() => {
    window.__pkSeen = [];
    const look = () => {
      const el = document.querySelector('.Sidebar__TodoListContainer, ul.right-side-list.to-do-list');
      if (el && getComputedStyle(el).display !== 'none' && el.getBoundingClientRect().height > 0) window.__pkSeen.push(performance.now());
    };
    setInterval(look, 50);
  });
  await p.goto(`${SCHOOL_A}/`, { waitUntil: 'domcontentloaded' });
  await p.waitForSelector('#pk-week', { timeout: 60_000 });
  await p.waitForTimeout(3000);
  const seen = await p.evaluate(() => window.__pkSeen);
  await p.close();
  assert.equal(seen.length, 0, `Canvas's To Do was on screen ${seen.length} times (first at ${Math.round(seen[0] ?? 0)} ms)`);
});

/// The skin must not slow Canvas's own React pages down. Same page, same
/// session, skin on then off; the cards must mount within 2 s of each other.
test('dashboard: the skin does not delay the cards', { skip: !!(BASELINE || (ONLY && !ONLY.includes('dashboard'))) }, async () => {
  // Three loads each, the best of them: this Mac often carries a load of 300.
  const time = async () => {
    const times = [];
    for (let i = 0; i < 3; i++) times.push(await open('/', '.ic-DashboardCard'));
    return Math.min(...times);
  };
  const on = await time();
  // With the Looks tab open: 26 tiles drawn from tokens must not move the number.
  await h.setStorage({ dashTab: 'looks' });
  const looks = await time();
  await h.setStorage({ dashTab: 'cards' });
  const { skin } = await h.storage();
  await h.setStorage({ skin: { ...skin, cards: false, mascot: false } });
  const off = await time();
  await h.setStorage({ skin });
  report['mount'] = { on, looks, off };
  assert.ok(on <= off + 2000, `cards mounted in ${on} ms with the skin on, ${off} ms with it off`);
  assert.ok(looks <= off + 2000, `cards mounted in ${looks} ms with the Looks tab open, ${off} ms with the skin off`);
});

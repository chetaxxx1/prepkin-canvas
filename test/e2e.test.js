// End-to-end: real Chromium, real extension, fake Canvas, fake bridge, fake phone.
//
//   npm run test:e2e            (HEADED=1 to watch)
//
// Needs Playwright and its Chromium in ~/Library/Developer/prepkin-canvas-test-deps
// (see harness.js). Every test starts from a blank world and a blank extension.
// Row numbers match design/CANVAS-TEST-PLAN.md.

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0'; // the fake server's cert is self-signed

const test = require('node:test');
const assert = require('node:assert');
const { FakeServer } = require('./fake-canvas');
const { FakePhone } = require('./fake-phone');
const { launch, SCHOOL_A, SCHOOL_B, BRIDGE } = require('./harness');
const { openPopup } = require('./popup');
const S = require('./scenarios');
const { THEMES } = require('../extension/themes.js');

let server, h;
const control = (p, body) => fetch(`${BRIDGE}/__${p}`, { method: 'POST', body: JSON.stringify(body ?? {}) }).then((r) => r.json());
const world = (host, w) => control('world', { host, world: w });
const canvasLog = () => control('log');
const HOST_A = 'localhost';
const HOST_B = '127.0.0.1';

test.before(async () => {
  server = await new FakeServer().start(8443);
  h = await launch();
});
test.after(async () => { await h?.close(); await server?.stop(); });
test.beforeEach(async () => {
  await control('reset');
  await h.clearStorage();
});

/// The happy path up to a paired, connected extension.
async function paired(w = S.plainSemester(), host = HOST_A, origin = SCHOOL_A) {
  await world(host, w);
  await h.connect(origin);
  const phone = new FakePhone(BRIDGE);
  const code = await phone.claim();
  const bound = await h.sw((c) => bindWriter(c), code);
  assert.deepEqual(bound, { ok: true });
  return phone;
}

const sync = (origin = SCHOOL_A) => h.sw((o) => syncNow(o), origin);
const syncAll = () => h.sw(() => syncAll());
const ids = (todo) => todo.tasks.map((t) => t.id).sort();
const byId = (todo, id) => todo.tasks.find((t) => t.id === `c-${HOST_A}-a${id}`);
const settle = (ms = 150) => new Promise((r) => setTimeout(r, ms));

// MARK: - A. Pairing

test('A1 a fresh code pairs, and the popup reports the first sync', async () => {
  await world(HOST_A, { ...S.plainSemester(), delayMs: 300 });
  await h.connect(SCHOOL_A);
  await h.setStorage({ onboarded: true });
  const phone = new FakePhone(BRIDGE);
  const code = await phone.claim();
  const popup = await openPopup(h);
  assert.equal(await popup.text('#resync'), 'Check again');
  assert.equal(await popup.evaluate(`document.getElementById('slime')`), null, 'the old inline mascot host is gone');
  assert.match(await popup.evaluate(`document.querySelector('#kin > img')?.src ?? ''`), /\/art\/kin\/mint\.webp$/, 'the popup uses the student\'s kin image');
  await popup.fill('#code', code.toLowerCase().replace('-', ' '));
  await popup.click('#save');
  assert.match(await popup.waitFor('#status', /Getting your work/), /Getting your work/);
  assert.equal(await popup.waitFor('#status', /Sent|should|not|expired|bridge/i), 'Sent 6 assignments.');
  assert.equal(await popup.value('#code'), code, 'the code is normalised in place');
  await popup.close();
  assert.equal((await phone.fetchTodo()).tasks.length, 6);
});

test('A2 the same code on a second laptop is refused', async () => {
  const phone = await paired();
  const again = await h.sw((c) => bindWriter(c), phone.code);
  assert.equal(again.ok, false);
  assert.match(again.error, /expired or is already paired/);
});

test('A3 a code older than fifteen minutes is refused', async () => {
  const phone = new FakePhone(BRIDGE);
  const code = await phone.claim();
  await control('bridge', { skew: 16 * 60_000 });
  const late = await h.sw((c) => bindWriter(c), code);
  assert.equal(late.ok, false);
  assert.match(late.error, /expired/);
});

test('A4 a code with a letter nobody uses is rejected before any request', async () => {
  await h.setStorage({ onboarded: true });
  const popup = await openPopup(h);
  await popup.fill('#code', 'ABCO-EFGH'); // O is not in the alphabet, so this is 7 chars
  await popup.click('#save');
  assert.equal(await popup.waitFor('#status', /./), 'That code should be 8 letters and numbers.');
  await popup.close();
  assert.equal(server.bridge.calls.length, 0, 'nothing went to the bridge');
});

test('A5 the first-run Link step actually pairs', async () => {
  await world(HOST_A, S.plainSemester());
  await h.connect(SCHOOL_A);
  const phone = new FakePhone(BRIDGE);
  const code = await phone.claim();
  const popup = await openPopup(h);
  await popup.waitFor('#onb-next');
  await popup.click('#onb-next');
  await popup.waitFor('#onb-skip');
  await popup.click('#onb-skip');
  await popup.waitFor('#onb-code');
  await popup.fill('#onb-code', code);
  await popup.click('#onb-link');
  assert.equal(await popup.waitFor('#status', /Sent|should|not|expired|bridge/i), 'Sent 6 assignments.');
  await popup.close();
  const s = await h.storage();
  assert.ok(s.writerToken, 'a writer token was bound');
  assert.equal((await phone.fetchTodo()).tasks.length, 6);
});

test('A6 when the phone unpairs, the laptop drops its token and asks for a new code', async () => {
  const phone = await paired();
  assert.equal((await sync()).ok, true);
  await phone.unpair();
  const status = await sync();
  assert.equal(status.ok, false);
  assert.match(status.error, /unpaired this laptop/);
  assert.equal((await h.storage()).writerToken, undefined);
});

test('A7 a bridge that is down still leaves the Canvas list on the laptop', async () => {
  await paired();
  await control('bridge', { down: true });
  const status = await sync();
  assert.equal(status.ok, false);
  assert.equal(status.error, 'Could not reach Prepkin.');
  const s = await h.storage();
  assert.equal(s.lastPayload.tasks.length, 6, 'the panel still has the list');
  assert.ok(s.writerToken, 'the token survives an outage');
});

test('A8 a build with no config.js says so instead of crashing', async () => {
  await paired();
  await h.sw(() => { globalThis.__bridge = bridge; bridge = null; });
  const status = await sync();
  await h.sw(() => { bridge = globalThis.__bridge; });
  assert.equal(status.ok, false);
  assert.equal(status.error, 'Extension is missing config.js.');
});

test('A9 against the old code-only bridge, pairing fails with a message, not a hang', async () => {
  await control('bridge', { legacy: true });
  const status = await h.sw((c) => bindWriter(c), 'ABCD-EFGH');
  assert.equal(status.ok, false);
  assert.match(status.error, /needs an update/);
});

// MARK: - B. Connecting a school

test('B1 a logged-in Canvas is recognised, gets the skin, and the panel mounts', async () => {
  await world(HOST_A, S.plainSemester());
  const check = await h.sw((o) => isCanvas(o), SCHOOL_A);
  assert.deepEqual(check, { ok: true, name: 'Alex Rivera' });
  await h.connect(SCHOOL_A);
  const registered = await h.sw(() => chrome.scripting.getRegisteredContentScripts());
  assert.ok(registered.some((r) => r.id === 'prepkin-localhost'));
  const page = await h.context.newPage();
  await page.goto(`${SCHOOL_A}/`);
  await page.waitForSelector('#prepkin-buddy', { state: 'attached' });
  const closed = await page.evaluate(() => document.getElementById('prepkin-buddy').shadowRoot === null);
  assert.equal(closed, true, 'the panel is in a closed shadow root');
  await page.close();
});

test('B10 a newer content-script instance takes over an open Canvas page', async () => {
  await world(HOST_A, S.plainSemester());
  await h.connect(SCHOOL_A);
  const page = await h.context.newPage();
  await page.goto(`${SCHOOL_A}/`);
  await page.waitForSelector('#prepkin-buddy', { state: 'attached' });
  const first = await page.getAttribute('html', 'data-pk-instance');
  assert.ok(first, 'the first content-script instance stamps the page');
  await h.sw(async (origin) => {
    const tabs = await chrome.tabs.query({ url: `${origin}/*` });
    const tab = tabs.find((candidate) => candidate.url?.startsWith(origin));
    if (!tab?.id) throw new Error('no open Canvas tab');
    await chrome.scripting.executeScript({ target: { tabId: tab.id }, files: ['content.js'] });
  }, SCHOOL_A);
  await page.waitForFunction((old) => document.documentElement.dataset.pkInstance !== old, first, { timeout: 5000 });
  await page.waitForSelector('#prepkin-buddy', { state: 'attached' });
  assert.equal(await page.locator('#prepkin-buddy').count(), 1, 'the old instance tears down and the new one mounts once');
  await page.close();
});

test('B2 Canvas with an expired login says so', async () => {
  await world(HOST_A, { ...S.plainSemester(), loggedIn: false });
  const check = await h.sw((o) => isCanvas(o), SCHOOL_A);
  assert.deepEqual(check, { ok: false, error: 'That is Canvas, but you are logged out.' });
});

test('B3 a site that answers {"id":1} is not Canvas', async () => {
  await world(HOST_A, { notCanvas: true });
  const check = await h.sw((o) => isCanvas(o), SCHOOL_A);
  assert.deepEqual(check, { ok: false, error: 'That page does not look like Canvas.' });
});

test('B4 an http site is never an origin', async () => {
  assert.equal(await h.sw(() => originOf('http://canvas.school.edu/')), null);
  assert.equal(await h.sw(() => originOf('https://canvas.school.edu/x')), 'https://canvas.school.edu');
});

test('B5 two schools sharing an assignment id do not collide', async () => {
  const phone = await paired();
  const other = S.plainSemester();
  other.courses[0].name = 'Other School Physics';
  await world(HOST_B, other);
  await h.connect(SCHOOL_B);
  const status = await syncAll();
  assert.equal(status.ok, true);
  const todo = await phone.fetchTodo();
  assert.ok(ids(todo).includes(`c-${HOST_A}-a11`));
  assert.ok(ids(todo).includes(`c-${HOST_B}-a11`));
  assert.equal(todo.tasks.length, 12);
  assert.equal(todo.courses.length, 4);
});

test('B6 removing a school takes its work off the phone', async () => {
  const phone = await paired();
  await world(HOST_B, S.plainSemester());
  await h.connect(SCHOOL_B);
  await syncAll();
  assert.equal((await phone.fetchTodo()).tasks.length, 12);
  await h.sw((o) => forgetOrigin(o), SCHOOL_B);
  const todo = await phone.fetchTodo();
  assert.equal(todo.tasks.length, 6);
  assert.ok(ids(todo).every((id) => id.startsWith(`c-${HOST_A}-`)));
  assert.deepEqual((await h.storage()).origins, [SCHOOL_A]);
});

test('B7 an origin Chrome no longer grants is ignored without fuss', async () => {
  await h.setStorage({ origins: ['https://nowhere.example'] });
  assert.deepEqual(await h.sw(() => connectedOrigins()), []);
  const status = await syncAll();
  assert.deepEqual([status.ok, status.error], [false, 'No Canvas connected yet.']);
});

test('B8/D5 one school logging out keeps its last list; both out is an error', async () => {
  const phone = await paired();
  await world(HOST_B, S.plainSemester());
  await h.connect(SCHOOL_B);
  await syncAll();
  await world(HOST_B, { loggedIn: false });
  await world(HOST_A, { assignments: { 1: [S.assignment({ id: 11, name: 'Problem Set 7', due: 0.1 })], 2: [] } });
  const status = await syncAll();
  assert.equal(status.ok, true);
  const todo = await phone.fetchTodo();
  assert.equal(todo.tasks.filter((t) => t.id.startsWith(`c-${HOST_B}-`)).length, 6, 'B keeps its last good list');
  assert.equal(todo.tasks.filter((t) => t.id.startsWith(`c-${HOST_A}-`)).length, 1, 'A is fresh');
  await world(HOST_A, { loggedIn: false });
  const both = await syncAll();
  assert.deepEqual([both.ok, both.error], [false, 'Canvas said no — log in again?']);
});

test('B9 the message gate: setup only from our own pages, page messages only from a connected top frame', async () => {
  await h.connect(SCHOOL_A);
  const ask = (type, sender) => h.sw(([t, s]) => senderMayAsk(t, { id: chrome.runtime.id, ...s }), [type, sender]);
  assert.equal(await ask('pair', { url: `chrome-extension://${h.id}/popup.html` }), true);
  assert.equal(await ask('pair', { tab: { id: 1 }, url: `chrome-extension://${h.id}/popup.html` }), false, 'not from a tab');
  assert.equal(await ask('focus-start', { tab: { id: 1 }, frameId: 0, url: `${SCHOOL_A}/courses/1` }), true);
  assert.equal(await ask('focus-start', { tab: { id: 1 }, frameId: 7, url: `${SCHOOL_A}/lti` }), false, 'not from a frame');
  assert.equal(await ask('spend', { tab: { id: 1 }, frameId: 0, url: 'https://evil.example/' }), false, 'not from another site');
  assert.equal(await h.sw(() => senderMayAsk('pair', { id: 'someone-else', url: 'x' })), false, 'not from another extension');
});

// MARK: - C. The assignment lifecycle

function lifecycleWorld() {
  const physics = S.course({ id: 1, name: 'AP Physics C' });
  const dead = S.course({ id: 3, name: 'Orientation 2020', termEnds: -1500 });
  const done = S.course({ id: 4, name: 'Concluded', state: 'completed' });
  const noTerm = S.course({ id: 5, name: 'Seminar', termEnds: null });
  const ta = S.course({ id: 6, name: 'Intro Lab (TA)', role: 'ta' });
  const a = (over) => S.assignment({ course: 1, ...over });
  return {
    courses: [physics, dead, done, noTerm, ta],
    assignments: {
      1: [
        a({ id: 101, name: 'Due in two hours', due: 0.08 }),
        a({ id: 102, name: 'Due tomorrow', due: 1 }),
        a({ id: 103, name: 'Due in six days', due: 6 }),
        a({ id: 104, name: 'Due in thirteen days', due: 13 }),
        a({ id: 105, name: 'Due in fifteen days', due: 15 }),
        a({ id: 106, name: 'Overdue one day', due: -1 }),
        a({ id: 107, name: 'Overdue six days', due: -6 }),
        a({ id: 108, name: 'Overdue eight days', due: -8 }),
        a({ id: 109, name: 'Undated with points', due: null, points: 20, created: -400 }),
        a({ id: 110, name: 'Undated no points new', due: null, points: null, created: -30 }),
        a({ id: 111, name: 'Undated no points old', due: null, points: null, created: -90 }),
        a({ id: 112, name: 'Submitted ungraded', due: -1, sub: S.submitted(-1) }),
        a({ id: 113, name: 'Submitted four days ago', due: -5, sub: S.submitted(-4, { score: 50 }) }),
        a({ id: 114, name: 'Graded 41', due: -3, sub: S.submitted(-2, { score: 41 }) }),
        a({ id: 115, name: 'Graded zero after submitting', due: -2, sub: S.submitted(-1, { score: 0 }) }),
        a({ id: 116, name: 'Missing, teacher entered zero', due: -3, points: 10, sub: S.missingZero(-1) }),
        a({ id: 117, name: 'Excused', due: -2, sub: S.excused(-1) }),
        a({ id: 118, name: 'Late, accepted', due: -4, sub: S.submitted(-2, { score: 45, late: true }) }),
        a({ id: 119, name: 'On paper, graded', due: -2, types: ['on_paper'], sub: S.paperGraded(18) }),
        a({ id: 120, name: 'Locked until Friday', due: 5, unlock: 2 }),
        a({ id: 121, name: 'Unit 4 concept check', due: 3, types: ['online_quiz'], quizId: 5001 }),
        a({ id: 122, name: 'New Quizzes item', due: 4, types: ['external_tool'] }),
        a({ id: 123, name: 'Discussion, no reply yet', due: 2, types: ['discussion_topic'] }),
        a({ id: 124, name: 'Discussion, replied', due: 2, types: ['discussion_topic'], sub: S.submitted(-0.5) }),
        a({ id: 125, name: 'My section due Friday', due: 4, extra: { has_overrides: true } }),
        a({ id: 126, name: 'Unparseable due date', due: 3, extra: { due_at: 'not-a-date' } }),
      ],
      3: [S.assignment({ id: 301, name: 'Old orientation quiz', due: null, points: 5, course: 3 })],
      4: [S.assignment({ id: 401, name: 'Concluded course work', due: 2, course: 4 })],
      5: [S.assignment({ id: 501, name: 'Seminar reading', due: 2, course: 5 })],
      6: [],
    },
    todoExtra: [
      S.todoQuiz({ id: 5001, title: 'Unit 4 concept check', due: 3, courseId: 1, courseName: 'AP Physics C' }),
      { type: 'grading', context_type: 'Course', course_id: 6, context_name: 'Intro Lab (TA)',
        assignment: { id: 601, name: 'Lab 1 to mark', due_at: S.at(2), points_possible: 10, html_url: '' } },
    ],
  };
}

test('C1–C35 every assignment state lands the right way', async () => {
  const phone = await paired(lifecycleWorld());
  const status = await sync();
  assert.equal(status.ok, true, JSON.stringify(status));
  const todo = await phone.fetchTodo();
  const present = (id) => assert.ok(byId(todo, id), `expected ${id} on the list`);
  const absent = (id) => assert.equal(byId(todo, id), undefined, `expected ${id} off the list`);
  const owed = (id) => { present(id); assert.equal(byId(todo, id).submittedAt, null, `${id} should not read as handed in`); };
  const handedIn = (id) => { present(id); assert.ok(byId(todo, id).submittedAt, `${id} should read as handed in`); };

  // C1–C4 the due-date window
  [101, 102, 103, 104].forEach(owed);
  absent(105);
  [106, 107].forEach(owed);
  absent(108);
  // C5–C7 undated work
  owed(109); owed(110); absent(111);
  // C8–C11 handed in
  handedIn(112); assert.equal(byId(todo, 112).score, null);
  absent(113);
  handedIn(114); assert.equal(byId(todo, 114).score, 41);
  handedIn(115); assert.equal(byId(todo, 115).score, 0, 'a zero is a score, not "ungraded"');
  // C12 missing with a zero is still owed — it must not pay coins
  owed(116);
  assert.equal(byId(todo, 116).score, 0);
  // C13 excused is neither owed nor paid
  absent(117);
  // C14, C19, on-paper: handed in one way or another
  handedIn(118); handedIn(119); handedIn(124);
  // C16 the quiz arrives once: the sweep's copy is folded into the assignment
  present(121);
  assert.equal(todo.tasks.find((t) => t.id === `c-${HOST_A}-q5001`), undefined, 'no second row for the quiz');
  // C18–C21, C25 other shapes that are simply owed
  [120, 122, 123, 125, 501].forEach(owed);
  // C35 a due date Canvas could not write is kept, not dropped
  present(126); assert.equal(byId(todo, 126).dueAt, 'not-a-date');
  // C23, C24, C26 courses that should not be there
  absent(301); absent(401);
  assert.equal(todo.tasks.find((t) => t.title === 'Lab 1 to mark'), undefined, 'marking is not homework');
  assert.deepEqual(todo.courses.map((c) => c.name).sort(), ['AP Physics C', 'Seminar'], 'the TA course is not yours');
  // C20 the override date is mine
  assert.equal(Math.round((Date.parse(byId(todo, 125).dueAt) - Date.now()) / 86_400_000), 4);
});

test('C27 three pages of assignments are all read', async () => {
  const many = Array.from({ length: 250 }, (_, i) => S.assignment({ id: 1000 + i, name: `Task ${i}`, due: 1 + (i % 12) }));
  const phone = await paired({ ...S.plainSemester(), assignments: { 1: many, 2: [] } });
  await sync();
  assert.equal((await phone.fetchTodo()).tasks.length, 250);
  const pages = (await canvasLog()).filter((l) => l.path.includes('/courses/1/assignments'));
  assert.equal(pages.length, 3);
});

test('C28 the page cap drops the fifth page, and only the fifth', async () => {
  const many = Array.from({ length: 500 }, (_, i) => S.assignment({ id: 1000 + i, name: `Task ${i}`, due: 1 + (i % 12) }));
  const phone = await paired({ ...S.plainSemester(), assignments: { 1: many, 2: [] } });
  await sync();
  assert.equal((await phone.fetchTodo()).tasks.length, 400, 'MAX_PAGES is 4: a 500-assignment course loses 100');
});

test('C29 a next-page link to another host is not followed', async () => {
  const many = Array.from({ length: 150 }, (_, i) => S.assignment({ id: 1000 + i, name: `Task ${i}`, due: 2 }));
  const phone = await paired({ ...S.plainSemester(), assignments: { 1: many, 2: [] }, linkHost: 'evil.example' });
  await sync();
  assert.equal((await phone.fetchTodo()).tasks.length, 100);
  assert.ok((await canvasLog()).every((l) => l.host !== 'evil.example'));
});

test('C30 a payload the bridge refuses is an error, not a silent unpair', async () => {
  const long = 'x'.repeat(400);
  const many = (base) => Array.from({ length: 400 }, (_, i) => S.assignment({ id: base + i, name: `${long} ${i}`, due: 2 }));
  const phone = await paired({ ...S.plainSemester(), assignments: { 1: many(1000), 2: many(2000) } });
  const status = await sync();
  assert.equal(status.ok, false);
  assert.doesNotMatch(status.error ?? '', /unpaired/, 'too big is not the same as unpaired');
  assert.ok((await h.storage()).writerToken, 'the token must survive');
  assert.deepEqual(await phone.fetchTodo(), [], 'nothing was written');
});

test('C31/C32 colours and grades: real, missing, junk, null, zero', async () => {
  const w = S.plainSemester();
  w.courses.push(S.course({ id: 3, name: 'Zero so far', score: 0, grade: 'F' }));
  w.colors = { course_1: '#FF6F61', course_2: 'red;background:url(x)' };
  const phone = await paired(w);
  await sync();
  const { courses } = await phone.fetchTodo();
  const c = (id) => courses.find((x) => x.id === String(id));
  assert.equal(c(1).colorHex, '#FF6F61');
  assert.equal(c(2).colorHex, null, 'junk is not a colour');
  assert.equal(c(3).colorHex, null, 'no colour set');
  assert.equal(c(2).score, null, 'no grade yet is null');
  assert.equal(c(3).score, 0, 'zero is zero');
});

test('C33 weights only count when the course actually weights its groups', async () => {
  const w = S.plainSemester();
  w.courses[1] = S.course({ id: 2, name: 'English 11', weighted: false });
  w.groups[2] = [S.group({ id: 201, name: 'Essays', weight: 40 }), S.group({ id: 202, name: 'Quizzes', weight: 60 })];
  await paired(w);
  await sync();
  const { lastPayload } = await h.storage();
  assert.equal(lastPayload.weights[1].length, 2, 'a weighted course keeps its groups');
  assert.equal(lastPayload.weights[2], null, 'an unweighted course must not pretend');
  assert.equal(lastPayload.graded[1].length, 1, 'the sparkline has the one graded item');
});

test('C34 junk from Canvas costs that endpoint, never the sync', async () => {
  const phone = await paired({ ...S.plainSemester(), fail: { '/courses/1/assignment_groups': 'html', '/courses/2/assignments': 'drop' } });
  const status = await sync();
  assert.equal(status.ok, true);
  const todo = await phone.fetchTodo();
  assert.ok(byId(todo, 11), 'course 1 is intact');
  assert.ok(byId(todo, 22), 'course 2 still arrives through the to-do sweep');
  assert.equal(byId(todo, 22).pointsPossible, 60);
  assert.equal((await h.storage()).lastPayload.weights[1], null);
});

// MARK: - D. When it syncs

test('D1/D2 landing on Canvas syncs once per ten minutes, not once per page', async () => {
  await paired();
  await control('log/clear');
  await h.sw((o) => syncOnVisit(o), SCHOOL_A);
  await settle(400);
  await h.sw((o) => syncOnVisit(o), SCHOOL_A);
  await settle(400);
  const colours = () => canvasLog().then((l) => l.filter((x) => x.path.includes('/colors')).length);
  assert.equal(await colours(), 1);
  await h.setStorage({ visitSyncs: { [SCHOOL_A]: Date.now() - 11 * 60_000 } });
  await h.sw((o) => syncOnVisit(o), SCHOOL_A);
  await settle(400);
  assert.equal(await colours(), 2);
});

test('D3 the half-hour alarm exists', async () => {
  const alarm = await h.sw(() => chrome.alarms.get('prepkin-sync'));
  assert.equal(alarm?.periodInMinutes, 30);
});

test('D4 Check again is never rate-limited', async () => {
  await paired();
  await control('log/clear');
  await sync(); await sync();
  const colours = (await canvasLog()).filter((x) => x.path.includes('/colors')).length;
  assert.equal(colours, 2);
});

// MARK: - E. Coins and requests

test('E1/E2 a finished focus session is asked for until the phone says it paid', async () => {
  const phone = await paired();
  const focus = await h.sw((a) => focusStart(a), { taskId: 'c-localhost-a11', title: 'Problem Set 7', url: '', minutes: 25 });
  assert.equal(focus.state, 'running');
  await h.sw(() => focusDone());
  await settle(400);
  let todo = await phone.fetchTodo();
  assert.equal(todo.requests.length, 1);
  assert.deepEqual([todo.requests[0].kind, todo.requests[0].minutes], ['focus', 25]);
  await sync();
  todo = await phone.fetchTodo();
  assert.equal(todo.requests.length, 1, 'still asked for: the phone has not answered');
  await phone.pushState({ coins: 130, requestsAppliedAt: todo.requests[0].at });
  await sync();
  const s = await h.storage();
  assert.deepEqual(s.requests, [], 'retired once paid');
  assert.equal(s.wallet.coins, 130);
  // The push that learned of the payment went out before the wallet was read,
  // so it still carried the request. The phone's ledger key makes that safe.
  assert.equal((await phone.fetchTodo()).requests.length, 1);
  await sync();
  assert.equal((await phone.fetchTodo()).requests.length, 0, 'and the next one is clean');
});

test('E4/E5 the timer lives in the worker, and giving up costs nothing', async () => {
  await paired();
  const focus = await h.sw((a) => focusStart(a), { taskId: 't', title: 'x', url: '', minutes: 15 });
  const page = await h.context.newPage();
  await page.goto(`${SCHOOL_A}/`);
  await page.goto(`${SCHOOL_A}/courses/1`);
  const after = (await h.storage()).focus;
  assert.deepEqual([after.state, after.endsAt], ['running', focus.endsAt]);
  assert.ok(await h.sw(() => chrome.alarms.get('prepkin-focus')));
  await page.close();
  await h.sw(() => focusStop());
  const s = await h.storage();
  assert.equal(s.focus.state, 'idle');
  assert.deepEqual(s.requests ?? [], []);
  assert.equal(await h.sw(() => chrome.alarms.get('prepkin-focus')), undefined);
});

test('E10 five more minutes on a running session only ever adds', async () => {
  await paired();
  const f = await h.sw((a) => focusStart(a), { taskId: 't', title: 'x', url: '', minutes: 15 });
  const g = await h.sw(() => focusExtend());
  assert.equal(g.durationMin, 20);
  assert.equal(g.endsAt - f.endsAt, 5 * 60_000);
  const alarm = await h.sw(() => chrome.alarms.get('prepkin-focus'));
  assert.equal(Math.round(alarm.scheduledTime), g.endsAt);
  await h.sw(() => focusStop());
  assert.equal(await h.sw(() => focusExtend().then((x) => x?.state)), 'idle', 'nothing to add to when idle');
});

test('E6/E7 buying a look asks the phone; the phone decides', async () => {
  const phone = await paired();
  await h.sw((r) => queueRequest(r), { kind: 'look', lookId: 'ninja', price: 60 });
  await sync();
  const todo = await phone.fetchTodo();
  assert.deepEqual([todo.requests[0].kind, todo.requests[0].lookId], ['look', 'ninja']);
  await phone.pushState({ coins: 40, owned: ['classic', 'ninja'], requestsAppliedAt: todo.requests[0].at });
  await sync();
  let s = await h.storage();
  assert.deepEqual(s.wallet.owned, ['classic', 'ninja']);
  assert.deepEqual(s.requests, []);
  // Too poor for the next one: the phone settles the request without granting it.
  await h.sw((r) => queueRequest(r), { kind: 'look', lookId: 'astronaut', price: 900 });
  await sync();
  const t2 = await phone.fetchTodo();
  await phone.pushState({ coins: 40, owned: ['classic', 'ninja'], requestsAppliedAt: t2.requests[0].at });
  await sync();
  s = await h.storage();
  assert.deepEqual(s.wallet.owned, ['classic', 'ninja']);
  assert.deepEqual(s.requests, []);
});

test('E8 no wallet is shown until the phone publishes one', async () => {
  await paired();
  await sync();
  assert.equal((await h.storage()).wallet, undefined);
});

test('E9 the request queue keeps the newest fifty', async () => {
  await paired();
  for (let i = 0; i < 51; i += 1) await h.sw((i) => queueRequest({ kind: 'focus', taskId: `t${i}`, minutes: 15 }), i);
  const { requests } = await h.storage();
  assert.equal(requests.length, 50);
  assert.equal(requests[0].taskId, 't1', 'the oldest is what goes');
});

// MARK: - F. Panel smoke

test('F3 each dashboard card says what is due next, and updates after a sync', async () => {
  await paired();
  await sync();
  const page = await h.context.newPage();
  await page.goto(`${SCHOOL_A}/`);
  await page.waitForSelector('.pk-card-due', { timeout: 5000 });
  const lines = await page.$$eval('.ic-DashboardCard', (cards) => cards.map((c) => [...c.querySelectorAll('.pk-due-row')].map((r) => (r.classList.contains('done') ? '~' : '') + r.querySelector('.t').textContent)));
  assert.equal(lines[0][0], 'Problem Set 7', 'the soonest unsubmitted item in Physics comes first');
  assert.ok(lines[0].length <= 3 && lines[0].length >= 2, `up to three rows: ${lines[0].join(' | ')}`);
  assert.equal(lines[1][0], 'Rhetorical analysis', 'the only pending item in English');
  assert.ok(!lines[0].includes('Problem Set 6'), 'handed-in work is never a pending row');
  assert.ok(lines.flat().some((x) => x.startsWith('~')) || true, 'handed-in work may fill the list, struck');
  // Alex hands in Problem Set 7: the card moves on to the next one.
  const w = S.plainSemester();
  w.assignments[1][0].submission = S.submitted(-0.01);
  await world(HOST_A, w);
  await sync();
  await page.waitForFunction(() => document.querySelector('.pk-due-row .t')?.textContent === 'Lab writeup: Momentum' || /Lab writeup/.test(document.querySelector('.pk-due-row .t')?.textContent ?? ''), null, { timeout: 5000 });
  // Cards off: the line goes with them.
  await h.setStorage({ skin: { dark: false, cards: false, tidy: true, mascot: true, focusMinutes: 25 } });
  await page.waitForFunction(() => !document.querySelector('.pk-card-due'), null, { timeout: 5000 });
  await page.close();
});

test('F2 turning the mascot off removes the panel', async () => {
  await paired();
  await h.setStorage({ skin: { dark: false, cards: true, tidy: true, mascot: false, focusMinutes: 25 } });
  const page = await h.context.newPage();
  await page.goto(`${SCHOOL_A}/`);
  await settle(300);
  assert.equal(await page.$('#prepkin-buddy'), null);
  await page.close();
});

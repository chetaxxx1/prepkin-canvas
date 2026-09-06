// Stress and failure-mode tests for the sync path: slow schools, dead schools,
// throttling, races, volume. Same harness as e2e.test.js.
//
//   node --test test/stress.test.js

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

const test = require('node:test');
const assert = require('node:assert');
const { FakeServer } = require('./fake-canvas');
const { FakePhone } = require('./fake-phone');
const { launch, SCHOOL_A, SCHOOL_B, BRIDGE } = require('./harness');
const S = require('./scenarios');

let server, h;
const control = (p, body) => fetch(`${BRIDGE}/__${p}`, { method: 'POST', body: JSON.stringify(body ?? {}) }).then((r) => r.json());
const world = (host, w) => control('world', { host, world: w });
const HOST_A = 'localhost';
const HOST_B = '127.0.0.1';

test.before(async () => { server = await new FakeServer().start(8443); h = await launch(); });
test.after(async () => { await h?.close(); await server?.stop(); });
test.beforeEach(async () => { await control('reset'); await h.clearStorage(); });

async function paired(w = S.plainSemester(), host = HOST_A, origin = SCHOOL_A) {
  await world(host, w);
  await h.connect(origin);
  const phone = new FakePhone(BRIDGE);
  const code = await phone.claim();
  assert.deepEqual(await h.sw((c) => bindWriter(c), code), { ok: true });
  return phone;
}
const sync = (origin = SCHOOL_A) => h.sw((o) => syncNow(o), origin);
const syncAll = () => h.sw(() => syncAll());
const byId = (todo, id, host = HOST_A) => todo.tasks.find((t) => t.id === `c-${host}-a${id}`);
const timed = async (fn) => { const t0 = Date.now(); const r = await fn(); return [r, Date.now() - t0]; };

function bigSemester(courses, perCourse) {
  const w = { courses: [], colors: {}, assignments: {}, groups: {} };
  for (let c = 1; c <= courses; c += 1) {
    w.courses.push(S.course({ id: c, name: `Course ${c}` }));
    w.assignments[c] = Array.from({ length: perCourse }, (_, i) =>
      S.assignment({ id: c * 1000 + i, name: `C${c} task ${i}`, due: 1 + (i % 13), course: c }));
    w.groups[c] = [S.group({ id: c * 10, name: 'All', weight: 100 })];
  }
  return w;
}

// MARK: - Slow and dead schools

test('X1 a slow school still syncs, in parallel not in series', { timeout: 90_000 }, async () => {
  const phone = await paired({ ...bigSemester(8, 20), delayMs: 700 });
  const [status, ms] = await timed(sync);
  assert.equal(status.ok, true);
  assert.equal((await phone.fetchTodo()).tasks.length, 160);
  // 8 courses x (assignments + groups) + 3 = 19 calls at 700 ms; serial would be ~13 s.
  assert.ok(ms < 6000, `took ${ms} ms`);
});

test('X2 a school that never answers cannot hang the other school forever', { timeout: 90_000 }, async () => {
  const phone = await paired();
  await world(HOST_B, { ...S.plainSemester(), fail: { '/api/v1/courses?': 'hang' } });
  await h.connect(SCHOOL_B);
  const [status, ms] = await timed(syncAll);
  assert.ok(ms < 40_000, `syncAll took ${ms} ms — a dead school must time out`);
  assert.equal(status.ok, true, 'the live school still gets through');
  assert.equal((await phone.fetchTodo()).tasks.filter((t) => t.id.startsWith(`c-${HOST_A}-`)).length, 6);
});

test('X3 a course the school throttles keeps its last good list instead of vanishing', { timeout: 90_000 }, async () => {
  const phone = await paired();
  await sync();
  assert.ok(byId(await phone.fetchTodo(), 11));
  await world(HOST_A, { fail: { '/courses/1/assignments': { status: 429, body: { errors: [{ message: 'Rate Limit Exceeded' }] } }, '/users/self/todo': { status: 429, body: {} } } });
  const status = await sync();
  assert.equal(status.ok, true);
  const todo = await phone.fetchTodo();
  assert.ok(byId(todo, 11), 'course 1 work must not disappear from the phone over one 429');
  assert.ok(byId(todo, 22), 'course 2 is fresh');
});

// MARK: - Races

test('X4 requests queued while a sync runs are never lost', { timeout: 90_000 }, async () => {
  const phone = await paired({ ...S.plainSemester(), delayMs: 300 });
  const runs = [
    h.sw(() => syncAll()),
    h.sw((o) => syncNow(o), SCHOOL_A),
    ...Array.from({ length: 6 }, (_, i) => h.sw((i) => queueRequest({ kind: 'focus', taskId: `race${i}`, minutes: 15 }), i)),
    h.sw((a) => focusStart(a).then(() => focusDone()), { taskId: 'race-focus', title: 'x', url: '', minutes: 25 }),
  ];
  await Promise.all(runs);
  await new Promise((r) => setTimeout(r, 800));
  const { requests } = await h.storage();
  const ids = requests.map((r) => r.taskId).sort();
  assert.deepEqual(ids, ['race-focus', 'race0', 'race1', 'race2', 'race3', 'race4', 'race5'], 'every request survives the race');
  await sync();
  assert.equal((await phone.fetchTodo()).requests.length, 7);
});

test('X5 the phone paying while a new request is being queued loses neither', { timeout: 90_000 }, async () => {
  const phone = await paired();
  await h.sw((i) => queueRequest({ kind: 'focus', taskId: 'old', minutes: 15 }));
  await sync();
  const paidAt = (await phone.fetchTodo()).requests[0].at;
  await phone.pushState({ coins: 30, requestsAppliedAt: paidAt });
  await new Promise((r) => setTimeout(r, 20)); // a newer timestamp
  await Promise.all([
    h.sw((o) => syncNow(o), SCHOOL_A),                       // pulls the wallet, retires 'old'
    h.sw(() => queueRequest({ kind: 'look', lookId: 'ninja', price: 60 })),
  ]);
  const { requests } = await h.storage();
  assert.deepEqual(requests.map((r) => r.kind), ['look'], 'old retired, new kept');
});

test('X6 fifty syncs in a row leave storage the same size', { timeout: 90_000 }, async () => {
  await paired();
  await sync();
  const before = JSON.stringify(await h.storage()).length;
  for (let i = 0; i < 50; i += 1) await sync();
  const after = JSON.stringify(await h.storage()).length;
  assert.ok(Math.abs(after - before) < 200, `storage grew from ${before} to ${after}`);
});

// MARK: - Volume

test('X7 a heavy but real semester fits and syncs fast', { timeout: 90_000 }, async () => {
  // 8 courses, 60 assignments each, of which 13 days' worth are in the window.
  const w = bigSemester(8, 60);
  const phone = await paired(w);
  const [status, ms] = await timed(sync);
  assert.equal(status.ok, true, JSON.stringify(status));
  const todo = await phone.fetchTodo();
  assert.equal(todo.tasks.length, 480);
  assert.ok(ms < 8000, `took ${ms} ms`);
  const { lastPayload } = await h.storage();
  assert.ok(Object.keys(lastPayload.graded).length === 8);
});

test('X8 the badge count matches what the phone got', { timeout: 90_000 }, async () => {
  const phone = await paired();
  await sync();
  const badge = await h.sw(() => chrome.action.getBadgeText({}));
  assert.equal(Number(badge), (await phone.fetchTodo()).tasks.length);
});

// Session C (2026-09-19): the course home, the assignment, the quiz and the
// wiki page on the fake Canvas (test/fake-canvas.js `pageC`).
//
//   PREPKIN_PORT=8512 node --test test/c-pages.test.js

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

const test = require('node:test');
const assert = require('node:assert');
const { FakeServer } = require('./fake-canvas');
const { launch, PORT, SCHOOL_A, BRIDGE } = require('./harness');
const S = require('./scenarios');

let server, h;
const control = (p, body) => fetch(`${BRIDGE}/__${p}`, { method: 'POST', body: JSON.stringify(body ?? {}) }).then((r) => r.json());
const SKIN = (over = {}) => ({ dark: false, cards: true, mascot: true, focusMinutes: 25, ...over });

test.before(async () => {
  server = await new FakeServer().start(PORT);
  h = await launch();
});
test.after(async () => { await h?.close(); await server?.stop(); });
test.beforeEach(async () => {
  await control('reset');
  await control('world', { host: 'localhost', world: S.plainSemester() });
  await h.clearStorage();
  await h.setStorage({ onboarded: true, skin: SKIN() });
  await h.connect(SCHOOL_A);
});

const open = async (path) => {
  const page = await h.context.newPage();
  await page.setViewportSize({ width: 1280, height: 860 });
  await page.goto(`${SCHOOL_A}${path}`, { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(500);
  return page;
};
const style = (page, sel, prop) => page.evaluate(([s, p]) => { const el = document.querySelector(s); return el ? getComputedStyle(el)[p] : null; }, [sel, prop]);
const box = (page, sel) => page.evaluate((s) => { const r = document.querySelector(s)?.getBoundingClientRect(); return r ? { x: r.x, y: r.y, w: r.width, h: r.height, cy: r.y + r.height / 2 } : null; }, sel);
const shows = (page, sel) => page.evaluate((s) => [...document.querySelectorAll(s)].filter((e) => e.getClientRects().length > 0).length, sel);
const rgb = (hex) => { const n = parseInt(hex.slice(1), 16); return `rgb(${(n >> 16) & 255}, ${(n >> 8) & 255}, ${n & 255})`; };
const CLEAR = 'rgba(0, 0, 0, 0)';
const LINK = rgb('#2F6BAA');

// MARK: - Course home

test('C1 course home: a module head once, Collapse All on the title line as words, the three sidebar links as quiet lines', async () => {
  await h.sw((o) => syncNow(o), SCHOOL_A);
  const page = await open('/courses/1');
  // Real Canvas gives a module both classes; the assignment-group rules must not reach it.
  assert.equal(await shows(page, '.context_module .expand_module_link'), 0, 'the hidden expand title stays hidden');
  assert.equal(await shows(page, '.context_module .collapse_module_link'), 2, 'one title a module');
  assert.equal(await page.$('.context_module .ig-header-title[data-pk-count]'), null, 'no count chip on a module');
  assert.ok(await shows(page, '.context_module.started .completion_status .in_progress_icon'), 'the header mark shows');
  // Collapse All: words only, on the title's own line.
  const title = await box(page, '#content > h1');
  const all = await box(page, '#expand_collapse_all');
  assert.ok(title && all && Math.abs(all.cy - title.cy) < 12, `Collapse All sits on the title line: title ${JSON.stringify(title)} button ${JSON.stringify(all)}`);
  assert.equal(await style(page, '#expand_collapse_all', 'backgroundColor'), CLEAR, 'no ground');
  assert.equal(await style(page, '#expand_collapse_all', 'color'), LINK, 'the link ink');
  // The sidebar's three wide buttons: text, no glyph, under our rows, above Recent Feedback.
  await page.waitForSelector('#right-side > #pk-course-next', { timeout: 5000 });
  for (const sel of ['#view_course_stream_btn', '#view_course_notifications_btn']) {
    assert.equal(await style(page, sel, 'backgroundColor'), CLEAR, `${sel} has no ground`);
    assert.equal(await style(page, sel, 'borderTopColor'), CLEAR, `${sel} has no edge`);
    assert.equal(await style(page, sel, 'color'), LINK, `${sel} is in the link ink`);
    assert.equal(await style(page, sel, 'fontSize'), '13px');
    assert.equal(await shows(page, `${sel} i`), 0, `${sel} lost its glyph`);
  }
  const next = await box(page, '#pk-course-next'), stream = await box(page, '#view_course_stream_btn'), feedback = await box(page, '.recent_feedback h2');
  assert.ok(stream.y > next.y + next.h && feedback.y > stream.y, 'the links sit between our rows and Recent Feedback');
  assert.equal(await style(page, '.Sidebar__TodoListContainer', 'display'), 'none', "Canvas's To Do folds under our rows");
  // Put back buttons: Canvas's own wide buttons, glyphs and all.
  await h.setStorage({ putBack: { buttons: true } }); await page.waitForTimeout(400);
  assert.equal(await style(page, '#view_course_stream_btn', 'backgroundColor'), 'rgb(245, 245, 245)', 'Put back returns the ground');
  assert.equal(await shows(page, '#view_course_stream_btn i'), 1, 'and the glyph');
  await h.setStorage({ putBack: {} });
  await page.close();
});

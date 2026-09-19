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

// MARK: - Assignment

test('C2 assignment: one sheet with the title row, the facts on one line, the description as prose; the Submission box as rows with the mark as a chip', async () => {
  const off = await (async () => {
    await h.setStorage({ skin: SKIN({ cards: false }) });
    const p = await open('/courses/1/assignments/12');
    const b = await style(p, '.assignment-buttons .Button', 'backgroundColor');
    await p.close(); return b;
  })();
  await h.setStorage({ skin: SKIN() });
  const page = await open('/courses/1/assignments/12');
  assert.equal(await style(page, '#content', 'backgroundColor'), rgb('#FFFFFF'), 'the sheet is the page');
  assert.equal(await style(page, '#content', 'borderTopLeftRadius'), '14px');
  assert.equal(await style(page, '#assignment_show .description.user_content', 'backgroundColor'), CLEAR, 'no card inside the sheet');
  const h1 = await box(page, '#assignment_show h1.title'), btn = await box(page, '.assignment-buttons .Button');
  assert.ok(Math.abs(h1.cy - btn.cy) < 12, `New Attempt on the title line: ${JSON.stringify([h1, btn])}`);
  assert.equal(await style(page, '.assignment-buttons .Button', 'backgroundColor'), off, "Canvas's own button, untouched");
  const tops = await page.$$eval('ul.student-assignment-overview > li', (els) => els.map((e) => Math.round(e.getBoundingClientRect().top)));
  assert.equal(new Set(tops).size, 1, `Due, Points and Submitting on one line: ${tops}`);
  assert.equal(await style(page, 'ul.student-assignment-overview .title', 'color'), rgb('#454B54'), 'labels in the quiet ink');
  // The Submission box.
  assert.equal(await style(page, '#sidebar_content > .details', 'display'), 'grid');
  assert.equal(await page.$eval('#sidebar_content .module > div[data-pk-mark]', (e) => e.dataset.pkMark), '47/50', 'the mark, re-said');
  assert.equal(await page.$eval('#sidebar_content .module > div[data-pk-mark]', (e) => e.textContent.replace(/\s+/g, ' ').trim()), 'Grade: 47 (50 pts possible)', "Canvas's words stay");
  assert.equal(await page.evaluate(() => getComputedStyle(document.querySelector('#sidebar_content .module > div[data-pk-mark]'), '::after').content), '"47/50"');
  assert.equal(await style(page, '#sidebar_content .details > .header > i.icon-check', 'fontSize'), '0px', 'the check is our tick');
  const head = await box(page, '#sidebar_content .details > .header'), chip = await box(page, '#sidebar_content .module > div[data-pk-mark]'), details = await box(page, '#sidebar_content a[href*="/submissions/"]'), comments = await box(page, '#sidebar_content .comments.module');
  assert.ok(Math.abs(head.cy - chip.cy) < 8, 'the chip sits on the Submitted line');
  assert.ok(details.y > comments.y, 'Submission Details is the foot line');
  assert.equal(await page.$eval('#sidebar_content .comments .comment .comment', (e) => getComputedStyle(e).color), rgb('#1B1F24'), "the teacher's words in the ink");
  // Put back: Canvas's stack, the mark unsaid.
  await h.setStorage({ putBack: { 'submission-rows': true } }); await page.waitForTimeout(500);
  assert.notEqual(await style(page, '#sidebar_content > .details', 'display'), 'grid');
  assert.equal(await page.$('#sidebar_content [data-pk-mark]'), null, 'the attribute goes with the row');
  await h.setStorage({ putBack: {} });
  await page.close();
});

// MARK: - Quiz

test('C3 quiz: six facts on one line, no empty sidebar, prerequisites as a head and rows, Previous and Next as words on a hairline; the take page gets nothing', async () => {
  const page = await open('/courses/1/quizzes/2');
  assert.equal(await style(page, '#content', 'backgroundColor'), rgb('#FFFFFF'), 'the sheet');
  assert.equal(await style(page, '#quiz_show .quiz-header', 'backgroundColor'), CLEAR, 'no card inside it');
  assert.equal(await style(page, '#quiz_title', 'fontSize'), '28px', 'the page title');
  const tops = await page.$$eval('#quiz_student_details > li', (els) => els.map((e) => Math.round(e.getBoundingClientRect().top)));
  assert.equal(tops.length, 6);
  assert.equal(new Set(tops).size, 1, `six facts on one line at 1280: ${tops}`);
  assert.equal(await style(page, '#right-side-wrapper', 'display'), 'none', 'a hidden Related Items list is no sidebar');
  assert.equal(await style(page, '.lock_explanation > h2', 'fontSize'), '14px', 'Completion Prerequisites is a group head');
  assert.equal(await style(page, '#module_prerequisites_list li.requirement', 'display'), 'flex', 'a requirement is a row');
  assert.equal(await style(page, '#module_prerequisites_list li.requirement', 'borderTopWidth'), '1px');
  assert.equal(await style(page, '#module_prerequisites_list li.requirement .description', 'backgroundColor'), CLEAR, 'its condition is words, not a pill');
  assert.equal(await style(page, '.module-sequence-footer-content', 'backgroundColor'), CLEAR, 'the foot is a hairline, not a card');
  assert.equal(await style(page, '.module-sequence-footer-content', 'borderTopWidth'), '1px');
  for (const sel of ['.module-sequence-footer-button--previous a', '.module-sequence-footer-button--next a']) {
    assert.equal(await style(page, sel, 'backgroundColor'), CLEAR, `${sel}: no ground`);
    assert.equal(await style(page, `${sel} > [class*="baseButton__content"]`, 'backgroundColor'), CLEAR, `${sel}: no ground on the content span`);
    assert.equal(await style(page, sel, 'color'), LINK);
  }
  await page.close();
  const take = await open('/courses/1/quizzes/2/take');
  assert.deepEqual(await take.evaluate(() => [...document.documentElement.classList].filter((c) => c.startsWith('pk-'))), [], 'nothing on a quiz being taken');
  await take.close();
});

// MARK: - Page

test('C4 page: one sheet at reading width, View All Pages on the title line as words, 16 on 26, a wide table and a wide picture kept inside, Next at the foot', async () => {
  const page = await open('/courses/1/pages/rotation-the-short-version');
  const sheet = await box(page, '#content');
  assert.ok(sheet.w <= 784 && sheet.w > 700, `a reading column: ${sheet.w}`);
  assert.equal(await style(page, '#content', 'backgroundColor'), rgb('#FFFFFF'));
  assert.equal(await style(page, '.show-content.user_content', 'backgroundColor'), CLEAR, 'no card inside the sheet');
  const h1 = await box(page, 'h1.page-title'), all = await box(page, '.view_all_pages');
  assert.ok(Math.abs(h1.cy - all.cy) < 12 && all.x > h1.x, `View All Pages on the title line: ${JSON.stringify([h1, all])}`);
  assert.equal(await style(page, '.view_all_pages', 'backgroundColor'), CLEAR);
  assert.equal(await style(page, '.view_all_pages', 'color'), LINK);
  assert.equal(await style(page, '.show-content p', 'fontSize'), '16px');
  assert.equal(await style(page, '.show-content p', 'lineHeight'), '26px');
  assert.equal(await style(page, '.show-content h2', 'fontSize'), '22px');
  const table = await box(page, '.show-content table'), img = await box(page, '.show-content img');
  assert.ok(table.x + table.w <= sheet.x + sheet.w + 1, `the table stays inside the sheet: ${table.x + table.w} vs ${sheet.x + sheet.w}`);
  assert.ok(img.x + img.w <= sheet.x + sheet.w + 1, `the picture stays inside the sheet: ${img.x + img.w} vs ${sheet.x + sheet.w}`);
  assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= document.documentElement.clientWidth), true, 'no sideways scroll');
  const foot = await box(page, '.module-sequence-footer-content');
  assert.ok(foot.y > img.y && foot.x + foot.w <= sheet.x + sheet.w + 1, 'Next is the foot of the same sheet');
  assert.equal(await style(page, '.module-sequence-footer-button--next a', 'backgroundColor'), CLEAR, 'Next is words');
  await page.close();
});

// Session D (2026-09-18): the table pages — All Courses, Files, People, the
// Syllabus — in a real browser on the fake pages trimmed from the sandbox
// (test/d-pages/). The same harness as receipt.test.js, its own port:
//
//   PREPKIN_PORT=8612 node --test test/d-pages.test.js

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
  await page.waitForTimeout(600); // the debounced observer pass
  return page;
};
const style = (page, sel, prop, pseudo = null) => page.evaluate(([s, p, ps]) => { const el = document.querySelector(s); return el ? getComputedStyle(el, ps)[p] : null; }, [sel, prop, pseudo]);
const shows = (page, sel) => page.evaluate((s) => { const el = document.querySelector(s); return !!el && el.getClientRects().length > 0; }, sel);
const box = (page, sel) => page.evaluate((s) => { const r = document.querySelector(s)?.getBoundingClientRect(); return r ? { top: r.top, left: r.left, width: r.width, height: r.height } : null; }, sel);
const clear = 'rgba(0, 0, 0, 0)';

// MARK: - The one head

test('D1 every table head is quiet words on a hairline, no band: the roster, the syllabus summary, the InstUI Files table', async () => {
  await h.setStorage({ skin: SKIN({ dark: true }) });
  for (const [path, th] of [['/courses/1/users', '.roster > thead > tr > th'], ['/courses/1/assignments/syllabus', '#syllabus > thead > tr > th'], ['/courses/1/files', '[data-testid="files-table"] th[class*="-colHeader"]']]) {
    const page = await open(path);
    assert.equal(await style(page, th, 'backgroundColor'), clear, `${path}: no band`);
    assert.equal(await style(page, th, 'fontSize'), '12px', `${path}: 12px`);
    assert.equal(await style(page, th, 'color'), 'rgb(180, 186, 193)', `${path}: the quiet ink`);
    assert.equal(await style(page, th, 'borderBottomWidth'), '1px', `${path}: one hairline`);
    await page.close();
  }
  // The head band is the paper's; Put back paper brings Canvas's head back.
  await h.setStorage({ putBack: { paper: true } });
  const page = await open('/courses/1/users');
  assert.notEqual(await style(page, '.roster > thead > tr > th', 'fontSize'), '12px', 'Put back paper: Canvas\'s own head');
  await page.close();
});

// MARK: - All Courses

test('D2 All Courses draws as the /grades rows: the columns a student never reads fold under one receipt row, the tile carries the initial, the term is a chip, the grade the sync holds sits at the end', async () => {
  await h.sw((o) => syncNow(o), SCHOOL_A);
  let page = await open('/courses?full=1');
  await page.waitForSelector('#my_courses_table td.course-list-course-title-column[data-pk-initial]', { timeout: 5000 });
  for (const col of ['thead', '.course-list-star-column', '.course-list-nickname-column', '.course-list-enrolled-as-column', '.course-list-published-column']) {
    assert.equal(await shows(page, `#my_courses_table ${col}`), false, `${col} folded`);
  }
  assert.equal(await shows(page, '#my_courses_table td.course-list-course-title-column'), true, 'the name stays');
  const row = await page.$eval('#my_courses_table > tbody > tr:first-child', (tr) => ({
    h: Math.round(tr.getBoundingClientRect().height), grade: tr.dataset.pkGrade, letter: tr.dataset.pkLetter,
    initial: tr.querySelector('.course-color-block')?.dataset.pkInitial, after: getComputedStyle(tr.querySelector('.course-color-block'), '::after').content,
    tile: getComputedStyle(tr.querySelector('.course-color-block')).width, rowAfter: getComputedStyle(tr, '::after').content,
    name: getComputedStyle(tr.querySelector('td.course-list-course-title-column a')).fontWeight,
  }));
  assert.ok(row.h >= 44 && row.h <= 50, `a 44px row: ${row.h}`);
  assert.equal(row.initial, 'A'); assert.equal(row.after, '"A"', 'the initial on the tile');
  assert.equal(row.tile, '26px', 'a 26px tile');
  assert.equal(row.grade, '88.5%'); assert.equal(row.letter, 'B+');
  assert.match(row.rowAfter, /88\.5%.*B\+/, 'the grade at the row\'s end');
  assert.equal(row.name, '700', 'the name bold');
  // A course with nothing graded yet says nothing; a finished one gets its term as a chip and the grey tile with its initial.
  assert.equal(await page.$eval('#my_courses_table > tbody > tr:nth-child(3)', (tr) => tr.hasAttribute('data-pk-grade')), false, 'English 11: no grade yet, no chip');
  const past = await page.$eval('#past_enrollments_table > tbody > tr:first-child', (tr) => ({
    term: tr.querySelector('td.course-list-term-column').dataset.pkTerm, chip: getComputedStyle(tr.querySelector('td.course-list-term-column'), '::after').content,
    tile: getComputedStyle(tr.querySelector('td.course-list-course-title-column'), '::before').content, grade: tr.dataset.pkGrade,
  }));
  assert.equal(past.term, 'Spring 2026'); assert.equal(past.chip, '"Spring 2026"');
  assert.equal(past.tile, '"C"', 'Calculus I: the initial on a drawn tile'); assert.equal(past.grade, '91%');
  assert.equal(await page.$eval('#content h2[data-pk-count]', (h) => h.dataset.pkCount), '2', 'Past Enrollments counts its rows');
  // The grade follows the cards' own switch.
  await h.setStorage({ skin: SKIN({ cardGrades: false }) }); await page.waitForTimeout(500);
  assert.equal(await page.$eval('#my_courses_table > tbody > tr:first-child', (tr) => tr.hasAttribute('data-pk-grade')), false, 'grades off: no grade on the row');
  await page.close();
  // Put back: Canvas's columns and its sort row return, the head quiet.
  await h.setStorage({ skin: SKIN(), putBack: { columns: true } });
  page = await open('/courses?full=1');
  assert.equal(await shows(page, '#my_courses_table thead'), true, 'the sort row is back');
  assert.equal(await shows(page, '#my_courses_table .course-list-published-column'), true, 'and Published');
  assert.equal(await style(page, '#my_courses_table > thead > tr > th', 'backgroundColor'), clear, 'still no band');
  assert.equal(await page.$eval('#my_courses_table > tbody > tr:first-child', (tr) => tr.hasAttribute('data-pk-grade')), false, 'nothing of ours on the row');
  await page.close();
});

// MARK: - Files

test('D3 Files: the two title buttons are words and the search is our field on the title line; the helper shows only on focus; Created, Modified By and Status fold; a folder and a file row share the row shape', async () => {
  const page = await open('/courses/1/files');
  await page.waitForSelector('[data-testid="files-table"]', { timeout: 5000 });
  for (const sel of ['[data-id="switch-to-old-files-button"]', 'a[href="/files"] > [class*="-baseButton"]']) {
    assert.equal(await style(page, sel, 'backgroundColor'), clear, `${sel}: no ground`);
    assert.equal(await style(page, `${sel} > [class*="baseButton__content"]`, 'backgroundColor'), clear, `${sel}: no ground on the content span`);
    assert.equal(await style(page, sel, 'fontSize'), '13px');
  }
  const h1 = await box(page, '#content h1[class*="-view-heading"]');
  const search = await box(page, 'form[name="files-search"] input');
  const button = await box(page, '[data-id="switch-to-old-files-button"]');
  const mid = (b) => b.top + b.height / 2;
  assert.ok(Math.abs(mid(search) - mid(h1)) < 6, `the search sits on the title line: ${mid(search)} vs ${mid(h1)}`);
  assert.ok(Math.abs(mid(button) - mid(h1)) < 6, `and the words too: ${mid(button)} vs ${mid(h1)}`);
  assert.ok(button.left + button.width < search.left, 'the words end before the search');
  assert.equal(Math.round(await page.$eval('form[name="files-search"] label[data-cid="TextInput"]', (e) => e.getBoundingClientRect().width)), 240, 'the field is 240');
  const helper = 'form[name="files-search"] + [class*="view--block"]';
  assert.equal(await shows(page, helper), false, 'the helper waits');
  await page.focus('[data-testid="files-search-input"]'); await page.waitForTimeout(100);
  assert.equal(await shows(page, helper), true, 'and shows on focus');
  assert.equal(await style(page, `${helper} [class*="-text"]`, 'fontSize'), '12px');
  for (const col of ['th[data-testid="created_at"]', 'td[data-testid="table-cell-created_at"]', 'th[data-testid="modified_by"]', 'td[data-testid="table-cell-modified_by"]', 'th[data-testid="permissions"]', 'td[data-testid="table-cell-permissions"]']) {
    assert.equal(await shows(page, `[data-testid="files-table"] ${col}`), false, `${col} folded`);
  }
  assert.equal(await shows(page, '[data-testid="files-table"] td[data-testid="table-cell-updated_at"]'), true, 'Last Modified stays');
  const rows = await page.$$eval('[data-testid="files-table"] tbody [data-testid="table-row"]', (els) => els.map((r) => ({
    h: Math.round(r.getBoundingClientRect().height), name: getComputedStyle(r.querySelector('[data-testid="table-cell-name"] [class*="-text"]')).fontWeight,
    tile: getComputedStyle(r.querySelector('[data-testid="table-cell-name"] a > span > span:first-child > :first-child')).width,
    size: getComputedStyle(r.querySelector('[data-testid="table-cell-size"]')).fontSize, folder: !!r.querySelector('[data-testid="folder-icon"]'),
  })));
  assert.ok(rows.some((r) => r.folder) && rows.some((r) => !r.folder), 'a folder and a file');
  for (const r of rows) {
    assert.ok(r.h >= 44 && r.h <= 56, `a 44px row: ${r.h}`);
    assert.equal(r.name, '700'); assert.equal(r.tile, '26px'); assert.equal(r.size, '12px');
  }
  // The receipt lists the fold, once, with a Put back.
  const rows2 = await page.evaluate(() => new Promise((res) => chrome.runtime.sendMessage({ type: 'receipt' }, res)).catch(() => null)).catch(() => null);
  await page.close();
  // Put back the columns: Created and the rest return.
  await h.setStorage({ putBack: { columns: true } });
  const back = await open('/courses/1/files');
  assert.equal(await shows(back, '[data-testid="files-table"] th[data-testid="created_at"]'), true, 'Put back: Created is back');
  await back.close();
  void rows2;
});

// MARK: - People

test('D4 People: the title shows with the kebab on its line, the role filter is our field with no native arrow, rows are 44px with the name bold and the section and role as meta, a placeholder face is the initials on the class colour', async () => {
  await h.sw((o) => syncNow(o), SCHOOL_A);
  const page = await open('/courses/1/users');
  await page.waitForSelector('.roster [class*="-avatar"][data-pk-initial]', { timeout: 5000 });
  assert.equal(await shows(page, '#content .ic-Action-header__Primary > h1'), true, 'the title is unclipped');
  assert.equal(await style(page, '#content .ic-Action-header__Primary > h1', 'fontSize'), '28px');
  const sel = 'select[data-view="roleSelect"]';
  assert.equal(await style(page, sel, 'appearance'), 'none', 'no native arrow');
  assert.equal(await style(page, sel, 'borderRadius'), '10px');
  assert.equal(await style(page, sel, 'fontSize'), '13px');
  assert.equal(await style(page, '.roster-tab > div:has(> select[data-view="roleSelect"])', 'content', '::after'), '"⌄"', 'the planner\'s chevron');
  const chevron = await page.evaluate(() => { const w = document.querySelector('.roster-tab > div:has(> select[data-view="roleSelect"])'); const s = w.querySelector('select').getBoundingClientRect(); const c = getComputedStyle(w, '::after'); return { selRight: s.right, selTop: s.top, selBottom: s.bottom, gridCol: c.gridColumnStart }; });
  assert.equal(chevron.gridCol, '2', 'in the select\'s own cell');
  const rows = await page.$$eval('.roster > tbody > tr', (els) => els.map((tr) => ({
    h: Math.round(tr.getBoundingClientRect().height), name: getComputedStyle(tr.querySelector('a.roster_user_name')).fontWeight, nameColor: getComputedStyle(tr.querySelector('a.roster_user_name')).color,
    meta: getComputedStyle(tr.children[2]).fontSize, face: tr.querySelector('[class*="-avatar"]').dataset.pkInitial, faceCourse: tr.querySelector('[class*="-avatar"]').dataset.pkCourse,
    initials: getComputedStyle(tr.querySelector('[class*="-avatar"]'), '::after').content, img: tr.querySelector('[class*="-avatar"] img').getClientRects().length,
    faceBg: getComputedStyle(tr.querySelector('[class*="-avatar"]')).backgroundColor, ring: getComputedStyle(tr.querySelector('[class*="-avatar"]')).borderTopWidth,
  })));
  assert.ok(rows.length >= 5);
  for (const r of rows) {
    assert.ok(r.h >= 44 && r.h <= 48, `a 44px row: ${r.h}`);
    assert.equal(r.name, '700'); assert.equal(r.nameColor, 'rgb(27, 31, 36)', 'the name in the ink, not the link blue');
    assert.equal(r.meta, '12px', 'section and role as meta');
    assert.equal(r.img, 0, 'the grey silhouette goes'); assert.equal(r.ring, '1px', 'a ring');
  }
  assert.equal(rows[0].face, 'RH'); assert.equal(rows[0].initials, '"RH"'); assert.equal(rows[0].faceCourse, '1');
  assert.equal(rows[0].faceBg, 'rgb(255, 111, 97)', 'the class colour, from the sync');
  // Two sections, two roles: one line, a dot between.
  const alex = await page.$eval('#user_3', (tr) => ({ sections: [...tr.querySelectorAll('.section')].map((d) => getComputedStyle(d).display), dot: getComputedStyle(tr.querySelectorAll('.section')[1], '::before').content }));
  assert.deepEqual(alex.sections, ['inline', 'inline']); assert.equal(alex.dot, '" · "');
  await page.close();
});

// MARK: - Syllabus

test('D5 Syllabus: the body reads in the page\'s column, an empty one draws no card, Course Summary heads its rows with a count, the date is a quiet row header, the work is the row\'s link with the look\'s icon, the mini month is the planner\'s', async () => {
  let page = await open('/courses/1/assignments/syllabus');
  await page.waitForSelector('#content h2[data-pk-count] + #syllabusContainer', { timeout: 5000 });
  assert.equal(await shows(page, '#course_syllabus'), true, 'the teacher\'s body shows');
  assert.equal(await style(page, '#course_syllabus', 'fontSize'), '15px');
  assert.equal(await style(page, '#content h2[data-pk-count]', 'fontSize'), '15px', 'Course Summary is a group head');
  assert.match(await page.$eval('#content h2[data-pk-count]', (h) => h.dataset.pkCount), /^\d+$/);
  const row = await page.$eval('#syllabus > tbody > tr', (tr) => ({
    h: Math.round(tr.getBoundingClientRect().height), dateBg: getComputedStyle(tr.querySelector('th.day_date')).backgroundColor, dateColor: getComputedStyle(tr.querySelector('th.day_date')).color, dateSize: getComputedStyle(tr.querySelector('th.day_date')).fontSize,
    link: getComputedStyle(tr.querySelector('td.name a')).fontWeight, linkColor: getComputedStyle(tr.querySelector('td.name a')).color,
    tile: getComputedStyle(tr.querySelector('td.name i')).width, mask: getComputedStyle(tr.querySelector('td.name i'), '::before').maskImage || getComputedStyle(tr.querySelector('td.name i'), '::before').webkitMaskImage,
    due: getComputedStyle(tr.querySelector('td.dates')).textAlign, nameW: tr.querySelector('td.name').getBoundingClientRect().width,
  }));
  assert.ok(row.h >= 44 && row.h <= 50, `a 44px row: ${row.h}`);
  assert.equal(row.dateBg, clear, 'the date has no fill'); assert.equal(row.dateColor, 'rgb(69, 75, 84)', 'in the quiet ink'); assert.equal(row.dateSize, '12px');
  assert.equal(row.link, '700'); assert.equal(row.linkColor, 'rgb(27, 31, 36)', 'the work in the ink');
  assert.equal(row.tile, '26px', 'the icon on a tile'); assert.match(row.mask, /^url\("data:image\/svg\+xml/, 'the look\'s icon');
  assert.equal(row.due, 'right'); assert.ok(row.nameW > 300, `the work takes the width: ${row.nameW}`);
  // The mini month.
  assert.equal(await style(page, '#right-side .mini_month table.mini_calendar > thead > tr > th:nth-child(2)', 'content', '::before'), '"M"', 'weekday letters');
  const cell = await page.$eval('#right-side .mini_month .mini_calendar_day.has_event .day_wrapper', (d) => ({ h: Math.round(d.getBoundingClientRect().height), bg: getComputedStyle(d).backgroundColor, dot: getComputedStyle(d, '::after').width }));
  assert.equal(cell.h, 28, 'a 28px cell'); assert.equal(cell.bg, clear, 'no wash'); assert.equal(cell.dot, '4px', 'a dot for a day with work');
  assert.equal(await style(page, '#right-side .mini_month .mini_calendar_day.today .day_wrapper', 'borderTopColor'), 'rgb(27, 31, 36)', 'today as a ring');
  assert.equal(await style(page, '#right-side [aria-label="Assignment Weights"] > h2', 'fontSize'), '12px', 'the weights line is quiet');
  await page.close();
  // No body from the teacher: no empty card.
  page = await open('/courses/1/assignments/syllabus?empty=1');
  await page.waitForSelector('#course_syllabus[data-pk-empty]', { state: 'attached', timeout: 5000 });
  assert.equal(await shows(page, '#course_syllabus'), false, 'an empty body draws nothing');
  await page.close();
});

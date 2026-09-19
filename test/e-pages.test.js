// Session E (2026-09-19): the calendar and the Inbox on the fake Canvas, from
// the sandbox dumps in test/e-pages/. What the stylesheet promises on each,
// measured in a real browser with the real extension.
//
//   PREPKIN_PORT=8712 node --test test/e-pages.test.js

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

const test = require('node:test');
const assert = require('node:assert');
const { FakeServer } = require('./fake-canvas');
const { launch, PORT, SCHOOL_A, BRIDGE } = require('./harness');
const S = require('./scenarios');

let server, h;
const control = (p, body) => fetch(`${BRIDGE}/__${p}`, { method: 'POST', body: JSON.stringify(body ?? {}) }).then((r) => r.json());
const SKIN = (over = {}) => ({ dark: false, cards: true, mascot: false, focusMinutes: 25, ...over });

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
  await page.goto(`${SCHOOL_A}${path}`, { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(600); // the debounced observer pass
  return page;
};
const style = (page, sel, prop, pseudo = null) => page.evaluate(([s, p, ps]) => { const el = document.querySelector(s); return el ? getComputedStyle(el, ps)[p] : null; }, [sel, prop, pseudo]);
const box = (page, sel) => page.evaluate((s) => { const el = document.querySelector(s); if (!el) return null; const r = el.getBoundingClientRect(); return { w: Math.round(r.width), h: Math.round(r.height), x: Math.round(r.left), y: Math.round(r.top) }; }, sel);
const shows = (page, sel) => page.evaluate((s) => { const el = document.querySelector(s); return !!el && el.getClientRects().length > 0; }, sel);

const PAPER = 'rgb(247, 246, 243)', PAPER2 = 'rgb(255, 255, 255)', SUNK = 'rgb(239, 237, 232)', INK = 'rgb(27, 31, 36)', INK2 = 'rgb(69, 75, 84)', RULE = 'rgb(227, 224, 217)', MARK = 'rgb(47, 107, 170)', CLEAR = 'rgba(0, 0, 0, 0)';

// MARK: - The calendar

test('E1 calendar: quiet weekday letters on a hairline, hairline cells, today a tint, the other month at half ink', async () => {
  const page = await open('/calendar');
  assert.equal(await style(page, '#calendar-app .fc-day-header', 'backgroundColor'), CLEAR, 'no band over the weekday letters');
  assert.equal(await style(page, '#calendar-app .fc-day-header', 'textTransform'), 'none', 'never uppercase');
  assert.equal(await style(page, '#calendar-app .fc-day-header', 'fontSize'), '12px');
  assert.equal(await style(page, '#calendar-app .fc-day-header', 'color'), INK2, 'the quiet ink');
  assert.equal(await style(page, '#calendar-app thead .fc-row.fc-widget-header', 'borderBottomColor'), RULE, 'one hairline under the letters');
  assert.equal(await style(page, '#calendar-app thead .fc-row.fc-widget-header', 'borderBottomWidth'), '1px');
  assert.equal(await style(page, '#calendar-app .fc-view > table', 'borderTopWidth'), '0px', 'no frame around the grid (the card is the frame)');
  assert.equal(await style(page, '#calendar-app .fc-bg .fc-day', 'borderRightColor'), RULE, 'cells part with the rule');
  assert.equal(await style(page, '#calendar-app .fc-bg td:first-child', 'borderLeftWidth'), '0px', 'no edge at the card wall');
  assert.equal(await style(page, '#calendar-app .fc-day-top', 'backgroundColor'), CLEAR, 'the number layer is clear, so the cell tint shows whole');
  assert.equal(await style(page, '#calendar-app .fc-content-skeleton table', 'backgroundColor'), CLEAR);
  assert.equal(await style(page, '#calendar-app .fc-bg .fc-day.fc-today', 'backgroundColor'), SUNK, 'today is a paper tint');
  assert.equal(await style(page, '#calendar-app .fc-day-top.fc-today .fc-day-number', 'fontWeight'), '800');
  assert.equal(await style(page, '#calendar-app .fc-day-top.fc-other-month .fc-day-number', 'opacity'), '0.5', 'the other month at half ink');
  assert.equal(await style(page, '#calendar-app .fc-day-number', 'fontSize'), '12px');
  await page.close();
});

test('E2 calendar chips: the class colour on the edge, two lines of the title, no icon, no due time; a timed event keeps its time', async () => {
  const page = await open('/calendar');
  const chip = '#calendar-app .fc-event.assignment';
  assert.equal(await style(page, chip, 'borderLeftColor'), 'rgb(255, 111, 97)', "the course's own colour, from its own class rule");
  assert.equal(await style(page, chip, 'borderLeftWidth'), '3px');
  assert.equal(await style(page, chip, 'backgroundColor'), CLEAR);
  assert.equal(await style(page, `${chip} .fc-content`, 'webkitLineClamp'), '2', 'the title gets two lines at most');
  assert.equal(await style(page, `${chip} .fc-content`, 'whiteSpace'), 'normal');
  assert.equal(await style(page, `${chip} .fc-content`, 'fontSize'), '12px');
  assert.equal(await shows(page, `${chip} .fc-content > i`), false, 'no icon in a month cell');
  assert.equal(await style(page, `${chip} .fc-title`, 'color'), INK, 'the title in the ink');
  // The due time is clipped to a screen reader's ear, never removed: Canvas's words stay.
  const time = await page.evaluate((s) => { const el = document.querySelector(`${s} .fc-time`); const r = el.getBoundingClientRect(); return { w: Math.round(r.width), text: el.textContent, pos: getComputedStyle(el).position }; }, chip);
  assert.deepEqual([time.w, time.pos], [1, 'absolute'], `a due time on a month grid says nothing: ${JSON.stringify(time)}`);
  assert.match(time.text, /\d/, "Canvas's words stay in the DOM");
  // A calendar event proper (a lab section at 1p) is not an assignment: its time shows.
  const event = '#calendar-app .fc-event:not(.assignment):not(.assignment_override)';
  assert.ok(await page.$(event), 'the dump holds a timed event');
  const ev = await page.evaluate((s) => { const el = document.querySelector(`${s} .fc-time`); return { w: Math.round(el.getBoundingClientRect().width), color: getComputedStyle(el).color }; }, event);
  assert.ok(ev.w > 10, `the event's time shows: ${JSON.stringify(ev)}`);
  assert.equal(ev.color, INK2, 'in the quiet ink');
  assert.equal(await style(page, '#calendar-app .fc-title.calendar__event--completed', 'textDecorationLine'), 'line-through', 'handed-in work stays struck');
  assert.equal(await style(page, '#calendar-app .fc-title.calendar__event--completed', 'color'), INK2);
  // Put back: the chip is Canvas's again, icon and all.
  await h.setStorage({ putBack: { 'cal-rows': true } });
  await page.waitForTimeout(700);
  assert.equal(await shows(page, `${chip} .fc-content > i`), true, 'Put back brings the icon back');
  assert.equal(await style(page, `${chip} .fc-content`, 'whiteSpace'), 'nowrap');
  await page.close();
});

test('E3 calendar toolbar: Today and the arrows bare on the paper, the view switch a sunk track with the chosen view in the ink, the + bare', async () => {
  const page = await open('/calendar');
  assert.equal(await style(page, '#calendar_header .navigate_today', 'backgroundColor'), PAPER, 'Today stands on the page paper');
  assert.equal(await style(page, '#calendar_header .navigate_today', 'borderTopColor'), CLEAR, 'no edge');
  assert.equal(await style(page, '#calendar_header .navigate_prev', 'backgroundColor'), PAPER);
  assert.equal(await style(page, '#calendar_header .navigation_title', 'fontSize'), '18px');
  assert.equal(await style(page, '#calendar_header .navigation_title', 'fontWeight'), '800');
  assert.equal(await style(page, '#calendar_header .calendar_view_buttons', 'backgroundColor'), SUNK, 'the track');
  assert.equal(await style(page, '#calendar_header #week', 'backgroundColor'), SUNK, 'an unchosen view is the track');
  assert.equal(await style(page, '#calendar_header #week', 'borderTopColor'), SUNK, 'its edge is the track too');
  assert.equal(await style(page, '#calendar_header #month', 'backgroundColor'), INK, 'the chosen view is the pressed key');
  assert.equal(await style(page, '#calendar_header #month', 'color'), PAPER);
  assert.equal(await style(page, '#calendar_header #create_new_event_link', 'backgroundColor'), PAPER, 'the + is bare');
  assert.equal(await style(page, '#calendar_header #create_new_event_link', 'borderTopColor'), CLEAR);
  // Every one of them is still a button of Canvas's: only the paper's tokens are written (the lint holds the line).
  assert.equal(await style(page, '#calendar_header #week', 'borderRadius'), '3px', "Canvas's own shape (the fake's .btn), never ours");
  await page.close();
});

test('E4 calendar sidebar: the mini month without boxes, the calendars as 32px rows with an 8px dot, the undated items in the row shape, Calendar Feed as words', async () => {
  const page = await open('/calendar');
  assert.equal(await style(page, '#minical .fc-row.fc-week', 'borderTopWidth'), '0px', 'no strip per week');
  assert.equal(await style(page, '#minical .fc-bg .fc-day', 'borderTopColor'), CLEAR, 'no boxes');
  assert.equal(await style(page, '#minical .event', 'content', '::after'), 'none', "Canvas's box on a day with work is gone");
  assert.match(await style(page, '#minical .fc-bg .fc-day.event', 'backgroundImage'), /radial-gradient/, 'a dot says it instead');
  assert.equal(await style(page, '#minical .fc-day-number', 'fontSize'), '12px');
  assert.equal(await style(page, '#minical .fc-toolbar h2', 'fontWeight'), '800');
  const rows = await page.$$eval('#calendars-context-list li.context_list_context', (els) => els.map((el) => Math.round(el.getBoundingClientRect().height)));
  assert.ok(rows.length >= 3 && rows.every((r) => r >= 32 && r <= 36), `32px rows: ${rows}`);
  const dot = await box(page, '#calendars-context-list .context-list-toggle-box.group_course_4');
  assert.deepEqual([dot.w, dot.h], [8, 8], `the colour as an 8px dot: ${JSON.stringify(dot)}`);
  assert.equal(await style(page, '#calendars-context-list .context-list-toggle-box.group_course_4', 'borderRadius'), '999px');
  assert.equal(await style(page, '#calendars-context-list .context-list-toggle-box.group_course_4', 'backgroundColor'), 'rgb(255, 111, 97)', "the course's colour, never repainted");
  assert.equal(await style(page, '#calendars-context-list label', 'fontSize'), '13px');
  assert.equal(await style(page, '#calendar-toggle-button', 'textTransform'), 'none', 'never an uppercase head');
  assert.equal(await style(page, '#calendar-toggle-button', 'content', '::after'), '"⌄"', "the planner's chevron after the words");
  await page.evaluate(() => document.querySelector('#undated-events-button').setAttribute('aria-expanded', 'false'));
  assert.equal(await style(page, '#undated-events-button', 'content', '::after'), '"›"', 'closed: the closed chevron');
  assert.equal(await shows(page, '#calendar-toggle-button i'), false, "Canvas's arrow is gone");
  // The undated list: each item a 32px row, the dot in its class's colour, the title in the ink.
  const item = '#undated_events_list li.undated_event.group_course_4';
  assert.equal(await style(page, item, 'display'), 'flex');
  assert.equal(await style(page, item, 'backgroundColor'), CLEAR, "the class rule's fill is not a row's ground");
  assert.equal(await style(page, item, 'borderTopColor', '::before'), 'rgb(255, 111, 97)', 'the dot reads the class colour');
  assert.equal(await style(page, item, 'borderTopWidth', '::before'), '4px', 'an 8px dot');
  assert.equal(await style(page, `${item} a.undated_event_title`, 'color'), INK);
  assert.equal(await style(page, `${item} a.undated_event_title`, 'content', '::before'), 'none', 'no glyph');
  assert.equal(await style(page, '#calendar-feed-button', 'backgroundColor'), CLEAR, 'Calendar Feed is words');
  assert.equal(await style(page, '#calendar-feed-button', 'color'), MARK);
  assert.equal(await style(page, '#calendar-feed-button', 'fontSize'), '13px');
  await page.close();
});

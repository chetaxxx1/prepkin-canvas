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

// MARK: - The Inbox

test('E5 inbox toolbar: one line under the title, Compose first, the filters and the search as our fields, the strip folded until a thread is open, More at the far right', async () => {
  const page = await open('/conversations');
  const bar = '#content [data-testid="tool-bar"]';
  assert.equal(await style(page, bar, 'borderTopWidth'), '0px', 'no bar above the toolbar');
  assert.equal(await style(page, bar, 'borderBottomWidth'), '0px');
  const order = await page.evaluate(() => {
    const at = (s) => document.querySelector(s)?.getBoundingClientRect();
    const compose = at('#compose-new-message'), course = at('[data-testid="course-select"]'), mailbox = at('[data-testid="mailbox-select"]'), search = at('[data-testid="message-list-actions-address-book-input"]'), book = at('[data-testid="address-button"]'), more = at('[data-testid="settings"]');
    return { compose: compose.left, course: course.left, mailbox: mailbox.left, search: search.left, book: book.left, more: more.right, bar: at('[data-testid="tool-bar"]').right, sameLine: [compose, course, mailbox, search, book, more].every((b) => Math.abs(b.top + b.height / 2 - (compose.top + compose.height / 2)) < 20) };
  });
  assert.ok(order.compose < order.course && order.course < order.mailbox && order.mailbox < order.search && order.search < order.book, `Compose leads, then the filters, then the search with its address book: ${JSON.stringify(order)}`);
  assert.ok(order.book - order.search < 320, 'the address book hugs the search');
  assert.ok(order.bar - order.more < 30, 'More at the far right');
  assert.ok(order.sameLine, 'one line');
  for (const id of ['reply', 'reply-all', 'archive', 'delete']) assert.equal(await shows(page, `[data-testid="${id}"]`), false, `${id} waits until a thread is open`);
  assert.equal(await shows(page, '[data-testid="settings"]'), true);
  assert.equal(await style(page, `${bar} [class*="textInput__facade"]`, 'borderRadius'), '10px', 'our field');
  assert.equal(await style(page, `${bar} [class*="textInput__facade"]`, 'borderTopColor'), RULE);
  assert.equal(await style(page, `${bar} [data-testid="course-select"]`, 'fontSize'), '13px');
  // Only the paper's tokens on a button: Compose keeps Canvas's own shape.
  assert.equal(await style(page, '#compose-new-message [class*="baseButton__content"]', 'borderRadius'), '4px', "Compose is Canvas's button, moved, not painted");
  await page.close();
  // A thread open: the strip shows.
  const open2 = await open('/conversations?open=1');
  for (const id of ['reply', 'reply-all', 'archive', 'delete']) assert.equal(await shows(open2, `[data-testid="${id}"]`), true, `${id} shows for the open thread`);
  await open2.close();
});

test('E6 inbox rows: the face tile with the initials the pass wrote, the unread mark on its corner, name, subject, one line, the date at the right, a hairline between', async () => {
  const page = await open('/conversations');
  const rows = await page.$$eval('#inbox-conversation-holder [data-testid="conversation"]', (els) => els.map((el) => ({ face: el.getAttribute('data-pk-face'), unread: !!el.querySelector('[data-testid="unread-badge"]'), h: Math.round(el.getBoundingClientRect().height), border: getComputedStyle(el).borderBottomWidth + ' ' + getComputedStyle(el).borderBottomColor })));
  assert.equal(rows.length, 4);
  assert.ok(rows.every((r) => r.face === 'DW'), `the sender's initials (never the student's): ${JSON.stringify(rows)}`);
  assert.deepEqual(rows.map((r) => r.unread), [false, true, true, false], 'the dump has two unread');
  assert.ok(rows.every((r) => r.h >= 72 && r.h <= 92), `rows of one height: ${rows.map((r) => r.h)}`);
  assert.ok(rows.every((r) => r.border === `1px ${RULE}`), 'a hairline between rows');
  const row = '#inbox-conversation-holder [data-testid="conversation"]';
  assert.equal(await style(page, row, 'content', '::before'), '"DW"', 'the tile draws the initials');
  assert.equal(await style(page, row, 'width', '::before'), '32px');
  assert.equal(await style(page, row, 'backgroundColor', '::before'), SUNK);
  assert.equal(await style(page, row, 'borderRadius', '::before'), '10px');
  assert.equal(await style(page, `${row}:has([data-testid="unread-badge"])`, 'backgroundColor', '::after'), MARK, 'unread is our mark on the tile');
  assert.equal(await style(page, `${row}:has([data-testid="unread-badge"])`, 'width', '::after'), '8px');
  assert.equal(await style(page, `${row}:not(:has([data-testid="unread-badge"]))`, 'content', '::after'), 'none', 'read: no mark');
  assert.equal(await shows(page, `${row} [data-testid="unread-badge"]`), false, "Canvas's circle is folded; the kebab still offers Mark as read");
  assert.equal(await shows(page, `${row} [data-cid="Badge"]`), false, 'a count of one is nothing to say');
  assert.equal(await page.$eval(`${row} [data-cid="Badge"]`, (el) => el.hasAttribute('data-pk-one')), true, 'the pass marked it');
  assert.equal(await style(page, `${row} h2 [class*="-text"]`, 'fontWeight'), '700', 'the names bold');
  assert.equal(await style(page, `${row} h2 [class*="-text"]`, 'fontSize'), '14px');
  assert.equal(await style(page, `${row} h3 [class*="-text"]`, 'fontSize'), '13px', 'the subject');
  assert.equal(await style(page, `${row} [data-testid="last-message-content"]`, 'color'), INK2, 'one quiet line of the message');
  assert.equal(await style(page, `${row} [data-testid="last-message-content"]`, 'whiteSpace'), 'nowrap');
  const geo = await page.evaluate((s) => { const el = document.querySelector(s); const r = (x) => x.getBoundingClientRect(); const row = r(el), h2 = r(el.querySelector('h2')), date = r(el.querySelector('[color="brand"]')), cb = r(el.querySelector('[data-testid="conversationListItem-Checkbox"]').closest('[class*="-gridCol"]')); return { textLeft: Math.round(h2.left - row.left), dateRight: Math.round(row.right - date.right), sameTop: Math.abs(h2.top - date.top) < 6, cbOverFace: Math.round(cb.left - row.left) === 14 && Math.round(cb.width) === 32, cbOpacity: getComputedStyle(el.querySelector('[data-testid="conversationListItem-Checkbox"]').closest('[class*="-gridCol"]')).opacity }; }, row);
  assert.equal(geo.textLeft, 58, `the words clear the tile: ${JSON.stringify(geo)}`);
  assert.ok(geo.dateRight <= 16 && geo.sameTop, 'the date at the right, on the first line');
  assert.ok(geo.cbOverFace && geo.cbOpacity === '0', "Canvas's check box lies over the face, unseen until hovered");
  await page.hover(row); await page.waitForTimeout(200);
  assert.equal(await page.evaluate((s) => getComputedStyle(document.querySelector(s).querySelector('[data-testid="conversationListItem-Checkbox"]').closest('[class*="-gridCol"]')).opacity, row), '1', 'hover shows it');
  await page.close();
});

test('E7 inbox: no thread chosen is one quiet line; the chosen thread is the sunk paper with the mark on its edge; its messages carry our face', async () => {
  const page = await open('/conversations');
  const detail = '#content [class*="view-flexItem"]:has(> #inbox-conversation-holder) + [class*="view-flexItem"]';
  assert.equal(await shows(page, `${detail} svg`), false, "Canvas's envelope drawing is gone");
  const words = await page.evaluate((s) => { const el = document.querySelector(`${s} [class*="-text"]`); return { canvas: el.textContent.trim(), ours: getComputedStyle(el, '::after').content, size: getComputedStyle(el).fontSize }; }, detail);
  assert.deepEqual(words, { canvas: 'No Conversations Selected', ours: '"Pick a message on the left"', size: '0px' }, "Canvas's words stay for a screen reader; ours are what shows");
  await page.close();
  const open2 = await open('/conversations?open=1');
  const chosen = '#inbox-conversation-holder div[style*="background-color"]:has(> [data-testid="conversation"])';
  assert.equal(await style(open2, chosen, 'backgroundColor'), SUNK, "Canvas's light blue is the sunk paper (the ground says chosen; the inset shadow is only focus)");
  assert.equal(await style(open2, chosen, 'boxShadow'), 'none', 'no blue inset');
  assert.equal(await style(open2, chosen, 'outlineColor'), MARK, 'the focus ring is the mark');
  assert.equal(await style(open2, chosen, 'backgroundColor', '::before'), MARK, 'the mark on the edge');
  assert.equal(await style(open2, chosen, 'width', '::before'), '3px');
  assert.equal(await style(open2, `${detail} h2 [data-testid="message-detail-header-desktop"]`, 'fontSize'), '18px');
  assert.equal(await style(open2, `${detail} h2 [data-testid="message-detail-header-desktop"]`, 'fontWeight'), '800');
  const face = '[data-testid="message-detail-item-desktop"] [class*="-avatar"]';
  assert.equal(await style(open2, face, 'borderRadius'), '10px', "the sender's face is our tile");
  assert.equal(await style(open2, face, 'backgroundColor'), SUNK);
  assert.equal(await style(open2, `${face} [class*="avatar__initials"]`, 'color'), INK2);
  const meta = await open2.evaluate(() => { const col = document.querySelector('[data-testid="message-detail-item-desktop"] > [class*="view-flexItem"]:nth-child(2) > [class*="view--flex-flex"]'); const kids = [...col.children]; const tops = kids.map((k) => Math.round(k.getBoundingClientRect().top)); return { n: kids.length, oneLine: tops.every((t) => Math.abs(t - tops[0]) < 8), dot: getComputedStyle(kids[1], '::before').content }; });
  assert.ok(meta.n === 3 && meta.oneLine && meta.dot === '"·"', `the name, the class and the time on one line with dots: ${JSON.stringify(meta)}`);
  await open2.close();
});

test('E8 inbox: Put back returns Canvas’s rows, drawing and toolbar, and the pass takes its attributes away', async () => {
  await h.setStorage({ putBack: { 'inbox-rows': true } });
  const page = await open('/conversations');
  const row = '#inbox-conversation-holder [data-testid="conversation"]';
  assert.equal(await page.$eval(row, (el) => el.hasAttribute('data-pk-face')), false, 'no initials written');
  assert.equal(await page.$eval(`${row} [data-cid="Badge"]`, (el) => el.hasAttribute('data-pk-one')), false);
  assert.equal(await style(page, row, 'content', '::before'), 'none', 'no tile');
  assert.equal(await shows(page, `${row} [data-testid="unread-badge"]`), true, "Canvas's circle is back");
  assert.equal(await shows(page, '#content [class*="view-flexItem"]:has(> #inbox-conversation-holder) + [class*="view-flexItem"] svg'), true, 'the envelope is back');
  assert.equal(await shows(page, '[data-testid="reply"]'), true, 'the toolbar is whole');
  assert.equal(await style(page, '#content [data-testid="tool-bar"]', 'borderTopWidth'), '1px');
  await page.close();
});

// MARK: - The calendar's other two views, and the Inbox's icon buttons (2026-09-19, the second pass)

test('E9 calendar week view: quiet hour labels, today a tint with no blue bar and no grey frame, the now line in the mark', async () => {
  const page = await open('/calendar?view=week');
  assert.ok(await page.$('#calendar-app .fc-agendaWeek-view'), 'the week view');
  assert.equal(await style(page, '#calendar-app .fc-agenda-view .fc-axis.fc-time', 'fontSize'), '12px');
  assert.equal(await style(page, '#calendar-app .fc-agenda-view .fc-axis.fc-time', 'color'), INK2);
  assert.equal(await style(page, '#calendar-app .fc-agenda-view .fc-axis.fc-time', 'textAlign'), 'right');
  assert.equal(await style(page, '#calendar-app .fc-agendaWeek-view .fc-day-grid .fc-day.fc-today', 'boxShadow'), 'none', "Canvas's blue bar is gone");
  assert.equal(await style(page, '#calendar-app .fc-agendaWeek-view .fc-day-grid .fc-day.fc-today', 'backgroundColor'), SUNK, 'today is a tint');
  assert.equal(await style(page, '#calendar-app .fc-agendaWeek-view .fc-time-grid .fc-day.fc-today', 'borderLeftWidth'), '1px', 'a hairline, not a 3px frame');
  assert.equal(await style(page, '#calendar-app .fc-agendaWeek-view .fc-time-grid .fc-day.fc-today', 'borderLeftColor'), RULE);
  assert.equal(await style(page, '#calendar-app .fc-agenda-view .fc-day-header.fc-today', 'fontWeight'), '800');
  assert.equal(await style(page, '#calendar-app .calendar-nowline', 'backgroundColor'), MARK, 'the now line is the mark, never orange');
  assert.equal(await style(page, '#calendar-app .fc-time-grid-event.fc-event', 'borderLeftWidth'), '3px', 'the chip is the month chip');
  await page.close();
});

test('E10 calendar agenda view: each day a group head, each item a 44px row with the class dot, the title in the ink, the time at the right', async () => {
  const page = await open('/calendar?view=agenda');
  assert.equal(await style(page, '#calendar-app .agenda-container', 'borderRadius'), '14px', 'the list is the card');
  assert.equal(await style(page, '#calendar-app h3.agenda-date', 'fontSize'), '14px');
  assert.equal(await style(page, '#calendar-app h3.agenda-date', 'fontWeight'), '800');
  assert.equal(await style(page, '#calendar-app h3.agenda-date', 'backgroundColor'), CLEAR, 'no band');
  assert.equal(await style(page, '#calendar-app .agenda-day:not(:first-child)', 'borderTopColor'), RULE, 'days part with a hairline');
  const row = '#calendar-app .agenda-event__item-container';
  assert.equal(await style(page, row, 'display'), 'grid');
  const h = await box(page, row);
  assert.ok(h.h >= 44 && h.h <= 48, `44px rows: ${JSON.stringify(h)}`);
  const dot = await box(page, `${row} .agenda-event__icon`);
  assert.deepEqual([dot.w, dot.h], [8, 8], 'the class colour is an 8px dot');
  assert.equal(await style(page, `${row} .agenda-event__icon`, 'backgroundColor'), 'rgb(255, 111, 97)', "the icon's own class rule colours it");
  assert.equal(await shows(page, `${row} .agenda-event__icon i`), false, 'no glyph');
  assert.equal(await style(page, `${row} .agenda-event__title`, 'color'), INK, 'the title in the ink, not the course colour');
  assert.equal(await style(page, `${row} .agenda-event__time`, 'color'), INK2);
  const geo = await page.evaluate((s) => { const el = document.querySelector(s); const r = (x) => x.getBoundingClientRect(); const row = r(el), t = r(el.querySelector('.agenda-event__title')), time = r(el.querySelector('.agenda-event__time')); return { titleLeft: Math.round(t.left - row.left), timeRight: Math.round(row.right - time.right), order: t.left < time.left }; }, row);
  assert.ok(geo.titleLeft === 36 && geo.timeRight === 16 && geo.order, `dot, title, then the time at the right: ${JSON.stringify(geo)}`);
  await page.close();
});

test('E11 inbox icon buttons: Compose the one raised key, the address book, the strip, More and a row star bare on the paper; an open thread the same', async () => {
  const page = await open('/conversations');
  const content = (id) => `#content [data-testid="${id}"] [class*="baseButton__content"]`;
  assert.equal(await style(page, '#compose-new-message [class*="baseButton__content"]', 'backgroundColor'), PAPER2, 'Compose is raised');
  assert.equal(await style(page, '#compose-new-message [class*="baseButton__content"]', 'borderTopColor'), RULE);
  assert.equal(await style(page, content('address-button'), 'backgroundColor'), PAPER, 'the address book is bare');
  assert.equal(await style(page, content('address-button'), 'borderTopColor'), CLEAR);
  assert.equal(await style(page, content('settings'), 'backgroundColor'), PAPER, 'More is bare');
  assert.equal(await style(page, content('settings'), 'color'), INK);
  assert.equal(await style(page, content('visible-not-starred'), 'backgroundColor'), PAPER, 'the star is bare');
  assert.equal(await style(page, content('visible-not-starred'), 'borderTopColor'), CLEAR);
  await page.close();
  const open2 = await open('/conversations?open=1');
  assert.equal(await style(open2, content('reply'), 'backgroundColor'), PAPER, 'the strip is bare');
  assert.equal(await style(open2, content('reply'), 'borderTopColor'), CLEAR);
  assert.equal(await style(open2, content('message-detail-header-reply-btn'), 'backgroundColor'), PAPER, "the thread's Reply is bare");
  assert.equal(await style(open2, content('message-reply'), 'backgroundColor'), PAPER, "a message's Reply is bare");
  await open2.close();
});

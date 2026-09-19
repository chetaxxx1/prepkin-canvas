// Session F's pages (2026-09-19): the discussions index and the profile
// settings, on the fake Canvas pages trimmed from the sandbox.
//
//   PREPKIN_PORT=8812 node --test test/f-pages.test.js

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

const test = require('node:test');
const assert = require('node:assert');
const { FakeServer } = require('./fake-canvas');
const { launch, PORT, SCHOOL_A, BRIDGE } = require('./harness');
const { openPopup } = require('./popup');
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
  await page.goto(`${SCHOOL_A}${path}`, { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(500); // the debounced observer pass
  return page;
};
const classes = (page) => page.evaluate(() => [...document.documentElement.classList].filter((c) => c.startsWith('pk-')).sort());
const style = (page, sel, prop, pseudo) => page.evaluate(([s, p, ps]) => { const el = document.querySelector(s); return el ? getComputedStyle(el, ps || null)[p] : null; }, [sel, prop, pseudo]);
const shows = (page, sel) => page.evaluate((s) => { const el = document.querySelector(s); return !!el && el.getClientRects().length > 0; }, sel);
const rgb = (hex) => { const n = parseInt(hex.slice(1), 16); return `rgb(${(n >> 16) & 255}, ${(n >> 8) & 255}, ${n & 255})`; };

// MARK: - Discussions

test('F1 discussions: the title shows with its controls on its line, Add Discussion and Settings are words, one sheet with counted heads, rows with the tile, the mark and one replies chip, an empty section folded with a Put back', async () => {
  const page = await open('/courses/1/discussion_topics');
  await page.waitForSelector('.ic-discussion-row', { timeout: 6000 });
  const top = await page.evaluate(() => {
    const h1 = document.querySelector('#content h1'); const r = h1.getBoundingClientRect();
    const bar = document.querySelector('.discussions-v2__wrapper > span + div').getBoundingClientRect();
    const words = (id) => { const b = document.getElementById(id); return { bg: getComputedStyle(b).backgroundColor, inner: getComputedStyle(b.querySelector('[class*="baseButton__content"]')).backgroundColor, size: getComputedStyle(b).fontSize, color: getComputedStyle(b).color, glyph: getComputedStyle(b.querySelector('[class*="baseButton__iconWrapper"]')).display }; };
    const filter = document.querySelector('[class*="textInput__facade"]:has(#discussion-filter)');
    return { shown: r.height > 20 && r.width > 50, size: getComputedStyle(h1).fontSize, sameLine: Math.abs((r.top + r.height / 2) - (bar.top + bar.height / 2)) < 12,
      add: words('add_discussion'), settings: words('discussion_settings'),
      filterBg: getComputedStyle(filter).backgroundColor, filterEdge: getComputedStyle(filter).borderTopColor, search: Math.round(document.querySelector('[data-cid="TextInput"]:has(#discussion-search)').getBoundingClientRect().width) };
  });
  assert.ok(top.shown, 'the page has its title'); assert.equal(top.size, '28px');
  assert.ok(top.sameLine, 'the controls line is the title line');
  for (const [name, b] of [['Add Discussion', top.add], ['Settings', top.settings]]) {
    assert.equal(b.bg, 'rgba(0, 0, 0, 0)', `${name}: no ground`); assert.equal(b.inner, 'rgba(0, 0, 0, 0)', `${name}: none on InstUI's span either`);
    assert.equal(b.size, '13px', name); assert.equal(b.color, rgb('#2F6BAA'), `${name}: the link ink`); assert.equal(b.glyph, 'none', `${name}: words only`);
  }
  assert.equal(top.filterBg, 'rgba(0, 0, 0, 0)'); assert.equal(top.filterEdge, 'rgba(0, 0, 0, 0)', 'the filter is words with a chevron');
  assert.equal(top.search, 240);
  // One sheet; the sections sit on it plain; the empty closed section is folded.
  assert.equal(await style(page, '.discussions-v2__wrapper > span:has(> [data-testid="discussion-connected-container"])', 'borderRadius'), '14px', 'the sheet is the card');
  assert.equal(await style(page, '.unpinned-discussions-v2__wrapper', 'backgroundColor'), 'rgba(0, 0, 0, 0)', 'a section has no paper of its own');
  assert.equal(await shows(page, '.closed-for-comments-discussions-v2__wrapper'), false, 'an empty section shows no head');
  const heads = await page.$$eval('.discussions-container__wrapper', (els) => els.map((w) => { const t = w.querySelector('[class*="toggleDetails__summaryText"]'); return { count: t.dataset.pkCount, chip: getComputedStyle(t, '::after').content, size: getComputedStyle(t.querySelector('[class*="-text"]')).fontSize, weight: getComputedStyle(t.querySelector('[class*="-text"]')).fontWeight, ordered: w.querySelector('.recent-activity-text-container') ? getComputedStyle(w.querySelector('.recent-activity-text-container')).display : 'absent', chevron: getComputedStyle(w.querySelector('[class*="toggleDetails__icon"]'), '::before').content }; }));
  assert.deepEqual(heads.map((x) => x.count), ['1', '3', '0'], 'each head counts its rows');
  assert.equal(heads[0].chip, '"1"'); assert.equal(heads[1].chip, '"3"', 'the count is the chip');
  assert.equal(heads[0].size, '14px'); assert.equal(heads[0].weight, '800'); assert.equal(heads[0].chevron, '"⌄"', 'the planner chevron');
  assert.equal(heads[1].ordered, 'none', '"Ordered by Recent Activity" is not said on every head');
  // The rows: our grid, the look's icon on the tile, the mark for an unread
  // topic or unread replies, one chip for the replies, Canvas's words kept.
  const rows = await page.$$eval('.ic-discussion-row', (els) => els.map((r) => { const tile = r.querySelector('.ic-drag-handle-container'); const badge = r.querySelector('.ic-unread-badge'); return { display: getComputedStyle(r.querySelector('.ic-discussion-row-container')).display, radius: getComputedStyle(r).borderRadius, tileW: getComputedStyle(tile).width, icon: getComputedStyle(tile, '::before').maskImage || getComputedStyle(tile, '::before').webkitMaskImage, dot: getComputedStyle(tile, '::after').content, dotColor: getComputedStyle(tile, '::after').backgroundColor, fresh: r.dataset.pkNew ?? null, replies: badge?.dataset.pkReplies ?? null, chip: badge ? getComputedStyle(badge, '::after').content : null, chipBg: badge ? getComputedStyle(badge).backgroundColor : null, words: badge ? badge.textContent.replace(/\s+/g, ' ').trim() : null, title: getComputedStyle(r.querySelector('h3 a')).color, titleSize: getComputedStyle(r.querySelector('h3')).fontSize, last: r.querySelector('.last-reply-at') ? getComputedStyle(r.querySelector('.last-reply-at [class*="-text"]')).fontSize : null }; }));
  assert.equal(rows.length, 4);
  assert.ok(rows.every((r) => r.display === 'grid' && r.radius === '0px' && r.tileW === '26px'), `rows in one sheet on our grid: ${JSON.stringify(rows.map((r) => [r.display, r.radius, r.tileW]))}`);
  assert.ok(rows.every((r) => /url\("data:image\/svg\+xml/.test(r.icon)), 'the tile wears the look\'s discussion icon');
  assert.deepEqual(rows.map((r) => r.dot), ['""', '""', '""', 'none'], 'the mark: an unread topic (rows 1 and 3), unread replies (row 2), none on a read row with nothing new');
  assert.equal(rows[0].dotColor, rgb('#2F6BAA'), 'our mark, never red');
  assert.deepEqual(rows.map((r) => r.fresh), [null, '1', null, null]);
  assert.deepEqual(rows.map((r) => r.replies), [null, '2 replies', null, '1 reply'], 'the replies said once');
  assert.equal(rows[1].chip, '"2 replies"'); assert.equal(rows[1].chipBg, 'rgba(0, 0, 0, 0)', 'Canvas\'s blue pill is gone');
  assert.equal(rows[1].words, '1 unread replies12 total replies2', 'Canvas\'s own words stay for a screen reader');
  assert.equal(rows[0].title, rgb('#1B1F24'), 'the title in the ink, not link blue'); assert.equal(rows[0].titleSize, '14px'); assert.equal(rows[1].last, '12px');
  // The receipt lists the folded drawing; Put back brings the section, its drawing and its edge back.
  await page.bringToFront();
  const popup = await openPopup(h);
  await popup.waitFor('#receipt li');
  const receipt = await popup.evaluate(`[...document.querySelectorAll('#receipt li')].map((li) => li.textContent.trim())`);
  await popup.close();
  assert.ok(receipt.some((r) => /drawings for an empty discussion list/.test(r)), `on the receipt: ${receipt.join(' | ')}`);
  await h.setStorage({ putBack: { 'disc-empty': true } }); await page.waitForTimeout(400);
  assert.ok((await classes(page)).includes('pk-back-disc-empty'));
  assert.equal(await shows(page, '.closed-for-comments-discussions-v2__wrapper'), true, 'Put back: the empty section is back');
  assert.equal(await shows(page, '.discussions-v2__container-image img'), true, 'and its drawing');
  await h.setStorage({ putBack: {} });
  await page.close();
});

test('F1 discussions with nothing in them: no sheet, one quiet line, the drawing and the duplicate link folded', async () => {
  const page = await open('/courses/1/discussion_topics?empty=1');
  await page.waitForSelector('.discussions-v2__container-image', { timeout: 6000, state: 'attached' });
  assert.equal(await style(page, '.discussions-v2__wrapper > span:has(> [data-testid="discussion-connected-container"])', 'borderTopWidth'), '0px', 'no sheet around one line');
  assert.equal(await shows(page, '.closed-for-comments-discussions-v2__wrapper'), false, 'the closed section goes');
  assert.equal(await shows(page, '.unpinned-discussions-v2__wrapper [class*="toggleDetails__summary"]'), false, 'and the open one\'s head');
  assert.equal(await shows(page, '.discussions-v2__container-image img'), false, 'no cartoon');
  assert.equal(await shows(page, '.discussions-v2__container-image a'), false, 'no second Add Discussion');
  const line = await page.evaluate(() => { const t = document.querySelector('.discussions-v2__container-image [class*="-text"]'); return { words: t.textContent.trim(), said: getComputedStyle(t, '::after').content, size: getComputedStyle(t, '::after').fontSize, edge: getComputedStyle(t.closest('.discussions-v2__container-image')).borderTopStyle }; });
  assert.equal(line.words, 'There are no discussions to show in this section', 'Canvas\'s words stay');
  assert.equal(line.said, '"No discussions yet"'); assert.equal(line.size, '13px'); assert.equal(line.edge, 'none', 'no dashed box');
  await page.close();
});

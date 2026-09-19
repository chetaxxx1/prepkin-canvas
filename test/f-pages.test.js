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

// MARK: - Settings

test('F2 settings: one column of rows (label, value right, the hint under the label), sections as group heads, New Access Token as words, the feature table with no band, the contact rows on hairlines; edit mode keeps every control', async () => {
  const page = await open('/profile/settings');
  await page.waitForSelector('.profile_table', { timeout: 6000 });
  const rows = await page.$$eval('.profile_table > tbody > tr', (els) => els.map((tr) => {
    const cs = getComputedStyle(tr); const label = tr.querySelector('th label, th.nobr'); const value = tr.querySelector('td > .display_data'); const hint = tr.querySelector('td > .data_description');
    const r = (el) => el ? el.getBoundingClientRect() : null;
    return { display: cs.display, shown: tr.getClientRects().length > 0, style: tr.getAttribute('style'), label: label ? { size: getComputedStyle(label).fontSize, weight: getComputedStyle(label).fontWeight, left: Math.round(r(label).left) } : null,
      value: value ? { right: Math.round(r(value).right), size: getComputedStyle(value).fontSize } : null, hint: hint ? { size: getComputedStyle(hint).fontSize, color: getComputedStyle(hint).color, top: Math.round(r(hint).top), left: Math.round(r(hint).left), br: getComputedStyle(hint.querySelector('br')).display } : null, rowRight: Math.round(r(tr).right), rowTop: Math.round(r(tr).top), edge: cs.borderBottomWidth };
  }));
  const shown = rows.filter((x) => x.shown);
  assert.equal(shown.length, 4, `four rows show while Canvas shows the values (Full Name, Display Name, Language, Time Zone): ${rows.map((x) => `${x.display}/${x.shown}`).join(' ')}`);
  assert.ok(rows.filter((x) => /display: none/.test(x.style ?? '')).every((x) => x.display === 'none'), 'a row Canvas hides stays hidden');
  for (const x of shown) {
    assert.equal(x.display, 'grid'); assert.equal(x.edge, '1px', 'a hairline under each row');
    assert.equal(x.label.size, '14px'); assert.equal(x.label.weight, '700', 'the label bold');
    assert.ok(x.value.right >= x.rowRight - 2, `the value at the right edge (${x.value.right} vs ${x.rowRight})`);
  }
  assert.equal(shown[0].hint.size, '12px'); assert.equal(shown[0].hint.color, rgb('#454B54'), 'the hint quiet');
  assert.equal(shown[0].hint.left, shown[0].label.left, 'the hint under the label, not the value'); assert.ok(shown[0].hint.top > shown[0].rowTop + 20);
  assert.equal(shown[0].hint.br, 'none', 'no blank first line');
  // Sections: 14/800 on a hairline; the paragraph under one a quiet 12px line; the checkbox line a row with the box right.
  const heads = await page.$$eval('#content h2', (els) => els.map((h) => ({ text: h.textContent.trim(), size: getComputedStyle(h).fontSize, weight: getComputedStyle(h).fontWeight, edge: getComputedStyle(h).borderBottomWidth })));
  for (const hd of heads.filter((x) => x.text !== 'User')) { assert.equal(hd.size, '14px', hd.text); assert.equal(hd.weight, '800', hd.text); assert.equal(hd.edge, '1px', hd.text); }
  assert.equal(heads.find((x) => x.text === 'User').size, '12px', 'the feature table\'s own heading is a quiet line');
  assert.equal(await style(page, '#content h2 + p', 'fontSize'), '12px'); assert.equal(await style(page, '#no_approved_integrations', 'fontSize'), '12px');
  const box = await page.evaluate(() => { const p = document.querySelector('p:has(> #show_user_services)'); const i = p.querySelector('input'); const l = p.querySelector('label'); return { display: getComputedStyle(p).display, boxRight: Math.round(i.getBoundingClientRect().right), pRight: Math.round(p.getBoundingClientRect().right), labelLeft: Math.round(l.getBoundingClientRect().left), pLeft: Math.round(p.getBoundingClientRect().left) }; });
  assert.equal(box.display, 'flex'); assert.ok(box.boxRight >= box.pRight - 20 && box.labelLeft <= box.pLeft + 2, `the words left, the box right: ${JSON.stringify(box)}`);
  // New Access Token: a Canvas primary that is not a submit, as words with its plus.
  const token = await page.evaluate(() => { const a = document.querySelector('.add_access_token_link'); const cs = getComputedStyle(a); return { bg: cs.backgroundColor, edge: cs.borderTopColor, color: cs.color, size: cs.fontSize, weight: cs.fontWeight }; });
  assert.equal(token.bg, 'rgba(0, 0, 0, 0)'); assert.equal(token.edge, 'rgba(0, 0, 0, 0)'); assert.equal(token.color, rgb('#2F6BAA')); assert.equal(token.size, '13px'); assert.equal(token.weight, '700');
  // The feature table: the filter as words, the search as our field, no header band, the state at the right, the flag's name in the row's type.
  const ff = await page.evaluate(() => { const w = document.querySelector('.feature-flag-wrapper'); const facade = w.querySelector('[class*="textInput__facade"]:has(input[role="combobox"])'); const head = w.querySelector('thead th'); const last = w.querySelector('tbody tr td:last-child'); const btn = last.querySelector('button');
    return { filterBg: getComputedStyle(facade).backgroundColor, filterEdge: getComputedStyle(facade).borderTopColor, search: Math.round(w.querySelector('label[data-cid="TextInput"]:has(input[type="search"])').getBoundingClientRect().width), headBg: getComputedStyle(head).backgroundColor, headLabel: getComputedStyle(head.querySelector('p')).fontSize, headEdge: getComputedStyle(head).borderBottomWidth, name: getComputedStyle(w.querySelector('[class*="toggleDetails__summaryText"]')).fontSize, nameWeight: getComputedStyle(w.querySelector('[class*="toggleDetails__summaryText"]')).fontWeight, stateRight: Math.round(btn.getBoundingClientRect().right), cellRight: Math.round(last.getBoundingClientRect().right), rowH: Math.round(w.querySelector('tbody tr').getBoundingClientRect().height) }; });
  assert.equal(ff.filterBg, 'rgba(0, 0, 0, 0)'); assert.equal(ff.filterEdge, 'rgba(0, 0, 0, 0)'); assert.equal(ff.search, 240);
  assert.equal(ff.headBg, 'rgba(0, 0, 0, 0)', 'no header band'); assert.equal(ff.headLabel, '12px'); assert.equal(ff.headEdge, '1px');
  assert.equal(ff.name, '14px'); assert.equal(ff.nameWeight, '700'); assert.ok(ff.stateRight >= ff.cellRight - 2, `the state control at the right (${ff.stateRight} vs ${ff.cellRight})`); assert.ok(ff.rowH >= 44);
  // Clear is words beside the search; a flag's state control is bare, its svg 16px in the quiet ink, mint when on; the chevron ours.
  const words = await page.evaluate(() => { const clear = document.querySelector('.feature-flag-wrapper [class*="view-flexItem"] > [data-cid="BaseButton Button"]'); const rows = [...document.querySelectorAll('.feature-flag-wrapper tbody tr')].map((tr) => { const d = tr.querySelector('td:last-child div[title]'); const b = d.querySelector('button'); const svg = d.querySelector('svg'); return { title: d.getAttribute('title'), bg: getComputedStyle(b).backgroundColor, inner: getComputedStyle(b.querySelector('[class*="baseButton__content"]')).backgroundColor, edge: getComputedStyle(b).borderTopColor, svgW: getComputedStyle(svg).width, svgColor: getComputedStyle(svg).color, chevron: getComputedStyle(tr.querySelector('[class*="toggleDetails__icon"]'), '::before').content }; });
    return { clearBg: getComputedStyle(clear).backgroundColor, clearInner: getComputedStyle(clear.querySelector('[class*="baseButton__content"]')).backgroundColor, clearSize: getComputedStyle(clear).fontSize, clearColor: getComputedStyle(clear).color, rows }; });
  assert.equal(words.clearBg, 'rgba(0, 0, 0, 0)'); assert.equal(words.clearInner, 'rgba(0, 0, 0, 0)', 'Clear: no ground on InstUI\'s span either'); assert.equal(words.clearSize, '13px'); assert.equal(words.clearColor, rgb('#2F6BAA'));
  assert.deepEqual(words.rows.map((r) => r.title), ['Disabled', 'Enabled']);
  for (const r of words.rows) { assert.equal(r.bg, 'rgba(0, 0, 0, 0)', 'the state control is bare'); assert.equal(r.inner, 'rgba(0, 0, 0, 0)'); assert.equal(r.edge, 'rgba(0, 0, 0, 0)'); assert.equal(r.svgW, '16px'); assert.equal(r.chevron, '"›"'); }
  assert.equal(words.rows[0].svgColor, rgb('#454B54'), 'off: the quiet ink'); assert.equal(words.rows[1].svgColor, rgb('#51CFA0'), 'on: the modules\' mint');
  // The right column: a group head, the address a 44px row with its star at the right, the add lines in the link ink, no header band.
  const side = await page.evaluate(() => { const h2 = document.querySelector('#right-side > h2'); const th = document.querySelector('#right-side .channel_list thead th'); const row = document.querySelector('#right-side #channel_3'); const star = row.querySelector('.icon-star'); const add = document.querySelector('#right-side .add_email_link');
    return { head: getComputedStyle(h2).fontSize, headWeight: getComputedStyle(h2).fontWeight, thBg: getComputedStyle(th).backgroundColor, thSize: getComputedStyle(th).fontSize, rowH: Math.round(row.getBoundingClientRect().height), path: getComputedStyle(row.querySelector('.path')).fontSize, starRight: Math.round(star.getBoundingClientRect().right), rowRight: Math.round(row.getBoundingClientRect().right), add: getComputedStyle(add).color, addSize: getComputedStyle(add).fontSize, addLeft: Math.round(add.getBoundingClientRect().left), rowLeft: Math.round(row.getBoundingClientRect().left) }; });
  assert.equal(side.head, '14px'); assert.equal(side.headWeight, '800'); assert.equal(side.thBg, 'rgba(0, 0, 0, 0)'); assert.equal(side.thSize, '12px');
  assert.ok(side.rowH >= 44, `a 44px row (${side.rowH})`); assert.equal(side.path, '14px'); assert.ok(side.starRight >= side.rowRight - 4, `the star at the right (${side.starRight} vs ${side.rowRight})`);
  assert.equal(side.add, rgb('#2F6BAA')); assert.equal(side.addSize, '13px'); assert.ok(side.addLeft <= side.rowLeft + 2, 'the add line starts at the left, not centred');
  // Edit Settings and Download Submissions: words at the left under a hairline, their glyphs gone (the course home's sidebar shape).
  const wide = await page.$$eval('#right-side .btn.button-sidebar-wide', (els) => els.map((a) => { const cs = getComputedStyle(a); const box = a.parentElement; const range = document.createRange(); range.selectNodeContents(a); const text = range.getBoundingClientRect(); return { bg: cs.backgroundColor, edge: cs.borderTopColor, size: cs.fontSize, color: cs.color, glyph: getComputedStyle(a.querySelector('i')).display, textLeft: Math.round(text.left), boxLeft: Math.round(box.getBoundingClientRect().left), boxTop: getComputedStyle(box).borderTopWidth, hr: getComputedStyle(box.querySelector('hr')).display }; }));
  assert.equal(wide.length, 2);
  for (const w of wide) { assert.equal(w.bg, 'rgba(0, 0, 0, 0)'); assert.equal(w.edge, 'rgba(0, 0, 0, 0)'); assert.equal(w.size, '13px'); assert.equal(w.color, rgb('#2F6BAA')); assert.equal(w.glyph, 'none', 'words only'); assert.ok(Math.abs(w.textLeft - w.boxLeft) <= 4, `the words start at the left, not centred (${w.textLeft} vs ${w.boxLeft})`); assert.equal(w.boxTop, '1px', 'a hairline above the pair'); assert.equal(w.hr, 'none'); }
  // Edit mode, as Canvas does it: the table takes `editing`, jQuery shows the
  // edit-only rows. The fields sit at the right in our field shape, the
  // checkbox line is a row, the password field is untouched but for paper
  // and edge, the empty "more options" row goes, Cancel and Update stay.
  await page.evaluate(() => { document.querySelector('.profile_table').classList.add('editing'); document.querySelectorAll('.profile_table .edit_data_row').forEach((tr) => { tr.style.display = ''; }); });
  await page.waitForTimeout(300);
  const edit = await page.evaluate(() => { const name = document.getElementById('user_name'); const cs = getComputedStyle(name); const row = name.closest('tr');
    const pw = document.getElementById('old_password'); const pwRow = pw.closest('tr');
    return { field: { right: Math.round(name.getBoundingClientRect().right), rowRight: Math.round(row.getBoundingClientRect().right), bg: cs.backgroundColor, radius: cs.borderRadius, h: cs.height, display: cs.display, text: cs.textAlign }, hint: Math.round(document.getElementById('hints_name').getBoundingClientRect().left), labelLeft: Math.round(row.querySelector('label').getBoundingClientRect().left),
      more: getComputedStyle(document.querySelector('.more_options_link_row')).display, pwRow: getComputedStyle(pwRow).display, pwType: pw.type, pwDisplay: getComputedStyle(pw).display,
      news: (() => { const l = document.querySelector('label[for="user_subscribe_to_emails"]'); const i = l.querySelector('input[type="checkbox"]'); return { display: getComputedStyle(l).display, boxRight: Math.round(i.getBoundingClientRect().right), labelRight: Math.round(l.getBoundingClientRect().right) }; })(),
      actions: getComputedStyle(document.querySelector('.profile_table .form-actions')).display, submit: getComputedStyle(document.querySelector('.profile_table .form-actions [type="submit"]')).display, cancel: getComputedStyle(document.querySelector('.profile_table .cancel_button')).backgroundColor }; });
  assert.ok(edit.field.right >= edit.field.rowRight - 2, 'the field at the right'); assert.equal(edit.field.bg, rgb('#FFFFFF')); assert.equal(edit.field.radius, '10px'); assert.equal(edit.field.h, '32px'); assert.equal(edit.field.text, 'left');
  assert.notEqual(edit.field.display, 'none', 'the field shows'); assert.equal(edit.hint, edit.labelLeft, 'the hint stays under the label');
  assert.equal(edit.more, 'none', 'the empty more-options row goes'); assert.equal(edit.pwRow, 'none', 'the password rows stay hidden until asked for'); assert.equal(edit.pwType, 'password');
  assert.equal(edit.news.display, 'flex'); assert.ok(edit.news.boxRight >= edit.news.labelRight - 2, 'the newsletter box at the right');
  assert.equal(edit.actions, 'flex'); assert.notEqual(edit.submit, 'none', 'Update Settings is Canvas\'s submit, untouched'); assert.equal(edit.cancel, rgb('#FFFFFF'), 'Cancel on the paper');
  // The password field, when asked for: the paper and an edge, nothing else of ours.
  await page.evaluate(() => { document.querySelectorAll('.profile_table .change_password_row').forEach((tr) => { tr.style.display = ''; }); });
  await page.waitForTimeout(200);
  const pw = await page.evaluate(() => { const i = document.getElementById('old_password'); const cs = getComputedStyle(i); return { display: cs.display, visibility: cs.visibility, pointer: cs.pointerEvents, bg: cs.backgroundColor, edge: cs.borderTopColor, type: i.type, rowDisplay: getComputedStyle(i.closest('tr')).display }; });
  assert.equal(pw.rowDisplay, 'grid'); assert.notEqual(pw.display, 'none'); assert.equal(pw.visibility, 'visible'); assert.equal(pw.pointer, 'auto'); assert.equal(pw.bg, rgb('#FFFFFF'));
  // The edit box's edge is the ink at 26% over its paper (on Newsprint about
  // #C4C5C6), so a field reads as a field: on the rule alone the form barely
  // looked editable (the tour of 2026-09-19).
  assert.match(pw.edge, /^color\(srgb 0\.7[5-8]\d* 0\.7[5-8]\d* 0\.7[6-9]\d*\)$/, `the edit box's edge is the ink at 26%: ${pw.edge}`); assert.equal(pw.type, 'password');
  await page.close();
});

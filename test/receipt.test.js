// The Receipt page skin, in a real browser on the fake Canvas pages.
//
//   node --test test/receipt.test.js
//
// Row names follow design/canvas-skin/EXTENSION-FEATURES.md (R1–R9).

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

const test = require('node:test');
const assert = require('node:assert');
const { FakeServer } = require('./fake-canvas');
const { launch, SCHOOL_A, BRIDGE } = require('./harness');
const { openPopup } = require('./popup');
const S = require('./scenarios');

let server, h;
const control = (p, body) => fetch(`${BRIDGE}/__${p}`, { method: 'POST', body: JSON.stringify(body ?? {}) }).then((r) => r.json());
const SKIN = (over = {}) => ({ dark: false, cards: true, mascot: true, focusMinutes: 25, ...over });

test.before(async () => {
  server = await new FakeServer().start(8443);
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

// DOM only: 'load' occasionally waits on a straggling asset for tens of
// seconds, and nothing here depends on it. The observer pass is debounced.
const open = async (path, { waitUntil = 'domcontentloaded' } = {}) => {
  const page = await h.context.newPage();
  await page.goto(`${SCHOOL_A}${path}`, { waitUntil });
  await page.waitForTimeout(500); // the debounced observer pass
  return page;
};
const classes = (page) => page.evaluate(() => [...document.documentElement.classList].filter((c) => c.startsWith('pk-')).sort());
const style = (page, sel, prop) => page.evaluate(([s, p]) => { const el = document.querySelector(s); return el ? getComputedStyle(el)[p] : null; }, [sel, prop]);
const rgb = (hex) => { const n = parseInt(hex.slice(1), 16); return `rgb(${(n >> 16) & 255}, ${(n >> 8) & 255}, ${n & 255})`; };

// MARK: - R1 / R2: on before paint, off when it must be

test('R1 the classes are on <html> by DOMContentLoaded, so a dark paper never flashes white', async () => {
  await h.setStorage({ skin: SKIN({ dark: true }) });
  const page = await h.context.newPage();
  await page.goto(`${SCHOOL_A}/`, { waitUntil: 'domcontentloaded' });
  const early = await classes(page);
  assert.ok(early.includes('pk-on') && early.includes('pk-dark') && early.includes('pk-paper-carbon'), early.join(' '));
  assert.equal(await style(page, 'body', 'backgroundColor'), rgb('#17191D'));
  await page.close();
});

test('R2 High Contrast, New Quizzes and the widget dashboard switch the skin off, with a reason', async () => {
  for (const [q, reason] of [['?hc=1', /Your school has High Contrast/], ['?nq=1', /New Quizzes/], ['?wd=1', /new dashboard/]]) {
    const page = await open(`/${q}`);
    assert.deepEqual(await classes(page), [], `${q} left classes on`);
    assert.equal(await style(page, 'body', 'backgroundColor'), 'rgba(0, 0, 0, 0)', 'stock Canvas');
    await page.bringToFront();
    const popup = await openPopup(h);
    assert.match(await popup.waitFor('#receipt-off', /./), reason);
    await popup.close();
    await page.close();
  }
  const page = await h.context.newPage();
  await page.emulateMedia({ forcedColors: 'active' });
  await page.goto(`${SCHOOL_A}/`);
  await page.waitForTimeout(350);
  assert.deepEqual(await classes(page), [], 'OS forced colours');
  await page.close();
});

test('R2 the sign-in page is the school\'s, in every mode', async () => {
  await h.setStorage({ skin: SKIN({ dark: true }), wallet: { coins: 0, owned: ['classic'], wearing: 'classic' } });
  const page = await h.context.newPage();
  await page.goto(`${SCHOOL_A}/login/canvas`, { waitUntil: 'domcontentloaded' });
  assert.deepEqual(await classes(page), [], 'nothing on before paint');
  await page.waitForTimeout(400);
  assert.deepEqual(await classes(page), [], 'nothing on after the DOM is read');
  assert.equal(await page.$('#prepkin-buddy'), null, 'no buddy on a sign-in page');
  await page.close();
});

test('R2 off means Canvas, unchanged: no classes, no inline style, no line on the cards', async () => {
  await h.setStorage({ skin: SKIN({ cards: false, dark: true }) });
  const page = await open('/');
  assert.deepEqual(await classes(page), []);
  assert.equal(await page.evaluate(() => document.documentElement.getAttribute('style')), null);
  assert.equal(await page.$('.pk-card-due'), null);
  assert.ok(await page.$('#prepkin-buddy'), 'the buddy is its own switch');
  await page.close();
});

// MARK: - R3 / R5: the dashboard

test('R3 dashboard: paper, thin hero, one To Do, every Coming Up row, one logo — and what is left alone', async () => {
  const page = await open('/');
  assert.equal(await style(page, 'body', 'backgroundColor'), rgb('#F7F6F3'), 'Newsprint');
  assert.equal(await style(page, '.ic-DashboardCard__header_hero', 'height'), '72px');
  assert.equal(await style(page, '.ic-DashboardCard__header_hero', 'opacity'), '0.6', 'the accessibility preference is never written');
  assert.equal(await style(page, '.ic-DashboardCard__header_hero', 'backgroundColor'), 'rgb(255, 111, 97)', 'the course colour stays, on the band');
  assert.equal(await style(page, '.ic-DashboardCard__header-title span', 'color'), rgb('#1B1F24'), 'the name is ink, one text stack under the band');
  assert.equal(await style(page, 'ul.right-side-list.to-do-list', 'display'), 'none', 'the second To Do list');
  // Canvas's own To Do and Coming Up stay open on their own; under our rail
  // they fold to one line together, and Coming Up shows every row once opened.
  if (await page.$('#pk-week')) {
    assert.equal(await style(page, '.Sidebar__TodoListContainer', 'display'), 'none', 'replaced by the rail');
    assert.equal(await style(page, '.events_list.coming_up', 'display'), 'none', 'Coming Up goes with it');
    assert.equal(await style(page, '#right-side h2.todo-list-header', 'display'), 'none', 'no stray heading left behind');
    assert.equal(await page.$('#pk-todo-fold'), null, 'no fold line to click: the receipt has the Put back');
  } else {
    assert.equal(await style(page, '.Sidebar__TodoListContainer', 'display'), 'block');
    assert.equal(await style(page, '.events_list.coming_up li.event[style*="display: none"]', 'display'), 'list-item', 'Coming Up rows');
  }
  assert.equal(await style(page, '.events_list.coming_up a.more_link', 'display'), 'none');
  assert.equal(await style(page, '.events_list.recent_feedback li.event[style*="display: none"]', 'display'), 'none', 'Recent Feedback is never touched');
  assert.equal(await style(page, '.events_list.recent_feedback a.more_link', 'display'), 'inline');
  assert.equal(await style(page, '.ic-app-header__logomark-container', 'display'), 'none', 'the header copy of the mark');
  assert.equal(await style(page, '.ic-sidebar-logo', 'display'), 'block', 'the school sidebar logo stays');
  assert.equal(await style(page, '.ic-DashboardCard', 'boxShadow'), 'none');
  assert.equal(await page.$eval('.ic-DashboardCard__action-badge', (el) => [el.textContent, getComputedStyle(el).backgroundColor].join(' ')), '0 rgb(81, 207, 160)', 'the badge keeps its count, on mint, on the icon corner');
  await page.close();
});

test('R3 modules and the course nav: sticky header, due column, four tabs dimmed, Grades not', async () => {
  const page = await open('/courses/1/modules');
  assert.equal(await style(page, '.context_module .ig-header.header', 'position'), 'sticky');
  assert.equal(await style(page, '.context_module .due_date_display', 'textAlign'), 'right');
  assert.equal(await style(page, '.context_module .due_date_display', 'minWidth'), '136px');
  assert.equal(await style(page, '.context_module .due_date_display', 'display'), 'inline-block');
  for (const tab of ['files', 'outcomes', 'conferences', 'collaborations']) {
    assert.equal(await style(page, `#section-tabs a.${tab}`, 'opacity'), '0.58', tab);
  }
  assert.equal(await style(page, '#section-tabs a.grades', 'opacity'), '1');
  assert.equal(await style(page, '#section-tabs a.modules', 'display'), 'inline', 'nothing hidden, nothing reordered');
  assert.equal(await style(page, '.ig-row .ig-title', 'color'), rgb('#1B1F24'), 'row titles take the paper ink');
  await page.close();
});

test('R3 assignment in dark: Word ink repaired, teacher colour kept, submit button untouched', async () => {
  const before = await (async () => {
    await h.setStorage({ skin: SKIN({ cards: false }) });
    const p = await open('/courses/1/assignments/11');
    const b = await p.evaluate(() => { const s = getComputedStyle(document.getElementById('assignment_submit')); return [s.backgroundColor, s.color, s.display, s.opacity]; });
    await p.close();
    return b;
  })();
  await h.setStorage({ skin: SKIN({ dark: true }) });
  const page = await open('/courses/1/assignments/11');
  assert.equal(await style(page, '.user_content [style*="color: #000000"]', 'color'), rgb('#E6E8EA'), 'black Word ink becomes the paper\'s ink');
  assert.equal(await style(page, '.user_content [style*="color: windowtext"]', 'color'), rgb('#E6E8EA'));
  assert.equal(await style(page, '.user_content [style*="background-color:#ffff00"]', 'backgroundColor'), 'rgb(255, 255, 0)', 'a highlight is not an ink');
  assert.equal(await style(page, '.user_content td[style*="color: #c00000"]', 'color'), 'rgb(192, 0, 0)', 'a colour the teacher chose stays');
  const after = await page.evaluate(() => { const s = getComputedStyle(document.getElementById('assignment_submit')); return [s.backgroundColor, s.color, s.display, s.opacity]; });
  assert.deepEqual(after, before, 'no property on a button, in any mode');
  await page.close();
});

// MARK: - R7: papers and Looks

test('R7 a Look moves the paper and nothing else; dark is free; Night Shift no longer forces dark', async () => {
  const cases = [
    ['classic', false, '#F7F6F3'], ['classic', true, '#17191D'],
    ['coastal', false, '#EDF3F8'], ['coastal', true, '#161B22'],
    ['blush', false, '#F8EEF0'], ['matcha', true, '#161C18'],
    ['nightshift', false, '#F4F6F8'], ['nightshift', true, '#161B22'],
  ];
  for (const [look, dark, paper] of cases) {
    await h.setStorage({ skin: SKIN({ dark }), wallet: { coins: 900, owned: ['classic', look], wearing: look } });
    const page = await open('/');
    assert.equal(await style(page, 'body', 'backgroundColor'), rgb(paper), `${look} ${dark ? 'dark' : 'light'}`);
    const paper2 = { '#F7F6F3': '#FFFFFF', '#17191D': '#1E2126', '#F4F6F8': '#FFFFFF', '#161B22': '#1C232C', '#EDF3F8': '#F6F9FC', '#F8EEF0': '#FDF7F8', '#161C18': '#1D2520' }[paper];
    assert.equal(await style(page, '.ic-DashboardCard', 'backgroundColor'), rgb(paper2), 'the card header block follows the paper, never stays white');
    assert.equal(await style(page, '.ic-DashboardCard__header_hero', 'backgroundColor'), 'rgb(255, 111, 97)', 'course colour never moves off the band');
    assert.equal(await page.evaluate(() => document.documentElement.getAttribute('style')), null, 'never inline');
    const has = await classes(page);
    assert.equal(has.includes('pk-dark'), dark, `${look}: dark is the switch, not the Look`);
    await page.close();
  }
});

test('R7 a theme brings its accent, its texture and a wash over the course band, never the band itself', async () => {
  await h.setStorage({ skin: SKIN(), wallet: { coins: 900, owned: ['classic', 'blush'], wearing: 'blush' } });
  const page = await open('/');
  assert.match(await style(page, 'body', 'backgroundImage'), /^url\("data:image\/svg\+xml/, 'the texture, inline, no request');
  assert.match(await style(page, '.ic-DashboardCard__header_hero', 'backgroundImage'), /linear-gradient/, 'the wash');
  assert.equal(await style(page, '.ic-DashboardCard__header_hero', 'backgroundColor'), 'rgb(255, 111, 97)', 'the course colour underneath');
  assert.equal(await style(page, '.ic-DashboardCard__header_hero', 'opacity'), '0.6');
  assert.equal(await page.evaluate(() => getComputedStyle(document.documentElement).getPropertyValue('--pk-mark').trim()), '#B04A6E', 'links take the accent');
  await h.setStorage({ wallet: { coins: 900, owned: ['classic'], wearing: 'classic' } });
  await page.waitForTimeout(400);
  assert.equal(await style(page, 'body', 'backgroundImage'), 'none', 'Classic has no texture');
  await page.close();
});

test('R11 an image theme: the wallpaper under a paper wash, four banners across the cards, the course colour still a strip', async () => {
  await h.setStorage({ skin: SKIN(), wallet: { coins: 900, owned: ['classic', 'graffiti'], wearing: 'graffiti' } });
  const page = await open('/');
  const bodyBg = await style(page, 'body', 'backgroundImage');
  assert.match(bodyBg, /linear-gradient\(rgba\(247, 246, 243, 0\.82\)/, 'the paper wash');
  assert.match(bodyBg, /chrome-extension:\/\/[a-z0-9-]+\/art\/(graffiti\/wallpaper\.webp|_placeholder\/wallpaper\.svg)/, 'the wallpaper, from inside the extension');
  assert.equal(await style(page, '#content', 'backgroundColor'), 'rgba(0, 0, 0, 0)', 'the columns let the wallpaper through');
  // The sticky bar paints the page's whole ground, not a second wash on top of
  // it. This line used to assert the wash as a flat colour, which is the bug
  // R22 now guards: the body had already laid that wash over the wallpaper, so
  // the bar came out a coat paler than the page. It paints both layers now.
  assert.equal(await style(page, '#dashboard_header_container .ic-Dashboard-header__layout', 'backgroundColor'), 'rgba(0, 0, 0, 0)', 'no flat wash on the sticky bar');
  assert.equal(await style(page, '#dashboard_header_container .ic-Dashboard-header__layout', 'backgroundImage'), bodyBg, 'it paints what the page paints');
  const heroes = await page.$$eval('.ic-DashboardCard__header_hero', (els) => els.map((e) => { const s = getComputedStyle(e); return [s.backgroundImage.match(/card-(\d)/)?.[1], s.backgroundColor, s.height, s.backgroundSize]; }));
  assert.deepEqual(heroes.map((x) => x[0]), ['1', '2'], 'banners rotate across cards');
  assert.equal(heroes[0][1], 'rgb(255, 111, 97)', 'the course colour is still there, as the strip');
  assert.equal(heroes[0][2], '146px', "Canvas's own height, so the art reads as a picture");
  assert.match(heroes[0][3], /auto 140px/, 'the banner leaves the 6px strip');
  const ok = await page.evaluate(() => performance.getEntriesByType('resource').every((r) => !/^https?:/.test(r.name) || r.name.startsWith(location.origin)));
  assert.ok(ok, 'no request left the laptop for the art');
  await page.close();
});

test('R12 compact pages: the same cards, less air, and a Put back still wins', async () => {
  await h.setStorage({ skin: SKIN({ dense: true }) });
  const page = await open('/');
  assert.ok((await classes(page)).includes('pk-dense'));
  assert.equal(await style(page, '.ic-DashboardCard', 'width'), '220px');
  assert.equal(await style(page, '.ic-DashboardCard', 'margin'), '20px 0px 0px 20px', 'the card keeps its top-left margin, so it never slides under the sticky header');
  assert.equal(await page.$$eval('.ic-DashboardCard', (els) => els.length), 2, 'nothing hidden');
  await h.setStorage({ skin: SKIN({ dense: false }) });
  await page.waitForTimeout(400);
  assert.ok(!(await classes(page)).includes('pk-dense'), 'off again without a reload');
  await page.close();
});

test('R13 the left menu wears the theme rail; an image theme shows its wall through it; Put back gives Canvas its own back', async () => {
  const page = await open('/');
  assert.equal(await style(page, '#header', 'backgroundColor'), 'rgb(47, 74, 102)', 'Classic Cream, light');
  assert.equal(await style(page, '.ic-app-header__logomark-container', 'backgroundColor'), 'rgb(47, 74, 102)');
  await h.setStorage({ skin: SKIN({ dark: true }) }); await page.waitForTimeout(400);
  assert.equal(await style(page, '#header', 'backgroundColor'), 'rgb(27, 39, 51)', 'dark rail in dark');
  await h.setStorage({ skin: SKIN(), wallet: { coins: 0, owned: ['graffiti'], wearing: 'graffiti' } }); await page.waitForTimeout(400);
  assert.match(await style(page, '#header', 'backgroundImage'), /linear-gradient\(rgba\(35, 18, 38, 0\.74\).*wallpaper/, 'the wall under a wash');
  assert.equal(await style(page, '.ic-app-header__main-navigation', 'backgroundColor'), 'rgba(0, 0, 0, 0)');
  assert.equal(await page.$$eval('.ic-app-header__menu-list-item', (els) => els.length), 2, 'every tab still there');
  await h.setStorage({ putBack: { rail: true } }); await page.waitForTimeout(400);
  assert.ok((await classes(page)).includes('pk-back-rail'));
  assert.equal(await style(page, '#header', 'backgroundImage'), 'none');
  assert.notEqual(await style(page, '#header', 'backgroundColor'), 'rgb(47, 74, 102)', 'Canvas paints its own rail again');
  await h.setStorage({ putBack: {} });
  await page.close();
});

test('R14 the grade pill is opt-in, reads the synced score, and Put back hides it', async () => {
  const page = await open('/');
  assert.equal(await page.$('.pk-card-grade'), null, 'off by default');
  await h.setStorage({ skin: SKIN({ cardGrades: true }) }); await page.waitForTimeout(500);
  const pills = await page.$$eval('.ic-DashboardCard', (els) => els.map((e) => e.querySelector('.pk-card-grade')?.textContent ?? null));
  assert.equal(pills[0], '88.5%', 'AP Physics has a score');
  assert.equal(pills[1], null, 'English has none, so no pill');
  assert.ok(await page.$('.ic-DashboardCard__action-container > .pk-card-grade:last-child'), 'the grade ends the action row');
  await h.setStorage({ skin: SKIN({ cardGrades: false }) }); await page.waitForTimeout(500);
  assert.equal(await page.$('.pk-card-grade'), null, 'its receipt row turns it off again');
  await page.close();
});

test('R15 a banner picked for a course outranks the rotation and follows storage', async () => {
  await h.setStorage({ wallet: { coins: 0, owned: ['graffiti'], wearing: 'graffiti' } });
  const page = await open('/');
  const heroArt = () => page.$$eval('.ic-DashboardCard__header_hero', (els) => els.map((e) => getComputedStyle(e).backgroundImage.match(/card-(\d)/)?.[1]));
  assert.deepEqual(await heroArt(), ['1', '2'], 'rotation by position');
  await h.setStorage({ banners: { 1: 3 } }); await page.waitForTimeout(500);
  assert.deepEqual(await heroArt(), ['3', '2'], 'Physics wears banner three');
  assert.ok(await page.$('.ic-DashboardCard.pk-banner-3'));
  await h.setStorage({ banners: {} }); await page.waitForTimeout(500);
  assert.deepEqual(await heroArt(), ['1', '2'], 'cleared, back to turns');
  await page.close();
});

test('R16 everywhere: calendar, the courses table and a quiz page take the paper, the rules and the mark; buttons and event colours do not', async () => {
  await h.setStorage({ skin: SKIN({ dark: true }) });
  const paper2 = 'rgb(30, 33, 38)', sunk = 'rgb(18, 20, 23)', ink = 'rgb(230, 232, 234)', link = 'rgb(111, 168, 220)';
  let page = await open('/calendar');
  assert.equal(await style(page, '.header-bar', 'backgroundColor'), paper2, 'the calendar toolbar is paper');
  assert.equal(await style(page, '.fc-widget-header', 'backgroundColor'), sunk, 'day headers are sunk paper');
  assert.equal(await style(page, '.fc-day', 'backgroundColor'), paper2);
  assert.equal(await style(page, '.fc-event', 'backgroundColor'), 'rgb(255, 111, 97)', 'an event keeps its course colour');
  assert.equal(await style(page, '#calendar-list', 'backgroundColor'), paper2, 'the calendar list is paper');
  await page.close();
  page = await open('/courses');
  assert.equal(await style(page, '.ic-Table th', 'backgroundColor'), sunk);
  assert.equal(await style(page, '[class*="-view-link"]', 'color'), link, 'an InstUI link takes the mark, found by the end of its class name');
  assert.equal(await style(page, '[class*="-text"]', 'color'), ink, 'InstUI text takes the ink');
  assert.equal(await style(page, '#content h1', 'color'), ink);
  await page.close();
  page = await open('/courses/1/quizzes/1');
  assert.equal(await style(page, '.quiz-header', 'backgroundColor'), paper2);
  assert.equal(await style(page, '.box', 'backgroundColor'), paper2);
  assert.equal(await style(page, '.btn-primary', 'backgroundColor'), 'rgb(3, 116, 181)', 'never a button');
  await h.setStorage({ putBack: { paper: true } }); await page.waitForTimeout(400);
  assert.equal(await style(page, '.quiz-header', 'backgroundColor'), 'rgba(0, 0, 0, 0)', 'Put back paper takes the everywhere layer with it');
  await h.setStorage({ putBack: {} });
  await page.close();
});

test('R17 this week: our rail card reports finished work, counts by course, and Put back removes it', async () => {
  const { FakePhone } = require('./fake-phone');
  const phone = new FakePhone(BRIDGE);
  await h.sw((c) => bindWriter(c), await phone.claim());
  await h.sw((o) => syncNow(o), SCHOOL_A);
  const page = await open('/');
  await page.waitForSelector('#right-side > #pk-week', { timeout: 5000 });
  assert.ok(await page.$('#pk-week + *'), 'Canvas\'s own sidebar follows it, folded, not gone');
  assert.match(await page.$eval('#pk-week .pk-w-centre b', (e) => e.textContent), /^\d+\/\d+$|^0$/);
  const finished = await page.$eval('#pk-week .pk-w-foot > span:first-child', (e) => e.textContent);
  assert.match(finished, /^(?:\d+ things? finished this week|)$/, 'finished work gets a line; nothing finished gets no scold');
  assert.doesNotMatch(finished, /streak|in a row/i, 'the rail no longer presents a streak');
  const legend = await page.$$eval('#pk-week .pk-w-legend li span', (els) => els.map((e) => e.textContent));
  assert.ok(legend.length === 0 || legend.includes('AP Physics C'), legend.join(','));
  assert.equal(await page.$$eval('#pk-week svg circle', (els) => els.length) >= 1, true);
  assert.equal(await style(page, '#pk-week', 'backgroundColor'), 'rgb(255, 255, 255)', 'paper-2 on Newsprint');
  await h.setStorage({ putBack: { week: true } }); await page.waitForTimeout(400);
  assert.equal(await page.$('#pk-week'), null);
  await h.setStorage({ putBack: {} });
  await page.close();
  const modules = await open('/courses/1/modules');
  assert.equal(await modules.$('#pk-week'), null, 'dashboard only');
  await modules.close();
});

/// Every selector in our own stylesheet, read off disk rather than out of the
/// page: how Chrome exposes an injected content-script sheet is its business,
/// and the claim here is about the file we ship.
const SKIN_SELECTORS = (() => {
  const css = require('node:fs').readFileSync(require('node:path').join(__dirname, '../extension/skin.css'), 'utf8')
    .replace(/\/\*[\s\S]*?\*\//g, '');
  const out = new Set();
  // Innermost blocks only, so an @media prelude is left behind as its own
  // match and dropped by the `@` filter below.
  for (const m of css.matchAll(/([^{}]+)\{[^{}]*\}/g)) {
    for (const one of m[1].split(',')) {
      const sel = one.trim();
      if (!sel || sel.startsWith('@') || sel.includes('::')) continue;
      out.add(sel);
    }
  }
  return [...out];
})();

/// Which of them actually match something on the page in front of us. A rule
/// that matches nothing changes nothing, which is the claim a school's IT
/// department actually cares about.
const skinReaches = (page) => page.evaluate((sels) => sels.filter((sel) => {
  try { return !!document.querySelector(sel); } catch { return false; }
}), SKIN_SELECTORS);

test('R18 a quiz being taken gets nothing from us: no node, no attribute, and not one rule that matches', async () => {
  // First prove the measurement works, on a page the skin is meant to be on.
  assert.ok(SKIN_SELECTORS.length > 100, `only ${SKIN_SELECTORS.length} selectors were read off disk`);
  const dash = await open('/');
  assert.ok((await skinReaches(dash)).length > 0, 'the skin does reach an ordinary page');
  await dash.close();

  const page = await open('/courses/1/quizzes/1/take');
  assert.deepEqual(await classes(page), [], 'no classes at all');
  assert.equal(await page.$('#prepkin-buddy'), null, 'no buddy either');
  const marks = await page.evaluate(() => ({
    ids: [...document.querySelectorAll('[id]')].map((e) => e.id).filter((i) => i.startsWith('pk-')),
    classed: [...document.querySelectorAll('[class]')].filter((e) => [...e.classList].some((c) => c.startsWith('pk-'))).length,
    attrs: document.querySelectorAll('[data-pk-course], [data-pk-name], [data-sig]').length,
    styles: document.querySelectorAll('style[id^="pk-"]').length,
  }));
  assert.deepEqual(marks.ids, [], 'no element of ours by id');
  assert.equal(marks.classed, 0, 'no element carries a class of ours');
  assert.equal(marks.attrs, 0, 'no attribute of ours on anybody');
  assert.equal(marks.styles, 0, 'no stylesheet element of ours');

  // The stylesheet is still injected — it is registered at document_start for
  // the whole site — so the claim that matters is that none of it reaches.
  assert.deepEqual(await skinReaches(page), [], 'not one rule of ours matches anything on a quiz being taken');
  await page.close();
});

test('R18 submission pages get nothing; an open editor drops the skin but keeps the buddy', async () => {
  let page = await open('/courses/1/assignments/11');
  assert.ok(await page.$('#prepkin-buddy'), 'an ordinary assignment page is not a submission page');
  await page.close();

  page = await open('/courses/1/assignments/11/submissions');
  assert.deepEqual(await classes(page), [], 'submission page has no skin classes');
  assert.equal(await page.$('#prepkin-buddy'), null, 'submission page has no buddy');
  await page.close();

  page = await open('/?rce=1');
  assert.deepEqual(await classes(page), [], 'an open Rich Content Editor has no skin classes');
  assert.ok(await page.$('#prepkin-buddy'), 'the buddy remains available because this is not a submission page');
  await page.close();
});

test('R19 a nickname goes on the card and comes off with Put back; the registrar\'s title is kept on the node', async () => {
  await h.setStorage({ nicknames: { 1: 'Physics' } });
  const page = await open('/');
  const title = () => page.$eval('.ic-DashboardCard__header-title span', (e) => e.textContent);
  assert.equal(await title(), 'Physics');
  await h.setStorage({ putBack: { nickname: true } }); await page.waitForTimeout(400);
  assert.equal(await title(), 'AP Physics C');
  await h.setStorage({ putBack: {}, nicknames: {} }); await page.waitForTimeout(400);
  assert.equal(await title(), 'AP Physics C');
  await page.close();
});

test('R20 Command-K opens the buddy on search; Escape closes it', async () => {
  const page = await open('/');
  await page.keyboard.press('Meta+KeyK');
  await page.waitForSelector('#prepkin-buddy[data-open][data-view="search"]', { timeout: 3000 });
  await page.keyboard.press('Escape');
  await page.waitForFunction(() => !document.getElementById('prepkin-buddy').hasAttribute('data-open'), null, { timeout: 3000 });
  await page.close();
});

test('R21 a pending task of your own counts in the week without inflating the finished line', async () => {
  const { FakePhone } = require('./fake-phone');
  const phone = new FakePhone(BRIDGE);
  await h.sw((c) => bindWriter(c), await phone.claim());
  await h.sw((o) => syncNow(o), SCHOOL_A);
  const page = await open('/');
  const before = await page.$eval('#pk-week .pk-w-centre b', (e) => e.textContent);
  const finishedBefore = await page.$eval('#pk-week .pk-w-foot > span:first-child', (e) => e.textContent);
  const today = new Date(); today.setHours(20, 0, 0, 0);
  await h.setStorage({ ownTasks: [{ id: 'own-1', title: 'Read chapter 4', dueAt: today.toISOString(), courseId: 1, courseName: 'AP Physics C', submittedAt: null }] });
  await page.waitForFunction(() => [...document.querySelectorAll('.pk-due-row .t')].some((e) => e.textContent === 'Read chapter 4'), null, { timeout: 4000 });
  const after = await page.$eval('#pk-week .pk-w-centre b', (e) => e.textContent);
  assert.notEqual(after, before, `the week counts it: ${before} then ${after}`);
  assert.equal(await page.$eval('#pk-week .pk-w-foot > span:first-child', (e) => e.textContent), finishedBefore, 'pending work is not called finished');
  const pushed = await phone.fetchTodo();
  assert.ok(!pushed.tasks.some((t) => t.title === 'Read chapter 4'), 'the phone never sees it');
  await h.setStorage({ ownTasks: [] });
  await page.close();
});

test('R22 the league the phone publishes reaches the buddy, not the rail, names from the same word lists', async () => {
  const { FakePhone } = require('./fake-phone');
  const phone = new FakePhone(BRIDGE);
  await h.sw((c) => bindWriter(c), await phone.claim());
  await h.sw((o) => syncNow(o), SCHOOL_A);
  await phone.pushState({ coins: 120, owned: ['classic'], kin: { species: 'sky', level: 2, skin: 'classic', scene: 'deep' },
    league: { tier: 1, points: 120, bar: 300, week: '2026-W37', pennants: [0],
    board: [{ you: false, adjective: 3, noun: 4, points: 200, level: 2, species: 'coral', look: 'base' }, { you: true, adjective: 1, noun: 2, points: 120, level: 1, species: 'sky', look: 'base' }] } });
  await h.sw(() => pullWallet());
  const page = await open('/');
  await page.waitForSelector('#pk-week', { timeout: 5000 });
  // The league is the buddy's: the rail is one list, like BetterCampus's,
  // and the tier reaches the page only as the buddy's own attribute.
  assert.equal(await page.$('#pk-week .pk-w-league'), null, 'no league card on the rail');
  assert.equal(await page.$eval('#pk-week', (e) => /Shallows|to go for|in your pod/.test(e.textContent)), false);
  await page.waitForFunction(() => document.getElementById('prepkin-buddy')?.dataset.league === 'shallows', null, { timeout: 5000 });
  // The band is the tank the phone named, cut from the same plate Home shows.
  assert.match(await page.$eval('#pk-week .pk-w-tank', (e) => e.style.getPropertyValue('--pk-tank')), /art\/tanks\/deep\.webp/, 'the phone\'s tank, on the band');
  assert.equal(await page.$eval('#prepkin-buddy', (e) => e.dataset.league), 'shallows');
  assert.ok(!(await page.evaluate(() => document.body.textContent)).includes('Otter'), 'no stranger\'s name lands in the page itself');
  await page.close();
});

test('R23 a search pill sits at the end of every title bar, opens the buddy on search, and its receipt row turns it off', async () => {
  let page = await open('/');
  assert.ok(await page.$('#dashboard_header_container .ic-Dashboard-header__layout > #pk-search'), 'dashboard: in the header bar');
  await page.click('#pk-search');
  await page.waitForSelector('#prepkin-buddy[data-open][data-view="search"]', { timeout: 3000 });
  await page.close();
  page = await open('/courses/1/modules');
  assert.ok(await page.$('.ic-app-nav-toggle-and-crumbs > #pk-search'), 'a course page: on the breadcrumb strip');
  await h.setStorage({ skin: SKIN({ search: false }) }); await page.waitForTimeout(400);
  assert.equal(await page.$('#pk-search'), null, 'turned off from the receipt');
  await page.close();
});

// MARK: - R10: Today, at the top of the dashboard

test('R10 the rail is one list: the thing to start on top, the next few, Canvas To Do and Coming Up replaced, one click off', async () => {
  const w = S.plainSemester();
  w.assignments[1].push(S.assignment({ id: 15, name: 'Overdue reading', due: -2, course: 1 }));
  await control('world', { host: 'localhost', world: w });
  const { FakePhone } = require('./fake-phone');
  const phone = new FakePhone(BRIDGE);
  await h.sw((c) => bindWriter(c), await phone.claim());
  await h.sw((o) => syncNow(o), SCHOOL_A);
  const page = await open('/');
  await page.waitForSelector('#pk-week .pk-w-first', { timeout: 5000 });
  assert.equal(await page.$('#pk-today'), null, 'no banner above the cards any more');
  const first = await page.$eval('#pk-week .pk-w-first', (el) => el.textContent.replace(/\s+/g, ' ').trim());
  assert.match(first, /Overdue reading/, 'the one to start is the one that slipped');
  assert.match(first, /Was due/, 'plain words, and amber below, never red');
  assert.doesNotMatch(first, /still counts/, 'the amber says late; no comment on top');
  assert.match(first, /Focus 25 min/);
  assert.equal(await page.$eval('#pk-week .pk-w-first small', (el) => el.className), 'amber');
  assert.equal(await page.$eval('#pk-week a.start', (a) => a.getAttribute('href')), 'https://localhost:8443/courses/1/assignments/15');
  assert.ok((await page.$$('#pk-week .pk-w-list li')).length >= 1, 'then, the next few');
  assert.equal(await page.$eval('#pk-week', (el) => /\d+%|GPA/.test(el.textContent)), false, 'no grade leaves the panel');
  // Rings: one track per course with work this week, a fill only where something is handed in.
  const rings = await page.$$eval('#pk-week .pk-w-ring circle', (els) => els.map((c) => c.getAttribute('stroke')));
  assert.ok(rings.length >= 1, 'at least one ring');
  // Canvas's own To Do and Coming Up are replaced; Put back on that row brings them back.
  const todo = require('../extension/selectors').SELECTORS.todoReact.sel;
  assert.equal(await page.$eval(todo, (el) => getComputedStyle(el).display), 'none', 'replaced');
  await h.setStorage({ putBack: { 'todo-fold': true } }); await page.waitForTimeout(400);
  assert.notEqual(await page.$eval(todo, (el) => getComputedStyle(el).display), 'none', 'Put back keeps them');
  await h.setStorage({ putBack: {} }); await page.waitForTimeout(400);
  // Put back from the receipt takes the rail off, and it stays off.
  await page.bringToFront();
  const popup = await openPopup(h);
  await popup.waitFor('li[data-key="week"] .put');
  await popup.click('li[data-key="week"] .put');
  await page.waitForFunction(() => { const t = document.getElementById('pk-week'); return !t || getComputedStyle(t).display === 'none'; });
  await popup.close();
  await page.reload();
  await page.waitForTimeout(400);
  assert.ok(['none', 'absent'].includes(await page.evaluate(() => { const t = document.getElementById('pk-week'); return t ? getComputedStyle(t).display : 'absent'; })), 'stays off after a reload');
  await page.close();
});

test('R24 handing in pays off at once: the form posts, one sync follows, the row is struck and the ring moves', async () => {
  await h.sw((o) => syncNow(o), SCHOOL_A);
  const ps7 = (p) => p?.tasks?.find((t) => t.title === 'Problem Set 7');
  assert.equal(ps7((await h.storage()).lastPayload)?.submittedAt ?? null, null, 'Problem Set 7 is pending');
  await control('log/clear');
  const page = await open('/courses/1/assignments/11');
  await page.click('#submit_text_entry');                       // a real click: the form posts, Canvas comes back
  await page.waitForURL(/\/courses\/1\/assignments\/11$/);
  // The page that comes back asks for one sync a moment later.
  const t0 = Date.now();
  let payload;
  while (Date.now() - t0 < 15_000) {
    payload = (await h.storage()).lastPayload;
    if (ps7(payload)?.submittedAt) break;
    await new Promise((r) => setTimeout(r, 300));
  }
  assert.ok(ps7(payload)?.submittedAt, 'the hand-in reached the laptop without waiting for the alarm');
  const log = await control('log');
  assert.ok(log.some((l) => l.path.startsWith('/api/v1/courses/1/assignments')), 'one sync ran after the post');
  // The dashboard now shows it struck through, and the badge floated the reward.
  const dash = await open('/');
  assert.match(await dash.$eval('.pk-card-due', (e) => e.textContent), /Problem Set 7[\s\S]*handed in/, 'struck on the card');
  await page.close(); await dash.close();
});

test('R25 while a session runs, the rail\'s top row is the session and Focus cannot restart it', async () => {
  await h.sw((o) => syncNow(o), SCHOOL_A);
  const lab = (await h.storage()).lastPayload.tasks.find((t) => t.title === 'Lab writeup: Momentum');
  await h.sw((t) => focusStart({ taskId: t.id, title: t.title, url: t.url, minutes: 25 }), lab);
  const page = await open('/');
  await page.waitForSelector('#pk-week .pk-w-clock', { timeout: 5000 });
  const top = await page.$eval('#pk-week .pk-w-first', (el) => el.textContent.replace(/\s+/g, ' ').trim());
  assert.match(top, /Lab writeup: Momentum/, 'the session, not the queue');
  assert.match(top, /\d+:\d\d left/, 'the clock');
  assert.match(top, /Stop/);
  assert.doesNotMatch(top, /Focus 25 min/, 'no second start');
  assert.equal(await page.$eval('#pk-week .pk-w-label', (el) => el.textContent), 'Now');
  const rows = await page.$$eval('#pk-week .pk-w-list li:not(.pk-w-first) b', (els) => els.map((e) => e.textContent));
  assert.ok(!rows.includes('Lab writeup: Momentum'), 'not listed twice');
  // The clock moves in place.
  const a = await page.$eval('#pk-week .pk-w-clock', (el) => el.textContent);
  await page.waitForTimeout(1600);
  const b = await page.$eval('#pk-week .pk-w-clock', (el) => el.textContent);
  assert.notEqual(a, b, 'ticks without a redraw');
  // A second start keeps the first session's clock.
  const endsAt = (await h.storage()).focus.endsAt;
  await h.sw(() => focusStart({ taskId: 'other', title: 'Problem Set 7', url: '', minutes: 45 }));
  assert.equal((await h.storage()).focus.endsAt, endsAt);
  await h.sw(() => focusStop());
  await page.close();
});

test('R26 a pending row on a course card is a link that says Start on hover; handed-in rows stay text', async () => {
  await h.sw((o) => syncNow(o), SCHOOL_A);
  const page = await open('/');
  await page.waitForSelector('.pk-card-due a.pk-due-row', { timeout: 5000 });
  const pending = await page.$('.pk-card-due a.pk-due-row:not(.done)');
  assert.ok(pending, 'a pending row is a link');
  assert.match(await pending.getAttribute('href'), /\/courses\/1\/assignments\/1[123]$/);
  assert.equal(await page.$eval('.pk-card-due a.pk-due-row:not(.done) .go', (e) => getComputedStyle(e).display), 'none', 'Start hides until hover');
  await pending.hover();
  assert.notEqual(await page.$eval('.pk-card-due a.pk-due-row:not(.done) .go', (e) => getComputedStyle(e).display), 'none', 'Start on hover');
  assert.equal(await page.$eval('.pk-card-due a.pk-due-row:not(.done) .d', (e) => getComputedStyle(e).display), 'none', 'the date steps aside');
  assert.equal(await page.$('.pk-card-due a.pk-due-row.done'), null, 'handed-in rows are not links');
  await page.close();
});

test('R27 the Planner and Looks tabs: a week grid and the shop in the main column, the cards put away and brought back, one click off', async () => {
  await h.sw((o) => syncNow(o), SCHOOL_A);
  const page = await open('/');
  await page.waitForSelector('#pk-dashtabs [role="tab"]', { timeout: 5000 });
  const tabs = await page.$$eval('#pk-dashtabs [role="tab"]', (els) => els.map((e) => [e.textContent, e.getAttribute('aria-selected')]));
  assert.deepEqual(tabs, [['Courses', 'true'], ['Planner', 'false'], ['Looks', 'false']], 'Courses first, the cards showing');
  assert.equal(await page.$('#pk-planner'), null);
  await page.click('#pk-dashtabs [data-tab="planner"]');
  await page.waitForSelector('#pk-planner .pk-pl-grid', { timeout: 5000 });
  assert.equal(await page.$$eval('#pk-planner .pk-pl-col', (els) => els.length), 7, 'seven days');
  assert.equal(await page.$$eval('#pk-planner .pk-pl-col.today', (els) => els.length), 1, 'one of them today');
  assert.equal(await style(page, '#DashboardCard_Container', 'display'), 'none', 'the cards step aside');
  assert.ok((await page.$$('#pk-planner .pk-pl-task')).length >= 3, 'the week\'s work as cards');
  assert.ok(await page.$('#pk-planner .pk-pl-task img.pk-pl-icon'), 'each with one of the app\'s icons');
  assert.equal(await page.$$eval('#pk-planner .pk-pl-card', (els) => els.map((e) => e.querySelector('.head b').textContent)).then((x) => x.join(',')), 'Grades,League,Focus');
  assert.equal(await page.$eval('#pk-planner', (e) => /\d+%|GPA about/.test(e.textContent)), true, 'grades live here now');
  assert.equal((await h.storage()).dashTab, 'planner', 'the choice is kept');
  // Dragging a card to another day plans it; the plan is kept in this browser only.
  const id = await page.$eval('#pk-planner .pk-pl-col .pk-pl-task:not(.done)', (e) => e.dataset.drag);
  await page.dragAndDrop(`#pk-planner .pk-pl-task[data-drag="${id}"]`, '#pk-planner .pk-pl-col:last-child');
  await page.waitForTimeout(600);
  assert.ok((await h.storage()).plans?.[id], 'planned onto a day');
  assert.ok(await page.$(`#pk-planner .pk-pl-col:last-child [data-drag="${id}"]`), 'and shown there');
  // Looks: the shop in the page, the worn one ticked, the rest priced.
  await page.click('#pk-dashtabs [data-tab="looks"]');
  await page.waitForSelector('#pk-looks .pk-pl-looks', { timeout: 5000 });
  assert.equal(await page.$('#pk-planner'), null, 'one tab at a time');
  assert.ok(await page.$('#pk-looks .pk-pl-look.wearing .tick'), 'the worn look is ticked');
  assert.ok((await page.$$('#pk-looks .pk-pl-look .price')).length >= 10, 'the rest carry a price');
  assert.equal(await style(page, '#DashboardCard_Container', 'display'), 'none', 'the cards stay aside');
  // Courses brings the cards back; Put back on the planner row hides the tab itself.
  await page.click('#pk-dashtabs [data-tab="cards"]');
  await page.waitForTimeout(300);
  assert.notEqual(await style(page, '#DashboardCard_Container', 'display'), 'none');
  assert.equal(await page.$('#pk-planner'), null);
  await h.setStorage({ putBack: { planner: true } }); await page.waitForTimeout(500);
  assert.equal(await page.$('#pk-dashtabs'), null, 'put back: the tab itself is gone');
  await h.setStorage({ putBack: {} });
  await page.close();
});

// MARK: - R4: the receipt

test('R4 the popup lists what this page got, Put back reverses one thing and is remembered, Show me outlines it', async () => {
  const page = await open('/');
  await page.bringToFront();
  let popup = await openPopup(h);
  await popup.waitFor('#receipt-fixed li');
  const rows = async () => popup.evaluate(`[...document.querySelectorAll('#receipt li')].map((li) => li.textContent.trim())`);
  const listed = await rows();
  assert.ok(listed.some((t) => t.startsWith('Page paper: Newsprint · 15.3:1')), listed.join(' | '));
  for (const line of ['Course colour band, thinner', 'One To Do list instead of two', 'Coming Up shows every row',
                      'The school logo, twice. One kept', 'Next due date on each course card', 'The buddy, bottom right']) {
    assert.ok(listed.some((t) => t.startsWith(line)), `missing: ${line}`);
  }
  assert.ok(!listed.some((t) => /Four menu items|Module header|Word/.test(t)), 'no course-page rows on the dashboard');
  assert.equal(await popup.text('#receipt-page'), 'Dashboard');
  assert.equal(await popup.text('#receipt .foot'), 'Everything here is one click from coming back.');
  // Put back the hero.
  await popup.click('li[data-key="hero"] .put');
  await popup.waitFor('li[data-key="hero"].back');
  assert.equal(await popup.text('li[data-key="hero"] .put'), 'Undo');
  await page.waitForFunction(() => document.documentElement.classList.contains('pk-back-hero'));
  assert.equal(await style(page, '.ic-DashboardCard__header_hero', 'height'), '146px', 'the band is back');
  assert.equal(await style(page, 'body', 'backgroundColor'), rgb('#F7F6F3'), 'everything else still applies');
  // Show me.
  await popup.click('#show-me');
  await page.waitForFunction(() => document.documentElement.classList.contains('pk-show'));
  assert.match(await style(page, '.ic-sidebar-logo', 'outlineStyle'), /dashed/);
  await popup.close();
  // Remembered across a reload and a navigation.
  await page.reload();
  await page.waitForTimeout(350);
  assert.ok((await classes(page)).includes('pk-back-hero'));
  await page.goto(`${SCHOOL_A}/courses/1/modules`);
  await page.waitForTimeout(350);
  assert.ok((await classes(page)).includes('pk-back-hero'));
  // Undo.
  await page.goto(`${SCHOOL_A}/`);
  await page.waitForTimeout(350);
  await page.bringToFront();
  popup = await openPopup(h);
  await popup.waitFor('li[data-key="hero"].back');
  await popup.click('li[data-key="hero"] .put');
  await page.waitForFunction(() => !document.documentElement.classList.contains('pk-back-hero'));
  assert.equal(await style(page, '.ic-DashboardCard__header_hero', 'height'), '72px');
  await popup.close();
  await page.close();
});

test('R4 the receipt on Modules and on a dark assignment names the right rows; Take off removes the buddy', async () => {
  const page = await open('/courses/1/modules');
  await page.bringToFront();
  let popup = await openPopup(h);
  await popup.waitFor('#receipt-fixed li');
  let listed = await popup.evaluate(`[...document.querySelectorAll('#receipt li')].map((li) => li.textContent.trim())`);
  for (const line of ['Four menu items dimmed', 'Module header stays at the top while you scroll', 'Due dates lined up in one column']) {
    assert.ok(listed.some((t) => t.startsWith(line)), `missing: ${line}`);
  }
  assert.equal(await popup.text('#receipt-page'), 'Modules');
  assert.equal(await popup.text('#receipt-taken li'), 'Nothing was taken from this page.');
  // Take off the buddy.
  await popup.click('li[data-key="buddy"] .put');
  await page.waitForFunction(() => !document.getElementById('prepkin-buddy'), null, { timeout: 5000 });
  await popup.close();
  await page.close();
  await h.setStorage({ skin: SKIN({ dark: true }) });
  const dark = await open('/courses/1/assignments/11');
  await dark.bringToFront();
  popup = await openPopup(h);
  await popup.waitFor('#receipt-fixed li');
  listed = await popup.evaluate(`[...document.querySelectorAll('#receipt li')].map((li) => li.textContent.trim())`);
  assert.ok(listed.some((t) => t.startsWith('Text pasted from Word, made readable')), listed.join(' | '));
  assert.equal(await popup.text('#receipt-page'), 'Assignment');
  await popup.close();
  await dark.close();
});

// MARK: - R1 again: the page changing under us

test('R1 a sidebar that arrives late still gets its rows and its receipt', async () => {
  const page = await open('/courses/1');
  await page.evaluate(() => {
    // What Canvas does: the dashboard sidebar lands by XHR after load.
    const side = document.createElement('div');
    side.id = 'right-side-wrapper';
    side.innerHTML = '<aside id="right-side"><div class="Sidebar__TodoListContainer"><div data-testid="ToDoSidebar"></div></div><ul class="right-side-list to-do-list"><li class="todo">x</li></ul></aside>';
    document.getElementById('main').append(side);
  });
  await page.waitForTimeout(400);
  assert.ok((await classes(page)).includes('pk-todo-dup'));
  assert.equal(await style(page, 'ul.right-side-list.to-do-list', 'display'), 'none');
  await page.close();
});

test('R2 reduced motion: nothing animates, nothing is set to none', async () => {
  const page = await h.context.newPage();
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await page.goto(`${SCHOOL_A}/`);
  await page.waitForTimeout(350);
  assert.ok(['0.01ms', '1e-05s'].includes(await style(page, '.ic-DashboardCard', 'transitionDuration')), 'durations go to 0.01ms');
  await page.close();
});

// MARK: - R9: the popup points at the buddy

test('R9 the popup is the extension; one button opens the planner on the page, and the day list is not in the popup', async () => {
  const page = await open('/');
  await page.bringToFront();
  const popup = await openPopup(h);
  await popup.waitFor('#open-buddy');
  assert.equal(await popup.evaluate(`document.getElementById('due-list')`), null, 'no Due next in the popup');
  assert.equal(await popup.evaluate(`document.getElementById('buddy').hidden`), false, 'a connected Canvas is in front');
  assert.equal(await page.$('#pk-planner'), null, 'the cards before');
  await popup.click('#open-buddy');
  await page.waitForSelector('#pk-planner .pk-pl-grid', { timeout: 5000 });
  await popup.close().catch(() => {});
  await page.close();
});

// MARK: - R20: courses you have finished

test('R20 past and future enrolments fold away only when the student turns it on, and the heading goes with the table', async () => {
  let page = await open('/courses');
  assert.notEqual(await style(page, '#past_enrollments_table', 'display'), 'none', 'off by default: the table is where Canvas put it');
  await page.close();

  await h.setStorage({ skin: SKIN({ hidePast: true }) });
  page = await open('/courses');
  assert.ok((await classes(page)).includes('pk-hide-past'));
  assert.equal(await style(page, '#past_enrollments_table', 'display'), 'none');
  assert.equal(await style(page, '#future_enrollments_table', 'display'), 'none');
  // No orphan title left pointing at nothing.
  const heading = await page.evaluate(() => {
    const h2 = [...document.querySelectorAll('h2')].find((e) => e.nextElementSibling?.id === 'past_enrollments_table');
    return h2 ? getComputedStyle(h2).display : 'missing';
  });
  assert.equal(heading, 'none', 'the heading goes with its table');
  // The courses the student is actually taking are untouched.
  assert.notEqual(await style(page, '#my_courses_table', 'display'), 'none', 'current courses stay');
  await page.close();

  // And it is a courses-page rule only: no other page loses anything.
  page = await open('/');
  assert.ok(await page.$('.ic-DashboardCard'), 'the dashboard is unaffected');
  await page.close();
});

// MARK: - R21: a picture the student put on a course card
//
// The picker itself lives inside the panel's closed shadow root, which
// Playwright cannot reach into, so what is driven here is the painting half:
// given a stored picture, the card wears it, the receipt says so, and Put back
// takes it off. `scrimFor` is proved separately in extension/receipt.test.js.

const PIXEL = 'data:image/gif;base64,R0lGODlhAQABAIAAAP///wAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==';

test('R21 a picture the student chose goes on that one card, and comes off with Put back', async () => {
  await h.setStorage({ cardArt: { 1: { src: PIXEL, scrim: 0.4, thumb: PIXEL } } });
  let page = await open('/');
  const hero = '.ic-DashboardCard[data-pk-course="1"] .ic-DashboardCard__header_hero';
  assert.ok(await page.$(hero), 'the card says which course it is for');
  assert.ok(await page.$('.ic-DashboardCard.pk-own-art'), 'and that it wears a picture of the student\'s');
  const image = await style(page, hero, 'backgroundImage');
  assert.ok(image.includes('data:image/gif'), image.slice(0, 80));
  assert.ok(image.includes('rgba(0, 0, 0, 0.4)'), `the measured scrim is in the paint: ${image.slice(0, 120)}`);
  assert.equal(await style(page, hero, 'backgroundSize'), 'cover, cover', 'the scrim and the picture are both laid over the whole band');
  // Only that card. A course with no picture keeps Canvas's own band.
  const others = await page.evaluate(() => [...document.querySelectorAll('.ic-DashboardCard')]
    .filter((c) => c.dataset.pkCourse !== '1')
    .map((c) => getComputedStyle(c.querySelector('.ic-DashboardCard__header_hero')).backgroundImage));
  assert.ok(others.every((b) => !b.includes('data:image/gif')), 'no other card was repainted');
  await page.close();

  await h.setStorage({ putBack: { 'card-art': true } });
  page = await open('/');
  assert.equal(await page.$('.ic-DashboardCard.pk-own-art'), null, 'Put back takes the class off');
  assert.ok(!(await style(page, hero, 'backgroundImage')).includes('data:image/gif'), 'and the picture with it');
  await page.close();
});

// MARK: - R22: one ground, painted once

test('R22 an image theme paints its wash exactly once, so no bar reads as a paler slab', async () => {
  await h.setStorage({ skin: SKIN(), wallet: { coins: 900, owned: ['classic', 'deepsea'], wearing: 'deepsea' } });

  // The bar behind the page title used to take `background-color: var(--pk-paper-wash)`
  // on top of a body that had already laid that same wash over the wallpaper.
  // Two coats of the same paper is a pale slab across the top of the page, which
  // is what a student reported. It paints the whole ground now — wash and
  // wallpaper, both fixed — so it lands on the pixels the body already drew.
  let page = await open('/');
  const bar = '#dashboard_header_container .ic-Dashboard-header__layout';
  assert.equal(await style(page, bar, 'backgroundColor'), 'rgba(0, 0, 0, 0)', 'no flat wash on the bar');
  const paint = await style(page, bar, 'backgroundImage');
  assert.match(paint, /linear-gradient\(rgba\(237, 243, 248, 0\.82\).*wallpaper/, paint);
  assert.equal(await style(page, bar, 'backgroundAttachment'), 'fixed, fixed', 'so it lines up with the body');
  assert.equal(await style(page, 'body', 'backgroundImage'), paint, 'the bar paints what the page paints');
  await page.close();

  // And nowhere else on any page does the wash get used as a flat colour: that
  // is the signature of the bug, wherever it turns up next.
  for (const path of ['/', '/courses', '/courses/1/modules', '/courses/1/assignments/11', '/courses/1/grades']) {
    page = await open(path);
    const doubled = await page.evaluate(() => {
      const wash = getComputedStyle(document.documentElement).getPropertyValue('--pk-paper-wash').trim();
      const out = new Set();
      for (const el of document.querySelectorAll('*')) {
        const c = getComputedStyle(el);
        if (c.backgroundColor === wash && c.backgroundImage === 'none') {
          out.add(`${el.tagName.toLowerCase()}${el.id ? '#' + el.id : ''}.${[...el.classList].slice(0, 2).join('.')}`);
        }
      }
      return [...out];
    });
    assert.deepEqual(doubled, [], `${path} paints the page wash twice`);
    await page.close();
  }
});

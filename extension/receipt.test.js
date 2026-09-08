// Run with: node --test extension/receipt.test.js
const test = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const path = require('path');
const { PAPERS, RULES, contrast, paperLine, stockFor, skinClasses, receiptRows, pageName, killReason } = require('./receipt.js');
const { SELECTORS } = require('./selectors.js');
const { LOOKS } = require('./looks.js');

// MARK: - Papers

test('every paper clears AAA for body text, and the card prints the measured number', () => {
  for (const [id, p] of Object.entries(PAPERS)) {
    assert.ok(contrast(p.ink, p.paper) >= 7, `${id} ${contrast(p.ink, p.paper)}`);
    assert.ok(contrast(p.ink2, p.paper) >= 4.5, `${id} secondary ink`);
    assert.ok(contrast(p.mark, p.paper) >= 4.5, `${id} link ink`);
    assert.match(paperLine(id), /^[A-Z][A-Za-z ]+ · \d+\.\d:1 · /);   // a stock may be two words: "Sea Foam"
  }
  assert.equal(paperLine('manila'), 'Manila · 11.9:1 · warm');
  assert.equal(paperLine('nope'), '');
});

test('the catalog is sixteen papers, eleven light and five dark, and every theme names two of them', () => {
  assert.equal(Object.keys(PAPERS).length, 16);
  assert.equal(Object.values(PAPERS).filter((p) => p.dark).length, 5);
  assert.equal(LOOKS.length, 26, 'eighteen flat themes and eight image themes');
  for (const look of LOOKS) {
    assert.ok(PAPERS[look.paper.light] && !PAPERS[look.paper.light].dark, `${look.id} light`);
    assert.ok(PAPERS[look.paper.dark] && PAPERS[look.paper.dark].dark, `${look.id} dark`);
    assert.equal('dark' in look, false, 'no Look forces dark any more');
    assert.equal('tints' in look, false, 'a Look moves paper tokens, never inline tints');
  }
  const night = LOOKS.find((l) => l.id === 'nightshift');
  assert.deepEqual([night.price, night.paper.dark], [500, 'blueprint'], 'Night Shift keeps its price and gets Blueprint');
});

test('every theme accent is AA on both tones of its paper, and its texture draws in the ink', () => {
  const { THEMES, textureImage, TEXTURES } = require('./themes.js');
  const { themeStyle } = require('./receipt.js');
  for (const t of THEMES) {
    for (const mode of ['light', 'dark']) {
      const p = PAPERS[t.paper[mode]];
      for (const ground of [p.paper, p.paper2]) {
        assert.ok(contrast(t.accent[mode], ground) >= 4.5, `${t.id} ${mode} accent ${t.accent[mode]} on ${ground}: ${contrast(t.accent[mode], ground).toFixed(2)}`);
      }
    }
    assert.ok(t.texture in TEXTURES, `${t.id} texture`);
    assert.ok(typeof t.price === 'number' && t.price >= 0);
  }
  assert.equal(textureImage('none', '#000'), 'none');
  assert.match(textureImage('dots', '#1B1F24'), /^url\("data:image\/svg\+xml,/);
  // The grain is a filtered rect: its filter reference must survive encoding
  // exactly once, or the rect paints solid ink over the whole page.
  const grain = decodeURIComponent(textureImage('grain', '#1B1F24').slice('url("data:image/svg+xml,'.length, -2));
  assert.match(grain, /filter='url\(#n\)'/);
  assert.match(grain, /<filter id='n'>/);
  assert.match(grain, /0 0 0 \.04 0/, 'a dark ink on a light paper: 4%');
  assert.match(decodeURIComponent(textureImage('grain', '#E4E8F0').slice('url("data:image/svg+xml,'.length, -2)), /0 0 0 \.07 0/, 'a light ink on a dark paper: 7%');
  const css = themeStyle(THEMES.find((t) => t.id === 'blush'), textureImage);
  assert.match(css, /html\.pk-on\.pk-theme-blush\{--pk-mark:#B04A6E;/);
  assert.match(css, /html\.pk-on\.pk-dark\.pk-theme-blush\{--pk-mark:#F0A3BE;/);
  assert.match(css, /--pk-texture:url\("data:/);
  assert.equal(themeStyle(THEMES[0], textureImage).includes('--pk-texture:none'), true, 'Classic has no texture');
});

test('compact pages is a class, and only when it is on', () => {
  const look = { id: 'classic', paper: { light: 'bright', dark: 'slate' } };
  assert.ok(skinClasses({ on: true, dark: false, look, dense: true }).includes('pk-dense'));
  assert.ok(!skinClasses({ on: true, dark: false, look }).includes('pk-dense'));
  assert.ok(!skinClasses({ on: false, dark: false, look, dense: true }).length, 'off is off');
});

test('an image theme draws the placeholder set until its own folder is packed', () => {
  const { THEMES_BY_ID, artFor } = require('./themes.js');
  const { themeStyle } = require('./receipt.js');
  const url = (f) => `chrome-extension://abc/${f}`;
  const fallback = artFor(THEMES_BY_ID.graffiti, [], url);
  assert.equal(fallback.wallpaper, 'chrome-extension://abc/art/_placeholder/wallpaper.svg');
  assert.equal(fallback.cards.length, 4);
  const real = artFor(THEMES_BY_ID.graffiti, ['graffiti'], url);
  assert.equal(real.cards[3], 'chrome-extension://abc/art/graffiti/card-4.webp');
  assert.equal(artFor(THEMES_BY_ID.classic, ['graffiti'], url), null, 'a flat theme has no art');
  const css = themeStyle(THEMES_BY_ID.graffiti, null, real);
  assert.match(css, /--pk-wallpaper:url\("chrome-extension:\/\/abc\/art\/graffiti\/wallpaper\.webp"\)/);
  assert.match(css, /--pk-paper-wash:rgba\(247, 246, 243, 0\.82\)/, 'the light paper as a wash');
  assert.match(css, /--pk-card-art-4:url\(/);
  assert.ok(skinClasses({ on: true, dark: false, look: THEMES_BY_ID.graffiti }).includes('pk-art'));
});

test('the theme classes carry the paper, the wash and the texture', () => {
  const { THEMES_BY_ID } = require('./themes.js');
  const c = skinClasses({ on: true, dark: false, look: THEMES_BY_ID.blush });
  assert.deepEqual(c.sort(), ['pk-head-wash', 'pk-on', 'pk-paper-rose', 'pk-textured', 'pk-theme-blush'].sort());
  const d = skinClasses({ on: true, dark: true, look: THEMES_BY_ID.classic });
  assert.deepEqual(d.sort(), ['pk-dark', 'pk-on', 'pk-paper-carbon', 'pk-theme-classic'].sort());
});

test('an unknown Look reads as Classic, and dark picks the dark stock', () => {
  assert.equal(stockFor(undefined, false), 'newsprint');
  assert.equal(stockFor(undefined, true), 'carbon');
  assert.equal(stockFor({ paper: { light: 'bond', dark: 'blueprint' } }, true), 'blueprint');
  assert.equal(stockFor({ paper: { light: 'nope', dark: 'nope' } }, false), 'newsprint');
});

// MARK: - Classes

test('the skin is classes only, and off means no classes at all', () => {
  assert.deepEqual(skinClasses({ on: false, dark: true, look: LOOKS[1], putBack: { hero: true } }), []);
  const on = skinClasses({ on: true, dark: false, look: LOOKS[1], putBack: { hero: true, 'nav-dim': false }, detect: { logoDup: true } });
  assert.deepEqual(on.sort(), ['pk-back-hero', 'pk-head-wash', 'pk-logo-dup', 'pk-on', 'pk-paper-vellum', 'pk-textured', 'pk-theme-academia'].sort());
  assert.ok(skinClasses({ on: true, dark: true, look: LOOKS[0] }).includes('pk-paper-carbon'));
});

// MARK: - The rows

test('a row is on the receipt only when its hook is on the page', () => {
  const none = receiptRows({ present: () => false });
  assert.deepEqual(none.map((r) => r.key), ['paper', 'rail', 'search', 'dense', 'buddy'], 'paper, the rail, search, compact and the buddy are always there');
  assert.ok(receiptRows({ present: () => true }).some((r) => r.key === 'today'), 'the Today block is on the dashboard receipt');
  const all = receiptRows({ present: () => true, detect: { logoDup: true, todoDup: true, wordPaste: true }, dark: true, cardGrades: true, nicknames: 1 });
  assert.deepEqual(all.map((r) => r.key).sort(), RULES.map((r) => r.key).sort());
  const light = receiptRows({ present: () => true, detect: { wordPaste: true }, dark: false });
  assert.ok(!light.some((r) => r.key === 'word-paste' || r.key === 'seam'), 'dark-only rows stay off in light');
});

test('put back is remembered on the row, and the buddy says Take off', () => {
  const rows = receiptRows({ present: () => true, putBack: { hero: true } });
  assert.equal(rows.find((r) => r.key === 'hero').back, true);
  assert.equal(rows.find((r) => r.key === 'buddy').putBack, 'Take off');
  assert.equal(rows.find((r) => r.key === 'hero').putBack, 'Put back');
  // The buddy is a switch, so its row stays on the receipt while it is off and
  // its button brings it back.
  const off = receiptRows({ present: () => true, mascot: false }).find((r) => r.key === 'buddy');
  assert.equal(off.back, true);
  assert.equal(off.undo, 'Bring back');
  assert.equal(off.opt, 'mascot');
});

test('the switches are rows: compact and grades read Turn on while off, and never put-back keys', () => {
  const rows = receiptRows({ present: () => true, putBack: { dense: true, 'card-grade': true } });
  assert.equal(rows.find((r) => r.key === 'dense').back, true, 'off by default, the put-back key is ignored');
  assert.equal(rows.find((r) => r.key === 'dense').undo, 'Turn on');
  const on = receiptRows({ present: () => true, dense: true, cardGrades: true });
  assert.equal(on.find((r) => r.key === 'dense').back, false);
  assert.equal(on.find((r) => r.key === 'card-grade').back, false);
  assert.equal(on.find((r) => r.key === 'hero').opt, null);
});

test('the menu-items row counts what the course shows', () => {
  const label = (n) => receiptRows({ present: (k) => (k === 'courseNavLowUse' ? n : 0) }).find((r) => r.key === 'nav-dim')?.label;
  assert.equal(label(4), 'Four menu items dimmed');
  assert.equal(label(1), 'One menu item dimmed');
  assert.equal(label(0), undefined);
});

test('the paper row prints the measured stock', () => {
  const [paper] = receiptRows({ present: () => false, stock: 'vellum' });
  assert.equal(paper.label, 'Page paper: Vellum · 9.6:1 · cream, softest');
});

test('every rule names a hook that exists, and no hook is a hashed class', () => {
  for (const rule of RULES) {
    if (rule.hook) assert.ok(SELECTORS[rule.hook], `${rule.key} → ${rule.hook}`);
  }
  for (const [k, v] of Object.entries(SELECTORS)) assert.doesNotMatch(v.sel, /css-/, k);
  // The three `opt` rows are the student's own switches, not changes to the
  // page, so they sit outside the cap.
  assert.ok(RULES.filter((r) => !r.opt).length <= 15, 'fifteen keys at most, so it cannot sprawl');
});

// MARK: - Off switches and names

test('the kill reasons, in order', () => {
  assert.equal(killReason(), null);
  assert.match(killReason({ quizTake: true, submitting: true }), /taking a quiz/);
  assert.match(killReason({ submitting: true, editorOpen: true, envHighContrast: true }), /handing something in/);
  assert.match(killReason({ editorOpen: true, envHighContrast: true }), /editor is open/);
  assert.match(killReason({ envHighContrast: true, newQuizzes: true }), /Your school has High Contrast on/);
  assert.match(killReason({ forcedColors: true }), /High Contrast is on/);
  assert.match(killReason({ newQuizzes: true }), /New Quizzes/);
  assert.match(killReason({ widgetDashboard: true }), /new dashboard/);
});

test('the sign-in pages are never touched', () => {
  const { isLoginPath } = require('./receipt.js');
  for (const path of ['/login', '/login/canvas', '/login/saml', '/logout', '/register', '/confirmations/1/re_send']) {
    assert.equal(isLoginPath(path), true, path);
  }
  for (const path of ['/', '/courses/4', '/courses/4/assignments/1', '/loginhelp/x']) {
    assert.equal(isLoginPath(path), false, path);
  }
  assert.match(killReason({ loginPage: true, envHighContrast: true }), /sign-in page/);
});

test('page names', () => {
  assert.equal(pageName('/'), 'Dashboard');
  assert.equal(pageName('/courses/4/modules'), 'Modules');
  assert.equal(pageName('/courses/4/assignments/10'), 'Assignment');
  assert.equal(pageName('/courses/4/grades'), 'Grades');
  assert.equal(pageName('/courses/4'), 'Course home');
  assert.equal(pageName('/calendar'), 'This page');
});

// MARK: - The stylesheet keeps its promises

const css = fs.readFileSync(path.join(__dirname, 'skin.css'), 'utf8').replace(/\/\*[\s\S]*?\*\//g, '');
// The lint guards Canvas's own page. Prepkin's own surfaces on it (#pk-today,
// the card line) are ours to style, so they are read separately below.
const allRules = [...css.matchAll(/([^{}]+)\{([^{}]*)\}/g)].map((m) => ({ selectors: m[1].trim(), body: m[2] }));
const ours = (sel) => /#pk-today|#pk-week|#pk-search|\.pk-card-due|pk-back-card-due|pk-back-today|pk-back-week/.test(sel);
// A rule counts as Canvas's if any selector in it reaches Canvas markup.
const rules = allRules.filter((r) => !r.selectors.split(',').every((sel) => ours(sel)));

test('no rule in the skin writes any property on a button', () => {
  const buttonish = /(^|[\s,>+~(])(button|\.btn|\.Button|\[type="?submit"?\]|input\[type="?submit"?\]|\[role="?button"?\])/i;
  for (const r of rules) {
    for (const sel of r.selectors.split(',')) {
      if (sel.includes('*') || sel.includes(':not([type="submit"])') || ours(sel)) continue;
      assert.doesNotMatch(sel, buttonish, `selects a button: ${sel.trim()}`);
    }
  }
});

test('the skin never sets font-family, a shadow that is not none, a hover lift, or red', () => {
  for (const r of rules) {
    assert.doesNotMatch(r.body, /font-family/, r.selectors);
    assert.doesNotMatch(r.body, /transform:\s*translate/, r.selectors);
    assert.doesNotMatch(r.body, /box-shadow:\s*(?!none)\S/, r.selectors);
    assert.doesNotMatch(r.body, /#(d41e00|c00000|b0453c|ff0000)/i, r.selectors);
  }
  assert.doesNotMatch(css, /css-/, 'no InstUI hash');
  assert.doesNotMatch(css, /--ic-brand-(?!button)/, 'never a brand variable (the three link variables are scoped, not brand)');
  assert.doesNotMatch(css, /\.ic-flash-error|#skip_navigation_link|\.ic-sidebar-logo\s*\{/, 'never the flash red, the skip link, or the school sidebar logo');
  assert.doesNotMatch(css, /animation-iteration-count/, 'never freezes a spinner');
});

test('every receipt key that has CSS is gated on its put-back class', () => {
  for (const key of ['paper', 'hero', 'logo-dup', 'todo-dup', 'coming-up', 'nav-dim', 'module-sticky', 'due-column', 'word-paste', 'seam']) {
    assert.ok(css.includes(`:not(.pk-back-${key})`), `${key} has no put-back gate`);
  }
});

test('every rail carries white text at AA, and the theme style names it', () => {
  const { THEMES } = require('./themes.js');
  const { themeStyle, contrast } = require('./receipt.js');
  for (const t of THEMES) {
    assert.ok(t.rail?.light && t.rail?.dark, `${t.id} has a rail`);
    for (const mode of ['light', 'dark']) {
      assert.ok(contrast(t.rail[mode], '#FFFFFF') >= 4.5, `${t.id} ${mode} rail ${t.rail[mode]} vs white: ${contrast(t.rail[mode], '#FFFFFF').toFixed(2)}`);
    }
  }
  const css = themeStyle(THEMES[0], null);
  assert.match(css, /--pk-rail:#2F4A66;--pk-rail-active:#2F6BAA;--pk-rail-image:none;/);
  const art = themeStyle(THEMES.find((t) => t.id === 'graffiti'), null, { wallpaper: 'x.webp', cards: [] });
  assert.match(art, /--pk-rail-image:linear-gradient\(rgba\(35, 18, 38, 0\.74\)[^;]*url\("x\.webp"\)/);
});

test('the grade row needs the toggle and a card; off by default so no score lands in the page', () => {
  const present = (k) => (k === 'card' ? 2 : 0);
  const keys = (o) => receiptRows({ present, ...o }).map((r) => r.key);
  const row = (o) => receiptRows({ present, ...o }).find((r) => r.key === 'card-grade');
  assert.equal(row({}).back, true, 'listed, struck through, Turn on');
  assert.equal(row({ cardGrades: true }).back, false);
  assert.ok(!keys({ cardGrades: true, present: () => 0 }).includes('card-grade'), 'no cards, no row');
});

test('a quiz being taken switches the skin off, from the path alone', () => {
  const { isQuizTake } = require('./receipt.js');
  assert.ok(isQuizTake('/courses/4/quizzes/12/take'));
  assert.ok(isQuizTake('/courses/4/quizzes/12/take/questions'));
  assert.ok(!isQuizTake('/courses/4/quizzes/12'));
  assert.match(killReason({ quizTake: true }), /taking a quiz/);
  const present = () => 1;
  assert.ok(!receiptRows({ present }).some((r) => r.key === 'nickname'));
  assert.equal(receiptRows({ present, nicknames: 2 }).find((r) => r.key === 'nickname').label, '2 course names you chose');
});

test('handing work in is never skinned', () => {
  const { isSubmissionPath } = require('./receipt.js');
  assert.ok(isSubmissionPath('/courses/4/assignments/12/submissions'));
  assert.ok(isSubmissionPath('/courses/4/assignments/12/submissions/7'));
  assert.ok(isSubmissionPath('/courses/4/gradebook/speed_grader'));
  assert.ok(isSubmissionPath('/courses/4/assignments/12', '#submit'));
  assert.ok(!isSubmissionPath('/courses/4/assignments/12'));
  assert.ok(!isSubmissionPath('/courses/4/assignments'));
  assert.ok(!isSubmissionPath('/'));
});

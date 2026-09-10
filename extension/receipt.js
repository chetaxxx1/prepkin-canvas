// Receipt: the page skin as a list. Every change the extension makes to a
// Canvas page is one row here, with a category key, the copy the popup shows,
// and how to tell whether it applies to the page in front of you. "Put back"
// is a class on <html> (`pk-back-<key>`) that switches the row's CSS off; the
// stylesheet gates every rule on it. No row can leave a broken page: a hook
// that misses means the row is simply not on the receipt.
//
// Kept free of chrome.* and DOM writes, so `node --test` can read it and so
// boot.js can run it before the page paints.

// MARK: - Papers

/// The closed catalog. Every body ratio is ink on paper, measured, and the
/// floor is AAA (7:1): a student picking a paper is picking a reading surface.
const PAPERS = {
  newsprint: { name: 'Newsprint', cast: 'neutral', dark: false,
    paper: '#F7F6F3', paper2: '#FFFFFF', sunk: '#EFEDE8', ink: '#1B1F24', ink2: '#454B54', rule: '#E3E0D9', mark: '#2F6BAA' },
  manila:    { name: 'Manila', cast: 'warm', dark: false,
    paper: '#F2EAD9', paper2: '#FBF6EC', sunk: '#E9DFC9', ink: '#33291F', ink2: '#5E5142', rule: '#E5D7C2', mark: '#9A4A30' },
  bond:      { name: 'Bond', cast: 'cool', dark: false,
    paper: '#F4F6F8', paper2: '#FFFFFF', sunk: '#E9EDF1', ink: '#12171C', ink2: '#3E464F', rule: '#DDE3E9', mark: '#1F5FA8' },
  vellum:    { name: 'Vellum', cast: 'cream, softest', dark: false,
    paper: '#EFE7D8', paper2: '#F6F1E6', sunk: '#E5DBC8', ink: '#3C3730', ink2: '#635C51', rule: '#DED3BE', mark: '#57534A' },
  carbon:    { name: 'Carbon', cast: 'neutral dark', dark: true,
    paper: '#17191D', paper2: '#1E2126', sunk: '#121417', ink: '#E6E8EA', ink2: '#B4BAC1', rule: '#2C3037', mark: '#6FA8DC' },
  blueprint: { name: 'Blueprint', cast: 'blue-grey dark', dark: true,
    paper: '#161B22', paper2: '#1C232C', sunk: '#11151B', ink: '#DDE4EC', ink2: '#A9B4C2', rule: '#29323D', mark: '#7FB2E0' },
  // The second six, 2026-09-05: the soft tints students ask for, held to the
  // same floor. A tinted paper is still a reading surface first.
  rose:      { name: 'Rose', cast: 'blush', dark: false,
    paper: '#F8EEF0', paper2: '#FDF7F8', sunk: '#F1E3E7', ink: '#2A2024', ink2: '#5C4A52', rule: '#EAD9DE', mark: '#A8455F' },
  lavender:  { name: 'Lavender', cast: 'cool lilac', dark: false,
    paper: '#F1EEF8', paper2: '#F8F6FC', sunk: '#E7E2F2', ink: '#24212E', ink2: '#534D63', rule: '#DCD6EA', mark: '#6A4FB0' },
  sage:      { name: 'Sage', cast: 'soft green', dark: false,
    paper: '#EEF3EC', paper2: '#F6F9F5', sunk: '#E2EAE0', ink: '#1E2620', ink2: '#4A5A4E', rule: '#D7E1D6', mark: '#33704B' },
  sky:       { name: 'Sky', cast: 'pale blue', dark: false,
    paper: '#EDF3F8', paper2: '#F6F9FC', sunk: '#E1EAF2', ink: '#1B2430', ink2: '#465464', rule: '#D5E0EA', mark: '#2C6FA8' },
  ink:       { name: 'Ink', cast: 'deep navy dark', dark: true,
    paper: '#131824', paper2: '#1A2030', sunk: '#0E121B', ink: '#E4E8F0', ink2: '#AEB6C6', rule: '#28303F', mark: '#8FB8EA' },
  moss:      { name: 'Moss', cast: 'forest dark', dark: true,
    paper: '#161C18', paper2: '#1D2520', sunk: '#10150F', ink: '#E4EAE4', ink2: '#AEBBB0', rule: '#2B352E', mark: '#8CCDA6' },
  // The third four, 2026-09-06: the tints the theme galleries are actually full
  // of — sea foam, a warm study beige, peach — and one more dark to hang them
  // on. Same floor as every other stock: body text clears AAA on all four.
  seafoam:   { name: 'Sea Foam', cast: 'pale mint', dark: false,
    paper: '#EAF4F1', paper2: '#F5FAF8', sunk: '#DDEBE7', ink: '#17251F', ink2: '#42574F', rule: '#D2E3DD', mark: '#0F6B57' },
  oat:       { name: 'Oat', cast: 'warm beige', dark: false,
    paper: '#F4EEE4', paper2: '#FBF7F0', sunk: '#EAE1D2', ink: '#2A241C', ink2: '#574E42', rule: '#E2D7C6', mark: '#7A5230' },
  peach:     { name: 'Peach', cast: 'soft apricot', dark: false,
    paper: '#FBEEE7', paper2: '#FEF7F3', sunk: '#F5E2D7', ink: '#2E211A', ink2: '#5E4A3E', rule: '#EFDACC', mark: '#A9482A' },
  plum:      { name: 'Plum', cast: 'aubergine dark', dark: true,
    paper: '#191320', paper2: '#211A2A', sunk: '#120D18', ink: '#E9E4EE', ink2: '#B3AAC0', rule: '#2F2739', mark: '#C3A6EE' },
};

/// WCAG contrast ratio of two hex colours, so the shop card prints a measured
/// number and a test can hold every paper to the floor.
function contrast(a, b) {
  const lum = (hex) => {
    const n = parseInt(hex.slice(1), 16);
    const ch = [(n >> 16) & 255, (n >> 8) & 255, n & 255].map((c) => {
      const s = c / 255;
      return s <= 0.03928 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4;
    });
    return 0.2126 * ch[0] + 0.7152 * ch[1] + 0.0722 * ch[2];
  };
  const [hi, lo] = [lum(a), lum(b)].sort((x, y) => y - x);
  return (hi + 0.05) / (lo + 0.05);
}

/// How much black a student's own picture takes behind a course card.
///
/// Canvas paints its own white controls — the three-dot menu — on that band, so
/// a pale photo would swallow them. This walks the scrim up a hundredth at a
/// time and stops at the first one where white clears 4.5:1 over the picture,
/// measured with the same `contrast` every paper is held to, and on the byte
/// the screen actually gets. A bright picture is dimmed; it is never refused,
/// and the loop always answers well below its own cap.
///
/// `luminance` is the mean over the whole picture, so this is a fair answer for
/// the picture and not a promise about every pixel: a mostly dark photo with one
/// white corner can still be bright under the button. That is the student's
/// picture to choose, and the alternative — refusing it — is the thing this
/// deliberately does not do.
const OWN_ART_FLOOR = 4.5;
function scrimFor(luminance) {
  const l = Math.min(1, Math.max(0, Number(luminance) || 0));
  // The one grey of that brightness: what a flat scrim actually has to cope with.
  const value = l <= 0.0031308 ? l * 12.92 : 1.055 * l ** (1 / 2.4) - 0.055;
  for (let step = 0; step <= 85; step += 1) {
    const c = Math.round(value * (1 - step / 100) * 255) / 255;
    const lin = c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
    if (1.05 / (lin + 0.05) >= OWN_ART_FLOOR) return step / 100;
  }
  return 0.85;
}

/// "Manila · 11.9:1 · warm" — exactly this shape, on every card.
function paperLine(stockId) {
  const p = PAPERS[stockId];
  if (!p) return '';
  return `${p.name} · ${(Math.round(contrast(p.ink, p.paper) * 10) / 10).toFixed(1)}:1 · ${p.cast}`;
}

/// Which paper a Look puts on the page, by mode. Unknown looks read as Classic.
function stockFor(look, dark) {
  const pair = look?.paper ?? { light: 'newsprint', dark: 'carbon' };
  const id = dark ? pair.dark : pair.light;
  return PAPERS[id] ? id : (dark ? 'carbon' : 'newsprint');
}

// MARK: - The rows

/// `kind`: taken (removed), fixed (repaired), added (Prepkin's own, listed so it
/// is honest and removable like everything else). `hook` names a SELECTORS
/// entry that must be on the page; `detect` names a fact the content script
/// works out from the DOM; `when` is a plain predicate on the context.
/// `darkOnly` rows only exist in dark mode.
const RULES = [
  { key: 'paper', kind: 'fixed', label: (ctx) => `Page paper: ${paperLine(ctx.stock)}`, when: () => true },
  { key: 'rail', kind: 'fixed', label: 'Left menu in the theme colour', when: () => true },
  { key: 'hero', kind: 'fixed', label: 'Course colour band, thinner', hook: 'cardHero' },
  { key: 'logo-dup', kind: 'taken', label: 'The school logo, twice. One kept', detect: 'logoDup' },
  { key: 'todo-dup', kind: 'fixed', label: 'One To Do list instead of two', detect: 'todoDup' },
  { key: 'coming-up', kind: 'fixed', label: 'Coming Up shows every row', hook: 'comingUpMore' },
  { key: 'nav-dim', kind: 'fixed', hook: 'courseNavLowUse',
    // Counts what this course actually shows: many schools expose one or two of the four.
    label: (ctx, n) => `${['One', 'Two', 'Three', 'Four'][n - 1] ?? n} menu item${n === 1 ? '' : 's'} dimmed` },
  { key: 'module-sticky', kind: 'fixed', label: 'Module header stays at the top while you scroll', hook: 'moduleHeader' },
  { key: 'due-column', kind: 'fixed', label: 'Due dates lined up in one column', hook: 'moduleDue' },
  { key: 'word-paste', kind: 'fixed', label: 'Text pasted from Word, made readable', detect: 'wordPaste', darkOnly: true },
  { key: 'seam', kind: 'fixed', label: 'Pages from other companies, dimmed to match', hook: 'ltiFrame', darkOnly: true },
  { key: 'card-due', kind: 'added', label: 'Next due date on each course card', hook: 'card' },
  { key: 'card-art', kind: 'added', hook: 'card', when: (ctx) => ctx.ownArt > 0,
    label: (ctx) => `${ctx.ownArt} course picture${ctx.ownArt === 1 ? '' : 's'} you chose` },
  // `opt` rows are the student's own switches, listed here instead of in a
  // settings card: the row is struck through while the switch is off and its
  // button turns it on. Same receipt, one fewer panel of toggles.
  { key: 'card-grade', kind: 'added', label: 'Your grade on each course card', hook: 'card', opt: 'cardGrades', undo: 'Turn on' },
  { key: 'today', kind: 'added', label: 'Today, at the top of the dashboard', hook: 'card' },
  { key: 'week', kind: 'added', label: 'This week, at the top of the sidebar', hook: 'card' },
  { key: 'search', kind: 'added', label: 'Search, in the corner of every page', when: () => true, opt: 'search', undo: 'Turn on' },
  { key: 'nickname', kind: 'fixed', when: (ctx) => ctx.nicknames > 0,
    label: (ctx) => `${ctx.nicknames} course name${ctx.nicknames === 1 ? '' : 's'} you chose` },
  { key: 'dense', kind: 'added', label: 'Compact pages, tighter rows', when: () => true, opt: 'dense', undo: 'Turn on' },
  // Off by default: a table that vanished without being asked for is the kind
  // of surprise the whole receipt exists to avoid. Turning it on is one click,
  // and this row is what says the table is gone and how to get it back.
  { key: 'past-courses', kind: 'taken', label: 'Courses you have finished, folded away', hook: 'pastCourses', opt: 'hidePast', undo: 'Turn on' },
  { key: 'buddy', kind: 'added', label: 'The buddy, bottom right', when: () => true, opt: 'mascot', putBack: 'Take off', undo: 'Bring back' },
];

/// The values Word actually pastes in as text colour. Enumerated on purpose:
/// `[style*="color"]` would also match background-color, border-color and
/// outline-color and repaint text that was never black.
const WORD_INKS = ['#000000', '#000', 'black', 'rgb(0,0,0)', 'rgb(0, 0, 0)', 'windowtext',
  '#1f497d', '#333333', '#222222', '#1a1a1a'];

// MARK: - Working it out

/// The <html> classes for one page state. boot.js runs this before first
/// paint; content.js runs it again with what the DOM turned out to hold.
function skinClasses({ on, dark, look, dense = false, hidePast = false, putBack = {}, detect = {} }) {
  if (!on) return [];
  const classes = ['pk-on', `pk-paper-${stockFor(look, !!dark)}`];
  if (dark) classes.push('pk-dark');
  if (dense) classes.push('pk-dense');
  if (hidePast) classes.push('pk-hide-past');
  if (look?.id) classes.push(`pk-theme-${look.id}`);
  if (look?.header === 'wash') classes.push('pk-head-wash');
  if (look?.texture && look.texture !== 'none') classes.push('pk-textured');
  if (look?.art) classes.push('pk-art');
  for (const [key, back] of Object.entries(putBack)) if (back) classes.push(`pk-back-${key}`);
  if (detect.logoDup) classes.push('pk-logo-dup');
  if (detect.todoDup) classes.push('pk-todo-dup');
  return classes;
}

/// The receipt for one page: every row that applies, with whether it has been
/// put back. `present(hookName)` says how many times the hook matches (a
/// boolean reads as one); the content script supplies it from the DOM, tests
/// supply it directly.
function receiptRows({ present, detect = {}, dark = false, mascot = true, stock = 'newsprint', putBack = {}, cardGrades = false, dense = false, hidePast = false, nicknames = 0, ownArt = 0, search = true }) {
  const ctx = { dark, mascot, stock, detect, cardGrades, dense, hidePast, nicknames, ownArt, search };
  return RULES.flatMap((rule) => {
    if (rule.darkOnly && !dark) return [];
    const hits = rule.hook ? Number(present(rule.hook)) || 0 : 0;
    // A rule with both a hook and a `when` needs both: the picture row is only
    // true on a page that actually has cards on it.
    const applies = rule.when ? rule.when(ctx, hits) && (!rule.hook || hits > 0)
      : rule.detect ? !!detect[rule.detect]
      : hits > 0;
    if (!applies) return [];
    return [{
      key: rule.key, kind: rule.kind,
      label: typeof rule.label === 'function' ? rule.label(ctx, hits) : rule.label,
      back: rule.opt ? !ctx[rule.opt] : putBack[rule.key] === true,
      putBack: rule.putBack ?? 'Put back',
      undo: rule.undo ?? 'Undo',
      opt: rule.opt ?? null,
    }];
  });
}

/// The theme's own variables, as a stylesheet: the accent for links and marks,
/// a wash of it for card headers, and the texture drawn in the paper's ink.
/// A <style> element, never an inline property on <html>.
function themeStyle(look, textureImage, art = null) {
  if (!look) return '';
  const rule = (dark) => {
    const p = PAPERS[stockFor(look, dark)];
    const accent = look.accent?.[dark ? 'dark' : 'light'] ?? p.mark;
    const n = parseInt(accent.slice(1), 16);
    const wash = `rgba(${(n >> 16) & 255}, ${(n >> 8) & 255}, ${n & 255}, ${dark ? 0.35 : 0.45})`;
    const tex = textureImage ? textureImage(look.texture, p.ink) : 'none';
    let vars = `--pk-mark:${accent};--pk-link:${accent};--pk-accent-wash:${wash};--pk-texture:${tex};`;
    const rail = look.rail?.[dark ? 'dark' : 'light'] ?? p.ink;
    const rn = parseInt(rail.slice(1), 16);
    vars += `--pk-rail:${rail};--pk-rail-active:${accent};`;
    vars += art
      ? `--pk-rail-image:linear-gradient(rgba(${(rn >> 16) & 255}, ${(rn >> 8) & 255}, ${rn & 255}, 0.74), rgba(${(rn >> 16) & 255}, ${(rn >> 8) & 255}, ${rn & 255}, 0.74)), url("${art.wallpaper}");`
      : '--pk-rail-image:none;';
    if (art) {
      // The paper as a wash over the wallpaper, so every line still reads.
      const pn = parseInt(p.paper.slice(1), 16);
      const alpha = look.wash?.[dark ? 'dark' : 'light'] ?? 0.8;
      vars += `--pk-wallpaper:url("${art.wallpaper}");--pk-paper-wash:rgba(${(pn >> 16) & 255}, ${(pn >> 8) & 255}, ${pn & 255}, ${alpha});`
        + art.cards.map((u, i) => `--pk-card-art-${i + 1}:url("${u}");`).join('');
    }
    return vars;
  };
  // Named for the theme, so it outranks the paper class's own mark.
  return `html.pk-on.pk-theme-${look.id}{${rule(false)}}html.pk-on.pk-dark.pk-theme-${look.id}{${rule(true)}}`;
}

/// Where the popup says you are.
function pageName(pathname) {
  if (/^\/?$|^\/dashboard/.test(pathname)) return 'Dashboard';
  if (/\/modules/.test(pathname)) return 'Modules';
  if (/\/assignments\/\d+/.test(pathname)) return 'Assignment';
  if (/\/grades/.test(pathname)) return 'Grades';
  if (/^\/courses\/\d+\/?$/.test(pathname)) return 'Course home';
  if (/\/quizzes/.test(pathname)) return 'Quiz';
  return 'This page';
}

/// A current rule from Prepkin may ask this build to leave one page alone.
/// The saved answer is deliberately short-lived, and every rule must expire.
function remoteKill(flags, { host, page, version, now }) {
  if (!flags || !Number.isFinite(flags.fetchedAt) || !Array.isArray(flags.rules)) return null;
  if (now - flags.fetchedAt > 7 * 86_400_000) return null;

  const parts = (value) => {
    if (typeof value !== 'string' || !/^\d+(?:\.\d+)*$/.test(value)) return null;
    return value.split('.').map(Number);
  };
  const compare = (a, b) => {
    const left = parts(a); const right = parts(b);
    if (!left || !right) return null;
    for (let i = 0; i < Math.max(left.length, right.length); i += 1) {
      const d = (left[i] ?? 0) - (right[i] ?? 0);
      if (d) return d < 0 ? -1 : 1;
    }
    return 0;
  };

  for (const rule of flags.rules) {
    if (!rule || typeof rule !== 'object') continue;
    const end = Date.parse(rule.endsAt ?? '');
    if (!Number.isFinite(end) || end <= now) continue;
    if (rule.host !== '*' && rule.host !== host) continue;
    if (rule.page !== '*' && rule.page !== page) continue;
    if (rule.minVer != null) {
      const order = compare(version, rule.minVer);
      if (order === null || order < 0) continue;
    }
    if (rule.maxVer != null) {
      const order = compare(version, rule.maxVer);
      if (order === null || order > 0) continue;
    }
    return typeof rule.note === 'string' && rule.note.trim()
      ? rule.note
      : 'Prepkin is staying out of the way on this page for now.';
  }
  return null;
}

/// Canvas's sign-in pages, which the skin never touches in any mode.
function isLoginPath(pathname) {
  return /^\/(login|logout|register|confirmations)(\/|$)|^\/users\/[^/]+\/(password|confirm)/.test(pathname);
}

/// When the skin has to stay out of the way entirely, and the sentence the
/// popup shows for it. Order matters: the first reason wins.
/// A quiz being taken. Nothing of ours belongs on that page, not even paper.
function isQuizTake(pathname) {
  return /\/quizzes\/\d+\/take(\b|\/|$)/.test(pathname);
}

/// A student handing work in. The submission flow stays entirely Canvas's.
function isSubmissionPath(pathname, hash = '') {
  return /\/courses\/\d+\/assignments\/\d+\/submissions(?:\/|$)/.test(pathname)
    || pathname.includes('/gradebook/speed_grader')
    || (/^\/courses\/\d+\/assignments\/\d+\/?$/.test(pathname) && hash === '#submit');
}

function killReason({ remote = '', forcedColors = false, prefersContrast = false, envHighContrast = false,
                      newQuizzes = false, widgetDashboard = false, loginPage = false, quizTake = false,
                      submitting = false, editorOpen = false } = {}) {
  if (loginPage) return 'This is the sign-in page. It stays the school\'s.';
  if (quizTake) return 'You are taking a quiz. Receipt stays out of the way.';
  if (remote) return remote;
  if (submitting) return 'You are handing something in. Receipt stays out of the way.';
  if (editorOpen) return 'The editor is open. Receipt stays out of the way.';
  if (envHighContrast) return 'Your school has High Contrast on. Receipt stays out of the way.';
  if (forcedColors || prefersContrast) return 'High Contrast is on. Receipt stays out of the way.';
  if (newQuizzes) return 'This is a New Quizzes page. Receipt stays out of the way.';
  if (widgetDashboard) return 'Canvas is trying a new dashboard here. Receipt stays out of the way.';
  return null;
}

/// Whether this page script no longer owns the page, either because its
/// extension context is gone or a newer instance has taken over.
function shouldStepAside({ mine, current, alive }) {
  return !alive || (!!current && current !== mine);
}

if (typeof module !== 'undefined') {
  module.exports = { PAPERS, RULES, WORD_INKS, contrast, scrimFor, paperLine, stockFor, skinClasses, receiptRows, pageName, remoteKill, killReason, isLoginPath, isQuizTake, isSubmissionPath, themeStyle, shouldStepAside };
}

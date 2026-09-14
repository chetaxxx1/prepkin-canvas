// The real extension on a real Canvas dressed as each real school.
//
// Instructure's cloud runs one Canvas build for every school (harvest.js
// records the build id; they all match), so what differs from one school to
// the next is the theme — the brand variables and the Theme Editor CSS and
// JavaScript — and that is public: every sign-in page loads it. This test puts
// each harvested school's theme onto the sandbox's real pages, with the real
// extension on top, and asks the questions a student at that school would:
// did the paper come through the school's CSS, is the buddy there, did every
// hook the receipt hangs off still match, and did nothing of ours error.
//
//   ssh -N -L 3000:localhost:3000 canvas@VM        (the sandbox tunnel)
//   node test/schools/harvest.js                   (once; fills test/schools/)
//   node --test test/schools.test.js               (all schools)
//   SCHOOLS=canvas.mit.edu,bcourses.berkeley.edu node --test test/schools.test.js
//
// Without the tunnel (or with CANVAS_UPSTREAM=none) it runs against the fake
// Canvas's skeleton pages instead — the school's CSS still fights ours, just
// on plainer ground — and finishes in minutes rather than hours.
//
// Findings go to design/signoff/canvas-schools/: one dashboard screenshot per
// school and report.json with every measurement.

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

const test = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const net = require('net');
const path = require('path');
const { FakeServer } = require('./fake-canvas');
const { launch, SCHOOL_A, BRIDGE } = require('./harness');
const { SELECTORS } = require('../extension/selectors');
const S = require('./scenarios');

const SCHOOLS_DIR = path.join(__dirname, 'schools');
const OUT = path.join(__dirname, '..', 'design', 'signoff', process.env.CANVAS_UPSTREAM === 'none' ? 'canvas-schools-fake' : 'canvas-schools');
const UPSTREAM = process.env.CANVAS_UPSTREAM || 'http://127.0.0.1:3000';
const STUDENT = { login: 'alex@prepkin.test', password: 'PrepkinSandbox!2026' };
// The paper's two tones, light and dark (skin.css: Newsprint and Carbon).
const TONES = { light: [[247, 246, 243], [255, 255, 255]], dark: [[23, 25, 29], [30, 33, 38]] };
// The hooks that carry rules today; a miss means the school's JavaScript took
// the ground away, or a Canvas deploy did.
const LOAD_BEARING = ['navRail', 'headerLogo', 'card', 'cardHero', 'courseNav', 'courseNavLowUse', 'moduleHeader', 'moduleDue', 'userContent'];

let server, h, page, real, pages, report = {};
let dialogs = [];
let ours = [];
const control = (p, body) => fetch(`${BRIDGE}/__${p}`, { method: 'POST', body: JSON.stringify(body ?? {}) }).then((r) => r.json());

function tunnelUp() {
  if (process.env.CANVAS_UPSTREAM === 'none') return Promise.resolve(false);
  return new Promise((resolve) => {
    const u = new URL(UPSTREAM);
    const s = net.connect(Number(u.port), u.hostname, () => { s.destroy(); resolve(true); });
    s.on('error', () => resolve(false));
  });
}

function schools() {
  const named = process.env.SCHOOLS?.split(',').map((s) => s.trim()).filter(Boolean);
  return fs.readdirSync(SCHOOLS_DIR)
    .filter((d) => fs.existsSync(path.join(SCHOOLS_DIR, d, 'theme.json')))
    .filter((d) => !named || named.includes(d))
    .map((d) => ({ host: d, dir: path.join(SCHOOLS_DIR, d), theme: JSON.parse(fs.readFileSync(path.join(SCHOOLS_DIR, d, 'theme.json'), 'utf8')) }))
    .filter((s) => fs.existsSync(path.join(s.dir, 'custom.css')) || fs.existsSync(path.join(s.dir, 'custom.js')) || fs.existsSync(path.join(s.dir, 'variables.css')));
}

/// The rendered colour at one point — what the student sees, not what a
/// stylesheet claims. A 1x1 PNG is eight bytes past its IDAT. The fake's
/// pages are short, so the point is kept inside whatever is on screen.
async function pixelAt(x, y) {
  // Not `innerWidth`: one district's theme script declares a global of that
  // name and the sample landed on its nav rail (a content script's own
  // world never sees such a global, so the extension is not affected).
  const box = await page.evaluate(() => ({ w: document.documentElement.clientWidth, h: Math.min(document.documentElement.clientHeight, document.documentElement.scrollHeight) }));
  x = Math.min(x, box.w - 2); y = Math.min(y, box.h - 2);
  const png = await page.screenshot({ clip: { x, y, width: 1, height: 1 } });
  let off = 8; const idat = [];
  while (off < png.length) {
    const len = png.readUInt32BE(off); const type = png.toString('ascii', off + 4, off + 8);
    if (type === 'IDAT') idat.push(png.subarray(off + 8, off + 8 + len));
    off += 12 + len;
  }
  const raw = require('zlib').inflateSync(Buffer.concat(idat));
  return [raw[1], raw[2], raw[3]];
}
const isTone = (rgb, tones) => tones.some((t) => t.join() === rgb.join());

/// A point on the page ground that is content column and nothing else: just
/// inside `#content`'s left padding, clear of the header line, and inside the
/// viewport. The same spot on every Canvas page and on the fake's skeleton.
async function groundPoint() {
  return page.evaluate(() => {
    const r = (document.getElementById('content') ?? document.body).getBoundingClientRect();
    // Clear of the global nav rail even where a school's theme widens it
    // (Charlotte-Mecklenburg's is 93px, and 6px into the content column was
    // still on it), and short of the first card.
    const rail = document.getElementById('header')?.getBoundingClientRect();
    const x = Math.round(Math.max(r.left + 6, (rail?.right ?? 0) + 12));
    const y = Math.round(Math.min(r.top + 150, innerHeight - 3, r.bottom - 3));
    return [Math.max(x, 1), Math.max(y, 1)];
  });
}

/// A fresh tab for every page. Stanford's theme script holds the dashboard
/// in a synchronous request loop that Chromium under Playwright never
/// navigates away from — a wedge that, on one shared tab, took every school
/// after it down with it. A student never navigates from a wedged tab either;
/// they open the next page. So does this.
async function freshPage() {
  if (page) await page.close({ runBeforeUnload: false }).catch(() => {});
  page = await h.context.newPage();
  page.setDefaultNavigationTimeout(120_000);
  page.setDefaultTimeout(60_000);
  // A school's script may put up a dialog, or ask "leave this page?" on the
  // way out. Playwright's default is to dismiss, which for a leave-page
  // question means "stay". Say yes, and note it, so the school's row shows it.
  page.on('dialog', (d) => { dialogs.push(`${d.type()}: ${d.message().slice(0, 120)}`); d.accept().catch(() => {}); });
  page.on('console', (msg) => { if (msg.type() === 'error' && /chrome-extension:/.test(msg.location()?.url ?? '')) ours.push(msg.text()); });
  page.on('pageerror', (e) => { if (/chrome-extension:/.test(e.stack ?? '')) ours.push(e.message); });
  return page;
}

async function open(p) {
  await freshPage();
  // A real page through the tunnel on a busy Mac can miss the two-minute
  // mark once; a second miss is the school's problem, or the day's.
  try {
    await page.goto(`${SCHOOL_A}${p}`, { waitUntil: 'domcontentloaded' });
  } catch (e) {
    if (e.name !== 'TimeoutError') throw e;
    console.log(`  ${p}: first try timed out at ${page.url()}; ${dialogs.length ? `dialogs: ${dialogs.join(' | ')}` : 'no dialog'}`);
    await freshPage();
    await page.goto(`${SCHOOL_A}${p}`, { waitUntil: 'domcontentloaded' });
  }
  await page.waitForLoadState('networkidle', { timeout: 30_000 }).catch(() => {});
  // The dashboard is React: its cards and sidebar arrive by XHR after load,
  // and a busy machine makes that slow. Measure the real cards, not the
  // grey placeholders drawn while they load.
  if (p === '/') await page.waitForSelector('.ic-DashboardCard__header_hero', { state: 'attached', timeout: 90_000 }).catch(() => {});
  // A school's deferred script runs after load; give it its say too.
  await page.waitForTimeout(real ? 1800 : 400);
}

test.before(async () => {
  fs.mkdirSync(OUT, { recursive: true });
  real = await tunnelUp();
  server = await new FakeServer(real ? { upstream: UPSTREAM } : {}).start(8443);
  h = await launch();
  // Nothing a school's script asks for may leave this machine: its own
  // dependencies are served from the harvest, everything else is refused.
  const local = (u) => /^https:\/\/(localhost|127\.0\.0\.1):8443\//.test(u) || /^(chrome|chrome-extension|devtools|about|data|blob):/.test(u);
  if (!process.env.SCHOOLS_NET) await h.context.route((u) => !local(u.href), (route) => {
    const dep = server.theme && depFile(server.theme, route.request().url());
    if (dep) return route.fulfill({ status: 200, contentType: 'application/javascript', body: fs.readFileSync(dep) });
    return route.abort('blockedbyclient');
  });
  await freshPage();
  await h.setStorage({ onboarded: true, skin: { dark: false, cards: true, mascot: true, focusMinutes: 25 } });
  if (real) {
    await page.goto(`${SCHOOL_A}/login/canvas`, { waitUntil: 'domcontentloaded', timeout: 120_000 });
    await page.fill('#pseudonym_session_unique_id', STUDENT.login);
    await page.fill('#pseudonym_session_password', STUDENT.password);
    await page.press('#pseudonym_session_password', 'Enter');
    await page.waitForURL((u) => !u.pathname.startsWith('/login'), { timeout: 120_000, waitUntil: 'domcontentloaded' });
    // The student's own courses and one open assignment, through the session.
    const courses = await page.evaluate(() => fetch('/api/v1/courses?enrollment_state=active&per_page=100', { headers: { Accept: 'application/json' } }).then((r) => r.text()).then((t) => JSON.parse(t.replace(/^while\(1\);/, ''))));
    const physics = courses.find((c) => /AP Physics/.test(c.name)) ?? courses[0];
    assert.ok(physics, 'seed.py has not run on this sandbox');
    const assignments = await page.evaluate((id) => fetch(`/api/v1/courses/${id}/assignments?per_page=100`, { headers: { Accept: 'application/json' } }).then((r) => r.text()).then((t) => JSON.parse(t.replace(/^while\(1\);/, ''))), physics.id);
    const a = assignments.find((x) => /Problem Set 8/.test(x.name)) ?? assignments[0];
    pages = { dashboard: '/', course: `/courses/${physics.id}`, modules: `/courses/${physics.id}/modules`, assignment: `/courses/${physics.id}/assignments/${a.id}`, grades: `/courses/${physics.id}/grades`, courses: '/courses' };
  } else {
    await control('world', { host: 'localhost', world: S.plainSemester() });
    pages = { dashboard: '/', course: '/courses/1', modules: '/courses/1/modules', assignment: '/courses/1/assignments/11', grades: '/courses/1/grades', courses: '/courses' };
  }
  await h.connect(SCHOOL_A);
  // One sync first, so every school is measured with the rail and the card
  // lines on the page — the busiest state, and the same state for each.
  if (real) await h.sw((o) => syncNow(o), SCHOOL_A);
});

/// Folded into what earlier runs found, so a re-run of a few schools
/// (SCHOOLS=a,b) updates their rows and keeps everyone else's. Written after
/// every school, not at the end: a run of seventy schools takes hours, and a
/// Mac that reboots in hour two should not take hour one with it.
function saveReport() {
  const file = path.join(OUT, 'report.json');
  let previous = {};
  try { previous = JSON.parse(fs.readFileSync(file, 'utf8')).schools ?? {}; } catch {}
  fs.writeFileSync(file, `${JSON.stringify({ at: new Date().toISOString(), real, schools: { ...previous, ...report } }, null, 2)}\n`);
}

test.after(async () => {
  saveReport();
  await h?.close(); await server?.stop();
});

function depFile(dir, url) {
  try {
    const theme = JSON.parse(fs.readFileSync(path.join(dir, 'theme.json'), 'utf8'));
    const file = theme.deps?.[url]?.file;
    return file && fs.existsSync(path.join(dir, file)) ? path.join(dir, file) : null;
  } catch { return null; }
}

// The theme files are gitignored (harvest.js writes them): a fresh worktree has
// theme.json alone, and a run with nothing to test used to sit forever in
// test.before with no word. Say so instead.
const SCHOOLS = schools();
assert.ok(SCHOOLS.length, 'no school under test/schools has its theme files: run node test/schools/harvest.js, or copy test/schools/ from the main checkout');

for (const school of SCHOOLS) {
  test(`${school.host}: the paper, the buddy and every hook survive the school's theme`, { timeout: 900_000 }, async () => {
    await control('theme', { dir: school.dir });
    const r = { at: new Date().toISOString(), build: school.theme.build, files: Object.keys(school.theme.files), pages: {}, errors: [], dialogs: [] };
    report[school.host] = r;
    dialogs = r.dialogs;
    ours = [];
    try {
      await h.setStorage({ skin: { dark: false, cards: true, mascot: true, focusMinutes: 25 } });
      // A school with only brand colours cannot move the ground under a hook;
      // one page in each paper is its whole story. Custom CSS or JavaScript
      // gets the pages the rules live on.
      const themed = school.theme.files['custom.css'] || school.theme.files['custom.js'];
      for (const [name, p] of Object.entries(pages)) {
        if (!(themed ? ['dashboard', 'modules', 'assignment'] : ['dashboard']).includes(name)) continue;
        await open(p);
        const on = await page.evaluate(() => document.documentElement.classList.contains('pk-on'));
        const buddy = await page.evaluate(() => !!document.getElementById('prepkin-buddy'));
        const hooks = {};
        for (const key of LOAD_BEARING) {
          const { sel, page: where } = SELECTORS[key];
          if (where !== name && where !== 'any') continue;
          hooks[key] = await page.evaluate((q) => document.querySelectorAll(q).length, sel);
        }
        const at = await groundPoint();
        const content = await pixelAt(...at);
        const side = name === 'dashboard' ? await page.evaluate(() => { const b = document.getElementById('right-side')?.getBoundingClientRect(); return b && b.width > 0 && b.top + 300 < innerHeight ? [Math.round(b.left + 30), Math.round(b.top + 300)] : null; }) : null;
        const sidebar = side ? await pixelAt(...side) : null;
        r.pages[name] = { on, buddy, hooks, at, content, contentIsPaper: isTone(content, TONES.light), sidebar, sidebarIsPaper: sidebar ? isTone(sidebar, TONES.light) : null };
        if (name === 'dashboard') await page.screenshot({ path: path.join(OUT, `${school.host}-dashboard.png`) });
      }
      // Dark is the promise students install for. One page, the busiest.
      await h.setStorage({ skin: { dark: true, cards: true, mascot: true, focusMinutes: 25 } });
      await open(pages.dashboard);
      const dark = await pixelAt(...await groundPoint());
      r.pages.dashboardDark = { content: dark, contentIsPaper: isTone(dark, TONES.dark) };
      await page.screenshot({ path: path.join(OUT, `${school.host}-dark.png`) });
      await h.setStorage({ skin: { dark: false, cards: true, mascot: true, focusMinutes: 25 } });
    } finally {
      await control('theme', { dir: null });
    }
    const { errorLog = [] } = await h.storage();
    r.errors = [...ours, ...errorLog.map((e) => `${e.where}: ${e.message}`)];
    await h.sw(() => chrome.storage.local.remove('errorLog'));
    saveReport();

    // What must hold at every school.
    for (const [name, p] of Object.entries(r.pages)) {
      if (name === 'dashboardDark') continue;
      assert.ok(p.on, `${name}: the skin classes are on <html>`);
      assert.ok(p.buddy, `${name}: the buddy mounted`);
      for (const [key, n] of Object.entries(p.hooks)) assert.ok(n > 0, `${name}: ${key} (${SELECTORS[key].sel}) matches nothing under this theme`);
      assert.ok(p.contentIsPaper, `${name}: the page ground is ${p.content}, not the paper — the school's CSS won`);
    }
    assert.ok(r.pages.dashboardDark.contentIsPaper, `dark: the ground is ${r.pages.dashboardDark.content}, not Carbon — dark mode lost to the school's CSS`);
    assert.deepEqual(r.errors, [], 'nothing of ours errored');
  });
}

// Collects what a real school's Canvas looks like without logging in: one
// anonymous GET of its sign-in page, which loads the same brand variables and
// the same Theme Editor CSS and JavaScript as every page a student sees. Those
// files are what differ between schools — Instructure's cloud runs one Canvas
// build for all of them — so they are what the cross-school run in
// schools.test.js puts in front of the extension.
//
//   node test/schools/harvest.js                 # every host in hosts.txt
//   node test/schools/harvest.js canvas.mit.edu  # one
//   node test/schools/harvest.js --new           # only hosts not yet harvested
//   node test/schools/harvest.js --beta          # the NEXT release: each school's beta host
//
// Writes test/schools/<host>/theme.json (kept in git: URLs, brand values, the
// build id) and custom.css / custom.js / variables.css (not in git — a
// school's own files, fetched again when missing).

const fs = require('fs');
const path = require('path');

const HERE = __dirname;
const UA = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) PrepkinCanvasThemeCheck/0.1 (read-only)';

async function get(url) {
  const res = await fetch(url, { redirect: 'follow', headers: { 'User-Agent': UA, Accept: 'text/html,text/css,*/*' }, signal: AbortSignal.timeout(15_000) });
  return { status: res.status, url: res.url, headers: res.headers, text: await res.text() };
}

const unescape = (s) => s.replace(/&amp;/g, '&');

/// The links and scripts in the head, in document order, with what each is.
function assets(html) {
  const out = [];
  const re = /<(link|script)\b([^>]*)>/g;
  let m;
  while ((m = re.exec(html))) {
    const attrs = m[2];
    const href = (attrs.match(/\b(?:href|src)="([^"]+)"/) || [])[1];
    if (!href) continue;
    const url = unescape(href);
    const isCss = m[1] === 'link' && /stylesheet/.test(attrs);
    const isJs = m[1] === 'script';
    if (!isCss && !isJs) continue;
    let kind = null;
    if (/\/brandable_css\/[0-9a-f]{32}\/variables-/.test(url)) kind = 'variables';
    else if (/instructure-uploads|\/accounts\/\d+\/files\/|\/account_\d+\//.test(url) && /\.css(\?|$)/.test(url) && isCss) kind = 'custom.css';
    else if (/instructure-uploads|\/accounts\/\d+\/files\/|\/account_\d+\//.test(url) && /\.js(\?|$)/.test(url) && isJs) kind = 'custom.js';
    if (kind) out.push({ kind, url });
  }
  return out;
}

/// A school's CSS usually starts with `@import url(...)` of a vendor sheet
/// (DesignPLUS, EvaluationKIT). Those are part of what the student sees, so
/// they are pulled in place, two levels deep, and the file stands alone.
async function inlineImports(css, depth = 0) {
  if (depth > 2) return css;
  const re = /@import\s+(?:url\()?\s*['"]?([^'")\s;]+)['"]?\s*\)?[^;]*;/g;
  const parts = []; let last = 0; let m;
  while ((m = re.exec(css))) {
    parts.push(css.slice(last, m.index));
    last = m.index + m[0].length;
    try {
      const r = await get(m[1]);
      parts.push(r.status === 200
        ? `/* prepkin harvest: imported ${m[1]} */\n${await inlineImports(r.text, depth + 1)}\n/* end ${m[1]} */`
        : `/* prepkin harvest: ${m[1]} answered ${r.status} */`);
    } catch (e) {
      parts.push(`/* prepkin harvest: ${m[1]} failed: ${e.message} */`);
    }
  }
  parts.push(css.slice(last));
  return parts.join('');
}

/// The scripts a school's JavaScript loads by hand (`script.src = 'https://…'`)
/// — a vendor's page tools, a survey widget — kept beside it so the
/// cross-school run can serve them without the network.
async function fetchDeps(js, dir) {
  const urls = [...new Set([...js.matchAll(/https:\/\/[^'"\s`]+\.js(?:\?[^'"\s`]*)?/g)].map((m) => m[0]))].slice(0, 6);
  const deps = {};
  fs.mkdirSync(path.join(dir, 'deps'), { recursive: true });
  for (const [i, url] of urls.entries()) {
    try {
      const r = await get(url);
      if (r.status !== 200 || r.text.length > 3_000_000) { deps[url] = { status: r.status, bytes: r.text.length }; continue; }
      const file = `deps/${i}.js`;
      fs.writeFileSync(path.join(dir, file), r.text);
      deps[url] = { file, bytes: Buffer.byteLength(r.text) };
    } catch (e) {
      deps[url] = { error: e.message };
    }
  }
  return deps;
}

async function harvest(host) {
  const dir = path.join(HERE, host);
  const page = await get(`https://${host}/login/canvas`);
  const isCanvas = /brandable_css|ic-Login|window\.ENV|CANVAS_ACTIVE_BRAND_VARIABLES/.test(page.text);
  // An unassigned *.instructure.com name answers with Instructure's own
  // "can't find your login page" (a 404 on a bare layout) — Canvas, but
  // nobody's school.
  if (!isCanvas || page.status === 404 || /bare-layout/.test(page.text)) return { host, canvas: false, status: page.status, final: page.url };
  // Schools on the React sign-in page (`new_login`) do not load the Theme
  // Editor files there. Canvas's not-found page uses the ordinary layout for
  // everyone, signed in or not, and that layout carries them — and the build
  // id and the body classes the flags leave.
  const missing = await get(`https://${host}/prepkin-theme-check`);
  const html = /brandable_css/.test(missing.text) ? missing.text : page.text;
  const found = assets(html);
  const meta = page.headers.get('x-canvas-meta') || missing.headers.get('x-canvas-meta') || '';
  const theme = {
    host,
    final: new URL(page.url).host,
    fetchedAt: new Date().toISOString(),
    build: (html.match(/bundles\/common-([0-9a-f]+)\.css/) || [])[1] ?? null,
    cluster: (meta.match(/c=([^;]+)/) || [])[1] ?? null,
    region: (meta.match(/z=([^;]+)/) || [])[1] ?? null,
    bucketMax: Number((meta.match(/rlr=([\d.]+)/) || [])[1]) || null,
    newLogin: !/ic-Login-Body/.test(page.text),
    // Canvas's only always-on policy is frame-ancestors; a school that added
    // style-src or script-src would block the stylesheet our content script
    // appends, so it is worth knowing about before that happens.
    csp: missing.headers.get('content-security-policy') || page.headers.get('content-security-policy') || null,
    bodyClass: (html.match(/<body[^>]*class="([^"]*)"/) || [])[1] ?? '',
    files: {},
    brand: {},
  };
  fs.mkdirSync(dir, { recursive: true });
  for (const { kind, url } of found) {
    if (theme.files[kind]) continue; // the first of each; a login page names each once
    try {
      const r = await get(url);
      if (r.status !== 200) { theme.files[kind] = { url, status: r.status }; continue; }
      let text = r.text;
      if (kind === 'custom.css') text = await inlineImports(text);
      if (kind === 'custom.js') theme.deps = await fetchDeps(text, dir);
      fs.writeFileSync(path.join(dir, kind === 'variables' ? 'variables.css' : kind), text);
      theme.files[kind] = { url, bytes: Buffer.byteLength(text) };
      if (kind === 'variables') {
        for (const [, k, v] of r.text.matchAll(/--(ic-[a-z0-9-]+)\s*:\s*([^;}]+)/g)) theme.brand[k] = v.trim();
      }
    } catch (e) {
      theme.files[kind] = { url, error: e.message };
    }
  }
  fs.writeFileSync(path.join(dir, 'theme.json'), `${JSON.stringify(theme, null, 2)}\n`);
  return { host, canvas: true, build: theme.build, files: Object.keys(theme.files), newLogin: theme.newLogin };
}

/// Instructure's beta environment runs the next release about three weeks
/// before production does, and every school's policy header names its beta
/// host. Read the not-found page there — no login — for the build id and the
/// global hooks the skin hangs off, and say which schools' beta already
/// differs from their production: that is the early warning that a deploy is
/// coming, and the moment to run test/live.test.js L7 against beta.
async function beta(hosts) {
  const rows = [];
  for (const host of hosts) {
    const theme = JSON.parse(fs.readFileSync(path.join(HERE, host, 'theme.json'), 'utf8'));
    const betaHost = (theme.csp || '').split(/\s+/).find((w) => /\.beta\.instructure\.com$/.test(w));
    if (!betaHost) { rows.push({ host, beta: null }); continue; }
    try {
      const r = await get(`https://${betaHost}/prepkin-theme-check`);
      const html = r.text;
      rows.push({
        host, beta: betaHost, production: theme.build,
        build: (html.match(/bundles\/common-([0-9a-f]+)\.css/) || [])[1] ?? null,
        hooks: {
          navRail: /<header id="header" class="ic-app-header/.test(html),
          headerLogo: /ic-app-header__logomark-container/.test(html),
          skipLink: /id="skip_navigation_link"/.test(html),
          layout: /ic-Layout-wrapper/.test(html),
        },
      });
    } catch (e) {
      rows.push({ host, beta: betaHost, error: e.message });
    }
  }
  const ahead = rows.filter((r) => r.build && r.production && r.build !== r.production);
  for (const r of rows) console.log(`${r.host}: ${r.beta ? `beta ${r.build ?? '?'} vs production ${r.production}${r.build && r.build !== r.production ? '  <-- NEXT RELEASE' : ''} ${Object.entries(r.hooks ?? {}).filter(([, v]) => !v).map(([k]) => `MISSING ${k}`).join(' ')}` : 'no beta host in its policy'}`);
  console.log(`\n${ahead.length} of ${rows.length} schools' beta run a newer build than production.`);
  fs.writeFileSync(path.join(HERE, 'beta.json'), `${JSON.stringify({ at: new Date().toISOString(), rows }, null, 2)}\n`);
}

async function main() {
  if (process.argv[2] === '--beta') {
    const hosts = process.argv.slice(3);
    return beta(hosts.length ? hosts : fs.readdirSync(HERE).filter((d) => fs.existsSync(path.join(HERE, d, 'theme.json'))));
  }
  const onlyNew = process.argv[2] === '--new';
  const named = onlyNew ? [] : process.argv.slice(2);
  let hosts = named.length ? named
    : fs.readFileSync(path.join(HERE, 'hosts.txt'), 'utf8').split('\n').map((l) => l.trim()).filter((l) => l && !l.startsWith('#'));
  if (onlyNew) hosts = hosts.filter((h) => !fs.existsSync(path.join(HERE, h, 'theme.json')));
  const summary = [];
  for (const host of hosts) {
    try {
      const r = await harvest(host);
      summary.push(r);
      console.log(r.canvas ? `${host}: canvas${r.build ? ` build ${r.build}` : ''}, ${r.files.join(' ')}${r.newLogin ? ', new login' : ''}` : `${host}: not Canvas (${r.status} ${r.final})`);
    } catch (e) {
      summary.push({ host, error: e.message });
      console.log(`${host}: ${e.name === 'TimeoutError' ? 'timed out' : e.message}`);
    }
  }
  const canvas = summary.filter((r) => r.canvas);
  console.log(`\n${canvas.length} of ${hosts.length} answered as Canvas`);
}

if (require.main === module) main();
module.exports = { harvest, assets };

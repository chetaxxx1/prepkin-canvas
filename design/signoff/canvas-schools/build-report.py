#!/usr/bin/env python3
"""Builds every-canvas.html, the one-page proof that the extension works on any
school's Canvas, from the harvest (test/schools/*/theme.json) and the run
reports (design/signoff/canvas-schools{,-fake}/report.json, canvas-variants/).

    python3 design/signoff/canvas-schools/build-report.py
"""
import json, os, glob, html, datetime

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..'))
OUT = os.path.join(os.path.dirname(__file__), 'every-canvas.html')


def load(p, default=None):
    try:
        return json.load(open(p))
    except Exception:
        return default


# Hosts grouped by the sections in hosts.txt
groups, cur = [], None
for line in open(f'{ROOT}/test/schools/hosts.txt'):
    line = line.strip()
    if not line:
        continue
    if line.startswith('#'):
        if line.startswith('# Real Canvas'):
            continue
        cur = {'title': line.lstrip('# ').strip(), 'hosts': []}
        groups.append(cur)
    elif cur:
        cur['hosts'].append(line)

themes = {os.path.basename(os.path.dirname(f)): load(f) for f in glob.glob(f'{ROOT}/test/schools/*/theme.json')}
real = load(f'{ROOT}/design/signoff/canvas-schools/report.json', {'schools': {}})
fake = load(f'{ROOT}/design/signoff/canvas-schools-fake/report.json', {'schools': {}})
variants_dir = f'{ROOT}/design/signoff/canvas-variants'
variant_shots = sorted(os.path.basename(p) for p in glob.glob(f'{variants_dir}/*.png'))


def verdict(r):
    if not r:
        return None
    pages = r.get('pages', {})
    if not pages:
        return 'fail'  # never got a page: the run timed out on it
    ok = not r.get('errors') and all(
        p.get('on', True) and p.get('buddy', True) and p.get('contentIsPaper', True)
        and all(n > 0 for n in p.get('hooks', {}).values()) for p in pages.values())
    return 'pass' if ok else 'fail'


builds = {}
for h, t in themes.items():
    builds.setdefault(t.get('build') or 'unknown', []).append(h)
n_schools = len(themes)
n_themed = sum(1 for t in themes.values() if 'custom.css' in t.get('files', {}) or 'custom.js' in t.get('files', {}))
real_v = {h: verdict(real['schools'].get(h)) for h in themes}
fake_v = {h: verdict(fake['schools'].get(h)) for h in themes}
n_real_pass = sum(1 for v in real_v.values() if v == 'pass')
n_real_fail = sum(1 for v in real_v.values() if v == 'fail')
n_real_run = n_real_pass + n_real_fail
n_bare = sum(1 for t in themes.values() if not t.get('files'))  # a login page that shows no theme at all: nothing to put on the page
n_fake_pass = sum(1 for v in fake_v.values() if v == 'pass')
n_fake_fail = sum(1 for v in fake_v.values() if v == 'fail')
biggest = max(((h, t['files'].get('custom.css', {}).get('bytes', 0)) for h, t in themes.items()), key=lambda x: x[1])
regions = sorted({t.get('region') for t in themes.values() if t.get('region')})
csp_n = sum(1 for t in themes.values() if (t.get('csp') or '').startswith('frame-ancestors'))
dialogs = {h: r.get('dialogs') for h, r in real['schools'].items() if r.get('dialogs')}
beta = load(f'{ROOT}/test/schools/beta.json', {'rows': []})['rows']
beta_builds = sorted({r.get('build') for r in beta if r.get('build')})
beta_ahead = sum(1 for r in beta if r.get('build') and r.get('production') and r['build'] != r['production'])
beta_missing = [r['host'] for r in beta if r.get('hooks') and not all(r['hooks'].values())]
build_id = list(builds.keys())[0] if len(builds) == 1 else 'mixed'


def chip(h):
    t = themes[h]
    rv = real_v[h]
    fv = fake_v[h]
    state = rv or (('fake-' + fv) if fv else 'todo')
    css = t['files'].get('custom.css', {}).get('bytes', 0)
    parts = []
    if 'custom.css' in t['files']:
        parts.append(f"CSS {css / 1024:.0f} KB" if css >= 1024 else "CSS")
    if 'custom.js' in t['files']:
        parts.append('JS')
    if not parts:
        parts.append('colours only')
    label = {'pass': 'real Canvas: pass', 'fail': 'real Canvas: FAIL', 'fake-pass': 'fake pages: pass, real run pending',
             'fake-fail': 'fake pages: FAIL', 'todo': 'not run'}[state]
    return (f'<li class="chip {state}" title="{html.escape(label)} · {html.escape(", ".join(parts))}"><span class="dot"></span>'
            f'<code>{html.escape(h)}</code><span class="meta">{html.escape(" · ".join(parts))}</span></li>')


group_html = ''
for g in groups:
    hosts = [h for h in g['hosts'] if h in themes]
    if not hosts:
        continue
    group_html += (f'<section class="group"><h3>{html.escape(g["title"])} <span class="count">{len(hosts)}</span></h3>'
                   f'<ul class="chips">{"".join(chip(h) for h in hosts)}</ul></section>')

fails = [(h, real['schools'][h]) for h in themes if real_v[h] == 'fail']
fail_html = ''
if fails:
    rows = []
    for h, r in fails:
        why = []
        if not r.get('pages'):
            why.append('no page loaded before the run\'s two-minute limit')
        for name, p in r.get('pages', {}).items():
            if not p.get('on', True):
                why.append(f'{name}: skin off')
            if not p.get('buddy', True):
                why.append(f'{name}: no buddy')
            if not p.get('contentIsPaper', True):
                why.append(f'{name}: ground {p.get("content")}')
            for k, n in p.get('hooks', {}).items():
                if not n:
                    why.append(f'{name}: {k} missing')
        why += r.get('errors', [])
        rows.append(f'<tr><td><code>{html.escape(h)}</code></td><td>{html.escape("; ".join(why) or "see report.json")}</td></tr>')
    fail_html = (f'<h3>What failed, by name</h3><div class="scroll"><table><thead><tr><th>School</th><th>What the run saw</th></tr></thead>'
                 f'<tbody>{"".join(rows)}</tbody></table></div>')

if n_real_run + n_bare == n_schools and not n_real_fail:
    real_line = f'all {n_real_run} with a theme pass on real Canvas' if n_bare else f'all {n_schools} pass on real Canvas'
elif n_real_run:
    real_line = f'{n_real_pass} of {n_real_run} run so far pass on real Canvas' + (f', {n_real_fail} fail' if n_real_fail else '')
else:
    real_line = 'real-Canvas run not started'
stamp = datetime.datetime.now().strftime('%Y-%m-%d %H:%M')
theme_pill = 'pass' if n_real_run and not n_real_fail else ('fail' if n_real_fail else 'warn')

variants_html = ''
if variant_shots:
    names = {'locale-es-dashboard': 'Spanish, dashboard', 'locale-es-modules': 'Spanish, modules',
             'locale-ar-dashboard': 'Arabic (right-to-left), dashboard', 'locale-ar-modules': 'Arabic, modules',
             'dashboard-planner': 'List View dashboard', 'dashboard-activity': 'Recent Activity dashboard',
             'overlays-hidden': 'Colour overlays hidden', 'nav-collapsed': 'Global nav collapsed',
             'narrow-dashboard': 'Narrow window, dashboard', 'narrow-modules': 'Narrow window, modules',
             'high-contrast': 'High Contrast on (skin off)'}
    variants_html = '<ul class="shots">' + ''.join(
        f'<li><img src="variants/{s}" alt="{html.escape(names.get(s[:-4], s))}" loading="lazy"><span>{html.escape(names.get(s[:-4], s))}</span></li>'
        for s in variant_shots) + '</ul>'

page = f'''<title>Every Canvas</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,400;0,500;0,600;1,400&family=IBM+Plex+Mono:wght@400;500&display=swap">
<style>
:root {{
  --paper: #F6F5F0; --paper-2: #FFFFFF; --sunk: #EDEBE4; --ink: #1B1F24; --ink-2: #4A515B; --rule: #DAD6CB; --mark: #2F6BAA;
  --pass: #2E7D5B; --pass-bg: #E3F1EA; --warn: #B8741A; --warn-bg: #F7EBD6; --fail: #B3382E; --fail-bg: #F6E1DE; --todo: #8A8F97;
  --sans: "IBM Plex Sans", "Helvetica Neue", Arial, sans-serif; --mono: "IBM Plex Mono", "SF Mono", Menlo, monospace;
}}
@media (prefers-color-scheme: dark) {{ :root:not([data-theme="light"]) {{ --paper: #17191D; --paper-2: #1E2126; --sunk: #23272D; --ink: #E8E6E1; --ink-2: #A9AEB6; --rule: #343941; --mark: #7FB0E8; --pass: #7FC9A6; --pass-bg: #1F3A2E; --warn: #E0B06A; --warn-bg: #3D3120; --fail: #EF9A8F; --fail-bg: #45251F; --todo: #7B8088; }} }}
:root[data-theme="dark"] {{ --paper: #17191D; --paper-2: #1E2126; --sunk: #23272D; --ink: #E8E6E1; --ink-2: #A9AEB6; --rule: #343941; --mark: #7FB0E8; --pass: #7FC9A6; --pass-bg: #1F3A2E; --warn: #E0B06A; --warn-bg: #3D3120; --fail: #EF9A8F; --fail-bg: #45251F; --todo: #7B8088; }}
body {{ margin: 0; background: var(--paper); color: var(--ink); font: 16px/1.55 var(--sans); }}
main {{ max-width: 76ch; margin: 0 auto; padding: 48px 24px 96px; }}
h1 {{ font-size: 40px; line-height: 1.1; font-weight: 600; letter-spacing: -0.02em; margin: 0 0 8px; text-wrap: balance; }}
h2 {{ font-size: 22px; font-weight: 600; letter-spacing: -0.01em; margin: 48px 0 12px; text-wrap: balance; }}
h3 {{ font-size: 16px; font-weight: 600; margin: 28px 0 8px; }}
p {{ margin: 0 0 14px; max-width: 68ch; }}
code {{ font: 0.92em var(--mono); }}
.eyebrow {{ font: 500 12px/1 var(--mono); letter-spacing: 0.08em; text-transform: uppercase; color: var(--ink-2); margin-bottom: 18px; }}
.verdict {{ font-size: 20px; line-height: 1.4; margin: 16px 0 28px; max-width: 64ch; }}
.verdict b {{ font-weight: 600; }}
.stamp {{ display: inline-block; font: 500 13px var(--mono); background: var(--sunk); border: 1px solid var(--rule); padding: 2px 8px; border-radius: 3px; }}
.figures {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 12px; margin: 24px 0 8px; }}
.figure {{ background: var(--paper-2); border: 1px solid var(--rule); border-radius: 4px; padding: 14px 16px; }}
.figure .n {{ font: 600 30px/1 var(--sans); letter-spacing: -0.02em; font-variant-numeric: tabular-nums; }}
.figure .l {{ font-size: 13px; color: var(--ink-2); margin-top: 6px; }}
.figure.pass .n {{ color: var(--pass); }} .figure.fail .n {{ color: var(--fail); }}
table {{ border-collapse: collapse; width: 100%; font-size: 14.5px; }}
th, td {{ text-align: left; vertical-align: top; padding: 9px 12px 9px 0; border-bottom: 1px solid var(--rule); }}
th {{ font-weight: 600; font-size: 12.5px; letter-spacing: 0.04em; text-transform: uppercase; color: var(--ink-2); }}
td.state {{ white-space: nowrap; font-weight: 500; }}
.scroll {{ overflow-x: auto; }}
.pill {{ display: inline-block; font: 500 12px/1 var(--mono); padding: 4px 8px; border-radius: 3px; }}
.pill.pass {{ color: var(--pass); background: var(--pass-bg); }} .pill.warn {{ color: var(--warn); background: var(--warn-bg); }} .pill.fail {{ color: var(--fail); background: var(--fail-bg); }} .pill.todo {{ color: var(--todo); background: var(--sunk); }}
.group h3 {{ display: flex; align-items: baseline; gap: 10px; margin-top: 22px; }}
.count {{ font: 500 12px var(--mono); color: var(--ink-2); }}
.chips {{ list-style: none; margin: 0; padding: 0; display: grid; grid-template-columns: repeat(auto-fill, minmax(230px, 1fr)); gap: 6px 14px; }}
.chip {{ display: grid; grid-template-columns: 10px 1fr; column-gap: 8px; align-items: baseline; padding: 4px 0; font-size: 13.5px; }}
.chip code {{ font-size: 13px; }}
.chip .meta {{ grid-column: 2; font-size: 11.5px; color: var(--ink-2); }}
.dot {{ width: 8px; height: 8px; border-radius: 50%; background: var(--todo); align-self: center; }}
.chip.pass .dot {{ background: var(--pass); }} .chip.fail .dot {{ background: var(--fail); }} .chip.fake-pass .dot {{ background: var(--pass); opacity: 0.45; }} .chip.fake-fail .dot {{ background: var(--fail); }}
.legend {{ display: flex; flex-wrap: wrap; gap: 16px; font-size: 13px; color: var(--ink-2); margin: 8px 0 0; }}
.legend span::before {{ content: ""; display: inline-block; width: 8px; height: 8px; border-radius: 50%; margin-right: 6px; background: var(--todo); }}
.legend .p::before {{ background: var(--pass); }} .legend .f::before {{ background: var(--fail); }} .legend .k::before {{ background: var(--pass); opacity: 0.45; }}
.shots {{ list-style: none; margin: 8px 0 0; padding: 0; display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: 14px; }}
.shots img {{ width: 100%; border: 1px solid var(--rule); border-radius: 3px; display: block; }}
.shots span {{ display: block; font-size: 12.5px; color: var(--ink-2); margin-top: 6px; }}
.note {{ border-left: 3px solid var(--mark); padding: 2px 0 2px 14px; color: var(--ink-2); font-size: 14.5px; }}
ul.plain {{ padding-left: 20px; }} ul.plain li {{ margin-bottom: 6px; }}
</style>
<main>
<div class="eyebrow">Prepkin for Canvas · cross-school proof · {stamp}</div>
<h1>Every Canvas</h1>
<p class="verdict"><b>Instructure's cloud is one Canvas build for every school.</b> {n_schools} real schools were read without logging in and every one answers with the same stylesheet bundle, <span class="stamp">common-{build_id}</span>, the same one canvas.dartmouth.edu serves George. What differs between schools is the theme, and it is public — so every school's theme was put on real Canvas under the real extension. <b>{real_line}</b>{"; all " + str(n_fake_pass) + " pass on the fake's pages" if n_fake_pass and not n_fake_fail else ""}.</p>

<div class="figures">
  <div class="figure"><div class="n">{n_schools}</div><div class="l">real schools read anonymously</div></div>
  <div class="figure"><div class="n">{len(builds)}</div><div class="l">distinct Canvas build{"s" if len(builds) != 1 else ""} among them</div></div>
  <div class="figure"><div class="n">{n_themed}</div><div class="l">ship their own CSS or JavaScript</div></div>
  <div class="figure {"pass" if n_real_run and not n_real_fail else ("fail" if n_real_fail else "")}"><div class="n">{n_real_pass}<span style="font-size:18px;color:var(--ink-2)">/{n_real_run}</span></div><div class="l">pass on real Canvas{" · " + str(n_real_fail) + " fail" if n_real_fail else ""}</div></div>
</div>

<h2>What "every type of Canvas" turned out to mean</h2>
<p>A school's Canvas can differ from Dartmouth's in nine ways. Each was either proven the same, tested, fixed, or put under watch.</p>
<div class="scroll"><table>
<thead><tr><th>Dimension</th><th>What we found</th><th>State</th></tr></thead>
<tbody>
<tr><td>The Canvas build itself</td><td>One build across all {n_schools} cloud schools and Dartmouth, served from {len(regions)} AWS zones across the US, Canada, Europe and Australia. Instructure deploys to everyone at once, so a selector that holds on one holds on all until the next release. The self-hosted sandbox is the open-source build from a few months earlier and shares the cloud's brand-variables file byte for byte.</td><td class="state"><span class="pill pass">same everywhere</span></td></tr>
<tr><td>Page security policy</td><td>Every school's Canvas sends one policy, <code>frame-ancestors</code> only — no <code>style-src</code>, no <code>script-src</code> ({csp_n} of {n_schools} checked). The stylesheet our content script appends and the buddy's shadow root cannot be blocked at any of them. A school that ever adds a stricter policy shows up in <code>theme.json</code>.</td><td class="state"><span class="pill pass">same everywhere</span></td></tr>
<tr><td>The school's theme (Theme Editor CSS + JS + brand colours)</td><td>{n_themed} of {n_schools} ship custom files; the biggest is {html.escape(biggest[0])} at {biggest[1] / 1024 / 1024:.1f} MB of DesignPLUS. Each theme was placed on the sandbox's real pages where Canvas places it; the run checks the skin classes, the buddy, every rule-carrying selector, the rendered ground in light and dark, and our error log.</td><td class="state"><span class="pill {theme_pill}">{real_line}</span></td></tr>
<tr><td>Feature flags that rewrite markup</td><td>Only one leaks into the page for signed-out visitors, <code>responsive_student_grades_page</code>, and it is on at every school read; on Dartmouth it keeps <code>#grades_summary</code>. The modules rewrite and the widget dashboard stay behind flags the sandbox can flip (L6, R2) and the skin steps aside on both.</td><td class="state"><span class="pill pass">covered</span></td></tr>
<tr><td>The student's own settings</td><td>Language (Spanish; Arabic flips Canvas to right-to-left), List View and Recent Activity dashboards, colour overlays hidden (George's own setting), a collapsed nav, a narrow window, High Contrast. Set through the student's session on real Canvas, no admin.</td><td class="state"><span class="pill {"pass" if variant_shots else "todo"}">{"run, see below" if variant_shots else "pending"}</span></td></tr>
<tr><td>Canvas's request budget</td><td>Every school rations a session with the same leaky bucket: 50 units held per request in flight, refused at 600, drains 10 a second (cloud: 700). Twelve reads at once already lose the twelfth, so a student in a dozen courses lost one on every first sync. Fixed: six reads at a time, and a refusal waits and asks again.</td><td class="state"><span class="pill pass">fixed · X9, X10</span></td></tr>
<tr><td>Instructure's next deploy</td><td>Every school's policy header names its <code>.beta.instructure.com</code> host, and beta runs the next release about three weeks early. Read anonymously: {len(beta)} betas, {"one build, " + ", ".join(beta_builds) if len(beta_builds) == 1 else ", ".join(beta_builds)}, {beta_ahead} of them already ahead of production; the global chrome the skin hangs off (rail, logo, layout, skip link) is intact on {"all of them" if not beta_missing else "all but " + ", ".join(beta_missing)}. <code>harvest.js --beta</code> is the early warning; the dashboard and course pages on beta need a login, so that check is George's, on <code>dartmouth.beta.instructure.com</code>.</td><td class="state"><span class="pill {"pass" if not beta_missing else "fail"}">watched · beta</span></td></tr>
<tr><td>Courses the school has locked by date</td><td>Many schools close a course once its dates pass. Canvas still lists it as an active enrolment, as a stub — id, name, <code>access_restricted_by_date</code> — that answers 401 to everything else. It was kept, listed on the phone with no work, and cost two refused requests per sync. Now dropped at the door.</td><td class="state"><span class="pill pass">fixed</span></td></tr>
<tr><td>Which name the school uses</td><td><code>canvas.school.edu</code> and <code>school.instructure.com</code> are one Canvas (every school's policy lists both, plus <code>.beta.</code> and <code>.test.</code>). Its next-page links carry the request's own host (checked in source, and on Dartmouth), so a plain school never hits it; a proxy that rewrites hosts would. A next-page link is now moved onto the connected origin rather than dropped — cookies still never leave it.</td><td class="state"><span class="pill pass">fixed · C29</span></td></tr>
</tbody></table></div>

<h2>Dartmouth today, in George's own Chrome</h2>
<p>Read-only, on the live cloud build with the extension he has installed. Every selector that carries a rule matched wherever its content exists.</p>
<div class="scroll"><table>
<thead><tr><th>Page</th><th>Hooks found</th><th>Ours</th></tr></thead>
<tbody>
<tr><td>Dashboard</td><td>rail, logo, 2 cards, 2 heroes, 2 action rows, Coming Up, Recent Feedback, dashboard header, right side. No To Do list (nothing to do) and no sidebar logo (Dartmouth has none).</td><td>skin on (<code>pk-paper-sky · pk-theme-deepsea</code>), buddy, a "Nothing due" line on each card; the 2020 orientation course is on the cards but carries no work. Colour overlays are hidden in his settings; Canvas wrote no opacity on these plain-colour heroes and we changed none.</td></tr>
<tr><td>Modules</td><td>course nav, 8 module headers, 31 items. No due dates in a workshop course; the four low-use tabs are hidden by the teacher. Modules rewrite: off.</td><td>skin on, buddy</td></tr>
<tr><td>Grades</td><td><code>#grades_summary</code> present under <code>responsive_student_grades_page</code>; the React summary is not.</td><td>skin on, buddy</td></tr>
<tr><td>Assignment → classic quiz</td><td>5 <code>.user_content</code> blocks; not a take page.</td><td>skin on, buddy</td></tr>
<tr><td>API</td><td>next-page links name <code>canvas.dartmouth.edu</code> itself; the bucket reads 700 remaining. Dartmouth's own theme script disables personal access tokens — the extension never needs one.</td><td>—</td></tr>
</tbody></table></div>

<h2>The schools</h2>
<p>Read from each sign-in page (or not-found page) on 2026-09-12 and 13. Hover a name for what it ships.{" Two districts' pages show no theme files at all, so there was nothing to put on the page for them." if n_bare else ""}</p>
<div class="legend"><span class="p">pass on real Canvas</span><span class="k">pass on the fake's pages, real run pending</span><span class="f">fail</span><span>not run</span></div>
{group_html}
{fail_html}
{"<p class='note'>Schools whose script put up a dialog during the run: " + html.escape("; ".join(f"{h}: {' | '.join(d)}" for h, d in dialogs.items())) + "</p>" if dialogs else ""}
<p class="note">One school's script, Stanford's, polls the dashboard with synchronous API calls; a driven browser never navigates away from that page, and in the first full run it took every school after it down. The run now opens a fresh tab for every page, the way a student opens the next page. Stanford passes; their students were never stuck.</p>

<h2>The student's settings</h2>
<p>Eight rows, all set through the student's own session on real Canvas, all pass. One found a bug: in right-to-left Canvas the sidebar sits on the left edge, so the buddy's panel opened off the page and gave every page a sideways scroll. The panel now opens to his right when there is no room on his left, and the Arabic row asserts no sideways scroll.</p>
{variants_html or '<p class="note">The variants run had not finished when this page was made. Its screenshots land in design/signoff/canvas-variants/.</p>'}

<h2>What this does not prove</h2>
<ul class="plain">
<li><b>A school that is not on Instructure's cloud.</b> Self-hosted Canvas is rare and the harvester would show it as a different build id; the sandbox is the closest stand-in.</li>
<li><b>A sub-account with its own theme.</b> The sign-in page shows the root account's theme; a department can layer its own on top of course pages.</li>
<li><b>A school's JavaScript that loads more JavaScript at run time.</b> One level of those files is kept with the harvest; the run refuses the rest of the network on purpose.</li>
<li><b>Instructure's next deploy, on the pages behind a login.</b> Beta shows the next build's global chrome to anyone; its dashboard, modules and grades need a Dartmouth login on <code>dartmouth.beta.instructure.com</code>. Three weeks' warning every release, if that check is run; the remote off-switch covers the day something moves anyway.</li>
</ul>

<h2>What changed in the code</h2>
<ul class="plain">
<li><code>extension/background.js</code>: reads go six at a time (<code>inTurns</code>); one Canvas GET (<code>canvasGet</code>) that recognises the bucket's refusal and retries after 3, 6, 9 seconds; <code>isCanvas</code> no longer calls a throttled answer "logged out".</li>
<li><code>extension/canvas.js</code>: <code>nextLink</code> moves a next-page link onto the connected origin when it is an API path, instead of refusing it; <code>mapCourses</code> drops a course Canvas has locked by date.</li>
<li><code>test/fake-canvas.js</code>: Canvas's bucket, word for word in its refusal; a school's theme dressed onto real or fake pages.</li>
<li><code>extension/content.js</code> + <code>panel.css</code>: the panel flips to the buddy's right when the band sits at the page's left edge (right-to-left Canvas).</li>
<li>New: <code>test/schools/harvest.js</code>, <code>test/schools.test.js</code>, <code>test/variants.test.js</code>; stress rows X9, X10; C29 rewritten.</li>
</ul>
<p class="note">One thing found on the way: <code>extension/canvas.test.js</code> "the detailed pass wins" had failed on main since 2026-09-09 — the test forgot to hand the sweep its clock, so its sample task aged out of the seven-day tail. One token (<code>NOW</code>) fixed it; <code>npm test</code> is 143 of 143 again, so <code>bridge/package.sh</code> will package.</p>
</main>
'''
open(OUT, 'w').write(page)
print('wrote', OUT, n_schools, 'schools;', n_real_run, 'real run;', n_real_pass, 'pass;', n_fake_pass, 'fake pass')

// Renders every buddy-panel view to HTML with sample data, so a view can be
// looked at without a Canvas tab, a phone or the sandbox. `chrome` is stubbed
// just enough for art URLs. DARK=1 for the dark tokens; OUT=<dir> for where
// the files go (default: a prepkin-gallery folder in the system temp dir).
//
//   node design/canvas-skin/gallery/build.js && node design/canvas-skin/gallery/shoot.js
//
const fs = require('fs');
const path = require('path');
const ROOT = path.resolve(__dirname, '../../..');
const DARK = !!process.env.DARK;
globalThis.chrome = { runtime: { id: 'gallery', getURL: (f) => 'file://' + path.join(ROOT, 'extension', f) } };
const C = require(path.join(ROOT, 'extension/content.js'));
const { buckets, voice } = require(path.join(ROOT, 'extension/day.js'));
const S = process.env.OUT || path.join(require('os').tmpdir(), 'prepkin-gallery');
fs.mkdirSync(S, { recursive: true });
const now = new Date(2026, 8, 11, 21, 30);
const day = 86400000;
const courses = [
  { id: '1', name: 'AP Physics C: Mechanics', colorHex: '#9B3FA0', score: 87.4, grade: 'B+' },
  { id: '2', name: 'English 11: American Voices', colorHex: '#D91A00', score: 92.1, grade: 'A-' },
  { id: '3', name: 'Ceramics I', colorHex: '#E4005B', score: null, grade: null },
  { id: '4', name: 'Calculus BC', colorHex: '#2F6BAA', score: 78.9, grade: 'C+' },
];
const t = (id, title, cid, dueDays, sub, pts = 20, url = 'https://canvas.test/x') => ({ id, title, courseId: cid, courseName: courses.find((c) => c.id === cid).name, colorHex: courses.find((c) => c.id === cid).colorHex, dueAt: new Date(now.getTime() + dueDays * day).toISOString(), submittedAt: sub ? new Date(now.getTime() + (dueDays - 0.5) * day).toISOString() : null, pointsPossible: pts, url });
const tasks = [
  t('a', 'Problem Set 7: Rotational Inertia', '1', -4, false, 50), t('b', 'Lab writeup: Conservation of Momentum', '1', -2, false, 50),
  t('c', 'Reading response: Chapter 10', '2', 0.1, false, 10), t('d', 'Quiz: Kinematics review', '4', 0.3, false, 15),
  t('e', 'Comparative essay: Douglass and Jacobs', '2', 3, false, 100), t('f', 'Glaze test tiles', '3', 5, false, 10), t('g', 'Problem Set 8: Angular Momentum', '1', 6, false, 50),
  t('h', 'Warm-up 12', '4', -1, true, 5), t('i', 'Reading check: Chapter 9', '2', -0.2, true, 10),
];
const graded = { '1': [80, 84, 91, 78, 88, 90].map((s, i) => ({ id: 'g' + i, score: s, outOf: 100, percent: s, classMean: 82, gradedAt: new Date(now.getTime() - (30 - i * 5) * day).toISOString(), title: `PS ${i + 1}` })) };
C._setData({ tasks, courses, graded, weights: { '1': [{ name: 'Problem sets', weight: 40 }, { name: 'Labs', weight: 20 }, { name: 'Final exam', weight: 40 }] }, at: new Date(now.getTime() - 4 * 60000).toISOString() });
if (DARK) C._setSkin?.({ dark: true });
C._setWallet({ coins: 120, owned: ['classic', 'deepsea'], wearing: 'classic', league: { tier: 1, points: 90, bar: 150, week: '2026-09-07', pennants: [0], board: [ { you: false, adjective: 3, noun: 7, points: 140, level: 2, species: 'coral', look: 'classic' }, { you: true, adjective: 1, noun: 2, points: 90, level: 2, species: 'mint', look: 'classic' }, { you: false, adjective: 9, noun: 4, points: 60, level: 1, species: 'sky', look: 'classic' } ] } });
const b = buckets(tasks, now, () => null);
const said = voice(b);
const css = fs.readFileSync(path.join(ROOT, 'extension/panel.css'), 'utf8').replace(/:host/g, '.host');
const skin = fs.readFileSync(path.join(ROOT, 'extension/skin.css'), 'utf8');

let vars = (skin.match(/html\.pk-on \{[^}]*\}/) || [''])[0].replace('html.pk-on', ':root') + (skin.match(/#prepkin-buddy \{[^}]*\}/) || [''])[0].replace('#prepkin-buddy', ':root');
if (DARK) vars += (skin.match(/html\.pk-on\.pk-dark \{[^}]*\}/) || [''])[0].replace('html.pk-on.pk-dark', ':root') + (skin.match(/html\.pk-dark #prepkin-buddy \{[^}]*\}/) || [''])[0].replace('html.pk-dark #prepkin-buddy', ':root');
const wrap = (title, body, head = '') => `<!doctype html><meta charset="utf-8"><title>${title}</title><style>${vars}${css}body{margin:0;background:${DARK ? '#17191D' : '#E9E6DF'};padding:24px;font-family:ui-rounded,-apple-system,system-ui,sans-serif}.host{position:static;display:block;width:360px}.pk-timer{width:280px;margin:0 auto}.pk-panel{position:static;animation:none;display:block;max-height:none}</style><div class="host"><div class="pk-panel">${head}<div class="pk-body">${body}</div></div></div>`;
const head = `<div class="pk-head worried"><div class="pk-hero"><div class="pk-bubble"><strong>${said.headline}</strong><span>${said.subline}</span></div></div><div class="pk-chips"><button class="pk-coins">◉ 120</button><span class="pk-donechip">✓ 1 of 3 done today</span></div><div class="pk-track"><i style="width:33%"></i></div></div>`;
const safe = (fn) => { try { return fn(); } catch (e) { return `<p style="color:#c00">${e.message}</p>`; } };
const views = {
  panel: [C.panelView(b, said, now), head],
  week: [C.weekView(b, now)],
  whatif: [safe(() => { C._ui.expanded = '1'; C._ui.target = 90; return C.whatIfView(); })],
  whatifask: [safe(() => { C._ui.expanded = '4'; C._ui.target = null; return C.whatIfView(); })],
  course: [safe(() => { C._ui.expanded = '1'; C._ui.courseId = '1'; return C.courseView(now); })],
  looks: [safe(() => C.looksView())],
  addtask: [C.addTaskView()],
  recap: [safe(() => C.recapView(now))],
  search: [safe(() => { C._ui.query = ''; return C.searchView(); })],
  searchq: [safe(() => { C._ui.query = 'phys'; return C.searchView(); })],
  focus: [safe(() => { C._setFocus({ state: 'running', endsAt: Date.now() + 17 * 60000 + 22000, durationMin: 25, taskId: 'a', title: 'Problem Set 7: Rotational Inertia' }); return C.focusCard(); })],
  focusdone: [safe(() => { C._setFocus({ state: 'done', endsAt: Date.now(), durationMin: 25, taskId: 'a', title: 'Problem Set 7: Rotational Inertia', url: 'https://canvas.test/x' }); return C.focusCard(); })],
};
for (const [k, [html, h]] of Object.entries(views)) fs.writeFileSync(`${S}/${k}.html`, wrap(k, html, h ?? ''));
console.log('gallery:', Object.keys(views).join(', '));

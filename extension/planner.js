// The Planner: the dashboard's main column as one list by day, in the page.
//
// A tab beside Canvas's own course cards. What slipped, then today and the
// next six days, then what sits further out (folded), then work with no date;
// one row per piece of work in the rail's shape (circle, class tile, title,
// date), drag a row onto a day to plan it. Under the list, Grades: a row per
// class that opens in place to the marks, a what-if line, a nickname, the
// level, and every assignment. When a term is ending, the recap sits at the
// top. No pop-out: this is where the buddy's panel used to keep all of it.
//
// Runs in the same world as content.js, before it. content.js sits inside one
// block, so only its plain function declarations reach this world (Annex B
// hoisting); its let/const and its async functions do not. So its state comes
// through plannerState(), a plan is set through plannerPlan(), and every
// helper used here is a plain function. Every name here starts with `pl` or
// `PLANNER_` so nothing collides at load.
// Titles are other people's text: textContent everywhere, never markup.

const PLANNER_ID = 'pk-planner';
const PLANNER_TABS_ID = 'pk-dashtabs';
const PLANNER_ONE_DAY = 86400000;

/// Which tab is showing: 'cards' (Canvas's own), 'planner' or 'looks'. Remembered.
let plTab = 'cards';
/// The course whose grades row is open, by id, or null; and which of its lists.
let plOpenCourse = null;
/// On a course's own grades page the course's row is the page: open, and not
/// a toggle. Set by renderGradesPage, read by plGradeRow.
let plGradesFixed = null;
let plCourseList = 'all';
/// The folded groups the student opened this visit.
const plUnfolded = new Set();
/// The what-if target picked per course, and a final's weight typed in, this visit.
const plTarget = {};
const plWeight = {};
const LOOKS_ID = 'pk-looks';
/// The look waiting for a yes, by id, or null.
let plConfirm = null;
/// The add-a-task form, open or not.
let plAdding = false;

function plannerShows() {
  return railShows() && !plannerState().putBack.planner && !!document.getElementById('DashboardCard_Container');
}

/// Canvas's own List View (its planner, in the dashboard's main column) is a
/// second planner. When the student has it on, ours stands in for it: Canvas's
/// list and its toolbar fold, the Planner tab is the page, and the Courses tab
/// goes (List View draws no cards). The `list-view` receipt row puts it back.
function listViewShows() {
  if (!plannerShows() || plannerState().putBack['list-view']) return false;
  // Canvas keeps the planner's mount node on a Card View dashboard too, empty
  // and `display: none` inline (the real sandbox, 2026-09-18); only a node it
  // is showing is List View. Otherwise every card-view dashboard folded.
  const node = document.getElementById('dashboard-planner');
  return !!node && node.style.display !== 'none';
}

/// The tabs in the dashboard's own title row: Courses (Canvas's cards) and
/// Planner (ours). The choice is remembered.
function renderPlannerTabs() {
  const existing = document.getElementById(PLANNER_TABS_ID);
  const bar = document.querySelector('#dashboard_header_container .ic-Dashboard-header__layout');
  if (!plannerShows()) { existing?.remove(); document.documentElement.classList.remove('pk-planner-on', 'pk-list-on'); return; }
  // The cards hide whenever a tab of ours is open, whether or not Canvas's
  // header bar is in the DOM this instant: React rebuilds the bar, and a pass
  // that met the gap used to drop the class and let the card skeletons show
  // under the Looks sheet (2026-09-17).
  const list = listViewShows();
  if (list && plTab === 'cards') plTab = 'planner';
  document.documentElement.classList.toggle('pk-list-on', list);
  document.documentElement.classList.toggle('pk-planner-on', plTab !== 'cards');
  if (!bar) { existing?.remove(); return; }
  if (existing && existing.parentElement === bar && existing.dataset.list === String(list)) { plSyncTabs(existing); return; }
  existing?.remove();
  const tabs = el('div', '', null);
  tabs.id = PLANNER_TABS_ID; tabs.dataset.list = String(list);
  tabs.setAttribute('role', 'tablist'); tabs.setAttribute('aria-label', 'Dashboard');
  for (const [key, label] of [['cards', 'Courses'], ['planner', 'Planner'], ['looks', 'Looks']]) {
    if (list && key === 'cards') continue;
    const tab = el('span', '', label);
    tab.setAttribute('role', 'tab'); tab.tabIndex = 0; tab.dataset.tab = key;
    const pick = (e) => { if (!e.isTrusted) return; plSetTab(key); };
    tab.addEventListener('click', pick);
    tab.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); pick(e); } });
    tabs.append(tab);
  }
  plSyncTabs(tabs);
  // Before the search pill, so the row reads: title, tabs, search.
  const chip = bar.querySelector('#pk-search');
  if (chip) chip.before(tabs); else bar.append(tabs);
}

function plSyncTabs(tabs) {
  for (const tab of tabs.querySelectorAll('[role="tab"]')) {
    const on = tab.dataset.tab === plTab;
    tab.classList.toggle('on', on);
    tab.setAttribute('aria-selected', String(on));
  }
}

function plSetTab(key) {
  plTab = ['planner', 'looks'].includes(key) ? key : 'cards';
  plConfirm = null;
  if (alive()) chrome.storage.local.set({ dashTab: plTab }).catch(() => {});
  // A "#planner" hash from the popup or the rail's link used to outlive the
  // tab: wearing a look (a wallet change remounts the page) read the old hash
  // and threw the student back to the planner (George, 2026-09-17). The hash
  // follows the tab, or goes when the cards are back.
  if (/^#(planner|looks)$/.test(location.hash) || plTab !== 'cards') {
    try { history.replaceState(null, '', location.pathname + location.search + (plTab === 'cards' ? '' : `#${plTab}`)); } catch {}
  }
  renderPlannerTabs();
  renderPlanner();
  renderLooks();
  renderPastFold();
  // The rail folds its list while the planner is open, and unfolds after.
  renderWeek();
}

/// The planner itself, right under the dashboard's title row. Rebuilt only
/// when what it shows has changed.
function renderPlanner() {
  renderGradesPage();
  const existing = document.getElementById(PLANNER_ID);
  const head = document.getElementById('dashboard_header_container');
  if (!plannerShows() || plTab !== 'planner' || !head) { existing?.remove(); return; }
  const now = new Date();
  const { data, plans, focus, skin, levels, plannedOn, nicknames, targets, recapDismissed, soFarDismissed } = plannerState();
  const groups = dayGroups(data.tasks, now, (t) => planDay(t, plans));
  const running = focus.state === 'running';
  const recap = recapDue(data.courses, data.tasks, now) && plRecapKey(data.tasks, now) !== recapDismissed;
  // Mid-term, the same card as "So far this term", once a month.
  const soFar = !recap && soFarDue(data.courses, data.tasks, now, data.graded) && soFarKey(now) !== soFarDismissed;
  const key = JSON.stringify([
    groups.past.map((t) => t.id), groups.days.map((d) => d.items.map((t) => [t.id, t.submittedAt, t.doneAt, plans[t.id] ?? null])),
    groups.later.map((t) => t.id), groups.undated.map((t) => t.id), groups.missed.map((t) => t.id),
    data.courses.map((c) => [c.id, c.name, c.score, c.grade]), (data.pastCourses ?? []).map((c) => [c.id, c.grade, c.score]), Object.values(data.graded ?? {}).reduce((n, g) => n + g.length, 0), running && focus.title, focus.state, focus.endsAt,
    skin.focusMinutes, plAdding, levels, nicknames, targets, plOpenCourse, plCourseList, [...plUnfolded], plTarget, plWeight, recap, soFar,
  ]);
  if (existing && existing.dataset.key === key) return;

  const box = el('section', '', null);
  box.id = PLANNER_ID; box.dataset.key = key;
  box.setAttribute('aria-label', 'Prepkin: planner');

  // One head row: the title. No arrows, no count, no button: the one action
  // (add a task) sits at the foot of Today, where Todoist's Upcoming keeps it.
  const headRow = el('div', 'pk-pl-head');
  const title = el('div', 'pk-pl-title');
  // Words, no picture: the one picture on a Canvas page of ours is Sprout.
  title.append(el('b', '', 'Planner'));
  headRow.append(title);
  box.append(headRow);

  // The term, in numbers, when a term is ending.
  if (recap) box.append(plRecapCard(now));
  else if (soFar) box.append(plRecapCard(now, { soFar: true }));

  const list = el('div', 'pk-pl-list');
  // The week at a glance, Structured's strip: seven days from today, the day
  // number, a dot under a day with work, today filled. A tap scrolls to the
  // day; a row dragged onto a day is planned for it. It is the planner's
  // navigation, not a count (the rail lost its strip for saying the count twice).
  const strip = el('div', 'pk-pl-strip');
  strip.setAttribute('aria-label', 'This week');
  groups.days.forEach((d, i) => {
    const cell = el('button', `day${i === 0 ? ' today' : ''}${d.items.some((t) => !isDone(t)) ? ' has' : ''}`);
    cell.type = 'button';
    cell.append(el('small', '', d.date.toLocaleDateString([], { weekday: 'short' }).slice(0, 2)), el('b', '', String(d.date.getDate())), el('i', 'dot'));
    cell.dataset.drop = dayKey(d.date);
    cell.title = d.date.toLocaleDateString([], { weekday: 'long', month: 'short', day: 'numeric' });
    plDropTarget(cell, d.date);
    cell.addEventListener('click', (e) => {
      if (!e.isTrusted) return;
      const target = list.querySelector(`[data-day="${dayKey(d.date)}"]`);
      target?.scrollIntoView({ behavior: 'smooth', block: 'center' });
    });
    strip.append(cell);
  });
  list.append(strip);
  // What slipped: amber dates, and one line saying what it is still worth.
  if (groups.past.length) {
    list.append(plGroupHead('Past due', groups.past.length));
    list.append(plRows(groups.past, now, { slipped: true }));
  }

  // Today and the next six days. Today always has its heading (with the next
  // thing named when nothing is due); a day with work has its heading and
  // rows; a run of empty days is one quiet line, so nothing stacks.
  const dayName = (d, i) => i === 0 ? 'Today' : i === 1 ? 'Tomorrow' : d.date.toLocaleDateString([], { weekday: 'long' });
  const shortDay = (d) => d.date.toLocaleDateString([], { weekday: 'short' });
  let quiet = [];
  const flushQuiet = () => {
    if (!quiet.length) return;
    const first = quiet[0], last = quiet[quiet.length - 1];
    const words = quiet.length === 1
      ? `Nothing due ${first[1] === 1 ? 'tomorrow' : shortDay(first[0])}`
      : `Nothing due ${first[1] === 1 ? 'tomorrow' : shortDay(first[0])} to ${shortDay(last[0])}`;
    const line = el('p', 'pk-pl-quiet', words);
    line.dataset.day = dayKey(first[0].date);
    list.append(line);
    quiet = [];
  };
  const nextAfterToday = groups.days.slice(1).flatMap((d) => d.items.filter((t) => !isDone(t)))[0] ?? groups.later[0] ?? null;
  groups.days.forEach((d, i) => {
    if (i > 0 && !d.items.length) { quiet.push([d, i]); return; }
    flushQuiet();
    const h = plGroupHead(dayName(d, i), d.items.filter((t) => !isDone(t)).length, { today: i === 0, date: d.date });
    h.dataset.day = dayKey(d.date);
    plDropTarget(h, d.date);
    list.append(h);
    if (d.items.length) list.append(plRows(d.items, now, { first: i === 0 && !running ? d.items.find((t) => !isDone(t)) ?? null : null, running: i === 0 && running }));
    else {
      // Nothing today: say so, and name the next thing so the day still points somewhere.
      const empty = el('p', 'pk-pl-empty', 'Nothing due today.');
      if (nextAfterToday) {
        empty.append(' Next: ');
        const url = safeURL(nextAfterToday.url);
        const a = url ? el('a', '', nextAfterToday.title) : el('b', '', nextAfterToday.title);
        if (url) a.href = url;
        empty.append(a, `, ${dueLabel(nextAfterToday, now).replace(' · still counts', '')}.`);
      }
      list.append(empty);
    }
    if (i === 0) list.append(plAdding ? plAddForm(now) : plAddLine());
  });
  flushQuiet();
  // Further out, folded until asked; then work with no date; then the old zeros.
  const fold = (id, name, items, opts = {}) => {
    if (!items.length) return;
    const open = plUnfolded.has(id);
    const h = plGroupHead(name, items.length, { fold: true, open, onToggle: () => { if (open) plUnfolded.delete(id); else plUnfolded.add(id); renderPlanner(); } });
    list.append(h);
    if (open) list.append(plRows(items, now, opts));
  };
  fold('later', 'Later', groups.later);
  if (groups.undated.length) { list.append(plGroupHead('No due date', groups.undated.length)); list.append(plRows(groups.undated, now)); }
  fold('missed', 'Missing, older', groups.missed, { slipped: true });
  box.append(list);

  box.append(plGrades(now));

  if (existing) existing.replaceWith(box); else head.after(box);
}

/// A group's heading: plain words, the count in the quiet ink, today outlined.
/// A folded group's heading is the button that opens it.
function plGroupHead(name, count, { today = false, fold = false, open = false, onToggle = null, date = null } = {}) {
  const h = el('div', `pk-pl-group${today ? ' today' : ''}${fold ? ' fold' : ''}${open ? ' open' : ''}`);
  h.append(el('b', '', name));
  // A day's heading carries its date in the quiet ink (Todoist's Upcoming):
  // "Today · Sep 17", so a week of weekday names still says when.
  if (date) h.append(el('span', 'when', date.toLocaleDateString([], { month: 'short', day: 'numeric' })));
  if (count) h.append(el('em', '', String(count)));
  if (date) h.dataset.drop = dayKey(date);
  if (fold && onToggle) {
    h.setAttribute('role', 'button'); h.tabIndex = 0; h.setAttribute('aria-expanded', String(open));
    h.addEventListener('click', onToggle);
    h.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); onToggle(); } });
  }
  return h;
}

/// Rows in the rail's shape: circle, class tile, title, the date at the right.
/// Today's first pending row is the one to start, with Start and Focus under
/// it; while a session runs, that row is the session, ticking in place.
function plRows(items, now, { slipped = false, first = null, running = false } = {}) {
  const ul = el('ul', 'pk-w-list pk-pl-rows');
  const { focus, skin } = plannerState();
  if (running) ul.append(plSessionRow(focus));
  for (const t of items) {
    const finished = isDone(t);
    const late = !finished && t.dueAt && Date.parse(t.dueAt) < now.getTime();
    const li = el('li', `${finished ? 'done' : ''}${isMoved(t) ? ' moved' : ''}${t === first ? ' pk-w-first' : ''}`.trim());
    if (!finished) { li.draggable = true; li.dataset.drag = String(t.id); plDragSource(li); }
    if (t.submittedAt) { const lock = el('span', 'pk-tick on locked'); lock.title = 'Handed in'; li.append(lock); } else li.append(tickCircle(t));
    li.append(classTile(t));
    const url = safeURL(t.url);
    const name = url ? el('a', '', t.title) : el('b', '', t.title);
    if (url) name.href = url;
    name.className = 'pk-pl-name';
    name.title = `${t.title}\n${t.courseName}${t.dueAt ? ` · ${dueLabel(t, now)}` : ''}${isMoved(t) ? '\nMoved. Drag it back to its due day to undo.' : ''}`;
    li.append(name);
    const when = t.submittedAt ? 'in' : t.doneAt ? 'done'
      // What slipped says its date and what it is still worth, in one line
      // of meta; before this a band over the group said the sum (2026-09-18).
      : slipped && t.dueAt ? `was due ${new Date(t.dueAt).toLocaleDateString([], { month: 'short', day: 'numeric' })}${Number(t.pointsPossible) > 0 ? ` · still counts · ${Number(t.pointsPossible)} pts` : ''}`
      : isMoved(t) ? `due ${dayShort(t, now)}`
      : t.dueAt ? new Date(t.dueAt).toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' }) : 'any time';
    if (t === first) {
      // The one to start: the class and when under the title, then the two
      // ways to start it, the rail's shape.
      name.replaceWith(el('span', 'pk-pl-words'));
      const words = li.querySelector('.pk-pl-words');
      name.className = 'pk-pl-name';
      words.append(name, el('small', late ? 'amber' : '', `${shortCourse(t.courseName)} · ${t.dueAt ? dueLabel(t, now).replace(' · still counts', '') : 'any time'}`));
      const actions = el('div', 'pk-w-actions');
      if (url) { const a = el('a', 'start', 'Start'); a.href = url; actions.append(a); }
      const focusBtn = el('span', '', `Focus ${skin.focusMinutes} min`);
      focusBtn.setAttribute('role', 'button'); focusBtn.tabIndex = 0;
      const go = (e) => { if (!e.isTrusted || !alive()) return; chrome.runtime.sendMessage({ type: 'focus-start', taskId: t.id, title: t.title, url: t.url, minutes: skin.focusMinutes }); };
      focusBtn.addEventListener('click', go);
      focusBtn.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); go(e); } });
      actions.append(focusBtn);
      li.append(actions);
    } else li.append(el('small', late || slipped ? 'amber' : '', when));
    ul.append(li);
  }
  return ul;
}

/// The running session as today's first row: what, how long is left (ticked
/// in place by tickClocks), and one way to stop.
function plSessionRow(focus) {
  const li = el('li', 'pk-w-first session');
  const words = el('div');
  const meta = el('small', '', '');
  meta.append(el('span', 'pk-w-clock', clockLeft()), ' left');
  words.append(el('b', '', focus.title ?? 'Focus'), meta);
  li.append(words);
  const actions = el('div', 'pk-w-actions');
  const url = safeURL(focus.url);
  if (url) { const a = el('a', 'start', 'Open'); a.href = url; actions.append(a); }
  const stop = el('span', '', 'Stop');
  stop.setAttribute('role', 'button'); stop.tabIndex = 0;
  stop.addEventListener('click', (e) => { if (e.isTrusted && alive()) chrome.runtime.sendMessage({ type: 'focus-stop' }); });
  actions.append(stop);
  li.append(actions);
  return li;
}

// Drag a row to a day: the plan. Dropping it on its own due day clears the plan.
let plDragging = null;
function plDragSource(row) {
  row.addEventListener('dragstart', (e) => {
    plDragging = row.dataset.drag;
    row.classList.add('dragging');
    try { e.dataTransfer.setData('text/plain', row.dataset.drag); e.dataTransfer.effectAllowed = 'move'; } catch {}
  });
  row.addEventListener('dragend', () => { plDragging = null; row.classList.remove('dragging'); document.querySelectorAll(`#${PLANNER_ID} .over`).forEach((n) => n.classList.remove('over')); });
}
function plDropTarget(node, date) {
  node.addEventListener('dragover', (e) => { if (!plDragging) return; e.preventDefault(); node.classList.add('over'); });
  node.addEventListener('dragleave', () => node.classList.remove('over'));
  node.addEventListener('drop', (e) => {
    if (!plDragging) return;
    e.preventDefault();
    const id = plDragging; plDragging = null;
    node.classList.remove('over');
    const t = plannerState().data.tasks.find((x) => String(x.id) === id);
    if (!t) return;
    const due = t.dueAt ? startOfDay(new Date(t.dueAt)) : null;
    // Back on its due day is not a plan, it is the plan's end.
    plannerPlan(id, due && sameLocalDay(due, date) ? null : dayKey(date)).then(() => renderPlanner());
  });
}

// MARK: - Grades: a row per class, one open at a time

/// The block under the list. A row: tile, name, per cent, letter. Open, it
/// holds the sparkline and the last three marks, one what-if line, the
/// nickname, the level, and every assignment the laptop already has.
function plGrades(now, { heading = 'Grades', gpa = true } = {}) {
  const { data, levels } = plannerState();
  const wrap = el('div', 'pk-pl-grades');
  const courses = data.courses.filter((c) => c.name && /^\d+$/.test(String(c.id)));
  // On /grades Canvas's own h1 already says it; the word is not said twice.
  // The heading is a group head like the days above it: the word, the count.
  if (heading) wrap.append(plGroupHead(heading, courses.length));
  if (!courses.length) { wrap.append(el('p', 'pk-pl-empty', 'Nothing graded yet.')); return wrap; }
  for (const c of courses) wrap.append(plGradeRow(c, now));
  if (gpa) wrap.append(plGpaBlock(courses, data.pastCourses ?? [], levels));
  return wrap;
}

/// GPA so far: the number large, a chip per term, and what it is made of. One
/// block on the Planner tab and on /grades, so the fact lives once. An
/// estimate, and the block says so beside the number, not in a tooltip.
function plGpaBlock(courses, past, levels) {
  const r = gpaReport(courses, past, levels);
  if (!r) return document.createDocumentFragment();
  const box = el('div', 'pk-pl-gpa');
  box.append(el('strong', '', (r.weighted ?? r.overall).toFixed(2)));
  const label = el('b', '', `GPA so far${r.weighted ? ', weighted' : ''} `);
  label.append(el('small', '', '· an estimate'));
  box.append(label);
  if (r.terms.length > 1) {
    const terms = el('div', 'terms');
    for (const t of r.terms) { const chip = el('span', '', `${t.name} `); chip.append(el('b', '', t.gpa.toFixed(2))); terms.append(chip); }
    box.append(terms);
  }
  const n = (k, w) => `${k} course${k === 1 ? '' : 's'} ${w}`;
  const made = r.letters && r.cutoffs ? `${n(r.letters, "from your school's letters")}, ${n(r.cutoffs, 'from the usual cutoffs')}`
    : r.letters ? `${n(r.letters, "from your school's letters")}`
    : `${n(r.cutoffs, 'from the usual cutoffs; Canvas gave no letters')}`;
  box.append(el('p', 'pk-pl-foot', `${made}. Not weighted by credits. Your registrar's number wins.`));
  return box;
}

// MARK: - Finished courses

let plPastOpen = false;
const PAST_ID = 'pk-past';

/// The fold belongs on the Courses tab of a synced dashboard, with something
/// finished to fold. The receipt row `past-fold` reads this.
function pastFoldShows() {
  const { data } = plannerState();
  return plannerShows() && plTab === 'cards' && (data.pastCourses?.length ?? 0) > 0;
}

/// One closed line, "Finished courses · 2"; open, a row per course with its
/// term and its letter, each a link to the course. The class list the rival
/// puts in a sidebar, without the sidebar; the hiding is that it starts closed.
function plPastFold(rows) {
  const wrap = el('div', 'pk-past');
  const toggle = () => { plPastOpen = !plPastOpen; renderPastFold(); renderGradesPage(); };
  wrap.append(plGroupHead('Finished courses', rows.length, { fold: true, open: plPastOpen, onToggle: toggle }));
  if (!plPastOpen) return wrap;
  const ul = el('ul', 'pk-past-rows');
  for (const c of rows) {
    const li = el('li');
    const a = el('a', '', null); a.href = `/courses/${c.id}`;
    a.append(classTile({ courseName: c.name, colorHex: c.colorHex }));
    const name = el('span', 'name', c.name); name.title = c.name;
    a.append(name);
    if (c.term) a.append(el('span', 'term', c.term));
    if (typeof c.score === 'number') a.append(el('span', 'pct', `${c.score}%`));
    a.append(el('span', 'letter', c.grade ?? ''));
    li.append(a);
    ul.append(li);
  }
  wrap.append(ul);
  return wrap;
}

function renderPastFold() {
  const existing = document.getElementById(PAST_ID);
  const cards = document.getElementById('DashboardCard_Container');
  if (!pastFoldShows() || !cards) { existing?.remove(); return; }
  const { data } = plannerState();
  const key = JSON.stringify([data.pastCourses.map((c) => [c.id, c.name, c.grade, c.score, c.term]), plPastOpen]);
  if (existing && existing.dataset.key === key) { if (cards.nextElementSibling !== existing) cards.after(existing); return; }
  const box = plPastFold(data.pastCourses);
  box.id = PAST_ID; box.dataset.key = key; box.setAttribute('aria-label', 'Prepkin: finished courses');
  if (existing) existing.replaceWith(box); else cards.after(box);
}

function plGradeRow(c, now) {
  const { data, levels, nicknames, LEVELS, LEVEL_NAMES } = plannerState();
  const fixed = plGradesFixed === String(c.id);
  const open = fixed || plOpenCourse === String(c.id);
  const pct = typeof c.score === 'number' ? Math.max(0, Math.min(100, c.score)) : null;
  const color = safeColor(c.colorHex);
  const row = el('div', `pk-pl-grade${open ? ' open' : ''}`);
  row.dataset.course = String(c.id);
  const headRow = el('div', 'pk-pl-grow');
  if (!fixed) { headRow.setAttribute('role', 'button'); headRow.tabIndex = 0; headRow.setAttribute('aria-expanded', String(open)); }
  const tile = classTile({ courseName: c.name, colorHex: c.colorHex });
  const name = el('span', 'name', c.name); name.title = c.fullName ?? c.name;
  const val = el('b', 'pct', pct === null ? '—' : `${c.score}%`);
  const letter = el('span', 'letter', c.grade ?? '');
  headRow.append(tile, name, val, letter);
  if (levels[c.id] && levels[c.id] !== 'regular') headRow.append(el('span', 'level', LEVEL_NAMES[levels[c.id]]));
  const toggle = () => { plOpenCourse = open ? null : String(c.id); plCourseList = 'all'; renderPlanner(); };
  if (!fixed) {
    headRow.addEventListener('click', toggle);
    headRow.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); toggle(); } });
  }
  row.append(headRow);
  // The fill is the school's course colour (data-pk-course-color says so to the floor).
  if (pct !== null) { const bar = el('div', 'bar'); const fill = el('i', '', null); fill.style.width = `${pct}%`; if (color) { fill.style.background = color; fill.dataset.pkCourseColor = ''; } bar.append(fill); row.append(bar); }
  if (!open) return row;

  const body = el('div', 'body');
  const graded = data.graded?.[c.id] ?? [];
  // The line of marks. The marks themselves are said once, in the Marked
  // list below, with the class average beside each; a "last three" here said
  // them twice in one card (one place per fact, 2026-09-16).
  if (graded.length >= 2) { const spark = el('div', 'spark'); spark.innerHTML = sparkline(graded, color ?? '#51CFA0'); body.append(spark); }
  // What-if: one line, from Canvas's weights or a weight the student typed.
  if (pct !== null) body.append(plWhatIf(c));
  // The nickname and the level: the student's own words for the class. Two
  // rows of controls nobody touches twice a term, so they wait behind one
  // quiet line; the card above is the grade, the aim and the what-if.
  const moreKey = `more-${c.id}`;
  const moreOpen = plUnfolded.has(moreKey);
  const more = el('button', `pk-pl-more${moreOpen ? ' open' : ''}`, nicknames[c.id] ? `Nickname and level · ${nicknames[c.id]}` : 'Nickname and level');
  more.type = 'button'; more.setAttribute('aria-expanded', String(moreOpen));
  more.addEventListener('click', (e) => { if (!e.isTrusted) return; if (moreOpen) plUnfolded.delete(moreKey); else plUnfolded.add(moreKey); renderPlanner(); });
  body.append(more);
  if (!moreOpen) { body.append(plCourseLists(c, now)); row.append(body); return row; }
  const rename = el('div', 'rename');
  const input = el('input', '', null); input.type = 'text'; input.maxLength = 40; input.placeholder = 'Nickname, like BIO 101'; input.value = nicknames[c.id] ?? '';
  input.setAttribute('aria-label', `Nickname for ${c.fullName ?? c.name}`);
  const save = el('button', '', 'Save'); save.type = 'button';
  save.addEventListener('click', (e) => { if (e.isTrusted) plannerNickname(c.id, input.value); });
  input.addEventListener('keydown', (e) => { if (e.key === 'Enter') { e.preventDefault(); plannerNickname(c.id, input.value); } });
  rename.append(input, save);
  body.append(rename);
  const lvl = el('div', 'levels'); lvl.setAttribute('role', 'radiogroup'); lvl.setAttribute('aria-label', 'Class level');
  for (const k of Object.keys(LEVELS)) {
    const b = el('button', (levels[c.id] ?? 'regular') === k ? 'on' : '', LEVEL_NAMES[k]); b.type = 'button'; b.setAttribute('role', 'radio'); b.setAttribute('aria-checked', String((levels[c.id] ?? 'regular') === k));
    b.addEventListener('click', (e) => { if (e.isTrusted) plannerLevel(c.id, k); });
    lvl.append(b);
  }
  body.append(lvl);
  // Every assignment the laptop already has: missing, ahead, marked.
  body.append(plCourseLists(c, now));
  row.append(body);
  return row;
}

/// "An A needs 91% on the final." Canvas only reports weights when the course
/// turns weighting on; with none, one small field asks what the final is worth.
function plWhatIf(c) {
  const { data, targets } = plannerState();
  const wrap = el('div', 'whatif');
  const groups = data.weights?.[c.id] ?? null;
  const guess = groups ? groups.find((g) => /final|exam/i.test(g.name))?.weight ?? null : null;
  const weight = plWeight[c.id] ?? guess;
  const options = targetsFor(c.score);
  const aim = targets[c.id] ?? null;
  const target = plTarget[c.id] ?? aim ?? options.find(([, cut]) => c.score >= cut)?.[1] ?? options[0][1];
  const letterOf = (cut) => options.find(([, x]) => x === cut)?.[0] ?? `${cut}%`;
  const chips = el('div', 'targets');
  chips.append(el('span', 'lead', 'Aiming for'));
  for (const [name, cut] of options) {
    const b = el('button', target === cut ? 'on' : '', name); b.type = 'button'; b.setAttribute('aria-pressed', String(target === cut));
    b.addEventListener('click', (e) => { if (!e.isTrusted) return; plTarget[c.id] = cut; plannerAim(c.id, cut); });
    chips.append(b);
  }
  wrap.append(chips);
  if (weight == null) {
    const ask = el('div', 'weight');
    ask.append(el('span', '', 'The final is worth'));
    const input = el('input', '', null); input.type = 'number'; input.min = 1; input.max = 100; input.placeholder = '30'; input.setAttribute('aria-label', 'What the final is worth, as a per cent of the grade');
    const set = el('button', '', 'Set'); set.type = 'button';
    const go = () => { const n = Number(input.value); if (n > 0 && n <= 100) { plWeight[c.id] = n; renderPlanner(); } };
    set.addEventListener('click', go);
    input.addEventListener('keydown', (e) => { if (e.key === 'Enter') { e.preventDefault(); go(); } });
    ask.append(input, el('span', '', '% of the grade'), set);
    wrap.append(ask);
    return wrap;
  }
  const needed = requiredScore({ current: c.score, target, weight });
  let line;
  if (needed === null) line = 'Once something is graded this works itself out.';
  else if (needed > 100) {
    const reachable = options.filter(([, cut]) => (requiredScore({ current: c.score, target: cut, weight }) ?? 999) <= 100)[0];
    line = reachable ? `${letterOf(target)} is out of reach. ${reachable[0]} needs ${requiredScore({ current: c.score, target: reachable[1], weight })}% on the final.` : `${letterOf(target)} is out of reach; the grade is settled either way.`;
  } else line = `${letterOf(target)} needs ${needed}% on the final (${weight}% of the grade). You are at ${c.score}%.`;
  wrap.append(el('p', 'line', line));
  return wrap;
}

/// Every assignment the laptop already has for one class: what the school
/// marked missing, what is ahead, what is marked. Canvas hides the same list
/// behind four clicks and a page load.
function plCourseLists(c, now) {
  const { data } = plannerState();
  const wrap = el('div', 'every');
  const tasks = data.tasks.filter((t) => String(t.courseId) === String(c.id));
  const graded = (data.graded?.[c.id] ?? []).slice().reverse();
  const missing = tasks.filter((t) => t.missing && !isDone(t));
  const upcoming = tasks.filter((t) => !isDone(t) && !t.missing);
  const missingIds = new Set(missing.map((t) => t.id));
  const gradedOnly = graded.filter((g) => !missingIds.has(g.id));
  const chips = el('div', 'chips');
  const counts = { all: missing.length + upcoming.length + gradedOnly.length, missing: missing.length, upcoming: upcoming.length, graded: graded.length };
  for (const [key, label] of [['all', 'Every assignment'], ['missing', 'Missing'], ['upcoming', 'Ahead'], ['graded', 'Marked']]) {
    const b = el('button', plCourseList === key ? 'on' : '', label); b.type = 'button'; b.setAttribute('aria-pressed', String(plCourseList === key));
    b.append(el('em', '', String(counts[key])));
    b.addEventListener('click', (e) => { if (!e.isTrusted) return; plCourseList = key; renderPlanner(); });
    chips.append(b);
  }
  wrap.append(chips);
  const ul = el('ul', 'pk-w-list pk-pl-rows small');
  const taskRow = (t, amber) => {
    const li = el('li', amber ? 'late' : '');
    li.append(classTile(t));
    const url = safeURL(t.url);
    const name = url ? el('a', 'pk-pl-name', t.title) : el('b', 'pk-pl-name', t.title);
    if (url) name.href = url;
    li.append(name, el('small', amber ? 'amber' : '', t.dueAt ? dueLabel(t, now).replace(' · still counts', '') : 'any time'));
    return li;
  };
  const gradedRow = (g) => {
    const li = el('li', 'marked');
    li.append(classTile({ courseName: c.name, colorHex: c.colorHex }), el('b', 'pk-pl-name', g.title), el('small', '', `${g.score}/${g.outOf}${typeof g.classMean === 'number' ? ` · class ${g.classMean}` : ''}`));
    return li;
  };
  const rows = plCourseList === 'graded' ? graded.map(gradedRow)
    : plCourseList === 'missing' ? missing.map((t) => taskRow(t, true))
    : plCourseList === 'upcoming' ? upcoming.map((t) => taskRow(t, false))
    : [...missing.map((t) => taskRow(t, true)), ...upcoming.map((t) => taskRow(t, false)), ...gradedOnly.map(gradedRow)];
  if (!rows.length) ul.append(el('li', 'empty', plCourseList === 'missing' ? 'Nothing missing. Good.' : plCourseList === 'graded' ? 'Nothing marked yet.' : 'Nothing here yet.'));
  for (const r of rows) ul.append(r);
  wrap.append(ul);
  wrap.append(el('p', 'pk-pl-foot', 'What Canvas handed over, nothing added.'));
  return wrap;
}

// MARK: - A course's own grades page: our row is the page

const GRADES_ID = 'pk-grades';
function gradesCourseId() { return /^\/courses\/(\d+)\/grades\/?$/.exec(location.pathname)?.[1] ?? null; }
/// The student's own Grades page (/grades): every class, so our rows are the
/// page there too, with Canvas's two tables folded under.
function allGradesPage() { return /^\/grades\/?$/.test(location.pathname); }

/// Our grades row stands in for Canvas's table when it has this course from a
/// sync, the cards are on, and the row has not been put back. Canvas's table
/// folds under it (the `grades-page` receipt row); "Show Canvas's table"
/// brings it out for this visit, Put back for good.
function gradesPageShows() {
  const { data, putBack, skin, killed } = plannerState();
  if (killed || !skin.cards || putBack['grades-page']) return false;
  if (allGradesPage()) return !!document.querySelector('#content table') && (data.courses ?? []).some((c) => c.name && /^\d+$/.test(String(c.id)));
  const id = gradesCourseId();
  if (!id || !document.querySelector('#grades_summary, #grade-summary-react')) return false;
  return (data.courses ?? []).some((c) => String(c.id) === id);
}

function renderGradesPage() {
  const existing = document.getElementById(GRADES_ID);
  if (!gradesPageShows()) { existing?.remove(); document.documentElement.classList.remove('pk-grades-page', 'pk-grades-all'); plGradesFixed = null; return; }
  const all = allGradesPage();
  const id = gradesCourseId();
  const now = new Date();
  const { data, levels, nicknames, targets } = plannerState();
  const c = all ? null : data.courses.find((x) => String(x.id) === id);
  plGradesFixed = all ? null : id;
  const key = all
    ? JSON.stringify([data.courses.map((x) => [x.id, x.name, x.score, x.grade]), (data.pastCourses ?? []).map((x) => [x.id, x.grade, x.score]), plPastOpen, levels, nicknames, targets, plOpenCourse, plCourseList, plTarget, plWeight])
    : JSON.stringify([c.id, c.name, c.score, c.grade, (data.graded?.[id] ?? []).map((g) => [g.id, g.score]), data.tasks.filter((t) => String(t.courseId) === id).map((t) => [t.id, t.submittedAt, t.doneAt, t.missing]), levels[id], nicknames[id], targets[id], plCourseList, plTarget, plWeight]);
  document.documentElement.classList.add('pk-grades-page');
  document.documentElement.classList.toggle('pk-grades-all', all);
  // Under Canvas's own title row, which React draws after the page; until it
  // is there the box leads #content, and moves under the title when it lands.
  // On /grades the title is a plain h1 Canvas already wrote.
  const anchor = all ? document.querySelector('#content > h1') : document.querySelector('#grade-summary-content > .ic-Action-header, #content > .header-bar');
  if (existing && existing.dataset.key === key) {
    if (anchor && anchor.nextElementSibling !== existing) anchor.after(existing);
    return;
  }
  const box = el('section', '', null);
  box.id = GRADES_ID; box.dataset.key = key;
  box.setAttribute('aria-label', all ? 'Prepkin: your grades' : 'Prepkin: your grade in this class');
  if (all) { box.append(plGrades(now, { heading: null })); if (data.pastCourses?.length) box.append(plPastFold(data.pastCourses)); }
  else box.append(plGroupHead('Your grade'), plGradeRow(c, now));
  // Canvas's own table (and, on a course, its side column), one click away
  // for this visit: a fold in the group shape, like Later on the planner.
  // The receipt's Put back brings it back for good.
  const open = document.documentElement.classList.contains('pk-grades-open');
  const show = plGroupHead("Canvas's table", 0, { fold: true, open, onToggle: (e) => {
    if (e && !e.isTrusted) return;
    document.documentElement.classList.toggle('pk-grades-open'); existing?.remove(); document.getElementById(GRADES_ID)?.remove(); renderGradesPage();
  } });
  show.classList.add('pk-gr-show');
  box.append(show);
  if (existing) existing.replaceWith(box);
  else if (anchor) anchor.after(box);
  else document.getElementById('content')?.prepend(box);
}

// MARK: - The term, in numbers

/// Which term the recap is for: the month the last due date fell in. The
/// dismiss remembers it, so the card shows once a term.
function plRecapKey(tasks, now) {
  const { data } = plannerState();
  const r = termRecap(tasks, now, data.graded, data.courses);
  const d = r.lastDue ?? now;
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
}

/// The card at the top of the planner when a term is ending: the big number,
/// the lines, a bar per course, Save as a picture, and a way to put it away.
function plRecapCard(now, { soFar = false } = {}) {
  const { data } = plannerState();
  const r = termRecap(data.tasks, now, data.graded, data.courses);
  const fmt = (d) => d.toLocaleDateString([], { month: 'short', day: 'numeric' });
  const card = el('div', `pk-pl-recap${soFar ? ' so-far' : ''}`);
  const h = el('div', 'head');
  h.append(el('b', '', soFar ? 'So far this term' : 'Your term, in numbers'));
  if (soFar && r.firstDue) h.append(el('small', '', `since ${fmt(r.firstDue)}`));
  else if (r.firstDue && r.lastDue) h.append(el('small', '', `${fmt(r.firstDue)} to ${fmt(r.lastDue)}`));
  card.append(h);
  const big = el('div', 'big');
  big.append(el('strong', '', String(r.handedIn)), el('span', '', ` thing${r.handedIn === 1 ? '' : 's'} handed in${r.total ? ` of ${r.total}` : ''}`));
  card.append(big);
  const most = r.byCourse.reduce((m, c) => (m && m.total >= c.total ? m : c), null);
  const lines = [
    r.onTimePct !== null ? `${r.onTimePct}% of it on time` : null,
    r.busiestWeek ? `Busiest week: ${fmt(r.busiestWeek.start)} to ${fmt(r.busiestWeek.end)}, ${r.busiestWeek.count} handed in` : null,
    r.hour ? `Most often handed in around ${hourLabel(r.hour.hour)}` : null,
    most ? `${shortCourse(most.name)} asked the most of you` : null,
  ].filter(Boolean);
  const ul = el('ul', 'lines');
  for (const l of lines) ul.append(el('li', '', l));
  card.append(ul);
  const bars = el('ul', 'courses');
  for (const c of r.byCourse.slice(0, 6)) {
    const li = el('li');
    li.append(classTile({ courseName: c.name, colorHex: c.colorHex }), el('b', '', shortCourse(c.name)), el('em', '', `${c.done} of ${c.total}`));
    const bar = el('i'); const fill = el('u'); fill.style.width = `${c.total ? Math.round((c.done / c.total) * 100) : 0}%`; const color = safeColor(c.colorHex); if (color) { fill.style.background = color; fill.dataset.pkCourseColor = ''; } bar.append(fill);
    li.append(bar);
    bars.append(li);
  }
  card.append(bars);
  const actions = el('div', 'actions');
  const save = el('span', 'start', 'Save as a picture'); save.setAttribute('role', 'button'); save.tabIndex = 0;
  save.addEventListener('click', (e) => { if (e.isTrusted) saveRecapPicture(now); });
  const later = el('span', 'ghost', 'Put it away'); later.setAttribute('role', 'button'); later.tabIndex = 0;
  later.addEventListener('click', (e) => { if (!e.isTrusted) return; if (soFar) plannerDismissSoFar(soFarKey(now)); else plannerDismissRecap(plRecapKey(data.tasks, now)); });
  actions.append(save, later);
  card.append(actions);
  card.append(el('p', 'pk-pl-foot', 'Counted on your own laptop. Nothing was sent anywhere, and the picture has no grades in it.'));
  return card;
}

/// The one way in: a quiet line at the foot of Today. Click, and the form
/// takes its place.
function plAddLine() {
  const p = el('p', 'pk-pl-addline');
  const b = el('span', 'add', '+ Add a task');
  b.setAttribute('role', 'button'); b.tabIndex = 0;
  const go = () => { plAdding = true; renderPlanner(); };
  b.addEventListener('click', go);
  b.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); go(); } });
  p.append(b);
  return p;
}

/// Add a task of your own: a title, a day, a class. Lives in this browser.
function plAddForm(now) {
  const { data } = plannerState();
  const form = el('form', 'pk-pl-add');
  const title = el('input', '', null); title.type = 'text'; title.placeholder = 'What is it?'; title.maxLength = 120; title.required = true; title.name = 'title';
  const date = el('input', '', null); date.type = 'date'; date.name = 'date'; date.value = dayKey(now);
  const course = el('select', '', null); course.name = 'course';
  const none = el('option', '', 'No class'); none.value = ''; course.append(none);
  for (const c of data.courses.filter((c) => c.name)) { const o = el('option', '', shortCourse(c.name)); o.value = String(c.id); course.append(o); }
  const submit = el('button', 'start', 'Add'); submit.type = 'submit';
  const cancel = el('span', 'ghost', 'Cancel'); cancel.setAttribute('role', 'button'); cancel.tabIndex = 0;
  cancel.addEventListener('click', () => { plAdding = false; renderPlanner(); });
  form.append(title, date, course, submit, cancel, el('small', '', 'Lives in this browser. Canvas and your phone never see it.'));
  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    if (!e.isTrusted || !alive()) return;
    const name = title.value.trim(); if (!name) return;
    const d = dayFromKey(date.value);
    const pick = data.courses.find((c) => String(c.id) === course.value);
    const dueAt = d ? new Date(d.getFullYear(), d.getMonth(), d.getDate(), 23, 59).toISOString() : null;
    const ownTasks = [...plannerState().ownTasks, { id: `own-${Date.now()}`, title: name, dueAt, courseId: pick?.id ?? null,
      courseName: pick?.fullName ?? pick?.name ?? '', colorHex: pick?.colorHex ?? null, createdAt: new Date().toISOString(), submittedAt: null }];
    plannerSetOwnTasks(ownTasks);
    plAdding = false;
    await chrome.storage.local.set({ ownTasks });
  });
  setTimeout(() => title.focus(), 0);
  return form;
}

// MARK: - Looks: the theme shop, in the page
//
// The same tiles the buddy's panel used to carry, with room to breathe:
// what you own first (the worn one ticked), then the rest under Locked with
// a price. One click wears a look you own; a locked one asks once, at the
// top, and the phone is told what was spent. Under the tiles, the course
// pictures: a banner from the worn theme, or a picture of your own.

function renderLooks() {
  const existing = document.getElementById(LOOKS_ID);
  const head = document.getElementById('dashboard_header_container');
  if (!plannerShows() || plTab !== 'looks' || !head) { existing?.remove(); return; }
  const { wallet, skin, data } = plannerState();
  const { LOOKS, LOOKS_BY_ID, PAPERS, ART_AVAILABLE, cardArt, banners, ownArt, worn } = plannerLooks();
  const key = JSON.stringify([wallet.coins, wallet.owned, wallet.wearing, !!skin.dark, plConfirm, Object.keys(cardArt), banners, data.courses.map((c) => [c.id, c.colorHex]), ownArt?.thumb?.length ?? 0, plWallBusy]);
  if (existing && existing.dataset.key === key) return;

  const box = el('section', '', null);
  box.id = LOOKS_ID; box.dataset.key = key;
  box.setAttribute('aria-label', 'Prepkin: looks');

  const headRow = el('div', 'pk-pl-head');
  const title = el('div', 'pk-pl-title');
  title.append(el('b', '', 'Looks'), el('small', '', 'Earned with coins from verified work. Dark is always free.'));
  headRow.append(title);
  if (wallet.coins !== null) {
    const coins = el('div', 'pk-pl-coins');
    coins.append(el('i', 'coin', null), el('b', '', String(wallet.coins)), el('span', '', 'coins'));
    headRow.append(coins);
  }
  box.append(headRow);

  // The question, when a locked look was picked.
  const asked = plConfirm ? LOOKS_BY_ID[plConfirm] : null;
  if (asked) {
    const ask = el('div', 'pk-pl-ask');
    const afford = wallet.coins !== null && wallet.coins >= asked.price;
    ask.append(el('b', '', `Wear ${asked.name}?`));
    ask.append(el('span', '', afford ? `${asked.price} coins. ${asked.vibe ?? ''}`.trim()
      : wallet.coins === null ? 'Link your phone in the Prepkin popup to spend coins.'
      : `${asked.price - wallet.coins} more coins to go. Verified work earns 30 each.`));
    const actions = el('div', 'actions');
    if (afford) {
      const yes = el('span', 'start', 'Wear it');
      yes.setAttribute('role', 'button'); yes.tabIndex = 0;
      yes.addEventListener('click', (e) => { if (!e.isTrusted) return; plannerBuy(asked.id).then(() => { plConfirm = null; renderLooks(); }); });
      actions.append(yes);
    }
    const no = el('span', 'ghost', 'Not now');
    no.setAttribute('role', 'button'); no.tabIndex = 0;
    no.addEventListener('click', () => { plConfirm = null; renderLooks(); });
    actions.append(no);
    ask.append(actions);
    box.append(ask);
  }

  // The student's own classes, so every tile's two cards are theirs.
  const courses = data.courses.filter((c) => /^\d+$/.test(String(c.id)));
  // The worn look first, then "Your picture", then the rest of what is theirs.
  const yours = LOOKS.filter((look) => look.free || wallet.owned.includes(look.id))
    .sort((a, b) => (b.id === wallet.wearing) - (a.id === wallet.wearing) || (b.art === 'own') - (a.art === 'own'));
  const locked = LOOKS.filter((look) => !yours.includes(look));
  const grid = (list) => {
    const g = el('div', 'pk-pl-looks');
    for (const look of list) g.append(plLookTile(look, { wallet, skin, PAPERS, ART_AVAILABLE, owned: yours.includes(look), courses, ownArt }));
    return g;
  };
  box.append(el('span', 'pk-pl-label plain', 'Yours'), grid(yours));
  if (locked.length) box.append(el('span', 'pk-pl-label plain', 'Locked'), grid(locked));
  box.append(plPictures(worn, { data, cardArt, banners, ART_AVAILABLE, ownArt }));

  if (existing) existing.replaceWith(box); else head.after(box);
}

/// A tile is this student's dashboard in that theme, small: the paper (or the
/// wallpaper under its wash), the rail, a title and a link in the accent, two
/// cards banded in the student's own first two course colours, the rail card
/// beside them. Drawn in container units, so the tile is the page at 4:3 and
/// nothing is scaled. The name and the mood under it, a tick when worn, a
/// price when locked. No request: the wallpapers are the ones already bundled.
function plLookTile(look, { wallet, skin, PAPERS, ART_AVAILABLE, owned, courses = [], ownArt = null }) {
  // "Your picture" with no photo yet is a place to drop one: the tile is a
  // label over a file input, and the scene says so. With a photo it is a look
  // like any other, in the photo's own colours, with a way to take it off.
  const own = look.art === 'own';
  if (own && typeof ownArt?.src !== 'string') return plOwnEmptyTile(look, { skin, PAPERS });
  if (own) look = { ...look, ...(ownArt.palette ?? {}) };
  const wearing = wallet.wearing === look.id;
  const dark = !!skin.dark;
  const stock = stockFor(look, dark);
  const p = PAPERS[stock];
  const art = alive() ? artFor(look, ART_AVAILABLE, (f) => chrome.runtime.getURL(f), ownArt) : null;
  const tile = el('div', `pk-pl-look${wearing ? ' wearing' : ''}${p.dark ? ' on-dark' : ''}${art ? ' has-art' : ''}${own ? ' own' : ''}`);
  tile.setAttribute('role', 'button'); tile.tabIndex = 0; tile.setAttribute('aria-pressed', String(wearing));
  tile.dataset.look = look.id;
  tile.style.cssText = tileTokens(look, dark, courses, art);
  const scene = el('div', 'scene');
  scene.setAttribute('aria-hidden', 'true');
  if (own) {
    const off = el('span', 'remove', '×');
    off.setAttribute('role', 'button'); off.tabIndex = 0; off.setAttribute('aria-label', 'Remove your picture'); off.title = 'Remove your picture';
    off.setAttribute('aria-hidden', 'false');
    const clear = (e) => { e.stopPropagation(); e.preventDefault(); if (e.isTrusted) plannerClearWallpaperAsync().then(() => renderLooks()); };
    off.addEventListener('click', clear);
    off.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') clear(e); });
    scene.append(off);
  }
  scene.append(el('i', 'rail'));
  const page = el('div', 'page');
  page.append(el('b', 'title'), el('i', 'link'));
  for (const n of [1, 2]) {
    const card = el('span', 'card');
    const band = el('i', 'band');
    band.style.setProperty('--band', `var(--tc${n})`);
    band.style.setProperty('--art', `var(--tcard${n})`);
    card.append(band, el('em'), el('em'));
    page.append(card);
  }
  const side = el('span', 'side');
  side.append(el('em'), el('em'), el('em'));
  page.append(side);
  scene.append(page);
  if (wearing) scene.append(el('span', 'tick', '✓'));
  tile.append(scene, el('b', '', look.name), el('small', '', look.vibe ?? paperLine(stock)));
  if (!owned) { const price = el('span', 'price', null); price.append(el('i', 'coin', null), el('span', '', String(look.price))); tile.append(price); }
  const pick = (e) => {
    if (!e.isTrusted) return;
    if (owned) { if (!wearing) plannerBuy(look.id).then(() => renderLooks()); return; }
    plConfirm = look.id; renderLooks();
    document.getElementById(LOOKS_ID)?.scrollIntoView({ behavior: 'smooth', block: 'start' });
  };
  tile.addEventListener('click', pick);
  tile.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); pick(e); } });
  return tile;
}

let plWallBusy = false;

/// "Your picture" before a photo is chosen: the paper, a dashed edge, the
/// words. A label, so the click is the file picker's own.
function plOwnEmptyTile(look, { skin, PAPERS }) {
  const dark = !!skin.dark;
  const p = PAPERS[stockFor(look, dark)];
  const tile = el('label', `pk-pl-look own empty${p.dark ? ' on-dark' : ''}${plWallBusy ? ' busy' : ''}`);
  tile.dataset.look = look.id;
  tile.style.cssText = tileTokens(look, dark, [], null);
  const scene = el('div', 'scene');
  scene.append(el('span', 'add', plWallBusy ? 'Reading it…' : '+ Add a photo'));
  const input = el('input', '', null); input.type = 'file'; input.accept = 'image/*';
  input.setAttribute('aria-label', 'Your picture: choose a photo for the wallpaper');
  input.addEventListener('change', () => {
    const file = input.files?.[0]; if (!file) return;
    plWallBusy = true; renderLooks();
    plannerWallpaperAsync(file).catch(() => {}).then(() => { plWallBusy = false; renderLooks(); });
  });
  tile.append(scene, input, el('b', '', look.name), el('small', '', 'A photo of yours, under the paper. Kept in this browser.'));
  return tile;
}

/// Course pictures: the worn theme's banners for each course, or a picture of
/// your own, read here, shrunk here, kept in this browser.
function plPictures(look, { data, cardArt, banners, ART_AVAILABLE, ownArt = null }) {
  const wrap = el('div', 'pk-pl-pictures');
  const courses = data.courses.filter((c) => c.name && /^\d+$/.test(String(c.id))).slice(0, 8);
  if (!courses.length) return wrap;
  const art = alive() ? artFor(look, ART_AVAILABLE, (f) => chrome.runtime.getURL(f), ownArt) : null;
  wrap.append(el('span', 'pk-pl-label plain', 'Course pictures'));
  for (const c of courses) {
    // Not "row": Canvas's own .row (its grid) reached in and laid this out
    // backwards on a real school (2026-09-17).
    const row = el('div', 'pk-pic-row');
    const name = el('b', '', shortCourse(c.name)); name.title = c.name;
    row.append(name);
    const thumbs = el('div', 'thumbs');
    const own = cardArt[c.id];
    if (art) art.cards.forEach((u, i) => {
      const b = el('span', `thumb${!own && banners[c.id] === i + 1 ? ' on' : ''}`, null);
      b.setAttribute('role', 'button'); b.tabIndex = 0; b.setAttribute('aria-label', `Banner ${i + 1}`);
      b.style.backgroundImage = `url("${u}")`;
      b.addEventListener('click', (e) => { if (e.isTrusted) plannerBannerAsync(String(c.id), i + 1).then(() => renderLooks()); });
      thumbs.append(b);
    });
    if (own) {
      const mine = el('span', 'thumb own on', null);
      mine.setAttribute('role', 'button'); mine.tabIndex = 0; mine.setAttribute('aria-label', `Remove your picture from ${c.name}`);
      mine.style.backgroundImage = `url("${own.thumb ?? own.src}")`;
      mine.append(el('i', '', '×'));
      mine.addEventListener('click', (e) => { if (e.isTrusted) plannerClearPictureAsync(String(c.id)).then(() => renderLooks()); });
      thumbs.append(mine);
    }
    const pick = el('label', 'pick', null);
    const input = el('input', '', null); input.type = 'file'; input.accept = 'image/*';
    input.addEventListener('change', () => {
      const file = input.files?.[0]; if (!file) return;
      pick.classList.add('busy');
      plannerPictureAsync(String(c.id), file).catch(() => {}).then(() => renderLooks());
    });
    pick.append(input, el('span', '', own ? 'Change' : 'Your picture'));
    thumbs.append(pick);
    row.append(thumbs);
    wrap.append(row);
  }
  wrap.append(el('small', '', 'A picture you choose is shrunk here and kept in this browser. It is never uploaded, and it never goes to your phone.'));
  return wrap;
}

if (typeof module !== 'undefined') {
  module.exports = {};
}

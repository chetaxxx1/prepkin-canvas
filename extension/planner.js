// The Planner: the dashboard's main column as a week, in the page.
//
// A tab beside Canvas's own course cards. Seven columns, one per day, a card
// per piece of work in its course's colour with one of the app's icons on it;
// drag a card to another day to plan it. Under the week, three small cards:
// grades, the league, and focus. No pop-out: this is where the buddy's panel
// used to keep all of it.
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
const PLANNER_ICON_DIR = 'art/icons/';
const PLANNER_ONE_DAY = 86400000;

/// Which week the grid shows, in weeks from this one. The arrows move it;
/// Today brings it back.
let plWeek = 0;
/// Whether the planner tab is the one showing. Remembered per browser.
let plOn = false;
/// The add-a-task form, open or not.
let plAdding = false;

/// The app's icon for a piece of work, read off its title. The pencil is the
/// plain assignment; a wrong icon would be worse than a plain one.
const PLANNER_ICONS = [
  [/problem set|pset|homework|\bhw\b|exercise|worksheet/i, 'problemSet'],
  [/\blab\b|\blabs\b|lab writeup|lab report/i, 'labs'],
  [/quiz|exam|\btest\b|midterm|final|review|check\b/i, 'study'],
  [/\bread|chapter|article|textbook/i, 'reading'],
];
function plIconFor(title) {
  for (const [re, id] of PLANNER_ICONS) if (re.test(String(title ?? ''))) return id;
  return 'writing';
}

function plIcon(name, size = 22) {
  const img = document.createElement('img');
  img.width = size; img.height = size; img.alt = ''; img.setAttribute('aria-hidden', 'true');
  img.className = 'pk-pl-icon';
  if (alive()) img.src = chrome.runtime.getURL(`${PLANNER_ICON_DIR}${name}.webp`);
  return img;
}

/// The Monday the shown week starts on.
function plMonday(now = new Date()) {
  const d = startOfDay(now);
  d.setDate(d.getDate() - ((d.getDay() + 6) % 7) + plWeek * 7);
  return d;
}

/// Seven columns for the shown week: each day's date and the work sitting on
/// it (planned there, or due there), plus what slipped from before the week.
function plColumns(tasks, now = new Date()) {
  const monday = plMonday(now);
  const end = new Date(monday.getTime() + 7 * PLANNER_ONE_DAY);
  const placed = tasks.map((t) => ({ t, day: planDay(t) })).filter((x) => x.day);
  const cols = Array.from({ length: 7 }, (_, i) => {
    const date = new Date(monday.getTime() + i * PLANNER_ONE_DAY);
    const items = placed.filter((x) => sameLocalDay(x.day, date)).map((x) => x.t)
      .sort((a, b) => Date.parse(a.dueAt ?? 0) - Date.parse(b.dueAt ?? 0));
    return { date, items, today: sameLocalDay(date, now), past: date < startOfDay(now) };
  });
  // Slipped: not in, sat before the shown week, and not planned into it.
  const slipped = placed.filter((x) => !x.t.submittedAt && x.day < monday && x.day >= startOfDay(new Date(monday.getTime() - 21 * PLANNER_ONE_DAY)))
    .map((x) => x.t).sort((a, b) => Date.parse(a.dueAt ?? 0) - Date.parse(b.dueAt ?? 0));
  const undated = tasks.filter((t) => !planDay(t) && !t.submittedAt);
  return { monday, end, cols, slipped, undated };
}

function plannerShows() {
  return railShows() && !plannerState().putBack.planner && !!document.getElementById('DashboardCard_Container');
}

/// The tabs in the dashboard's own title row: Courses (Canvas's cards) and
/// Planner (ours). The choice is remembered.
function renderPlannerTabs() {
  const existing = document.getElementById(PLANNER_TABS_ID);
  const bar = document.querySelector('#dashboard_header_container .ic-Dashboard-header__layout');
  if (!bar || !plannerShows()) { existing?.remove(); document.documentElement.classList.remove('pk-planner-on'); return; }
  document.documentElement.classList.toggle('pk-planner-on', plOn);
  if (existing && existing.parentElement === bar) { plSyncTabs(existing); return; }
  existing?.remove();
  const tabs = el('div', '', null);
  tabs.id = PLANNER_TABS_ID;
  tabs.setAttribute('role', 'tablist'); tabs.setAttribute('aria-label', 'Dashboard');
  for (const [key, label] of [['cards', 'Courses'], ['planner', 'Planner']]) {
    const tab = el('span', '', label);
    tab.setAttribute('role', 'tab'); tab.tabIndex = 0; tab.dataset.tab = key;
    const pick = (e) => { if (!e.isTrusted) return; plSetOn(key === 'planner'); };
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
    const on = (tab.dataset.tab === 'planner') === plOn;
    tab.classList.toggle('on', on);
    tab.setAttribute('aria-selected', String(on));
  }
}

function plSetOn(on) {
  plOn = !!on;
  if (alive()) chrome.storage.local.set({ dashTab: plOn ? 'planner' : 'cards' }).catch(() => {});
  renderPlannerTabs();
  renderPlanner();
}

/// The planner itself, right under the dashboard's title row. Rebuilt only
/// when what it shows has changed; the clock in the focus card ticks in place.
function renderPlanner() {
  const existing = document.getElementById(PLANNER_ID);
  const head = document.getElementById('dashboard_header_container');
  if (!plannerShows() || !plOn || !head) { existing?.remove(); return; }
  const now = new Date();
  const { data, plans, wallet, focus, skin, levels } = plannerState();
  const week = plColumns(data.tasks, now);
  const running = focus.state === 'running';
  const key = JSON.stringify([plWeek, week.cols.map((c) => c.items.map((t) => [t.id, t.submittedAt, plans[t.id] ?? null])),
    week.slipped.map((t) => t.id), week.undated.map((t) => t.id), data.courses.map((c) => [c.id, c.score, c.grade]),
    wallet.coins, wallet.league?.tier ?? null, wallet.league?.points ?? null, wallet.wearing, running && focus.title, focus.state,
    skin.focusMinutes, plAdding, levels]);
  if (existing && existing.dataset.key === key) return;

  const box = el('section', '', null);
  box.id = PLANNER_ID; box.dataset.key = key;
  box.setAttribute('aria-label', 'Prepkin: planner');

  // The week's head: the range, arrows, Today, and a way to add a task.
  const last = new Date(week.end - 1);
  const mon = (d) => d.toLocaleDateString([], { month: 'short' });
  const range = week.monday.getMonth() === last.getMonth()
    ? `${mon(week.monday)} ${week.monday.getDate()} – ${last.getDate()}`
    : `${mon(week.monday)} ${week.monday.getDate()} – ${mon(last)} ${last.getDate()}`;
  const inWeek = week.cols.flatMap((c) => c.items);
  const done = inWeek.filter((t) => t.submittedAt).length;
  const headRow = el('div', 'pk-pl-head');
  const title = el('div', 'pk-pl-title');
  title.append(plIcon('tabCalendar', 28), el('b', '', plWeek === 0 ? 'This week' : plWeek === 1 ? 'Next week' : plWeek === -1 ? 'Last week' : `Week of ${mon(week.monday)} ${week.monday.getDate()}`),
    el('small', '', `${range}${inWeek.length ? ` · ${done} of ${inWeek.length} in` : ''}`));
  const nav = el('div', 'pk-pl-nav');
  const arrow = (dir, label) => {
    const a = el('span', dir < 0 ? 'prev' : 'next', null);
    a.setAttribute('role', 'button'); a.tabIndex = 0; a.setAttribute('aria-label', label);
    const go = () => { plWeek += dir; renderPlanner(); };
    a.addEventListener('click', go);
    a.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); go(); } });
    return a;
  };
  const today = el('span', 'today', 'Today');
  today.setAttribute('role', 'button'); today.tabIndex = 0;
  today.addEventListener('click', () => { plWeek = 0; renderPlanner(); });
  today.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); plWeek = 0; renderPlanner(); } });
  const add = el('span', 'add', '+ Add a task');
  add.setAttribute('role', 'button'); add.tabIndex = 0;
  add.addEventListener('click', () => { plAdding = !plAdding; renderPlanner(); });
  add.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); plAdding = !plAdding; renderPlanner(); } });
  nav.append(arrow(-1, 'Previous week'), today, arrow(1, 'Next week'), add);
  headRow.append(title, nav);
  box.append(headRow);

  if (plAdding) box.append(plAddForm(now));

  // What slipped from before this week: a band of cards, amber, above the grid.
  if (week.slipped.length && plWeek === 0) {
    const band = el('div', 'pk-pl-slipped');
    band.append(el('span', 'pk-pl-label', `Past due · ${week.slipped.length}`));
    const row = el('div', 'row');
    for (const t of week.slipped) row.append(plCard(t, now, { slipped: true, wide: true }));
    band.append(row);
    box.append(band);
  }

  // The grid.
  const grid = el('div', 'pk-pl-grid');
  for (const c of week.cols) {
    const col = el('div', `pk-pl-col${c.today ? ' today' : c.past ? ' past' : ''}`);
    col.dataset.drop = dayKey(c.date);
    const h = el('div', 'pk-pl-day');
    h.append(el('span', '', c.date.toLocaleDateString([], { weekday: 'short' })), el('b', '', String(c.date.getDate())));
    col.append(h);
    for (const t of c.items) col.append(plCard(t, now, {}));
    if (!c.items.length) col.append(el('div', 'pk-pl-empty', c.today ? 'Nothing due' : ''));
    plDropTarget(col);
    grid.append(col);
  }
  box.append(grid);

  if (week.undated.length) {
    const band = el('div', 'pk-pl-slipped undated');
    band.append(el('span', 'pk-pl-label', `No due date · ${week.undated.length}`));
    const row = el('div', 'row');
    for (const t of week.undated) row.append(plCard(t, now, { wide: true }));
    band.append(row);
    box.append(band);
  }

  // Under the week: grades, the league, focus.
  const cards = el('div', 'pk-pl-cards');
  cards.append(plGradesCard(), plLeagueCard(), plFocusCard(now));
  box.append(cards);

  if (existing) existing.replaceWith(box); else head.after(box);
}

/// One piece of work as a card: the course's colour down the left, the app's
/// icon for the kind of work, the title (a link), the course and when.
function plCard(t, now, { slipped = false, wide = false } = {}) {
  const card = el('div', `pk-pl-task${t.submittedAt ? ' done' : ''}${slipped || (!t.submittedAt && t.dueAt && Date.parse(t.dueAt) < now.getTime() && !sameLocalDay(new Date(t.dueAt), now)) ? ' late' : ''}${isMoved(t) ? ' moved' : ''}`);
  const color = safeColor(t.colorHex);
  if (color) card.style.setProperty('--c', color);
  if (!t.submittedAt) { card.draggable = true; card.dataset.drag = String(t.id); plDragSource(card); }
  card.append(plIcon(plIconFor(t.title), 22));
  const body = el('div', 'body');
  const url = safeURL(t.url);
  const title = url ? el('a', '', t.title) : el('b', '', t.title);
  if (url) { title.href = url; title.className = 'title'; }
  body.append(title);
  const due = t.dueAt ? new Date(t.dueAt) : null;
  const when = t.submittedAt ? 'in'
    : slipped ? `was due ${due.toLocaleDateString([], { month: 'short', day: 'numeric' })}`
    : isMoved(t) ? `due ${dayShort(t, now)}`
    : due && !isNaN(due) ? due.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' }) : 'anytime';
  // In a day column the colour bar is the course, so the line is the time
  // alone; the wider band cards name the course.
  body.append(el('small', '', wide ? `${shortCourse(t.courseName)} · ${when}` : when));
  card.append(body);
  if (t.submittedAt) card.append(el('span', 'tick', '✓'));
  card.title = `${t.title}\n${t.courseName}${t.dueAt ? ` · ${dueLabel(t, now)}` : ''}${isMoved(t) ? '\nMoved. Drag it back to its due day to undo.' : ''}`;
  return card;
}

// Drag a card to a day: the plan. Dropping it on its own due day clears the plan.
let plDragging = null;
function plDragSource(card) {
  card.addEventListener('dragstart', (e) => {
    plDragging = card.dataset.drag;
    card.classList.add('dragging');
    try { e.dataTransfer.setData('text/plain', card.dataset.drag); e.dataTransfer.effectAllowed = 'move'; } catch {}
  });
  card.addEventListener('dragend', () => { plDragging = null; card.classList.remove('dragging'); document.querySelectorAll(`#${PLANNER_ID} .over`).forEach((n) => n.classList.remove('over')); });
}
function plDropTarget(col) {
  col.addEventListener('dragover', (e) => { if (!plDragging) return; e.preventDefault(); col.classList.add('over'); });
  col.addEventListener('dragleave', () => col.classList.remove('over'));
  col.addEventListener('drop', (e) => {
    if (!plDragging) return;
    e.preventDefault();
    const id = plDragging; plDragging = null;
    col.classList.remove('over');
    const t = plannerState().data.tasks.find((x) => String(x.id) === id);
    if (!t) return;
    const due = t.dueAt ? startOfDay(new Date(t.dueAt)) : null;
    const target = dayFromKey(col.dataset.drop);
    // Back on its due day is not a plan, it is the plan's end.
    plannerPlan(id, due && target && sameLocalDay(due, target) ? null : col.dataset.drop).then(() => renderPlanner());
  });
}

/// Grades: each course's score and letter, one bar each, the estimate under.
function plGradesCard() {
  const { data, levels } = plannerState();
  const card = el('div', 'pk-pl-card grades');
  const h = el('div', 'head'); h.append(plIcon('calculator', 26), el('b', '', 'Grades'));
  card.append(h);
  const courses = data.courses.filter((c) => c.name && /^\d+$/.test(String(c.id)));
  const list = el('div', 'list');
  for (const c of courses) {
    const row = el('div', 'grow');
    const dot = el('i', '', null); const color = safeColor(c.colorHex); if (color) dot.style.background = color;
    const name = el('span', '', shortCourse(c.name)); name.title = c.name;
    const pct = typeof c.score === 'number' ? Math.max(0, Math.min(100, c.score)) : null;
    const val = el('b', '', pct === null ? '—' : `${c.score}%${c.grade ? ` · ${c.grade}` : ''}`);
    row.append(dot, name, val);
    if (pct !== null) { const bar = el('div', 'bar'); const fill = el('i', '', null); fill.style.width = `${pct}%`; if (color) fill.style.background = color; bar.append(fill); row.append(bar); }
    list.append(row);
  }
  if (!courses.length) list.append(el('div', 'quiet', 'Nothing graded yet.'));
  card.append(list);
  const est = gpa(courses, levels);
  if (est) card.append(el('div', 'foot', `GPA about ${est.weighted ?? est.unweighted}${est.weighted ? ' weighted' : ''}. An estimate; your school's scale wins.`));
  return card;
}

/// The league: the tier's shield, how long is left, the bar, the pod place.
function plLeagueCard() {
  const { wallet, TIERS } = plannerState();
  const card = el('div', 'pk-pl-card league');
  const L = wallet.league;
  const tier = L ? tierOf(L) : null;
  const h = el('div', 'head');
  h.append(plIcon(tier ? `tier${tier.id === 'openwater' ? 'OpenWater' : tier.id[0].toUpperCase() + tier.id.slice(1)}` : 'pod', 26), el('b', '', tier ? tier.name : 'League'));
  const left = L ? leagueDaysLeft(L) : null;
  if (left) h.append(el('span', 'meta', left));
  card.append(h);
  if (!L) { card.append(el('div', 'quiet', 'Link your phone and your week counts in a pod of five.')); return card; }
  const pts = Math.max(0, Number(L.points) || 0);
  const bar = typeof L.bar === 'number' ? L.bar : null;
  const next = TIERS[TIERS.indexOf(tier) + 1] ?? null;
  card.append(el('div', 'big', `${pts} earned this week`));
  if (bar !== null) {
    const track = el('div', 'bar'); const fill = el('i', '', null); fill.style.width = `${Math.min(100, Math.round((pts / bar) * 100))}%`; fill.style.background = tier.color; track.append(fill);
    card.append(track);
    card.append(el('div', 'foot', pts >= bar ? `Bar cleared. ${next?.name ?? ''} next week.` : `${bar - pts} to go for ${next?.name ?? 'the next tier'}.`));
  } else card.append(el('div', 'foot', 'Deep is the last one.'));
  const board = Array.isArray(L.board) ? L.board : null;
  const rank = board ? board.findIndex((m) => m.you) + 1 : 0;
  const ordinal = (n) => `${n}${['th', 'st', 'nd', 'rd'][(n % 100 > 10 && n % 100 < 14) ? 0 : Math.min(n % 10, 4) % 4 || 0] ?? 'th'}`;
  if (board && board.length > 1 && rank) card.append(el('div', 'foot', `${ordinal(rank)} of ${board.length} in your pod. Nothing here ever moves you down.`));
  return card;
}

/// Focus: the next thing and the two ways to start it; while a session runs,
/// what it is and how long is left, ticking in place.
function plFocusCard(now) {
  const { data, focus, skin, plannedOn } = plannerState();
  const card = el('div', 'pk-pl-card focus');
  const h = el('div', 'head'); h.append(plIcon('tabFocus', 26), el('b', '', 'Focus'));
  card.append(h);
  const press = (node, fn) => {
    node.setAttribute('role', 'button'); node.tabIndex = 0;
    node.addEventListener('click', fn);
    node.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); fn(e); } });
  };
  if (focus.state === 'running') {
    card.append(el('div', 'big', focus.title ?? 'Focus'));
    const line = el('div', 'foot', ''); line.append(el('span', 'pk-w-clock', clockLeft()), ' left · ends at ', new Date(focus.endsAt).toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' }));
    card.append(line);
    const actions = el('div', 'actions');
    const url = safeURL(focus.url);
    if (url) { const a = el('a', 'start', 'Open'); a.href = url; actions.append(a); }
    const stop = el('span', 'ghost', 'Stop');
    press(stop, (e) => { if (e.isTrusted && alive()) chrome.runtime.sendMessage({ type: 'focus-stop' }); });
    actions.append(stop);
    card.append(actions);
    return card;
  }
  if (focus.state === 'done') {
    card.append(el('div', 'big', `${focus.durationMin} minutes. Nice.`));
    card.append(el('div', 'foot', `+${focus.durationMin} coins on your phone.`));
    const actions = el('div', 'actions');
    const ok = el('span', 'ghost', 'Done');
    press(ok, (e) => { if (e.isTrusted && alive()) chrome.runtime.sendMessage({ type: 'focus-clear' }); });
    actions.append(ok);
    card.append(actions);
    return card;
  }
  const b = buckets(data.tasks, now, plannedOn);
  const next = [...b.overdue, ...b.today, ...b.week].find((t) => t.dueAt) ?? null;
  if (!next) { card.append(el('div', 'quiet', 'Nothing waiting. Rest counts too.')); return card; }
  card.append(el('div', 'big', next.title));
  card.append(el('div', 'foot', `${shortCourse(next.courseName)} · ${dueLabel(next, now).replace(' · still counts', '')}`));
  const actions = el('div', 'actions');
  const go = el('span', 'start', `Focus ${skin.focusMinutes} min`);
  press(go, (e) => {
    if (!e.isTrusted || !alive()) return;
    chrome.runtime.sendMessage({ type: 'focus-start', taskId: next.id, title: next.title, url: next.url, minutes: skin.focusMinutes });
  });
  actions.append(go);
  const url = safeURL(next.url);
  if (url) { const a = el('a', 'ghost', 'Open'); a.href = url; actions.append(a); }
  card.append(actions);
  const lens = el('div', 'lens');
  for (const m of [15, 25, 45]) {
    const chip = el('span', skin.focusMinutes === m ? 'on' : '', `${m}`);
    press(chip, (e) => { if (!e.isTrusted || !alive()) return; chrome.storage.local.get('skin').then(({ skin: s }) => chrome.storage.local.set({ skin: { ...(s ?? {}), focusMinutes: m } })); });
    lens.append(chip);
  }
  lens.prepend(el('span', 'lead', 'minutes'));
  card.append(lens);
  return card;
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

if (typeof module !== 'undefined') {
  module.exports = { plIconFor, PLANNER_ICONS };
}

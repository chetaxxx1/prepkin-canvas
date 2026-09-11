// The side panel: what is due, beside whatever you are actually doing.
//
// The most-asked-for thing on the competitor's own board that they never built:
// clicking the toolbar icon took you to Canvas, which every student already has
// bookmarked. This is the list on its own, with no Canvas tab open at all.
//
// It reads what the worker last collected and nothing else. No network call is
// made from this page, and it never writes: everything here is a view.

const LIMIT = 40;

/// The same day helpers the panel and the popup use, so three surfaces cannot
/// disagree about what "today" means.
function planDayOf(key) {
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(String(key ?? ''));
  if (!m) return null;
  const [y, mo, d] = [Number(m[1]), Number(m[2]), Number(m[3])];
  const day = new Date(y, mo - 1, d);
  return day.getFullYear() === y && day.getMonth() === mo - 1 && day.getDate() === d ? day : null;
}

/// Only ever a link Canvas itself handed us, and only over https.
function safeURL(u) {
  try { const url = new URL(String(u)); return url.protocol === 'https:' ? url.href : null; } catch { return null; }
}

/// The same three words the buddy panel uses for the same fact.
function freshness(at) {
  const t = Date.parse(String(at ?? ''));
  if (!Number.isFinite(t)) return 'just now';
  const mins = Math.round((Date.now() - t) / 60000);
  if (mins < 1) return 'just now';
  if (mins < 60) return `${mins} min ago`;
  return `${Math.round(mins / 60)} hr ago`;
}

function el(tag, cls, text) {
  const n = document.createElement(tag);
  if (cls) n.className = cls;
  if (text != null) n.textContent = text;
  return n;
}

/// One row. Titles are other people's text, so every one of these is
/// textContent and never markup.
function row(t, now, overdue) {
  const li = el('li', overdue ? 'overdue' : '');
  const dot = el('i');
  // The course's own Canvas colour, so the eye lands by colour the way it does
  // on the dashboard. Validated here because storage may hold an older shape.
  if (typeof t.colorHex === 'string' && /^#[0-9a-f]{3,8}$/i.test(t.colorHex)) dot.style.background = t.colorHex;
  const body = el('div', 't');
  const title = el('b', '', t.title ?? 'Untitled');
  const href = safeURL(t.url);
  if (href) {
    const a = el('a');
    a.href = href;
    a.target = '_blank';
    a.rel = 'noreferrer';
    a.append(title);
    body.append(a);
  } else {
    body.append(title);
  }
  if (t.courseName) body.append(el('small', '', t.courseName));
  // The headline and the section title already say late work counts.
  li.append(dot, body, el('span', 'w', overdue ? dueLabel(t, now).replace(' · still counts', '') : dueLabel(t, now)));
  return li;
}

function list(title, tasks, now, { overdue = false, empty } = {}) {
  const wrap = document.createDocumentFragment();
  const label = el('p', 'label');
  label.append(el('span', '', title));
  if (tasks.length) label.append(el('em', '', String(tasks.length)));
  wrap.append(label);
  const ul = el('ul');
  if (!tasks.length) ul.append(el('li', 'none', empty));
  else for (const t of tasks.slice(0, LIMIT)) ul.append(row(t, now, overdue));
  wrap.append(ul);
  return wrap;
}

async function draw() {
  const { lastPayload, ownTasks, plans = {}, nicknames = {}, skin = {} } =
    await chrome.storage.local.get(['lastPayload', 'ownTasks', 'plans', 'nicknames', 'skin']);

  const dark = skin.mode === 'auto' ? matchMedia('(prefers-color-scheme: dark)').matches : !!skin.dark;
  document.body.classList.toggle('dark', dark);

  const own = Array.isArray(ownTasks) ? ownTasks : [];
  const tasks = [...(lastPayload?.tasks ?? []), ...own].map((t) => {
    const nick = nicknames[t.courseId];
    return nick ? { ...t, courseName: nick } : t;
  });

  const lists = document.getElementById('lists');
  lists.replaceChildren();

  if (!tasks.length) {
    document.getElementById('say').textContent = 'Nothing here yet';
    document.getElementById('sub').textContent = '';
    lists.append(el('p', 'foot', 'Open your Canvas once and connect it in the Prepkin popup. Your work shows up here.'));
    document.getElementById('foot').textContent = '';
    return;
  }

  const now = new Date();
  const b = buckets(tasks, now, (t) => planDayOf(plans[t.id]));
  const said = voice(b);
  document.getElementById('say').textContent = said.headline;
  document.getElementById('sub').textContent = said.subline;

  lists.append(list('Today', b.today, now, { empty: 'Nothing due today.' }));
  if (b.overdue.length) lists.append(list('Past due', b.overdue, now, { overdue: true }));
  lists.append(list('This week', b.week, now, { empty: 'The rest of the week is clear.' }));
  if (b.missed.length) lists.append(list('Missing', b.missed, now, { overdue: true }));

  document.getElementById('foot').textContent = `Read from your Canvas ${freshness(lastPayload?.at)}.`;
}

draw();
chrome.storage.onChanged.addListener((changes) => {
  if (changes.lastPayload || changes.ownTasks || changes.plans || changes.nicknames || changes.skin) draw();
});
matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => draw());

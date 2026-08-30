// Prepkin Canvas Sync — background service worker (MV3).
//
// Works with any school's Canvas. Nothing is hardcoded: you connect the site
// you are standing on, Chrome asks you to approve that one origin, and the
// extension remembers it. A school on canvas.dartmouth.edu and one on
// school.instructure.com go through exactly the same path.

const SYNC_ALARM = 'prepkin-sync';

// bridge/apply-config.sh writes config.js. Without it the extension still reads
// Canvas; it just has nowhere to send the list.
importScripts('canvas.js');

let bridge = null;
try {
  importScripts('config.js');
  bridge = PREPKIN_BRIDGE;
} catch (e) {
  console.warn('Prepkin: no config.js — run bridge/apply-config.sh');
}

chrome.runtime.onInstalled.addListener(async () => {
  chrome.alarms.create(SYNC_ALARM, { periodInMinutes: 30 });
  await registerAll();
});
// Re-created on every browser start too — creating an alarm that already
// exists is a cheap no-op, and a lost alarm would otherwise stay lost.
chrome.runtime.onStartup.addListener(() => {
  chrome.alarms.create(SYNC_ALARM, { periodInMinutes: 30 });
  registerAll();
});

// MARK: - Putting the skin on a page

/// Content scripts are registered per site at run time rather than declared in
/// the manifest, because the manifest cannot name a school we have not met. A
/// site only gets one after you press Connect and Chrome grants the permission.
async function registerFor(origin) {
  const id = `prepkin-${new URL(origin).hostname}`;
  try { await chrome.scripting.unregisterContentScripts({ ids: [id] }); } catch {}
  try {
    await chrome.scripting.registerContentScripts([{
      id,
      matches: [`${origin}/*`],
      js: ['slime.js', 'content.js'],
      css: ['skin.css'],
      runAt: 'document_end',
    }]);
  } catch (e) {
    console.warn('Prepkin: could not inject into', origin, e);
  }
}

async function unregisterFor(origin) {
  try {
    await chrome.scripting.unregisterContentScripts({ ids: [`prepkin-${new URL(origin).hostname}`] });
  } catch {}
}

async function registerAll() {
  for (const origin of await connectedOrigins()) await registerFor(origin);
}

chrome.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name === SYNC_ALARM) syncAll();
});

// Syncing when you land on a connected Canvas keeps the phone close to current
// without polling anyone's server every minute.
chrome.tabs.onUpdated.addListener(async (_id, info, tab) => {
  if (info.status !== 'complete' || !tab.url) return;
  const origin = originOf(tab.url);
  if (origin && (await connectedOrigins()).includes(origin)) syncNow(origin);
});

chrome.runtime.onMessage.addListener((msg, _sender, sendResponse) => {
  if (msg.type === 'sync-now') {
    (msg.origin ? syncNow(msg.origin) : syncAll()).then(sendResponse);
    return true; // keep the message channel open for the async reply
  }
  if (msg.type === 'verify-canvas') {
    isCanvas(msg.origin).then(sendResponse);
    return true;
  }
  if (msg.type === 'register') {
    registerFor(msg.origin).then(() => sendResponse({ ok: true }));
    return true;
  }
  if (msg.type === 'forget') {
    forgetOrigin(msg.origin).then(sendResponse);
    return true;
  }
});

/// Disconnecting a school also takes its already-synced work back off the phone
/// and the page overlay — revoking the permission alone would leave the last
/// pushed list lingering forever.
async function forgetOrigin(origin) {
  await unregisterFor(origin);
  try { await chrome.permissions.remove({ origins: [`${origin}/*`] }); } catch {}
  const { origins = [] } = await chrome.storage.local.get('origins');
  await chrome.storage.local.set({ origins: origins.filter((o) => o !== origin) });
  const { lastResults = {} } = await chrome.storage.local.get('lastResults');
  delete lastResults[origin];
  await chrome.storage.local.set({ lastResults });
  return send({});
}

// MARK: - Origins

function originOf(url) {
  try {
    const u = new URL(url);
    return u.protocol === 'https:' ? u.origin : null;
  } catch {
    return null;
  }
}

async function connectedOrigins() {
  const { origins = [] } = await chrome.storage.local.get('origins');
  // Chrome can revoke a permission behind our back, so trust it, not our list.
  const live = [];
  for (const origin of origins) {
    if (await chrome.permissions.contains({ origins: [`${origin}/*`] })) live.push(origin);
  }
  return live;
}

/// Is this actually Canvas, and are you logged in? Asking Canvas beats guessing
/// from the hostname — plenty of schools do not have "canvas" in their domain.
async function isCanvas(origin) {
  try {
    const res = await fetch(`${origin}/api/v1/users/self`, {
      credentials: 'include',
      headers: { Accept: 'application/json' },
    });
    if (res.status === 401 || res.status === 403) {
      return { ok: false, error: 'That is Canvas, but you are logged out.' };
    }
    if (!res.ok) return { ok: false, error: 'That page does not look like Canvas.' };
    const me = await res.json();
    return me && me.id ? { ok: true, name: me.name } : { ok: false, error: 'That page does not look like Canvas.' };
  } catch {
    return { ok: false, error: 'Could not reach that site.' };
  }
}

// MARK: - Syncing

async function syncAll() {
  const origins = await connectedOrigins();
  if (!origins.length) return finish({ ok: false, error: 'No Canvas connected yet.' });
  const reads = await Promise.all(origins.map(async (o) => [o, await readSchool(o)]));
  const fresh = Object.fromEntries(reads.filter(([, r]) => r));
  if (!Object.keys(fresh).length) return finish({ ok: false, error: 'Canvas said no — log in again?' });
  return send(fresh);
}

async function syncNow(origin) {
  const result = await readSchool(origin);
  if (!result) return finish({ ok: false, error: 'Canvas said no — log in again?' });
  return send({ [origin]: result });
}

/// Folds this round's reads into the per-school store and pushes the lot. A
/// school that did not answer this round — an expired login, a flaky network —
/// keeps its last good list rather than vanishing from the phone.
async function send(fresh) {
  const { lastResults = {} } = await chrome.storage.local.get('lastResults');
  const results = {};
  for (const origin of await connectedOrigins()) {
    const r = fresh[origin] ?? lastResults[origin];
    if (r) results[origin] = r;
  }
  const all = Object.values(results);
  const payload = {
    tasks: all.flatMap((r) => r.tasks),
    courses: all.flatMap((r) => r.courses),
  };
  // The page overlay reads lastPayload, so the slime knows what you owe even
  // when the phone is in another room.
  await chrome.storage.local.set({ lastResults: results, lastPayload: payload });
  return finish(await pushToBridge(payload), payload.tasks.length);
}

/// Everything one school knows, in three or so calls: the courses you are in
/// (with their current grade), the colours you picked on the dashboard, and the
/// assignments in each course with your own submission attached.
///
/// The to-do sweep at the end is a safety net — one cheap call that catches
/// anything the per-course pass missed, at the cost of no grade detail.
async function readSchool(origin) {
  const host = new URL(origin).hostname;

  const [rawCourses, rawColors] = await Promise.all([
    getPaged(origin, '/api/v1/courses?enrollment_state=active&include[]=total_scores&per_page=100'),
    getJSON(`${origin}/api/v1/users/self/colors`),
  ]);
  if (rawCourses === null) return null; // logged out, or not Canvas any more

  const courses = mapCourses(rawCourses, rawColors?.custom_colors ?? {});

  const perCourse = await Promise.all(courses.map(async (course) => {
    const raw = await getPaged(
      origin,
      `/api/v1/courses/${course.id}/assignments?include[]=submission&order_by=due_at&per_page=100`
    );
    return raw ? mapAssignments(raw, { host, course }) : [];
  }));

  const rawTodo = await getPaged(origin, '/api/v1/users/self/todo?per_page=100&include[]=ungraded_quizzes');

  return { courses, tasks: merge(perCourse.flat(), rawTodo ? mapTodo(rawTodo, host) : []) };
}

/// One GET with the session cookie already in the browser. No password is ever
/// asked for, stored, or sent anywhere. Returns null rather than throwing, so a
/// single bad endpoint cannot take the whole sync down.
async function getJSON(url) {
  try {
    const res = await fetch(url, {
      credentials: 'include',
      headers: { Accept: 'application/json' },
    });
    return res.ok ? await res.json() : null;
  } catch {
    return null;
  }
}

/// A list endpoint, following Canvas's `Link: rel="next"` paging. A semester's
/// worth of assignments does not fit in one page, and Canvas sorts `due_at`
/// ascending — so stopping at page one would keep the oldest work and silently
/// drop what is actually due this week. Capped so a pathological feed cannot
/// spin forever; a later page failing costs that page, not the ones already read.
const MAX_PAGES = 4;

async function getPaged(origin, path) {
  let url = `${origin}${path}`;
  let out = null;
  for (let page = 0; page < MAX_PAGES && url; page += 1) {
    let res;
    try {
      res = await fetch(url, { credentials: 'include', headers: { Accept: 'application/json' } });
    } catch { return out; }
    if (!res.ok) return out;
    const body = await res.json().catch(() => null);
    if (!Array.isArray(body)) return out ?? body;
    out = (out ?? []).concat(body);
    url = nextLink(res.headers.get('Link'));
  }
  return out;
}

function nextLink(header) {
  if (!header) return null;
  for (const part of header.split(',')) {
    const m = part.match(/<([^>]+)>\s*;\s*rel="next"/);
    if (m) return m[1];
  }
  return null;
}

/// Hands the list to the bridge, keyed by the pairing code and nothing else —
/// no name, no account, no Canvas credentials.
async function pushToBridge(payload) {
  const { pairingCode } = await chrome.storage.local.get('pairingCode');
  if (!pairingCode) return { ok: false, error: 'No pairing code yet.' };
  if (!bridge) return { ok: false, error: 'Extension is missing config.js.' };

  try {
    const res = await fetch(`${bridge.url}/rest/v1/rpc/push_todo`, {
      method: 'POST',
      headers: {
        apikey: bridge.key,
        Authorization: `Bearer ${bridge.key}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ p_code: pairingCode, p_todo: payload }),
    });
    return res.ok ? { ok: true } : { ok: false, error: `Bridge returned ${res.status}.` };
  } catch {
    return { ok: false, error: 'Could not reach the bridge.' };
  }
}

async function finish(result, count) {
  const status = { ...result, count, at: new Date().toISOString() };
  await chrome.storage.local.set({ lastSync: status });
  chrome.action.setBadgeText({ text: count ? String(count) : '' });
  return status;
}

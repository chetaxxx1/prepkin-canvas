// Prepkin for Canvas — background service worker (MV3).
//
// Works with any school's Canvas. Nothing is hardcoded: you connect the site
// you are standing on, Chrome asks you to approve that one origin, and the
// extension remembers it. A school on canvas.dartmouth.edu and one on
// school.instructure.com go through exactly the same path.

const SYNC_ALARM = 'prepkin-sync';
const UPDATE_WAITING = 'updateWaiting';
const BOOT_SCRIPTS = ['receipt.js', 'themes.js', 'art/manifest.js', 'looks.js', 'boot.js'];
const CONTENT_SCRIPTS = ['podnames.js', 'canvas.js', 'selectors.js', 'day.js', 'content.js'];

/// No request may hang a sync. A school behind a dead SSO hop, or a bridge that
/// accepts the connection and never answers, used to stall syncAll forever —
/// and with it every other school. Canvas answers a page in well under this.
const FETCH_TIMEOUT_MS = 20_000;
const withTimeout = (init = {}) => ({ ...init, signal: AbortSignal.timeout(FETCH_TIMEOUT_MS) });

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

chrome.runtime.onInstalled.addListener(async ({ reason }) => {
  chrome.alarms.create(SYNC_ALARM, { periodInMinutes: 30 });
  await chrome.storage.local.remove(UPDATE_WAITING);
  await registerAll();
  if (reason === 'update') await reinjectOpenTabs();
});
// Re-created on every browser start too — creating an alarm that already
// exists is a cheap no-op, and a lost alarm would otherwise stay lost.
chrome.runtime.onStartup.addListener(() => {
  chrome.alarms.create(SYNC_ALARM, { periodInMinutes: 30 });
  registerAll();
});

chrome.runtime.onUpdateAvailable.addListener(async () => {
  const { focus } = await chrome.storage.local.get('focus');
  if (focus?.state === 'running') {
    await chrome.storage.local.set({ [UPDATE_WAITING]: true });
    return;
  }
  chrome.runtime.reload();
});

// MARK: - Putting the skin on a page

/// Content scripts are registered per site at run time rather than declared in
/// the manifest, because the manifest cannot name a school we have not met. A
/// site only gets one after you press Connect and Chrome grants the permission.
async function registerFor(origin) {
  const id = `prepkin-${new URL(origin).hostname}`;
  try { await chrome.scripting.unregisterContentScripts({ ids: [id, `${id}-boot`] }); } catch {}
  try {
    await chrome.scripting.registerContentScripts([
      {
        // Before first paint: the stylesheet and the classes it hangs off, so a
        // dark paper never flashes white and the school's theme never paints first.
        id: `${id}-boot`,
        matches: [`${origin}/*`],
        js: BOOT_SCRIPTS,
        css: ['skin.css'],
        runAt: 'document_start',
      },
      {
        id,
        matches: [`${origin}/*`],
        // canvas.js rides along because the what-if screen does its arithmetic with
        // the same requiredScore() the worker uses. One source of truth beats two.
        // receipt.js, themes.js, art/manifest.js and looks.js already ran at
        // document_start (the boot set) in this same world; naming them twice
        // redeclared their constants on every page.
        js: CONTENT_SCRIPTS,
        runAt: 'document_end',
      },
    ]);
  } catch (e) {
    console.warn('Prepkin: could not inject into', origin, e);
  }
}

async function unregisterFor(origin) {
  const id = `prepkin-${new URL(origin).hostname}`;
  try {
    await chrome.scripting.unregisterContentScripts({ ids: [id, `${id}-boot`] });
  } catch {}
}

async function registerAll() {
  for (const origin of await connectedOrigins()) await registerFor(origin);
}

/// Put both page entry points back into tabs that were already open when an
/// update landed. Their supporting scripts are already in the isolated world.
async function reinjectOpenTabs() {
  const origins = new Set(await connectedOrigins());
  const tabs = await chrome.tabs.query({});
  for (const tab of tabs) {
    if (tab.id == null || !origins.has(originOf(tab.url ?? ''))) continue;
    try {
      await chrome.scripting.executeScript({ target: { tabId: tab.id }, files: BOOT_SCRIPTS });
      await chrome.scripting.executeScript({ target: { tabId: tab.id }, files: CONTENT_SCRIPTS });
    } catch (e) {
      console.warn('Prepkin: could not put the page back on', tab.url, e);
    }
  }
}

chrome.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name === SYNC_ALARM) syncAll();
  if (alarm.name === FOCUS_ALARM) focusDone();
});

// Syncing when you land on a connected Canvas keeps the phone close to current
// without polling anyone's server every minute.
//
// Rate-limited per school, because one sync is not one request: it is the course
// list, the colours, then two calls per course, each paged. Clicking around
// Canvas for a minute would otherwise fire hundreds of credentialed requests at
// a school's server, which is indistinguishable from scraping and is exactly
// what gets an extension blocked district-wide.
const TAB_SYNC_GAP_MS = 10 * 60_000;

async function syncOnVisit(origin) {
  const { visitSyncs = {} } = await chrome.storage.local.get('visitSyncs');
  const last = visitSyncs[origin] ?? 0;
  if (Date.now() - last < TAB_SYNC_GAP_MS) return;
  await chrome.storage.local.set({ visitSyncs: { ...visitSyncs, [origin]: Date.now() } });
  syncNow(origin);
}

chrome.tabs.onUpdated.addListener(async (_id, info, tab) => {
  if (info.status !== 'complete' || !tab.url) return;
  const origin = originOf(tab.url);
  if (origin && (await connectedOrigins()).includes(origin)) syncOnVisit(origin);
});

// MARK: - Focus timer
//
// The countdown lives here, not in the page: a content script dies on every
// navigation, and a timer that resets when you open your reading is useless.

const FOCUS_ALARM = 'prepkin-focus';

async function focusStart({ taskId, title, url, minutes }) {
  const durationMin = [15, 25, 45].includes(minutes) ? minutes : 25;
  const focus = {
    state: 'running', taskId, title, url,
    durationMin, endsAt: Date.now() + durationMin * 60_000,
  };
  await chrome.storage.local.set({ focus });
  chrome.alarms.create(FOCUS_ALARM, { when: focus.endsAt });
  return focus;
}

/// Apply a waiting update once the timer no longer owns the session.
async function reloadAfterFocus() {
  const { focus, [UPDATE_WAITING]: waiting } = await chrome.storage.local.get(['focus', UPDATE_WAITING]);
  if (!waiting || focus?.state === 'running') return false;
  await chrome.storage.local.remove(UPDATE_WAITING);
  chrome.runtime.reload();
  return true;
}

/// Five more minutes on a running session. Time only ever goes up.
async function focusExtend() {
  const { focus } = await chrome.storage.local.get('focus');
  if (focus?.state !== 'running') return focus;
  const next = { ...focus, durationMin: focus.durationMin + 5, endsAt: focus.endsAt + 5 * 60_000 };
  await chrome.storage.local.set({ focus: next });
  chrome.alarms.create(FOCUS_ALARM, { when: next.endsAt });
  return next;
}

/// Giving up costs nothing — no coins lost, no record kept, no nagging.
async function focusStop() {
  chrome.alarms.clear(FOCUS_ALARM);
  await chrome.storage.local.set({ focus: { state: 'idle' } });
  await reloadAfterFocus();
}

async function focusDone() {
  const { focus } = await chrome.storage.local.get('focus');
  if (focus?.state !== 'running') return;
  await chrome.storage.local.set({ focus: { ...focus, state: 'done' } });
  await queueRequest({ kind: 'focus', taskId: focus.taskId, minutes: focus.durationMin });
  if (!(await reloadAfterFocus())) syncAll();
}

/// Which senders may ask for what.
///
/// `setup` messages change what the extension is connected to, so only our own
/// pages (the popup) may send them. `page` messages come from the buddy panel,
/// so they must arrive from a tab on a school you actually connected — a page
/// can dispatch a synthetic click at the panel's own buttons, and without this
/// any connected site could drive the timer or file spend requests.
const SETUP_MESSAGES = ['register', 'forget', 'sync-now', 'verify-canvas', 'pair'];

async function senderMayAsk(type, sender) {
  if (!sender || sender.id !== chrome.runtime.id) return false;
  if (SETUP_MESSAGES.includes(type)) {
    return !sender.tab && (sender.url ?? '').startsWith(chrome.runtime.getURL(''));
  }
  // Only the page itself, never a frame inside it: an embedded tool on the same
  // origin is somebody else's code.
  if (!sender.tab || sender.frameId !== 0) return false;
  const origin = originOf(sender.url ?? '');
  return !!origin && (await connectedOrigins()).includes(origin);
}

chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => {
  if (!msg || typeof msg.type !== 'string') return;
  // The gate is async, so every branch below answers through this one promise.
  senderMayAsk(msg.type, sender)
    .then((ok) => {
      if (!ok) return sendResponse({ ok: false, error: 'Not allowed.' });
      handleMessage(msg, sendResponse);
    })
    .catch(() => sendResponse({ ok: false, error: 'Not allowed.' }));
  return true; // keep the channel open for the async reply
});

function handleMessage(msg, sendResponse) {
  if (msg.type === 'focus-start') {
    focusStart(msg).then(sendResponse);
    return true;
  }
  if (msg.type === 'focus-extend') {
    focusExtend().then(sendResponse);
    return true;
  }
  if (msg.type === 'focus-stop' || msg.type === 'focus-clear') {
    focusStop().then(() => sendResponse({ ok: true }));
    return true;
  }
  if (msg.type === 'spend') {
    queueRequest({ kind: 'look', lookId: msg.lookId, price: msg.price })
      .then(() => sendResponse({ ok: true }));
    return true;
  }
  if (msg.type === 'sync-now') {
    // Deliberately not rate-limited: this is the button a student presses when
    // the phone looks stale, and making it do nothing would be worse than the
    // requests it costs.
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
  if (msg.type === 'pair') {
    bindWriter(msg.code).then(sendResponse);
    return true;
  }
}

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
    const res = await fetch(`${origin}/api/v1/users/self`, withTimeout({
      credentials: 'include',
      headers: { Accept: 'application/json' },
    }));
    if (res.status === 401 || res.status === 403) {
      return { ok: false, error: 'That is Canvas, but you are logged out.' };
    }
    if (!res.ok) return { ok: false, error: 'That page does not look like Canvas.' };
    const me = await res.json().catch(() => null);
    // Any site can serve `{"id":1}`. Canvas's own user object always carries the
    // name trio, and its course list is always an array — two signals a site
    // pretending to be Canvas has to fake on purpose, not by accident.
    const looksLikeUser = me && me.id != null
      && (typeof me.sortable_name === 'string' || typeof me.short_name === 'string');
    if (!looksLikeUser) return { ok: false, error: 'That page does not look like Canvas.' };
    const courses = await getJSON(`${origin}/api/v1/courses?per_page=1`);
    if (!Array.isArray(courses)) return { ok: false, error: 'That page does not look like Canvas.' };
    return { ok: true, name: me.name };
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
  const { requests = [] } = await chrome.storage.local.get('requests');
  const payload = {
    tasks: all.flatMap((r) => r.tasks),
    courses: all.flatMap((r) => r.courses),
    graded: Object.assign({}, ...all.map((r) => r.graded ?? {})),
    weights: Object.assign({}, ...all.map((r) => r.weights ?? {})),
    // Coins the phone still owes or is owed: finished focus sessions, and looks
    // worn here. The app's ledger is the truth; this is only the request.
    requests,
    at: new Date().toISOString(),
  };
  // The page overlay reads lastPayload, so the buddy knows what you owe even
  // when the phone is in another room.
  await chrome.storage.local.set({ lastResults: results, lastPayload: payload });
  // The panel reads grades from lastPayload, on this machine. The bridge gets a
  // narrower copy: per-item scores and group weights never leave the laptop,
  // because nothing on the phone reads them and they are the most identifying
  // thing here.
  const { graded, weights, ...rest } = payload;
  // Old missing work stays on this machine too. The phone's list is today; a
  // term of three-week-old zeros would fill it with work nobody is doing
  // tonight, and it is the panel's Missing list that they belong to.
  const staleMissing = Date.now() - DAYS_OVERDUE * 86_400_000;
  const forBridge = { ...rest, tasks: rest.tasks.filter((t) => {
    if (!t.missing || !t.dueAt) return true;
    const due = Date.parse(t.dueAt);
    return !Number.isFinite(due) || due >= staleMissing;
  }) };
  const pushed = await pushToBridge(forBridge);
  // Requests deliberately stay queued. A push the bridge accepted only means the
  // row was written — the phone may not read it before the next push overwrites
  // it, and clearing here is how finished focus sessions used to vanish. They
  // are retired in pullWallet(), once the phone says it actually paid them.
  await pullWallet();
  return finish(pushed, payload.tasks.length);
}

/// Trades the code the student typed for this laptop's write token.
///
/// The code is only good for the few minutes after the app shows it, and only
/// the first laptop in gets a token — so a stranger who guesses a code later
/// can neither read the list nor overwrite it. The token is what every push
/// uses from then on; the code is never sent again.
async function bindWriter(code) {
  if (!bridge) return { ok: false, error: 'Extension is missing config.js.' };
  try {
    const res = await fetch(`${bridge.url}/rest/v1/rpc/bind_writer`, withTimeout({
      method: 'POST',
      headers: {
        apikey: bridge.key,
        Authorization: `Bearer ${bridge.key}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ p_code: code }),
    }));
    // 404 here is the bridge itself, not the code: the pairing functions are
    // missing, which means bridge/schema.sql was never run on this project.
    if (res.status === 404) return { ok: false, error: 'Prepkin needs an update before this can pair.' };
    if (!res.ok) return { ok: false, error: 'That code is not one the app is offering.' };
    const token = await res.json().catch(() => null);
    if (typeof token !== 'string' || !token) {
      return {
        ok: false,
        error: 'That code has expired or is already paired to another laptop. Tap New code in the app.',
      };
    }
    await chrome.storage.local.set({ pairingCode: code, writerToken: token });
    return { ok: true };
  } catch {
    return { ok: false, error: 'Could not reach Prepkin.' };
  }
}

/// The phone's side of the bridge: the coin balance and which looks are owned.
/// Absent until the app publishes it — the shop says so rather than inventing
/// a number.
async function pullWallet() {
  const { pairingCode, writerToken } = await chrome.storage.local.get(['pairingCode', 'writerToken']);
  if (!pairingCode || !writerToken || !bridge) return;
  try {
    const res = await fetch(`${bridge.url}/rest/v1/rpc/fetch_state`, withTimeout({
      method: 'POST',
      headers: {
        apikey: bridge.key,
        Authorization: `Bearer ${bridge.key}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ p_code: pairingCode, p_token: writerToken }),
    }));
    if (!res.ok) return;
    const state = await res.json();
    if (!state || typeof state.coins !== 'number') return;
    const { wallet = {} } = await chrome.storage.local.get('wallet');
    await chrome.storage.local.set({
      wallet: {
        ...wallet,
        coins: state.coins,
        owned: Array.isArray(state.owned) ? state.owned : (wallet.owned ?? ['classic']),
        // The phone's league, or null: the panel says "link your phone" then.
        league: state.league && typeof state.league.tier === 'number' ? state.league : null,
      },
    });
    // Everything the phone has paid for can stop being re-sent. Anything newer
    // stays queued until it says otherwise.
    const paidUpTo = Date.parse(state.requestsAppliedAt ?? '');
    if (Number.isFinite(paidUpTo)) {
      await changeRequests((requests) => {
        const still = requests.filter((r) => !(Date.parse(r.at) <= paidUpTo));
        return still.length === requests.length ? requests : still;
      });
    }
  } catch {
    // A bridge that is down is not worth a broken panel.
  }
}

/// The request queue is read-modify-write in storage, and two writers at once —
/// a focus session ending while the wallet pull retires paid ones — would drop
/// whichever wrote first. Every change goes through this one chain.
let requestsLock = Promise.resolve();
function changeRequests(change) {
  const run = requestsLock.then(async () => {
    const { requests = [] } = await chrome.storage.local.get('requests');
    const next = change(requests);
    if (next !== requests) await chrome.storage.local.set({ requests: next });
  });
  requestsLock = run.catch(() => {});
  return run;
}

/// Queued for the next sync rather than sent on the spot, so a click never
/// waits on the network and a flaky connection cannot drop the request.
function queueRequest(request) {
  return changeRequests((requests) =>
    [...requests, { ...request, at: new Date().toISOString() }].slice(-50));
}

/// Everything one school knows, in three or so calls: the courses you are in
/// (with their current grade), the colours you picked on the dashboard, and the
/// assignments in each course with your own submission attached.
///
/// The to-do sweep at the end is a safety net — one cheap call that catches
/// anything the per-course pass missed, at the cost of no grade detail.
async function readSchool(origin) {
  const host = new URL(origin).hostname;
  // What this school looked like last time, so one course that fails to load —
  // a 429 from a throttling school, a flaky page — keeps its last good work
  // rather than vanishing from the phone until the next sync.
  const { lastResults = {} } = await chrome.storage.local.get('lastResults');
  const previous = lastResults[origin] ?? null;

  const [rawCourses, rawColors] = await Promise.all([
    getPaged(origin, '/api/v1/courses?enrollment_state=active&include[]=total_scores&include[]=term&per_page=100'),
    getJSON(`${origin}/api/v1/users/self/colors`),
  ]);
  if (rawCourses === null) return null; // logged out, or not Canvas any more

  const courses = mapCourses(rawCourses, rawColors?.custom_colors ?? {});

  const graded = {};
  const weights = {};
  const examined = new Set();
  const perCourse = await Promise.all(courses.map(async (course) => {
    const raw = await getPaged(
      origin,
      `/api/v1/courses/${course.id}/assignments?include[]=submission&include[]=score_statistics&order_by=due_at&per_page=100`
    );
    if (!raw) {
      if (!previous) return [];
      graded[course.id] = previous.graded?.[course.id] ?? [];
      weights[course.id] = previous.weights?.[course.id] ?? null;
      const kept = previous.tasks.filter((t) => t.courseId === course.id);
      for (const t of kept) examined.add(t.id);
      return kept;
    }
    examinedIds(raw, host, examined);
    // The same rows feed the task list and the grade sparkline — one fetch read
    // two ways, rather than asking Canvas twice for the same assignments.
    graded[course.id] = mapGraded(raw, { host });
    const rawGroups = await getPaged(origin, `/api/v1/courses/${course.id}/assignment_groups?per_page=50`);
    weights[course.id] = mapWeights(rawGroups, { weighted: course.weighted !== false });
    return mapAssignments(raw, { host, course });
  }));

  const rawTodo = await getPaged(origin, '/api/v1/users/self/todo?per_page=100&include[]=ungraded_quizzes');
  // The sweep sees every enrolment, so hold it to the same courses the term
  // filter kept — otherwise a concluded class returns through the back door.
  const courseIds = new Set(courses.map((c) => c.id));

  return {
    courses,
    graded,
    weights,
    tasks: merge(perCourse.flat(), rawTodo ? mapTodo(rawTodo, host, Date.now(), courseIds) : [], examined),
  };
}

/// One GET with the session cookie already in the browser. No password is ever
/// asked for, stored, or sent anywhere. Returns null rather than throwing, so a
/// single bad endpoint cannot take the whole sync down.
async function getJSON(url) {
  try {
    const res = await fetch(url, withTimeout({
      credentials: 'include',
      headers: { Accept: 'application/json' },
    }));
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
      res = await fetch(url, withTimeout({ credentials: 'include', headers: { Accept: 'application/json' } }));
    } catch { return out; }
    if (!res.ok) return out;
    const body = await res.json().catch(() => null);
    if (!Array.isArray(body)) return out ?? body;
    out = (out ?? []).concat(body);
    url = nextLink(res.headers.get('Link'), origin);
  }
  return out;
}

/// Hands the list to the bridge, keyed by the pairing code and nothing else —
/// no name, no account, no Canvas credentials.
async function pushToBridge(payload) {
  const { pairingCode, writerToken } = await chrome.storage.local.get(['pairingCode', 'writerToken']);
  if (!pairingCode) return { ok: false, error: 'No pairing code yet.' };
  if (!writerToken) return { ok: false, error: 'Not paired yet — paste the code from the app.' };
  if (!bridge) return { ok: false, error: 'Extension is missing config.js.' };

  try {
    const res = await fetch(`${bridge.url}/rest/v1/rpc/push_todo`, withTimeout({
      method: 'POST',
      headers: {
        apikey: bridge.key,
        Authorization: `Bearer ${bridge.key}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ p_code: pairingCode, p_token: writerToken, p_todo: payload }),
    }));
    if (res.ok) return { ok: true };
    // The bridge raises for two different reasons and answers 400 to both, so
    // the message is what tells them apart. Only a dead pairing loses the
    // token; a list too big to send is an error to show, not a reason to
    // make the student pair again.
    const message = String((await res.json().catch(() => null))?.message ?? '');
    if (message.includes('too large')) {
      return { ok: false, error: 'Too much to send. Disconnect a school you are done with, then Check again.' };
    }
    // The phone unpaired, or the row expired. Say so plainly and drop the dead
    // token, so the popup asks for a fresh code instead of retrying forever.
    if (res.status === 404 || (res.status === 400 && message.includes('not paired'))) {
      await chrome.storage.local.remove('writerToken');
      return { ok: false, error: 'Your phone unpaired this laptop. Tap New code in the app and paste it here.' };
    }
    return { ok: false, error: `Prepkin returned ${res.status}.` };
  } catch {
    return { ok: false, error: 'Could not reach Prepkin.' };
  }
}

async function finish(result, count) {
  const status = { ...result, count, at: new Date().toISOString() };
  await chrome.storage.local.set({ lastSync: status });
  chrome.action.setBadgeText({ text: count ? String(count) : '' });
  return status;
}

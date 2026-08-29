// Prepkin Canvas Sync — background service worker (MV3).
// Fetches the student's to-do list from Canvas's own REST API using the
// logged-in session (no password, no HTML scraping), stores it locally.
// TODO (M2): push `todo` to the pairing bridge so the iOS app can pull it.

const SYNC_ALARM = 'prepkin-sync';

chrome.runtime.onMessage.addListener((msg) => {
  if (msg.type === 'canvas-detected') {
    chrome.storage.local.set({ canvasOrigin: msg.origin });
    syncNow(msg.origin);
    // Re-sync every 30 min while the browser is open.
    chrome.alarms.create(SYNC_ALARM, { periodInMinutes: 30 });
  }
});

chrome.alarms.onAlarm.addListener(async (alarm) => {
  if (alarm.name !== SYNC_ALARM) return;
  const { canvasOrigin } = await chrome.storage.local.get('canvasOrigin');
  if (canvasOrigin) syncNow(canvasOrigin);
});

async function syncNow(origin) {
  try {
    const res = await fetch(`${origin}/api/v1/users/self/todo?per_page=50`, {
      credentials: 'include',
      headers: { Accept: 'application/json' },
    });
    if (!res.ok) return; // session expired or not a student account

    const raw = await res.json();
    const todo = raw
      .filter((item) => item.assignment)
      .map((item) => ({
        id: `c-${item.assignment.id}`,
        title: item.assignment.name,
        courseName: item.context_name ?? '',
        dueAt: item.assignment.due_at, // ISO 8601 or null
      }));

    await chrome.storage.local.set({ todo, syncedAt: new Date().toISOString() });
    chrome.action.setBadgeText({ text: String(todo.length || '') });

    // TODO (M2): POST { pairingCode, todo } to the bridge (e.g. Supabase).
  } catch (e) {
    console.warn('Prepkin sync failed', e);
  }
}

# Prepkin Canvas Sync — Chrome extension

Reads your Canvas to-do list with the session already in your browser, and pushes
it to the bridge so the iPhone app can pick it up. No password is asked for,
stored, or sent anywhere.

## Works with any school

Nothing is hardcoded. Canvas lives on `*.instructure.com` for some schools and on
a custom domain for others (`canvas.dartmouth.edu`, `canvas.myschool.org`), so the
extension asks Chrome for one site at a time:

1. Open your Canvas and log in.
2. Click the Prepkin icon → **Connect &lt;your canvas host&gt;**.
3. Chrome asks you to approve that one site. Approve it.
4. It checks the site really is Canvas by calling `/api/v1/users/self`, and drops
   the permission again if it isn't.

Connect as many schools as you like — the popup lists them, and *remove* revokes
the permission. Assignment ids are prefixed with the host, so two schools can't
collide.

## Setup

1. Run `../bridge/apply-config.sh` once, so `config.js` exists. Without it the
   extension can read Canvas but has nowhere to send the list.
2. `chrome://extensions` → Developer mode → **Load unpacked** → this folder.
3. Open the app, tap the sliders on Today, and copy the pairing code.
4. Paste it into the popup → **Save and sync**.

## When it syncs

- When you finish loading a page on a connected Canvas.
- Every 30 minutes while Chrome is open.
- Whenever you press **Sync now**.

## Permissions, and why

| Permission | Why |
|---|---|
| `activeTab` | Read the address of the tab you clicked from, so *Connect* knows which site you mean. |
| `optional_host_permissions: https://*/*` | Nothing is granted up front. Chrome asks per site, and only when you press *Connect*. |
| `https://*.supabase.co/*` | Push the list to the bridge. |
| `storage` | Remember your pairing code and connected sites. |
| `alarms` | The 30-minute re-sync. |

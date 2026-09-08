# Reviewer notes

## Chrome Web Store reviewer

Prepkin for Canvas quiets the Canvas page you are already on, shows your day in a buddy panel, and sends your coursework list and course grades to your own phone.

The extension does nothing until the student connects a Canvas site they are already logged in to.

### How to see it work

1. Install the extension and open the popup.
2. Sign in to any Canvas site in Chrome (`https://<school>.instructure.com`, or your school's own Canvas host).
3. On that tab, open the popup and press Connect. Chrome will ask you to approve that one site.
4. After you approve, reload Canvas. The quiet look and the buddy panel appear on the page.

A free Canvas Free-for-Teacher account no longer exists. A reviewer without Canvas access will see only the popup's connect screen.

### Permissions

- **storage** — Remembers the schools you connected, your pairing with the phone app, and where the focus timer left off.
- **alarms** — Wakes every 30 minutes while Chrome is open to refresh your coursework list, and runs the focus timer across page changes.
- **activeTab** — Reads the address of the tab you clicked the icon on, so Connect knows which school you mean.
- **scripting** — Puts the buddy panel and the quiet Canvas look onto pages at schools you connected.
- **Host permission `https://*.supabase.co/*`** — Sends your coursework list and course grades to Prepkin's server so your own phone can show them.
- **Optional host permission `https://*/*`** — Asks Chrome for one school at a time when you press Connect. Nothing is granted until you approve that one site.

Pairing with the phone is optional. The quiet look and buddy panel work on Canvas without it.

## App Store reviewer

The iPhone app works fully with no account and no Chrome extension.

Without pairing, you see sample tasks and the note: "This build is not connected to Canvas, so the tasks here are sample data."

There is no login. Open the app and use Today right away.

The pairing code screen is reachable from the sliders on Today.

There are no purchases in this build.

Contact: support@prepkin.com

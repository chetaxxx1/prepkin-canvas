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
2. Run `../bridge/schema.sql` in the Supabase SQL editor. It needs `pgcrypto`
   and `pg_cron` enabled under Database → Extensions.
3. `chrome://extensions` → Developer mode → **Load unpacked** → this folder.
4. Open the app, tap the sliders on Today, and copy the pairing code.
5. Paste it into the popup → **Save and sync**.

To build the zip for the store, run `../bridge/package.sh`. It refuses to
package a tree with failing tests, a missing `config.js`, or no icons.

### The code is only good for a few minutes

Pairing trades the code for a long random token, once. The phone gets one when
it makes the code; the first laptop to paste the code gets the other. After
that, the code opens nothing — reading the list and writing to it both need a
token, and only the SHA-256 of each is stored.

That means **the code cannot be reused**. Pairing a second laptop, or the same
laptop after reinstalling, needs a fresh code from the app. This is deliberate:
the old design let anyone who learned a code read a student's coursework and
overwrite their task list.

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
| `storage` | Remember your pairing token and connected sites. |
| `alarms` | The 30-minute re-sync. |

## Quiet Canvas: the receipt

The page skin is subtractive. It takes duplicated or dead things off a Canvas
page, fixes a few things Canvas gets wrong, and hands the student a receipt:
the popup lists every change on the page in front of them — **Taken off**,
**Fixed**, **Added** — with one **Put back** per row, remembered forever, and a
**Show me** that outlines each change on the page for a few seconds. The worst
case is Canvas, unchanged: every rule hangs off a class on `<html>`, no inline
property is ever written, and a rule whose hook is missing simply is not on the
receipt.

What it does today (`extension/receipt.js` is the list, `extension/selectors.js`
names every Canvas selector it uses):

- The page becomes one of twelve **papers** (Newsprint, Manila, Bond, Vellum,
  Rose, Lavender, Sage, Sky; and Carbon, Blueprint, Ink, Moss for dark), each
  printed with its measured body-text contrast. A Look picks a light paper and
  a dark one. Dark is free and always will be, and Auto follows the OS.
- The course-colour band on a dashboard card is 8px, not 146; its opacity (a
  student's accessibility setting) is never touched, and the course colour stays.
- One To Do list where Canvas shows two; Coming Up shows every row; the header
  logo goes when the same mark is also in the sidebar.
- Modules: the module header stays at the top while you scroll, and due dates
  line up in one right-aligned column.
- Four low-use course tabs (Files, Outcomes, Conferences, Collaborations) are
  dimmed, never hidden or reordered.
- In dark: text pasted from Word in black ink is made readable, and a frame
  from another company gets a seam and a slight veil.
- The extension's own additions — the buddy and the next-due line on each
  card — are on the receipt too, with the same one click off.

What it refuses: any property on a button (the submit button is always the
school's own), `font-family`, shadows, hover lifts, red, the flash-error bar,
the skip link, the school's sidebar logo, the login page, and any selector
containing an InstUI hash. It switches itself off entirely, and says so in the
popup, when the school has High Contrast on, when the OS forces colours, on a
New Quizzes page, and on the widget dashboard.

## What the buddy panel does

Click the slime, bottom-right of any connected Canvas page.

- **Today / This week / Overdue.** "This week" opens a day-by-day planner with a
  seven-dot week strip. Overdue work is amber and says "still counts" — never red,
  never a scold.
- **Next up.** The nearest deadline, with a Start link into Canvas and a focus
  timer (15/25/45 minutes). The countdown lives in the service worker, so it
  survives navigating around Canvas. Giving up costs nothing.
- **Grades.** Tap a course to expand: a sparkline of every graded item, the three
  most recent scores, and a what-if calculator ("what do I need on the final?").
  Weights come from Canvas when the course publishes them; when it does not, the
  panel asks rather than guessing.
- **Today, at the top of the dashboard.** The buddy's line, what is due today,
  what still counts, what is due this week, and the next thing with Start and a
  focus timer. On the receipt, one click off.
- **Themes.** Twelve, each a paper, an accent, a card-header wash and a faint
  texture, all drawn on the laptop. Every ink measured.
- **Next due, on the card.** Every dashboard card of a course you are a student
  in carries one line: what is due next and when, or "still counts" in amber if
  it slipped. Updates on every sync; goes away with the cards toggle.
- **Looks.** A paper pair plus something the buddy wears, earned with coins from
  verified work. On the page a look moves exactly the seven paper tokens —
  type, layout and Canvas's own course colours never change.

Dark mode is a warm charcoal, not a grey filter. The slime never recolours.

## Tests

```bash
npm test              # canvas.js mapping rules and the panel's helpers, no browser
npm run test:e2e      # the real extension in Chromium against a fake Canvas and bridge
npm run test:stress   # slow, dead and throttling schools; races; volume
```

The end-to-end suite lives in `../test/`; `design/CANVAS-TEST-PLAN.md` lists every
scenario it covers and how to set it up on a new Mac.

## Files

| File | Does |
| --- | --- |
| `background.js` | Service worker: syncing, per-site injection, the focus timer |
| `canvas.js` | Canvas's API → our shapes. No `chrome.*`, so `node --test` can run it |
| `content.js` | The panel and every view inside it; applies the skin's classes; answers the popup's receipt |
| `receipt.js` | The receipt: papers, the rows, put-back classes, kill switches |
| `selectors.js` | Every Canvas selector, with page and confidence |
| `boot.js` | Runs at document_start so the paper is on before first paint |
| `day.js` | The date helpers the panel and popup share |
| `looks.js` | The look catalog and the slime's accessories |
| `slime.js` | Generated by `bridge/port-slime.py` — do not hand-edit |
| `skin.css` | The Canvas reskin and the panel, all through CSS custom properties |
| `popup.html/js` | Due next, the receipt, pairing, connected schools, toggles, first-run |

## Two-way bridge

The extension pushes Canvas work to the phone and reads two things back: the coin
balance with the looks that are owned, and how far the phone has paid.

Coins for a finished focus session, and for a look bought here, are queued into
the push as `requests`. The app's ledger decides — the extension only asks, and
the same request is never paid twice because each carries its own idempotency
key.

**Requests stay queued until the phone says it paid them**, not until the bridge
accepts the push. A push only means the row was written; the phone may not read
it before the next push overwrites it. Clearing on write is how finished focus
sessions used to disappear.

## What leaves your laptop

Course names and codes, your grade in each, and assignment titles, due dates,
points and submission times.

Not sent: your per-assignment score history and assignment-group weights. Those
stay on this machine for the Grades view, because the phone has no use for them
and they are the most identifying thing here.

The panel itself lives in a closed shadow root, so no script on a Canvas page —
a school's global theme JS, a teacher's HTML, an embedded tool — can read the
grades it is showing.

# How BetterCampus skins every page (read live on George's Dartmouth Canvas, 2026-09-06)

Two themes were applied and every main page was walked: the pink "Frutiger Metro"
copy George had on, then the community theme "Ghibli" (40k likes). Findings come
from the styles the extension injects into the page, computed styles, and the DOM.

## The model: nine colours on `:root`, then "everything is transparent"

Every theme is a set of CSS variables the extension writes into a `<style
id="bettercanvas-theme-preset">`:

| Variable | Ghibli | Frutiger Metro | Used for |
|---|---|---|---|
| `--bcbackground-0` | #2f3e46 | #edd4d4 | the page (body) |
| `--bcbackground-1` | #354f52 | #c6949b | raised bits: buttons, active course tab, inputs, table headers |
| `--bcbackground-2` | #52796f | #c6949b | accents (rarely seen) |
| `--bcborders` | #84a98c | #a8cbb7 | every border and rule |
| `--bclinks` | #d8f5c7 | #7b9e7e | links, course nav links, breadcrumb links |
| `--bctext-0` | #e2e8de | #362621 | headings |
| `--bctext-1` | #cad2c5 | #4e3318 | body text |
| `--bctext-2` | #adb1aa | #896e5d | meta text |
| `--bcsidebar` | gradient | gradient + a Pinterest JPG | the left rail |
| `--bcsidebar-text` | #cadfbf | #362621 | rail text and icons |
| `--bccards` | transparent | = background-0 | course card body |
| `--bcfont` | broken (fell back to serif) | Jost, from Google Fonts | every element, `!important` |

Then their main stylesheet does one thing everywhere: white and grey surfaces
become transparent so background-0 shows through, links take `links`, headings
`text-0`, body `text-1`, borders `borders`, and anything "raised" (buttons,
active tab, input, table header) takes `background-1`. That is why one theme
reaches Calendar, Inbox, the courses table, quizzes and announcements without
per-page work: they do not skin pages, they skin surfaces.

What they also do, that we chose not to:
- **Replace the left rail.** Canvas's `#header` children get `opacity: 0;
  pointer-events: none` and a `<bettercanvas-sidebar>` custom element (closed
  shadow root) is placed on top, 86px collapsed, ~180px wide open. It only
  loaded some of the time during the walk; other loads showed Canvas's rail
  painted with the sidebar gradient.
- **Restyle every button.** Buttons become `background-1` with `borders`.
- **Swap the font** on `*` with `!important`. Ghibli's font link was empty, so
  the whole site fell back to Times. A theme can break reading.
- **Load art from the internet.** The sidebar image and card images are
  Pinterest / Tumblr URLs fetched by the student's browser.

## Where they still miss (with Ghibli on)

Measured on Inbox and Announcements, both InstUI (React) pages:
- Text inputs and checkboxes stay white with grey borders.
- Meta text stays InstUI grey (#586874) on a dark theme.
- Avatars stay white circles.
- Buttons keep InstUI light grey.
So "every page" is really "every page's big surfaces". The small controls are
still stock, and on a dark theme they glow.

## The in-page app

Clicking the sidebar opens `?bettercampus=open`, a full-screen app inside Canvas:
Edit Canvas (Themes / Widgets / To-Do List / Sidebar / Dashboard / Courses /
Other), Grades, Plan, Explore, My Locker, Create. Themes has Browse (categories
All, Minimalist, Pastel, Vintage...) and My themes; a theme editor with Colors
(with a readability checker and contrast target), Cards (overlay opacity, an image
per course), Cursors, and Stickers. Free accounts get **5 theme swaps**; the rest
is Pro. Widgets: Notes area, GPA overview. Dashboard: universal search bar, grades
on cards (always / hover), tasks under cards. Sidebar: width, label density, icon
size, hide school logo. Other: file annotations, task integrations, quiz safe mode
(turns themes off on quizzes).

## What we take from this

1. **Skin surfaces, not pages.** One layer that maps every white or grey
   surface to paper, every rule to `--pk-rule`, every heading to ink, every
   link to the theme mark. Built 2026-09-06 as the "everywhere" block in
   `extension/skin.css`.
2. **InstUI by suffix, never by hash.** Their class names are
   `css-<hash>-<name>`; the name is stable. `[class*="textInput__facade"]`,
   `[class*="checkboxFacade__facade"]`, `[class*="-view-heading"]`,
   `[class*="-text"]` reach the small controls they leave stock.
3. **Keep our lines.** Buttons stay Canvas's. The rail stays Canvas's, painted.
   No font. No URLs. Art ships in the zip.
4. **Quiz safe mode is right.** We already switch off on New Quizzes; classic
   quiz-taking pages should get the same kill switch.

Screens from the walk are in `reference/bettercampus/live-*.png`.

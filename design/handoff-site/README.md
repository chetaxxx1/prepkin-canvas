# Handoff: prepkin.com — Home, Privacy, Terms, Support

## Overview

**About the design files.** `prepkin.com.dc.html` and `support.js` are a design reference created in HTML: a pannable canvas showing intended look and copy. Do not ship the HTML. Recreate the pages in `site/build.py`'s markdown-to-HTML pipeline with inline CSS, self-hosted fonts and images, and no JavaScript beyond the optional find field. Open the canvas in any browser; ids (`1a`, `2c`) are badged on each artboard.


Four pages plus a 404, designed as a compliance site that also sells. Every artboard lives in `prepkin.com.dc.html` (pan/zoom canvas, ids badged `1a`–`1j`). Port into `site/build.py`; do not ship the HTML.

| id | Artboard | Width |
|---|---|---|
| `1a` | Home, light | 1280 |
| `1b` | Home, light | 390 |
| `1c` | Home, dark, above the fold + first section | 1280 |
| `1d` | Privacy policy, one page, two registers (recommended) | 1280 |
| `1e` | Privacy, plainly — the Loom two-tier alternative at `/privacy/plain/` | 1280 |
| `1f` | Privacy, light, to the pod section | 390 |
| `1g` | Privacy, dark, above the fold + TLDR | 1280 |
| `1h` | Terms of Service | 1280 |
| `1i` | Support | 1280 |
| `1j` | 404 | 1280 |
| `2a` | Home hero + privacy claim, second pass (nav dots, full-fill mint block) | 1280 |
| `2b` | Install section, second pass (white panel, browser marks, no illustration) | 1280 |
| `2c` | Privacy shell, second pass (band + overlapping sheet, gradient title card) | 1280 |
| `2d` | Support, second pass (smaller cards, icon rows, arrow chips) | 1280 |

Turn 2 artboards are drop-in replacements for the matching sections of turn 1. If adopted: `2a` replaces the hero + "Reads nothing" section on Home; `2b` replaces the install section and removes the line-drawing placeholder; `2c` changes the legal shell on Privacy, Terms and the plain page; `2d` replaces Support.

**Privacy structure — pick one.** `1d` is one page with two registers: the policy's own "The short version" promoted into a bordered TLDR card above the formal document, sidebar contents with a find field. `1e` adds a second page at `/privacy/plain/` with seven short statements, every sentence lifted from PRIVACY.md, cross-linked to the full document. Recommendation for a one-person product: ship `1d` only. Two documents drift; the TLDR card in `1d` already gives the human register and it is the same file. If you ship `1e`, add it to the Documents list on `1d` and `1h` as "Privacy, plainly".

## Fidelity

High. Colours, type, spacing, radii are final. Three placeholders, all dashed frames with monospace labels:
- Home hero: before/after Canvas shot, 1120 × 520, below the hero.
- Home "On your laptop" card: before/after, 520 × 260 (346 × 150 on mobile).
- Home install section: a single line drawing of the Chrome toolbar with the Prepkin mark pinned, 420 × 120.
- Support: three 36 × 36 icon tiles. Use icons from `design/icons/` (connect, heart, tabHome or similar), 1-colour, ink.
- Browser marks in the hero "Works in" row: 16 px circles. Use the official mark of each browser, self-hosted SVG, or drop the row and keep the sentence.

## Network rule

No external request from any page. Fonts and images are same-origin. The design file loads Newsreader and Nunito from Google **for preview only**; production hosts the `.woff2` files at `/fonts/`. No JavaScript is required on any page. The only optional script is the privacy find field (≤ 30 lines, inline, see Interactions); without it the field is omitted, not broken.

## Typefaces (self-host)

- **Newsreader** (SIL OFL) — variable or static. Weights used: 400 (display, all headlines, italic for the hero accent), 500 (h2 in documents). Optical size axis: use the 24–72 cut for display.
- **Nunito** (SIL OFL) — weights 500, 600, 700, 800. No 900 anywhere.
- Fallbacks: `Newsreader, Georgia, serif` and `Nunito, "SF Pro Rounded", ui-rounded, system-ui, sans-serif`. `font-display: swap`.

## Tokens

### Colour, light
```
paper        #FAF5EC   page ground
card         #FFFFFF   raised card
inset        #F3EDE0   recessed block, sidebar current, pod "cannot see"
hairline     #E8E0D2   rules, card borders
ink          #2E2822   headlines, body
ink-2        #5E554B   support copy, nav links
muted        #776D62   labels, meta, placeholder text   (5.0:1 on paper)
mint         #57C79B   accent border, active dot, underline
green        #2E8C68   text-safe accent, links, hero italic (4.6:1 on paper)
mint-soft    #E3F6EE   "Start here" pill ground
hero-glow    #DDF3E8   radial gradient centre (fades to #F3EEDF then paper)
frame-dash   #CFC5B4   placeholder dashes
```
### Colour, dark
```
paper        #17191D
card         #1E2126
inset        #121417
hairline     #2C3037
ink          #E6E8EA
ink-2        #B4BAC1
muted        #8D949C
mint         #57C79B   unchanged
green        #7FDDB8   text-safe accent on dark
hero-glow    #1E3A31   radial centre (fades to #1B1F24 then paper)
button       #E6E8EA fill, #17191D text (inverts the light #2E2822 / #FAF5EC)
```
Switch with `prefers-color-scheme: dark`. No toggle.

### Type scale (size / line-height)
```
display-xl   96 / 0.98   Newsreader 400, -0.03em   legal page titles
display-l    92 / 1.02   Newsreader 400, -0.025em  home hero (56 on mobile)
display-m    84 / 1.00   Newsreader 400, -0.03em   Support title
display-s    72 / 1.02   Newsreader 400, -0.03em   404 title
h2-home      52 / 1.05   Newsreader 400, -0.02em   (44 / 1.1 for centred h2s; 36 / 32 on mobile)
h2-sync      40 / 1.10   Newsreader 400, -0.02em
h3-card      34 / 1.10   Newsreader 400, -0.02em   two-up card titles (26 on mobile)
h2-doc       28 / 1.20   Newsreader 500, -0.01em   section heads in Privacy/Terms (24 on mobile)
tldr         26 / 1.30   Newsreader 400, -0.01em   TLDR card lead (21 on mobile)
plain-label  28 / 1.15   Newsreader 400           left labels on /privacy/plain/
numeral      26 / 1      Newsreader 400, green     01 02 03 list
lead         22 / 1.45   Nunito 500               install sentence
sub          20 / 1.50   Nunito 600, ink-2        hero support, page subtitles (17 on mobile)
list-l       19 / 1.40   Nunito 500               "What Prepkin is not"
body-l       18 / 1.60   Nunito 500, ink-2        section support copy
body         17 / 1.65   Nunito 500               document reading text (16 on mobile)
ui           16 / 1      Nunito 800               buttons, wordmark
row-title    17 / 1.3    Nunito 800
row-body     15 / 1.55   Nunito 500, ink-2
nav          14 / 1      Nunito 700, ink-2
toc          14 / 1.35   Nunito 700
chip         13.5 / 1    Nunito 700, line-through
meta         13 / 1      Nunito 700, muted
label        12 / 1      Nunito 800, +0.12em, uppercase   (11 in sidebars and cards)
```
Nothing below 11 px. Nothing a reader reads below 13 px.

### Reading column
620 px wide at 17 px Nunito 500 = **66–70 characters per line** (measured on the privacy body). Hold it: `max-width: 620px`. On 390: 350 px at 16 px = 58–62 characters.

### Radius
`10` sidebar row · `14` small frames · `16` mobile cards · `18` pod cards · `20` list block · `22` cards · `28` two-up and sync block · `999` pills and buttons.

### Spacing
4-pt grid. Page gutter 80 (20 on mobile). Section gap 128 (72 mobile). Above-the-fold air on legal pages: nav at 24, title at 168 from the top, body grid 96 below the title. Sidebar 260 · gap 100 · column 620 (= 980 content, centred in 1280 with 80 gutters plus 70 slack on the right). Card padding 36 (24 mobile). Row padding 22 × 26.

### Elevation
Nav pill: `rgba(255,255,255,.72)`, 1 px `rgba(46,40,34,.08)` border, `0 2px 12px rgba(46,40,34,.06)`. Dark: `rgba(30,33,38,.8)`, border `rgba(255,255,255,.1)`. No other shadows on the site.

## Layout per artboard

**1a Home, 1280.** Nav pill centred, top 24, 44 tall. Hero: h1 at y≈212, centred, max 900; support 520 wide; two pill buttons (56 tall, 26 side padding) gap 12; "Works in" row. Sprout 300 wide, right 120, bleeding 40 below the hero ground. Hero ground is a radial gradient anchored at 50% / 108%. Dashed shot frame 1120 × 200 (grows to 520 when the shot exists). Section "Reads nothing, sends nothing": 2-col grid 1fr/1fr gap 64; right column a 3-row hairline list. Two-up: two cards 1fr/1fr gap 24, left card 2 px mint border + "Start here" pill, right card 2 px hairline + "Optional"; framed area 260 tall, top corners 20, bleeds out of the card bottom. Sync block: inset ground, radius 28, padding 56 × 64, 2-col; right side a laptop box 150 × 104, dashed mint line, phone box 74 × 130. Install: centred, drawing 420 × 120, one sentence, two buttons. "What Prepkin is not": h2 left, hairline list right (6 rows, 16 vertical padding). Footer: hairline top, wordmark left, two link columns centre, disclaimer right.

**1b Home, 390.** Same order, single column, gutters 20. Nav pill collapses to wordmark + Privacy + Support + a "Chrome" button. Buttons stack full-width. "Works in" becomes a sentence. Cards stack, laptop card first.

**1c Home, dark.** Token swap only. Buttons invert. Sprout unchanged.

**1d Privacy, 1280.** Title block with 168 above. Grid: sticky sidebar (top 96) 260 wide with Documents (current row on inset with a 6 px mint dot) and On this page (find field, then a numbered 11-item list with a 2 px left rule, current item mint). Article 620. TLDR card: white, 2 px mint, radius 22, padding 32 × 36; the label reads "1 · The short version"; first paragraph in Newsreader 26, second in Nunito 16 ink-2. Every h2 has an id (`what-it-reads`, `what-leaves`, `where-it-goes`, `the-pod`, `how-long`, `who-for`, `third-parties`, `your-choices`, `changes`, `contact`; the TLDR is `short-version`) and `scroll-margin-top: 96px` so store-reviewer deep links land below the nav. Pod section: after the intro paragraph, a 2-col block gap 16 — left, white card "They can see · four things" with the four bold items verbatim; right, inset card "They cannot see" with 15 struck-through chips (coursework, course names, grades, assignments, due dates, school, Canvas site, email, real name, student ID, location, your device, when you last opened the app, whether you are online, your balance) and one line. The original paragraphs follow unchanged below the block, so the legal text is complete.

**1e Privacy, plainly.** Same shell. Title 96 across 1000. Sidebar Documents lists three. Body: seven hairline-ruled rows, grid 160 / 1fr, label in Newsreader 28, text Nunito 17. Then "Read the full policy" button.

**1f Privacy, 390.** Contents becomes a single disclosure row ("On this page · 11 sections"). TLDR card padding 22. Pod block stacks: can-see card, then cannot-see card.

**1g Privacy, dark.** Token swap. TLDR card is `card` dark with the same 2 px mint.

**1h Terms.** Identical shell to `1d`; 11 contents items; no find field (900 words does not need one). TLDR card has one paragraph.

**1i Support.** Title 84 centred with a 560-wide lead. Three cards 1fr × 3 gap 20, radius 22, padding 28: icon tile 36, one-word label 18/800, one line 15 ink-2. Two inset cards 1fr/1fr gap 20, radius 22, padding 36: Newsreader 30 title, one line, arrow links in green (no buttons). Closer: "Questions?" 52 and one dark pill.

**1j 404.** Title 72 in a 720 column, one line, four pills (Home dark, three outline). Sprout 340 bottom right.

## Copy, verbatim

### Nav and footer (all pages)
- Prepkin · Privacy · Terms · Support · Add to Chrome
- Footer links: Privacy · Terms · Support · Add to Chrome · Get the iPhone app · support@prepkin.com
- Footer: "Not made or endorsed by Instructure or by any school."
- Footer: "No cookies. No analytics. Nothing loads from anywhere but prepkin.com."
- Current nav item: 2 px mint underline, 6 px offset.

### Home
- H1: "Canvas, but calm." ("calm." italic, green)
- Support: "A Chrome extension that quiets your Canvas page with pure CSS. It reads nothing, sends nothing."
- Buttons: "Add to Chrome" · "Get the iPhone app"
- "Works in" Chrome · Edge · Brave · Arc (mobile: "Works in Chrome, Edge, Brave and Arc.")
- Label: "The skin" · H2: "Reads nothing, sends nothing."
- "Pure CSS over Canvas's own markup. Zero external requests. Turn it off and Canvas goes back to how it was."
- 01 "No password, no account" / "It uses the Canvas login already in your browser."
- 02 "No requests" / "No fonts, images, scripts or analytics from anywhere else. This site keeps the same rule."
- 03 "Every change listed" / "What was changed and put back is worked out on your laptop and shown to you. It is not sent anywhere."
- H2: "Two halves. Each one works alone." · "They pair only if you pair them."
- Card 1: pill "Start here" · label "On your laptop" · "A Canvas you can look at at 11pm." · "Quieter page. A small buddy panel and a focus timer on Canvas itself. Free."
- Card 2: pill "Optional" · label "On your phone" · "A fish called Sprout." · "Finish a Canvas task, earn 30 coins. Coins buy tank scenes, costumes and looks. Sprout does not eat, so there is nothing to keep alive."
- Label: "If you pair them" · H2: "The pairing does send something. Here is exactly what."
- "Your coursework list and your course grades, to your own phone, only after you pair. Never your password, name, email or student ID. Never anything from another site. Unpair, and the row is deleted."
- Link: "Read the full privacy policy →"
- Diagram labels: "Your laptop" · "coursework list / course grades" · "only after you pair" · "Your phone"
- Install: "Add it to Chrome, open Canvas, and the page is already quieter."
- H2: "What Prepkin is not."
- "Not a hunger meter. Sprout does not eat." · "Not an account. There is nothing to sign up for." · "Not tracking. No analytics, no ads, no cookies." · "Not a promise about your grades." · "Not test prep." · "Not made or endorsed by Instructure or by any school."

### Privacy (1d, 1f, 1g)
- Label: "Legal · Last updated 5 September 2026" · H1: "Privacy policy" · Sub: "Prepkin for Canvas"
- Sidebar: "Documents" (Privacy policy, Terms of Service) · "On this page" · find field placeholder "Find in this policy"
- Body: `bridge/PRIVACY.md` from "The short version" to "Contact", unchanged, including the Supabase link and the mailto. The TLDR card label is "1 · The short version". Chips on the cannot-see card are drawn from the policy's own "does not contain" sentence plus "when you last opened the app", "whether you are online", "your balance" from the same section.

### Privacy, plainly (1e)
- Label: "Privacy, plainly · Last updated 5 September 2026"
- H1: "What Prepkin knows about you, in one page."
- Sub: "This is the same policy, said shorter. The full document is the one that counts. It is one click away and says nothing this page hides."
- Documents: "Privacy, plainly" · "Privacy policy, in full" · "Terms of Service"
- It reads — "Only the Canvas you connect, using the login already in your browser. Your courses, assignments, whether you handed things in, your grades, and your dashboard colours."
- It sends — "Your coursework list and course grades, to your own phone, and makes no other request. Every six hours the extension asks whether to turn itself off on some Canvas page; that request carries nothing about you."
- Never — "Your Canvas password, your email address, your name, your student ID, your browsing on any other site, or anything at all from a site you did not connect."
- Who can read it — "Nobody else. It takes your token, and only your phone and your laptop have it. Not other students, not people in your league pod, not anyone with the app."
- The pod — "If you join, up to nineteen students you do not know can see four things: a nickname the app picked, your fish, its stars, and the coins you earned that week. Never your coursework, never your grades, never your real name. Joining is your choice."
- How long — "The coursework row is deleted 30 days after your laptop last synced. Tap Disconnect in the app and it is deleted immediately. Tap Forget me in the league and your identity and every pod row you appear in go too."
- Third parties — "Supabase hosts the database. No analytics, advertising, tracking, or other third-party code is included in the extension or the app."
- Button: "Read the full policy" · "or email support@prepkin.com"

### Terms (1h)
- Label: "Legal · Last updated 8 September 2026" · H1: "Terms of Service" · Sub: "Prepkin"
- Body: `bridge/TERMS.md` from "The short version" to "Contact", unchanged except the Plus line, which reads "$9.99 a month, or $69.99 a year".

### Support (1i)
- H1: "Support"
- Lead: "One person makes Prepkin and the same person answers this address. Email support@prepkin.com and we will help."
- Write — "Say which half you are writing about, iPhone or Chrome, your school's Canvas address, and what you expected to happen."
- Chrome — "If a Canvas page looks wrong, turn the look off in the popup. The page goes back to Canvas as it was."
- iPhone — "Disconnect in the app deletes your coursework row right away. Forget me in the league deletes your league identity."
- "Get Prepkin" / "The Chrome extension and the iPhone app. Each one works on its own." / "Chrome extension →" · "iPhone app →" (→ https://prepkin.com/chrome and /app)
- "Also on this site" / "What Prepkin reads, what it sends, and the terms you agree to." / "Privacy policy →" · "Terms of Service →"
- "Questions?" · button "Email support@prepkin.com"

### Turn 2 additions
- 2a block: "Pure CSS" / "Over Canvas's own markup. It uses the login already in your browser and never asks for a password." · "Zero requests" / "No fonts, images, scripts or analytics from anywhere else. This site keeps the same rule." · "Every change listed" / "What was changed and put back is shown to you on your laptop. It is not sent anywhere."
- 2b: "Add it to Chrome. Open Canvas." · "The page is already quieter. Turn it off any time and Canvas goes back to how it was." · "Free. No account. Not made or endorsed by Instructure or by any school."
- 2c: band label "Prepkin · legal" · title card meta "Prepkin for Canvas · Last updated 5 September 2026" · lead begins "TLDR:" in green.
- 2d: "How can we help?" · "Questions about Canvas, the app, privacy, or anything else. One person makes Prepkin and the same person answers." · Email / "We read them all, we promise." · Privacy / "Read it first. It is short and says everything." · Delete / "Disconnect in the app. The row goes immediately." · chips "Get the extension ›" · "Get the app ›" · "Writing in" · "Anything else" / "Deletion requests, a school asking about the extension, or something that just seems off."

### 404 (1j)
- "404" · "Nothing lives at this address." · "The page may have moved. Everything on this site is one of four." · Home · Privacy · Terms · Support

## Interactions

- **Links and buttons:** hover shifts background 6% toward ink (dark pill → `#3A342D`; outline pill → `#F3EDE0`); underline appears on text links. 150 ms, `cubic-bezier(.22,1,.36,1)`. Focus-visible: 2 px mint ring, 2 px offset. Never removed.
- **Sticky sidebar:** `position: sticky; top: 96px` on the aside. Pure CSS.
- **Current-section marking in contents:** CSS only via `:target` on the h2 ids is enough for deep links. Live scroll-spy would need JS; skip it.
- **Find in this policy:** the one JS candidate. Inline, ≤ 30 lines: filter the 11 contents rows by substring as the user types, hide non-matches. Without JS the field is not rendered.
- **Deep links:** every h2 carries an id and `scroll-margin-top: 96px`. Store reviewers land on `/privacy/#the-pod` with the heading visible under the nav.
- **Motion:** none beyond hover. No scroll animation, no entrance fades. `prefers-reduced-motion: reduce` sets all transition durations to 0.01 ms; nothing else changes because nothing else moves.
- **Dark:** `prefers-color-scheme: dark` swaps the token set. The nav pill and buttons invert; mint stays.

## References (Mobbin)

From the brief:
- mymind hero and floating pill nav, and its "We promise" list (https://mobbin.com/sites/sections/e6583aed-2cb5-4cc3-82c2-ce637e125675) — the serif headline at size, the soft radial ground, the pill nav, and the plain "No …" list that became "What Prepkin is not."
- Notion Web Clipper install pattern — drawing, sentence, buttons; used for the install section.
- Butter two-up — two large rounded cards with tight headlines and framed product areas; used for the two halves.
- Superpower accent outline — mint border on the recommended card only.
- Craft TLDR + sidebar with find field — the TLDR card and contents column on Privacy and Terms.
- Loom "Privacy for Humans" — the `1e` alternative.
- Mistral AI legal shell — large display title on cream with generous air, left document list, current one marked.
- Miro / ClickUp sticky sidebar mechanics; Upwork numbered contents.
- Visitors three small cards; Linear two quiet cards with arrow links; ExpressVPN "Questions?" closer — all on Support.

Second pass:
- mymind browser-extension panel (https://mobbin.com/sites/sections/5c3f7e72-6d1a-446f-b555-4e293919f495) — white rounded panel on a gradient ground, serif headline, one sentence, a row of outline browser marks; became `2b`. Also mymind's coloured nav dots, used in `2a`.
- Clockwise hero (https://mobbin.com/sites/sections/ff439432-5975-41e1-a742-02370e3ad477) — one huge green statement inside a pale-green fill; became the privacy-claim block in `2a` (mint-soft ground, green Newsreader at 84).
- Craft privacy (https://mobbin.com/sites/sections/186d65b3-ec98-4a7b-af3d-5e200b92debf) — gradient title card with the logo, bold "TLDR:" lead, dotted rule, then the document; used in `2c`.
- Loom terms shell (https://mobbin.com/sites/sections/48f8ae6c-9f70-4a00-901e-746e05f8e83e) — coloured band with an uppercase label and a white sheet overlapping it; used in `2c`.
- Visitors contact (https://mobbin.com/sites/sections/3bba69b3-41b3-4814-b503-5f23824a0fc4) — three 230-wide cards, circle icon, one word, one line ("We read them all, we promise."); `2d`.
- Linear contact (https://mobbin.com/sites/sections/ef038e1f-4aaf-47d4-a7a5-33713bc679fa) — icon-title row, arrow chip instead of a button, two-column quiet closer with the email in plain text; `2d`.
- Notion Web Clipper (https://mobbin.com/sites/sections/b1e2f911-9184-4df9-884f-f6b92439c640) — confirmed the drawing/sentence/buttons pattern from the brief; `2b` keeps the structure without the drawing.
- Superpower hero (https://mobbin.com/sites/sections/a66c7229-39c5-4f24-b34c-c09db551575d) — reviewed for the pill nav; its dark full-width bar was not taken.

Found in search:
- Headspace hero (https://mobbin.com/sites/sections/1f442b7d-ed5e-42f1-a0f3-5010604f47d8) — one mascot, one line, one button; confirmed the hero can carry Sprout at size without a screenshot. Palette not borrowed.
- PayPal two-up (https://mobbin.com/sites/sections/779990c5-bf1c-43f3-9f95-2e2f74aade46) — framed product area sitting on top of the card, headline and list below; used for the framed-area proportions.
- Superhuman footer (https://mobbin.com/sites/sections/92400f28-451c-421c-9e15-34707c259a2b) — wordmark left, link columns, one-line tagline; adopted the column structure, not the giant wordmark.
- Daylight 404 (https://mobbin.com/sites/sections/607b3e76-ee4f-4a81-ad95-4f3f84dab994) — a short serif sentence and two actions on cream; used for `1j`.
- folk / 1Password / Dropbox two-column feature sections — reviewed, not used; all read as SaaS.

## Deviations from the brief

1. **Plus price.** TERMS.md says $3.99 / $19.99; the brief says $9.99 / $69.99. The design shows $9.99 / $69.99 as agreed. Update `bridge/TERMS.md` before publishing so the page and the source match.
2. **Privacy: one page recommended over two.** Both are drawn (`1d`, `1e`). Ship `1d`; a single maintainer should not keep two privacy documents in step.
3. **Sprout is on the page.** The brief said "no images" only about the current site; the user approved the mascot in the hero, the phone card and the 404. It is the one image on the site and is served from prepkin.com.
4. **A 404 was added.** Cloudflare will serve one; an unstyled one would break the register.
5. **Browser marks are placeholders.** The brief asks for a row of browser marks; drawing third-party logos is out of scope. Host official SVGs or keep the sentence only.
6. **No search in Terms.** 900 words and 11 headings do not need a find field; the sidebar contents does the job.
7. **The current site (`bridge/site/`) was not recreated.** The brief referenced `site/` and `build.py`, which are not on `main`; the user chose to skip the recreation.
8. **Home copy is new.** Everything on Home outside the verbatim facts (30 coins, reads nothing sends nothing, the sync sentence, the footer line) was written for this design and should be read with the same care as the policy text.

## Files

- `prepkin.com.dc.html` — the canvas, ten artboards.
- `hero-a.dc.html`, `hero-b.dc.html` — the two serif candidates shown for the typeface pick (B chosen). Safe to delete.
- `extension/icons/icon.svg`, `ios/Resources/Assets.xcassets/sprout-mint-2.imageset/sprout-mint-2@2x.png` — copied from the repo for the mark and the hero.
- `github.md` — source association.

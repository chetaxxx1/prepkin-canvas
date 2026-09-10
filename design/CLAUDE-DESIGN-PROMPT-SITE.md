# Prompt for Claude Design — prepkin.com

**How to use.** Do NOT paste `CLAUDE-DESIGN-PREAMBLE.md` with this one. That preamble
is written for iPhone screens at 402x874 and its canvas rules do not apply here. This
brief is self-contained. Mobbin connector on. Attach nothing; the current site is in the
repo at `site/`.

---

You are designing **four pages of a website**, not an app screen. The site is
`prepkin.com`. It exists because the Chrome Web Store and the App Store both refuse a
submission without a hosted privacy policy and a working support page. So this is a
compliance site that also has to sell, and it currently does neither well.

## What exists today, and what is wrong with it

Read `site/index.html`, `site/privacy/index.html`, `site/support/index.html` and
`site/build.py`. Claude Code generated them in one pass and they are a **wireframe with
real text in it**: a centred column, one accent green, cards with 14px radius, system
font, no images, no motion, no idea. The content is right. The design is placeholder.
Assume nothing in the current CSS is load-bearing.

Your job is the design. Claude Code will port whatever you return back into
`site/build.py`, which generates the pages from markdown.

## The one constraint that shapes everything

**The site may not make a single external network request.**

The whole product claim is that the Canvas skin loads nothing from anywhere — no CDN
fonts, no CDN images, no analytics. A marketing site that pulls Inter from Google Fonts
would undercut the only thing we lead with, and a reviewer could reasonably notice.

What that permits, and it is more than it sounds:

- **Self-hosted web fonts are fine.** A `.woff2` served from `prepkin.com` is
  same-origin. Name the exact typefaces you want and we will host the files. Do not
  settle for `system-ui` — see mymind and Mistral below for what real type buys.
- **Self-hosted images are fine.** SVG, PNG, WebP, all served from our own domain.
- **Inline CSS and inline SVG are fine.** No build step, no framework, no Tailwind.
- **No JavaScript unless one interaction genuinely needs it**, and then it is inline and
  under 30 lines. There is no analytics script; Cloudflare counts page views server-side.

## The facts. Do not invent past these.

- **Prepkin is two halves.** A Chrome extension that reskins Canvas, and an iPhone app
  where a fish called Sprout lives in a tank. They pair only if the student pairs them.
- **The skin's claim, verbatim: "reads nothing, sends nothing."** Pure CSS over Canvas's
  own markup. Zero external requests. Never strengthen this sentence and never let it
  drift onto the sync half.
- **The sync is separate and it does send things**: your coursework list and your course
  grades, to your own phone, only after you pair. Say so plainly. The honesty is the
  pitch.
- **The reward loop is coins, not food.** Finish a Canvas task, earn 30 coins. Coins buy
  the five tank scenes — Lagoon free, Reef 200, Kelp 220, Dusk 250, Deep 280 — plus
  costumes and looks. **Sprout does not eat. There is no hunger, no food, no meter.**
- **Learn holds 57 lessons** on money, studying, psychology, people and work. Real
  titles: "Why compound interest wins", "Credit scores, plainly", "Your employer's match
  is free money".
- **Prepkin Plus is $9.99 a month or $69.99 a year.** Yearly is the default. Plus buys
  speed, slots and convenience. It never sells cosmetics. Nothing is taken away if it
  lapses. **The site does not need a pricing page** — do not design one.
- **Audience: US college undergrads, 18 to 22.** Not high schoolers, who stay free.
- **Never claim grades, GPA or scores improve.** No evidence exists and it converts a
  marketing problem into a store-policy one.
- **Never call Prepkin an SAT or test-prep app.**
- Not made or endorsed by Instructure or by any school. This line goes in the footer.

## Voice

Plain, warm, specific. Eighth-grade reading level. Short sentences, one idea each. No
exclamation marks. No "seamless", "unlock", "level up", "game-changer". **No emoji
anywhere.** Never use the word "students" to address the reader; the reader is "you".

## The four pages

### 1. Home
The manifest declares `homepage_url: https://prepkin.com`, so a dead or thin page here is
a rejection risk. It has one job beyond existing: make a sophomore who has Canvas open in
another tab want the extension.

Needs: a hero, the privacy claim, the two halves, the separateness of the sync, the "what
Prepkin is not" list, a footer. **The hero has no product screenshot yet** — the
before-and-after Canvas shots do not exist. Design the hero so it works without one, and
mark where one goes later.

**Steal from [mymind](https://mobbin.com/sites/sections/a350031f-021b-411a-a9c5-a32f6befc5d3)** —
the best reference in this brief. A serif display headline at genuine size, a soft
gradient ground, one small line of support copy, a row of browser marks, and a nav that
is a floating pill rather than a bar. It is cozy without being childish, which is the
exact register Prepkin needs and the exact register the current site misses.

**Steal the install pattern from [Notion Web Clipper](https://mobbin.com/sites/sections/b1e2f911-9184-4df9-884f-f6b92439c640)** —
a single line drawing, one sentence, then the install buttons. No screenshot needed,
which solves our missing-asset problem outright.

**Steal the two-up from [Butter](https://mobbin.com/sites/sections/3e1db400-2e9f-477c-bdc7-f9209d245ca5)** —
two large rounded cards side by side on a quiet ground, each with a headline set tight
and a framed product area beneath. Use this for "on your laptop" and "on your phone".
The framed area is where the before-and-after goes when we shoot it.

**Steal the accent-outline trick from [Superpower](https://mobbin.com/sites/sections/f95688f7-2ed1-4663-8d6d-2fb686648996)** —
of two side-by-side cards, one carries a thin accent border to mark it as the one being
recommended. Use it to make the skin read as the default and the sync read as optional.

### 2. Privacy policy
The longest page and the one a school reviewer will actually read. The text is in
`bridge/PRIVACY.md` and is already good; do not rewrite it. It has 11 sections and runs
to about 1,800 words, including a section on what strangers can see in a league pod.

**Steal the TLDR from [Craft](https://mobbin.com/sites/sections/186d65b3-ec98-4a7b-af3d-5e200b92debf)** —
a bold plain-language summary sitting above the formal document, plus a sidebar table of
contents with a search field. Our policy already opens with a section called "The short
version"; promote it into that TLDR slot and set it apart visually.

**Steal the two-tier idea from [Loom](https://mobbin.com/sites/sections/0a31fbe8-4778-4aa6-901d-1c7c852020be)** —
Loom ships "Privacy for Humans" as a separate page beside the legal Privacy Policy. This
is the single best structural idea available to a product whose whole pitch is privacy.
Propose it: a short human page at `/privacy/plain/` and the full document at `/privacy/`,
cross-linked. If you think a one-person product cannot maintain two, say so and give one
page with two clearly separated registers instead.

**Steal the shell from [Mistral AI](https://mobbin.com/sites/sections/d5310632-7c5b-4580-80a9-465115a25a80)** —
a very large display headline on a cream ground above the fold, then a left sidebar of
document links with the current one marked, then the body. The cream is close to what
Prepkin already uses. Note how much air sits above the first heading.

Also look at [Miro](https://mobbin.com/sites/sections/700572c9-51b3-40bb-aa84-8c22c6200fd3)
and [ClickUp](https://mobbin.com/sites/sections/bc246468-a583-4199-b5f6-78f7957aa779) for
sticky-sidebar mechanics, and
[Upwork](https://mobbin.com/sites/sections/628dc701-15b6-4444-9517-591272c30e8f) for a
numbered in-page contents block. We have only two documents, not thirty, so the sidebar
must not pretend to be a legal library.

Solve these specifically:
- **Measure the reading column.** The current one is 44rem and unmeasured. Give a
  character count per line and hold it.
- **The pod section is the scariest-looking part and the most reassuring in content.**
  It lists four things a stranger can see and about fifteen they cannot. Design that
  contrast; a wall of paragraphs wastes it.
- **Deep links must work.** A store reviewer will be sent to one section.

### 3. Terms
Same shell as the privacy page. Text is in `bridge/TERMS.md`, about 900 words, 12
sections. Nothing special beyond consistency with page 2.

### 4. Support
Both stores require a reachable support page. Ours has four things a student might need
and one email address. It should feel like one person answers it, because one person does.

**Steal from [Visitors](https://mobbin.com/sites/sections/3bba69b3-41b3-4814-b503-5f23824a0fc4)** —
three small cards with a tiny icon, a one-word label and a single line of warm copy
underneath ("We read them all, we promise"). It is exactly the right scale for a
one-person product and the opposite of a help centre.

**Steal the restraint from [Linear](https://mobbin.com/sites/sections/ef038e1f-4aaf-47d4-a7a5-33713bc679fa)** —
two cards, generous padding, a quiet arrow link rather than a button.

**Steal the closer from [ExpressVPN](https://mobbin.com/sites/sections/4e6b8537-04b3-4280-88f0-f54636d3a86c)** —
a centred "Questions?" and one action at the bottom of the page.

Do not steal from [Mural](https://mobbin.com/sites/sections/0fcecfae-738f-4126-a206-12be20264116)
or [monday.com](https://mobbin.com/sites/sections/7784e958-c57b-4cc5-9121-21a7257cf728).
A row of support-agent headshots and a purple help-centre banner are a lie at our size.

## Mobbin searches to run before you draw

Every link above is a section on `web`. Look at the images, not the metadata. Then run
these yourself with `search_sections`, and add what you find to the README:

1. `cozy consumer app marketing site hero with hand-drawn illustration and warm palette`
2. `two column feature section explaining a browser extension and a phone app together`
3. `privacy first product page with a short list of what is and is not collected`
4. `website footer with legal links and a single support email`
5. `404 page for a small consumer product`

Borrow mechanics and structure. Do not borrow a look wholesale, and do not borrow any
palette that reads as enterprise SaaS — no royal blue, no purple gradient, no dark navy
hero. Prepkin is cream, green and warm.

## What to return

A `.dc.html` canvas with **one artboard per page at 1280 wide**, plus a mobile artboard
at 390 wide for Home and Privacy, plus a `README.md` in the shape of
`design/handoff-kin/README.md`:

- Overview and fidelity
- Layout per artboard, in px, with the reading column's character count stated
- Tokens: every colour as a hex with a name, every type size with its line height, the
  radius scale, the spacing scale
- The exact typefaces, by name, with the weights used, so we can host the `.woff2` files
- Every string of copy, verbatim
- Light and dark palettes, both. The current site has both and it must stay that way.
- Any interaction, with duration and curve, and a `prefers-reduced-motion` note
- **References**: every Mobbin section you leaned on, as a link, one line on what you
  took from it
- Deviations from this brief and why

## Hard nos

- No cookie banner. We set no cookies and run no analytics script.
- No newsletter capture, no chat widget, no testimonials, no logo wall, no "trusted by".
- No stock photography and no faces.
- No pricing page.
- No claim about grades. No SAT. No emoji.
- No external font, image, script or stylesheet. Same-origin only.

# Action items from the Grok bot round

2026-09-10. Everything Scout, Reel and Storefront produced, plus what checking it
against the code turned up, collapsed into one ordered list.

## The one-line read

The bots produced a week of usable content work in one pass, and the real finding
is that **none of it can ship yet**, because the two store listings block on a
hosted privacy policy, a support address and a set of compliance answers that no
bot can create for you. The content is ahead of the plumbing.

---

## P0 — nothing ships until these exist. Only George can do them.

These were due 2026-09-07 per `LAUNCH-PLAN.md`. They are three days overdue and
both stores hard-block on them.

1. **Host the privacy policy at a real URL.** The text already exists at
   `bridge/PRIVACY.md`. It has never been hosted. Chrome and Apple both require a
   live URL. `LAUNCH-PLAN.md` picked Cloudflare Pages over GitHub Pages, because
   Cloudflare's free Web Analytics reports click counts and GitHub Pages does not.
   That choice is also your only way to measure view-to-install.
2. **Host the terms too.** Text exists at `bridge/TERMS.md`. Same situation.
3. **Create `support@` on the domain**, forward it somewhere you read daily, and
   send it a test message from a second account. Both stores require a working
   contact. The Chrome developer account needs an email read daily.
4. **Confirm what is actually at prepkin.com.** The extension's `manifest.json`
   declares `homepage_url: https://prepkin.com`, but that URL returned 403 when I
   checked today. A dead homepage URL in a submitted manifest is an easy rejection.
5. **Apple: there is no demo account to give, and that is fine.** The iOS app has
   no email, no sign-in and no accounts. Answer Apple's demo-account question with
   "sign-in is not required", do not invent credentials. Storefront's pack asked
   you for creds that cannot exist.

Until 1, 2 and 3 exist, every piece of listing copy in Storefront's pack is a
document, not a submission.

---

## P1 — the content work, in order

6. **Send the three correction blocks** in `design/grok-correction-01.md`. Reel
   rewrites six scripts, Storefront rewrites everything containing "feed". Do this
   before either bot produces anything else, or you get more work built on the same
   two wrong facts.
7. **Shoot script 10, "Five due tonight."** It is the only script sitting on a
   pattern with verified in-window reach at our scale (@_balencii, 686K views,
   metrics read from TikTok's own page JSON), it needs no face, and the slime fix
   means the Canvas before-and-after is now shootable. Swap its ending from feeding
   to coins.
8. **Then shoot script 1, "CUSTOMIZE. YOUR. CANVAS."** Before-and-after plus a Look
   Card and a six-character code. This is the unproven pattern, so treat it as the
   test: same week, same effort, and see which one moves.
9. **Get the promo images Storefront's pack forgot.** Chrome needs a 440x280 tile
   and a 1400x560 marquee on top of the five 1280x800 screenshots. Neither is in
   the pack. This is Ink's job — it is the one bot with nothing to do right now.
10. **Answer the compliance fields yourself.** Chrome wants a single-purpose
    statement and one justification per permission — there are four:
    `storage`, `alarms`, `activeTab`, `scripting`, plus one host permission,
    `https://*.supabase.co/*`. Apple wants age answers and export compliance.
    No bot should guess at these.

---

## P2 — measurement, which the plan says matters more than any campaign

11. **Nothing currently measures the three load-bearing rates.** The forecast rests
    on view-to-install 0.15%, install-to-pair 15%, and paywall-to-paid 1.5%, and
    all three are guesses. The app ships **zero analytics SDKs**, so today you can
    measure none of them.
12. **What each one needs.** View-to-install: per-channel redirect pages on the
    Cloudflare site, which has to exist anyway for item 1. Install-to-pair: the
    bridge's `pairings` table already holds it. Paywall-to-paid: App Store Connect
    reports it once there is a listing.
13. **Run the pairing count now.** A row appears when a phone makes a code, and
    `writer_hash` fills in when a laptop claims it, so the rate is:

    ```sql
    select count(*) as codes_made,
           count(writer_hash) as paired,
           round(100.0 * count(writer_hash) / nullif(count(*),0), 1) as pct
    from pairings;
    ```

    One caveat that matters: rows expire after 30 days (`expires_at`), and an
    unclaimed code is spent after 15 minutes. So this is a rolling 30-day snapshot,
    not a cumulative rate, and a code made and abandoned in the same minute still
    counts in the denominator. Read it as a floor.

---

## What actually generalizes from the research

Eight rules that showed up across every pattern Scout found, and that should
survive this batch:

1. **Externalize the stake in under two seconds.** The pet, tree or bean visibly
   thriving or suffering. This is the whole reason the genre works.
2. **Name a shameful micro-behavior**, not a goal. "Falling behind and pretending
   I'm fine" beats "stay organized".
3. **Self-own humor beats wellness perfection.** Nobody shares an ad for being
   good at school.
4. **Specific context beats category.** "Midterms", a real class name, "five due
   tonight" — never "productivity app".
5. **Lead with the job, the failure or the artifact. Never the product name.**
6. **Face is optional for product demos and required for testimonials.** Decide
   before casting, not in the edit.
7. **Comment keywords are part of the funnel.** "What app?", "is it free?", "drop
   the code". Write toward one of those, deliberately.
8. **The hook must land muted.** Most of these are watched with the sound off.

Two hard boundaries the research also proved:

- **The biggest video in the window was a cheat-extension meme at 21.1M views.**
  That is a warning, not a template. A Canvas tool whose whole claim is "reads
  nothing, sends nothing" cannot sit next to cheating, four months after a breach
  that took 275 million records.
- **Never claim grades improve.** No evidence exists, and it converts a marketing
  problem into a store-policy one.

## Two rules about running the bots

- **Fix the facts file, never the chat.** One edit to `grok-FACTS.md` corrected
  both Reel and Storefront. That is the architecture working.
- **Every product mechanic in the facts file carries a `file:line` citation, or it
  does not go in the file.** The feeding error reached an App Store subtitle
  because nobody had checked the loop in the code.

---

## What the research did not answer

Say these out loud so nobody assumes they are settled.

- **Whether Look Card / palette-code share works at all.** Scout ranked it first
  and then reported that no in-window BetterCampus short with real reach exists.
  It is our only share unit and it is faceless, which is why it is worth testing —
  but it is a hypothesis with zero evidence behind it.
- **Whether the pet lane travels cold.** The only evidence is Finch's own brand
  Shorts at 8K to 35K views, from an account that already has an audience.
- **Whether any of this reaches a buyer.** High schoolers make the videos and
  cannot be sold to. The forecast says a breakout video adds two to five payers.
  Fall is a proof cohort. Nothing in this list changes that.
- **The Look Card creation flow in the extension.** Never verified. Scripts show
  finished Look Cards only, which is a workaround, not an answer.

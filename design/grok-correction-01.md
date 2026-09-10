# Correction 01 — both bots inherited two bad facts from me

2026-09-10. Reel and Storefront both did good work on a facts file that had two
errors in it. Both errors are mine, from `grok-FACTS.md`. Both are now fixed in the
file. Send the blocks below.

## The two errors

**1. Sprout does not eat.** I wrote "finishing schoolwork feeds a pet fish called
Sprout." There is no feeding in the app. Verified in the code today: no feed
function, no hunger state, no food asset, nothing.

The real loop: finish a Canvas task, earn **30 coins** (a study task pays 20). The
coins fly up over the tank on the Home screen. Coins buy the five tank scenes
(Lagoon free, Reef 200, Kelp 220, Dusk 250, Deep 280), costumes and looks.
`AppState.swift:806`, `Models.swift:114`, `Theme.swift:207-216`.

This one matters most in Storefront's pack, because "Feed Sprout" is in the App
Store **subtitle**. That would ship a false product claim into the listing.

**2. The slime blocker is cleared.** I wrote that the extension still draws the old
slime. It was fixed in commit `edf422c`, "Extension draws Sprout, not the slime".
The word "slime" appears nowhere in `extension/`. `content.js` line 1 says it puts
Sprout on screen.

So every "crop the slime out", "don't show extension UI" and "prefer Look Cards
until the port lands" rule in both outputs is obsolete. The extension is shootable
and screenshottable as-is. This *unblocks* the strongest visual Prepkin has: the
real before-and-after.

---

## Block 1 — send to any one bot, with the updated grok-FACTS.md attached

```text
Overwrite /workspace/prepkin/FACTS.md with this attached version. Two facts were
wrong in the old one and you both built on them.

1. Sprout does NOT eat. There is no food, hunger, feeding or meter. Finishing a
   Canvas task earns 30 coins. Coins buy tank scenes, costumes and looks. Never
   write "feed Sprout", "Sprout eats", "Sprout is hungry" or "fish fed" again.
2. The slime blocker is gone. The extension draws Sprout now, commit edf422c.
   Showing the extension UI is fine. Ignore every instruction to avoid it or crop
   around it.

Confirm the overwrite with `ls -la /workspace/prepkin/`, then tell me in two lines
what the reward loop is and whether the extension is shootable. Then stop.
```

---

## Block 2 — send to Reel

```text
FACTS.md has been overwritten. Re-read it before you touch anything.

Two things changed and they hit your batch hard.

FIRST: Sprout does not eat. Six of your ten scripts end on a feeding beat that
does not exist in the app. The real beat is coins: finish a task, 30 coins fly up
over the tank, and coins buy scenes and costumes. Rewrite the endings of scripts
3, 4, 7, 8, 9 and 10.

The replacement beat, and it is a better one: "one assignment, 30 coins, 170 to go
until Reef." That is a real number, it shows progress, and it never touches a
grade claim. "Fish doesn't grade me" from script 10 is your best line in the batch.
Keep it.

SECOND: the slime blocker is cleared. The extension draws Sprout. Delete every
"slime cropped out" note and stop preferring Look Cards for that reason. The
before-and-after of real ugly Canvas turning into real skinned Canvas is now our
strongest shot. Use it.

Keep as written: scripts 1, 2 and 5. "Dark Academia" in script 2 is a real theme
name, one of 26 in extension/themes.js. Others you can name: Lo-fi, Matcha,
Cottage, Midnight, Cherry Blossom, Vaporwave, Graffiti, Rainy Cafe, Spirit Forest.

Fix script 6. It says "i pick a new one when the semester turns", which implies
scenes are free. Four of the five cost coins. Rewrite it as saving up for one.

Answers to the five things you flagged:
1. The tank home screen is called "Home". That is the tab name in the code.
2. Assignment complete is: check it off in the app, coins appear over the tank.
   Canvas submit does not trigger anything by itself. Do not script a
   Canvas-submit-then-app-reacts sequence, because that is not how it works.
3. There is no official hungry state, because there is no hunger. Pout, curious and
   cheer exist as expressions. Use them as mood, never as hunger.
4. The five tank scenes are Lagoon, Reef, Kelp, Dusk, Deep. They are called SCENES.
   Careful: those same five words are also the league tier names. Different things.
5. Look Card creation flow: not verified yet. Keep showing finished Look Cards only.

Redeliver the six rewritten scripts. Do not touch the four that are fine.
```

---

## Block 3 — send to Storefront

```text
FACTS.md has been overwritten. Re-read it. One product fact you built on was wrong
and it reached your highest-value copy.

Sprout does not eat. There is no feeding in the app. Finishing a Canvas task earns
30 coins, and coins buy tank scenes, costumes and looks.

Every line with "feed" or "feeds" is a false product claim and has to go. That is:
- the App Store subtitle, "Finish work. Feed Sprout."
- the promo text
- the App Store description, first line and body
- What's New, bullet one
- the Chrome detailed description
- screenshot 2, "Check-off → feed"
- the support page

Rewrite them around coins and the tank. The honest sentence is "finish schoolwork,
earn coins, make Sprout's tank yours." Give me three subtitle options under 30
characters.

Second: the slime blocker is cleared. The extension draws Sprout, commit edf422c.
Drop the "no slime-mascot extension UI" risk from the screenshot plan. Screenshot 2
can be the real before-and-after now, which is the best asset we have.

Third, answers to your CONFIRM flags, checked in the code today:

- Contact Info: NO. There is no email, no sign-in, no account, no Sign in with
  Apple anywhere in the iOS app. Mark it Data Not Collected. Your draft had it as
  "Likely Yes" and that is wrong.
- Identifiers: a pairing CODE, not a user id or a device id. Nicknames never leave
  the phone that typed them.
- Usage Data and Diagnostics: NO. There are zero analytics SDKs in the app. No
  Firebase, Amplitude, Mixpanel, Sentry or PostHog.
- User Content, coursework and course grades when paired: YES. That one stands and
  it is the reason Chrome cannot say "no data collected".
- Purchases: yes, StoreKit.

So the privacy label is much emptier than your draft. Redo the table with those
five answers. An honest empty label is an asset for us, not a gap to hedge.

Keep everything else. The character limits, the skin-versus-sync separation, the
"never no data collected" rule and the review-response stubs are all good work.
```

---

## What I got wrong and why it spread

I wrote the facts file from memory and from the launch plan, and never checked the
reward loop or the extension's mascot in the code. Both bots followed the file
exactly, which is what they were built to do. The file being the single source of
truth is the reason one edit fixes both of them, so the architecture worked. The
input did not.

Rule going forward: any product mechanic in `grok-FACTS.md` gets a file and line
number next to it, or it does not go in the file.

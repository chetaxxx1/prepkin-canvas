# Prepkin Canvas — brief preamble

Paste this block first, every time, before any screen brief. Then paste one brief.
One screen per request.

---

You are designing one screen, with its states, for **Prepkin Canvas**, a SwiftUI iPhone
app. The whole repo is public at `github.com/chetaxxx1/prepkin-canvas` (branch `main`).
Read it before you draw. You do not write Swift; Claude Code ports your handoff.

## What the app is

A companion app for high school students. A small mascot, the **kin**, lives on the home
screen like Finch's bird. Real Canvas LMS assignments sync in through a Chrome extension
and appear as tasks. Finishing daily tasks — school work and life care — earns coins.
Coins grow the kin (three stars) and adopt new kin and room scenes. Six tabs: Home,
Focus, Games, Learn, Friends, Kin. No accounts. Nothing is ever taken away.

## Read these files first

- `ios/Sources/Theme.swift` — every colour, font and radius, by name. Use those names.
- `ios/Sources/KinComponents.swift`, `PrepkinIcons.swift`, `HomeView.swift`,
  `DayEditorView.swift`, `FriendsView.swift` — the named components. Reuse them by
  name (`WalletChip`, `StarPips`, `TierPlate`, `KinCostBadge`, `GlassPill`, `KinToast`,
  `CoinDisc`, `TaskRow`, `CategoryIcon`, `KinChip`, `SproutFace`, `CareButton`).
  Do not restyle a component that exists.
- `ios/Sources/Models.swift`, `Core/GameState.swift`, `Core/TaskTemplate.swift`,
  `CanvasSync.swift` — the only data the app has. Design against real fields. Never
  invent a stat, a preset list, or a number the app could not already know. Never ask
  the student to type a number the app could work out.
- `design/screenshots/` — the app as it runs today (`18`–`23` are the newest).
- The most recent finished handoffs, for the level to match:
  `design/handoff-kin/README.md`, `design/handoff-friends/README.md`,
  `design/handoff-first-run/README.md`.

## The mascot — never draw it

The kin is **Sprout**, a finished character rendered from real assets by `SproutImage`
(still) and `SproutView` (animated, Home only). Wherever a kin appears, draw a **dashed
box labelled KIN** at the size you intend and name the coat and star count in a caption.
Never sketch, restyle or approximate the character.

Six coats map to the six species: slime → mint (free, Common), Ember → coral (Uncommon),
Droplet → sky (Rare), Sprout → peach (Rare), Wisp → lilac (Epic), Comet → butter
(Legendary). Three evolutions = three stars. Emotes that exist and can be called by name:
idle, bounce, celebrate, wave, sleep, dance, peek, startle, slump.

## Canvas and chrome

- iPhone **402×874 pt**. Content starts at **y = 99** (59 status bar + 40 title row).
  Keep **90 pt clear** above the tab bar.
- The tab bar is `RootView.tabBar`: cream, six full-colour object icons, settled. Do not
  redraw it. It hides on pushed screens and full-screen moments.
- Never draw a fake iOS status bar or a fake keyboard. **No emoji anywhere.** Every icon is
  a drawn vector in the palette.
- Type is SF Pro Rounded (`Theme.font`), weights 600–900. Nunito may stand in inside the
  HTML prototype.

## Rules you must not break

- Coins pay for **finishing**, never for grades, correct answers, or beating a friend.
- **No meters.** Nothing decays. The kin is never hungry, sad, neglected or punished.
- **No streaks, no countdowns, no padlocks, no `?` tiles.** Every number shown can only
  go up. "New picks tomorrow" is the most urgency allowed.
- **No free text between students.** Anything a student can send is chosen from a fixed
  set of drawn cards. No DMs, no captions, no photos, no camera.
- **Ranking is opt-in, never the default.** The default social number is a group total.
- Copy is plain, warm, no exclamation marks, no engineering words ("sync", "M2",
  "bridge"). A student should never read a roadmap.

## What to return

One screen per handoff, as a `.dc.html` prototype plus a `README.md` in the same shape as
`design/handoff-kin/README.md`: overview · fidelity · layout per artboard with pt values ·
tokens by `Theme` name · reused components by name · state · every string of copy ·
interactions and motion with durations and curves · a Reduce Motion note · deviations
and why. Claude Code ports it to SwiftUI and writes `BUILD-NOTES.md` back into the same
folder.

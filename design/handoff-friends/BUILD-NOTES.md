# Build notes — Friends tab

Ported to SwiftUI on 2026-09-03 from `Friends Tab.dc.html` + `README.md` in this
folder. The HTML is a design reference, not shipped code.

## What changed in the app

| File | Change |
| --- | --- |
| `ios/Sources/FriendsView.swift` | Rewritten. Both artboards. |
| `ios/Sources/PrepkinIcons.swift` | Added `ClapGlyph`, `AddFriendGlyph`, and a cubic-curve `Path.arc` helper. |
| `ios/Sources/Core/GameState.swift` | Added `friendCode` + `ensureFriendCode()`. |
| `ios/Sources/AppState.swift` | Exposed `friendCode` / `ensureFriendCode()`. |

Nothing else was touched. `RootView.tabBar` and the five shipped `TabIcon`
objects are unchanged.

## Departures from the README

1. **`friendCode` is a new persisted field, not `pairingCode`.** The pairing code
   ties this phone to one laptop and `unpair()` throws it away. A friend code is
   the person, and disconnecting Canvas must not change it. Same generator, same
   32-character alphabet (`PairingCode`), so the "codes skip I, O, 0 and 1" rule
   in the helper line is the real rule and not a copy of it. It is generated the
   first time the tab is opened, then kept.

2. **The `+` in 1b pushes to a screen the handoff did not draw.** The README says
   the button "pushes to the 1a add card" but 1a's add card sits under a "Friends"
   title and a kin card that make no sense on their own. The pushed screen is the
   same 34/900 title row reading **Add a friend**, then that card verbatim. No new
   tokens.

3. **The richer tab icons were not ported.** The HTML adds highlights, under-
   shadows and an ink-8% ground ellipse to all five `TabIcon` objects. The README
   makes that conditional on approval, so the shipped icons stayed. Only the clap
   and add-friend glyphs were drawn.

4. **The copy button keeps SF `doc.on.doc` / `checkmark`.** The README's Add-card
   spec names those symbols explicitly, so the HTML's two-coral-sheets drawing was
   not ported. The button is `DayEditorView.unpairedCard`'s, verbatim.

5. **`cheered` is in-memory only.** "One cheer per friend per day" needs a day key
   and a place to store it; there is no friend bridge to send a cheer to, so a
   cheer resets when the tab is rebuilt. Nothing else in the app reads it.

6. **The `D` sheet tokens are declared again in `FriendsView`.** `DayEditorView.D`
   is `private` to that file. Five of them are duplicated rather than promoted to
   `Theme`, because they are still one handoff's tokens and not the app's.

## Found while testing on device

- **The code field dropped characters.** Formatting inside the `TextField`
  binding's setter keeps the model right but never refreshes what the field
  shows — the student saw raw lowercase with no dash while the helper line
  reacted to a value they could not see. It is back on `onChange`, guarded so it
  only writes when formatting actually changed something.
- **The pushed add screen drew a system navigation bar** over the title. The
  root `ScrollView` hides it; a `navigationDestination` does not inherit that.
  Hidden there too, with its own back chevron above the title.

Verified on `prepkin-today` at 402×874: kin row, board with You pinned, Cheer →
Cheered, copy button, live helper line through empty / partial / I-O-0-1 /
valid, Add → Sent → Add another.

## Still open

- **New art needs sign-off.** `ClapGlyph` and `AddFriendGlyph` are drawn from the
  HTML's SVG. `glyph-signoff.png` in this folder is the reference next to the
  shipped SwiftUI; the paths match, but nobody has approved the glyphs
  themselves.
- **1a is unreachable in the shipped build.** The four sample friends are always
  present, so the zero-friends screen only renders if that list empties. Decide
  whether new installs should start with an empty list.
- **Everything except the friend code is mock.** Names, kins, levels, week coins
  and activity lines are the sample data from the old `FriendsView.swift`. Add,
  Sent and Cheer all change local state and send nothing.

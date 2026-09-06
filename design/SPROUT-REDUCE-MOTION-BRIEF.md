# Brief for the Sprout repo: Reduce Motion in the tank

**Done 2026-09-05.** `Mascot.reduceMotion` in `src/sprite.ts`, `RiverSprite.setReduceMotion`
plus the `prefers-reduced-motion` default in `src/main.ts`, rebuilt into `ios/SproutWeb`
(`index-s6U3bi4U.js`), and `SproutView` pushes the host setting on ready and on change.
Measured on the simulator: over five seconds the fish band changed ~81k pixels with the
setting off and ~11k with it on, the remainder being the blink and the two-pixel breathe.
The Sprout repo change is uncommitted there, like everything else in it.


Decided 2026-09-05 by council (contrarian seat carried it). The iPhone app now stills its
own motion under Reduce Motion (coin flight, tab switch). The tank page cannot, because the
built bundle in `ios/SproutWeb` has no motion hook. This is a WCAG 2.2.2 (AA) gap: ambient
motion for more than five seconds, next to the task list, with no way to stop it.

## The ask, in the Sprout source (`~/Downloads/Sprout-handoff`)

Add `window.RiverSprite.setReduceMotion(on: boolean)` and read
`matchMedia('(prefers-reduced-motion: reduce)')` at boot as the default.

**Drift-only**, not frozen. A frozen fish reads as a dead pet; a resting fish does not.
- No auto-darting, no bubbles, no background or parallax motion.
- Sprout holds place with a slow breathe or fin idle of a few pixels.
- Blink stays.
- Swimming happens only when the student taps (`goTo`): motion the student started is fine.
- Emotes (`play`) still run but without the travel: `happy` lifts 0, `dance` slides 0.

Then `npm run build`, copy `dist/` into `ios/SproutWeb` (all eight folders), and in
`SproutView.swift` call `setReduceMotion` from `@Environment(\.accessibilityReduceMotion)`
on `ready` and on change. Verify: `xcrun simctl spawn <udid> defaults write
com.apple.Accessibility ReduceMotionEnabled -bool true`, relaunch, screenshot Home twice
five seconds apart; the two frames must match except for a blink.

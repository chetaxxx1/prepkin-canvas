# Claude Design brief: a dark paper for the iPhone app

Paste `CLAUDE-DESIGN-PREAMBLE.md` first. One screen per request; start with Home.

## Why

The app is light only today (`ios/project.yml`, `UIUserInterfaceStyle = Light`, decided
2026-09-05 by council). PRODUCT.md names dark as accessibility, never behind coins, and the
student in the brief is on a bed at 11pm. The extension already ships Carbon (`DESIGN.md`).
The phone should get the same paper, but it is art work, not a token swap: the tank plates,
the four scene paintings, the kin coats and the coral / coin ramps were all tuned on cream.

## The ask

Design Home in a dark paper that reads as the same lamp, turned down.

- Ground: Carbon `#17191D`, raised `#1E2126`, sunk `#121417`, hairline `#2C3037`, ink
  `#E6E8EA`, second ink `#B4BAC1` (from `DESIGN.md`, the extension's dark pair).
- Accent stays coral for action, mint for done, coin for coins. Show each on the dark ground
  at AA; shift toward the text-safe forms (`#7FDDB8` mint, `#ECB35C` coin) where the light
  ones fail.
- The tank keeps its painting. Show what the plate's cream floor hands off to when the page
  below is Carbon: a darker ramp, not a hard edge. The kin is still the most saturated thing
  on screen.
- Chips over the tank (name, tier, coins) flip to light-on-dark glass, as Kin already does on
  its dark scenes (`GlassPill(onDark:)`).
- Nothing else changes: same layout, same type (SF Pro Rounded), same copy.

## Hand back

One Home artboard, light and dark side by side, and the token table with the dark values
filled in. Then Focus, Learn and the Shop sheet, one per request, in that order.

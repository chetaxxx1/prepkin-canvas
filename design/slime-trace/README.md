# Slime trace pipeline

Turns the approved renders in `~/Desktop/mascot/slime-handoff/` into the bezier
path data baked into `ios/Sources/SlimeView.swift`. Never hand-edit that data —
change the reference renders (with approval), then re-run this.

1. `python3 trace.py` — thresholds the palette colors in `mascot-idle.png` and
   `approved-expressions.png`, traces each shape's contour (Moore boundary +
   Gaussian smoothing), fits cubic beziers (Schneider), and writes
   `trace_result.json` (all coords normalized to the character bounding box).
2. `python3 emit_swift.py` — writes `ios/Sources/SlimeView.swift` around the
   traced data. NOTE: it regenerates the whole file, so port any later
   hand-edits to the view code back into this script's template first.
   After regenerating, re-add `import UIKit` if missing.
3. `python3 verify.py` — rasterizes the fitted beziers and diffs against the
   source pixels (expect IoU > 0.99, max deviation ~2px at 886px wide).
4. Optional visual proof: `swiftc -O -parse-as-library -o harness harness_main.swift art_extract.swift`
   where `art_extract.swift` is `import SwiftUI` + everything from
   `/// Renders pre-traced` to the end of SlimeView.swift. Renders each
   expression to PNG at the reference size; `diff_swift.py` diffs them.

Fit quality shipped in Aug 2026: body IoU 0.9966 (max 2px off at 886px wide),
belly 0.992, all four faces within 2px of the approved sheet. Palette exact:
#51CFA0 / #B1EDD4 / #101820.

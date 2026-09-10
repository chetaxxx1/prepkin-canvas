#!/usr/bin/env bash
# iOS UI sweep: screenshots + accessibility trees for every tab, in light, dark,
# and at the largest accessibility text size. Then a contact sheet and a lint.
#
#   test/ios-sweep.sh [udid] [outdir]
#
# Defaults to the prepkin-fresh simulator. NEVER point this at prepkin-today
# (George's real data) without asking. Needs idb (brew install idb-companion)
# and Pillow (python3 -m pip install pillow). Coordinates are iPhone 17 Pro
# points (402 x 874); the tab bar centres are y=805, x=47,107,167,227,287 and Kin at
# 361 (six tabs since Calendar landed on 2026-09-09 — measured with idb, not guessed).
set -euo pipefail
U="${1:-5982E2BF-C16C-4243-B049-26D1FA73FC07}"
OUT="${2:-design/screenshots/sweep-$(date +%Y-%m-%d)}"
mkdir -p "$OUT"
TABS="47:home 107:focus 167:learn 227:calendar 287:friends 361:kin"

shot() { sleep 1.4; xcrun simctl io "$U" screenshot "$OUT/$1.png" >/dev/null 2>&1
         idb ui describe-all --udid "$U" > "$OUT/$1.json" 2>/dev/null || true; echo "  $1"; }
tap()  { idb ui tap "$1" "$2" --udid "$U"; }
sweep(){ for t in $TABS; do tap "${t%%:*}" 805; shot "$1-${t##*:}"; done; }

xcrun simctl launch "$U" com.prepkin.canvas >/dev/null 2>&1 || true; sleep 2
echo "light";  xcrun simctl ui "$U" appearance light;  sweep light
tap 47 805; sleep 1; tap 326 81;  shot light-shop        # coin chip -> Shop
tap 39 81; sleep 1                                       # the Shop's own X. A swipe
                                                         # leaves it up, and then the
                                                         # next tap lands inside it.
tap 369 429; shot light-yourday                          # Edit your day
tap 334 110; sleep 1                                     # Done. A swipe leaves the
                                                         # sheet up and every dark
                                                         # shot then lands on it.
echo "dark";   xcrun simctl ui "$U" appearance dark;   sweep dark
xcrun simctl ui "$U" appearance light
echo "ax-xl";  xcrun simctl ui "$U" content_size accessibility-extra-large; sweep axxl
tap 47 805; sleep 1; tap 326 81;  shot axxl-shop                # the sheets grow too
tap 39 81; sleep 1
tap 369 429; shot axxl-yourday
tap 334 110; sleep 1                                            # Done (the sheet is taller at AX-XL)
tap 167 805; sleep 1; tap 201 275; sleep 1.5
idb ui describe-all --udid "$U" 2>/dev/null | grep -q '"AXLabel":"Start"' && tap 201 777 2
shot axxl-lesson
tap 40 90; sleep 1                                              # close the deck
xcrun simctl ui "$U" content_size medium
tap 47 805

python3 - "$OUT" <<'PY'
import json, glob, os, sys
from PIL import Image, ImageDraw
out = sys.argv[1]
for prefix in ("light", "dark", "axxl"):
    files = sorted(glob.glob(f"{out}/{prefix}-*.png"))
    if not files: continue
    W = 300; th = []
    for f in files:
        im = Image.open(f); r = W / im.width
        th.append((os.path.basename(f)[:-4], im.resize((W, int(im.height * r)))))
    H = th[0][1].height; cols = 4; rows = (len(th) + cols - 1) // cols
    s = Image.new("RGB", (cols * (W + 16) + 16, rows * (H + 40) + 16), "#EDE7DC"); d = ImageDraw.Draw(s)
    for i, (n, t) in enumerate(th):
        x = 16 + (i % cols) * (W + 16); y = 16 + (i // cols) * (H + 40)
        s.paste(t, (x, y)); d.text((x, y + H + 8), n, fill="#2E2622")
    s.save(f"{out}/contact-{prefix}.png")
print("\nlint (light):  screen | buttons under 44pt | unlabeled buttons+images")
for f in sorted(glob.glob(f"{out}/light-*.json")):
    d = json.load(open(f)); n = os.path.basename(f)[:-5]
    small = [(e.get("AXLabel"), round(e["frame"]["width"]), round(e["frame"]["height"]))
             for e in d if e.get("type") == "Button" and (e["frame"]["width"] < 44 or e["frame"]["height"] < 44)]
    unl = sum(1 for e in d if e.get("type") in ("Button", "Image") and not e.get("AXLabel"))
    print(f"  {n} | {small} | {unl}")
PY
echo "done -> $OUT"

"""Contact sheets and the lint for this folder, the same checks `test/ios-sweep.sh` runs.

    python3 design/screenshots/kin-redesign-2026-09-11/sheet.py

Sheets: contact-light.png, contact-dark.png, contact-axxl.png. Lint, per accessibility
dump: buttons under 44pt, unlabeled buttons and images, strings 40 characters or
longer, the banned words, and any "?" on its own.
"""
import glob, json, os, re, pathlib
from PIL import Image, ImageDraw

OUT = pathlib.Path(__file__).parent
BANNED = re.compile(r"\b(sync|syncing|bridge|endpoint|selector|api|token|schema|payload|streak|behind|catch up)\b", re.I)

for prefix in ("light", "dark", "axxl"):
    files = sorted(glob.glob(str(OUT / f"{prefix}-*.png")))
    if not files:
        continue
    W = 300
    th = []
    for f in files:
        im = Image.open(f)
        r = W / im.width
        th.append((os.path.basename(f)[:-4], im.resize((W, int(im.height * r)))))
    H = max(t.height for _, t in th)
    cols = 4
    rows = (len(th) + cols - 1) // cols
    s = Image.new("RGB", (cols * (W + 16) + 16, rows * (H + 40) + 16), "#EDE7DC")
    d = ImageDraw.Draw(s)
    for i, (n, t) in enumerate(th):
        x = 16 + (i % cols) * (W + 16)
        y = 16 + (i // cols) * (H + 40)
        s.paste(t, (x, y))
        d.text((x, y + H + 8), n, fill="#2E2622")
    s.save(OUT / f"contact-{prefix}.png")
    print("sheet", f"contact-{prefix}.png", len(th))

print("\nlint: screen | buttons under 44pt | unlabeled buttons+images | long strings | banned")
for f in sorted(glob.glob(str(OUT / "*.json"))):
    try:
        d = json.load(open(f))
    except Exception:
        continue
    n = os.path.basename(f)[:-5]
    small = [(e.get("AXLabel"), round(e["frame"]["width"]), round(e["frame"]["height"]))
             for e in d if e.get("type") == "Button"
             and (e["frame"]["width"] < 44 or e["frame"]["height"] < 44)
             # The system share sheet and the tab bar are not this screen's.
             and (e.get("AXLabel") or "") not in ("Sheet Grabber",)]
    unl = [e.get("type") for e in d if e.get("type") in ("Button", "Image") and not e.get("AXLabel")]
    long_ = [e.get("AXLabel") for e in d if e.get("type") == "StaticText"
             and e.get("AXLabel") and len(e["AXLabel"]) >= 40]
    banned = [e.get("AXLabel") for e in d if e.get("AXLabel") and (BANNED.search(e["AXLabel"]) or e["AXLabel"].strip() == "?")]
    print(f"  {n} | {small} | {len(unl)} | {long_} | {banned}")

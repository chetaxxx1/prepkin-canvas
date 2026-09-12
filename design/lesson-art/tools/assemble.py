#!/usr/bin/env python3
"""Build a lesson into the app: imagesets for every picture card, then its entry in
lessons.json.

  python3 tools/assemble.py work-4 hlth-1
  python3 tools/assemble.py work-4 --dry      (report only, write nothing)

Refuses a lesson whose pictures are not all on disk, so a half-painted deck can never
ship with a blank card. Figures come from figures.py (run it first); paintings come from
Ink through tools/unpack.py. Existing lessons with the same id are replaced in place; a
new id lands after the last lesson of its track, or at the end for a new track.
"""
import json, os, sys
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import plan as P

REPO = os.path.dirname(os.path.dirname(P.ROOT))
ASSETS = os.path.join(REPO, "ios", "Resources", "Assets.xcassets")
LESSONS = os.path.join(REPO, "ios", "Resources", "Content", "lessons.json")

def imageset(name, src, dry):
    d = os.path.join(ASSETS, name + ".imageset")
    im = Image.open(src).convert("RGB")
    if im.size != (1200, 900):
        raise SystemExit(f"{src}: {im.size}, want 1200x900 (run tools/unpack.py on paintings)")
    if dry: return
    os.makedirs(d, exist_ok=True)
    for f in os.listdir(d):
        if f != "Contents.json": os.remove(os.path.join(d, f))
    im.save(os.path.join(d, name + ".jpg"), "JPEG", quality=85, optimize=True)
    json.dump({"images": [{"filename": name + ".jpg", "idiom": "universal"}],
               "info": {"author": "xcode", "version": 1}},
              open(os.path.join(d, "Contents.json"), "w"), indent=2)

def merge(entries, dry):
    data = json.load(open(LESSONS))
    for e in entries:
        idx = next((i for i, x in enumerate(data) if x["id"] == e["id"]), None)
        if idx is not None:
            data[idx] = e; continue
        last = max((i for i, x in enumerate(data) if x["track"] == e["track"]), default=None)
        data.insert(len(data) if last is None else last + 1, e)
    if not dry:
        with open(LESSONS, "w") as f:
            json.dump(data, f, indent=2, ensure_ascii=False); f.write("\n")
    return len(data)

def main():
    dry = "--dry" in sys.argv; ids = [a for a in sys.argv[1:] if not a.startswith("--")]
    entries = []
    for lid in ids:
        L = P.load(lid); missing = []
        for n, c in P.image_cards(L):
            src = P.source_path(lid, c)
            if not src: missing.append(c["src"]); continue
            imageset(P.asset_name(lid, n), src, dry)
        if missing:
            print(f"{lid}: NOT built, missing {', '.join(missing)}"); continue
        entries.append(P.to_app_json(L)); print(f"{lid}: {len(P.image_cards(L))} imagesets{' (dry)' if dry else ''}")
    if entries:
        n = merge(entries, dry); print(f"lessons.json: {n} lessons{' (dry)' if dry else ''}")

if __name__ == "__main__":
    main()

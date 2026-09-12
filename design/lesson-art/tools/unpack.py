#!/usr/bin/env python3
"""Move Ink's paintings from the inbox into the lesson folders.

  python3 tools/unpack.py

Drop into design/lesson-art/inbox/ either a zip named after the lesson (work-4.zip) or a
folder named after the lesson (inbox/work-4/p01-inbox.png). This unpacks every picture
into design/lesson-art/<id>/, forces 4:3 (centre crop) and 1200x900, then moves the zip
to inbox/done/. It ends by listing which paintings each plan still lacks.
"""
import os, shutil, sys, zipfile, io
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import plan as P

INBOX = os.path.join(P.ROOT, "inbox"); DONE = os.path.join(INBOX, "done")
IMG = (".png", ".jpg", ".jpeg", ".webp")

def normalise(im):
    """4:3 by centre crop, then no larger than 1200x900. Returns (image, note)."""
    im = im.convert("RGB"); w, h = im.size; note = ""
    if abs(w / h - 4 / 3) > 0.01:
        if w / h > 4 / 3:
            nw = int(h * 4 / 3); im = im.crop(((w - nw) // 2, 0, (w - nw) // 2 + nw, h)); note = f"cropped {w}x{h} to 4:3"
        else:
            nh = int(w * 3 / 4); im = im.crop((0, (h - nh) // 2, w, (h - nh) // 2 + nh)); note = f"cropped {w}x{h} to 4:3"
    if im.size[0] < 1200: note += f" SMALL {im.size[0]}x{im.size[1]}"
    if im.size[0] != 1200: im = im.resize((1200, 900), Image.LANCZOS)
    return im, note.strip()

def place(lesson_id, name, data):
    stem = os.path.splitext(os.path.basename(name))[0]
    dest = os.path.join(P.folder(lesson_id), stem + ".png")
    os.makedirs(P.folder(lesson_id), exist_ok=True)
    im, note = normalise(Image.open(io.BytesIO(data)))
    im.save(dest, "PNG")
    print(f"  {lesson_id}/{stem}.png  {note}")

def main():
    os.makedirs(DONE, exist_ok=True)
    for entry in sorted(os.listdir(INBOX)):
        path = os.path.join(INBOX, entry)
        if entry == "done" or entry.startswith("."): continue
        if entry.lower().endswith(".zip"):
            lid = entry[:-4]
            print(f"{entry}:")
            with zipfile.ZipFile(path) as z:
                for n in z.namelist():
                    base = os.path.basename(n)
                    if "__MACOSX" in n or base.startswith(".") or not base.lower().endswith(IMG): continue
                    place(lid, base, z.read(n))
            shutil.move(path, os.path.join(DONE, entry))
        elif os.path.isdir(path):
            lid = entry; print(f"{entry}/:")
            for f in sorted(os.listdir(path)):
                if f.startswith(".") or not f.lower().endswith(IMG): continue
                place(lid, f, open(os.path.join(path, f), "rb").read())
            shutil.move(path, os.path.join(DONE, entry + "-" + str(int(os.path.getmtime(path)))))
    print("\nStill owed:")
    owed = 0
    for d in sorted(os.listdir(P.ROOT)):
        if d == "tools" or not os.path.exists(os.path.join(P.ROOT, d, "plan.py")): continue
        L = P.load(d)
        missing = [c["src"] for n, c in P.paintings(L) if not P.source_path(d, c)]
        if missing: owed += len(missing); print(f"  {d}: {', '.join(missing)}")
    if not owed: print("  nothing. Every planned painting is in.")

if __name__ == "__main__":
    main()

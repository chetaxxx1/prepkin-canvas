#!/usr/bin/env python3
"""Recraft test: what a redone Sprout could look like. See BRIEF.md.

    python3 design/mascot-recraft/gen.py            # all variants, one roll each
    python3 design/mascot-recraft/gen.py v2 v3 -n 3 # named variants, three rolls
    python3 design/mascot-recraft/gen.py --sheet    # rebuild sheet.png only
"""
import json, os, re, subprocess, sys, time, urllib.request
HERE = os.path.dirname(os.path.abspath(__file__))
SVG, PRE = os.path.join(HERE, "svg"), os.path.join(HERE, "preview")
TOKEN = open(os.path.expanduser("~/.config/recraft/token")).read().strip()
API = "https://external.api.recraft.ai/v1/images/generations"

BASE = ("A small pear-shaped chibi fish mascot, one soft rounded blob body, a pale oval belly, "
        "two short rounded side fins, a single tiny two-leaf sprout growing from the top of the head. "
        "Exactly one character, front view, centred, filling 70 percent of the frame, no background, "
        "no text, no shadow, no extra objects. Companion mascot for a study app for 19 to 24 year olds: "
        "cute but calm and a little cool, never babyish, no blush marks. ")

# id -> (variant prompt, main colour, belly colour)
V = {
  "v1_sage":     ("Matte sage green body, two small wide-set black dot eyes, a small flat resting mouth. Flat vector, no outline, soft matte colours.", (0x7F,0xB8,0x9A), (0xD6,0xEB,0xDC)),
  "v2_deadpan":  ("Matte sage green body, two small half-lidded eyes glancing slightly to the side, a flat unimpressed mouth. Flat vector, no outline.", (0x7F,0xB8,0x9A), (0xD6,0xEB,0xDC)),
  "v3_slate":    ("Slate blue body, small wide-set eyes, the tiniest confident smirk, one side fin with a small notch bitten out of its edge. Flat vector, no outline.", (0x5C,0x7F,0xA0), (0xD3,0xE0,0xEC)),
  "v4_plush":    ("Sage green body with soft two-tone matte shading like a plush toy, small dot eyes, flat mouth, gentle and squishy. Flat vector, no outline.", (0x7F,0xB8,0x9A), (0xD6,0xEB,0xDC)),
  "v5_sticker":  ("Sage green body, thick dark even outline on every shape like a sticker, small dot eyes, flat mouth, bold and graphic. Flat vector sticker style.", (0x7F,0xB8,0x9A), (0xD6,0xEB,0xDC)),
  "v6_bean":     ("Very minimal: just the sage bean body, two small dot eyes, a flat mouth and the sprout, fins barely there. Like a simple bean character. Flat vector, no outline.", (0x7F,0xB8,0x9A), (0xD6,0xEB,0xDC)),
  "v7_terra":    ("Terracotta orange body, small eyes looking slightly to one side, tiny smirk, the sprout leaning to one side. Flat vector, no outline.", (0xD9,0x8C,0x6B), (0xF3,0xDC,0xCF)),
  "v8_lilac":    ("Dusty lilac body with a subtle soft grain texture and one soft shading tone, small calm eyes, flat mouth. Flat vector, no outline.", (0x9C,0x8D,0xB8), (0xE3,0xDC,0xEE)),
}
MODELS = ["recraftv4_1_vector", "recraftv3"]

# Round 2: one face spec, locked style (style.json made from the best round-1 rolls),
# five coats + three emotes. Tests whether Recraft can hold ONE character across a set.
FACE = ("Small wide-set black dot eyes, a small flat resting mouth, no blush. Flat vector, no outline, matte colours. ")
FAMILY = {
  "f_sage":  ("Sage green body. " + FACE, (0x7F,0xB8,0x9A), (0xD6,0xEB,0xDC)),
  "f_slate": ("Slate blue body. " + FACE, (0x5C,0x7F,0xA0), (0xD3,0xE0,0xEC)),
  "f_terra": ("Terracotta orange body. " + FACE, (0xD9,0x8C,0x6B), (0xF3,0xDC,0xCF)),
  "f_lilac": ("Dusty lilac body. " + FACE, (0x9C,0x8D,0xB8), (0xE3,0xDC,0xEE)),
  "f_mustard": ("Mustard yellow body. " + FACE, (0xC9,0xA8,0x3E), (0xF1,0xE6,0xC0)),
  "e_happy": ("Sage green body, eyes closed into two happy upward arcs, a small open smile, fins raised. Flat vector, no outline, matte colours.", (0x7F,0xB8,0x9A), (0xD6,0xEB,0xDC)),
  "e_sleepy": ("Sage green body, eyes closed into two flat sleepy lines, a tiny o mouth, body slumped slightly. Flat vector, no outline, matte colours.", (0x7F,0xB8,0x9A), (0xD6,0xEB,0xDC)),
  "e_shock": ("Sage green body, two small wide round eyes, a small round o mouth, fins out, sprout standing straight up. Flat vector, no outline, matte colours.", (0x7F,0xB8,0x9A), (0xD6,0xEB,0xDC)),
}
STYLE_ID = json.load(open(os.path.join(HERE, "style.json"))).get("id") if os.path.exists(os.path.join(HERE, "style.json")) else None

def call(body):
    for _ in range(8):
        req = urllib.request.Request(API, data=json.dumps(body).encode(),
              headers={"Authorization": f"Bearer {TOKEN}", "Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=180) as r: return json.load(r)
        except urllib.error.HTTPError as e:
            msg = e.read().decode()
            m = re.search(r"doesn't support the '(\w+)' control", msg)
            if m and m.group(1) in body.get("controls", {}):
                del body["controls"][m.group(1)]; continue
            print(f"HTTP {e.code} {msg[:300]}"); return None
    return None

def gen(vid, roll, model):
    p, main, belly = (V | FAMILY)[vid]
    body = {"prompt": BASE + p, "model": model, "size": "1024x1024", "n": 1, "response_format": "url",
            "controls": {"colors": [{"rgb": list(main)}, {"rgb": list(belly)}, {"rgb": [0x2E,0x26,0x22]}],
                         "no_text": True, "transparent_background": True}}
    if vid in FAMILY and STYLE_ID: body["style_id"] = STYLE_ID; body["model"] = model = "recraftv4_styles_vector"
    elif model == "recraftv3": body["style"] = "vector_illustration"
    out = call(body)
    if not out: return None
    data = urllib.request.urlopen(out["data"][0]["url"], timeout=180).read()
    ext = "svg" if data[:200].lstrip().startswith(b"<") else "png"
    os.makedirs(SVG, exist_ok=True); os.makedirs(PRE, exist_ok=True)
    name = f"{vid}-{roll}"
    path = os.path.join(SVG, f"{name}.{ext}"); open(path, "wb").write(data)
    png = os.path.join(PRE, f"{name}.png")
    if ext == "svg":
        subprocess.run(["rsvg-convert", "-w", "512", "-h", "512", "-b", "#F3F1EA", path, "-o", png], check=True)
    else:
        open(png, "wb").write(data)
    print(f"{name}: {len(data)} bytes .{ext} via {model}, credits {out.get('credits')}")
    return png

def sheet(prefix="v", out="sheet.png"):
    from PIL import Image, ImageDraw
    files = sorted(f for f in os.listdir(PRE) if f.endswith(".png") and f.startswith(prefix))
    if not files: return
    cols = 4; cell = 300; rows = (len(files) + cols - 1) // cols
    im = Image.new("RGB", (cols * cell, rows * (cell + 24)), "#F3F1EA"); d = ImageDraw.Draw(im)
    for i, f in enumerate(files):
        t = Image.open(os.path.join(PRE, f)).convert("RGB").resize((cell, cell))
        x, y = (i % cols) * cell, (i // cols) * (cell + 24)
        im.paste(t, (x, y)); d.text((x + 8, y + cell + 4), f[:-4], fill="#2E2622")
    im.save(os.path.join(HERE, out)); print(out, len(files), "tiles")

if __name__ == "__main__":
    a = sys.argv[1:]; n = 1
    if "-n" in a: i = a.index("-n"); n = int(a[i + 1]); del a[i:i + 2]
    if "--sheet" not in a:
        ids = [x for x in a if x in V or x in FAMILY] or (list(FAMILY) if "--family" in a else list(V))
        for vid in ids:
            for r in range(1, n + 1):
                for m in MODELS:
                    if gen(vid, r, m): break
                time.sleep(0.3)
    sheet("v", "sheet.png"); sheet("f", "sheet-family.png"); sheet("e", "sheet-emotes.png")

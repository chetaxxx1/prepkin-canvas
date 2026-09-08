#!/usr/bin/env python3
"""Generate the hero objects for lesson figures as SVG with Recraft.

    python3 design/figure-art/recraft.py ticket burrito        # named objects
    python3 design/figure-art/recraft.py --all                  # every object
    python3 design/figure-art/recraft.py --preview              # PNG previews only

The token lives in ~/.config/recraft/token (never in the repo). SVGs land in
design/figure-art/svg/<id>.svg, PNG previews in design/figure-art/preview/.
Each vector image costs about $0.08. The palette is the figure palette from
LessonFigures.swift so the art sits on the same field as the code-drawn labels.
"""
import json, os, subprocess, sys, time, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
SVG = os.path.join(HERE, "svg"); PREVIEW = os.path.join(HERE, "preview")
# The locked custom style, made from style-refs/. Without it every object is generated
# freehand and the set stops looking like a set — which is what happened the first time.
STYLE_ID = json.load(open(os.path.join(HERE, "style.json")))["style_id"]
TOKEN = open(os.path.expanduser("~/.config/recraft/token")).read().strip()
API = "https://external.api.recraft.ai/v1/images/generations"

# Fig palette (LessonFigures.swift). Ink, then the four masses and the accent.
PALETTE = {
    "ink": (0x2E, 0x26, 0x22), "coin": (0xFF, 0xC2, 0x4B), "coral": (0xFF, 0x6F, 0x61),
    "sky": (0x9B, 0xC8, 0xF2), "leaf": (0xA5, 0xCE, 0x6B), "lav": (0xC3, 0xB2, 0xF0),
    "paper": (0xFF, 0xFF, 0xFF), "faint": (0xD9, 0xCF, 0xC0),
}

STYLE = ("flat vector illustration, one single object, big flat colour shapes, thin dark "
         "outline, no gradients, no shadows, no texture, no text, no letters, no background, "
         "centred, friendly and simple, like a modern educational app illustration")

# id -> (prompt, colours used, most important first)
OBJECTS = {
    "ticket":   ("a cinema admission ticket stub, horizontal, rounded corners, a perforated tear line one third from the left, plain yellow", ["coin", "ink", "paper"]),
    "burrito":  ("a burrito wrapped in a tortilla, side view, one end cut open showing green lettuce, red salsa and rice, warm yellow tortilla with a fold seam", ["coin", "leaf", "coral", "ink"]),
    "ship":     ("a small wooden sailing ship, side view, white sail, hull made of visible horizontal planks, calm and simple", ["faint", "paper", "ink", "coin"]),
    "jar":      ("a glass jar with a yellow lid, seen from the front, a few gold coins at the bottom, mostly empty", ["paper", "coin", "ink"]),
    "heart":    ("a heart shape with a heartbeat pulse line drawn across it in white", ["coral", "paper", "ink"]),
    "trolley":  ("a small red tram trolley, side view, two windows, two black wheels", ["coral", "paper", "ink"]),
    "envelope": ("an open envelope with a letter sticking halfway out, front view", ["coral", "paper", "ink"]),
    "funnel":   ("a funnel, front view, wide at the top narrow at the bottom, plain light blue", ["sky", "ink"]),
    "phone":    ("a smartphone, front view, white body, blank light blue screen", ["paper", "sky", "ink"]),
    "ladder":   ("a short wooden step ladder with three rungs, front view, yellow wood", ["coin", "ink"]),
    "chalkboard": ("an empty green chalkboard with a wooden tray and a piece of white chalk", ["leaf", "faint", "paper", "ink"]),
    "campfire": ("a small campfire, flame in coral and yellow, two dark logs underneath", ["coral", "coin", "ink"]),
    "spotlight": ("a stage spotlight beam, a bright yellow cone of light shining down onto a small round stage", ["coin", "lav", "ink"]),
    "moon":     ("a crescent moon with two small stars", ["coin", "ink"]),
}

def rgb(name): return {"rgb": list(PALETTE[name])}

def generate(oid, model="recraftv4_styles_vector", substyle=None):
    prompt, colours = OBJECTS[oid]
    body = {
        "prompt": f"{prompt}. {STYLE}",
        "model": model,
        "style_id": STYLE_ID,
        "size": "1024x1024",
        "n": 1,
        "response_format": "url",
        "controls": {
            "colors": [rgb(c) for c in colours],
            "no_text": True,
            "transparent_background": True,
        },
    }
    if substyle: body["substyle"] = substyle
    # Newer models reject controls they don't know. Drop the named one and retry.
    for _ in range(6):
        req = urllib.request.Request(API, data=json.dumps(body).encode(),
                                     headers={"Authorization": f"Bearer {TOKEN}", "Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=120) as r: out = json.load(r); break
        except urllib.error.HTTPError as e:
            msg = e.read().decode()
            import re
            m = re.search(r"doesn't support the '(\w+)' control", msg)
            if m and m.group(1) in body["controls"]:
                print(f"{oid}: dropping control {m.group(1)}"); del body["controls"][m.group(1)]; continue
            print(f"{oid}: HTTP {e.code} {msg[:300]}"); return None
    else:
        return None
    url = out["data"][0]["url"]
    os.makedirs(SVG, exist_ok=True)
    data = urllib.request.urlopen(url, timeout=120).read()
    ext = "svg" if data[:200].lstrip().startswith(b"<") else "png"
    path = os.path.join(SVG, f"{oid}.{ext}")
    open(path, "wb").write(data)
    print(f"{oid}: {len(data)} bytes .{ext}, credits {out.get('credits')}")
    return path

def preview(oid):
    os.makedirs(PREVIEW, exist_ok=True)
    src = os.path.join(SVG, f"{oid}.svg"); dst = os.path.join(PREVIEW, f"{oid}.png")
    if os.path.exists(src):
        subprocess.run(["rsvg-convert", "-w", "512", "-h", "512", "-b", "#FFF4DC", src, "-o", dst], check=True)
        return dst

if __name__ == "__main__":
    args = sys.argv[1:]
    model = "recraftv4_styles_vector"
    if "--model" in args:
        i = args.index("--model"); model = args[i + 1]; del args[i:i + 2]
    substyle = None
    if "--substyle" in args:
        i = args.index("--substyle"); substyle = args[i + 1]; del args[i:i + 2]
    ids = list(OBJECTS) if "--all" in args else [a for a in args if not a.startswith("--")]
    if "--preview" in args and not ids: ids = list(OBJECTS)
    for oid in ids:
        if "--preview" not in args:
            generate(oid, model, substyle); time.sleep(0.3)
        p = preview(oid)
        if p: print("preview", p)

#!/usr/bin/env python3
"""Pack Recraft SVGs into the iOS asset catalog as vector image sets.

    python3 design/figure-art/pack.py            # every svg in design/figure-art/svg

For each <id>.svg: drop the C2PA metadata and the full-bleed background path Recraft
always adds, trim the viewBox to the object's own bounds (plus a 2% margin), and
write ios/Resources/Assets.xcassets/fig-<id>.imageset with preserves-vector-representation
so SwiftUI's Image("fig-<id>") scales it crisply at any size. Prints each asset's
aspect ratio, which the figure code needs to place it.
"""
import json, os, re, subprocess, sys, tempfile
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
SVG = os.path.join(HERE, "svg")
ASSETS = os.path.join(HERE, "..", "..", "ios", "Resources", "Assets.xcassets")

def clean(svg):
    svg = re.sub(r"<metadata>.*?</metadata>", "", svg, flags=re.S)
    svg = re.sub(r'\s+xmlns:c2pa="[^"]*"', "", svg)
    # Recraft's background: one axis-aligned path covering the whole viewBox.
    svg = re.sub(r'<path[^>]*d="M 0 0 L 2048 0 L 2048 2048 L 0 2048 L 0 0 z"\s*/>', "", svg)
    return svg

def bounds(svg):
    """Object bounds in viewBox units, from the alpha of a 1024px raster."""
    with tempfile.TemporaryDirectory() as d:
        src = os.path.join(d, "a.svg"); dst = os.path.join(d, "a.png")
        open(src, "w").write(svg)
        subprocess.run(["rsvg-convert", "-w", "1024", "-h", "1024", src, "-o", dst], check=True)
        box = Image.open(dst).getbbox()  # on the RGBA image, transparent = 0
    if not box: raise SystemExit("empty image")
    m = re.search(r'viewBox="0 0 (\d+) (\d+)"', svg); vw = float(m.group(1))
    k = vw / 1024
    x0, y0, x1, y1 = [v * k for v in box]
    pad = 0.02 * max(x1 - x0, y1 - y0)
    return x0 - pad, y0 - pad, x1 + pad, y1 + pad

INK = 'fill="rgb(46,38,34)"'
TARGET_PT = 2.0   # the ink weight of the code-drawn chips and outlines
FIGURES = os.path.join(HERE, "..", "..", "ios", "Sources", "LessonFigures.swift")

def display_box(oid):
    """The (w, h) in figure points that LessonFigures.swift fits this asset into."""
    m = re.search(r'fxArt\("%s", [\d.]+, [\d.]+, ([\d.]+), ([\d.]+)\)' % oid, open(FIGURES).read())
    return (float(m.group(1)), float(m.group(2))) if m else None

def outline_pt(svg, scale):
    """Measured thickness of the outer ink edge, in points, at the display scale."""
    m = re.search(r'viewBox="[\d.\-]+ [\d.\-]+ ([\d.]+) ([\d.]+)"', svg)
    vw, vh = float(m.group(1)), float(m.group(2))
    W, H = max(int(vw * scale * 3), 8), max(int(vh * scale * 3), 8)
    with tempfile.TemporaryDirectory() as d:
        src = os.path.join(d, "a.svg"); dst = os.path.join(d, "a.png")
        open(src, "w").write(svg)
        subprocess.run(["rsvg-convert", "-w", str(W), "-h", str(H), src, "-o", dst], check=True)
        px = Image.open(dst).convert("RGBA").load()
    runs = []
    for fy in (0.3, 0.45, 0.6, 0.75):
        run, started = 0, False
        for xx in range(W):
            r, g, b, a = px[xx, int(H * fy)]
            if a > 200 and r < 90 and g < 80 and b < 80: run += 1; started = True
            elif started: break
        if run: runs.append(run)
    return (sum(runs) / len(runs) / 3) if runs else 0

def thicken(svg, oid):
    """Stroke the ink shapes so the outline lands at TARGET_PT where the figure shows it.
    The first ink path is Recraft's silhouette union: only its outer half shows, so it
    gets twice the width. Later ink paths are interior lines and get the width itself."""
    box = display_box(oid)
    if not box: return svg
    m = re.search(r'viewBox="[\d.\-]+ [\d.\-]+ ([\d.]+) ([\d.]+)"', svg)
    scale = min(box[0] / float(m.group(1)), box[1] / float(m.group(2)))
    have = outline_pt(svg, scale)
    if have > TARGET_PT * 1.5: have = 0.6   # the scan hit a solid ink shape (logs), not an edge
    need = TARGET_PT - have
    if need <= 0.15: return svg
    w = need / scale
    n = [0]
    def stroke(mm):
        n[0] += 1
        width = w * 2 if n[0] == 1 else w
        return mm.group(0) + f' stroke="rgb(46,38,34)" stroke-width="{width:.1f}" stroke-linejoin="round"'
    svg = re.sub(r'<path[^>]*?' + re.escape(INK), stroke, svg)
    print(f"  {oid}: outline {have:.1f}pt -> stroked +{need:.1f}pt ({n[0]} ink paths, w={w:.0f} units)")
    return svg

def pack(oid):
    svg = clean(open(os.path.join(SVG, f"{oid}.svg")).read())
    x0, y0, x1, y1 = bounds(svg)
    w, h = x1 - x0, y1 - y0
    svg = re.sub(r'viewBox="[^"]*"', f'viewBox="{x0:.1f} {y0:.1f} {w:.1f} {h:.1f}"', svg, count=1)
    svg = re.sub(r'\swidth="\d+"\sheight="\d+"', f' width="{w/2:.0f}" height="{h/2:.0f}"', svg, count=1)
    svg = svg.replace(' preserveAspectRatio="none"', "")
    svg = thicken(svg, oid)
    name = f"fig-{oid}"
    d = os.path.join(ASSETS, f"{name}.imageset"); os.makedirs(d, exist_ok=True)
    open(os.path.join(d, f"{name}.svg"), "w").write(svg)
    json.dump({"images": [{"filename": f"{name}.svg", "idiom": "universal"}],
               "info": {"author": "xcode", "version": 1},
               "properties": {"preserves-vector-representation": True}},
              open(os.path.join(d, "Contents.json"), "w"), indent=2)
    print(f"{name}: aspect {w/h:.3f} (w/h), {len(svg)} bytes")

# --- raster scenes (Grok) -----------------------------------------------------

ART_SRC = os.path.join(HERE, "..", "art-src", "figures")

def bg_colour(im):
    """The scene's flat background, read from the four corners."""
    w, h = im.size
    corners = [im.getpixel(p) for p in ((2, 2), (w - 3, 2), (2, h - 3), (w - 3, h - 3))]
    return max(set(corners), key=corners.count)

def raster_outline_pt(im, scale):
    """Median dark-run width in points at the display scale. Runs longer than 12pt are
    fills, not outlines, so they are dropped before taking the median."""
    px = im.convert("RGB").load()
    w, h = im.size
    runs = []
    for fy in (0.25, 0.35, 0.45, 0.55, 0.65, 0.75):
        y, run = int(h * fy), 0
        for x in range(w):
            r, g, b = px[x, y]
            if r < 90 and g < 80 and b < 80: run += 1
            else:
                if run: runs.append(run)
                run = 0
        if run: runs.append(run)
    pts = sorted(r * scale for r in runs if r * scale <= 12)
    return pts[len(pts) // 2] if pts else 0

# Which field each scene sits on, so its background can be recoloured to match exactly.
FIELD = {
    0xFFF4DC: ["slots", "sunk", "paycheck", "brackets", "jar", "burrito"],
    0xEAF4E0: ["filter", "cornell", "feynman", "exam"],
    0xE6F0FB: ["refresh", "loop", "arousal", "trolley", "sleep"],
    0xFFEDE7: ["email", "no", "echo", "ladder", "apology"],
    0xEDE7FB: ["spotlight", "ship", "cave"],
}
FIELD_OF = {i: hexv for hexv, ids in FIELD.items() for i in ids}

def recolour_bg(im, want, tol=20):
    """Repaint the scene's own background to our exact field colour. Grok lands a few
    shades off, and at full bleed that shows as a seam where the field takes over."""
    have = bg_colour(im)
    px = im.load()
    w, h = im.size
    wr, wg, wb = (want >> 16) & 0xFF, (want >> 8) & 0xFF, want & 0xFF
    n = 0
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            if abs(r - have[0]) <= tol and abs(g - have[1]) <= tol and abs(b - have[2]) <= tol:
                px[x, y] = (wr, wg, wb); n += 1
    return n / (w * h)

def pack_raster(oid):
    """Pack one Grok scene as a full-bleed 3x image set. Nothing is trimmed: the empty
    area the prompt reserved is where the figure's labels go."""
    im = Image.open(os.path.join(ART_SRC, f"{oid}.png")).convert("RGB")
    w, h = im.size
    want = FIELD_OF.get(oid)
    share = recolour_bg(im, want) if want else 0
    r, g, b = bg_colour(im)
    name = f"fig-scene-{oid}"
    d = os.path.join(ASSETS, f"{name}.imageset"); os.makedirs(d, exist_ok=True)
    im.save(os.path.join(d, f"{name}@3x.png"), optimize=True)
    json.dump({"images": [{"filename": f"{name}@3x.png", "idiom": "universal", "scale": "3x"}],
               "info": {"author": "xcode", "version": 1}},
              open(os.path.join(d, "Contents.json"), "w"), indent=2)
    # Full bleed across the 360pt canvas is how these are placed.
    scale = 360 / w
    print(f"{name}: {w}x{h} aspect {w/h:.3f}, field 0x{r:02X}{g:02X}{b:02X} "
          f"({share*100:.0f}% repainted), height at full bleed {h*scale:.0f}pt, "
          f"outline ~{raster_outline_pt(im, scale):.1f}pt")

if __name__ == "__main__":
    args = sys.argv[1:]
    if "--raster" in args:
        ids = [a for a in args if not a.startswith("--")] or \
              sorted(f[:-4] for f in os.listdir(ART_SRC) if f.endswith(".png"))
        for oid in ids: pack_raster(oid)
    else:
        ids = args or sorted(f[:-4] for f in os.listdir(SVG) if f.endswith(".svg"))
        for oid in ids: pack(oid)

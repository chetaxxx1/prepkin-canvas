#!/usr/bin/env python3
"""Render a lesson chart to a finished PNG, in the app's own font.

Charts used to be computed here and drawn in Swift from point arrays. That kept type
themeable but meant nothing could be measured: label widths were an estimate, so
"what they budgeted" was drawn wider than the box it sat in and nobody knew until it
shipped. Here the renderer holds the real font, so every string is measured before it
is drawn and a box that cannot hold its label says so.

    from chartkit import Chart
    c = Chart(field="rose")
    ...
    c.save("design/art-src/figures/work-band.png")

Output is 1080x900 for a 360x300 point card, which is the @3x the asset catalogue
wants. Everything is drawn at 3x that and downsampled, because PIL does not antialias
strokes.
"""
import math, os
from PIL import Image, ImageDraw, ImageFont

W, H = 360, 300                      # the figure's point space
SCALE = 3                            # @3x asset
SS = 3                               # supersample on top of that
FONT = "/System/Library/Fonts/SFNSRounded.ttf"

INK = (46, 38, 34)
COIN = (255, 194, 75)
CORAL = (255, 111, 97)
SKY = (155, 200, 242)
SKY_DEEP = (111, 163, 220)
LEAF = (165, 206, 107)
LEAF_DEEP = (132, 179, 69)
LAV = (195, 178, 240)
PAPER = (255, 255, 255)
FAINT = (217, 207, 192)
FIELDS = {"coin": (255, 244, 220), "leaf": (234, 244, 224), "sky": (230, 240, 251),
          "lav": (237, 231, 251), "rose": (255, 237, 231)}

_cache = {}


def font(size, weight="Heavy"):
    key = (round(size * SCALE * SS), weight)
    if key not in _cache:
        f = ImageFont.truetype(FONT, key[0])
        try: f.set_variation_by_name(weight)
        except Exception: pass
        _cache[key] = f
    return _cache[key]


class Chart:
    def __init__(self, field="coin"):
        self.k = SCALE * SS
        self.im = Image.new("RGB", (W * self.k, H * self.k), FIELDS[field])
        self.d = ImageDraw.Draw(self.im, "RGBA")
        self.notes = []
        self.obstacles = []          # every stroke a label has to keep away from
        self.drawn = []              # every box of type already on the card

    # ---- measuring ---------------------------------------------------------------
    def measure(self, s, size, weight="Heavy"):
        """Exact width and cap height of a string, in points."""
        x0, y0, x1, y1 = self.d.textbbox((0, 0), s, font=font(size, weight))
        return (x1 - x0) / self.k, (y1 - y0) / self.k

    def fit(self, s, size, room, weight="Heavy", floor=10.0):
        """The largest size at or below `size` whose string fits `room` points wide."""
        while size > floor and self.measure(s, size, weight)[0] > room:
            size -= 0.5
        return size

    # ---- drawing -----------------------------------------------------------------
    def _p(self, x, y): return (x * self.k, y * self.k)

    def line(self, pts, colour, w, cap=True, avoid=True):
        if avoid: self.obstacles.append((list(pts), w))
        p = [self._p(*q) for q in pts]
        self.d.line(p, fill=colour, width=int(w * self.k), joint="curve")
        if cap:
            r = w * self.k / 2
            for q in (p[0], p[-1]):
                self.d.ellipse([q[0] - r, q[1] - r, q[0] + r, q[1] + r], fill=colour)

    def area(self, pts, colour, alpha=0.3):
        self.d.polygon([self._p(*q) for q in pts], fill=colour + (int(alpha * 255),))

    def pill(self, x0, y0, x1, y1, colour, r=10, outline=None, ow=2):
        box = [self._p(x0, y0), self._p(x1, y1)]
        self.d.rounded_rectangle([box[0], box[1]], radius=r * self.k, fill=colour,
                                 outline=outline, width=int(ow * self.k) if outline else 0)

    def dot(self, x, y, r, colour):
        c = self._p(x, y); rr = r * self.k
        self.d.ellipse([c[0] - rr, c[1] - rr, c[0] + rr, c[1] + rr], fill=colour)

    def dash(self, x0, y0, x1, y1, colour, w=1.5, on=6, off=5):
        """A dashed rule. Takes RGBA so a gridline can sit behind everything quietly."""
        n = max(int(((x1 - x0) ** 2 + (y1 - y0) ** 2) ** 0.5 / (on + off)), 1)
        for i in range(n):
            t0, t1 = i * (on + off) / (n * (on + off)), (i * (on + off) + on) / (n * (on + off))
            self.line([(x0 + (x1 - x0) * t0, y0 + (y1 - y0) * t0),
                       (x0 + (x1 - x0) * t1, y0 + (y1 - y0) * t1)], colour, w, cap=False)

    def clear_of(self, s, x, y, size, weight="Heavy"):
        """Shortest distance from this string's box to any stroke, in points."""
        w, h = self.measure(s, size, weight)
        bx0, by0, bx1, by1 = x - w / 2, y - h / 2, x + w / 2, y + h / 2
        best = 1e9
        for pts, lw in self.obstacles:
            for a, b in zip(pts, pts[1:]):
                for i in range(9):
                    t = i / 8
                    px, py = a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t
                    dx = max(bx0 - px, 0, px - bx1)
                    dy = max(by0 - py, 0, py - by1)
                    best = min(best, math.hypot(dx, dy) - lw / 2)
        return best

    def place(self, s, near, size, colour=INK, weight="Heavy", floor=10.0):
        """Draw a string as near `near` as open field allows, and say where it went."""
        cx, cy = near
        w, h = self.measure(s, size, weight)
        for r in range(0, 120, 5):
            for dx, dy in ((0, -r), (0, r), (-r, 0), (r, 0), (-r, -r), (r, -r), (-r, r), (r, r)):
                x, y = cx + dx, cy + dy
                if x - w / 2 < 16 or x + w / 2 > 344 or y - h / 2 < 14 or y + h / 2 > 286:
                    continue
                if any(not (x + w / 2 + 7 <= o[0] or o[2] + 7 <= x - w / 2
                            or y + h / 2 + 4 <= o[1] or o[3] + 4 <= y - h / 2)
                       for o in self.drawn): continue
                if self.clear_of(s, x, y, size, weight) >= floor:
                    if r: self.notes.append(f"{s!r} moved {r}pt to clear the lines")
                    self.text(s, x, y, size, colour, weight)
                    return x, y
        raise SystemExit(f"nowhere clear for {s!r}")

    def text(self, s, x, y, size, colour=INK, weight="Heavy", anchor="mm"):
        w, h = self.measure(s, size, weight)
        if anchor == "mm":
            self.drawn.append((x - w / 2, y - h / 2, x + w / 2, y + h / 2))
        self.d.text(self._p(x, y), s, font=font(size, weight), fill=colour, anchor=anchor)
        return w, h

    def label_in(self, s, x0, y0, x1, y1, size, colour=INK, pad=10):
        """Type inside a box, shrunk until it actually fits. Reports if it had to."""
        room = (x1 - x0) - pad * 2
        got = self.fit(s, size, room)
        if got < size:
            self.notes.append(f"{s!r} shrunk {size:.0f}pt -> {got:.0f}pt to fit "
                              f"{room:.0f}pt of box")
        self.text(s, (x0 + x1) / 2, (y0 + y1) / 2, got, colour)
        return got

    # ---- out ---------------------------------------------------------------------
    def save(self, path):
        os.makedirs(os.path.dirname(path), exist_ok=True)
        self.im.resize((W * SCALE, H * SCALE), Image.LANCZOS).save(path, optimize=True)
        return path

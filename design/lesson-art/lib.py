"""Shared drawing helpers for lesson figures: the app font, the palette, a supersampled
canvas. Every number a card shows is drawn here, never painted.
"""
import math, os
from PIL import Image, ImageDraw, ImageFont

W, H, SS = 1200, 900, 3
FONT = "/System/Library/Fonts/SFNSRounded.ttf"
CREAM = (251, 247, 240); INK = (46, 38, 34); MUTED = (150, 135, 127); FAINT = (232, 224, 210)
CORAL = (255, 111, 97); MINT = (87, 199, 155); GOLD = (255, 194, 75); SKY = (111, 163, 220)
MINT_SOFT = (221, 245, 234); CORAL_SOFT = (255, 233, 229)

_fc = {}
def font(size, weight="Heavy"):
    key = (int(size * SS), weight)
    if key not in _fc:
        f = ImageFont.truetype(FONT, key[0])
        try: f.set_variation_by_name(weight)
        except Exception: pass
        _fc[key] = f
    return _fc[key]

class Canvas:
    """Every text() call records its box and every line()/dash() records its segments, so
    save() can shout when a label sits on a line. George, 2026-09-11: no text may cross a
    line on any chart."""
    def __init__(self):
        self.im = Image.new("RGB", (W * SS, H * SS), CREAM)
        self.d = ImageDraw.Draw(self.im, "RGBA")
        self._texts = []; self._segs = []
    def p(self, x, y): return (x * SS, y * SS)
    def text(self, s, x, y, size, colour=INK, weight="Heavy", anchor="mm"):
        f = font(size, weight)
        self.d.text(self.p(x, y), s, font=f, fill=colour, anchor=anchor)
        b = self.d.textbbox(self.p(x, y), s, font=f, anchor=anchor)
        self._texts.append((tuple(v / SS for v in b), s))
    def width(self, s, size, weight="Heavy"):
        return self.d.textlength(s, font=font(size, weight)) / SS
    def line(self, pts, colour, w):
        self.d.line([self.p(*q) for q in pts], fill=colour, width=int(w * SS), joint="curve")
        for q in (pts[0], pts[-1]):
            self.dot(*q, w / 2, colour)
        for a, b in zip(pts, pts[1:]):
            self._segs.append((a[0], a[1], b[0], b[1], w))
    def strike(self, x0, y0, x1, y1, colour, w=8):
        """A deliberate line through text (a crossed-out word). Not a chart line, so it is
        not recorded for the collision check."""
        self.d.line([self.p(x0, y0), self.p(x1, y1)], fill=colour, width=int(w * SS))
        self.dot(x0, y0, w / 2, colour); self.dot(x1, y1, w / 2, colour)
    def dot(self, x, y, r, colour):
        x, y, r = x * SS, y * SS, r * SS
        self.d.ellipse([x - r, y - r, x + r, y + r], fill=colour)
    def rrect(self, x0, y0, x1, y1, r, fill, outline=None, ow=0):
        self.d.rounded_rectangle([self.p(x0, y0), self.p(x1, y1)], radius=int(r * SS), fill=fill,
                                 outline=outline, width=int(ow * SS))
    def area(self, pts, base_y, colour):
        poly = [self.p(*q) for q in pts] + [self.p(pts[-1][0], base_y), self.p(pts[0][0], base_y)]
        self.d.polygon(poly, fill=colour)
    def dash(self, x0, y0, x1, y1, colour, w=3, on=10, off=8):
        self._segs.append((x0, y0, x1, y1, w))
        L = math.hypot(x1 - x0, y1 - y0); n = int(L // (on + off)) + 1
        for i in range(n):
            t0 = min(1, i * (on + off) / L); t1 = min(1, (i * (on + off) + on) / L)
            self.d.line([self.p(x0 + (x1 - x0) * t0, y0 + (y1 - y0) * t0),
                         self.p(x0 + (x1 - x0) * t1, y0 + (y1 - y0) * t1)], fill=colour, width=int(w * SS))
    def collisions(self, margin=6):
        """Text boxes that a line passes through, with a little breathing room."""
        hits = []
        for (x0, y0, x1, y1), s in self._texts:
            rx0, ry0, rx1, ry1 = x0 - margin, y0 - margin, x1 + margin, y1 + margin
            for ax, ay, bx, by, w in self._segs:
                L = max(1, math.hypot(bx - ax, by - ay)); n = int(L // 3) + 1
                for i in range(n + 1):
                    t = i / n; px, py = ax + (bx - ax) * t, ay + (by - ay) * t
                    if rx0 - w / 2 <= px <= rx1 + w / 2 and ry0 - w / 2 <= py <= ry1 + w / 2:
                        hits.append(s); break
                else:
                    continue
                break
        # and text boxes that sit on each other
        for i, ((a0, b0, a1, b1), s) in enumerate(self._texts):
            for (c0, d0, c1, d1), t in self._texts[i + 1:]:
                if a0 < c1 and c0 < a1 and b0 < d1 and d0 < b1:
                    hits.append(f"{s} / {t}")
        return hits
    def save(self, path):
        self.im.resize((W, H), Image.LANCZOS).save(path, "PNG")
        hits = self.collisions()
        print("wrote", path, ("  COLLISION: " + " | ".join(repr(h) for h in hits)) if hits else "")

def money(v):
    return "$" + f"{int(round(v)):,}"


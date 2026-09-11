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


# ------------------------------------------------------------------ figure builders
# Shared shapes for the lesson decks. Every one of them goes through Canvas.text/line so
# the collision check covers them.
WHITE = (255, 255, 255); STONE = (200, 190, 175); SKY_SOFT = (226, 238, 250)
GOLD_SOFT = (255, 240, 200)

def title(c, s, size=44, y=80):
    c.text(s, 600, y, size)

def note(c, s, y=830, colour=MUTED, size=24):
    c.text(s, 600, y, size, colour, "Bold")

def wrap(c, s, size, maxw, weight="Bold"):
    words = s.split(); lines = []; cur = ""
    for w in words:
        t = (cur + " " + w).strip()
        if c.width(t, size, weight) > maxw and cur: lines.append(cur); cur = w
        else: cur = t
    if cur: lines.append(cur)
    return lines

def arrow(c, x0, y0, x1, y1, colour, w=8):
    c.line([(x0, y0), (x1, y1)], colour, w)
    ang = math.atan2(y1 - y0, x1 - x0); L = 30
    c.d.polygon([c.p(x1 - L * math.cos(ang - 0.5), y1 - L * math.sin(ang - 0.5)), c.p(x1, y1),
                 c.p(x1 - L * math.cos(ang + 0.5), y1 - L * math.sin(ang + 0.5))], fill=colour)

def vbars(c, items, fmt=str, base=720, top=200, x0=None, width=None, gap=None, value_size=36, label_size=26, vmax=None):
    """Vertical bars: items = [(label, value, colour)] or [(label, value, colour, sublabel)]."""
    n = len(items)
    width = width or min(260, int(760 / n)); gap = gap or int((960 - n * width) / max(1, n - 1)) if n > 1 else 0
    total = n * width + (n - 1) * gap; x0 = x0 if x0 is not None else (1200 - total) / 2
    vmax = vmax or max(it[1] for it in items)
    scale = (base - top) / vmax
    for i, it in enumerate(items):
        label, v, col = it[0], it[1], it[2]
        bx0 = x0 + i * (width + gap); bx1 = bx0 + width
        c.rrect(bx0, base - v * scale, bx1, base, 24, col)
        c.text(fmt(v), (bx0 + bx1) / 2, base - v * scale - 36, value_size)
        for j, ln in enumerate(label.split("\n")):
            c.text(ln, (bx0 + bx1) / 2, base + 44 + j * 30, label_size, MUTED, "Bold")
    return scale

def hbars(c, items, fmt=str, x0=470, xmax=1080, y0=200, step=None, h=76, label_size=24, value_size=30, vmax=None):
    """Horizontal bars with the label on the left: items = [(label, value, colour)]."""
    vmax = vmax or max(it[1] for it in items)
    step = step or min(130, int((760 - y0) / len(items)))
    for i, (label, v, col) in enumerate(items):
        y = y0 + i * step
        c.text(label, x0 - 24, y + h / 2, label_size, INK, "Bold", anchor="rm")
        c.rrect(x0, y, x0 + (xmax - x0) * v / vmax, y + h, 22, col)
        c.text(fmt(v), x0 + (xmax - x0) * v / vmax + 20, y + h / 2, value_size, INK, anchor="lm")

def stack(c, parts, x0=430, x1=770, top=200, bottom=760, fmt=str, label_size=24, value_size=32, ink=WHITE):
    """One stacked column, bottom part first: parts = [(label, value, colour)]."""
    total = sum(p[1] for p in parts); scale = (bottom - top) / total
    y = bottom
    for i, (label, v, col) in enumerate(parts):
        h = v * scale
        c.rrect(x0, y - h, x1, y, 22 if i in (0, len(parts) - 1) else 0, col)
        if i not in (0, len(parts) - 1) or len(parts) == 1:
            pass
        if i == 0 and len(parts) > 1: c.rrect(x0, y - h, x1, y - h + 22, 0, col)
        if i == len(parts) - 1 and len(parts) > 1: c.rrect(x0, y - 22, x1, y, 0, col)
        if h >= 60:
            c.text(fmt(v), (x0 + x1) / 2, y - h / 2 - (14 if label else 0), value_size, ink)
            if label: c.text(label, (x0 + x1) / 2, y - h / 2 + 22, label_size, ink, "Bold")
        else:
            c.text(f"{fmt(v)} {label}".strip(), x1 + 24, y - h / 2, label_size, INK, "Bold", anchor="lm")
        y -= h

def steps(c, rows, y0=190, step=None, h=170, x0=120, x1=1080, num=True):
    """Numbered rows: rows = [(head, sub, colour)]. sub may be empty."""
    step = step or (h + 40)
    for i, (head, sub, col) in enumerate(rows):
        y = y0 + i * step
        c.rrect(x0, y, x1, y + h, 34, WHITE, outline=FAINT, ow=4)
        if num:
            c.dot(x0 + 80, y + h / 2, 44, col); c.text(str(i + 1), x0 + 80, y + h / 2, 40, WHITE if col not in (GOLD, FAINT, STONE) else INK)
            tx = x0 + 160
        else:
            c.rrect(x0 + 20, y + 20, x0 + 40, y + h - 20, 10, col); tx = x0 + 70
        if sub:
            c.text(head, tx, y + h / 2 - 24, 32, INK, anchor="lm")
            c.text(sub, tx, y + h / 2 + 30, 24, MUTED, "Bold", anchor="lm")
        else:
            c.text(head, tx, y + h / 2, 32, INK, anchor="lm")

def columns(c, left, right, y0=160, y1=820, item_h=90, gap=30):
    """Two columns of pills: left/right = (head, [items], colour)."""
    for k, (head, items, col) in enumerate((left, right)):
        x0 = 90 + k * 540; x1 = x0 + 480
        c.rrect(x0, y0, x1, y1, 36, col)
        ink = WHITE if col not in (FAINT, STONE, GOLD, GOLD_SOFT, MINT_SOFT, CORAL_SOFT, SKY_SOFT) else INK
        c.text(head, (x0 + x1) / 2, y0 + 70, 36, ink)
        for i, it in enumerate(items):
            y = y0 + 160 + i * (item_h + gap)
            c.rrect(x0 + 30, y, x1 - 30, y + item_h, 24, WHITE)
            c.text(it, (x0 + x1) / 2, y + item_h / 2, 26, INK, "Bold")

def phone(c, heading, rows, y0=150, footer=None, toggles=True):
    """A phone with a list of settings rows: rows = [(head, sub, on)]."""
    c.rrect(330, y0, 870, 840, 60, WHITE, outline=FAINT, ow=5)
    c.rrect(540, y0 + 20, 660, y0 + 46, 13, FAINT)
    c.text(heading, 600, y0 + 110, 32, INK)
    for i, (head, sub, on) in enumerate(rows):
        y = y0 + 180 + i * 170
        c.rrect(370, y, 830, y + 130, 30, MINT_SOFT if on else CORAL_SOFT if on is False else FAINT)
        c.text(head, 400, y + 48, 28, INK, anchor="lm")
        if sub: c.text(sub, 400, y + 92, 22, MUTED, "Bold", anchor="lm")
        if toggles and on is not None:
            c.rrect(730, y + 42, 810, y + 90, 24, MINT if on else STONE)
            c.dot(790 if on else 750, y + 66, 18, WHITE)
    if footer: c.text(footer, 600, 790, 22, MUTED, "Bold")

def bubbles(c, msgs, y0=150, phone_frame=True, size=28):
    """A chat: msgs = [(text, 'them'|'me')]. Returns the y after the last bubble."""
    if phone_frame:
        c.rrect(150, y0 - 20, 1050, 860, 60, WHITE, outline=FAINT, ow=5)
        c.rrect(510, y0, 690, y0 + 28, 14, FAINT)
    y = y0 + 80
    for text, who in msgs:
        lines = wrap(c, text, size, 560)
        h = 40 + len(lines) * (size + 16)
        if who == "me":
            x1 = 1010; x0 = x1 - 620
            c.rrect(x0, y, x1, y + h, 40, SKY)
            for i, ln in enumerate(lines): c.text(ln, x0 + 35, y + 40 + i * (size + 16), size, WHITE, "Bold", anchor="lm")
        else:
            x0 = 190; x1 = x0 + 620
            c.rrect(x0, y, x1, y + h, 40, FAINT)
            for i, ln in enumerate(lines): c.text(ln, x0 + 35, y + 40 + i * (size + 16), size, INK, "Bold", anchor="lm")
        y += h + 30
    return y

def legend(c, items, y, x0=300, gap=220):
    for i, (label, col) in enumerate(items):
        x = x0 + i * gap
        c.dot(x, y, 14, col); c.text(label, x + 28, y, 26, MUTED, "Bold", anchor="lm")

def axes(c, x0, x1, y0, y1, xmax, ymax, ystep, xstep, fmt=str, xunit=""):
    for v in range(0, int(ymax) + 1, int(ystep)):
        y = y1 - (y1 - y0) * v / ymax
        c.line([(x0, y), (x1, y)], FAINT, 2)
        c.text(fmt(v), x0 - 18, y, 22, MUTED, "Bold", anchor="rm")
    for t in range(0, int(xmax) + 1, int(xstep)):
        x = x0 + (x1 - x0) * t / xmax
        c.text(str(t), x, y1 + 34, 24, MUTED, "Bold")
    if xunit: c.text(xunit, x1 + 24, y1 + 34, 24, MUTED, "Bold", anchor="lm")

def curve(c, fn, xmax, x0, x1, y0, y1, ymax, colour, w=9, fill=None, n=60):
    pts = [(x0 + (x1 - x0) * i / n, y1 - (y1 - y0) * min(ymax, fn(xmax * i / n)) / ymax) for i in range(n + 1)]
    if fill: c.area(pts, y1, fill)
    c.line(pts, colour, w)
    return pts

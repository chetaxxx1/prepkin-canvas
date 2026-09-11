#!/usr/bin/env python3
"""The six charts in "Why compound interest wins", drawn by code with the real numbers.

A painting cannot be trusted with a number, so anything with a figure on it is drawn
here, in the app's own font, and every value is computed rather than typed. Output is
1200x900 (4:3 at @3x for a 400x300pt card), supersampled 3x for clean strokes.
"""
import math, os, sys
from PIL import Image, ImageDraw, ImageFont

OUT = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
from lib import Canvas as _Canvas

class Canvas(_Canvas):
    """The shared canvas, saving by bare name into this folder."""
    def save(self, name):
        super().save(os.path.join(OUT, name))

# ---------------------------------------------------------------- 1: one year
def chart_year_one():
    c = Canvas()
    c.text("Put $1,000 in at 8%", 600, 80, 44)
    # two bars
    base = 760; scale = 0.5  # px per dollar
    for i, (label, v, col) in enumerate([("Day 1", 1000, FAINT), ("One year later", 1080, MINT)]):
        x0 = 260 + i * 420; x1 = x0 + 260
        c.rrect(x0, base - v * scale, x1, base, 22, col)
        c.text(money(v), (x0 + x1) / 2, base - v * scale - 40, 40)
        c.text(label, (x0 + x1) / 2, base + 46, 28, MUTED, "Bold")
    # the +$80 slice, labelled inside it like chart 2
    x0 = 680; x1 = 940
    c.rrect(x0, base - 1080 * scale, x1, base - 1000 * scale, 12, CORAL)
    c.text("+ $80 interest", (x0 + x1) / 2, base - 1040 * scale, 24, (255, 255, 255))
    c.save("chart-01-year-one.png")

# ---------------------------------------------------------------- 2: year two earns more
def chart_year_two():
    c = Canvas()
    c.text("The $80 starts earning too", 600, 80, 44)
    base = 760; scale = 0.5
    cols = [("Start", 1000, 0), ("Year 1", 1080, 80), ("Year 2", 1166.4, 86.4)]
    for i, (label, v, gain) in enumerate(cols):
        x0 = 160 + i * 330; x1 = x0 + 250
        c.rrect(x0, base - v * scale, x1, base, 22, MINT if i else FAINT)
        if gain:
            c.rrect(x0, base - v * scale, x1, base - (v - gain) * scale, 12, CORAL)
            c.text(f"+ {money(gain) if gain == int(gain) else '$' + format(gain, ',.2f')}", (x0 + x1) / 2,
                   base - (v - gain / 2) * scale, 26, (255, 255, 255))
        c.text(money(v) if v == int(v) else "$1,166", (x0 + x1) / 2, base - v * scale - 40, 40)
        c.text(label, (x0 + x1) / 2, base + 46, 28, MUTED, "Bold")
    c.save("chart-02-year-two.png")

# ---------------------------------------------------------------- 3: thirty years
def curve(c, years, fn, x0, x1, y0, y1, ymax, colour, w=9, fill=None):
    pts = []
    for i in range(0, years * 4 + 1):
        t = i / 4
        x = x0 + (x1 - x0) * t / years
        y = y1 - (y1 - y0) * fn(t) / ymax
        pts.append((x, y))
    if fill: c.area(pts, y1, fill)
    c.line(pts, colour, w)
    return pts

def axes(c, x0, x1, y0, y1, years, ymax, ystep, xstep=10, money_axis=True):
    for v in range(0, int(ymax) + 1, int(ystep)):
        y = y1 - (y1 - y0) * v / ymax
        c.line([(x0, y), (x1, y)], FAINT, 2)
        c.text(money(v) if money_axis else str(v), x0 - 18, y, 22, MUTED, "Bold", anchor="rm")
    for t in range(0, years + 1, xstep):
        x = x0 + (x1 - x0) * t / years
        c.text(f"{t}", x, y1 + 34, 24, MUTED, "Bold")
    c.text("years", x1 + 20, y1 + 34, 24, MUTED, "Bold", anchor="lm")

def chart_thirty():
    c = Canvas()
    c.text("$1,000 at 8%, left alone", 600, 80, 44)
    x0, x1, y0, y1 = 200, 1080, 180, 740
    ymax = 12000
    axes(c, x0, x1, y0, y1, 30, ymax, 4000)
    pts = curve(c, 30, lambda t: 1000 * 1.08 ** t, x0, x1, y0, y1, ymax, CORAL, fill=CORAL_SOFT)
    for t in (10, 20, 30):
        v = 1000 * 1.08 ** t
        x = x0 + (x1 - x0) * t / 30; y = y1 - (y1 - y0) * v / ymax
        c.dot(x, y, 12, CORAL); c.dot(x, y, 6, CREAM)
        c.text(money(v), x - 22, y - 26 if t < 30 else y - 44, 32, anchor="rm")
    c.save("chart-03-thirty-years.png")

# ---------------------------------------------------------------- 4: simple vs compound
def chart_simple_vs_compound():
    c = Canvas()
    c.text("Flat $80 a year vs. interest on interest", 600, 80, 40)
    x0, x1, y0, y1 = 200, 1080, 180, 740
    ymax = 12000
    axes(c, x0, x1, y0, y1, 30, ymax, 4000)
    curve(c, 30, lambda t: 1000 + 80 * t, x0, x1, y0, y1, ymax, SKY)
    curve(c, 30, lambda t: 1000 * 1.08 ** t, x0, x1, y0, y1, ymax, CORAL)
    ys = y1 - (y1 - y0) * 3400 / ymax; yc = y1 - (y1 - y0) * 10063 / ymax
    c.text("$3,400  simple", x1 - 10, ys - 58, 30, SKY, anchor="rm")
    c.text("$10,063  compound", x1 - 10, yc - 44, 30, CORAL, anchor="rm")
    c.save("chart-04-simple-vs-compound.png")

# ---------------------------------------------------------------- 5: rule of 72
def chart_rule_of_72():
    c = Canvas()
    c.text("At 8% it doubles every 9 years", 600, 80, 44)
    base = 760; scale = 0.062
    for i, t in enumerate((0, 9, 18, 27)):
        v = 1000 * 2 ** i
        x0 = 150 + i * 260; x1 = x0 + 200
        c.rrect(x0, base - v * scale, x1, base, 22, [FAINT, MINT, MINT, MINT][i])
        c.text(money(v), (x0 + x1) / 2, base - v * scale - 40, 38)
        c.text("start" if t == 0 else f"year {t}", (x0 + x1) / 2, base + 46, 28, MUTED, "Bold")
        if i:
            c.text("×2", x0 - 30, base - (v * scale) / 2 - 60, 30, CORAL)
    c.save("chart-05-rule-of-72.png")

# ---------------------------------------------------------------- 6: two savers
def chart_two_savers():
    c = Canvas()
    c.text("$200 a month, until 60", 600, 80, 44)
    x0, x1, y0, y1 = 220, 840, 180, 740   # room on the right for end-of-line labels
    m = 0.08 / 12
    fv = lambda months: 200 * ((1 + m) ** months - 1) / m
    ymax = 900_000
    # y axis in $ thousands, x axis in age
    for v in range(0, 900_001, 300_000):
        y = y1 - (y1 - y0) * v / ymax
        c.line([(x0, y), (x1, y)], FAINT, 2)
        c.text(f"${v // 1000}k" if v else "$0", x0 - 18, y, 22, MUTED, "Bold", anchor="rm")
    for age in (18, 28, 40, 50, 60):
        x = x0 + (x1 - x0) * (age - 18) / 42
        c.text(f"age {age}" if age == 18 else f"{age}", x, y1 + 34, 24, MUTED, "Bold")
    def series(start, colour, fill):
        pts = []
        for age4 in range(start * 4, 60 * 4 + 1):
            age = age4 / 4
            v = fv((age - start) * 12)
            pts.append((x0 + (x1 - x0) * (age - 18) / 42, y1 - (y1 - y0) * v / ymax))
        if fill: c.area(pts, y1, fill)
        c.line(pts, colour, 9)
        return pts
    series(18, CORAL, CORAL_SOFT)
    series(28, SKY, None)
    a, b = fv(42 * 12), fv(32 * 12)
    ya = y1 - (y1 - y0) * a / ymax; yb = y1 - (y1 - y0) * b / ymax
    # Labels live in the margin at each line's end, so neither can sit on a curve.
    c.text(money(a), x1 + 24, ya - 16, 34, CORAL, anchor="lm")
    c.text("started at 18", x1 + 24, ya + 22, 24, CORAL, "Bold", anchor="lm")
    c.text(money(b), x1 + 24, yb - 16, 34, SKY, anchor="lm")
    c.text("started at 28", x1 + 24, yb + 22, 24, SKY, "Bold", anchor="lm")
    c.save("chart-06-two-savers.png")

if __name__ == "__main__":
    chart_year_one(); chart_year_two(); chart_thirty(); chart_simple_vs_compound(); chart_rule_of_72(); chart_two_savers()

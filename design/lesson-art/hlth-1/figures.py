#!/usr/bin/env python3
"""Caffeine has a half-life: the decay curve, the 4pm timeline, adenosine's parking
spots, the six-hour study, the dose chart."""
import os, sys, math
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))
HALF = 5.0  # hours

def left(t, dose=200): return dose * 0.5 ** (t / HALF)

def halflife():
    c = Canvas(); title(c, "Half every five hours")
    x0, x1, y0, y1 = 170, 1080, 170, 700
    axes(c, x0, x1, y0, y1, xmax=15, ymax=200, ystep=50, xstep=5, fmt=lambda v: f"{v}mg", xunit="hours")
    curve(c, left, 15, x0, x1, y0, y1, 200, CORAL, fill=CORAL_SOFT)
    for t in (0, 5, 10, 15):
        x = x0 + (x1 - x0) * t / 15; y = y1 - (y1 - y0) * left(t) / 200
        c.dot(x, y, 14, CORAL)
        c.text(f"{int(left(t))}mg", x + (44 if t else 90), y - (46 if t < 15 else 40), 30, INK, anchor="mm")
    c.save(f"{OUT}/fig-02-halflife.png")

def timeline():
    c = Canvas(); title(c, "A 4pm coffee")
    x0, x1, y = 150, 1050, 430
    c.rrect(x0, y - 8, x1, y + 8, 8, FAINT)
    stops = [("4pm", 0, 200, CORAL), ("9pm", 5, 100, CORAL), ("2am", 10, 50, GOLD), ("7am", 15, 25, MINT)]
    for label, t, mg, col in stops:
        x = x0 + (x1 - x0) * t / 15
        r = 18 + mg / 5
        c.dot(x, y, r, col)
        c.text(f"{mg}mg", x, y - r - 40, 34, INK)
        c.text(label, x, y + r + 44, 28, MUTED, "Bold")
    c.rrect(300, 680, 900, 770, 26, GOLD_SOFT)
    c.text("50mg at 2am is a cup of black tea", 600, 725, 28, INK, "Bold")
    c.save(f"{OUT}/fig-03-timeline.png")

def adenosine():
    c = Canvas(); title(c, "Adenosine's parking spots")
    # a row of spots; some hold adenosine (sleepy), some hold caffeine (blocked)
    cols = 6; x0 = 150; w = 150
    for i in range(cols):
        x = x0 + i * w
        c.rrect(x + 10, 240, x + w - 10, 440, 24, WHITE, outline=FAINT, ow=4)
        if i < 3:
            c.dot(x + w / 2, 340, 52, CORAL)
        else:
            c.dot(x + w / 2, 340, 52, SKY)
    c.dot(300, 560, 22, CORAL); c.text("caffeine, parked", 340, 560, 28, INK, "Bold", anchor="lm")
    c.dot(300, 630, 22, SKY); c.text("adenosine, the tired signal", 340, 630, 28, INK, "Bold", anchor="lm")
    # the pile that keeps growing
    for j in range(7):
        c.dot(900 + (j % 3) * 50 - 50, 780 - (j // 3) * 48, 22, SKY)
    c.text("still piling up", 880, 850, 24, MUTED, "Bold")
    c.save(f"{OUT}/fig-05-adenosine.png")

def study():
    c = Canvas(); title(c, "400mg, six hours before bed")
    hbars(c, [("no caffeine", 7, MINT), ("six hours before", 6, CORAL)], fmt=lambda v: f"{v} hours",
          x0=420, xmax=980, y0=250, step=180, h=90, label_size=28, value_size=30, vmax=7.6)
    note(c, "about an hour less, and the people did not notice", y=680, size=26)
    note(c, "Drake et al., 2013, Journal of Clinical Sleep Medicine", y=740, size=20)
    c.save(f"{OUT}/fig-06-study.png")

def doses():
    c = Canvas(); title(c, "Milligrams in one drink")
    items = [("large cafe coffee", 200, CORAL), ("energy drink", 160, CORAL), ("small coffee", 95, GOLD),
             ("espresso shot", 63, GOLD), ("black tea", 47, MINT), ("cola", 34, MINT), ("decaf", 3, STONE)]
    hbars(c, items, fmt=lambda v: f"{v}mg", x0=430, xmax=1060, y0=170, step=92, h=64, label_size=26, value_size=28, vmax=210)
    c.save(f"{OUT}/fig-08-doses.png")

if __name__ == "__main__":
    halflife(); timeline(); adenosine(); study(); doses()

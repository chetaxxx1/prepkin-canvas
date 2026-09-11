#!/usr/bin/env python3
"""You forget most of it by tomorrow: the bars, what fell out, the day-one review,
Ebbinghaus's numbers, the cheap review, and the schedule."""
import os, sys, math
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))
DAYS = [("today", 100), ("day 1", 34), ("day 2", 28), ("day 7", 25)]

def bars(c, show_lost=False, reviewed=False):
    base, top = 700, 220; scale = (base - top) / 100
    vals = [("today", 100), ("day 1", 100 if reviewed else 34), ("day 2", 80 if reviewed else 28), ("day 7", 65 if reviewed else 25)]
    for i, (label, v) in enumerate(vals):
        x0 = 150 + i * 250; x1 = x0 + 190
        if show_lost: c.rrect(x0, top, x1, base, 24, WHITE, outline=STONE, ow=3)
        c.rrect(x0, base - v * scale, x1, base, 24, MINT if v > 50 else CORAL)
        c.text(f"{v}%", (x0 + x1) / 2, base - v * scale - 34, 30)
        c.text(label, (x0 + x1) / 2, base + 44, 24, MUTED, "Bold")

def the_bars():
    c = Canvas(); title(c, "How much is still in your head"); bars(c)
    c.save(f"{OUT}/fig-01-bars.png")

def what_fell():
    c = Canvas(); title(c, "The empty part is what fell out"); bars(c, show_lost=True)
    note(c, "almost all of the loss is in the first day", 830)
    c.save(f"{OUT}/fig-02-what-fell.png")

def slope():
    c = Canvas(); title(c, "With one review on day one"); bars(c, reviewed=True)
    note(c, "the cliff has turned into a slope", 830)
    c.save(f"{OUT}/fig-04-slope.png")

def curve_fig():
    c = Canvas(); title(c, "Ebbinghaus, 1885")
    x0, x1, y0, y1 = 200, 1060, 180, 720
    for v in (0, 25, 50, 75, 100):
        y = y1 - (y1 - y0) * v / 100; c.line([(x0, y), (x1, y)], FAINT, 2); c.text(f"{v}%", x0 - 18, y, 22, MUTED, "Bold", anchor="rm")
    for d, lab in ((0, "0"), (1, "1 day"), (2, "2"), (6, "6 days")):
        c.text(lab, x0 + (x1 - x0) * d / 7, y1 + 34, 22, MUTED, "Bold")
    pts = [(x0 + (x1 - x0) * t / 7, y1 - (y1 - y0) * (24 + 76 * math.exp(-t * 1.6)) / 100) for t in [i / 20 for i in range(141)]]
    c.area(pts, y1, CORAL_SOFT); c.line(pts, CORAL, 9)
    c.text("about a third left after a day", x0 + 200, y1 - (y1 - y0) * 0.34 - 50, 24, INK, "Bold", anchor="lm")
    c.text("about a quarter after a week", x1 - 10, y1 - (y1 - y0) * 0.25 - 44, 24, INK, "Bold", anchor="rm")
    c.save(f"{OUT}/fig-06-curve.png")

def cheap():
    c = Canvas(); title(c, "The cheapest review is the soonest")
    vbars(c, [("ten minutes\ntonight", 10, MINT), ("an hour the night\nbefore the test", 60, STONE)], fmt=lambda v: f"{v} min", base=680, top=220, width=280)
    note(c, "the same result, because tonight there is still something there to catch", 840, size=22)
    c.save(f"{OUT}/fig-07-cheap.png")

def schedule():
    c = Canvas(); title(c, "The schedule")
    x0, x1, y = 120, 1080, 460
    c.line([(x0, y), (x1, y)], STONE, 8)
    for d, lab in ((1, "day 1"), (3, "day 3"), (7, "day 7"), (21, "day 21")):
        x = x0 + (x1 - x0) * math.log(d + 1) / math.log(23)
        c.dot(x, y, 22, MINT); c.text(lab, x, y + 60, 24, INK, "Bold")
    c.text("each review shorter and further out than the last", 600, 330, 24, MUTED, "Bold")
    c.save(f"{OUT}/fig-09-schedule.png")

if __name__ == "__main__":
    the_bars(); what_fell(); slope(); curve_fig(); cheap(); schedule()

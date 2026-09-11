#!/usr/bin/env python3
"""Figures for "Spaced practice beats cramming". Curves are illustrative (the shape of
forgetting), so the axes say "how much you remember" and no card quotes a percentage."""
import math, os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def frame(c, title, first="the cram", last="day 7"):
    c.text(title, 600, 80, 42)
    x0, x1, y0, y1 = 200, 1080, 180, 740
    for v, lab in ((0, "none"), (0.5, "half"), (1, "all")):
        y = y1 - (y1 - y0) * v
        c.line([(x0, y), (x1, y)], FAINT, 2)
        c.text(lab, x0 - 18, y, 22, MUTED, "Bold", anchor="rm")
    labels = [first] + [f"day {d}" for d in range(1, 7)] + [last]
    if first == "day 1":
        labels = [f"day {d}" for d in range(1, 8)] + [last]
    for d in range(0, 8):
        x = x0 + (x1 - x0) * d / 7
        c.text(labels[d], x, y1 + 34, 22, MUTED, "Bold")
    c.text("how much you remember", x0, y0 - 40, 22, MUTED, "Bold", anchor="lm")
    return x0, x1, y0, y1

def forget(t):  # illustrative decay
    return 0.2 + 0.8 * math.exp(-t / 1.6)

def cram():
    c = Canvas()
    x0, x1, y0, y1 = frame(c, "One long cram")
    pts = [(x0 + (x1 - x0) * t / 7, y1 - (y1 - y0) * forget(t)) for t in [i / 8 for i in range(0, 57)]]
    c.area(pts, y1, CORAL_SOFT); c.line(pts, CORAL, 9)
    c.text("a week later", x1 - 10, y1 - (y1 - y0) * forget(7) - 46, 26, CORAL, anchor="rm")
    c.save(f"{OUT}/fig-02-cram.png")

def hour_split():
    c = Canvas()
    c.text("The same hour, two ways", 600, 80, 42)
    # left: one 60-minute block
    c.text("Sunday night", 330, 180, 28, MUTED, "Bold")
    c.rrect(200, 220, 460, 700, 26, CORAL)
    c.text("60 min", 330, 460, 40, (255, 255, 255))
    c.text("=", 600, 460, 60, MUTED)
    # right: six 10-minute blocks
    c.text("Monday to Saturday", 890, 180, 28, MUTED, "Bold")
    days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    for i, d in enumerate(days):
        x0 = 740 + (i % 3) * 110; y0 = 240 + (i // 3) * 240
        c.rrect(x0, y0, x0 + 90, y0 + 170, 20, MINT)
        c.text("10", x0 + 45, y0 + 70, 34, (255, 255, 255)); c.text("min", x0 + 45, y0 + 108, 20, (255, 255, 255), "Bold")
        c.text(d, x0 + 45, y0 + 200, 22, MUTED, "Bold")
    c.save(f"{OUT}/fig-03-hour-split.png")

def spaced():
    c = Canvas()
    x0, x1, y0, y1 = frame(c, "Ten minutes a day", first="day 1", last="test")
    # Sawtooth. A session lifts recall to the top; between sessions it slips, but each
    # time it slips less, because every pull-back leaves the memory stronger.
    pts = []
    floors = [0.55, 0.64, 0.72, 0.79, 0.85, 0.90]
    for day in range(0, 6):          # six sessions, days 1 to 6
        top = 1.0; floor = floors[day]
        for i in range(0, 9):
            f = i / 8
            v = floor + (top - floor) * math.exp(-f * 2.2)
            pts.append((x0 + (x1 - x0) * (day + f) / 7, y1 - (y1 - y0) * v))
    # day 7: no session, it just holds to the test
    last_v = floors[-1] + (1 - floors[-1]) * math.exp(-2.2)
    for i in range(1, 9):
        f = i / 8
        v = last_v - 0.03 * f
        pts.append((x0 + (x1 - x0) * (6 + f) / 7, y1 - (y1 - y0) * v))
    c.area(pts, y1, MINT_SOFT); c.line(pts, MINT, 9)
    for day in range(0, 6):
        x = x0 + (x1 - x0) * day / 7
        c.dot(x, y1 - (y1 - y0) * 1.0, 11, MINT); c.dot(x, y1 - (y1 - y0) * 1.0, 5, CREAM)
    c.text("each slip is smaller than the last", x0 + 20, y1 - 40, 24, MINT, "Bold", anchor="lm")
    c.save(f"{OUT}/fig-04-spaced.png")

def calendar():
    c = Canvas()
    c.text("Put them in the day you get the material", 600, 80, 40)
    days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    x0 = 90; w = 145
    for i, d in enumerate(days):
        x = x0 + i * w
        c.text(d, x + w / 2, 180, 26, MUTED, "Bold")
        c.rrect(x + 8, 210, x + w - 8, 760, 22, (255, 255, 255), outline=FAINT, ow=2)
        if i < 6:
            c.rrect(x + 22, 330, x + w - 22, 420, 16, MINT)
            c.text("10 min", x + w / 2, 375, 24, (255, 255, 255))
        else:
            c.text("test", x + w / 2, 375, 26, CORAL)
    c.save(f"{OUT}/fig-07-calendar.png")

if __name__ == "__main__":
    cram(); hour_split(); spaced(); calendar()

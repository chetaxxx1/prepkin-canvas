#!/usr/bin/env python3
"""Alcohol and sleep: what a sedative does, the two halves, one drink an hour, REM, timing."""
import os, sys, math
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def what_it_is():
    c = Canvas(); title(c, "A sedative, then a rebound")
    columns(c, ("First, while it's in you", ["brain slows down", "asleep fast", "deep at first"], SKY),
            ("Then, as it clears", ["brain rebounds", "wake-ups you forget", "less dreaming"], CORAL), y0=170, y1=780)
    c.save(f"{OUT}/fig-02-what-it-is.png")

DEEP = (74, 96, 160); LIGHT = SKY_SOFT; REM = (196, 178, 240)

def stages(c, y, segs, label):
    """One night as a bar of stages: segs = [(hours, kind)], kind in deep/light/rem/awake."""
    x0, x1 = 150, 1050; x = x0
    c.text(label, 600, y - 60, 28, INK, "Bold")
    for hours, kind in segs:
        w = (x1 - x0) * hours / 8
        col = {"deep": DEEP, "light": LIGHT, "rem": REM}.get(kind)
        if kind == "awake":
            c.rrect(x, y - 44, x + w, y + 44, 6, CORAL)
        else:
            c.rrect(x, y - 44, x + w, y + 44, 6, col)
        x += w
    c.rrect(x0, y - 44, x1, y + 44, 18, (0, 0, 0, 0), outline=CREAM, ow=4)

def two_halves():
    c = Canvas(); title(c, "Two halves of the night")
    normal = [(1.0, "deep"), (0.4, "light"), (0.3, "rem"), (0.9, "deep"), (0.4, "light"), (0.5, "rem"), (0.6, "deep"), (0.6, "light"), (0.8, "rem"), (0.5, "light"), (1.0, "rem"), (1.0, "light")]
    drinks = [(1.6, "deep"), (0.3, "light"), (0.2, "rem"), (1.4, "deep"), (0.5, "light"), (0.15, "awake"), (0.6, "light"), (0.3, "rem"), (0.15, "awake"), (0.7, "light"), (0.15, "awake"), (0.5, "light"), (0.3, "rem"), (0.15, "awake"), (1.0, "light")]
    stages(c, 300, normal, "a normal night"); stages(c, 560, drinks, "after three drinks")
    for i, h in enumerate(["bed", "2h", "4h", "6h", "8h"]):
        c.text(h, 150 + i * 225, 640, 22, MUTED, "Bold")
    legend(c, [("deep", DEEP), ("light", LIGHT), ("REM", REM), ("awake", CORAL)], 740, x0=250, gap=200)
    c.text("first half: deeper. Second half: broken, less REM.", 600, 830, 24, MUTED, "Bold")
    c.save(f"{OUT}/fig-03-two-halves.png")

def clearing():
    c = Canvas(); title(c, "Roughly one drink an hour")
    x0, x1, y = 150, 1050, 450
    c.rrect(x0, y - 8, x1, y + 8, 8, FAINT)
    labels = ["11pm", "12am", "1am", "2am", "3am", "4am"]
    for i, lab in enumerate(labels):
        x = x0 + i * 180; c.text(lab, x, y + 60, 24, MUTED, "Bold")
        left = max(0, 3 - i)
        for k in range(left): c.dot(x, y - 40 - k * 44, 18, GOLD)
    c.text("three drinks", x0, y - 190, 26, INK, "Bold")
    c.text("gone", x0 + 3 * 180, y - 60, 26, CORAL, "Bold"); c.text("rebound starts", x0 + 3 * 180, y - 100, 26, CORAL, "Bold")
    c.save(f"{OUT}/fig-04-clearing.png")

def rem():
    c = Canvas(); title(c, "REM is when the day gets filed")
    hbars(c, [("normal night", 10, MINT), ("after drinking", 6, CORAL)], fmt=lambda v: "", x0=420, xmax=1000, y0=260, step=190, h=100, label_size=28, vmax=10)
    c.text("less REM, less of what you studied kept", 600, 700, 26, MUTED, "Bold")
    c.text("study nights and drink nights: keep them apart", 600, 760, 24, MUTED, "Bold")
    c.save(f"{OUT}/fig-06-rem.png")

def timing():
    c = Canvas(); title(c, "Same drinks, better night")
    for k, (label, reb_x, col) in enumerate([("last drink at 11pm", 450, CORAL), ("last drink at 8pm", 225, MINT)]):
        y = 280 + k * 260
        x0, x1 = 150, 1050
        c.rrect(x0, y - 8, x1, y + 8, 8, FAINT)
        for i, h in enumerate(["8pm", "11pm", "2am", "5am", "8am"]):
            c.text(h, x0 + i * 225, y + 50, 22, MUTED, "Bold")
        bed = x0 + 300; c.dot(bed, y, 22, SKY); c.text("bed", bed, y - 50, 22, SKY, "Bold")
        c.dot(x0 + reb_x, y, 22, col); c.text("rebound", x0 + reb_x, y - 50, 24, col, "Bold")
        c.text(label, 600, y - 130, 26, INK, "Bold")
    c.text("the rebound lands while you are still awake", 600, 800, 26, MINT)
    c.save(f"{OUT}/fig-07-timing.png")

if __name__ == "__main__":
    what_it_is(); two_halves(); clearing(); rem(); timing()

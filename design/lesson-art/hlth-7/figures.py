#!/usr/bin/env python3
"""Scrolling, not blue light: what light does, the ten-minute study, night mode, where the
hour goes, the phone's place."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def what_it_is():
    c = Canvas(); title(c, "What the light does")
    steps(c, [("Blue-ish light says 'daytime'", "to the clock in your brain", SKY), ("Melatonin gets delayed", "the hormone that says sleep", GOLD), ("That is real", "the question is how big", MINT)], y0=180, h=160, step=185, num=False)
    c.save(f"{OUT}/fig-02-what-it-is.png")

def study():
    c = Canvas(); title(c, "Time to fall asleep")
    hbars(c, [("paper book", 20, MINT), ("bright tablet, 4 hours", 30, CORAL)], fmt=lambda v: "" if v == 20 else "about 10 minutes longer", x0=480, xmax=900, y0=260, step=190, h=100, label_size=28, value_size=24, vmax=32)
    c.text("at full brightness, for four hours, five nights running", 600, 700, 24, MUTED, "Bold")
    note(c, "Chang et al., Harvard, 2015", y=780, size=20)
    c.save(f"{OUT}/fig-03-study.png")

def night_mode():
    c = Canvas(); title(c, "Night mode, tested")
    vbars(c, [("no phone", 10, MINT), ("phone", 8.4, CORAL), ("phone,\nnight mode", 8.4, CORAL)], fmt=lambda v: "", base=640, top=240, width=220)
    c.text("the orange filter made no difference to sleep", 600, 780, 26, MUTED, "Bold")
    note(c, "Brigham Young University, 2021", y=830, size=20)
    c.save(f"{OUT}/fig-04-night-mode.png")

def hours():
    c = Canvas(); title(c, "Where the hour goes")
    hbars(c, [("the light", 10, GOLD), ("the scrolling", 75, CORAL), ("wired afterwards", 30, STONE)], fmt=lambda v: {10: "10 min", 75: "60 to 90 min", 30: "lighter sleep"}[v], x0=420, xmax=1000, y0=230, step=170, h=90, label_size=28, value_size=28, vmax=90)
    c.text("the filter can only touch the first one", 600, 790, 26, MUTED, "Bold")
    c.save(f"{OUT}/fig-06-hours.png")

def place():
    c = Canvas(); title(c, "The fix is a place")
    c.rrect(150, 180, 1050, 760, 40, WHITE, outline=FAINT, ow=5)
    c.rrect(200, 320, 560, 700, 30, SKY_SOFT); c.text("bed", 380, 510, 30, INK)
    c.rrect(930, 200, 1050, 380, 8, FAINT); c.text("door", 990, 290, 22, MUTED, "Bold")
    c.rrect(850, 640, 900, 720, 12, INK); c.text("phone, charging by the door", 875, 590, 24, INK, "Bold")
    c.rrect(600, 640, 680, 700, 16, GOLD); c.text("$10 alarm clock", 640, 735, 24, INK, "Bold")
    c.text("the phone does not sleep where you do", 600, 830, 26, MUTED, "Bold")
    c.save(f"{OUT}/fig-07-place.png")

if __name__ == "__main__":
    what_it_is(); study(); night_mode(); hours(); place()

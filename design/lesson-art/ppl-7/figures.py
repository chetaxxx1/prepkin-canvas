#!/usr/bin/env python3
"""Group projects: the page with what, who, when filled in one column at a time,
the rope pull, and one file."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

WHAT = ["10 slides on the causes", "the timeline, drawn and labelled", "the sources list, formatted", "the intro and the summary"]
WHO = ["Maya", "Sam", "Priya", "Leo"]
WHEN = ["Tue", "Thu", "Sat", "Mon"]

def page(c, cols):
    title(c, "One page")
    xs = [(130, 690), (700, 900), (910, 1070)]
    heads = ["what", "who", "when"]
    for k, (x0, x1) in enumerate(xs):
        on = k < cols
        c.rrect(x0, 160, x1, 230, 22, MINT if on else FAINT)
        c.text(heads[k], (x0 + x1) / 2, 195, 26, WHITE if on else MUTED)
    for i in range(4):
        y = 260 + i * 140
        c.rrect(130, y, 1070, y + 110, 26, WHITE, outline=FAINT, ow=4)
        vals = [WHAT[i], WHO[i], WHEN[i]]
        for k, (x0, x1) in enumerate(xs):
            if k < cols: c.text(vals[k], (x0 + x1) / 2 if k else x0 + 30, y + 55, 26, INK, "Bold", anchor="mm" if k else "lm")
            else: c.rrect(x0 + 24, y + 42, x1 - 24, y + 68, 10, FAINT)

def empty():
    c = Canvas(); page(c, 0); c.save(f"{OUT}/fig-02-page.png")

def what():
    c = Canvas(); page(c, 1); c.save(f"{OUT}/fig-03-what.png")

def who():
    c = Canvas(); page(c, 2); c.save(f"{OUT}/fig-04-who.png")

def when():
    c = Canvas(); page(c, 3); c.save(f"{OUT}/fig-05-when.png")

def rope():
    c = Canvas(); title(c, "Pull per person")
    vbars(c, [("pulling alone", 63, MINT), ("in a group of eight", 31, CORAL)], fmt=lambda v: f"{v} kg", base=660, top=220, width=300)
    note(c, "Ringelmann, 1880s", 840, size=22)
    c.save(f"{OUT}/fig-07-rope.png")

def one_file():
    c = Canvas(); title(c, "Where the page lives")
    columns(c, ("Three copies", ["three inboxes", "three versions", "work done twice"], STONE), ("One link", ["one page", "one version", "everyone sees the gaps"], MINT), y0=170, y1=780)
    c.save(f"{OUT}/fig-08-one-file.png")

if __name__ == "__main__":
    empty(); what(); who(); when(); rope(); one_file()

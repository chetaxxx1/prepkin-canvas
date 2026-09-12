#!/usr/bin/env python3
"""The planning fallacy: what it is, the thesis study, inside vs outside view, multiply by
1.5, parts add up."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def what_it_is():
    c = Canvas(); title(c, "The planning fallacy")
    hbars(c, [("the plan", 2, SKY), ("what happened", 3.3, CORAL)], fmt=lambda v: "", x0=380, xmax=1000, y0=260, step=200, h=100, label_size=28, vmax=3.5)
    c.text("everyone has it. Knowing does not cure it.", 600, 720, 26, MUTED, "Bold")
    c.save(f"{OUT}/fig-02-what-it-is.png")

def study():
    c = Canvas(); title(c, "When will your thesis be done?")
    vbars(c, [("the guess", 34, SKY), ("the reality", 56, CORAL)], fmt=lambda v: f"{v} days", base=680, top=220, width=300, gap=160)
    c.text("fewer than a third finished by the day they said", 600, 830, 24, MUTED, "Bold")
    note(c, "Buehler, Griffin and Ross, 1994", y=780, size=20)
    c.save(f"{OUT}/fig-03-study.png")

def why():
    c = Canvas(); title(c, "Inside view, outside view")
    c.line([(150, 300), (1050, 300)], SKY, 9); c.text("the plan: a straight line", 600, 240, 28, SKY, "Bold")
    pts = [(150, 560), (300, 540), (380, 640), (520, 600), (600, 700), (760, 660), (860, 740), (1050, 720)]
    c.line(pts, CORAL, 9)
    for x, y in pts[2:7:2]: c.dot(x, y, 18, GOLD)
    c.text("the reality: things come up", 600, 480, 28, CORAL, "Bold")
    c.save(f"{OUT}/fig-04-why.png")

def multiply():
    c = Canvas(); title(c, "No record? Multiply by 1.5")
    c.rrect(120, 260, 460, 560, 36, SKY); c.text("a weekend", 290, 380, 32, WHITE); c.text("your guess", 290, 450, 24, WHITE, "Bold")
    c.text("x 1.5", 600, 410, 44, INK)
    c.rrect(740, 260, 1080, 560, 36, CORAL); c.text("three days", 910, 380, 32, WHITE); c.text("plan for this", 910, 450, 24, WHITE, "Bold")
    c.text("the students were off by 1.6", 600, 700, 26, MUTED, "Bold")
    c.save(f"{OUT}/fig-06-multiply.png")

def parts():
    c = Canvas(); title(c, "Parts add up bigger than the whole")
    c.rrect(160, 300, 460, 620, 34, SKY); c.text("'about", 310, 430, 30, WHITE); c.text("five hours'", 310, 480, 30, WHITE)
    stack(c, [("reading", 2, GOLD), ("outline", 1, MINT), ("draft", 4, CORAL), ("edits", 2, SKY)], x0=680, x1=980, top=180, bottom=760, fmt=lambda v: f"{v}h", label_size=22, value_size=28)
    c.text("9 hours", 830, 130, 32, INK)
    c.text("one guess", 310, 680, 26, MUTED, "Bold")
    c.save(f"{OUT}/fig-07-parts.png")

if __name__ == "__main__":
    what_it_is(); study(); why(); multiply(); parts()

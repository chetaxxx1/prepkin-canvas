#!/usr/bin/env python3
"""Sleep is part of studying: five cycles, the early and late jobs, a cut night, and
Jenkins and Dallenbach 1924."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))
DEEP = (111, 130, 200); REM = (190, 140, 220)

def night(c, y=380, h=160, highlight=None, cut=None):
    x0, x1 = 120, 1080; n = 5; w = (x1 - x0) / n
    for i in range(n):
        if cut is not None and i >= cut: col = FAINT
        elif highlight == "early": col = DEEP if i < 2 else FAINT
        elif highlight == "late": col = REM if i >= 3 else FAINT
        else: col = SKY
        c.rrect(x0 + i * w + 6, y, x0 + (i + 1) * w - 6, y + h, 24, col)
        c.text(f"cycle {i + 1}", x0 + (i + 0.5) * w, y + h + 40, 22, MUTED, "Bold")
    c.text("11pm", x0, y - 40, 22, MUTED, "Bold"); c.text("7am", x1, y - 40, 22, MUTED, "Bold")

def cycles():
    c = Canvas(); title(c, "A full night: about five cycles"); night(c)
    note(c, "ninety minutes each", 700)
    c.save(f"{OUT}/fig-02-cycles.png")

def early():
    c = Canvas(); title(c, "Early in the night: the filing shift"); night(c, highlight="early")
    note(c, "deep sleep moves the day's facts into long-term storage", 700, size=22)
    c.save(f"{OUT}/fig-03-early.png")

def late():
    c = Canvas(); title(c, "Late in the night: the connecting shift"); night(c, highlight="late")
    note(c, "dream sleep links the new facts to what you already knew", 700, size=22)
    c.save(f"{OUT}/fig-04-late.png")

def cut_night():
    c = Canvas(); title(c, "Cut the night to four hours")
    night(c, y=300, h=120, cut=3)
    c.text("filing: kept", 320, 260, 24, DEEP, "Bold"); c.text("connecting: lost", 890, 260, 24, CORAL, "Bold")
    note(c, "skip the night and you lose both. Studying at 3am writes to a drive that will not save.", 700, size=22)
    c.save(f"{OUT}/fig-05-cut-night.png")

def evidence():
    c = Canvas(); title(c, "Eight hours later, how much was left")
    vbars(c, [("learned it,\nthen slept", 56, MINT), ("learned it,\nstayed awake", 9, STONE)], fmt=lambda v: f"{v}%", base=680, top=220, width=280)
    note(c, "Jenkins and Dallenbach, 1924, lists of syllables", 840, size=22)
    c.save(f"{OUT}/fig-07-evidence.png")

def plan():
    c = Canvas(); title(c, "Test week")
    steps(c, [("Earlier in the week", "do the real studying here", SKY), ("The last two nights", "full nights, no exceptions", DEEP), ("The night before", "a short review, then an early lights-out", MINT)], y0=190, h=170)
    c.save(f"{OUT}/fig-09-plan.png")

if __name__ == "__main__":
    cycles(); early(); late(); cut_night(); evidence(); plan()

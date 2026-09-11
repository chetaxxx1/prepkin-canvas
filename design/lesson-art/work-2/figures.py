#!/usr/bin/env python3
"""Your number: the hidden range, under the floor, sticky, ten years, ask back,
and your own range."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def rangebar(c, lo, hi, vmin=50000, vmax=90000, y=460, marks=(), hidden=False):
    x0, x1 = 160, 1040
    X = lambda v: x0 + (x1 - x0) * (v - vmin) / (vmax - vmin)
    c.rrect(x0, y - 16, x1, y + 16, 16, FAINT)
    c.rrect(X(lo), y - 40, X(hi), y + 40, 30, STONE if hidden else MINT)
    if not hidden:
        c.text(money(lo), X(lo), y - 80, 26, MINT, "Bold"); c.text("floor", X(lo), y - 118, 20, MUTED, "Bold")
        c.text(money(hi), X(hi), y - 80, 26, MINT, "Bold"); c.text("ceiling", X(hi), y - 118, 20, MUTED, "Bold")
    for v, label, col in marks:
        c.dot(X(v), y, 24, col); c.text(money(v), X(v), y + 90, 30, col); c.text(label, X(v), y + 132, 22, MUTED, "Bold")
    return X

def the_range():
    c = Canvas(); title(c, "What you can't see")
    X = rangebar(c, 65000, 80000, hidden=True)
    c.text("?", X(72500), 460, 40, WHITE)
    note(c, "a floor and a ceiling, approved before the job was posted", 700, size=22)
    c.save(f"{OUT}/fig-03-range.png")

def under_floor():
    c = Canvas(); title(c, "Under the floor")
    rangebar(c, 65000, 80000, marks=[(60000, "what you said", CORAL)])
    note(c, "you landed under a range you never saw", 720)
    c.save(f"{OUT}/fig-04-under-floor.png")

def sticky():
    c = Canvas(); title(c, "The first number is sticky")
    X = rangebar(c, 65000, 80000, marks=[(60000, "what you said", CORAL)])
    c.rrect(X(59000), 680, X(66000), 740, 20, CORAL_SOFT); c.text("the rest of the call", X(62500), 710, 22, CORAL, "Bold")
    c.text("never comes up", X(80000), 710, 22, MUTED, "Bold")
    c.save(f"{OUT}/fig-05-sticky.png")

def ten_years():
    c = Canvas(); title(c, "It follows you")
    x0, x1, y0, y1 = 200, 1040, 200, 680
    axes(c, x0, x1, y0, y1, 10, 100000, 25000, 5, fmt=lambda v: f"${v // 1000}k", xunit="years")
    lo = curve(c, lambda t: 60000 * 1.03 ** t, 10, x0, x1, y0, y1, 100000, CORAL)
    hi = curve(c, lambda t: 65000 * 1.03 ** t, 10, x0, x1, y0, y1, 100000, MINT)
    legend(c, [("said $65,000", MINT), ("said $60,000", CORAL)], 760, x0=330, gap=300)
    note(c, "with 3% raises, the gap adds up to about $57,000 over ten years", 830, size=22)
    c.save(f"{OUT}/fig-06-ten-years.png")

def ask_back():
    c = Canvas()
    y = bubbles(c, [("So what are you looking for, salary-wise?", "them"), ("What range is budgeted for this role?", "me"), ("We're looking at sixty-five to eighty.", "them")])
    c.text("now you are negotiating inside their numbers", 600, y + 30, 24, MINT, "Bold")
    c.save(f"{OUT}/fig-08-ask-back.png")

def your_range():
    c = Canvas(); title(c, "If you must go first")
    X = rangebar(c, 70000, 80000)
    c.text("the number you want goes at the bottom", X(75000), 600, 24, INK, "Bold")
    note(c, "the lowest number you say is the one they work from", 720)
    c.save(f"{OUT}/fig-09-your-range.png")

if __name__ == "__main__":
    the_range(); under_floor(); sticky(); ten_years(); ask_back(); your_range()

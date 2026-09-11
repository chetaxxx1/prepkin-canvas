#!/usr/bin/env python3
"""Mix the problems up: two orders, the unlabelled test, Rohrer and Taylor 2007, the
first question, and the week."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def tiles(c, seq, y, x0=150, s=110, gap=20):
    for i, ch in enumerate(seq):
        x = x0 + i * (s + gap)
        c.rrect(x, y, x + s, y + s, 24, CORAL if ch == "A" else SKY)
        c.text(ch, x + s / 2, y + s / 2, 44, WHITE)

def two_orders():
    c = Canvas(); title(c, "Two orders, same problems")
    c.text("blocked: run the method", 600, 200, 28, INK); tiles(c, "AAAABBBB", 240)
    c.text("mixed: choose the method, then run it", 600, 480, 28, INK); tiles(c, "ABBABAAB", 520)
    note(c, "on a mixed page, every problem starts with 'what kind is this?'", 720, size=22)
    c.save(f"{OUT}/fig-02-two-orders.png")

def unlabelled():
    c = Canvas(); title(c, "Homework has headings. The test does not.")
    for k, (head, x0) in enumerate((("homework", 110), ("the test", 630))):
        c.rrect(x0, 170, x0 + 460, 800, 24, WHITE, outline=FAINT, ow=4)
        c.text(head, x0 + 230, 220, 28, MUTED, "Bold")
        for i in range(5):
            y = 290 + i * 100
            if k == 0 and i in (0, 3):
                c.rrect(x0 + 40, y, x0 + 260, y + 26, 8, CORAL if i == 0 else SKY)
                y += 40
            c.rrect(x0 + 40, y, x0 + 420, y + 16, 6, FAINT); c.rrect(x0 + 40, y + 28, x0 + 300, y + 44, 6, FAINT)
    c.save(f"{OUT}/fig-03-unlabelled.png")

def research():
    c = Canvas(); title(c, "Practice score, then the test a week later")
    vbars(c, [("blocked,\nin practice", 89, STONE), ("blocked,\non the test", 20, CORAL), ("mixed,\nin practice", 60, STONE), ("mixed,\non the test", 63, MINT)], fmt=lambda v: f"{v}%", base=660, top=200, width=180)
    note(c, "Rohrer and Taylor, 2007, students learning geometry", 840, size=22)
    c.save(f"{OUT}/fig-05-research.png")

def first_question():
    c = Canvas()
    c.rrect(160, 220, 1040, 620, 40, INK)
    c.text("Before you solve it:", 600, 330, 30, WHITE, "Bold")
    c.text("what kind of problem is this,", 600, 420, 36, WHITE); c.text("and how do I know?", 600, 480, 36, WHITE)
    note(c, "say it out loud. That sentence is the skill the test checks.", 720, size=22)
    c.save(f"{OUT}/fig-07-first-question.png")

def week():
    c = Canvas(); title(c, "The week")
    days = [("Mon", "learn A", CORAL), ("Tue", "learn B", SKY), ("Wed", "mixed", MINT), ("Thu", "mixed", MINT), ("Fri", "mixed", MINT)]
    for i, (d, what, col) in enumerate(days):
        x = 110 + i * 200
        c.text(d, x + 85, 230, 26, MUTED, "Bold")
        c.rrect(x, 270, x + 170, 560, 30, col); c.text(what, x + 85, 415, 26, WHITE, "Bold")
    note(c, "learn each type alone once, then every session is mixed", 680)
    c.save(f"{OUT}/fig-09-week.png")

if __name__ == "__main__":
    two_orders(); unlabelled(); research(); first_question(); week()

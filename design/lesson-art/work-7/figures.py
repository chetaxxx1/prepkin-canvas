#!/usr/bin/env python3
"""Quitting well: what notice is, who hears first, the three-line email, the counteroffer,
the exit interview."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def notice():
    c = Canvas(); title(c, "Two weeks' notice")
    x0, x1, y = 150, 1050, 470
    c.rrect(x0, y - 10, x1, y + 10, 10, FAINT)
    days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Mon", "Tue", "Wed", "Thu", "Fri"]
    for i, d in enumerate(days):
        x = x0 + 60 + i * 87
        c.dot(x, y, 20, MINT if i not in (0, 9) else CORAL)
        c.text(d, x, y + 56, 22, MUTED, "Bold")
    c.text("you tell them", x0 + 60, y - 70, 28, CORAL); c.text("last day", x0 + 60 + 9 * 87, y - 70, 28, CORAL)
    c.rrect(200, 660, 1000, 750, 30, GOLD_SOFT); c.text("a custom, not a law. Give it anyway.", 600, 705, 28, INK, "Bold")
    c.save(f"{OUT}/fig-02-notice.png")

def order():
    c = Canvas(); title(c, "Who hears first")
    steps(c, [("Your manager", "live, in person or on a call", CORAL), ("A short email", "confirming the date, same day", SKY), ("Your team", "once your manager says so", MINT)], y0=180, h=160, step=185)
    c.text("never Slack first, never a coworker first", 600, 800, 26, MUTED, "Bold")
    c.save(f"{OUT}/fig-03-order.png")

def email():
    c = Canvas()
    c.rrect(150, 130, 1050, 820, 40, WHITE, outline=FAINT, ow=5)
    c.text("Re: Resignation", 200, 200, 30, INK, anchor="lm"); c.line([(200, 240), (1000, 240)], FAINT, 3)
    lines = ["Hi Dana,", "", "I'm writing to confirm that I'm resigning.", "My last day will be Friday the 24th.", "",
             "Thank you for the last two years. I learned", "a lot here and I'll make the handover easy.", "", "Sam"]
    for i, ln in enumerate(lines):
        if ln: c.text(ln, 200, 300 + i * 50, 28, INK, "Bold", anchor="lm")
    c.text("written for the person who reads it in two years", 600, 790, 22, MUTED, "Bold")
    c.save(f"{OUT}/fig-05-email.png")

def counter():
    c = Canvas(); title(c, "A counteroffer fixes")
    columns(c, ("The pay", ["the number", "for now"], MINT), ("Not the reason", ["the manager", "the work", "the ceiling"], STONE), y0=170, y1=720)
    c.text("ask what else changes. If nothing, the answer is no.", 600, 800, 26, MUTED, "Bold")
    c.save(f"{OUT}/fig-06-counter.png")

def exit_interview():
    c = Canvas(); title(c, "The exit interview")
    columns(c, ("Say", ["I wanted a bigger role", "the growth here slowed", "thank you"], MINT),
            ("Don't", ["names", "who was difficult", "the rant"], CORAL), y0=170, y1=780)
    c.save(f"{OUT}/fig-08-exit.png")

if __name__ == "__main__":
    notice(); order(); email(); counter(); exit_interview()

#!/usr/bin/env python3
"""Ask for the reference before you need it: what it is, when to ask, the sentence, the one
page, lead times."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def what_it_is():
    c = Canvas(); title(c, "Two kinds")
    columns(c, ("A reference", ["a person they call", "'what were they like?'", "for jobs"], SKY),
            ("A letter", ["the same, written down", "one to two pages", "for grad school"], MINT), y0=170, y1=780)
    c.save(f"{OUT}/fig-02-what-it-is.png")

def when():
    c = Canvas(); title(c, "How well they remember you")
    x0, x1, y0, y1 = 170, 1080, 170, 700
    axes(c, x0, x1, y0, y1, xmax=24, ymax=100, ystep=25, xstep=6, fmt=lambda v: "", xunit="months")
    curve(c, lambda t: 100 * 0.5 ** (t / 5), 24, x0, x1, y0, y1, 100, SKY, fill=SKY_SOFT)
    c.dot(x0, y0, 16, MINT); c.text("ask here", x0 + 40, y0 + 30, 30, MINT, anchor="lm")
    xn = x0 + (x1 - x0) * 22 / 24; c.dot(xn, y1 - (y1 - y0) * (100 * 0.5 ** (22 / 5)) / 100, 16, CORAL)
    c.text("you need it here", 990, 585, 28, CORAL, "Bold", anchor="rm")
    c.save(f"{OUT}/fig-03-when.png")

def sentence():
    c = Canvas()
    y = bubbles(c, [("Would you be comfortable being a strong reference for me?", "me"), ("Of course. Send me the details whenever you need it.", "them")], y0=170)
    c.rrect(190, y + 10, 1010, y + 90, 26, GOLD_SOFT)
    c.text("'comfortable' gives them an out. If they hesitate, ask someone else.", 600, y + 50, 22, INK, "Bold")
    c.save(f"{OUT}/fig-04-sentence.png")

def one_page():
    c = Canvas(); title(c, "The one page you send")
    c.rrect(250, 150, 950, 840, 28, WHITE, outline=FAINT, ow=4)
    rows = [("The job", "title, company, a link", SKY), ("The deadline", "when they will call, or when the letter is due", CORAL),
            ("What I did for you", "three lines, with numbers", GOLD), ("Two things to mention", "if you agree they are true", MINT)]
    for i, (h, s, col) in enumerate(rows):
        y = 200 + i * 160
        c.rrect(290, y, 310, y + 120, 8, col)
        c.text(h, 340, y + 35, 30, INK, anchor="lm")
        for j, ln in enumerate(wrap(c, s, 22, 560)): c.text(ln, 340, y + 80 + j * 30, 22, MUTED, "Bold", anchor="lm")
    c.save(f"{OUT}/fig-06-one-page.png")

def lead_time():
    c = Canvas(); title(c, "Warning they need")
    hbars(c, [("a phone reference", 1, SKY), ("a letter", 4, GOLD), ("a grad school letter", 6, CORAL)],
          fmt=lambda v: f"{v} week" if v == 1 else f"{v} weeks", x0=470, xmax=1020, y0=230, step=170, h=90, label_size=28, value_size=30, vmax=6.6)
    note(c, "a letter due Friday is a no, or a bad one", y=790)
    c.save(f"{OUT}/fig-07-lead-time.png")

if __name__ == "__main__":
    what_it_is(); when(); sentence(); one_page(); lead_time()

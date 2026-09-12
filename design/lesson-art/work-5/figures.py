#!/usr/bin/env python3
"""Your first week: what onboarding is, the four lists, the rising price of a question,
the one question for your manager, the name trick."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def what_it_is():
    c = Canvas(); title(c, "Week one is for")
    columns(c, ("Not this", ["shipping something", "proving yourself", "knowing the answer"], STONE),
            ("This", ["asking", "watching", "writing it down"], MINT), y0=170, y1=780)
    c.save(f"{OUT}/fig-02-what-it-is.png")

def four_lists():
    c = Canvas(); title(c, "Four lists, from the first hour")
    tiles = [("Names", "and what each one owns", SKY), ("Words", "acronyms you did not know", GOLD),
             ("Places", "where things live", MINT), ("Questions", "not asked yet", CORAL)]
    for i, (head, sub, col) in enumerate(tiles):
        x0 = 110 + (i % 2) * 500; y0 = 170 + (i // 2) * 320
        c.rrect(x0, y0, x0 + 480, y0 + 280, 36, WHITE, outline=FAINT, ow=4)
        c.rrect(x0 + 30, y0 + 30, x0 + 90, y0 + 90, 18, col)
        c.text(head, x0 + 120, y0 + 60, 36, INK, anchor="lm")
        c.text(sub, x0 + 40, y0 + 160, 26, MUTED, "Bold", anchor="lm")
        for j in range(3):
            c.rrect(x0 + 40, y0 + 200 + j * 24, x0 + 40 + (300 - j * 70), y0 + 212 + j * 24, 6, FAINT)
    c.save(f"{OUT}/fig-03-four-lists.png")

def price():
    c = Canvas(); title(c, "What a question costs")
    x0, x1, y0, y1 = 170, 1080, 170, 700
    axes(c, x0, x1, y0, y1, xmax=6, ymax=100, ystep=25, xstep=1, fmt=lambda v: "", xunit="months")
    pts = curve(c, lambda t: 4 + 96 * (t / 6) ** 2.2, 6, x0, x1, y0, y1, 100, CORAL, fill=CORAL_SOFT)
    c.text("free", x0 + 60, y1 - 70, 30, MINT)
    c.text("a little pride", 520, 500, 28, INK, "Bold")
    c.text("'you still don't know that?'", 1000, 200, 28, CORAL, "Bold", anchor="rm")
    c.save(f"{OUT}/fig-05-price.png")

def one_question():
    c = Canvas()
    y = bubbles(c, [("What does good look like at ninety days?", "me"),
                    ("Honestly? If the Tuesday report goes out without me checking it, you're there.", "them")], y0=170)
    c.rrect(190, y + 10, 1010, y + 90, 26, MINT_SOFT)
    c.text("write that down, word for word", 600, y + 50, 28, INK, "Bold")
    c.save(f"{OUT}/fig-06-one-question.png")

def names():
    c = Canvas(); title(c, "Twelve names by Friday")
    for k, (label, kept, col) in enumerate([("heard once", 3, STONE), ("written down, with one fact", 12, MINT)]):
        y = 250 + k * 280
        c.text(label, 600, y - 60, 30, INK, "Bold")
        for i in range(12):
            x = 200 + i * 73
            c.dot(x, y + 40, 28, col if i < kept else FAINT)
        c.text(f"{kept} left", 1080, y + 40, 30, INK, anchor="lm")
    c.text("'Priya, Tuesday report, has a dog'", 600, 800, 26, MUTED, "Bold")
    c.save(f"{OUT}/fig-08-names.png")

if __name__ == "__main__":
    what_it_is(); four_lists(); price(); one_question(); names()

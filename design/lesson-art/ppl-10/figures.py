#!/usr/bin/env python3
"""A compliment that sticks: what it is, name the thing, choice over talent, where it counts
double, timing."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def what_it_is():
    c = Canvas(); title(c, "Information in it")
    hbars(c, [("'Great job!'", 0.4, STONE), ("'The pause before the numbers worked.'", 9, MINT)],
          fmt=lambda v: "nothing to repeat" if v < 1 else "something to do again", x0=110, xmax=760, y0=260, step=200, h=100, label_size=26, value_size=24, vmax=10)
    c.save(f"{OUT}/fig-02-what-it-is.png")

def what_it_is():
    c = Canvas(); title(c, "What a compliment is for")
    columns(c, ("'Great job'", ["a rating", "no information", "gone by lunch"], STONE),
            ("Specific praise", ["what worked", "so they do it again", "proof you noticed"], MINT), y0=170, y1=780)
    c.save(f"{OUT}/fig-02-what-it-is.png")

def specific():
    c = Canvas()
    c.rrect(100, 160, 1100, 300, 34, FAINT); c.text("'Great job!'", 600, 230, 34, MUTED, "Bold")
    c.rrect(100, 360, 1100, 600, 34, MINT_SOFT)
    for i, ln in enumerate(["'The way you paused before the", "numbers made everyone look up.'"]):
        c.text(ln, 600, 440 + i * 50, 32, INK, "Bold")
    c.text("worth fifty of the first one", 600, 700, 28, MINT)
    c.save(f"{OUT}/fig-03-specific.png")

def choice():
    c = Canvas(); title(c, "Praise the choice, not the trait")
    columns(c, ("'You're so smart'", ["about what they are", "afraid to look dumb next time", "nothing to repeat"], STONE),
            ("'You practised it'", ["about what they chose", "wants to practise again", "repeatable"], MINT), y0=170, y1=780, item_h=80, gap=26)
    c.save(f"{OUT}/fig-04-choice.png")

def two_places():
    c = Canvas(); title(c, "Where it counts double")
    tiles = [("In front of others", "costs you nothing, gives them status", SKY), ("To their boss", "two lines can change their year", GOLD)]
    for i, (h, s, col) in enumerate(tiles):
        x0 = 100 + i * 520
        c.rrect(x0, 180, x0 + 480, 700, 36, col)
        c.text(h, x0 + 240, 300, 34, WHITE if col == SKY else INK)
        for j, ln in enumerate(wrap(c, s, 26, 400)): c.text(ln, x0 + 240, 420 + j * 40, 26, WHITE if col == SKY else INK, "Bold")
    c.text("both are rare, so both land", 600, 790, 26, MUTED, "Bold")
    c.save(f"{OUT}/fig-06-two-places.png")

def timing():
    c = Canvas(); title(c, "Soon beats perfect")
    hbars(c, [("same day", 10, MINT), ("this week", 7, GOLD), ("a perfect one, never sent", 0.3, STONE)],
          fmt=lambda v: "" , x0=520, xmax=1080, y0=230, step=170, h=90, label_size=28, vmax=10)
    c.text("a text works. Two lines work.", 600, 790, 26, MUTED, "Bold")
    c.save(f"{OUT}/fig-08-timing.png")

if __name__ == "__main__":
    what_it_is(); specific(); choice(); two_places(); timing()

#!/usr/bin/env python3
"""A resume gets seven seconds: what it is, the F-shaped first look, the bullet shape,
what to cut, matching the posting."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def page(c, x0=330, y0=120, x1=870, y1=840):
    c.rrect(x0, y0, x1, y1, 24, WHITE, outline=FAINT, ow=4)
    c.rrect(x0 + 50, y0 + 50, x0 + 260, y0 + 78, 10, STONE)      # name
    c.rrect(x0 + 50, y0 + 100, x0 + 200, y0 + 114, 7, FAINT)      # contact
    y = y0 + 170
    for block in range(3):
        c.rrect(x0 + 50, y, x0 + 230, y + 18, 8, STONE); y += 40
        for f in (0.85, 0.7, 0.8):
            c.rrect(x0 + 70, y, x0 + 70 + (x1 - x0 - 120) * f, y + 12, 6, FAINT); y += 30
        y += 30

def what_it_is():
    c = Canvas(); title(c, "One page, one argument")
    page(c, 330, 140, 870, 840)
    c.rrect(380, 440, 820, 520, 30, CORAL_SOFT); c.text("'I can do this job'", 600, 480, 34, CORAL)
    c.save(f"{OUT}/fig-02-what-it-is.png")

def eyes():
    c = Canvas(); title(c, "Where the eyes go first")
    page(c, 330, 140, 870, 840)
    # the F: top bar, second bar, left stem
    c.rrect(360, 180, 840, 270, 20, (255, 111, 97, 110))
    c.rrect(360, 300, 700, 360, 20, (255, 111, 97, 90))
    c.rrect(360, 360, 440, 800, 20, (255, 111, 97, 70))
    c.text("name, latest job,", 1010, 240, 26, INK, "Bold"); c.text("first bullet", 1010, 276, 26, INK, "Bold")
    c.text("the left edge", 190, 600, 26, INK, "Bold")
    c.save(f"{OUT}/fig-03-eyes.png")

def bullet():
    c = Canvas(); title(c, "Verb, what, number")
    c.rrect(100, 180, 1100, 330, 34, FAINT)
    c.text("Ran the club's Instagram", 600, 255, 32, MUTED, "Bold")
    c.rrect(100, 400, 1100, 620, 34, MINT_SOFT)
    c.text("Grew the club's Instagram from 200 to", 600, 480, 32, INK, "Bold")
    c.text("1,400 followers in a year", 600, 540, 32, INK, "Bold")
    c.dot(300, 700, 16, SKY); c.text("verb", 330, 700, 26, INK, "Bold", anchor="lm")
    c.dot(520, 700, 16, GOLD); c.text("what", 550, 700, 26, INK, "Bold", anchor="lm")
    c.dot(740, 700, 16, CORAL); c.text("number", 770, 700, 26, INK, "Bold", anchor="lm")
    c.save(f"{OUT}/fig-04-bullet.png")

def cut():
    c = Canvas(); title(c, "Cut")
    items = ["Objective: seeking a challenging role...", "References available on request", "Westlake High School, 2020", "Hard-working, passionate, detail-oriented"]
    for i, it in enumerate(items):
        y = 210 + i * 130
        c.rrect(120, y, 1080, y + 90, 26, WHITE, outline=FAINT, ow=4)
        c.text(it, 600, y + 45, 28, MUTED, "Bold")
        w = c.width(it, 28, "Bold"); c.strike(600 - w / 2 - 10, y + 45, 600 + w / 2 + 10, y + 45, CORAL, 7)
    c.text("a claim is not proof. A number is.", 600, 790, 26, MUTED, "Bold")
    c.save(f"{OUT}/fig-06-cut.png")

def keywords():
    c = Canvas(); title(c, "Use the posting's words")
    c.rrect(90, 170, 570, 800, 36, FAINT); c.rrect(630, 170, 1110, 800, 36, WHITE, outline=FAINT, ow=4)
    c.text("The posting", 330, 230, 30, INK); c.text("Your resume", 870, 230, 30, INK)
    pairs = [("data analysis", "data analysis", True), ("SQL", "SQL", True), ("stakeholders", "crunching numbers", False)]
    for i, (a, b, ok) in enumerate(pairs):
        y = 320 + i * 130
        c.rrect(130, y, 530, y + 80, 24, MINT_SOFT if ok else GOLD_SOFT); c.text(a, 330, y + 40, 28, INK, "Bold")
        c.rrect(670, y, 1070, y + 80, 24, MINT_SOFT if ok else CORAL_SOFT); c.text(b, 870, y + 40, 28, INK if ok else CORAL, "Bold")
    c.text("software reads the words before a person does", 600, 760, 24, MUTED, "Bold")
    c.save(f"{OUT}/fig-07-keywords.png")

if __name__ == "__main__":
    what_it_is(); eyes(); bullet(); cut(); keywords()

#!/usr/bin/env python3
"""Why rare things feel common: the search results, sharks against drownings, the
letter R, out of how many, and the two questions."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def search():
    c = Canvas(); title(c, "What your brain returns first")
    rows = [("shark attack", "loud: a video, a headline", CORAL, 1.0), ("jellyfish sting", "a story someone told", GOLD, 0.6), ("rip current", "quiet", STONE, 0.3), ("drowning", "quietest, and the real risk", STONE, 0.2)]
    for i, (head, sub, col, w) in enumerate(rows):
        y = 190 + i * 150
        c.rrect(120, y, 1080, y + 120, 30, WHITE, outline=FAINT, ow=4)
        c.rrect(140, y + 20, 140 + 300 * w, y + 100, 20, col)
        c.text(head, 480, y + 44, 28, INK, anchor="lm"); c.text(sub, 480, y + 86, 22, MUTED, "Bold", anchor="lm")
    c.save(f"{OUT}/fig-02-search.png")

def numbers():
    c = Canvas(); title(c, "A year in the US")
    vbars(c, [("killed by sharks", 1, CORAL), ("drowned", 4000, SKY)], fmt=lambda v: f"about {v:,}", base=660, top=220, width=300, vmax=4000)
    note(c, "the one that comes to mind first is the rare one", 830)
    c.save(f"{OUT}/fig-03-numbers.png")

def letter_r():
    c = Canvas(); title(c, "The letter R")
    columns(c, ("First letter", ["run, red, river", "arrive fast", "feels common"], STONE), ("Third letter", ["car, word, park", "arrive slowly", "is common"], MINT), y0=170, y1=780)
    c.save(f"{OUT}/fig-05-letter-r.png")

def out_of_how_many():
    c = Canvas()
    c.rrect(160, 200, 1040, 640, 40, INK)
    c.text("Not 'what comes to mind'.", 600, 330, 34, WHITE); c.text("'Out of how many?'", 600, 410, 40, WHITE)
    c.text("a count beats a memory every time", 600, 540, 24, MINT, "Bold")
    c.save(f"{OUT}/fig-06-out-of-how-many.png")

def two_questions():
    c = Canvas(); title(c, "When something feels likely")
    steps(c, [("What made me think of it?", "if the answer is 'a story', the feeling is not data", CORAL), ("Out of how many?", "two cases out of millions of meals", MINT)], y0=230, h=190)
    c.save(f"{OUT}/fig-09-two-questions.png")

if __name__ == "__main__":
    search(); numbers(); letter_r(); out_of_how_many(); two_questions()

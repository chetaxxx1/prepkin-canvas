#!/usr/bin/env python3
"""How to read a chapter once: headings into questions, search vs scan, four
sentences, no headings, and the whole recipe."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def headings():
    c = Canvas(); title(c, "Headings into questions")
    pairs = [("Cell division", "How does a cell divide?"), ("The cell membrane", "What does the membrane let through?"), ("Mitochondria", "What do mitochondria do?")]
    for i, (h, q) in enumerate(pairs):
        y = 200 + i * 190
        c.rrect(90, y, 480, y + 120, 30, FAINT); c.text(h, 285, y + 60, 26, INK, "Bold")
        arrow(c, 500, y + 60, 590, y + 60, STONE, 6)
        c.rrect(610, y, 1110, y + 120, 30, MINT_SOFT); c.text(q, 860, y + 60, 24, INK, "Bold")
    note(c, "two minutes with the contents page, and that is the whole setup", 800, size=22)
    c.save(f"{OUT}/fig-02-headings.png")

def search_vs_scan():
    c = Canvas(); title(c, "Scanning or searching")
    columns(c, ("No question", ["eyes move over the page", "nothing to notice", "read it again"], STONE), ("With a question", ["you are looking for something", "you notice when it arrives", "read it once"], MINT), y0=170, y1=780)
    c.save(f"{OUT}/fig-03-search-vs-scan.png")

def four_sentences():
    c = Canvas(); title(c, "Book shut. Four sentences.")
    c.rrect(200, 180, 1000, 780, 24, WHITE, outline=FAINT, ow=4)
    for i in range(4):
        y = 250 + i * 130
        c.dot(260, y + 20, 18, MINT); c.text(str(i + 1), 260, y + 20, 20, WHITE)
        c.rrect(300, y + 8, 940 - (i % 2) * 90, y + 32, 8, FAINT); c.rrect(300, y + 48, 760 - (i % 3) * 60, y + 72, 8, FAINT)
    note(c, "that is your whole set of notes", 830)
    c.save(f"{OUT}/fig-05-four-sentences.png")

def no_headings():
    c = Canvas(); title(c, "No headings? Use first lines.")
    c.rrect(160, 170, 1040, 800, 24, WHITE, outline=FAINT, ow=4)
    for p in range(3):
        y = 230 + p * 190
        c.rrect(200, y, 1000, y + 26, 8, MINT)
        for j in range(3): c.rrect(200, y + 44 + j * 34, 1000 - (j == 2) * 300, y + 60 + j * 34, 6, FAINT)
    note(c, "the first line of each paragraph is the heading it did not print", 840, size=22)
    c.save(f"{OUT}/fig-07-no-headings.png")

def recipe():
    c = Canvas(); title(c, "One pass")
    steps(c, [("Turn the headings into questions", "", SKY), ("Read once, looking for the answers", "", SKY), ("Shut the book", "", CORAL), ("Write four sentences", "", MINT), ("Open it and check", "", GOLD)], y0=170, h=110, step=130)
    c.save(f"{OUT}/fig-09-recipe.png")

if __name__ == "__main__":
    headings(); search_vs_scan(); four_sentences(); no_headings(); recipe()

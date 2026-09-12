#!/usr/bin/env python3
"""How to leave a conversation: the 2% study, the mismatch, three moves, lines that work,
what not to do."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def study():
    c = Canvas(); title(c, "When conversations end")
    c.rrect(150, 300, 1050, 420, 30, STONE)
    c.rrect(150, 300, 150 + 900 * 0.02 + 18, 420, 30, MINT)
    c.text("2%", 150 + 30, 250, 34, MINT, anchor="lm"); c.text("ended when both people wanted", 150 + 100, 250, 26, MUTED, "Bold", anchor="lm")
    c.text("98%: at least one of them wanted out earlier", 600, 500, 28, INK, "Bold")
    note(c, "Mastroianni et al., 2021", y=780, size=20)
    c.save(f"{OUT}/fig-02-study.png")

def mismatch():
    c = Canvas(); title(c, "Nobody can tell")
    for k, (who, t, col) in enumerate([("you wanted out", 0.45, CORAL), ("they wanted out", 0.6, SKY)]):
        y = 300 + k * 200
        c.rrect(150, y - 8, 1050, y + 8, 8, FAINT)
        c.dot(150 + 900 * t, y, 24, col); c.text(who, 150 + 900 * t, y - 60, 28, col, "Bold")
    c.dot(1050, 300, 14, STONE); c.dot(1050, 500, 14, STONE); c.text("it ended", 1050, 560, 24, MUTED, "Bold")
    c.text("the awkward feeling is shared, and invisible", 600, 740, 26, MUTED, "Bold")
    c.save(f"{OUT}/fig-03-mismatch.png")

def three_moves():
    c = Canvas(); title(c, "Ten seconds")
    steps(c, [("Signal", "'Before I go...'", CORAL), ("Appreciate", "'It was great hearing about your trip.'", GOLD), ("Exit, to somewhere", "'I'm going to find a drink.'", MINT)], y0=180, h=160, step=185)
    c.save(f"{OUT}/fig-04-three-moves.png")

def lines():
    c = Canvas(); title(c, "Lines that work")
    rows = ["'I'm going to do a lap.'", "'I promised I'd find Sam.'", "'I need to head out, but this was fun.'", "'Let's talk again, I want to hear how the interview goes.'"]
    for i, r in enumerate(rows):
        y = 180 + i * 140
        c.rrect(120, y, 1080, y + 100, 30, WHITE, outline=FAINT, ow=4)
        c.text(r, 600, y + 50, 26, INK, "Bold")
    c.text("pick two. Keep them.", 600, 790, 26, MUTED, "Bold")
    c.save(f"{OUT}/fig-06-lines.png")

def dont():
    c = Canvas(); title(c, "All three say 'you were boring'")
    rows = ["fade away mid-sentence", "fake a phone call", "check your phone until they get it"]
    for i, r in enumerate(rows):
        y = 200 + i * 150
        c.rrect(120, y, 1080, y + 100, 30, WHITE, outline=FAINT, ow=4)
        c.text(r, 600, y + 50, 30, MUTED, "Bold")
        w = c.width(r, 30, "Bold"); c.strike(600 - w / 2 - 12, y + 50, 600 + w / 2 + 12, y + 50, CORAL, 7)
    c.rrect(200, 680, 1000, 770, 30, MINT_SOFT); c.text("the three moves say 'you were not'", 600, 725, 28, INK, "Bold")
    c.save(f"{OUT}/fig-08-dont.png")

if __name__ == "__main__":
    study(); mismatch(); three_moves(); lines(); dont()

#!/usr/bin/env python3
"""Disagree without a fight: what they said in pieces, the one piece, say it
back, then push, two ways, and one thing not five."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

PIECES = [("afternoons are too hot", True), ("people are wiped out by three", True), ("so practice should move to mornings", False)]

def pieces(c, mark_disagree):
    title(c, "What they said")
    for i, (txt, agree) in enumerate(PIECES):
        y = 200 + i * 170
        col = MINT if agree else (CORAL if mark_disagree else MINT)
        c.rrect(140, y, 1060, y + 130, 34, col)
        c.text(txt, 600, y + 65, 30, WHITE, "Bold")
    if mark_disagree: legend(c, [("you agree", MINT), ("the one piece", CORAL)], 760, x0=340, gap=300)
    else: note(c, "most of it, you agree with", 760)

def look_again():
    c = Canvas(); pieces(c, False); c.save(f"{OUT}/fig-02-look-again.png")

def one_piece():
    c = Canvas(); pieces(c, True); c.save(f"{OUT}/fig-03-one-piece.png")

def say_back():
    c = Canvas()
    y = bubbles(c, [("Afternoons are too hot. Everyone's dead by three. We should move to mornings.", "them"), ("You're right, afternoons are brutal.", "me")])
    c.text("they have nothing to defend", 600, y + 30, 24, MINT, "Bold")
    c.save(f"{OUT}/fig-04-say-back.png")

def then_push():
    c = Canvas()
    y = bubbles(c, [("You're right, afternoons are brutal.", "me"), ("The part I'd change is mornings. Half of us can't get there by seven.", "me"), ("Fair. Six thirty is rough. What about right after school?", "them")])
    c.save(f"{OUT}/fig-05-then-push.png")

def two_ways():
    c = Canvas(); title(c, "Two ways in")
    columns(c, ("Lead with no", ["they defend", "you defend", "nobody moves"], STONE), ("Agree, then edit", ["they relax", "one thing to fix", "the plan gets better"], MINT), y0=170, y1=780)
    c.save(f"{OUT}/fig-07-two-ways.png")

def one_thing():
    c = Canvas(); title(c, "One thing, not five")
    items = ["mornings", "the warm-up", "the playlist", "who brings water", "the group chat name"]
    for i, it in enumerate(items):
        y = 190 + i * 118
        on = i == 0
        c.rrect(200, y, 1000, y + 90, 28, MINT if on else FAINT)
        c.text(it, 600, y + 45, 28, WHITE if on else MUTED, "Bold")
    c.save(f"{OUT}/fig-08-one-thing.png")

if __name__ == "__main__":
    look_again(); one_piece(); say_back(); then_push(); two_ways(); one_thing()

#!/usr/bin/env python3
"""Small talk: the ladder, one rung at a time, follow-ups against switching, and
the exit line."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

RUNGS = ["Where are you from?", "What do you like about it?", "How did you get into that?"]

def ladder(c, lit):
    title(c, "The ladder")
    x0, x1 = 300, 900
    c.rrect(x0 - 40, 170, x0, 800, 20, STONE); c.rrect(x1, 170, x1 + 40, 800, 20, STONE)
    for i in range(3):
        y = 720 - i * 220
        on = i < lit
        c.rrect(x0, y - 50, x1, y + 50, 30, MINT if on else FAINT)
        if on: c.text(RUNGS[i], 600, y, 28, WHITE, "Bold")
        else: c.text("?", 600, y, 32, MUTED)
        c.text(f"rung {i + 1}", x0 - 70, y, 22, MUTED, "Bold", anchor="rm")

def rung(n):
    c = Canvas(); ladder(c, n); c.save(f"{OUT}/fig-0{n + 1}-rung{n}.png")

def followups():
    c = Canvas(); title(c, "Two ways to reply")
    columns(c, ("Ask a follow-up", ["shows you listened", "keeps them talking", "rated more likeable"], MINT), ("Switch to you", ["shows you were waiting", "resets the talk", "rated less likeable"], STONE), y0=170, y1=780)
    c.save(f"{OUT}/fig-07-followups.png")

def exit_line():
    c = Canvas()
    c.rrect(160, 200, 1040, 640, 40, INK)
    c.text("It was really nice talking to you.", 600, 340, 32, WHITE); c.text("I'm going to grab a drink.", 600, 400, 32, WHITE)
    c.text("smile, and go", 600, 530, 24, MINT, "Bold")
    c.save(f"{OUT}/fig-08-exit.png")

if __name__ == "__main__":
    [rung(n) for n in (1, 2, 3)]; followups(); exit_line()

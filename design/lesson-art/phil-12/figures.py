#!/usr/bin/env python3
"""The prisoner's dilemma: the matrix, the logic, the trap, repetition, tit for tat, the four
rules."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def grid(c, highlight=None, dim=None):
    x0, y0, w = 330, 220, 300
    c.text("They stay silent", x0 + w / 2, y0 - 40, 24, MUTED, "Bold"); c.text("They talk", x0 + w * 1.5, y0 - 40, 24, MUTED, "Bold")
    c.text("You stay", 260, y0 + w / 2 - 16, 24, MUTED, "Bold", anchor="rm"); c.text("silent", 260, y0 + w / 2 + 16, 24, MUTED, "Bold", anchor="rm")
    c.text("You talk", 260, y0 + w * 1.5, 24, MUTED, "Bold", anchor="rm")
    cells = {(0, 0): ("1 year each", MINT_SOFT), (0, 1): ("you: 10, them: 0", CORAL_SOFT), (1, 0): ("you: 0, them: 10", GOLD_SOFT), (1, 1): ("5 years each", FAINT)}
    for (r, k), (t, col) in cells.items():
        x = x0 + k * w; y = y0 + r * w
        strong = highlight == (r, k); faded = dim and (r, k) in dim
        c.rrect(x + 8, y + 8, x + w - 8, y + w - 8, 30, col if not strong else (CORAL if col == FAINT else MINT), outline=None)
        ink = WHITE if strong else (INK if not faded else STONE)
        for j, ln in enumerate(t.split(", ")):
            c.text(ln, x + w / 2, y + w / 2 - 20 + j * 44 if ", " in t else y + w / 2, 28, ink, "Bold")

def matrix():
    c = Canvas(); title(c, "The deal", y=90); grid(c)
    c.save(f"{OUT}/fig-02-matrix.png")

def logic():
    c = Canvas(); title(c, "Talking wins either way", y=90); grid(c, highlight=(1, 1), dim=[(0, 0), (0, 1)])
    c.text("0 beats 1. 5 beats 10.", 600, 860, 26, CORAL, "Bold")
    c.save(f"{OUT}/fig-03-logic.png")

def trap():
    c = Canvas(); title(c, "Better for both, reached by neither", y=90); grid(c, highlight=(0, 0), dim=[(0, 1), (1, 0)])
    c.text("1 year each was sitting right there", 600, 860, 26, MINT, "Bold")
    c.save(f"{OUT}/fig-04-trap.png")

def repeat():
    c = Canvas(); title(c, "Play it more than once")
    x0, x1, y = 150, 1050, 430
    c.rrect(x0, y - 8, x1, y + 8, 8, FAINT)
    for i in range(6):
        x = x0 + i * 180; c.dot(x, y, 26, MINT if i < 4 else CORAL if i == 4 else MINT)
        c.text(f"week {i + 1}", x, y + 66, 22, MUTED, "Bold")
    c.text("slack here", x0 + 4 * 180, y - 70, 26, CORAL, "Bold"); c.text("they remember", x0 + 5 * 180, y - 70, 26, INK, "Bold")
    c.text("repeating the game is what makes cooperating safe", 600, 720, 26, MUTED, "Bold")
    c.save(f"{OUT}/fig-06-repeat.png")

def tit_for_tat():
    c = Canvas(); title(c, "Tit for tat")
    rows = [("them", ["C", "C", "D", "C", "C"]), ("you", ["C", "C", "C", "D", "C"])]
    for k, (who, moves) in enumerate(rows):
        y = 260 + k * 200
        c.text(who, 200, y + 45, 28, MUTED, "Bold", anchor="rm")
        for i, m in enumerate(moves):
            x = 260 + i * 150
            c.rrect(x, y, x + 110, y + 90, 26, MINT if m == "C" else CORAL)
            c.text("nice" if m == "C" else "cheat", x + 55, y + 45, 24, WHITE)
    c.text("start nice, then copy their last move", 600, 720, 26, MUTED, "Bold")
    note(c, "Axelrod's tournament, 1980", y=800, size=20)
    c.save(f"{OUT}/fig-07-tit-for-tat.png")

def four_rules():
    c = Canvas(); title(c, "Why it won")
    tiles = [("Be nice", "never cheat first", MINT), ("Retaliate", "answer cheating at once", CORAL), ("Forgive", "cooperate as soon as they do", SKY), ("Be clear", "so they can predict you", GOLD)]
    for i, (h, s, col) in enumerate(tiles):
        x0 = 110 + (i % 2) * 500; y0 = 170 + (i // 2) * 320
        c.rrect(x0, y0, x0 + 480, y0 + 280, 36, col)
        ink = INK if col == GOLD else WHITE
        c.text(h, x0 + 240, y0 + 110, 36, ink); c.text(s, x0 + 240, y0 + 190, 24, ink, "Bold")
    c.save(f"{OUT}/fig-08-four-rules.png")

if __name__ == "__main__":
    matrix(); logic(); trap(); repeat(); tit_for_tat(); four_rules()

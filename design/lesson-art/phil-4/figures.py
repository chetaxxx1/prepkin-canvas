#!/usr/bin/env python3
"""The veil of ignorance: what you keep and lose, the one-question test, two late-work
rules, and the three prompts."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def keep_lose():
    c = Canvas(); title(c, "Behind the veil")
    columns(c, ("You keep", ["how the world works", "what people need", "what money does", "how rules play out"], MINT), ("You lose", ["your money", "your health", "your talents", "your family and country"], STONE), y0=160, y1=800)
    c.save(f"{OUT}/fig-02-keep-lose.png")

def test():
    c = Canvas()
    c.rrect(200, 120, 1000, 280, 40, INK); c.text("Would I still sign this rule", 600, 175, 32, WHITE); c.text("not knowing my seat?", 600, 225, 32, WHITE)
    for x, ans, col, what in ((330, "Yes", MINT, "it is fair"), (870, "No", CORAL, "change it")):
        c.line([(600, 280), (x, 420)], STONE, 6)
        c.rrect(x - 200, 420, x + 200, 540, 34, col); c.text(ans, x, 480, 40, WHITE)
        c.rrect(x - 200, 580, x + 200, 700, 34, WHITE, outline=FAINT, ow=4); c.text(what, x, 640, 30, INK)
    note(c, "the whole test, for rules of any size", 800)
    c.save(f"{OUT}/fig-04-test.png")

def two_rules():
    c = Canvas(); title(c, "Two late-work rules, seen from behind the veil")
    rows = [("No late work, ever", "great if you know you will never need it", STONE), ("One late pass a term, no questions", "the one you write when you might", MINT)]
    for i, (head, sub, col) in enumerate(rows):
        y = 220 + i * 260
        c.rrect(120, y, 1080, y + 200, 36, WHITE, outline=FAINT, ow=4)
        c.rrect(140, y + 20, 180, y + 180, 12, col)
        c.text(head, 220, y + 76, 32, INK, anchor="lm"); c.text(sub, 220, y + 130, 24, MUTED, "Bold", anchor="lm")
    note(c, "the veil picks the second", 800)
    c.save(f"{OUT}/fig-06-two-rules.png")

def prompts():
    c = Canvas(); title(c, "Before the rule is finished")
    steps(c, [("Who is worst off under this rule?", "", CORAL), ("Would I take their seat?", "", GOLD), ("If not, change the rule.", "", MINT)], y0=200, h=150)
    c.save(f"{OUT}/fig-09-prompts.png")

if __name__ == "__main__":
    keep_lose(); test(); two_rules(); prompts()

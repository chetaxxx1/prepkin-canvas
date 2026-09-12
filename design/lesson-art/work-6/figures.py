#!/usr/bin/env python3
"""Feedback is data: what it is, delivery vs content, the three words, the three piles,
the sandwich."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def what_it_is():
    c = Canvas(); title(c, "Feedback is")
    columns(c, ("What it feels like", ["a grade on you", "a verdict", "a judgement"], STONE),
            ("What it is", ["one reader's reaction", "a data point", "about the work"], MINT), y0=170, y1=780)
    c.save(f"{OUT}/fig-02-what-it-is.png")

def two_parts():
    c = Canvas(); title(c, "Every piece has two parts")
    c.rrect(110, 180, 590, 760, 36, FAINT); c.rrect(610, 180, 1090, 760, 36, MINT_SOFT)
    c.text("How it was said", 350, 250, 34, INK); c.text("What it says", 850, 250, 34, INK)
    for i, ln in enumerate(["rushed", "in front of people", "a bit blunt"]):
        c.rrect(150, 320 + i * 110, 550, 400 + i * 110, 24, WHITE); c.text(ln, 350, 360 + i * 110, 28, MUTED, "Bold")
    for i, ln in enumerate(["the numbers came too late", "page two lost them", "the ask was unclear"]):
        c.rrect(650, 320 + i * 110, 1050, 400 + i * 110, 24, WHITE); c.text(ln, 850, 360 + i * 110, 28, INK, "Bold")
    c.text("let it go", 350, 700, 28, MUTED, "Bold"); c.text("judge this", 850, 700, 28, MINT)
    c.save(f"{OUT}/fig-03-two-parts.png")

def three_words():
    c = Canvas()
    y = bubbles(c, [("The report was hard to follow.", "them"), ("Thanks, tell me more.", "me"),
                    ("Page two. The numbers came before I knew what they were for.", "them")], y0=160)
    c.rrect(190, y + 10, 1010, y + 90, 26, MINT_SOFT)
    c.text("now you have an example", 600, y + 50, 28, INK, "Bold")
    c.save(f"{OUT}/fig-04-three-words.png")

def sort():
    c = Canvas(); title(c, "Next morning, three piles")
    heads = [("True, do it", MINT, ["numbers later"]), ("True, not now", GOLD, ["shorter overall"]), ("Not true", STONE, ["'you rushed it'"])]
    for i, (head, col, items) in enumerate(heads):
        x0 = 100 + i * 340
        c.rrect(x0, 180, x0 + 320, 760, 36, col)
        ink = WHITE if col in (MINT,) else INK
        c.text(head, x0 + 160, 250, 30, ink)
        for j, it in enumerate(items):
            c.rrect(x0 + 24, 320 + j * 100, x0 + 296, 400 + j * 100, 22, WHITE); c.text(it, x0 + 160, 360 + j * 100, 24, INK, "Bold")
    c.text("most of it lands in the first pile", 600, 830, 24, MUTED, "Bold")
    c.save(f"{OUT}/fig-06-sort.png")

def sandwich():
    c = Canvas(); title(c, "The praise sandwich")
    layers = [("'Great effort on this.'", GOLD_SOFT, INK), ("'But page two lost me.'", CORAL, WHITE), ("'Overall, really solid.'", GOLD_SOFT, INK)]
    for i, (ln, col, ink) in enumerate(layers):
        y = 200 + i * 170
        c.rrect(200, y, 1000, y + 130, 40, col); c.text(ln, 600, y + 65, 32, ink)
    arrow(c, 1090, 435, 1020, 435, CORAL, 8)
    c.text("the message", 1100, 435, 24, CORAL, "Bold", anchor="lm") if False else None
    c.text("the middle is the message", 600, 760, 28, CORAL)
    c.save(f"{OUT}/fig-08-sandwich.png")

if __name__ == "__main__":
    what_it_is(); two_parts(); three_words(); sort(); sandwich()

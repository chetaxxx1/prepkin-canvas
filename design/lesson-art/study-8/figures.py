#!/usr/bin/env python3
"""Explain it to a twelve-year-old: the plain line, the vague spot, the loop, big words
against plain words, and the one-breath check."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def plain_words():
    c = Canvas(); title(c, "The same idea, two ways")
    c.rrect(100, 190, 1100, 400, 36, STONE)
    for i, ln in enumerate(wrap(c, "Chlorophyll absorbs photons to drive the light-dependent reactions of photosynthesis.", 26, 920)):
        c.text(ln, 600, 260 + i * 40, 26, WHITE, "Bold")
    c.text("the textbook", 600, 370, 22, WHITE, "Bold")
    c.rrect(100, 460, 1100, 700, 36, MINT)
    for i, ln in enumerate(wrap(c, "The plant catches sunlight and uses it to turn air and water into sugar.", 30, 920)):
        c.text(ln, 600, 540 + i * 44, 30, WHITE)
    c.text("a twelve-year-old would follow this", 600, 660, 22, WHITE, "Bold")
    c.save(f"{OUT}/fig-02-plain-words.png")

def vague_spot():
    c = Canvas(); title(c, "Where the words go vague")
    c.rrect(160, 180, 1040, 760, 24, WHITE, outline=FAINT, ow=4)
    lines = ["The plant catches sunlight with its leaves.", "It pulls in air through tiny holes.", "Water comes up from the roots.", "And then it... does something with the light?", "Somehow that makes sugar."]
    for i, ln in enumerate(lines):
        y = 250 + i * 100
        if i == 3:
            c.rrect(190, y - 32, 1010, y + 32, 20, CORAL_SOFT); c.text(ln, 600, y, 26, CORAL)
        else:
            c.text(ln, 600, y, 26, INK, "Bold")
    note(c, "that is the gap. That is the exact thing you do not know yet.", 820, size=22)
    c.save(f"{OUT}/fig-03-vague-spot.png")

def loop():
    c = Canvas(); title(c, "The loop")
    boxes = [("explain it plainly", MINT), ("find the vague spot", CORAL), ("look up that one thing", GOLD), ("explain it again", SKY)]
    for i, (label, col) in enumerate(boxes):
        x = 90 + i * 280
        c.rrect(x, 330, x + 250, 480, 30, col)
        for j, ln in enumerate(wrap(c, label, 24, 220)): c.text(ln, x + 125, 390 + j * 30, 24, WHITE if col != GOLD else INK, "Bold")
        if i < 3: arrow(c, x + 255, 405, x + 275, 405, STONE, 6)
    c.line([(1060, 490), (1060, 600), (215, 600), (215, 495)], STONE, 6)
    c.d.polygon([c.p(215, 485), c.p(200, 505), c.p(230, 505)], fill=STONE)
    note(c, "each lap the vague spots get fewer. Stop when there are none.", 700, size=22)
    c.save(f"{OUT}/fig-05-loop.png")

def big_words():
    c = Canvas(); title(c, "Big words hide gaps")
    columns(c, ("Big words", ["sayable without understanding", "sound like the book", "hide the gap"], STONE), ("Plain words", ["cannot be faked", "sound like you", "find the gap"], MINT), y0=170, y1=780)
    c.save(f"{OUT}/fig-08-big-words.png")

def one_breath():
    c = Canvas()
    c.rrect(160, 200, 1040, 640, 40, INK)
    c.text("Say it to a friend", 600, 300, 36, WHITE); c.text("in one breath,", 600, 360, 36, WHITE); c.text("no terms, no pauses.", 600, 420, 36, WHITE)
    c.text("If you can, you are done.", 600, 540, 26, MINT, "Bold")
    note(c, "a minute per topic, before every test", 740)
    c.save(f"{OUT}/fig-09-one-breath.png")

if __name__ == "__main__":
    plain_words(); vague_spot(); loop(); big_words(); one_breath()

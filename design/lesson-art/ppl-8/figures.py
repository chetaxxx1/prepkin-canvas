#!/usr/bin/env python3
"""Ask for help: the path, the three parts as texts, two messages compared, and
the three parts as a list."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def path():
    c = Canvas(); title(c, "A good ask shows your path")
    steps(c, [("Where you started", "what you tried", SKY), ("Where you got stuck", "the exact spot", CORAL), ("What you need", "one small thing", MINT)], y0=190, h=170)
    c.save(f"{OUT}/fig-02-path.png")

def tried():
    c = Canvas()
    y = bubbles(c, [("I don't get it", "me")], y0=260)
    c.strike(380, 382, 1010, 382, CORAL)
    bubbles(c, [("I watched the video and redid problem 3 twice.", "me")], y0=y - 60, phone_frame=False)
    c.text("now they know where to pick up", 600, 760, 24, MINT, "Bold")
    c.save(f"{OUT}/fig-03-tried.png")

def spot():
    c = Canvas()
    y = bubbles(c, [("I don't get quadratics", "me")], y0=260)
    c.strike(380, 382, 1010, 382, CORAL)
    bubbles(c, [("I get lost right where you take the square root.", "me")], y0=y - 60, phone_frame=False)
    c.text("one spot can be answered in a minute", 600, 760, 24, MINT, "Bold")
    c.save(f"{OUT}/fig-04-spot.png")

def ask():
    c = Canvas()
    y = bubbles(c, [("help??", "me")], y0=260)
    c.strike(380, 382, 1010, 382, CORAL)
    bubbles(c, [("Can you check my setup? Ten minutes at lunch would do it.", "me")], y0=y - 60, phone_frame=False)
    c.text("one small thing, named", 600, 760, 24, MINT, "Bold")
    c.save(f"{OUT}/fig-05-ask.png")

def two_messages():
    c = Canvas(); title(c, "Two messages")
    for k, (txt, reply, col) in enumerate((("hey can you help me with the essay?", "nothing back for two hours", STONE), ("I have the intro and two body paragraphs. My conclusion just repeats the intro. Can you read that last paragraph and tell me what's missing?", "answered in five minutes", MINT))):
        x0 = 110 + k * 520; x1 = x0 + 460
        c.rrect(x0, 170, x1, 780, 36, WHITE, outline=FAINT, ow=4)
        lines = wrap(c, txt, 24, 380)
        c.rrect(x0 + 30, 200, x1 - 30, 240 + len(lines) * 34, 30, SKY)
        for j, ln in enumerate(lines): c.text(ln, x0 + 55, 232 + j * 34, 24, WHITE, "Bold", anchor="lm")
        c.rrect(x0 + 30, 660, x1 - 30, 740, 24, col)
        c.text(reply, (x0 + x1) / 2, 700, 24, WHITE if col == MINT else INK, "Bold")
    c.save(f"{OUT}/fig-06-two-messages.png")

def three_parts():
    c = Canvas(); title(c, "Three parts")
    steps(c, [("What I tried", "", SKY), ("Where I'm stuck", "", CORAL), ("What I'm asking for", "", MINT)], y0=200, h=150)
    note(c, "leave one out and they have to guess", 800)
    c.save(f"{OUT}/fig-08-three-parts.png")

if __name__ == "__main__":
    path(); tried(); spot(); ask(); two_messages(); three_parts()

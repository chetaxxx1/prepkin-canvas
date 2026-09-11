#!/usr/bin/env python3
"""Listen so people feel heard: the reflex reply, saying it back, two kinds of
reply, then ask, and the three-move shape."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def reflex():
    c = Canvas()
    y = bubbles(c, [("I completely bombed that test.", "them"), ("You'll be fine!", "me"), ("yeah.", "them")])
    c.text("and that is the end of it", 600, y + 30, 24, CORAL, "Bold")
    c.save(f"{OUT}/fig-02-reflex.png")

def say_back():
    c = Canvas()
    y = bubbles(c, [("I completely bombed that test.", "them"), ("Sounds like it really got to you.", "me"), ("It did. I studied all week and still blanked on the essay.", "them")])
    c.text("they keep going", 600, y + 30, 24, MINT, "Bold")
    c.save(f"{OUT}/fig-03-say-back.png")

def two_kinds():
    c = Canvas(); title(c, "Two kinds of reply")
    columns(c, ("Closes it", ["You'll be fine", "Study earlier next time", "That test was unfair"], STONE), ("Opens it", ["Sounds like it got to you", "What part went wrong?", "Want to talk it through?"], MINT), y0=170, y1=780)
    c.save(f"{OUT}/fig-05-two-kinds.png")

def then_ask():
    c = Canvas()
    y = bubbles(c, [("What part went wrong?", "me"), ("The essay. I ran out of time on the last question and left half of it blank.", "them"), ("Ah. So you knew it, you just ran out of clock.", "me")])
    c.save(f"{OUT}/fig-06-then-ask.png")

def shape():
    c = Canvas(); title(c, "The shape")
    steps(c, [("Say back what you heard", "no fix, no verdict", MINT), ("Ask about one detail", "what part, which bit, when", SKY), ("Advice only if they ask", "and they usually will not", STONE)], y0=190, h=170)
    c.save(f"{OUT}/fig-08-shape.png")

if __name__ == "__main__":
    reflex(); say_back(); two_kinds(); then_ask(); shape()

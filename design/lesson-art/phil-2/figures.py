#!/usr/bin/env python3
"""The Socratic method: the why chain, the flashcard example, the covered page, and
what a test asks."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def chain(c, items, y0=200, step=125, col=SKY):
    for i, (label, kind) in enumerate(items):
        y = y0 + i * step
        if kind == "why":
            c.dot(600, y, 34, CORAL); c.text("why?", 600, y, 22, WHITE, "Bold")
        elif kind == "hole":
            c.rrect(320, y - 42, 880, y + 42, 30, CORAL_SOFT, outline=CORAL, ow=4); c.text(label, 600, y, 28, CORAL)
        else:
            c.rrect(320, y - 42, 880, y + 42, 30, WHITE, outline=FAINT, ow=4); c.text(label, 600, y, 28, INK, "Bold")
        if i < len(items) - 1:
            c.line([(600, y + 44 if kind != "why" else y + 36), (600, y + step - 44 if items[i + 1][1] != "why" else y + step - 36)], STONE, 5)

def why_chain():
    c = Canvas(); title(c, "Ask why until the floor runs out")
    chain(c, [("something you believe", "box"), ("", "why"), ("a reason", "box"), ("", "why"), ("a smaller reason", "box"), ("", "why"), ("...?", "hole")], y0=190, step=105)
    c.save(f"{OUT}/fig-02-why-chain.png")

def flashcards():
    c = Canvas(); title(c, "Three questions in")
    chain(c, [("I should use flashcards", "box"), ("", "why"), ("they help me remember", "box"), ("", "why"), ("because I test myself", "box"), ("", "why"), ("why does testing work?", "hole")], y0=190, step=105)
    c.save(f"{OUT}/fig-03-flashcards.png")

def covered():
    c = Canvas(); title(c, "On your own notes")
    c.rrect(250, 170, 950, 800, 20, WHITE, outline=FAINT, ow=4)
    for i in range(5):
        c.rrect(300, 230 + i * 44, 900 - (i % 3) * 120, 246 + i * 44, 8, FAINT)
    c.rrect(300, 470, 900, 560, 20, INK); c.text("the answer, covered", 600, 515, 26, WHITE, "Bold")
    c.rrect(300, 610, 900, 720, 24, CORAL_SOFT); c.text("why is this the answer?", 600, 665, 30, CORAL)
    c.save(f"{OUT}/fig-06-covered.png")

def two_versions():
    c = Canvas(); title(c, "What a test asks for")
    columns(c, ("Rereading trains", ["seeing the answer", "and knowing it is right", "recognising"], STONE), ("The test wants", ["producing the answer", "with the reason attached", "explaining"], MINT), y0=170, y1=780)
    c.save(f"{OUT}/fig-09-two-versions.png")

if __name__ == "__main__":
    why_chain(); flashcards(); covered(); two_versions()

#!/usr/bin/env python3
"""Roommate rules: what a rule is, the six things, the fridge note, rule not person, the
monthly reset."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def what_it_is():
    c = Canvas(); title(c, "Two unsaid rules meet in the kitchen")
    c.rrect(100, 190, 560, 440, 36, SKY_SOFT); c.rrect(640, 190, 1100, 440, 36, GOLD_SOFT)
    c.text("Yours", 330, 250, 30, INK); c.text("Theirs", 870, 250, 30, INK)
    c.text("dishes the same day", 330, 340, 28, INK, "Bold"); c.text("dishes when the sink's full", 870, 340, 26, INK, "Bold")
    c.rrect(300, 540, 900, 660, 36, CORAL); c.text("the fight", 600, 600, 34, WHITE)
    c.text("said out loud, it is just a rule", 600, 770, 26, MUTED, "Bold")
    c.save(f"{OUT}/fig-02-what-it-is.png")

def six_things():
    c = Canvas(); title(c, "Six things, twenty minutes")
    tiles = [("Guests", SKY), ("Noise", GOLD), ("Cleaning", MINT), ("Shared food", CORAL), ("Temperature", STONE), ("Bills", (196, 178, 240))]
    for i, (h, col) in enumerate(tiles):
        x0 = 100 + (i % 3) * 340; y0 = 180 + (i // 3) * 300
        c.rrect(x0, y0, x0 + 320, y0 + 260, 36, WHITE, outline=FAINT, ow=4)
        c.dot(x0 + 160, y0 + 100, 50, col)
        c.text(h, x0 + 160, y0 + 200, 30, INK)
    c.save(f"{OUT}/fig-03-six-things.png")

def fridge():
    c = Canvas(); title(c, "Somewhere you both see it")
    c.rrect(380, 160, 820, 820, 24, WHITE, outline=FAINT, ow=5)
    c.dot(600, 200, 14, CORAL)
    rows = ["dishes: same day", "quiet after 11", "guests: ask first", "rent: 1st, Sam pays", "internet: 5th, Ana pays"]
    for i, r in enumerate(rows):
        c.text(r, 430, 280 + i * 90, 28, INK, "Bold", anchor="lm")
        c.line([(430, 320 + i * 90), (770, 320 + i * 90)], FAINT, 2)
    c.text("memory bends. A note does not.", 600, 860, 24, MUTED, "Bold")
    c.save(f"{OUT}/fig-05-fridge.png")

def rule_not_person():
    c = Canvas(); title(c, "The rule, not the person")
    y = bubbles(c, [("You never clean up.", "me")], y0=170, phone_frame=False)
    c.strike(430, y - 70, 1010, y - 70, CORAL, 8)
    y = bubbles(c, [("We said dishes same day. Can you get those tonight?", "me")], y0=y - 40, phone_frame=False)
    c.text("a reminder, not a fight", 600, y + 40, 28, MINT)
    c.save(f"{OUT}/fig-06-rule-not-person.png")

def reset():
    c = Canvas(); title(c, "The monthly reset")
    x0, y0 = 150, 200
    for i in range(30):
        x = x0 + (i % 10) * 92; y = y0 + (i // 10) * 92
        c.rrect(x, y, x + 76, y + 76, 16, MINT_SOFT if i == 0 else FAINT)
    c.dot(x0 + 38, y0 + 38, 22, MINT)
    c.text("'Anything bugging you?'", 600, 560, 32, INK)
    c.text("five minutes, before you have something to say", 600, 640, 26, MUTED, "Bold")
    c.save(f"{OUT}/fig-08-reset.png")

if __name__ == "__main__":
    what_it_is(); six_things(); fridge(); rule_not_person(); reset()

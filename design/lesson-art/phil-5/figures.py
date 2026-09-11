#!/usr/bin/env python3
"""The map is not the territory: a map beside the land, three models and what they
dropped, the practice test, and the two questions."""
import os, sys, random
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def map_vs_land():
    c = Canvas(); title(c, "The map keeps the road and drops the rest")
    # the territory: dense noise of shapes
    random.seed(3)
    c.rrect(90, 170, 570, 760, 30, (214, 226, 200))
    for _ in range(260):
        x = random.uniform(110, 550); y = random.uniform(190, 740); r = random.uniform(4, 16)
        c.dot(x, y, r, random.choice([(150, 190, 130), (120, 160, 110), (190, 205, 170), (170, 150, 120)]))
    c.line([(110, 700), (250, 560), (330, 520), (420, 380), (550, 240)], (120, 110, 100), 14)
    c.text("the territory", 330, 800, 26, MUTED, "Bold")
    # the map: two lines and a dot
    c.rrect(630, 170, 1110, 760, 30, WHITE, outline=FAINT, ow=4)
    c.line([(650, 700), (790, 560), (870, 520), (960, 380), (1090, 240)], INK, 10)
    c.dot(870, 520, 16, CORAL)
    c.text("the map", 870, 800, 26, MUTED, "Bold")
    c.save(f"{OUT}/fig-02-map-vs-land.png")

def models():
    c = Canvas(); title(c, "Every model cut something")
    rows = [("A formula", "drops friction and air", SKY), ("A stereotype", "drops the actual person", CORAL), ("A study guide", "drops the questions it did not expect", GOLD)]
    steps(c, rows, y0=190, h=170, num=False)
    c.save(f"{OUT}/fig-03-models.png")

def practice_test():
    c = Canvas(); title(c, "What the practice test knew")
    columns(c, ("It predicted", ["your score, within a few points", "your weak topic", "how long you need"], MINT), ("It could not see", ["you slow down at the end", "you skip the long readings", "nerves on the real day"], STONE), y0=170, y1=780)
    c.save(f"{OUT}/fig-05-practice-test.png")

def two_questions():
    c = Canvas(); title(c, "Before you trust a model")
    steps(c, [("What did this leave out?", "", CORAL), ("Did I need it?", "", MINT)], y0=240, h=170)
    note(c, "the skill is not distrusting maps. It is knowing what was cut.", 760, size=22)
    c.save(f"{OUT}/fig-07-two-questions.png")

if __name__ == "__main__":
    map_vs_land(); models(); practice_test(); two_questions()

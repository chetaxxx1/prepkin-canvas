#!/usr/bin/env python3
"""Water: where eight came from, the real number, what counts, the colour check, what a
little dry does."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def glass(c, x, y, fill, w=70, h=110):
    c.rrect(x - w / 2, y - h / 2, x + w / 2, y + h / 2, 14, WHITE, outline=STONE, ow=4)
    c.rrect(x - w / 2 + 8, y - h / 2 + 30, x + w / 2 - 8, y + h / 2 - 8, 10, fill)

def eight():
    c = Canvas(); title(c, "Eight glasses a day")
    for i in range(8): glass(c, 230 + i * 106, 330, SKY_SOFT)
    c.strike(160, 330, 1040, 330, CORAL, 10)
    c.text("no study behind it. Researchers looked in 2002 and found none.", 600, 520, 26, INK, "Bold")
    c.text("the number that does exist is a total, and food and coffee count", 600, 600, 24, MUTED, "Bold")
    c.save(f"{OUT}/fig-02-eight.png")

def real_number():
    c = Canvas(); title(c, "A day's water, from everything")
    for k, (who, total, col) in enumerate([("women, 2.7 L", 2.7, CORAL), ("men, 3.7 L", 3.7, SKY)]):
        x0 = 230 + k * 500
        stack(c, [("from drinks", round(total * 0.8, 1), col), ("from food", round(total * 0.2, 1), GOLD)], x0=x0, x1=x0 + 260, top=200, bottom=680, fmt=lambda v: f"{v} L", value_size=30, label_size=22)
        c.text(who, x0 + 130, 740, 28, INK, "Bold")
    c.text("roughly 9 cups of drinks for women, 12 for men", 600, 830, 24, MUTED, "Bold")
    c.save(f"{OUT}/fig-03-real-number.png")

def counts():
    c = Canvas(); title(c, "All of these count")
    items = [("water", SKY), ("coffee", (140, 100, 70)), ("tea", GOLD), ("a latte", STONE), ("soup", CORAL), ("fruit", MINT)]
    for i, (name, col) in enumerate(items):
        x = 200 + (i % 3) * 400; y = 260 + (i // 3) * 300
        c.dot(x, y, 70, col); c.text(name, x, y + 120, 28, INK, "Bold")
    c.text("caffeine makes you pee a little more. You keep most of the cup.", 600, 840, 22, MUTED, "Bold")
    c.save(f"{OUT}/fig-04-counts.png")

def colour():
    c = Canvas(); title(c, "The two-second check")
    swatches = [("clear", (245, 245, 225), "ease off"), ("pale straw", (250, 240, 160), "right"), ("yellow", (245, 210, 60), "drink soon"), ("dark yellow", (200, 150, 20), "drink now")]
    for i, (name, col, verdict) in enumerate(swatches):
        x0 = 120 + i * 250
        c.rrect(x0, 220, x0 + 220, 520, 36, col, outline=FAINT, ow=4)
        c.text(name, x0 + 110, 590, 26, INK, "Bold")
        c.text(verdict, x0 + 110, 650, 26, MINT if verdict == "right" else CORAL if "now" in verdict else MUTED, "Bold")
    c.save(f"{OUT}/fig-06-colour.png")

def focus():
    c = Canvas(); title(c, "Losing 1 to 2% of your water")
    steps(c, [("mood dips", "before you feel very thirsty", CORAL), ("focus dips", "one long lecture without a bottle", GOLD), ("a headache starts", "the classic afternoon one", SKY)], y0=180, h=160, step=185, num=False)
    c.save(f"{OUT}/fig-07-focus.png")

if __name__ == "__main__":
    eight(); real_number(); counts(); colour(); focus()

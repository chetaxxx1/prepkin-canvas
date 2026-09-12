#!/usr/bin/env python3
"""Why you crash at 3pm: the 24-hour wave, what lunch adds, the coffee trap, the 20-minute
nap, light."""
import os, sys, math
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def alert(h):
    """Alertness over the day, 0..100: low at 3am, a dip near 2pm, a second wind at 5-7pm."""
    return 55 + 30 * math.sin((h - 9) / 24 * 2 * math.pi) - 22 * math.exp(-((h - 14) / 1.6) ** 2) + 10 * math.exp(-((h - 18.5) / 1.5) ** 2)

def wave():
    c = Canvas(); title(c, "Your clock's two low points")
    x0, x1, y0, y1 = 170, 1080, 200, 640
    c.line([(x0, y1), (x1, y1)], FAINT, 3)
    for h in range(6, 25, 6):
        x = x0 + (x1 - x0) * (h - 6) / 18; c.text({6: "6am", 12: "noon", 18: "6pm", 24: "midnight"}[h], x, y1 + 40, 24, MUTED, "Bold")
    n = 120
    pts = [(x0 + (x1 - x0) * i / n, y1 - (y1 - y0) * alert(6 + 18 * i / n) / 100) for i in range(n + 1)]
    c.line(pts, SKY, 9)
    xd = x0 + (x1 - x0) * (14 - 6) / 18; yd = y1 - (y1 - y0) * alert(14) / 100
    c.dot(xd, yd, 18, CORAL); c.text("the dip, around 2pm", xd, yd + 60, 26, CORAL, "Bold")
    xw = x0 + (x1 - x0) * (18.5 - 6) / 18; yw = y1 - (y1 - y0) * alert(18.5) / 100
    c.text("second wind", xw + 40, yw - 40, 24, MINT, "Bold", anchor="lm")
    c.text("even with no lunch at all", 600, 800, 24, MUTED, "Bold")
    c.save(f"{OUT}/fig-02-wave.png")

def lunch():
    c = Canvas(); title(c, "What lunch adds")
    x0, x1, y0, y1 = 170, 1080, 200, 640
    c.line([(x0, y1), (x1, y1)], FAINT, 3)
    for h, lab in [(12, "noon"), (14, "2pm"), (16, "4pm")]:
        x = x0 + (x1 - x0) * (h - 11.5) / 5.5; c.text(lab, x, y1 + 40, 24, MUTED, "Bold")
    n = 100
    big = lambda h: 50 + 45 * math.exp(-((h - 12.7) / 0.6) ** 2) - 35 * math.exp(-((h - 14.3) / 0.9) ** 2)
    small = lambda h: 50 + 12 * math.exp(-((h - 12.8) / 0.8) ** 2) - 8 * math.exp(-((h - 14.3) / 0.9) ** 2)
    for fn, col in ((big, CORAL), (small, MINT)):
        pts = [(x0 + (x1 - x0) * i / n, y1 - (y1 - y0) * max(2, min(98, fn(11.5 + 5.5 * i / n))) / 100) for i in range(n + 1)]
        c.line(pts, col, 8)
    c.text("blood sugar", x0 - 20, y0 + 20, 22, MUTED, "Bold", anchor="rm")
    legend(c, [("big carb lunch", CORAL), ("smaller, with protein", MINT)], 740, x0=300, gap=320)
    c.text("the down lands right on the dip", 600, 820, 24, MUTED, "Bold")
    c.save(f"{OUT}/fig-03-lunch.png")

def coffee():
    c = Canvas(); title(c, "A 3pm coffee, later")
    x0, x1, y = 150, 1050, 450
    c.rrect(x0, y - 8, x1, y + 8, 8, FAINT)
    for label, t, mg, col in [("3pm", 0, 200, CORAL), ("8pm", 5, 100, CORAL), ("1am", 10, 50, GOLD)]:
        x = x0 + (x1 - x0) * t / 10; r = 18 + mg / 5
        c.dot(x, y, r, col); c.text(f"{mg}mg", x, y - r - 40, 32, INK); c.text(label, x, y + r + 44, 26, MUTED, "Bold")
    c.text("the dip is a two-hour problem. The coffee is a tonight problem.", 600, 760, 24, MUTED, "Bold")
    c.save(f"{OUT}/fig-04-coffee.png")

def nap():
    c = Canvas(); title(c, "How you wake up")
    hbars(c, [("10 minutes", 5, MINT), ("20 minutes", 9, MINT), ("45 minutes", 3, CORAL), ("90 minutes", 8, GOLD)],
          fmt=lambda v: {5: "refreshed", 9: "refreshed", 3: "groggy, from deep sleep", 8: "fine, but it eats tonight"}[v], x0=380, xmax=760, y0=200, step=140, h=80, label_size=28, value_size=24, vmax=10)
    c.text("twenty minutes, before 3pm, alarm set", 600, 800, 26, INK, "Bold")
    c.save(f"{OUT}/fig-06-nap.png")

def light():
    c = Canvas(); title(c, "Light tells the clock it's still day")
    c.rrect(100, 200, 560, 680, 36, (60, 55, 70)); c.text("a dim lecture hall", 330, 620, 26, WHITE, "Bold")
    c.rrect(640, 200, 1100, 680, 36, GOLD_SOFT); c.dot(870, 380, 90, GOLD); c.text("a window seat, or five minutes outside", 870, 620, 24, INK, "Bold")
    c.text("deepens the dip", 330, 750, 26, CORAL, "Bold"); c.text("lifts it", 870, 750, 26, MINT, "Bold")
    c.save(f"{OUT}/fig-07-light.png")

if __name__ == "__main__":
    wave(); lunch(); coffee(); nap(); light()

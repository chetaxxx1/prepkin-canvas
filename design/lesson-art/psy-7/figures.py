#!/usr/bin/env python3
"""Say I'm excited: same signals, why calm down fails, the karaoke scores (Brooks
2014), threat vs challenge, and the two-line script."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def same_signals():
    c = Canvas(); title(c, "Same body, two labels")
    for k, (head, col) in enumerate((("anxious", STONE), ("excited", MINT))):
        x0 = 110 + k * 520; x1 = x0 + 460
        c.rrect(x0, 170, x1, 780, 36, WHITE, outline=FAINT, ow=4)
        c.rrect(x0, 170, x1, 250, 36, col); c.rrect(x0, 220, x1, 250, 0, col); c.text(head, (x0 + x1) / 2, 210, 30, WHITE if col == MINT else INK)
        for i, (label, v) in enumerate((("heart rate", 0.9), ("breathing", 0.8), ("sweaty hands", 0.7))):
            y = 320 + i * 140
            c.text(label, x0 + 30, y, 24, INK, "Bold", anchor="lm")
            c.rrect(x0 + 30, y + 30, x1 - 30, y + 70, 16, FAINT); c.rrect(x0 + 30, y + 30, x0 + 30 + (x1 - x0 - 60) * v, y + 70, 16, col)
    c.save(f"{OUT}/fig-02-same-signals.png")

def calm_down():
    c = Canvas(); title(c, "What each one asks the body to do")
    rows = [("'Calm down'", "drop from high alert to still, in thirty seconds. Impossible.", CORAL), ("'I'm excited'", "nothing. Keep the alert, change the story. Easy.", MINT)]
    for i, (head, sub, col) in enumerate(rows):
        y = 220 + i * 250
        c.rrect(120, y, 1080, y + 190, 36, WHITE, outline=FAINT, ow=4)
        c.rrect(140, y + 20, 180, y + 170, 12, col)
        c.text(head, 220, y + 66, 34, INK, anchor="lm")
        for j, ln in enumerate(wrap(c, sub, 24, 820)): c.text(ln, 220, y + 118 + j * 32, 24, MUTED, "Bold", anchor="lm")
    c.save(f"{OUT}/fig-03-calm-down.png")

def scores():
    c = Canvas(); title(c, "Karaoke, scored by a machine")
    vbars(c, [("said 'I'm excited'", 80, MINT), ("said nothing", 69, STONE), ("said 'I'm calm'", 53, CORAL)], fmt=lambda v: f"{v}%", base=680, top=220, width=240)
    note(c, "Brooks, 2014, singing accuracy", 830, size=22)
    c.save(f"{OUT}/fig-05-scores.png")

def threat_challenge():
    c = Canvas(); title(c, "Threat or challenge")
    columns(c, ("Threat", ["brace", "narrow", "get through it"], STONE), ("Challenge", ["lean in", "open", "go and get it"], MINT), y0=170, y1=780)
    c.save(f"{OUT}/fig-07-threat-challenge.png")

def script():
    c = Canvas(); title(c, "The script")
    steps(c, [("Notice the racing heart", "", SKY), ("Say: I'm excited", "", MINT)], y0=240, h=170)
    note(c, "two lines, in the ten seconds before you walk in", 760)
    c.save(f"{OUT}/fig-09-script.png")

if __name__ == "__main__":
    same_signals(); calm_down(); scores(); threat_challenge(); script()

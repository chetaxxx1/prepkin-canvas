#!/usr/bin/env python3
"""Working memory: four slots, the fifth thing, chunking, the sticky note, and Miller
against Cowan."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))
WHITE = (255, 255, 255)

def slot(c, x, y, label=None, col=FAINT, ink=INK, w=230, h=230):
    c.rrect(x, y, x + w, y + h, 34, col, outline=None if col != FAINT else (220, 210, 195), ow=4)
    if label:
        for j, ln in enumerate(label.split("\n")):
            c.text(ln, x + w / 2, y + h / 2 + (j - (label.count("\n")) / 2) * 34, 26, ink, "Bold")

def slots():
    c = Canvas()
    c.text("Four slots", 600, 80, 44)
    items = ["the song\nin your head", "the text you\nhaven't answered", "the phone\nface up", None]
    for i, it in enumerate(items):
        x = 90 + i * 260
        slot(c, x, 330, it, col=CORAL_SOFT if it else FAINT)
    c.text("one left for the thing you are trying to learn", 600, 660, 26, MUTED, "Bold")
    c.save(f"{OUT}/fig-02-slots.png")

def fifth():
    c = Canvas()
    c.text("The fifth thing", 600, 80, 44)
    items = ["the song", "the text", "the phone", "a notification"]
    for i, it in enumerate(items):
        x = 90 + i * 260
        slot(c, x, 220, it, col=CORAL_SOFT if i < 3 else CORAL, ink=INK if i < 3 else WHITE)
    # the thing that fell out, below the row
    slot(c, 870, 560, "what you were\nlearning", col=(200, 190, 175), w=230, h=160)
    c.line([(985, 465), (985, 520)], MUTED, 6)
    c.d.polygon([c.p(985, 545), c.p(968, 518), c.p(1002, 518)], fill=MUTED)
    c.text("something falls off, and it is usually the newest thing", 600, 800, 24, MUTED, "Bold")
    c.save(f"{OUT}/fig-03-fifth.png")

def chunking():
    c = Canvas()
    c.text("Seven things, or two", 600, 80, 44)
    digits = "8675309"
    for i, d in enumerate(digits):
        x = 150 + i * 135
        c.rrect(x, 200, x + 110, 330, 26, FAINT)
        c.text(d, x + 55, 265, 44, INK)
    c.text("seven slots", 600, 380, 26, MUTED, "Bold")
    for i, (chunk, x0, x1) in enumerate((("867", 250, 540), ("5309", 620, 950))):
        c.rrect(x0, 500, x1, 640, 30, MINT)
        c.text(chunk, (x0 + x1) / 2, 570, 48, WHITE)
    c.text("two slots", 600, 690, 26, MUTED, "Bold")
    c.text("Same number. You learned to chunk it.", 600, 800, 28, INK)
    c.save(f"{OUT}/fig-05-chunking.png")

def sticky():
    c = Canvas()
    c.text("Put them on paper", 600, 80, 44)
    # a yellow sticky note, slightly turned
    from PIL import Image as _I, ImageDraw as _D
    note = _I.new("RGBA", (560 * SS, 560 * SS), (0, 0, 0, 0))
    d = _D.Draw(note)
    d.rounded_rectangle([0, 0, 560 * SS, 560 * SS], radius=8 * SS, fill=(255, 231, 128))
    d.rectangle([0, 0, 560 * SS, 40 * SS], fill=(246, 216, 100))
    note = note.rotate(3, resample=_I.BICUBIC, expand=True)
    c.im.paste(note, (int(320 * SS), int(150 * SS)), note)
    c.d = _D.Draw(c.im, "RGBA")
    lines = ["F = m a", "v = d / t", "KE = ½ m v²"]
    for i, ln in enumerate(lines):
        c.text(ln, 600, 300 + i * 120, 48, INK, "Bold")
    c.text("three formulas out of your head, three slots free", 600, 800, 24, MUTED, "Bold")
    c.save(f"{OUT}/fig-06-sticky.png")

def miller_cowan():
    c = Canvas()
    c.text("How many things?", 600, 80, 44)
    for i, (who, year, n, note, col) in enumerate((("Miller", 1956, 7, "seven, plus or minus two", (200, 190, 175)),
                                                 ("Cowan", 2001, 4, "about four, when nothing is chunked", MINT))):
        y = 220 + i * 300
        c.text(f"{who}, {year}", 120, y, 30, INK, anchor="lm")
        for j in range(n):
            x = 120 + j * 120
            c.rrect(x, y + 40, x + 100, y + 140, 22, col)
        c.text(note, 120, y + 190, 24, MUTED, "Bold", anchor="lm")
    c.save(f"{OUT}/fig-08-miller-cowan.png")

if __name__ == "__main__":
    slots(); fifth(); chunking(); sticky(); miller_cowan()

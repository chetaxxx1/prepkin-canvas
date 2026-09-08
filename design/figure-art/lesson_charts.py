#!/usr/bin/env python3
"""The raster charts, computed and rendered here rather than drawn in Swift.

    python3 design/figure-art/lesson_charts.py            # every chart
    python3 design/figure-art/lesson_charts.py work-band  # one

Each function computes its numbers, prints the checks that make it honest, and renders
a finished PNG into design/art-src/figures/. `pack.py --raster` takes it from there.
"""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from chartkit import (Chart, INK, CORAL, LEAF, LEAF_DEEP, COIN, PAPER, FAINT, W, H)

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "art-src", "figures")


def work_band():
    """Where the number you say lands against the range they already approved."""
    LO, HI, SAID = 65_000.0, 80_000.0, 60_000.0
    lo, hi, x0, x1 = 55_000.0, 85_000.0, 44.0, 330.0
    mx = lambda v: x0 + (v - lo) / (hi - lo) * (x1 - x0)
    axis_y, band_top = 206.0, 166.0

    c = Chart("rose")
    c.line([(x0 - 8, axis_y), (x1 + 8, axis_y)], INK, 2, cap=False)
    for v in (60_000, 70_000, 80_000):
        c.line([(mx(v), axis_y), (mx(v), axis_y + 7)], INK + (0,) if False else INK, 2, cap=False)
        c.text(f"${v // 1000}k", mx(v), axis_y + 20, 12, INK + (0,)[:0] or (120, 108, 100))

    c.pill(mx(LO), band_top, mx(HI), axis_y, LEAF, r=8, outline=INK, ow=2)
    c.label_in("what they budgeted", mx(LO), band_top, mx(HI), axis_y, 12)
    c.text(f"${LO:,.0f}", mx(LO), band_top - 18, 12)
    c.text(f"${HI:,.0f}", mx(HI), band_top - 18, 12)

    c.line([(mx(SAID), axis_y), (mx(SAID), band_top - 34)], CORAL, 4)
    c.dot(mx(SAID), band_top - 34, 7, CORAL)
    c.text("you said", mx(SAID), axis_y + 42, 12, CORAL)
    c.text(f"${SAID:,.0f}", mx(SAID), axis_y + 66, 20, CORAL)

    checks = [f"their range is ${LO:,.0f} to ${HI:,.0f}; ${SAID:,.0f} sits "
              f"${LO - SAID:,.0f} under the floor",
              f"the band is {mx(HI) - mx(LO):.0f}pt wide and its label measures "
              f"{c.measure('what they budgeted', 12)[0]:.0f}pt"]
    return c, checks


def work_careers():
    """Two careers, the same raises, one starting line five thousand lower."""
    LOW, SAID, RAISE, YEARS = 65_000.0, 60_000.0, 0.03, 10
    # The left margin holds the money scale, so it has to be wide enough for "$90k".
    bx0, bx1, by0, by1 = 78.0, 330.0, 84.0, 228.0
    ylo, yhi = 55_000.0, 92_000.0
    px = lambda t: bx0 + t / YEARS * (bx1 - bx0)
    py = lambda v: by0 + (yhi - v) / (yhi - ylo) * (by1 - by0)
    pay = lambda s, t: s * (1 + RAISE) ** t
    pts = lambda s: [(px(t / 4), py(pay(s, t / 4))) for t in range(YEARS * 4 + 1)]

    theirs, yours = pts(LOW), pts(SAID)
    total = sum(pay(LOW, t) - pay(SAID, t) for t in range(YEARS))

    c = Chart("rose")
    # The money scale first, so the wedge and the lines sit on top of it. Without this
    # the chart showed two lines climbing to nothing you could read.
    for v in (60_000, 70_000, 80_000, 90_000):
        c.dash(bx0, py(v), bx1, py(v), (46, 38, 34, 60), 1.5)
        c.text(f"${v // 1000}k", bx0 - 9, py(v), 12, (120, 108, 100), anchor="rm")
    c.area(theirs + yours[::-1], CORAL, 0.32)
    c.line([(bx0, by1), (bx1, by1)], INK, 2, cap=False)
    for t, lab in ((0, "now"), (5, "5 yr"), (10, "10 yr")):
        c.line([(px(t), by1), (px(t), by1 + 7)], INK, 2, cap=False)
        c.text(lab, px(t), by1 + 21, 12, (120, 108, 100))
    c.line(theirs, LEAF_DEEP, 6)
    c.line(yours, INK, 6)

    # Measured placement: each label sits a full type-height clear of its own line.
    # Each label goes where it means something: the green one over its own left end,
    # the black one under its right end, in the open field below the pair.
    c.place(f"${LOW:,.0f} start", (px(2.1), py(pay(LOW, 2.1)) - 22), 12, LEAF_DEEP)
    c.place(f"${SAID:,.0f} start", (px(7.4), py(pay(SAID, 7.4)) + 22), 12, INK)

    # The total names the wedge, so it is tied to it with a leader rather than floated.
    c.line([(150, 84), (196, 126)], CORAL, 1.5, cap=False, avoid=False)
    c.place("never earned", (108, 50), 12, CORAL)
    c.place(f"${total:,.0f}", (108, 70), 20, CORAL)

    checks = [f"after {YEARS} years of {RAISE:.0%}: ${pay(SAID, YEARS):,.0f} "
              f"against ${pay(LOW, YEARS):,.0f}",
              f"the yearly gap widens ${LOW - SAID:,.0f} -> "
              f"${pay(LOW, YEARS) - pay(SAID, YEARS):,.0f}",
              f"never earned over {YEARS} years: ${total:,.0f}"]
    return c, checks


def trolley_split():
    """What people actually say, for the two versions of the same arithmetic.

    Both cases kill one to save five. The split between them is the whole finding, and
    it has held up across decades of surveys. The figures are approximate and the card
    says so — the point is the size of the gap, not the second decimal.
    """
    LEVER, PUSH = 90, 10
    bx0, bx1, by0, by1 = 84.0, 322.0, 78.0, 226.0
    py = lambda pct: by1 - pct / 100.0 * (by1 - by0)

    c = Chart("sky")
    for pct in (50, 100):
        c.dash(bx0, py(pct), bx1, py(pct), (46, 38, 34, 55), 1.5)
        c.text(f"{pct}%", bx0 - 9, py(pct), 12, (120, 108, 100), anchor="rm")
    c.line([(bx0, by1), (bx1, by1)], INK, 2, cap=False)

    for cx, pct, colour, cap in ((146, LEVER, LEAF, "pull the lever"),
                                 (264, PUSH, CORAL, "push the man")):
        c.pill(cx - 42, py(pct), cx + 42, by1, colour, r=8, outline=INK, ow=2)
        # A tall bar's label goes inside it; above, it would sit on the 100% rule.
        if pct >= 40: c.text(f"{pct}%", cx, py(pct) + 22, 20, INK)
        else: c.text(f"{pct}%", cx, py(pct) - 20, 20, colour)
        c.text(cap, cx, by1 + 22, 12, (90, 80, 74))

    checks = [f"both cases trade one life for five; {LEVER}% say pull, about {PUSH}% say push",
              f"the bars are {py(PUSH) - py(LEVER):.0f}pt apart, drawn to the same scale"]
    return c, checks


def raise_timing():
    """When the money is actually decided, against when most people ask for it.

    A different shape from the two-line charts: one year, left to right, with the
    window that matters marked on it. The point is that the review is downstream of a
    decision made months earlier.
    """
    x0, x1, y = 44.0, 330.0, 150.0
    mx = lambda m: x0 + m / 12.0 * (x1 - x0)     # month 0..12 across the year
    PLAN, REVIEW = 8.0, 11.0                      # planning window, then the review

    c = Chart("leaf")
    # Everything after planning is already spent. Shading it is the whole argument.
    c.area([(mx(PLAN), y - 26), (mx(12), y - 26), (mx(12), y + 26), (mx(PLAN), y + 26)],
           (120, 108, 100), 0.22)
    c.line([(x0 - 8, y), (x1 + 8, y)], INK, 2, cap=False)
    for m, lab in ((0, "Jan"), (6, "Jul"), (12, "Dec")):
        c.line([(mx(m), y), (mx(m), y + 8)], INK, 2, cap=False)
        c.text(lab, mx(m), y + 22, 12, (120, 108, 100))

    c.line([(mx(PLAN), y - 26), (mx(PLAN), y + 26)], INK, 3)
    c.text("budget set", mx(PLAN) + 30, y - 40, 12)

    c.dot(mx(REVIEW), y, 8, CORAL)
    c.text("your review", mx(REVIEW), y + 46, 12, CORAL)
    c.text("too late", mx(REVIEW), y + 66, 12, CORAL)

    # The ask lands on the timeline itself, in the months before the money is spoken for.
    c.line([(mx(4.6), y - 62), (mx(6.6), y - 14)], LEAF_DEEP, 3)
    c.dot(mx(6.8), y, 8, LEAF_DEEP)
    c.text("ask here", mx(3.6), y - 74, 14, LEAF_DEEP)

    checks = [f"the planning window sits at month {PLAN:.0f} and the review at "
              f"{REVIEW:.0f}, so the money is {REVIEW - PLAN:.0f} months old by then",
              f"the shaded stretch is {mx(12) - mx(PLAN):.0f}pt of a "
              f"{mx(12) - mx(0):.0f}pt year"]
    return c, checks


CHARTS = {"work-band": work_band, "work-careers": work_careers,
          "trolley-split": trolley_split, "raise-timing": raise_timing}

if __name__ == "__main__":
    for name in (sys.argv[1:] or list(CHARTS)):
        c, checks = CHARTS[name]()
        for k in checks + c.notes: print(f"  {name}: {k}")
        print(c.save(os.path.join(OUT, f"{name}.png")))

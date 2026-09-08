#!/usr/bin/env python3
"""Compute the curves in the lesson figures and emit them as Swift.

    python3 design/figure-art/charts.py            # print every chart
    python3 design/figure-art/charts.py compound   # just one

The curves used to be hand-tuned Bezier control points, which meant a chart about
compound interest was not actually a picture of compound interest — the doubling
marker sat wherever it looked right. Everything here is computed from the formula,
mapped into the figure's 360x300 point space, and printed as a Swift array of points
for `fxLine` to draw. Each chart also prints the checks that make it honest.

Paste the emitted block into ios/Sources/LessonFigures.swift. Nothing is generated at
runtime: the app draws a plain polyline, so there is no charting library in the phone.
"""
import math, os, subprocess, sys

W, H = 360.0, 300.0


class P:
    """A point, so a hand-built polygon matches what sample() returns."""

    def __init__(self, x, y):
        self.x, self.y = x, y

    def __iter__(self):
        yield self.x
        yield self.y

    def __getitem__(self, i):
        return (self.x, self.y)[i]



class Box:
    """A plot area inside the figure, and the mapping from data into it."""

    def __init__(self, x0, y0, x1, y1, xmax, ymax, xmin=0.0, ymin=0.0):
        self.x0, self.y0, self.x1, self.y1 = x0, y0, x1, y1
        self.xmin, self.xmax, self.ymin, self.ymax = xmin, xmax, ymin, ymax

    def px(self, x):
        return self.x0 + (x - self.xmin) / (self.xmax - self.xmin) * (self.x1 - self.x0)

    def py(self, y):
        # figure space counts downward
        return self.y1 - (y - self.ymin) / (self.ymax - self.ymin) * (self.y1 - self.y0)

    def pt(self, x, y):
        return (self.px(x), self.py(y))



def text_width(s, size):
    """Rough width of a string at `size`. Same model figcheck.py uses, so a label that
    passes here passes there."""
    w = 0.0
    for ch in s:
        if ch in " .,·:'\u2019!": w += 0.30
        elif ch in "ijl": w += 0.30
        elif ch.isupper() or ch.isdigit(): w += 0.66
        else: w += 0.58
    return w * size


# ---------------------------------------------------------------------------- plot
INK, FIELD = "#2E2622", {"coin": "#FFF4DC", "rose": "#FFEDE7", "sky": "#E6F0FB",
                         "leaf": "#EAF4E0", "lav": "#EDE7FB"}
CLEAR = 13.0          # a label must sit this far from any drawn line, in points


class Plot:
    """A chart that places its own labels and proves they do not touch a line.

    Placing labels by hand put type across a curve twice. Here a label is anchored to
    a line and a side, and its y comes from the line's own value at that x, so it
    cannot land on it. `check()` then measures every label box against every line and
    fails loudly if anything is closer than CLEAR.

    `preview()` writes a PNG of the whole thing, which is the point: a chart you can
    look at in a second gets fixed, and one that needs a rebuild and six taps does not.
    """

    def __init__(self, name, box, field="coin"):
        self.name, self.box, self.field = name, box, field
        self.lines, self.areas, self.rules, self.ticks, self.labels = {}, [], [], [], []

    @staticmethod
    def _pts(raw):
        return [q if hasattr(q, "x") else P(q[0], q[1]) for q in raw]

    def line(self, key, fn, a, b, colour, w=6.0, n=40):
        self.lines[key] = {"pts": self._pts(sample(lambda t: self.box.pt(t, fn(t)), a, b, n)),
                           "fn": fn, "colour": colour, "w": w}
        return self.lines[key]["pts"]

    def area(self, pts, colour, opacity=0.35):
        self.areas.append({"pts": self._pts(pts), "colour": colour, "opacity": opacity})

    def rule(self, value, label=None, size=12.0):
        y = self.box.py(value)
        self.rules.append(y)
        if label: self.labels.append({"text": label, "x": self.box.x0 - 16, "y": y,
                                      "size": size, "anchor": "end",
                                      "colour": INK + "99"})
        return y

    def tick(self, t, label=None, size=12.0):
        x = self.box.px(t)
        self.ticks.append(x)
        if label: self.labels.append({"text": label, "x": x, "y": self.box.y1 + 20,
                                      "size": size, "anchor": "middle", "colour": INK,
                                      "kind": "tick"})
        return x

    def label_on(self, key, text, at_t, side="above", size=12.0, colour=INK):
        """Anchor a label to a line, clear of it by construction.

        The offset is not a taste number: it is the floor, plus half the type's height,
        plus half the line's width. Guessing it put labels on curves twice.
        """
        ln = self.lines[key]
        # A sloped line climbs across the label's own width, so a fixed offset is not
        # enough — this is only the starting guess, and place() searches from there.
        gap = CLEAR + size * 0.6 + ln["w"] / 2
        y = self.box.py(ln["fn"](at_t)) + (-gap if side == "above" else gap)
        return self.place(text, (self.box.px(at_t), y), size=size, colour=colour)

    def place(self, text, near, size=12.0, colour=INK, anchor="middle"):
        """Put a label as close to `near` as open field allows.

        Searches outward in rings and takes the first spot that clears every line and
        stays inside the figure's safe box. Beats moving a number by hand and
        rebuilding to see whether it worked.
        """
        cx, cy = near
        for r in range(0, 140, 6):
            for dx, dy in ((0, -r), (0, r), (-r, 0), (r, 0),
                           (-r, -r), (r, -r), (-r, r), (r, r)):
                x, y = cx + dx, cy + dy
                lb = {"text": text, "x": x, "y": y, "size": size,
                      "anchor": anchor, "colour": colour}
                bx0, by0, bx1, by1 = self._box_of(lb)
                if bx0 < 16 or bx1 > 344 or by0 < 14 or by1 > 286: continue
                if any(not (bx1 + 6 <= o[0] or o[2] + 6 <= bx0
                            or by1 + 3 <= o[1] or o[3] + 3 <= by0)
                       for o in map(self._box_of, self.labels)): continue
                if all(min(_seg_box(p, q, bx0, by0, bx1, by1)
                           for p, q in zip(ln["pts"], ln["pts"][1:])) - ln["w"] / 2 >= CLEAR
                       for ln in self._obstacles().values()):
                    self.labels.append(lb)
                    return x, y
        raise SystemExit(f"{self.name}: nowhere clear to put {text!r}")

    def free(self, text, x, y, size=12.0, colour=INK, anchor="middle"):
        self.labels.append({"text": text, "x": x, "y": y, "size": size,
                            "anchor": anchor, "colour": colour})
        return x, y

    # ---- checking ----------------------------------------------------------------
    def _obstacles(self):
        """Every line a label has to keep away from, the axis and rules included."""
        obs = dict(self.lines)
        obs["axis"] = {"pts": [P(self.box.x0, self.box.y1), P(self.box.x1, self.box.y1)],
                       "w": 2.0}
        for i, y in enumerate(self.rules):
            obs[f"rule{i}"] = {"pts": [P(self.box.x0, y), P(self.box.x1, y)], "w": 1.5}
        return obs

    def _box_of(self, lb):
        w, h = text_width(lb["text"], lb["size"]), lb["size"] * 1.2
        x = {"middle": lb["x"] - w / 2, "start": lb["x"], "end": lb["x"] - w}[lb["anchor"]]
        return x, lb["y"] - h / 2, x + w, lb["y"] + h / 2

    def check(self):
        """Distance from every label box to every line, as printable check lines."""
        out, worst = [], None
        for lb in self.labels:
            x0, y0, x1, y1 = self._box_of(lb)
            for key, ln in self._obstacles().items():
                if key == "axis" and lb.get("kind") == "tick": continue
                d = min(_seg_box(p, q, x0, y0, x1, y1)
                        for p, q in zip(ln["pts"], ln["pts"][1:]))
                d -= ln["w"] / 2
                if worst is None or d < worst[0]: worst = (d, lb["text"], key)
                if d < CLEAR:
                    out.append(f"LABEL {lb['text']!r} is {d:.1f}pt from {key} "
                               f"(needs {CLEAR:.0f})")
        for i, a in enumerate(self.labels):
            ax0, ay0, ax1, ay1 = self._box_of(a)
            for b in self.labels[i + 1:]:
                bx0, by0, bx1, by1 = self._box_of(b)
                if not (ax1 <= bx0 or bx1 <= ax0 or ay1 <= by0 or by1 <= ay0):
                    out.append(f"LABEL {a['text']!r} overlaps {b['text']!r}")
        if worst:
            out.append(f"closest label to any line: {worst[1]!r} vs {worst[2]}, "
                       f"{worst[0]:.1f}pt (floor {CLEAR:.0f})")
        return out

    # ---- output ------------------------------------------------------------------
    def preview(self, path):
        e = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W:.0f} {H:.0f}" '
             f'width="{W*2:.0f}" height="{H*2:.0f}">'
             f'<rect width="{W:.0f}" height="{H:.0f}" fill="{FIELD[self.field]}"/>']
        for a in self.areas:
            d = "M " + " L ".join(f"{p.x:.1f} {p.y:.1f}" for p in a["pts"]) + " Z"
            e.append(f'<path d="{d}" fill="{a["colour"]}" opacity="{a["opacity"]}"/>')
        for y in self.rules:
            e.append(f'<line x1="{self.box.x0:.1f}" y1="{y:.1f}" x2="{self.box.x1:.1f}" '
                     f'y2="{y:.1f}" stroke="{INK}" stroke-width="1.5" '
                     f'stroke-dasharray="6 5" opacity="0.35"/>')
        e.append(f'<line x1="{self.box.x0:.1f}" y1="{self.box.y1:.1f}" '
                 f'x2="{self.box.x1:.1f}" y2="{self.box.y1:.1f}" stroke="{INK}" stroke-width="2"/>')
        for x in self.ticks:
            e.append(f'<line x1="{x:.1f}" y1="{self.box.y1:.1f}" x2="{x:.1f}" '
                     f'y2="{self.box.y1 + 6:.1f}" stroke="{INK}" stroke-width="2"/>')
        for ln in self.lines.values():
            d = "M " + " L ".join(f"{p.x:.1f} {p.y:.1f}" for p in ln["pts"])
            e.append(f'<path d="{d}" fill="none" stroke="{ln["colour"]}" '
                     f'stroke-width="{ln["w"]}" stroke-linecap="round" stroke-linejoin="round"/>')
        for key, ln in self.lines.items():
            if key == "pin":
                p = ln["pts"][0]
                e.append(f'<circle cx="{p.x:.1f}" cy="{p.y:.1f}" r="6" fill="{ln["colour"]}"/>')
        for lb in self.labels:
            e.append(f'<text x="{lb["x"]:.1f}" y="{lb["y"] + lb["size"] * 0.36:.1f}" '
                     f'text-anchor="{lb["anchor"]}" fill="{lb["colour"]}" '
                     f'font-family="-apple-system, system-ui, Avenir, sans-serif" '
                     f'font-weight="800" font-size="{lb["size"]:.1f}">{lb["text"]}</text>')
        e.append("</svg>")
        open(path, "w").write("".join(e))
        subprocess.run(["rsvg-convert", "-w", f"{W*2:.0f}", "-h", f"{H*2:.0f}",
                        path, "-o", path.replace(".svg", ".png")], check=True)
        return path.replace(".svg", ".png")

    def marks(self, prefix):
        """Label positions, so the Swift never invents one."""
        out = []
        for i, lb in enumerate(self.labels):
            out.append(f"private let {prefix}L{i}: CGPoint = "
                       f"CGPoint(x: {lb['x']:.1f}, y: {lb['y']:.1f})   // {lb['text']}")
        return "/// Label anchors, placed and clearance-checked by charts.py.\n" + "\n".join(out) + "\n"


def _seg_box(p, q, x0, y0, x1, y1):
    """Shortest distance from a segment to an axis-aligned box."""
    best = 1e9
    for i in range(9):                       # sampling the segment is enough at this size
        t = i / 8
        x, y = p.x + (q.x - p.x) * t, p.y + (q.y - p.y) * t
        dx = max(x0 - x, 0, x - x1)
        dy = max(y0 - y, 0, y - y1)
        best = min(best, math.hypot(dx, dy))
    return best


def swift(name, pts, note):
    body = ",\n    ".join(f"CGPoint(x: {x:.1f}, y: {y:.1f})" for x, y in pts)
    return f"/// {note}\n/// Generated by design/figure-art/charts.py — do not hand-edit.\nprivate let {name}: [CGPoint] = [\n    {body},\n]\n"


def sample(f, a, b, n=26):
    return [f(a + (b - a) * i / (n - 1)) for i in range(n)]


# --------------------------------------------------------------------------- compound
def compound():
    """$1,000 at 8% a year. One line starts now, one starts ten years later."""
    RATE, YEARS, P = 0.08, 30, 1000.0
    val = lambda t: P * (1 + RATE) ** t
    top = val(YEARS)
    box = Box(64, 44, 336, 246, xmax=YEARS, ymax=top, ymin=P * 0.6)

    early = sample(lambda t: box.pt(t, val(t)), 0, YEARS)
    late = sample(lambda t: box.pt(t, val(t - 10)), 10, YEARS)

    double_t = math.log(2) / math.log(1 + RATE)          # the real doubling time
    rule72 = 72 / (RATE * 100)                            # what the rule of thumb says
    out = [swift("compoundEarly", early, "$1,000 at 8% a year, from the start."),
           swift("compoundLate", late, "The same $1,000 at 8%, begun ten years later.")]
    marks = {
        "doubleX": box.px(double_t),
        "doubleY": box.py(2 * P),
        "axisY": box.py(P * 0.6),
        "startY": box.py(P),
    }
    out.append("/// x of the doubling point, and the y of $2,000 and of $1,000.\n"
               + "".join(f"private let compound{k[0].upper()}{k[1:]}: CGFloat = {v:.1f}\n"
                         for k, v in marks.items()))
    checks = [
        f"doubling at {double_t:.2f} years, rule of 72 says {rule72:.1f} — within "
        f"{abs(double_t - rule72):.2f} years, which is why the rule is taught",
        f"value at the doubling point is ${val(double_t):,.0f} (target $2,000)",
        f"the ten-year-late line reaches ${val(YEARS - 10):,.0f} by year {YEARS}, "
        f"against ${val(YEARS):,.0f} — {val(YEARS) / val(YEARS - 10):.2f}x behind",
    ]
    return "".join(out), checks


# ---------------------------------------------------------------------------- spacing
def spacing():
    """Forgetting curves. One long session against the same time split over six days."""
    box = Box(38, 52, 336, 214, xmax=1.0, ymax=1.0)
    # Ebbinghaus-shaped decay with a floor: what you learn never falls all the way to
    # nothing, it settles low, and a curve that reaches zero would be a lie about that.
    FLOOR = 0.12
    decay = lambda t, s: FLOOR + (1 - FLOOR) * math.exp(-t / s)

    cram = sample(lambda t: box.pt(t, decay(t, 0.16)), 0, 1.0, 40)

    # four sessions; each review starts from full and decays more slowly than the last
    spaced, dots = [], []
    starts = [0.0, 0.22, 0.46, 0.72]
    strengths = [0.16, 0.30, 0.52, 0.95]
    for i, (t0, s) in enumerate(zip(starts, strengths)):
        end = starts[i + 1] if i + 1 < len(starts) else 1.0
        seg = sample(lambda t: box.pt(t, decay(t - t0, s)), t0, end, 14)
        spaced.append(seg)
        if i + 1 < len(starts):
            dots.append(box.pt(end, decay(end - t0, s)))

    out = [swift("spacingCram", cram, "One long session: a single decay.")]
    for i, seg in enumerate(spaced):
        out.append(swift(f"spacingSpaced{i + 1}", seg,
                         f"Session {i + 1}; each review decays more slowly than the last."))
    out.append(swift("spacingDots", dots, "Where each review picks the curve back up."))
    restarts = [box.py(decay(0.0, s)) for s in strengths[1:]]
    out.append("/// The y each review climbs back to.\n"
               + "private let spacingRestartY: [CGFloat] = ["
               + ", ".join(f"{v:.1f}" for v in restarts) + "]\n")
    checks = [
        f"cram retains {decay(1.0, 0.16) * 100:.0f}% at the end of the window",
        f"spaced retains {decay(1.0 - starts[-1], strengths[-1]) * 100:.0f}% at the same point",
        "every review starts from full and each decay is flatter than the one before, "
        "so the gap between the two lines only widens",
    ]
    return "".join(out), checks


# ------------------------------------------------------------------------------ gauge
def gauge():
    """A credit score dial. The sweep has to be the real fraction of the range."""
    LOW, HIGH, SCORE = 300, 850, 712
    frac = (SCORE - LOW) / (HIGH - LOW)
    START, SWEEP = 200.0, 140.0                  # degrees, drawn clockwise from 3 o'clock
    cx, cy, r = 180.0, 168.0, 92.0
    end = START + SWEEP * frac
    arc = [(cx + r * math.cos(math.radians(a)), cy + r * math.sin(math.radians(a)))
           for a in [START + (end - START) * i / 39 for i in range(40)]]
    rest = [(cx + r * math.cos(math.radians(a)), cy + r * math.sin(math.radians(a)))
            for a in [end + (START + SWEEP - end) * i / 19 for i in range(20)]]
    out = [swift("gaugeFilled", arc, f"{LOW} to {SCORE} of the {LOW}-{HIGH} range."),
           swift("gaugeRest", rest, f"{SCORE} to {HIGH}: the part not earned yet.")]
    checks = [
        f"{SCORE} is {frac * 100:.1f}% of the way from {LOW} to {HIGH}",
        f"the filled arc sweeps {end - START:.1f} degrees of {SWEEP:.0f}, "
        f"which is {(end - START) / SWEEP * 100:.1f}%",
    ]
    return "".join(out), checks


# --------------------------------------------------------------------------- brackets
def brackets():
    """2025 single-filer bands, and how much of $50,000 taxable lands in the top one."""
    BANDS = [(0, 11_925, 0.10), (11_925, 48_475, 0.12), (48_475, 103_350, 0.22)]
    TAXABLE = 50_000.0
    top_lo, top_hi, top_rate = BANDS[2]
    inside = max(0.0, min(TAXABLE, top_hi) - top_lo)
    frac = inside / (top_hi - top_lo)
    BUCKET_H = 70.0                      # each band is drawn the same height
    fill = frac * BUCKET_H
    tax = sum((min(TAXABLE, hi) - lo) * r for lo, hi, r in BANDS if TAXABLE > lo)
    out = ["/// How much of the top bucket is actually filled, in points.\n"
           f"private let bracketsFillH: CGFloat = {fill:.1f}\n"]
    checks = [
        f"${inside:,.0f} of ${TAXABLE:,.0f} sits in the {top_rate:.0%} band",
        f"that is {frac * 100:.1f}% of the band, so the fill is {fill:.1f}pt of {BUCKET_H:.0f}pt",
        f"total tax on ${TAXABLE:,.0f} taxable is ${tax:,.0f}, an effective rate of "
        f"{tax / TAXABLE:.1%} — not {top_rate:.0%}, which is the whole lesson",
    ]
    return "".join(out), checks


# ------------------------------------------------------------------------------ decay
def decay():
    """Forgetting bars. How much of today's lesson is still there on later days,
    with and without one review on day one."""
    DAYS = [0, 1, 2, 4, 7]
    FLOOR = 0.12
    keep = lambda t, s: FLOOR + (1 - FLOOR) * math.exp(-t / s)
    plain = [keep(t, 0.9) for t in DAYS]                # no review: steep first day
    # one recall on day one restores it to full and slows the next decay
    reviewed = [plain[0], 1.0] + [keep(t - 1, 4.5) for t in DAYS[2:]]
    BAR_H = 200.0                                        # the day-0 bar, in points
    out = ["/// Bar heights, days 0 1 2 4 7, no review. Day 0 is all of it.\n"
           "private let decayBarH: [CGFloat] = [" + ", ".join(f"{v * BAR_H:.1f}" for v in plain) + "]\n",
           "/// The same days after one recall on day one.\n"
           "private let decayReviewedH: [CGFloat] = [" + ", ".join(f"{v * BAR_H:.1f}" for v in reviewed) + "]\n"]
    checks = [
        f"without review: {', '.join(f'day {d} {v * 100:.0f}%' for d, v in zip(DAYS, plain))}",
        f"the first day loses {(plain[0] - plain[1]) * 100:.0f} points, the next six lose {(plain[1] - plain[4]) * 100:.0f}",
        f"with one review on day one: {', '.join(f'day {d} {v * 100:.0f}%' for d, v in zip(DAYS, reviewed))}",
    ]
    return "".join(out), checks


# ---------------------------------------------------------------------------- minimum
def minimum():
    """A $1,000 balance at 22% APR, paid at the card's minimum against $50 a month."""
    P, APR = 1000.0, 0.22
    r = APR / 12

    def payoff(pay):
        bal, months, paid = P, 0, 0.0
        while bal > 0.005:
            interest = bal * r
            due = pay(bal, interest)
            due = min(due, bal + interest)
            bal = bal + interest - due
            paid += due; months += 1
        return months, paid

    minimum_rule = lambda bal, i: max(25.0, 0.01 * bal + i)
    m_months, m_paid = payoff(minimum_rule)
    f_months, f_paid = payoff(lambda bal, i: 50.0)
    first = minimum_rule(P, P * r)
    # total paid as a bar next to the price: 1000 -> BAR_H points
    BAR_H = 150.0
    out = [f"/// Minimum payments on $1,000 at 22%: months to clear, and total handed over.\n"
           f"private let minimumMonths: Int = {m_months}\n"
           f"private let minimumTotal: Int = {round(m_paid)}\n"
           f"/// The same card at $50 a month.\n"
           f"private let minimumFastMonths: Int = {f_months}\n"
           f"private let minimumFastTotal: Int = {round(f_paid)}\n"
           f"/// Bar heights at {BAR_H:.0f}pt per $1,000: price, minimum total, $50 total.\n"
           f"private let minimumBarH: [CGFloat] = [{BAR_H:.1f}, {m_paid / P * BAR_H:.1f}, {f_paid / P * BAR_H:.1f}]\n"]
    checks = [
        f"first minimum is ${first:.0f}: ${P * r:.0f} interest + ${0.01 * P:.0f} principal",
        f"minimum clears in {m_months} payments ({m_months // 12} years {m_months % 12} months), total ${m_paid:,.0f}, "
        f"interest ${m_paid - P:,.0f} ({(m_paid - P) / P * 100:.0f}% over the price)",
        f"$50 a month clears in {f_months} payments ({f_months // 12} years {f_months % 12} months), total ${f_paid:,.0f}, "
        f"saving ${m_paid - f_paid:,.0f}",
    ]
    return "".join(out), checks


def workmatch():
    """The 401(k) match, as money rather than multiples.

    Card 3 needs the 4% slice at true width. Card 4 is the whole argument: your $2,080
    is worth $4,160 the day the match lands, and growing it yourself at 8% takes nine
    years to reach the same place. The shaded gap between the two is what the match
    hands you for nothing.
    """
    SALARY, MATCH, PERIODS = 52_000.0, 0.04, 26
    RATE = 0.08                                   # the rate fin-1 already uses

    contrib = SALARY * MATCH
    matched = contrib * 2
    per_cheque = SALARY / PERIODS * MATCH
    cross_t = math.log(2) / math.log(1 + RATE)    # years for your own money to double

    # --- card 3: the salary bar, with the 4% slice at its true width ----------------
    BAR_X0, BAR_W = 28.0, 304.0
    slice_w = BAR_W * MATCH

    # --- card 4: dollars against years ---------------------------------------------
    YEARS, HEAD = 10.0, 4600.0
    box = Box(62, 66, 330, 228, xmax=YEARS, ymax=HEAD, ymin=contrib)
    own = lambda t: contrib * (1 + RATE) ** t
    curve = sample(lambda t: box.pt(t, own(t)), 0, YEARS)

    baseY, topY = box.py(contrib), box.py(matched)
    leftX, rightX, crossX = box.px(0), box.px(YEARS), box.px(cross_t)

    step = [(leftX, baseY), (leftX, topY), (rightX, topY)]
    # The gap: along the match line to the crossing, then home along your own curve.
    gap = [(leftX, topY), (crossX, topY)]
    gap += [box.pt(t, own(t)) for t in [cross_t * i / 24 for i in range(24, -1, -1)]]

    out = [swift("workMarket", curve, f"${contrib:,.0f} at {RATE:.0%} a year for ten years."),
           swift("workMatchStep", step, "The match: straight to twice the money at year zero."),
           swift("workGap", gap, "What the match hands you, until your own money catches up.")]
    ticks = [box.px(t) for t in (0, 3, 6, 9)]
    out.append("/// Year ticks along the foot of the chart.\n"
               "private let workTickX: [CGFloat] = ["
               + ", ".join(f"{t:.1f}" for t in ticks) + "]\n")
    marks = {"sliceW": slice_w, "barX0": BAR_X0, "barW": BAR_W,
             "baseY": baseY, "topY": topY, "leftX": leftX, "rightX": rightX, "crossX": crossX}
    out.append("/// The 4% slice at true width, and the chart's own edges.\n"
               + "".join(f"private let work{k[0].upper()}{k[1:]}: CGFloat = {v:.1f}\n"
                         for k, v in marks.items()))
    checks = [
        f"4% of ${SALARY:,.0f} is ${contrib:,.0f} a year, or ${per_cheque:,.0f} a paycheck",
        f"matched, that is ${matched:,.0f} — a 100% return on the day it lands",
        f"on your own at {RATE:.0%} it takes {cross_t:.2f} years to reach ${matched:,.0f}",
        f"the 9-year tick is at x {ticks[3]:.1f} and the crossing at x {crossX:.1f} — "
        f"{abs(ticks[3] - crossX):.1f}pt apart, so the tick marks the crossing",
        f"the curve ends at ${own(YEARS):,.0f}, inside the ${HEAD:,.0f} ceiling",
        f"the 4% slice is {slice_w:.1f}pt of a {BAR_W:.0f}pt bar, drawn at true width",
    ]
    return "".join(out), checks


def salaryanchor():
    """The salary question. Card 2: where the answer lands against the band they had.
    Card 3: what that gap is worth after ten years of the same percentage raises."""
    LOW, HIGH, SAID = 65_000.0, 80_000.0, 60_000.0
    RAISE, YEARS = 0.03, 10
    LEAF, CORAL = "#84B345", "#FF6F61"
    out = []

    # --- card 2: one money axis, their band, and where the answer landed -----------
    money = Plot("band", Box(52, 150, 300, 196, xmax=10.0, ymax=1.0), field="rose")
    mx = lambda v: 52 + (v - 52_000.0) / 33_000.0 * 248
    bx0, bx1, said_x = mx(LOW), mx(HIGH), mx(SAID)
    # The pin the "you said" labels point at, drawn as a line so the checker sees it.
    money.lines["pin"] = {"pts": [P(said_x, 138.0), P(said_x, 208.0)],
                          "fn": lambda t: 0.0, "colour": CORAL, "w": 4.0}
    top, bot = 150.0, 196.0
    money.area([P(bx0, top), P(bx1, top), P(bx1, bot), P(bx0, bot)], LEAF, 0.9)
    for v in (70_000, 80_000):
        money.ticks.append(mx(v))
        money.labels.append({'text': f'${v // 1000}k', 'x': mx(v), 'y': 216.0,
                             'size': 12.0, 'anchor': 'middle', 'colour': INK,
                             'kind': 'tick'})
    money.free("what they budgeted", (bx0 + bx1) / 2, 173, size=12)
    money.place(f"${LOW:,.0f}", (bx0, 128), size=12)
    money.place(f"${HIGH:,.0f}", (bx1, 128), size=12)
    money.place("you said", (said_x, 232), size=12, colour=CORAL)
    money.place(f"${SAID:,.0f}", (said_x, 256), size=20, colour=CORAL)
    out.append(money.marks("band"))
    out.append(f"private let bandX0: CGFloat = {bx0:.1f}\n"
               f"private let bandX1: CGFloat = {bx1:.1f}\n"
               f"private let bandSaidX: CGFloat = {said_x:.1f}\n"
               f"private let bandTop: CGFloat = {top:.1f}\n"
               f"private let bandBottom: CGFloat = {bot:.1f}\n"
               "private let bandTickX: [CGFloat] = ["
               + ", ".join(f"{t:.1f}" for t in money.ticks) + "]\n")

    # --- card 3: two careers, same raises, one starting line lower -----------------
    pay = lambda start, t: start * (1 + RAISE) ** t
    plot = Plot("careers", Box(74, 78, 322, 206, xmax=float(YEARS), ymax=92_000.0,
                               ymin=56_000.0), field="rose")
    theirs = plot.line("theirs", lambda t: pay(LOW, t), 0, YEARS, LEAF)
    yours = plot.line("yours", lambda t: pay(SAID, t), 0, YEARS, "#2E2622")
    plot.area(theirs + yours[::-1], CORAL, 0.3)

    for t in (0, 5, 10):
        plot.tick(float(t), "now" if t == 0 else f"{t} yr")
    plot.label_on("theirs", f"${LOW:,.0f}", 0.9, "above")
    plot.label_on("yours", f"${SAID:,.0f}", 0.9, "below")
    total = sum(pay(LOW, t) - pay(SAID, t) for t in range(YEARS))
    tx, ty = plot.place(f"${total:,.0f}", (214, 104), size=20, colour=CORAL)
    plot.place("never earned", (tx, ty + 22), size=12, colour=CORAL)

    out += [swift("anchorTheirs", theirs, f"${LOW:,.0f} with {RAISE:.0%} raises."),
            swift("anchorYours", yours, f"${SAID:,.0f} with the same raises."),
            swift("anchorGap", theirs + yours[::-1], "The years between the two."),
            plot.marks("careers"),
            "private let careersRuleY: [CGFloat] = ["
            + ", ".join(f"{y:.1f}" for y in plot.rules) + "]\n"
            + "private let careersTickX: [CGFloat] = ["
            + ", ".join(f"{x:.1f}" for x in plot.ticks) + "]\n"
            + f"private let careersAxisY: CGFloat = {plot.box.y1:.1f}\n"
            + f"private let careersLeftX: CGFloat = {plot.box.x0:.1f}\n"
            + f"private let careersRightX: CGFloat = {plot.box.x1:.1f}\n"]

    prev = os.path.join(os.path.dirname(os.path.abspath(__file__)), "preview")
    os.makedirs(prev, exist_ok=True)
    money.preview(os.path.join(prev, "chart-band.svg"))
    plot.preview(os.path.join(prev, "chart-careers.svg"))

    checks = [
        f"they budgeted ${LOW:,.0f} to ${HIGH:,.0f}; saying ${SAID:,.0f} lands "
        f"${LOW - SAID:,.0f} under the floor",
        f"after {YEARS} years of {RAISE:.0%} raises: ${pay(SAID, YEARS):,.0f} "
        f"against ${pay(LOW, YEARS):,.0f}",
        f"the yearly gap widens from ${LOW - SAID:,.0f} to "
        f"${pay(LOW, YEARS) - pay(SAID, YEARS):,.0f}, because a raise is a percentage",
        f"total never earned over {YEARS} years: ${total:,.0f}",
    ] + money.check() + plot.check()
    return "".join(out), checks


CHARTS = {"compound": compound, "spacing": spacing, "gauge": gauge, "brackets": brackets,
          "decay": decay, "minimum": minimum,
          "workmatch": workmatch,
          "salaryanchor": salaryanchor}

if __name__ == "__main__":
    want = sys.argv[1:] or list(CHARTS)
    for name in want:
        code, checks = CHARTS[name]()
        print(f"\n// ===== {name} " + "=" * (60 - len(name)))
        for c in checks:
            print(f"//   check: {c}")
        print(code)

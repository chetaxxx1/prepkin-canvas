#!/usr/bin/env python3
"""Hold every lesson figure to the house scale.

    python3 design/figure-art/figcheck.py                # all of them
    python3 design/figure-art/figcheck.py SlotsFigure    # just these

Five checks, all of them things that were found by eye once and should never have to
be found by eye again:

  SCALE    a raw number where a named constant exists (Fig.leader, Fig.caption, ...)
  FIT      a chip label wider than its chip, which silently shrinks the type
  EDGE     type or a chip outside x 16..344 / y 14..286, where the band's rounded
           corners start to clip
  OVER     two pieces of type sharing space
  DEAD     a reveal step that adds nothing, which reads as a tap that did nothing

Run it before rendering. Rendering shows you what a figure looks like; this says
whether it was built the way the rest of them were.
"""
import ast, operator, re, sys, collections

FIGURES = 'ios/Sources/LessonFigures.swift'
NUM = r"[-\d.]+(?:\s*[-+*/]\s*[-\d.]+)*"
SAFE = (16, 344, 14, 286)

# the named scale, and the raw values that should now be using it
NAMED = {
    'leader': ('1.5', '2'), 'pointer': ('2.5',), 'flow': ('4', '5', '6'),
    'strike': ('3',), 'caption': ('11', '11.5', '12', '12.5'),
    'label': ('13', '14'), 'chipH': ('26', '28', '30', '32', '34', '36', '38', '40'),
}


# Coordinates in the source are small arithmetic expressions ("38 + 4 * 58"). They are
# our own code, but they are still parsed rather than eval'd: numbers and + - * / only,
# so nothing else can ever be executed by running this check.
_OPS = {ast.Add: operator.add, ast.Sub: operator.sub,
        ast.Mult: operator.mul, ast.Div: operator.truediv, ast.USub: operator.neg}


def arith(expr):
    """The value of a numeric expression, or None if it is anything more than that."""
    def walk(n):
        if isinstance(n, ast.Constant) and isinstance(n.value, (int, float)): return float(n.value)
        if isinstance(n, ast.UnaryOp) and type(n.op) in _OPS: return _OPS[type(n.op)](walk(n.operand))
        if isinstance(n, ast.BinOp) and type(n.op) in _OPS:
            return _OPS[type(n.op)](walk(n.left), walk(n.right))
        raise ValueError(n)
    try:
        return walk(ast.parse(expr.strip(), mode='eval').body)
    except Exception:
        return None


def text_width(s, size):
    """Rough width of a string at `size`, calibrated against SF Rounded heavy."""
    w = 0.0
    for ch in s:
        if ch in " .,·:'’!": w += 0.30
        elif ch in "ijl": w += 0.30
        elif ch.isupper() or ch.isdigit(): w += 0.66
        else: w += 0.58
    return w * size


def size_of(tok):
    """A literal, or the point size a named constant stands for."""
    tok = tok.strip()
    if tok.startswith('Fig.'):
        return {'Fig.caption': 12.0, 'Fig.label': 13.0, 'Fig.chipH': 30.0, 'Fig.headline': 17.0}.get(tok)
    try: return float(tok)
    except ValueError: return None


def boxes(body):
    """Every piece of type and every chip, as (kind, text, x0, y0, x1, y1, step)."""
    out, step, frame = [], 1, "body"
    for line in body.splitlines():
        # A figure whose cards are different pictures draws each in its own computed
        # view and picks one with a switch, so type in `math` can never collide with
        # type in `race`. Only type in the same frame is ever on screen together.
        f = re.search(r'(?:private\s+)?var\s+(\w+)\s*:\s*some View', line)
        if f: frame, step = f.group(1), 1
        m = re.search(r'fxLayer\((\d+),', line)
        if m: step = int(m.group(1))
        for t in re.finditer(r'fx(?:Text)\("([^"]*)",\s*([\w.]+),\s*(%s),\s*(%s)\s*[,)]' % (NUM, NUM), line):
            s, size = t.group(1), size_of(t.group(2))
            if size is None: continue
            cx, cy = arith(t.group(3)), arith(t.group(4))
            if cx is None or cy is None: continue
            w, h = text_width(s, size), size * 1.2
            out.append(('text', s, cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2, step, frame))
        for t in re.finditer(r'fxChip\("([^"]*)",\s*([\w.]+),\s*(%s),\s*(%s),\s*(%s),\s*([\w.]+)' % (NUM, NUM, NUM), line):
            s, size = t.group(1), size_of(t.group(2))
            h = size_of(t.group(6))
            if size is None or h is None: continue
            x, y, w = arith(t.group(3)), arith(t.group(4)), arith(t.group(5))
            if x is None or y is None or w is None: continue
            out.append(('chip', s, x, y, x + w, y + h, step, size, w, frame))
    return out


def check(name, body):
    found = []

    # SCALE: raw numbers where a name exists
    for m in re.finditer(r'fxStroke\(Fig\.ink,\s*([\d.]+)\)', body):
        if m.group(1) in NAMED['leader'] + NAMED['strike']:
            found.append(f"SCALE  fxStroke ink width {m.group(1)} should be a named weight")
    # only the 6-argument form carries a width; the 4-argument form is coordinates only
    for m in re.finditer(r'fxArrow\(([^)]*)\)', body):
        args = [a.strip() for a in m.group(1).split(',')]
        if len(args) >= 6 and re.fullmatch(r'[\d.]+', args[5]):
            found.append(f"SCALE  fxArrow width {args[5]} should be Fig.pointer or Fig.flow")
    for m in re.finditer(r'fx(?:Text|Left|Right)\("[^"]*",\s*(\d+(?:\.\d+)?),', body):
        if float(m.group(1)) < 15:
            found.append(f"SCALE  type size {m.group(1)} should be Fig.caption or Fig.label")
    for m in re.finditer(r'fxChip\("[^"]*",\s*(\d+(?:\.\d+)?),', body):
        found.append(f"SCALE  chip size {m.group(1)} should be Fig.caption or Fig.label")
    for m in re.finditer(r'\.opacity\((0\.\d+)\)', body):
        if m.group(1) not in ('0.5', '0.18'):  # shadow ink and a hairline rule
            found.append(f"SCALE  opacity {m.group(1)} should be Fig.dim or Fig.sub")

    bs = boxes(body)

    # FIT and EDGE
    for b in bs:
        if b[0] == 'chip':
            need = text_width(b[1], b[7]) + 20
            if need > b[8]:
                found.append(f"FIT    chip {b[1]!r} needs {need:.0f}pt, has {b[8]:.0f}pt")
        if b[2] < SAFE[0] or b[4] > SAFE[1] or b[3] < SAFE[2] or b[5] > SAFE[3]:
            found.append(f"EDGE   {b[0]} {b[1]!r} at x {b[2]:.0f}..{b[4]:.0f} y {b[3]:.0f}..{b[5]:.0f}")

    # OVER: type on type
    for i in range(len(bs)):
        for j in range(i + 1, len(bs)):
            a, b = bs[i], bs[j]
            if a[-1] != b[-1]: continue          # different frames never share a card
            if not (a[4] <= b[2] or b[4] <= a[2] or a[5] <= b[3] or b[5] <= a[3]):
                found.append(f"OVER   {a[1]!r} and {b[1]!r}")

    # DEAD: a step that draws nothing. Counts any drawing line inside the layer, not
    # just direct fx* calls, because a figure may draw through its own helper or a
    # ForEach and that still puts ink on the card.
    per, cur, depth = collections.Counter(), None, 0
    for line in body.splitlines():
        m = re.search(r'fxLayer\((\d+),', line)
        if m:
            cur, depth = int(m.group(1)), 0
            per[cur] += 0
            rest = line[m.end():]
            # a one-line layer draws on the same line as it opens
            if re.search(r'\b\w+\(', rest[rest.find('{') + 1:] if '{' in rest else ''):
                per[cur] += 1
            depth += line.count('{') - line.count('}')
            if depth <= 0: cur = None
            continue
        if cur is None: continue
        stripped = line.strip()
        depth += line.count('{') - line.count('}')
        if depth < 0: cur = None; continue
        if not stripped or stripped.startswith('//') or stripped in ('}', '{', '})'):
            continue
        per[cur] += 1
    for st, n in sorted(per.items()):
        if n == 0:
            found.append(f"DEAD   step {st} adds nothing")
    return found


# The figures written against the scale. The seventeen that predate it are only
# checked when named explicitly, so a clean run means what it says.
SCALED = set("""Slots Refresh Sunk Filter Spotlight Loop Arousal Email No Echo Ladder
Apology Paycheck Brackets Jar Burrito Trolley Ship Cave Cornell Feynman Sleep Exam""".split())

if __name__ == '__main__':
    src = open(FIGURES).read()
    parts = re.split(r"\nstruct (\w+Figure): View", src)
    args = [a for a in sys.argv[1:] if not a.startswith('-')]
    only = set(args) if args else {n + 'Figure' for n in SCALED}
    if '--all' in sys.argv[1:]: only = set()
    total = 0
    for i in range(1, len(parts), 2):
        name, body = parts[i], parts[i + 1]
        # the last struct's chunk runs on into the shared helpers below it
        cut = body.find('\n// MARK: - Design space')
        if cut > 0: body = body[:cut]
        if only and name not in only: continue
        hits = check(name, body)
        if hits:
            total += len(hits)
            print(name)
            for h in hits: print('  ' + h)
    print(f"\n{total} findings")

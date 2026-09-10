#!/usr/bin/env python3
"""Deal a year of Play puzzles into ios/Resources/Content/.

Six files, all checked before they are written:

  sorts.json     [{groups, hard, deal}]     hand-written in sorts.py (Connections-type)
  weaves.json    [{theme, grid, span, words}] themes in weaves.py, tiled here (Strands-type)
  dictionary.txt one word a line            what Weave accepts as a non-theme word
  balance.json   [{n, givens, signs}]       6x6 Takuzu with = / x signs (Tango-type), one answer, by rule
  pearls.json    [{n, regions}]             Star Battle one-star (Queens-type), one answer, by rule
  trace.json     [{n, numbers, walls}]      one path through every cell, numbers in order (Zip-type), one answer

"Solvable by rule" means a small deduction solver that never guesses gets to the
answer. That is the difficulty gate: a puzzle that needs bifurcation is thrown out.
Seeded, so re-running reproduces the same files. Run from the repo root:

    python3 design/games/gen.py            # everything
    python3 design/games/gen.py trace      # one file
"""
import json, random, sys, os, itertools, collections

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CONTENT = os.path.join(ROOT, 'ios', 'Resources', 'Content')
SEED = 20260908

# ---------------------------------------------------------------- sorts (Connections-type)

def gen_sorts(rng):
    """sorts.py, checked: four groups of four, sixteen different words, a hard
    tag of 1-5. `deal` is the shuffled order the sixteen tiles are laid out in
    (word i is group i // 4, word i % 4), never four rows that are the answer."""
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from sorts import SORTS
    out, seen = [], set()
    for hard, groups in SORTS:
        assert len(groups) == 4, groups
        assert 1 <= hard <= 5, groups
        words = [w for _, ws in groups for w in ws]
        assert len(words) == 16, groups
        assert len(set(words)) == 16, f"repeat in {groups}: {sorted(w for w in set(words) if words.count(w) > 1)}"
        for name, ws in groups:
            assert name.strip() and len(ws) == 4, groups
            for w in ws:
                assert w == w.upper() and 1 <= len(w) <= 12 and ' ' not in w, w
        key = tuple(sorted(words))
        assert key not in seen, f"duplicate sort {groups[0]}"
        seen.add(key)
        while True:
            deal = list(range(16)); rng.shuffle(deal)
            # No row of the dealt board may already be a whole group.
            if all(len({deal[r * 4 + k] // 4 for k in range(4)}) > 1 for r in range(4)):
                break
        out.append({'groups': [{'name': n, 'words': ws} for n, ws in groups], 'hard': hard, 'deal': deal})
    return out

# ---------------------------------------------------------------- weaves (Strands-type)

W_COLS, W_ROWS = 6, 8
W_MIN = 4

def w_nbrs(i):
    r, c = divmod(i, W_COLS)
    for dr in (-1, 0, 1):
        for dc in (-1, 0, 1):
            if dr == 0 and dc == 0: continue
            rr, cc = r + dr, c + dc
            if 0 <= rr < W_ROWS and 0 <= cc < W_COLS:
                yield rr * W_COLS + cc

def w_cross(a, b):
    """The other diagonal of the 2x2 a diagonal step a->b sits in, or None for a
    straight step. Two words cross when one takes a step and another takes its cross."""
    ra, ca = divmod(a, W_COLS); rb, cb = divmod(b, W_COLS)
    if ra == rb or ca == cb: return None
    return frozenset((ra * W_COLS + cb, rb * W_COLS + ca))

def w_components(free):
    seen, out = set(), []
    for s in free:
        if s in seen: continue
        stack, comp = [s], set()
        seen.add(s)
        while stack:
            i = stack.pop(); comp.add(i)
            for j in w_nbrs(i):
                if j in free and j not in seen:
                    seen.add(j); stack.append(j)
        out.append(comp)
    return out

def w_sums(lengths):
    """Every total some subset of `lengths` can make."""
    s = {0}
    for L in lengths:
        s |= {x + L for x in s}
    return s

def w_fill(rng, free, words, diag, budget):
    """Lay every word in `words` (longest first) as a path through `free`.
    Returns [(word, cells)] or None. `diag` is the set of diagonal edges in use."""
    if not words:
        return [] if not free else None
    word, rest = words[0], words[1:]
    L = len(word)
    starts = list(free); rng.shuffle(starts)
    for s in starts:
        path = [s]; used = {s}; mydiag = []
        def rec():
            budget[0] -= 1
            if budget[0] < 0: return None
            if len(path) == L:
                left = free - used
                rest_len = [len(w) for w in rest]
                sums = w_sums(rest_len)
                for comp in w_components(left):
                    if len(comp) not in sums: return None
                got = w_fill(rng, left, rest, diag | set(mydiag), budget)
                return got if got is None else [(word, list(path))] + got
            here = path[-1]
            opts = [j for j in w_nbrs(here) if j in free and j not in used]
            rng.shuffle(opts)
            for j in opts:
                x = w_cross(here, j)
                if x is not None and (x in diag or x in mydiag): continue
                path.append(j); used.add(j)
                # Record the step itself; a later step is refused when ITS cross is here.
                if x is not None: mydiag.append(frozenset((here, j)))
                got = rec()
                if got is not None: return got
                path.pop(); used.discard(j)
                if x is not None: mydiag.pop()
            return None
        got = rec()
        if got is not None: return got
        if budget[0] < 0: return None
    return None

def w_span(rng, word, budget):
    """A path for the spanning word that touches two opposite sides."""
    L = len(word)
    horizontal = rng.random() < 0.5 if L >= W_ROWS else True
    cells = list(range(W_COLS * W_ROWS)); rng.shuffle(cells)
    for s in cells:
        path = [s]; used = {s}; mydiag = []
        def rec():
            budget[0] -= 1
            if budget[0] < 0: return None
            if len(path) == L:
                if horizontal:
                    ok = any(i % W_COLS == 0 for i in path) and any(i % W_COLS == W_COLS - 1 for i in path)
                else:
                    ok = any(i // W_COLS == 0 for i in path) and any(i // W_COLS == W_ROWS - 1 for i in path)
                return list(path) if ok else None
            here = path[-1]
            opts = [j for j in w_nbrs(here) if j not in used]
            rng.shuffle(opts)
            for j in opts:
                x = w_cross(here, j)
                if x is not None and x in mydiag: continue
                path.append(j); used.add(j)
                if x is not None: mydiag.append(frozenset((here, j)))
                got = rec()
                if got is not None: return got
                path.pop(); used.discard(j)
                if x is not None: mydiag.pop()
            return None
        got = rec()
        if got is not None: return got, set(mydiag)
        if budget[0] < 0: return None
    return None

def w_pick(rng, cands, need):
    """A subset of candidates whose lengths add to `need`, 4 to 8 words, random."""
    cands = [w for w in cands if len(w) >= W_MIN]
    for _ in range(400):
        pool = cands[:]; rng.shuffle(pool)
        chosen, total = [], 0
        for w in pool:
            if total + len(w) <= need and len(chosen) < 8:
                chosen.append(w); total += len(w)
            if total == need: break
        if total == need and len(chosen) >= 4:
            return chosen
    return None

def gen_weave_one(rng, theme, span, cands):
    need = W_COLS * W_ROWS - len(span)
    # Many short tries beat one long one: a bad spanning path or word set is
    # abandoned fast and a fresh random one drawn.
    for attempt in range(600):
        words = w_pick(rng, cands, need)
        if words is None: continue
        budget = [20000]
        got = w_span(rng, span, budget)
        if got is None: continue
        spath, diag = got
        free = set(range(W_COLS * W_ROWS)) - set(spath)
        order = sorted(words, key=len, reverse=True)
        budget = [30000]
        laid = w_fill(rng, free, order, diag, budget)
        if laid is None: continue
        grid = [''] * (W_COLS * W_ROWS)
        for i, ch in zip(spath, span): grid[i] = ch
        for w, cells in laid:
            for i, ch in zip(cells, w): grid[i] = ch
        assert all(grid), theme
        rows = [''.join(grid[r * W_COLS:(r + 1) * W_COLS]) for r in range(W_ROWS)]
        # Word order on the board is by first cell, so the file gives nothing away.
        laid.sort(key=lambda wc: wc[1][0])
        return {'theme': theme, 'cols': W_COLS, 'rows': W_ROWS, 'grid': rows,
                'span': {'w': span, 'c': spath},
                'words': [{'w': w, 'c': cells} for w, cells in laid]}
    return None

def gen_weaves(rng):
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from weaves import WEAVES
    out, seen = [], set()
    for theme, span, cands in WEAVES:
        assert theme.strip() and span == span.upper() and len(span) >= W_COLS, theme
        assert len(set(cands) | {span}) == len(cands) + 1, f"repeat in {theme}"
        assert theme not in seen, f"duplicate theme {theme}"
        seen.add(theme)
        p = gen_weave_one(rng, theme, span, cands)
        print(f"  weave {theme!r}: {'ok' if p else 'FAILED'}", file=sys.stderr, flush=True)
        if p is None:
            print(f"  weave: could not tile {theme!r}", file=sys.stderr, flush=True)
            continue
        out.append(p)
    return out

def write_dictionary():
    """Every word Weave accepts as a non-theme find: the system word list, 4-10
    lowercase letters, plus every theme word. Newline separated, one file."""
    words = set()
    with open('/usr/share/dict/words') as f:
        for line in f:
            w = line.strip()
            if 4 <= len(w) <= 10 and w.isalpha() and w.islower():
                words.add(w)
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from weaves import WEAVES
    for _, span, cands in WEAVES:
        words.add(span.lower())
        for w in cands: words.add(w.lower())
    path = os.path.join(CONTENT, 'dictionary.txt')
    with open(path, 'w') as f:
        f.write('\n'.join(sorted(words)) + '\n')
    print(f"  dictionary.txt: {len(words)} words, {os.path.getsize(path)//1024} KB", file=sys.stderr, flush=True)

# ---------------------------------------------------------------- balance (Takuzu)

def bal_ok(g, N, r, c, v, signs=()):
    old = g[r][c]; g[r][c] = v
    try:
        for (r1, c1), (r2, c2), same in signs:
            if (r, c) in ((r1, c1), (r2, c2)):
                other = g[r2][c2] if (r, c) == (r1, c1) else g[r1][c1]
                if other != -1 and (other == v) != same: return False
        if sum(1 for j in range(N) if g[r][j] == v) > N // 2: return False
        if sum(1 for i in range(N) if g[i][c] == v) > N // 2: return False
        for s in range(max(0, c - 2), min(c, N - 3) + 1):
            if g[r][s] == g[r][s+1] == g[r][s+2] == v: return False
        for s in range(max(0, r - 2), min(r, N - 3) + 1):
            if g[s][c] == g[s+1][c] == g[s+2][c] == v: return False
        return True
    finally:
        g[r][c] = old

def bal_count(p, N, limit=2, signs=()):
    h = [row[:] for row in p]; n = 0
    def rec(i):
        nonlocal n
        if n >= limit: return
        if i == N * N: n += 1; return
        r, c = divmod(i, N)
        if h[r][c] != -1: rec(i + 1); return
        for v in (0, 1):
            if bal_ok(h, N, r, c, v, signs):
                h[r][c] = v; rec(i + 1); h[r][c] = -1
    rec(0); return n

def bal_deduce(p, N, signs=()):
    """Fill by rule only: pairs force their ends, gaps force their middle, a full
    half forces the rest, a sign copies or flips its known neighbour. True if
    that alone finishes the grid."""
    g = [row[:] for row in p]
    def use_signs():
        changed = False
        for (r1, c1), (r2, c2), same in signs:
            a, b = g[r1][c1], g[r2][c2]
            if a != -1 and b == -1: g[r2][c2] = a if same else 1 - a; changed = True
            elif b != -1 and a == -1: g[r1][c1] = b if same else 1 - b; changed = True
        return changed
    def line(cells):
        vals = [g[r][c] for r, c in cells]
        changed = False
        for i in range(N - 1):
            if vals[i] != -1 and vals[i] == vals[i+1]:
                for j in (i - 1, i + 2):
                    if 0 <= j < N and vals[j] == -1:
                        vals[j] = 1 - vals[i]; changed = True
        for i in range(N - 2):
            if vals[i] != -1 and vals[i] == vals[i+2] and vals[i+1] == -1:
                vals[i+1] = 1 - vals[i]; changed = True
        for v in (0, 1):
            if vals.count(v) == N // 2:
                for i in range(N):
                    if vals[i] == -1:
                        vals[i] = 1 - v; changed = True
        for (r, c), v in zip(cells, vals):
            g[r][c] = v
        return changed
    while True:
        moved = False
        for r in range(N):
            moved |= line([(r, c) for c in range(N)])
        for c in range(N):
            moved |= line([(r, c) for r in range(N)])
        moved |= use_signs()
        if not moved: break
    return all(v != -1 for row in g for v in row)

def gen_balance_one(rng, N=6):
    g = [[-1] * N for _ in range(N)]
    def fill(i):
        if i == N * N: return True
        r, c = divmod(i, N)
        for v in ([0, 1] if rng.random() < 0.5 else [1, 0]):
            if bal_ok(g, N, r, c, v):
                g[r][c] = v
                if fill(i + 1): return True
                g[r][c] = -1
        return False
    fill(0)
    # Tango's signs: = between two alike, x between two different. Four to six
    # of them, on distinct pairs, read off the finished grid so they are true.
    pairs = [((r, c), (r, c + 1)) for r in range(N) for c in range(N - 1)] + \
            [((r, c), (r + 1, c)) for r in range(N - 1) for c in range(N)]
    rng.shuffle(pairs)
    signs = []
    for a, b in pairs[:rng.randint(4, 6)]:
        signs.append((a, b, g[a[0]][a[1]] == g[b[0]][b[1]]))
    puzzle = [row[:] for row in g]
    order = list(range(N * N)); rng.shuffle(order)
    for i in order:
        r, c = divmod(i, N)
        v = puzzle[r][c]; puzzle[r][c] = -1
        if not (bal_deduce(puzzle, N, signs) and bal_count(puzzle, N, signs=signs) == 1):
            puzzle[r][c] = v
    return puzzle, signs

def gen_balance(rng, count=400):
    out, seen = [], set()
    while len(out) < count:
        if len(out) % 50 == 0: print(f"  balance {len(out)}", file=sys.stderr, flush=True)
        p, signs = gen_balance_one(rng)
        key = json.dumps(p)
        if key in seen: continue
        seen.add(key)
        out.append({'n': 6, 'givens': p,
                    'signs': [{'a': list(a), 'b': list(b), 'same': same} for a, b, same in signs]})
    return out

# ---------------------------------------------------------------- pearls (Star Battle, 1 star)

def perm_no_touch(rng, N):
    p, used = [], set()
    def rec(r):
        if r == N: return True
        cs = list(range(N)); rng.shuffle(cs)
        for c in cs:
            if c in used or (r > 0 and abs(c - p[-1]) < 2): continue
            p.append(c); used.add(c)
            if rec(r + 1): return True
            p.pop(); used.discard(c)
        return False
    return p if rec(0) else None

def grow_regions(rng, N, perm, min_size):
    reg = [[-1] * N for _ in range(N)]
    for r in range(N): reg[r][perm[r]] = r
    remaining = N * N - N
    sizes = [1] * N
    while remaining:
        # smallest regions grow first, so none stays a single given cell
        order = sorted(range(N), key=lambda k: (sizes[k], rng.random()))
        grew = False
        for k in order:
            cands = []
            for r in range(N):
                for c in range(N):
                    if reg[r][c] != k: continue
                    for dr, dc in ((1,0),(-1,0),(0,1),(0,-1)):
                        nr, nc = r + dr, c + dc
                        if 0 <= nr < N and 0 <= nc < N and reg[nr][nc] == -1:
                            cands.append((nr, nc))
            if cands:
                nr, nc = rng.choice(cands); reg[nr][nc] = k; sizes[k] += 1; remaining -= 1; grew = True
                break
        if not grew: return None
    if min(sizes) < min_size: return None
    return reg

def pearl_count(reg, N, limit=2):
    n = 0; usedC, usedR = set(), set()
    def rec(r, prev):
        nonlocal n
        if n >= limit: return
        if r == N: n += 1; return
        for c in range(N):
            k = reg[r][c]
            if c in usedC or k in usedR or (prev >= 0 and abs(c - prev) < 2): continue
            usedC.add(c); usedR.add(k); rec(r + 1, c); usedC.discard(c); usedR.discard(k)
    rec(0, -1); return n

def pearl_deduce(reg, N):
    """Rule-only solver. 0 unknown, 1 no, 2 pearl. Rules: a unit with a pearl is
    otherwise empty; a unit with one cell left takes the pearl; a pearl clears its
    eight neighbours; a region confined to one row/column clears the rest of that
    line (and a line confined to one region clears the rest of the region); a cell
    touching every candidate of some unit can never hold a pearl."""
    st = [[0] * N for _ in range(N)]
    units = []
    for r in range(N): units.append([(r, c) for c in range(N)])
    for c in range(N): units.append([(r, c) for r in range(N)])
    regs = collections.defaultdict(list)
    for r in range(N):
        for c in range(N): regs[reg[r][c]].append((r, c))
    units += list(regs.values())
    def place(r, c):
        st[r][c] = 2
        for dr in (-1, 0, 1):
            for dc in (-1, 0, 1):
                nr, nc = r + dr, c + dc
                if (dr or dc) and 0 <= nr < N and 0 <= nc < N and st[nr][nc] == 0: st[nr][nc] = 1
        for u in units:
            if (r, c) in u:
                for (ur, uc) in u:
                    if st[ur][uc] == 0: st[ur][uc] = 1
    while True:
        changed = False
        for u in units:
            pearls = [x for x in u if st[x[0]][x[1]] == 2]
            unknown = [x for x in u if st[x[0]][x[1]] == 0]
            if not pearls and len(unknown) == 1:
                place(*unknown[0]); changed = True
        # confinement
        for k, cells in regs.items():
            if any(st[r][c] == 2 for r, c in cells): continue
            cand = [x for x in cells if st[x[0]][x[1]] == 0]
            rows = {r for r, c in cand}; cols = {c for r, c in cand}
            if len(rows) == 1:
                (r,) = rows
                for c in range(N):
                    if reg[r][c] != k and st[r][c] == 0: st[r][c] = 1; changed = True
            if len(cols) == 1:
                (c,) = cols
                for r in range(N):
                    if reg[r][c] != k and st[r][c] == 0: st[r][c] = 1; changed = True
        for line in units[:2 * N]:
            if any(st[r][c] == 2 for r, c in line): continue
            cand = [x for x in line if st[x[0]][x[1]] == 0]
            ks = {reg[r][c] for r, c in cand}
            if len(ks) == 1:
                (k,) = ks
                for (r, c) in regs[k]:
                    if (r, c) not in line and st[r][c] == 0: st[r][c] = 1; changed = True
        # touching every candidate of a unit
        for u in units:
            if any(st[r][c] == 2 for r, c in u): continue
            cand = [x for x in u if st[x[0]][x[1]] == 0]
            if not cand or len(cand) > 4: continue
            for r in range(N):
                for c in range(N):
                    if st[r][c] != 0 or (r, c) in cand: continue
                    if all(abs(r - cr) <= 1 and abs(c - cc) <= 1 for cr, cc in cand):
                        st[r][c] = 1; changed = True
        if not changed: break
    return sum(1 for row in st for v in row if v == 2) == N

def connected(reg, N, k, without=None):
    cells = [(r, c) for r in range(N) for c in range(N) if reg[r][c] == k and (r, c) != without]
    if not cells: return False
    seen = {cells[0]}; q = [cells[0]]
    while q:
        r, c = q.pop()
        for dr, dc in ((1,0),(-1,0),(0,1),(0,-1)):
            x = (r + dr, c + dc)
            if 0 <= x[0] < N and 0 <= x[1] < N and x not in seen and x != without and reg[x[0]][x[1]] == k:
                seen.add(x); q.append(x)
    return len(seen) == len(cells)

def carve_pearls(rng, N, min_size=3, budget=4000):
    """Random regions have dozens of answers. So start there and hill-climb: move
    one boundary cell to a neighbouring reef at a time, keep the move when the
    answer count does not go up, stop when it is one and the rule solver agrees."""
    perm = perm_no_touch(rng, N)
    if not perm: return None
    reg = grow_regions(rng, N, perm, min_size)
    if reg is None: return None
    fixed = {(r, perm[r]) for r in range(N)}
    sizes = collections.Counter(v for row in reg for v in row)
    score = pearl_count(reg, N, 64)
    for _ in range(budget):
        r, c = rng.randrange(N), rng.randrange(N)
        if (r, c) in fixed: continue
        k = reg[r][c]
        if sizes[k] <= min_size: continue
        nbs = {reg[r+dr][c+dc] for dr, dc in ((1,0),(-1,0),(0,1),(0,-1))
               if 0 <= r+dr < N and 0 <= c+dc < N and reg[r+dr][c+dc] != k}
        if not nbs: continue
        k2 = rng.choice(sorted(nbs))
        if not connected(reg, N, k, without=(r, c)): continue
        reg[r][c] = k2; sizes[k] -= 1; sizes[k2] += 1
        new = pearl_count(reg, N, 64)
        if new > score or (new == 1 and score == 1 and rng.random() < 0.5):
            reg[r][c] = k; sizes[k] += 1; sizes[k2] -= 1
            continue
        score = new
        if score == 1 and pearl_deduce(reg, N):
            return reg
    return None

def gen_pearls(rng, count7=340, count8=60):
    out, seen = [], set()
    tries = collections.Counter()
    for N, count in ((7, count7), (8, count8)):
        got = 0
        while got < count:
            tries[N] += 1
            reg = carve_pearls(rng, N)
            if reg is None: continue
            key = json.dumps(reg)
            if key in seen: continue
            seen.add(key); got += 1
            out.append({'n': N, 'regions': reg})
            if got % 50 == 0: print(f"  pearls {N}x{N} {got} ({tries[N]} tries)", file=sys.stderr, flush=True)
    print(f"  pearls: {tries[7]} tries for {count7} 7x7, {tries[8]} tries for {count8} 8x8", file=sys.stderr)
    return out

# ---------------------------------------------------------------- trace (Zip-type)

def trace_hamiltonian(rng, N):
    """A random path through every cell, by Warnsdorff with a random tie-break
    and backtracking. Cells are r*N+c."""
    def nbrs(i):
        r, c = divmod(i, N)
        for dr, dc in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            rr, cc = r + dr, c + dc
            if 0 <= rr < N and 0 <= cc < N: yield rr * N + cc
    start = rng.randrange(N * N)
    path = [start]; used = {start}
    def rec():
        if len(path) == N * N: return True
        opts = [j for j in nbrs(path[-1]) if j not in used]
        rng.shuffle(opts)
        opts.sort(key=lambda j: sum(1 for k in nbrs(j) if k not in used))
        for j in opts:
            path.append(j); used.add(j)
            if rec(): return True
            path.pop(); used.discard(j)
        return False
    sys.setrecursionlimit(10000)
    return path if rec() else None

def trace_count(N, numbers, walls, limit=2, budget=200000):
    """Paths through every cell that hit 1..k in order, end on k, and cross no
    wall. Stops at `limit`, or at `budget` steps (returned as -1: too slow, skip)."""
    k = max(numbers)
    pos = {numbers[i]: i for i in range(N * N) if numbers[i]}
    blocked = set()
    for a, b in walls: blocked.add((a, b)); blocked.add((b, a))
    def nbrs(i):
        r, c = divmod(i, N)
        for dr, dc in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            rr, cc = r + dr, c + dc
            if 0 <= rr < N and 0 <= cc < N and (i, rr * N + cc) not in blocked: yield rr * N + cc
    used = [False] * (N * N); found = 0; steps = 0
    def rec(i, need, depth):
        nonlocal found, steps
        steps += 1
        if steps > budget or found >= limit: return
        if depth == N * N:
            if need > k: found += 1
            return
        for j in nbrs(i):
            if used[j]: continue
            nj = numbers[j]
            if nj and nj != need: continue
            if nj == k and depth != N * N - 1: continue
            used[j] = True
            rec(j, need + 1 if nj else need, depth + 1)
            used[j] = False
    used[pos[1]] = True
    rec(pos[1], 2, 1)
    return -1 if steps > budget else found

def gen_trace_one(rng, N=6):
    path = trace_hamiltonian(rng, N)
    if not path: return None
    k = rng.randint(6, 9)
    # 1 at the start, k at the end, the rest spread along the path at least two
    # cells apart, so the line has to wander between numbers.
    inner = sorted(rng.sample(range(2, N * N - 2), k - 2))
    if any(b - a < 2 for a, b in zip(inner, inner[1:])): return None
    numbers = [0] * (N * N)
    for n, idx in enumerate([0] + inner + [N * N - 1], start=1):
        numbers[path[idx]] = n
    # Walls only between neighbours the path does not step across, so the answer
    # stays valid. Start with two and add more until the board has one line.
    step = set(zip(path, path[1:])) | set(zip(path[1:], path))
    cand = []
    for i in range(N * N):
        r, c = divmod(i, N)
        if c + 1 < N and (i, i + 1) not in step: cand.append((i, i + 1))
        if r + 1 < N and (i, i + N) not in step: cand.append((i, i + N))
    rng.shuffle(cand)
    walls = cand[:2]
    while True:
        c = trace_count(N, numbers, walls)
        if c == 1: break
        if c == -1 or len(walls) >= 10 or len(walls) + 2 > len(cand): return None
        walls = cand[:len(walls) + 2]
    return {'n': N, 'numbers': [numbers[r * N:(r + 1) * N] for r in range(N)],
            'walls': [list(w) for w in walls]}

def gen_trace(rng, count=400):
    out, seen = [], set()
    tries = 0
    while len(out) < count and tries < count * 40:
        tries += 1
        if len(out) % 50 == 0 and tries % 50 == 1: print(f"  trace {len(out)}", file=sys.stderr, flush=True)
        p = gen_trace_one(rng)
        if not p: continue
        key = json.dumps(p)
        if key in seen: continue
        seen.add(key); out.append(p)
    return out

# ---------------------------------------------------------------- main

def write(name, data):
    path = os.path.join(CONTENT, name)
    with open(path, 'w') as f:
        json.dump(data, f, separators=(',', ':'))
    print(f"  {name}: {len(data)} puzzles, {os.path.getsize(path)//1024} KB", file=sys.stderr, flush=True)

if __name__ == '__main__':
    only = set(sys.argv[1:])   # e.g. `gen.py sorts weaves` re-deals just those
    print("dealing...", file=sys.stderr)
    if not only or 'sorts' in only: write('sorts.json', gen_sorts(random.Random(SEED + 1)))
    if not only or 'weaves' in only:
        write('weaves.json', gen_weaves(random.Random(SEED + 5)))
        write_dictionary()
    if not only or 'balance' in only: write('balance.json', gen_balance(random.Random(SEED + 2)))
    if not only or 'pearls' in only: write('pearls.json', gen_pearls(random.Random(SEED + 3)))
    if not only or 'trace' in only: write('trace.json', gen_trace(random.Random(SEED + 4)))
    # Every re-deal invalidates the old ratings, so rate what was just written.
    import rate
    rate.main(only if only else ())

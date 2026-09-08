#!/usr/bin/env python3
"""Deal a year of Play puzzles into ios/Resources/Content/.

Four files, all checked before they are written:

  ladders.json   [{start, end, par}]        par = shortest path in the full word list
  threads.json   [{id, name, accept, clues}] hand-written below
  balance.json   [{n, givens}]              6x6 Takuzu, one answer, solvable by rule
  pearls.json    [{n, regions}]             Star Battle one-star, one answer, solvable by rule

"Solvable by rule" means a small deduction solver that never guesses gets to the
answer. That is the difficulty gate: a puzzle that needs bifurcation is thrown out.
Seeded, so re-running reproduces the same files. Run from the repo root:

    python3 design/games/gen.py
"""
import json, random, sys, os, itertools, collections

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CONTENT = os.path.join(ROOT, 'ios', 'Resources', 'Content')
SEED = 20260908

# ---------------------------------------------------------------- ladders

def word_graph(words):
    buckets = collections.defaultdict(list)
    for w in words:
        for i in range(5):
            buckets[w[:i] + '*' + w[i+1:]].append(w)
    nb = {w: set() for w in words}
    for group in buckets.values():
        for a in group:
            for b in group:
                if a != b:
                    nb[a].add(b)
    return nb

def bfs(nb, start, limit):
    dist = {start: 0}
    q = collections.deque([start])
    while q:
        w = q.popleft()
        if dist[w] >= limit:
            continue
        for n in nb[w]:
            if n not in dist:
                dist[n] = dist[w] + 1
                q.append(n)
    return dist

def gen_ladders(rng, count=400):
    common = [w.lower() for w in json.load(open(os.path.join(CONTENT, 'words.json')))]
    full = set(w.lower() for w in json.load(open(os.path.join(CONTENT, 'guesses.json')))) | set(common)
    nb_full = word_graph(full)
    nb_common = word_graph(common)
    out, used = [], collections.Counter()
    starts = [w for w in common if len(nb_common[w]) >= 2]
    # Three passes, each letting a word appear once more, so 400 pairs come out of
    # 563 usable words without any word showing up more than a few times a year.
    for allowance in (1, 2, 3, 4, 5):
        rng.shuffle(starts)
        for start in starts:
            if len(out) >= count:
                return out
            if used[start] >= allowance:
                continue
            par = 5 if rng.random() < 0.3 else 4
            dc = bfs(nb_common, start, par)
            df = bfs(nb_full, start, par)
            # The answer has to be reachable in par using common words, and there
            # must be no shortcut through the wide list, or "par" would be a lie.
            ends = [w for w, d in dc.items() if d == par and df.get(w) == par and used[w] < allowance]
            if not ends:
                continue
            end = rng.choice(ends)
            used[start] += 1; used[end] += 1
            out.append({'start': start.upper(), 'end': end.upper(), 'par': par})
    return out

# ---------------------------------------------------------------- threads

THREADS = [
  ('card',      '___ card',                  ['card'],                       ['Wild','Green','Report','Business','Credit']),
  ('drop',      'Things you drop',           ['drop'],                       ['A beat','A hint','The ball','A class','The mic']),
  ('bank',      '___ bank',                  ['bank'],                       ['Power','River','Blood','Piggy','Food']),
  ('money',     'Slang for money',           ['money','cash'],               ['Bands','Cheddar','Bread','Dough','Bucks']),
  ('keys',      'Things with keys',          ['key','keys'],                 ['Florida','Map','Locksmith','Piano','Keyboard']),
  ('schools',   'Fictional schools',         ['fictional school','made-up school','tv school','fake school','school'], ['Greendale','Bayside',"Xavier's",'Monsters University','Hogwarts']),
  ('pull',      'Things you pull',           ['pull'],                       ['Strings','A muscle','Weight','A prank','An all-nighter']),
  ('office',    'Office ___',                ['office'],                     ['Chair','Supplies','Space','Party','Hours']),
  ('loans',     'Kinds of loan',             ['loan','loans'],               ['Payday','Auto','Personal','Mortgage','Student']),
  ('due',       'Things that are due',       ['due'],                        ['Respect','A baby','Rent','A library book','An assignment']),
  ('elements',  'Elements named after places', ['element','elements','named after places','places'], ['Polonium','Germanium','Francium','Americium','Californium']),
  ('group',     'Group ___',                 ['group'],                      ['Therapy','Discount','Text','Project','Chat']),
  ('accounts',  'Kinds of account',          ['account','accounts'],         ['Roth IRA','Email','Checking','Savings','Instagram']),
  ('space',     '___ space',                 ['space'],                      ['White','Head','Outer','Storage','Office']),
  ('credits',   'Things with credits',       ['credit','credits'],           ['Tax','Film','Movies','Transfer','Classes']),
  ('dropouts',  'College dropouts',          ['dropout','dropouts','dropped out','drop out','left college','never graduated'], ['Lady Gaga','Steve Jobs','Kanye','Bill Gates','Zuckerberg']),
  ('run',       'Things you run',            ['run'],                        ['The numbers','A fever','Late','A business','A mile']),
  ('study',     'Study ___',                 ['study'],                      ['Buddy','Hall','Break','Abroad','Group']),
  ('compound',  'Things that compound',      ['compound'],                   ['Fractures','Sentences','Pharmacies','Words','Interest']),
  ('file',      'Things you file',           ['file'],                       ['For divorce','Nails','A complaint','Papers','Taxes']),
  ('coffee',    'Coffee orders',             ['coffee','espresso'],          ['Cortado','Flat white','Americano','Cold brew','Oat latte']),
  ('hall',      '___ hall',                  ['hall'],                       ['Town','Concert','Residence','Lecture','Dining']),
  ('shot',      '___ shot',                  ['shot'],                       ['Long','Mug','Moon','Flu','Screen']),
  ('take',      'Things you take',           ['take'],                       ['The L','A hint','A shot','A break','Notes']),
  ('terms',     'Things with terms',         ['term','terms'],               ['Presidents','Contracts','Dictionaries','Loans','Semesters']),
  ('major',     '___ major',                 ['major','majors'],             ['Ursa','Canis','Sergeant','Drum','Double']),
]

def gen_threads():
    return [{'id': i, 'name': n, 'accept': a, 'clues': c} for i, n, a, c in THREADS]

# ---------------------------------------------------------------- balance (Takuzu)

def bal_ok(g, N, r, c, v):
    old = g[r][c]; g[r][c] = v
    try:
        if sum(1 for j in range(N) if g[r][j] == v) > N // 2: return False
        if sum(1 for i in range(N) if g[i][c] == v) > N // 2: return False
        for s in range(max(0, c - 2), min(c, N - 3) + 1):
            if g[r][s] == g[r][s+1] == g[r][s+2] == v: return False
        for s in range(max(0, r - 2), min(r, N - 3) + 1):
            if g[s][c] == g[s+1][c] == g[s+2][c] == v: return False
        return True
    finally:
        g[r][c] = old

def bal_count(p, N, limit=2):
    h = [row[:] for row in p]; n = 0
    def rec(i):
        nonlocal n
        if n >= limit: return
        if i == N * N: n += 1; return
        r, c = divmod(i, N)
        if h[r][c] != -1: rec(i + 1); return
        for v in (0, 1):
            if bal_ok(h, N, r, c, v):
                h[r][c] = v; rec(i + 1); h[r][c] = -1
    rec(0); return n

def bal_deduce(p, N):
    """Fill by rule only: pairs force their ends, gaps force their middle, a full
    half forces the rest. True if that alone finishes the grid."""
    g = [row[:] for row in p]
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
    puzzle = [row[:] for row in g]
    order = list(range(N * N)); rng.shuffle(order)
    for i in order:
        r, c = divmod(i, N)
        v = puzzle[r][c]; puzzle[r][c] = -1
        if not (bal_deduce(puzzle, N) and bal_count(puzzle, N) == 1):
            puzzle[r][c] = v
    return puzzle

def gen_balance(rng, count=400):
    out, seen = [], set()
    while len(out) < count:
        if len(out) % 50 == 0: print(f"  balance {len(out)}", file=sys.stderr, flush=True)
        p = gen_balance_one(rng)
        key = json.dumps(p)
        if key in seen: continue
        seen.add(key)
        out.append({'n': 6, 'givens': p})
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

def gen_pearls(rng, count7=340, count8=60):
    out, seen = [], set()
    tries = collections.Counter()
    for N, count in ((7, count7), (8, count8)):
        got = 0
        while got < count:
            tries[N] += 1
            perm = perm_no_touch(rng, N)
            if not perm: continue
            reg = grow_regions(rng, N, perm, min_size=3)
            if reg is None: continue
            key = json.dumps(reg)
            if key in seen: continue
            if pearl_count(reg, N) != 1: continue
            if not pearl_deduce(reg, N): continue
            seen.add(key); got += 1
            out.append({'n': N, 'regions': reg})
            if got % 50 == 0: print(f"  pearls {N}x{N} {got} ({tries[N]} tries)", file=sys.stderr, flush=True)
    print(f"  pearls: {tries[7]} tries for {count7} 7x7, {tries[8]} tries for {count8} 8x8", file=sys.stderr)
    return out

# ---------------------------------------------------------------- main

def write(name, data):
    path = os.path.join(CONTENT, name)
    with open(path, 'w') as f:
        json.dump(data, f, separators=(',', ':'))
    print(f"  {name}: {len(data)} puzzles, {os.path.getsize(path)//1024} KB", file=sys.stderr, flush=True)

if __name__ == '__main__':
    only = set(sys.argv[1:])   # e.g. `gen.py ladders threads` re-deals just those
    print("dealing...", file=sys.stderr)
    if not only or 'ladders' in only: write('ladders.json', gen_ladders(random.Random(SEED + 1)))
    if not only or 'threads' in only: write('threads.json', gen_threads())
    if not only or 'balance' in only: write('balance.json', gen_balance(random.Random(SEED + 2)))
    if not only or 'pearls' in only: write('pearls.json', gen_pearls(random.Random(SEED + 3)))

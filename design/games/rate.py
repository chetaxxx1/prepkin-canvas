#!/usr/bin/env python3
"""Writes a `rating` onto every puzzle, so a solve can move a player's rating.

Copied from chess.com, where a puzzle carries its own rating and the player's
moves against it: solving one above your rating gains a lot, failing one below
it costs a lot. Their ratings come from watching who solves what. We have no
players yet, so this is the seed — a per-game difficulty measure, ranked inside
that game's own pool and stretched over 400-2000. Percentile rather than an
absolute scale, because "the 70th-hardest Balance board of 400" is something we
can actually measure and "1450 elo" is not.

Runs over the JSON `gen.py` already wrote. It never re-deals, so today's board
stays today's board.

    python3 design/games/rate.py            # all five
    python3 design/games/rate.py balance    # just one
"""

import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CONTENT = os.path.join(ROOT, 'ios', 'Resources', 'Content')

LOW, HIGH = 400, 2000


def load(name):
    with open(os.path.join(CONTENT, name + '.json')) as f:
        return json.load(f)


def save(name, data):
    path = os.path.join(CONTENT, name + '.json')
    with open(path, 'w') as f:
        json.dump(data, f, separators=(',', ':'))
    return path


# ---------------------------------------------------------------- the measures
# Each returns "how hard", higher being harder. Only the ORDER matters; the
# numbers never leave this file.

def rate_sorts(puzzles):
    # The author's own 1-5 call, made while writing the traps. Nothing in the
    # words themselves says how misleading a group is.
    return [p['hard'] for p in puzzles]


def rate_weaves(puzzles):
    # A word that bends is harder to see than one that runs straight. Count the
    # turns across every path, spanning word included.
    def turns(cells, cols):
        t = 0
        for a, b, c in zip(cells, cells[1:], cells[2:]):
            d1 = (b // cols - a // cols, b % cols - a % cols)
            d2 = (c // cols - b // cols, c % cols - b % cols)
            if d1 != d2:
                t += 1
        return t
    return [sum(turns(w['c'], p['cols']) for w in p['words'] + [p['span']]) for p in puzzles]


def rate_balance(puzzles):
    # Blanks. The classic Takuzu difficulty driver: the fewer cells you are given,
    # the longer the chain of deductions before the grid closes.
    return [sum(1 for row in p['givens'] for v in row if v == -1) for p in puzzles]


def rate_pearls(puzzles):
    # Star Battle difficulty lives in the big sprawling regions: a region confined
    # to two or three cells places its own star, a region of twelve does not.
    out = []
    for p in puzzles:
        sizes = {}
        for row in p['regions']:
            for r in row:
                sizes[r] = sizes.get(r, 0) + 1
        big = sorted(sizes.values(), reverse=True)
        out.append(sum(big[:2]) / 2.0)
    return out


def rate_trace(puzzles):
    # Every number and every wall is a constraint that does the solving for you.
    # What is left over is the part you have to work out.
    return [p['n'] * p['n']
            - sum(1 for row in p['numbers'] for v in row if v)
            - len(p['walls'])
            for p in puzzles]


MEASURES = {
    'sorts': rate_sorts,
    'weaves': rate_weaves,
    'balance': rate_balance,
    'pearls': rate_pearls,
    'trace': rate_trace,
}


# ---------------------------------------------------------------- the mapping

def to_ratings(scores):
    """Rank inside the pool, then stretch over LOW..HIGH.

    Ties share a rating, so two identical boards can never be worth different
    amounts. A pool of one lands in the middle rather than at either end.
    """
    if not scores:
        return []
    if len(scores) == 1:
        return [(LOW + HIGH) // 2]
    order = sorted(range(len(scores)), key=lambda i: scores[i])
    out = [0] * len(scores)
    i = 0
    while i < len(order):
        j = i
        while j + 1 < len(order) and scores[order[j + 1]] == scores[order[i]]:
            j += 1
        # Mid-rank for the whole tied run, so a long tie sits where it belongs
        # instead of drifting to whichever end came first.
        pct = ((i + j) / 2.0) / (len(order) - 1)
        for k in range(i, j + 1):
            out[order[k]] = int(round(LOW + (HIGH - LOW) * pct))
        i = j + 1
    return out


def main(only=()):
    names = [n for n in MEASURES if not only or n in only]
    for name in names:
        puzzles = load(name)
        ratings = to_ratings(MEASURES[name](puzzles))
        for p, r in zip(puzzles, ratings):
            p['rating'] = r
        save(name, puzzles)
        lo, hi = min(ratings), max(ratings)
        mid = sorted(ratings)[len(ratings) // 2]
        print(f"  {name}: {len(puzzles)} rated, {lo}-{hi}, median {mid}",
              file=sys.stderr, flush=True)


if __name__ == '__main__':
    main(set(sys.argv[1:]))

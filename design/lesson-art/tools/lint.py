#!/usr/bin/env python3
"""Check a lesson plan against the house rules before anything is painted or built.

  python3 tools/lint.py work-4 hlth-1        (or no ids: every folder with a plan.py)

The rules, each of which cost a round with George: eleven cards; every picture card has
two real lines (95+ characters); no em or en dashes; sentences under 20 words; check
options of equal length and equal plausibility; a real reference or a code figure owns
every layout, so every painting spec names its count.
"""
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import plan as P

def sentences(s):
    return [x for x in re.split(r"(?<=[.!?])\s+", s.strip()) if x]

def lint(lesson_id):
    L = P.load(lesson_id); bad = []; warn = []
    cards = L["cards"]
    kinds = [c["kind"] for c in cards]
    if len(cards) != 11: bad.append(f"{len(cards)} cards, want 11")
    if kinds.count("image") != 9: bad.append(f"{kinds.count('image')} picture cards, want 9")
    if kinds[-2:] != ["key", "check"]: bad.append("last two cards must be key then check")
    text_fields = [L["title"], L["blurb"], L["takeaway"]]
    for i, c in enumerate(cards, 1):
        for k in ("eyebrow", "body", "question", "why"):
            if k in c: text_fields.append(c[k])
        if c["kind"] == "image":
            if len(c["body"]) < 95: bad.append(f"card {i}: body is {len(c['body'])} chars, want 95+")
            if len(c.get("eyebrow", "")) > 26: warn.append(f"card {i}: eyebrow is long ({len(c['eyebrow'])})")
            if "paint" in c:
                spec = c["paint"]
                if not re.search(r"\b(exactly|no people|no person|no face|one person|two people|three people|four people)\b", spec, re.I):
                    bad.append(f"card {i}: painting spec never says how many people")
                if "The card says" not in spec: warn.append(f"card {i}: painting spec does not quote the card")
                if not c["src"].startswith("p"): bad.append(f"card {i}: painting src should start with p, got {c['src']}")
            else:
                if not c["src"].startswith("fig-"): bad.append(f"card {i}: figure src should start with fig-, got {c['src']}")
            if c["src"][1:3] != f"{i:02d}" and c["src"][4:6] != f"{i:02d}":
                bad.append(f"card {i}: src {c['src']} does not carry the card number {i:02d}")
        if c["kind"] == "check":
            ch = c["choices"]; text_fields += ch
            if len(ch) != 3: bad.append("check: want exactly 3 choices")
            lens = [len(x) for x in ch]
            if max(lens) - min(lens) > 8: bad.append(f"check: option lengths {lens} differ by more than 8")
            if not (0 <= c["answer"] < len(ch)): bad.append("check: answer index out of range")
    for t in text_fields:
        if "—" in t or "–" in t: bad.append(f"dash in: {t[:60]!r}")
        for s in sentences(t):
            n = len(s.split())
            if n > 20: warn.append(f"{n}-word sentence: {s[:70]!r}")
    words = sum(len(c.get("body", "").split()) for c in cards) + len(cards[-1]["question"].split()) + len(cards[-1]["why"].split())
    if not 250 <= words <= 380: warn.append(f"{words} words (house range 250-380)")
    paints = len(P.paintings(L)); figs = len(P.figures(L))
    print(f"{lesson_id}: {len(cards)} cards, {paints} paintings, {figs} figures, {words} words")
    for b in bad: print("  BAD ", b)
    for w in warn: print("  warn", w)
    return not bad

if __name__ == "__main__":
    ids = sys.argv[1:] or sorted(d for d in os.listdir(P.ROOT) if d != "tools" and os.path.exists(os.path.join(P.ROOT, d, "plan.py")))
    ok = all([lint(i) for i in ids])
    sys.exit(0 if ok else 1)

#!/usr/bin/env python3
"""Print the painting list for Ink (the Grok art bot) from one or more plans.

  python3 tools/brief.py work-4 hlth-1 > ../grok-brief-ink-03-partC.txt

Only the painting cards go out. Every line carries the exact file name, the scene, the
people count, and the sentence the card will say, so Ink never has to guess the point.
"""
import sys, textwrap
sys.path.insert(0, __import__("os").path.dirname(__import__("os").path.abspath(__file__)))
import plan as P

def part_c(ids, owed_only=False):
    out = []
    out.append(textwrap.dedent(f"""\
    Read /workspace/prepkin/LESSON-ART-RULES.md first. This batch is {len(ids)} lesson{'s' if len(ids) != 1 else ''}. Do them
    one lesson at a time, in this order, and stop after each lesson so I can check it
    before you start the next. File names are exact. Every picture is 4:3, 1200 x 900
    or larger. Every picture: no text, no logos, count the people, then zip the folder.
    """))
    for k, lid in enumerate(ids, 1):
        L = P.load(lid); ps = P.paintings(L)
        if owed_only: ps = [(n, c) for n, c in ps if not P.source_path(lid, c)]
        if not ps: continue
        out.append("=" * 71)
        out.append(f"LESSON {k} of {len(ids)}: {lid} \"{L['title']}\". {len(ps)} pictures.")
        out.append(f"Folder: /workspace/prepkin/lesson-art/{lid}/   Zip it as {lid}.zip when done.\n")
        for n, c in ps:
            out.append(f"{c['src']}.png — " + c["paint"].strip() + "\n")
    out.append("=" * 71)
    out.append(textwrap.dedent("""\
    After each lesson: show every picture at full size and at 400 x 300, with the three
    lines under each (people count, anything that could read as text, which brief line).
    Then zip the lesson folder as <lesson-id>.zip, show the zip so I can download it, and
    wait for me before the next lesson."""))
    return "\n".join(out)

if __name__ == "__main__":
    args = sys.argv[1:]; owed = "--owed" in args
    print(part_c([a for a in args if not a.startswith("--")], owed))

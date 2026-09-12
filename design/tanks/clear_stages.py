"""Clear the floor of an existing tank painting so it can take slots.

    python3 design/tanks/clear_stages.py ~/Downloads/Sprout-handoff/public/tanks/lagoon.png ...
        [--out design/tanks/trial/clear] [--tries 3]

The floor rule (GROK-TANK-PROMPTS.md): the floor is a bare, flat plane from the
horizon down, and everything painted stands ON the horizon line, hangs from the top,
or hugs the far edge. The five shipping tanks were painted before the rule and have
discs, plants and mounds standing on the floor exactly where a slot prop's feet go.

This asks the Gemini image model to EDIT the painting — erase what stands on the
floor, keep everything else pixel-close — then runs the same stage check the
compositor gates on, and retries with a firmer prompt until both stages are bare or
the tries run out. The best attempt (lowest stage texture) is kept as
`<name>-clear.png`, and the report says PASS or FAIL per tank so nothing slips
through on hope. Gemini, not Grok: this is a cleanup of an accepted look, and an
edit keeps that look where a fresh paint would not.
"""
import argparse, os, subprocess, sys
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import check_tank as ct

PY = os.path.expanduser("~/.claude/skills/nano-banana/.venv/bin/python")
GEN = os.path.expanduser("~/.claude/skills/nano-banana/scripts/genimage.py")

PROMPTS = [
    "Edit this image. Remove everything that stands or lies on the floor in front of the ridge of "
    "mounds: every flat stepping disc, every plant, coral, rock, pebble and scattered object on the "
    "ground. Keep the back wall, the ridge of mounds along the horizon, anything hanging from the "
    "top, the light, the colours, the framing and the size exactly the same. The floor becomes a "
    "bare, flat, empty plane from the horizon to the bottom edge, in its own colour, with nothing on "
    "it anywhere. No text, no bubbles, no fish.",
    "Edit this image again and be strict: the floor must be completely EMPTY. Erase every object "
    "that touches the floor in front of the mounds — discs, plants, clusters, small items — and "
    "fill those spots with the same smooth floor colour around them. Change nothing above the "
    "horizon line. Same framing, same size, no text, no bubbles, no fish.",
]


def score(path):
    im = Image.open(path).convert("RGB")
    row = ct.floor_line(im)
    plate, scale = ct.cut(im, row)
    y0 = 0 if im.height * scale <= ct.H else max(0, min(im.height * scale - ct.H, row * scale - ct.FLOOR_AT * ct.H))
    floor_frac = (row * scale - y0) / ct.H
    rep = ct.stage_report(plate, floor_frac)
    ok = all(v[0] for v in rep.values())
    # a single number to rank attempts by: the worst stage's texture
    worst = max(float(v[1].split("texture ")[1].split(" ")[0]) for v in rep.values())
    return ok, worst, rep


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("paintings", nargs="+")
    ap.add_argument("--out", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "trial", "clear"))
    ap.add_argument("--tries", type=int, default=3)
    ap.add_argument("--hires", action="store_true",
                    help="ask for a 2K edit (the Pro model, more credits): the default edit comes back at 1200 px wide, "
                         "a 1.2x upscale into the 1440 plate — fine for a proof, soft for shipping")
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)
    summary = []
    for src in args.paintings:
        name = os.path.splitext(os.path.basename(src))[0]
        ok0, worst0, _ = score(src)
        print(f"{name}: before — stages {'bare' if ok0 else 'DRESSED'} (texture {worst0:.2f})")
        if ok0:
            summary.append((name, True, "already bare, untouched"))
            continue
        best = None
        current = src
        for i in range(args.tries):
            out = os.path.join(args.out, f"{name}-try{i + 1}.png")
            prompt = PROMPTS[min(i, len(PROMPTS) - 1)]
            # Match the SOURCE aspect. The first run asked for 4:3 from 3:2 paintings and
            # the model squashed the whole scene 11% narrower instead of cropping it (the
            # council caught it with a wall diff): every object moved and the plate no longer
            # matched what ships. 3:2 in, 3:2 out; the cutter crops, as it always has.
            sw, sh = Image.open(src).size
            aspect = min(("3:2", "2:3", "4:3", "3:4", "1:1", "16:9", "9:16"),
                         key=lambda r: abs(sw / sh - int(r.split(":")[0]) / int(r.split(":")[1])))
            cmd = [PY, GEN, "--prompt", prompt, "--images", current, "--aspect-ratio", aspect, "--output", out]
            if args.hires:
                cmd += ["--resolution", "2K"]
            r = subprocess.run(cmd, capture_output=True, text=True)
            if not os.path.exists(out):
                print(f"  try {i + 1}: no image ({r.stderr.strip()[-200:]})")
                continue
            ok, worst, rep = score(out)
            print(f"  try {i + 1}: {'PASS' if ok else 'fail'} (texture {worst:.2f})")
            for side, (sok, note) in rep.items():
                print(f"      {note}")
            if best is None or worst < best[1]:
                best = (out, worst, ok)
            if ok:
                break
            current = out  # edit the edit: what survived one pass rarely survives two
        if best:
            final = os.path.join(args.out, f"{name}-clear.png")
            Image.open(best[0]).save(final)
            summary.append((name, best[2], f"{'PASS' if best[2] else 'FAIL'} — {os.path.basename(final)} (texture {best[1]:.2f})"))
        else:
            summary.append((name, False, "no image came back"))
    print("\nsummary:")
    for name, ok, note in summary:
        print(f"  {name:9} {note}")
    sys.exit(0 if all(ok for _, ok, _ in summary) else 1)


if __name__ == "__main__":
    main()

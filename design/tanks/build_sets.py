"""Paint whole theme sets from the pack with Gemini, check them, compose them.

    python3 design/tanks/build_sets.py castle zen frost vapor        # theme sets
    python3 design/tanks/build_sets.py --loose                       # the twelve loose pieces
    python3 design/tanks/build_sets.py --earned                      # the seven earned pieces
    python3 design/tanks/build_sets.py --all                         # everything not yet built

Reads GROK-TANK-PROMPTS.md (the same prompts Grok would get), paints each theme's
six images with the Gemini image model (three at a time), checks the empty tank
against the rules — bare stages, horizon 0.58-0.74, quiet centre, pale top on a light
tank — and repaints a failing tank once with the failed rule spelled out. Then it
composes the set with compose_tank.py (which refuses a dressed stage and reports any
piece hidden under Home's chips or the island), checks the composite, and writes a
contact sheet. Everything lands in design/tanks/trial/sets/<theme>/ and a one-line
verdict per theme goes to trial/sets/REPORT.md. Already-painted files are kept, so a
rerun only fills gaps.
"""
import argparse, json, os, re, subprocess, sys, time
from concurrent.futures import ThreadPoolExecutor
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import check_tank as ct

PY = os.path.expanduser("~/.claude/skills/nano-banana/.venv/bin/python")
GEN = os.path.expanduser("~/.claude/skills/nano-banana/scripts/genimage.py")
REF = {"light": os.path.expanduser("~/Downloads/Sprout-handoff/public/tanks/reef.png"),
       "dark": os.path.expanduser("~/Downloads/Sprout-handoff/public/tanks/deep.png")}
PACK = os.path.join(HERE, "GROK-TANK-PROMPTS.md")
OUT = os.path.join(HERE, "trial", "sets")
ORDER = ["treasure", "castle", "zen", "frost", "vapor", "disco", "orbit", "arcade", "lantern", "magma",
         "library", "cottage", "lofi", "court", "haunt"]
FIXES = {
    "bare floor": " The floor is completely empty: nothing on the floor plane at all, not even discs; the two or three discs only touch the far left and right frame edges.",
    "floor line": " The horizon, where the wall meets the floor, sits exactly two thirds of the way down the frame, level across the whole width.",
    "quiet centre": " The middle third of the frame is the plainest part of the picture: smooth wall, a low smooth ridge, empty floor, nothing else.",
    "pale top": " The top fifth of the wall is very pale, almost white, with nothing painted on it.",
}


def pack():
    s = open(PACK).read()
    def shared(name):
        t = s[s.index(f"- **{name}** = `") + len(f"- **{name}** = `"):]
        return t[:t.index("`")]
    SH = {k: shared(k) for k in ("STYLE", "EMPTY", "PROP", "CORNER", "LIGHT")}
    themes = {}
    for m in re.finditer(r"^### \d+\. (\w+) — `(\w+)` — (light|DARK)", s, re.M):
        name, tid, mode = m.group(1), m.group(2), "dark" if m.group(3) == "DARK" else "light"
        b = s[s.index("```text", m.end()) + 7:]
        b = b[:b.index("```")]
        parts = re.split(r"\n\n(?=[A-Z][A-Z ]*(?: \(.*?\))?: )", b.strip())
        out = {"name": name, "mode": mode}
        for part in parts:
            mm = re.match(r"([A-Z][A-Z ]*?)(?: \((.*?)\))?: (.*)", part, re.S)
            key, note, txt = mm.group(1), mm.group(2) or "", mm.group(3).replace("\n", " ").strip()
            txt = txt.replace("STYLE", SH["STYLE"]).replace("EMPTY", SH["EMPTY"])
            txt = re.sub(r"^PROP ", SH["PROP"] + " ", txt)
            txt = re.sub(r"^CORNER ", SH["CORNER"] + " ", txt)
            txt = re.sub(r"^LIGHT ", SH["LIGHT"] + " ", txt)
            if "GREEN" in note:
                txt = txt.replace("#FF00FF", "#00FF00").replace("magenta", "green")
            out[key] = txt
            c = re.search(r"--light-color '(#[0-9A-Fa-f]+)'", note)
            if c:
                out["light_color"] = c.group(1)
        themes[tid] = out
    # loose + earned, from their own sections
    loose = {}
    sec = s[s.index("### Loose pieces"):s.index("### Earned pieces")]
    for m in re.finditer(r"^(STAND|CORNER|LIGHT)\s+(\w+)\s*: (\w+) (.*?)(?:\s+--light-color '(#[0-9A-Fa-f]+)')?$", sec, re.M):
        kind, pid, word, body, col = m.groups()
        base = {"STAND": SH["PROP"], "CORNER": SH["CORNER"], "LIGHT": SH["LIGHT"]}[kind]
        loose[pid] = {"kind": kind.lower(), "prompt": base + " " + body.strip(), "light_color": col}
    earned = {
        "first-assignment": ("stand", "a tiny gold star standing on a small round wooden stand"),
        "clean-week": ("corner", "a small calendar page on a string, every box ticked in mint, no numbers"),
        "deep-work": ("stand", "an hourglass in a wooden frame, all its sand run through to the bottom"),
        "reader": ("stand", "a stack of five clay books with the top one lying open, blank pages"),
        "semester": ("stand", "a rolled diploma tube in cream with a coral ribbon, standing upright"),
        "league": ("corner", "a small brass bell on a short rope"),
        "night-owl": ("light", "a round pale moon lamp on a cord, glowing soft silver"),
    }
    earned = {k: {"kind": kind, "prompt": {"stand": SH["PROP"], "corner": SH["CORNER"], "light": SH["LIGHT"]}[kind] + " " + body + ".",
                  "light_color": "#E6ECFF" if kind == "light" else None} for k, (kind, body) in earned.items()}
    return themes, loose, earned


def gen(prompt, out, aspect, ref=None):
    if os.path.exists(out):
        return True
    cmd = [PY, GEN, "--prompt", prompt, "--aspect-ratio", aspect, "--output", out]
    if ref:
        cmd[3] = "The attached image is the STYLE reference: same clay material, light and camera. Paint a new scene: " + prompt
        cmd += ["--images", ref]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if "RESOURCE_EXHAUSTED" in r.stdout + r.stderr:
        raise SystemExit("Gemini credits are out (429). Top up at ai.studio and rerun; finished files are kept.")
    return os.path.exists(out)


def tank_fails(path, mode):
    im = Image.open(path).convert("RGB")
    row = ct.floor_line(im)
    plate, scale = ct.cut(im, row)
    y0 = 0 if im.height * scale <= ct.H else max(0, min(im.height * scale - ct.H, row * scale - ct.FLOOR_AT * ct.H))
    ff = (row * scale - y0) / ct.H
    m = ct.measure(plate, ff)
    fails = []
    if not all(v[0] for v in ct.stage_report(plate, ff).values()):
        fails.append("bare floor")
    if not 0.58 <= ff <= 0.74:
        fails.append("floor line")
    if m["centre"] > 0.85:
        fails.append("quiet centre")
    if mode == "light" and (m["clock"] < 165 or m["battery"] < 165):
        fails.append("pale top")
    return fails


def build_theme(tid, t):
    d = os.path.join(OUT, tid)
    os.makedirs(d, exist_ok=True)
    tank = os.path.join(d, f"{tid}-tank.png")
    # the tank, with one repaint that names the failed rules
    gen(t["TANK"], tank, "4:3", REF[t["mode"]])
    fails = tank_fails(tank, t["mode"])
    if fails:
        retry = os.path.join(d, f"{tid}-tank-retry.png")
        gen(t["TANK"] + "".join(FIXES[f] for f in fails), retry, "4:3", REF[t["mode"]])
        f2 = tank_fails(retry, t["mode"])
        if len(f2) < len(fails):
            os.replace(tank, os.path.join(d, f"{tid}-tank-first.png"))
            os.replace(retry, tank)
            fails = f2
    # the five pieces, three at a time
    jobs = [("left", t["LEFT"], "1:1"), ("right", t["RIGHT"], "1:1"),
            ("tl", t["CORNER L"], "3:4"), ("tr", t["CORNER R"], "3:4"), ("light", t["LIGHT"], "3:4")]
    with ThreadPoolExecutor(3) as ex:
        list(ex.map(lambda j: gen(j[1], os.path.join(d, f"{tid}-{j[0]}.png"), j[2]), jobs))
    # compose + check
    cmd = [sys.executable, os.path.join(HERE, "compose_tank.py"), "--id", tid, "--tank", tank,
           "--out", os.path.join(d, f"{tid}-set.png"), "--layers", os.path.join(d, "layers"),
           "--light-color", t.get("light_color", "#FFFFFF")]
    for slot in ("left", "right", "tl", "tr", "light"):
        cmd += [f"--{slot}", os.path.join(d, f"{tid}-{slot}.png")]
    if "bare floor" in fails:
        cmd.append("--force")
    r = subprocess.run(cmd, capture_output=True, text=True)
    blocked = [l.strip() for l in r.stdout.splitlines() if "BLOCKED" in l]
    chk = subprocess.run([sys.executable, os.path.join(HERE, "check_tank.py"), os.path.join(d, f"{tid}-set.png"),
                          "--id", tid, "--out", os.path.join(d, "check")], capture_output=True, text=True)
    verdict = "PASS" if "RESULT: PASS" in chk.stdout else "FAIL"
    failed_rules = [l.strip() for l in chk.stdout.splitlines() if "[FAIL]" in l]
    sheet(tid, d)
    line = f"| {t['name']} | {t['mode']} | tank: {'ok' if not fails else ', '.join(fails)} | set: {verdict}" \
           + (f" — {'; '.join(x.split(': ',1)[0] for x in failed_rules)}" if failed_rules else "") \
           + (f" | {'; '.join(blocked)}" if blocked else "") + " |"
    return line


def sheet(tid, d):
    tiles = []
    for name in (f"{tid}-tank", f"{tid}-left", f"{tid}-right", f"{tid}-tl", f"{tid}-tr", f"{tid}-light", f"{tid}-set"):
        p = os.path.join(d, name + ".png")
        if os.path.exists(p):
            im = Image.open(p).convert("RGB")
            im.thumbnail((420, 420))
            tiles.append(im)
    if not tiles:
        return
    W = sum(t.width for t in tiles) + 10 * (len(tiles) + 1)
    H = max(t.height for t in tiles) + 20
    s = Image.new("RGB", (W, H), "white")
    x = 10
    for t in tiles:
        s.paste(t, (x, 10))
        x += t.width + 10
    s.save(os.path.join(d, f"{tid}-sheet.png"))


def build_pieces(items, folder):
    d = os.path.join(OUT, folder)
    os.makedirs(d, exist_ok=True)
    jobs = [(pid, it["prompt"], "1:1" if it["kind"] == "stand" else "3:4") for pid, it in items.items()]
    with ThreadPoolExecutor(3) as ex:
        list(ex.map(lambda j: gen(j[1], os.path.join(d, f"{j[0]}.png"), j[2]), jobs))
    tiles = []
    for pid in items:
        p = os.path.join(d, f"{pid}.png")
        if os.path.exists(p):
            im = Image.open(p).convert("RGB")
            im.thumbnail((300, 300))
            tiles.append(im)
    if tiles:
        cols = 6
        rows = (len(tiles) + cols - 1) // cols
        cw, chh = max(t.width for t in tiles) + 10, max(t.height for t in tiles) + 10
        s = Image.new("RGB", (cw * cols + 10, chh * rows + 10), "white")
        for i, t in enumerate(tiles):
            s.paste(t, (10 + (i % cols) * cw, 10 + (i // cols) * chh))
        s.save(os.path.join(d, f"{folder}-sheet.png"))
    return f"| {folder} | — | {sum(os.path.exists(os.path.join(d, f'{pid}.png')) for pid in items)} of {len(items)} painted | — |"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("themes", nargs="*")
    ap.add_argument("--loose", action="store_true")
    ap.add_argument("--earned", action="store_true")
    ap.add_argument("--all", action="store_true")
    args = ap.parse_args()
    themes, loose, earned = pack()
    todo = [t for t in ORDER if t in themes] if args.all else args.themes
    os.makedirs(OUT, exist_ok=True)
    report = os.path.join(OUT, "REPORT.md")
    if not os.path.exists(report):
        open(report, "w").write("# Sets built with Gemini stand-ins\n\n| theme | light/dark | tank | set |\n| --- | --- | --- | --- |\n")
    t0 = time.time()
    for tid in todo:
        if tid in ("treasure", "orbit") and os.path.exists(os.path.join(OUT, tid, f"{tid}-set.png")):
            continue
        line = build_theme(tid, themes[tid])
        open(report, "a").write(line + "\n")
        print(line, f"({(time.time() - t0) / 60:.1f} min)", flush=True)
    if args.loose or args.all:
        line = build_pieces(loose, "loose"); open(report, "a").write(line + "\n"); print(line, flush=True)
    if args.earned or args.all:
        line = build_pieces(earned, "earned"); open(report, "a").write(line + "\n"); print(line, flush=True)


if __name__ == "__main__":
    main()

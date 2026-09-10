#!/usr/bin/env python3
"""Tap a control by its accessibility label instead of by a guessed coordinate.

    test/ios-poke.py <udid> tap "Start focus"
    test/ios-poke.py <udid> shot out.png
    test/ios-poke.py <udid> find focus          # list labels containing "focus"

Guessed tab-bar coordinates are how a sweep ends up screenshotting the wrong tab.
`idb ui describe-all` already knows where everything is; this reads it.
"""
import json
import subprocess
import sys
import time

TIMEOUT = 90


def run(args):
    return subprocess.run(args, capture_output=True, text=True, timeout=TIMEOUT)


def tree(udid):
    r = run(["idb", "ui", "describe-all", "--udid", udid])
    return json.loads(r.stdout) if r.stdout.strip() else []


def match(udid, needle):
    needle = needle.lower()
    out = []
    for e in tree(udid):
        label = (e.get("AXLabel") or "") + " " + (e.get("AXValue") or "")
        if needle in label.lower():
            f = e["frame"]
            out.append((e.get("AXLabel"), e.get("type"), f))
    return out


def main():
    udid, cmd = sys.argv[1], sys.argv[2]
    if cmd == "shot":
        run(["xcrun", "simctl", "io", udid, "screenshot", sys.argv[3]])
        return
    if cmd == "find":
        for label, kind, f in match(udid, sys.argv[3]):
            print(f"{kind:10} {round(f['x'])},{round(f['y'])} "
                  f"{round(f['width'])}x{round(f['height'])}  {label}")
        return
    if cmd == "tap":
        hits = match(udid, sys.argv[3])
        if not hits:
            print(f"no match for {sys.argv[3]!r}")
            sys.exit(1)
        # A button beats a label. "Clock out early" matches the sheet's own title
        # before it matches the button, and tapping a title does nothing at all.
        hits.sort(key=lambda h: 0 if h[1] in ("Button", "Cell") else 1)
        label, kind, f = hits[0]
        if kind not in ("Button", "Cell"):
            print(f"warning: {sys.argv[3]!r} is a {kind}, not a control")
        x = round(f["x"] + f["width"] / 2)
        y = round(f["y"] + f["height"] / 2)
        run(["idb", "ui", "tap", str(x), str(y), "--udid", udid])
        print(f"tapped {kind} {label!r} at {x},{y}")
        time.sleep(float(sys.argv[4]) if len(sys.argv) > 4 else 1.5)
        return
    print(__doc__)
    sys.exit(2)


if __name__ == "__main__":
    main()

"""Record the live tank as a GIF for sign-off (animations get a GIF, like faces).

    cd ~/Downloads/Sprout-handoff && npm run dev          # in one shell
    python3 design/tanks/capture_fx.py treasure orbit lagoon --out design/tanks/trial

Opens the Sprout build the way the iOS Home band does (`?embed=1&tank=<id>`, 402 x 336
points at 2x) and grabs frames for a few seconds, then writes `<id>-fx.gif`. Add
`--still` to record with Reduce Motion on, which is what a student with that setting
sees: everything drawn, nothing moving.

The page's clock is virtual: `requestAnimationFrame` and `performance.now` are
stubbed before load and stepped exactly 1/fps per frame, so the GIF plays in real
time no matter how slow the machine is while it records (the first take, on a
machine at load 300, captured five seconds of motion over three minutes and played
it back thirty times too fast).

Needs Playwright and the installed Chrome (the costume pipeline uses the same).
"""
from playwright.sync_api import sync_playwright
from PIL import Image
import argparse, io, os, time

ap = argparse.ArgumentParser()
ap.add_argument("tanks", nargs="+")
ap.add_argument("--url", default="http://localhost:5173")
ap.add_argument("--out", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "trial"))
ap.add_argument("--seconds", type=float, default=5.0)
ap.add_argument("--fps", type=int, default=12)
ap.add_argument("--still", action="store_true", help="record with Reduce Motion on")
ap.add_argument("--evo", default="2", help="stage to show, 1-3 (2 is the bare Sprout)")
args = ap.parse_args()
os.makedirs(args.out, exist_ok=True)

with sync_playwright() as p:
    browser = p.chromium.launch(channel="chrome")  # the installed Chrome, like capture_sprout.py
    for tank in args.tanks:
        page = browser.new_page(viewport={"width": 402, "height": 336}, device_scale_factor=2)
        page.add_init_script("""
            window.__vt = { now: 0, cbs: [] };
            performance.now = () => window.__vt.now;
            window.requestAnimationFrame = (cb) => { window.__vt.cbs.push(cb); return window.__vt.cbs.length; };
            window.cancelAnimationFrame = () => {};
            window.__step = (ms) => {
              window.__vt.now += ms;
              const cbs = window.__vt.cbs; window.__vt.cbs = [];
              for (const cb of cbs) cb(window.__vt.now);
            };
        """)
        page.goto(f"{args.url}/?embed=1&type=sprout&coat=mint&evo={args.evo}&radius=46.96&tank={tank}")
        page.wait_for_selector("#boot.hide", state="attached", timeout=20000)
        page.wait_for_timeout(600)
        if args.still:
            page.evaluate("window.RiverSprite.setReduceMotion(true)")
            page.wait_for_timeout(200)
        frames = []
        n = int(args.seconds * args.fps)
        t0 = time.time()
        # let the page settle a second of virtual time first (boot fade, first layout)
        for _ in range(10):
            page.evaluate("__step(100)")
        for i in range(n):
            page.evaluate(f"__step({1000 / args.fps:.2f})")
            frames.append(Image.open(io.BytesIO(page.screenshot(type="png"))).convert("RGB"))
        page.close()
        small = [f.resize((f.width // 2, f.height // 2), Image.LANCZOS).quantize(colors=128, method=Image.MEDIANCUT)
                 for f in frames]
        name = f"{tank}-fx{'-still' if args.still else ''}.gif"
        small[0].save(os.path.join(args.out, name), save_all=True, append_images=small[1:],
                      duration=int(1000 / args.fps), loop=0, optimize=True)
        frames[len(frames) // 2].save(os.path.join(args.out, f"{tank}-fx-frame.png"))
        print(f"wrote {name} ({len(frames)} frames, {time.time() - t0:.1f}s)")
    browser.close()

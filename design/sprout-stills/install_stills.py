"""Copy the captured stills into Assets.xcassets, one imageset per name.

`capture_sprout.py` writes `out/sprout-[look-]<coat>-<evo>@{1,2,3}x.png`. This puts
each trio in `ios/Resources/Assets.xcassets/<name>.imageset` with the Contents.json
Xcode expects, creating the folder if the look is new.
"""
import json, os, re, shutil, sys

HERE = os.path.dirname(os.path.abspath(__file__))
# Which staging folder to install. `out` is capture_sprout.py's; capture_costumes.py
# writes `out-costumes`.
OUT = os.path.join(HERE, sys.argv[1] if len(sys.argv) > 1 else "out")
ASSETS = os.path.join(HERE, "..", "..", "ios", "Resources", "Assets.xcassets")

names = sorted({re.sub(r"@\dx\.png$", "", f) for f in os.listdir(OUT) if f.endswith(".png")})
for name in names:
    folder = os.path.join(ASSETS, f"{name}.imageset")
    os.makedirs(folder, exist_ok=True)
    for scale in (1, 2, 3):
        shutil.copy(os.path.join(OUT, f"{name}@{scale}x.png"), folder)
    json.dump({"images": [{"filename": f"{name}@{s}x.png", "idiom": "universal",
                           "scale": f"{s}x"} for s in (1, 2, 3)],
               "info": {"author": "xcode", "version": 1}},
              open(os.path.join(folder, "Contents.json"), "w"), separators=(",", ":"))
print(f"installed {len(names)} imagesets")

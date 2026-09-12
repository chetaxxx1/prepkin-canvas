#!/usr/bin/env bash
# Rebuilds ios/Widget/WidgetAssets.xcassets from the app's own art.
#
# The Activity target's rule, one size up: the app catalogue is 38MB of lesson
# figures and reef sprites, and a widget has a 30MB memory ceiling, so the widget
# carries its own slim copy — every kin still cropped to the art and 300px wide
# (the small widget draws the fish 126pt wide; the art is flat colour and reads
# clean a little under 3x) and one tank plate, the lagoon, for the band behind
# the fish. A costume with no still here draws the plain coat instead; the
# widget checks for the image before it asks for it.
#
# Run it whenever the stills are recaptured (see SproutImage's header).
set -euo pipefail
cd "$(dirname "$0")/.."

SRC=Resources/Assets.xcassets
OUT=Widget/WidgetAssets.xcassets
WIDTH=300

rm -rf "$OUT"
mkdir -p "$OUT"
cat > "$OUT/Contents.json" <<'JSON'
{"info":{"author":"xcode","version":1}}
JSON

emit() {
  local name=$1 src=$2 width=$3
  mkdir -p "$OUT/$name.imageset"
  sips --resampleWidth "$width" "$src" --out "$OUT/$name.imageset/$name.png" >/dev/null
  cat > "$OUT/$name.imageset/Contents.json" <<JSON
{
  "images" : [ { "filename" : "$name.png", "idiom" : "universal", "scale" : "1x" },
               { "idiom" : "universal", "scale" : "2x" },
               { "idiom" : "universal", "scale" : "3x" } ],
  "info" : { "author" : "xcode", "version" : 1 }
}
JSON
}

# The kin stills are cropped to the art's own edges first. A stage-I fish is
# 57% of its square box and sits at the bottom of it; on Home that box is what
# `SproutImage.heightRatio` reserves, but a widget has no such budget, and a
# 126pt box holding a 70pt fish is the wrong fish. Here the box *is* the fish,
# so the size the widget asks for is the width the fish is drawn at.
count=0
for dir in "$SRC"/{sprout,axolotl,orca}-*.imageset; do
  name=$(basename "$dir" .imageset)
  src="$dir/$name@2x.png"
  [ -f "$src" ] || { echo "no @2x for $name, skipped"; continue; }
  mkdir -p "$OUT/$name.imageset"
  python3 - "$src" "$OUT/$name.imageset/$name.png" "$WIDTH" <<'PY'
import sys
from PIL import Image
src, out, width = sys.argv[1], sys.argv[2], int(sys.argv[3])
im = Image.open(src).convert("RGBA")
box = im.split()[3].getbbox() or (0, 0, im.width, im.height)
pad = 4
box = (max(0, box[0] - pad), max(0, box[1] - pad), min(im.width, box[2] + pad), min(im.height, box[3] + pad))
im = im.crop(box)
im = im.resize((width, round(im.height * width / im.width)), Image.LANCZOS)
im.save(out, optimize=True)
PY
  cat > "$OUT/$name.imageset/Contents.json" <<JSON
{
  "images" : [ { "filename" : "$name.png", "idiom" : "universal", "scale" : "1x" },
               { "idiom" : "universal", "scale" : "2x" },
               { "idiom" : "universal", "scale" : "3x" } ],
  "info" : { "author" : "xcode", "version" : 1 }
}
JSON
  count=$((count + 1))
done

# The one plate. 1440px wide in the app; 720 is plenty for a band 170pt wide.
emit "scene-lagoon" "$SRC/scene-lagoon.imageset/scene-lagoon.png" 720

echo "$count kin stills + 1 plate -> $OUT ($(du -sh "$OUT" | cut -f1))"

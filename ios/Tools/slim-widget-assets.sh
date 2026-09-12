#!/usr/bin/env bash
# Rebuilds ios/Widget/WidgetAssets.xcassets from the app's own art.
#
# The Activity target's rule, one size up: the app catalogue is 38MB of lesson
# figures and reef sprites, and a widget has a 30MB memory ceiling, so the widget
# carries its own slim copy — every kin still at 240px (the small widget draws the
# kin at about 80pt on a 3x screen) and one tank plate, the lagoon, for the band
# behind the fish. A costume with no still here draws the plain coat instead; the
# widget checks for the image before it asks for it.
#
# Run it whenever the stills are recaptured (see SproutImage's header).
set -euo pipefail
cd "$(dirname "$0")/.."

SRC=Resources/Assets.xcassets
OUT=Widget/WidgetAssets.xcassets
WIDTH=240

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

count=0
for dir in "$SRC"/{sprout,axolotl,orca}-*.imageset; do
  name=$(basename "$dir" .imageset)
  src="$dir/$name@2x.png"
  [ -f "$src" ] || { echo "no @2x for $name, skipped"; continue; }
  emit "$name" "$src" "$WIDTH"
  count=$((count + 1))
done

# The one plate. 1440px wide in the app; 720 is plenty for a band 170pt wide.
emit "scene-lagoon" "$SRC/scene-lagoon.imageset/scene-lagoon.png" 720

echo "$count kin stills + 1 plate -> $OUT ($(du -sh "$OUT" | cut -f1))"

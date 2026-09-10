#!/usr/bin/env bash
# Rebuilds ios/Activity/ActivityAssets.xcassets from the app's own kin stills.
#
# The app catalogue is 38MB — every lesson figure, every reef sprite. None of that
# belongs in an extension, and a Live Activity only ever draws one kin at about 46pt.
# So this takes the @2x still of each kin and scales it to 160px, which is more than
# a 46pt image needs on a 3x screen.
#
# Run it whenever the stills are recaptured (see SproutImage's header).
set -euo pipefail
cd "$(dirname "$0")/.."

SRC=Resources/Assets.xcassets
OUT=Activity/ActivityAssets.xcassets
WIDTH=160

rm -rf "$OUT"
mkdir -p "$OUT"
cat > "$OUT/Contents.json" <<'JSON'
{"info":{"author":"xcode","version":1}}
JSON

count=0
for dir in "$SRC"/{sprout,axolotl,orca}-*.imageset; do
  name=$(basename "$dir" .imageset)
  src="$dir/$name@2x.png"
  [ -f "$src" ] || { echo "no @2x for $name, skipped"; continue; }
  mkdir -p "$OUT/$name.imageset"
  sips --resampleWidth "$WIDTH" "$src" --out "$OUT/$name.imageset/$name.png" >/dev/null
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

echo "$count kin stills -> $OUT ($(du -sh "$OUT" | cut -f1))"

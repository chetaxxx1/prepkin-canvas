#!/usr/bin/env bash
# Packs the art Grok made into what the extension ships. Originals live in
# design/art-src/<theme>/{wallpaper,card-1..4}.png (never shipped); each becomes
# a WebP at the right size under extension/art/<theme>/, and art/manifest.js
# lists the themes with a complete set. Needs cwebp (brew install webp).
set -euo pipefail
cd "$(dirname "$0")/.."
SRC=design/art-src; OUT=extension/art
command -v cwebp >/dev/null || { echo "cwebp missing: brew install webp" >&2; exit 1; }
themes=()
for dir in "$SRC"/*/; do
  t="$(basename "$dir")"
  ok=1
  for name in wallpaper card-1 card-2 card-3 card-4; do
    src="$SRC/$t/$name.png"; [ -f "$src" ] || src="$SRC/$t/$name.jpg"
    if [ ! -f "$src" ]; then echo "  $t: missing $name" >&2; ok=0; continue; fi
    if [ "$name" = wallpaper ]; then w=1920; q=78; else w=1200; q=82; fi
    mkdir -p "$OUT/$t"
    cwebp -quiet -q "$q" -resize "$w" 0 "$src" -o "$OUT/$t/$name.webp"
  done
  [ "$ok" = 1 ] && themes+=("\"$t\"")
done
list=$(IFS=,; echo "${themes[*]:-}")
printf '// Which art folders exist, kept by bridge/art-pack.sh. An image theme whose\n// folder is not listed draws the placeholder set.\nconst ART_AVAILABLE = [%s];\nif (typeof module !== '"'"'undefined'"'"') module.exports = { ART_AVAILABLE };\n' "$list" > "$OUT/manifest.js"
echo "packed: ${list:-nothing}"; du -sh "$OUT" | cut -f1

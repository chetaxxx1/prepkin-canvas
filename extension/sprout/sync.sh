#!/bin/sh
# Copies the app's Sprout web build into the extension, so the buddy on Canvas
# is the same character, the same motion and the same costumes the phone
# draws. The source of truth is ios/SproutWeb (itself a copy of the Sprout
# repo's `npm run build`; see ios/Sources/SproutView.swift for that step).
#
#   extension/sprout/sync.sh
#
# Left out on purpose: tanks/ (12 MB of plates; the Canvas page is the scene),
# playground.png and sprout.png (the playground's own art). bridge.js is ours
# and is the one thing added to the page: a message listener, so the content
# script can ask for an emote across the frame boundary.
set -e
cd "$(dirname "$0")"
SRC=../../ios/SproutWeb
for d in assets layers costumes badges vfx; do
  rm -rf "$d"; cp -R "$SRC/$d" "$d"
done
cp "$SRC/favicon.svg" favicon.svg
# The build's page, plus our bridge, loaded after the module so RiverSprite exists.
sed 's|</body>|<script src="./bridge.js"></script></body>|' "$SRC/index.html" > index.html
grep -q 'bridge.js' index.html || { echo "bridge.js was not added" >&2; exit 1; }
du -sh . | sed 's/\t.*//; s/^/sprout: /'

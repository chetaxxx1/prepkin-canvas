#!/usr/bin/env bash
# The Plus screens, in one pass: the sheet for three reasons, the compare table,
# the already-Plus state, the gift-week timeline, the Focus chips, the Shop at
# seven slots, the Season card, and the calendar export.
#
#   test/plus-shots.sh [udid] [outdir]
#
# Needs idb. Coordinates are iPhone 17 Pro points (402 x 874). The tab bar centres
# are y=805: home 47, focus 107, learn 167, calendar 227, friends 287, kin 361.
set -euo pipefail
U="${1:-2A015A89-6DC3-4E91-9D3C-417F76DB523A}"
OUT="${2:-design/screenshots/plus-build-$(date +%Y-%m-%d)}"
mkdir -p "$OUT"

shot() { sleep 1.5; xcrun simctl io "$U" screenshot "$OUT/$1.png" >/dev/null 2>&1
         idb ui describe-all --udid "$U" > "$OUT/$1.json" 2>/dev/null || true; echo "  $1"; }
tap()  { idb ui tap "$1" "$2" --udid "$U"; sleep 0.6; }
# tapl <label>: tap the element whose label equals it, else the first that contains it.
tapl() { idb ui describe-all --udid "$U" 2>/dev/null | python3 -c "
import json,sys
ns=[n for n in json.load(sys.stdin) if n.get('AXLabel')]
hit=next((n for n in ns if n['AXLabel']=='$1'), None) or next((n for n in ns if '$1' in n['AXLabel']), None)
if hit: f=hit['frame']; print(int(f['x']+f['width']/2), int(f['y']+f['height']/2))" | { read x y; [ -n "${x:-}" ] && tap "$x" "$y" || echo "  no '$1' on screen"; }; }
tab()  { tap "$1" 805; }
swipe_down() { idb ui swipe 201 300 201 760 --udid "$U" >/dev/null 2>&1 || true; sleep 0.8; }

run() {
  local prefix="$1"
  # Focus: three chips; 60 and 90 sit behind More since 2026-09-12.
  tab 107; shot "$prefix-focus-chips"
  tapl "More lengths"; sleep 1; shot "$prefix-focus-more"
  # The sheet, reason .focus, from the 60 chip on More. More closes first, then
  # the Plus sheet opens, so give it a beat.
  tapl "60 minutes, in Plus"; sleep 1.5; shot "$prefix-sheet-focus"
  swipe_down
  # Shop, from Home's coin chip.
  tab 47; tap 326 81; shot "$prefix-shop"
  idb ui swipe 201 700 201 300 --udid "$U" >/dev/null 2>&1 || true; sleep 1
  shot "$prefix-shop-plusrow"
  tap 39 81
  # Kin: the season card and the saved-looks rail.
  tab 361
  idb ui swipe 201 700 201 260 --udid "$U" >/dev/null 2>&1 || true; sleep 1
  shot "$prefix-kin-season"
  # Calendar: the export menu.
  tab 227; tap 318 78; shot "$prefix-calendar-export"
  tap 201 700
}

xcrun simctl launch "$U" com.prepkin.canvas >/dev/null 2>&1 || true; sleep 2.5
xcrun simctl ui "$U" appearance light
echo "light"; run light
echo "ax-xl"; xcrun simctl ui "$U" content_size accessibility-extra-large; run axxl
xcrun simctl ui "$U" content_size medium
echo "shots in $OUT"

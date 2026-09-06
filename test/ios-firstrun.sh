#!/usr/bin/env bash
# First run, end to end, on the blank simulator: erase it, install the built app,
# name the kin, pick three, land on Home, check the first task, see the coin.
#
#   test/ios-firstrun.sh [app path]
#
# Uses prepkin-blank (0DC4140E…), never prepkin-fresh or prepkin-today. idb takes
# about a minute to answer a sim that just booted, so the first probe is patient.
set -uo pipefail
B=0DC4140E-0EE8-4B9D-A26A-99B3EA19763B
APP="${1:-$(ls -d ~/Library/Developer/Xcode/DerivedData/PrepkinCanvas-*/Build/Products/Debug-iphonesimulator/PrepkinCanvas.app | head -1)}"
OUT="${FLOW_OUT:-design/screenshots/firstrun-$(date +%Y-%m-%d)}"; mkdir -p "$OUT"
PASS=0; FAIL=0
labels() { idb ui describe-all --udid "$B" 2>/dev/null | python3 -c "import json,sys;print('\n'.join(str(n.get('AXLabel')) for n in json.load(sys.stdin)))"; }
tap()    { idb ui tap "$1" "$2" --udid "$B"; sleep "${3:-1.2}"; }
shot()   { xcrun simctl io "$B" screenshot "$OUT/$1.png" >/dev/null 2>&1; }
assert() { if labels | grep -q -- "$2"; then echo "  ok   $1"; PASS=$((PASS+1)); else echo "  FAIL $1: no '$2'"; shot "FAIL-$1"; FAIL=$((FAIL+1)); fi; }

xcrun simctl shutdown "$B" >/dev/null 2>&1; xcrun simctl erase "$B" && xcrun simctl boot "$B" && sleep 15
xcrun simctl install "$B" "$APP" && xcrun simctl launch "$B" com.prepkin.canvas >/dev/null && sleep 6
for i in 1 2 3 4 5 6; do labels | grep -q "Shuffle" && break; sleep 10; done   # idb companion warming up
shot 01-name;      assert name-screen "Shuffle"
tap 112 515;       tap 290 515 1.5
shot 02-pick;      assert pick-three "Continue"
tap 201 358; tap 201 444; tap 201 530
tap 201 798 3;     shot 03-home
assert home "goals left today"
assert first-kin-named "coins. Open the shop."
tap 358 485 2.5;   shot 04-first-check
assert first-coin "20 coins. Open the shop."
assert day1-offer "Not now"
xcrun simctl shutdown "$B" >/dev/null 2>&1
echo "passed $PASS · failed $FAIL · shots in $OUT"; [ "$FAIL" -eq 0 ]

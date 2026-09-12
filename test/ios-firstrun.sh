#!/usr/bin/env bash
# First run, end to end, on a blank simulator: erase it, install the built app,
# and walk welcome → school → plate → coat → name → picks → result → Home →
# first coin → both Day 1 cards, asserting each step and shooting every screen.
#
#   test/ios-firstrun.sh [app path]
#
#   SCHOOL=highSchool|college|gradSchool   which school card to tap (default college)
#   PLATE="Big exams coming"               which plate rows to tick (default focus)
#   FLOW_OUT=dir                           where the screenshots go
#
# Uses a simulator called prepkin-firstrun (created if missing), never
# prepkin-fresh or prepkin-today. idb takes about a minute to answer a sim that
# just booted, so the first probe is patient. Do not launch with -unlockAll: it
# marks the first run done and the flow never shows.
set -uo pipefail
NAME=prepkin-firstrun
B=$(xcrun simctl list devices | grep "$NAME (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')
if [ -z "$B" ]; then
  B=$(xcrun simctl create "$NAME" "iPhone 17 Pro" "$(xcrun simctl list runtimes | grep -o 'com.apple.CoreSimulator.SimRuntime.iOS-[0-9-]*' | tail -1)")
fi
APP="${1:-$(ls -d /tmp/prepkin-firstrun-dd/Build/Products/Debug-iphonesimulator/PrepkinCanvas.app ~/Library/Developer/Xcode/DerivedData/PrepkinCanvas-*/Build/Products/Debug-iphonesimulator/PrepkinCanvas.app 2>/dev/null | head -1)}"
OUT="${FLOW_OUT:-design/screenshots/firstrun-$(date +%Y-%m-%d)}"; mkdir -p "$OUT"
SCHOOL="${SCHOOL:-college}"
PLATE="${PLATE:-Staying focused}"
PASS=0; FAIL=0

tree()   { idb ui describe-all --udid "$B" 2>/dev/null; }
labels() { tree | python3 -c "import json,sys;print('\n'.join(str(n.get('AXLabel')) for n in json.load(sys.stdin)))"; }
tap()    { idb ui tap "$1" "$2" --udid "$B"; sleep "${3:-1.2}"; }
shot()   { xcrun simctl io "$B" screenshot "$OUT/$1.png" >/dev/null 2>&1; }
assert() { if labels | grep -q -- "$2"; then echo "  ok   $1"; PASS=$((PASS+1)); else echo "  FAIL $1: no '$2'"; shot "FAIL-$1"; FAIL=$((FAIL+1)); fi; }
refute() { if labels | grep -q -- "$2"; then echo "  FAIL $1: '$2' still on screen"; shot "FAIL-$1"; FAIL=$((FAIL+1)); else echo "  ok   $1"; PASS=$((PASS+1)); fi; }
# tapl <label> [pause]: tap the element whose label equals it, else the first that contains it
# The label rides in an env var, not in the Python source: "Let's go" has a quote.
tapl()   { tree | LBL="$1" python3 -c "
import json,sys,os
l=os.environ['LBL']
ns=[n for n in json.load(sys.stdin) if n.get('AXLabel')]
hit=next((n for n in ns if n['AXLabel']==l), None) or next((n for n in ns if l in n['AXLabel']), None)
if hit: f=hit['frame']; print(int(f['x']+f['width']/2), int(f['y']+f['height']/2))" | { read x y; [ -n "${x:-}" ] && tap "$x" "$y" "${2:-1.2}" || { echo "  FAIL tap '$1': not found"; shot "FAIL-tap"; FAIL=$((FAIL+1)); }; }; }
# wait_for <label> [tries]: polls until the label is on screen (an animation may still be running)
wait_for() { for _ in $(seq 1 "${2:-8}"); do labels | grep -q -- "$1" && return 0; sleep 1; done; return 1; }

# LEAD is the level's first study preset (on the pick screen); HOME_ROW is the
# first suggested pick for that level + plate, which is the row Home leads with
# and the one the first coin comes from (`FirstRun.suggestedPicks`).
case "$SCHOOL" in
  highSchool) SCHOOL_LABEL="High school"; LEAD="Read the chapter"; HOME_ROW="${HOME_ROW:-Study for the quiz}" ;;
  gradSchool) SCHOOL_LABEL="Grad school"; LEAD="Write for 25 minutes"; HOME_ROW="${HOME_ROW:-Write for 25 minutes}" ;;
  *)          SCHOOL_LABEL="College";     LEAD="Read for one class"; HOME_ROW="${HOME_ROW:-20 min study session}" ;;
esac

xcrun simctl shutdown "$B" >/dev/null 2>&1; xcrun simctl erase "$B" && xcrun simctl boot "$B" && sleep 15
xcrun simctl install "$B" "$APP" && xcrun simctl launch "$B" com.prepkin.canvas >/dev/null && sleep 6
for i in 1 2 3 4 5 6; do labels | grep -q "Meet your fish" && break; sleep 10; done   # idb companion warming up

# 1 · Welcome (Finch d57f16e6)
shot 01-welcome;        assert welcome "Meet your fish"
assert welcome-invite "Have a friend code?"
assert welcome-legal "Privacy Policy"
tapl "Meet your fish" 1.5

# 2 · Where are you in school? (Duolingo ce101753)
shot 02-school;         assert school "Where are you in school?"
assert school-cards "Grad school"
assert school-skip "Skip"
assert school-back "Back"
tapl "$SCHOOL_LABEL";   tapl "Continue" 1.5

# 3 · What's on your plate? (Headspace 6aba84cc)
shot 03-plate;          assert plate "What's on your plate?"
tapl "$PLATE";          shot 03b-plate-ticked
tapl "Continue" 1.5

# 4 · Pick your coat (Finch 9a45c4b2)
shot 04-coat;           assert coat "Pick your coat"
assert coat-lilac "Lilac coat"
tapl "Coral coat";      shot 04b-coat-picked
tapl "Meet" 3.2         # the reveal: swim in, wave, field rises

# 5 · Name (Finch 0b3973cb)
wait_for "Shuffle" 20;  shot 05-name;           assert name "Shuffle"
tapl "Shuffle" 1;       tapl "Next" 1.5

# 6 · Pick three for today (Finch 75c0006a): three arrive ticked, Continue live
shot 06-picks;          assert picks "Pick three for today"
assert picks-level "$LEAD"
assert picks-suggested "3 of 3 picked"
tapl "Continue" 1.8

# 7 · Your day is set (Headspace 71a1f085)
shot 07-result;         assert result "Your day is set."
assert result-line "gets paid."
tapl "Let's go" 3

# 8 · Home: the outcome. The bubble waits for the Canvas check, so poll for it.
wait_for "Tap one when it's done." 12
shot 08-home;           assert home "goals left today"
assert home-bubble "Tap one when it's done."
assert home-level "$HOME_ROW"

# 9 · The first coin, then the Day 1 cards in the plate's order
tapl "$HOME_ROW" 2.5;   shot 09-first-check
assert first-coin "20 coins. Open the shop."
wait_for "Not now" 6;   assert day1-card "Not now"
if labels | grep -q "Your Canvas homework can live here."; then
  shot 10-day1-canvas;  assert day1-canvas-first "Send the link to my laptop"
  refute day1-canvas-no-laptop-excuse "Takes a laptop"
  tapl "Not now" 1.5;   shot 11-day1-checkin
  assert day1-checkin-second "check in tomorrow evening"
else
  shot 10-day1-checkin; assert day1-checkin-first "check in tomorrow evening"
  tapl "Not now" 1.5;   shot 11-day1-canvas
  assert day1-canvas-second "Your Canvas homework can live here."
  assert day1-canvas-share "Send the link to my laptop"
  refute day1-canvas-no-laptop-excuse "Takes a laptop"
fi
tapl "Not now" 1.5;     shot 12-home-settled
refute day1-over "Not now"

xcrun simctl shutdown "$B" >/dev/null 2>&1
echo "passed $PASS · failed $FAIL · shots in $OUT"; [ "$FAIL" -eq 0 ]

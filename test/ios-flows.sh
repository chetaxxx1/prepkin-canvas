#!/usr/bin/env bash
# Scripted end-to-end flows on the iPhone simulator. Each flow drives the app with
# idb, then asserts on the accessibility tree, so a broken flow fails loudly.
#
#   test/ios-flows.sh [udid] [flow ...]      flows: focus lesson shop shophold shopshort yourday task pod all
#
# Defaults to prepkin-fresh. Never point this at prepkin-today. Coordinates are
# iPhone 17 Pro points; see .claude/skills/ios-walkthrough/SKILL.md.
set -uo pipefail
U="${1:-5982E2BF-C16C-4243-B049-26D1FA73FC07}"; shift || true
FLOWS="${*:-all}"; [ "$FLOWS" = all ] && FLOWS="focus lesson shop shophold shopshort yourday task pod"
OUT="${FLOW_OUT:-design/screenshots/flows-$(date +%Y-%m-%d)}"; mkdir -p "$OUT"
PASS=0; FAIL=0

tree()   { idb ui describe-all --udid "$U" 2>/dev/null; }
labels() { tree | python3 -c "import json,sys;print('\n'.join(str(n.get('AXLabel')) for n in json.load(sys.stdin)))"; }
tap()    { idb ui tap "$1" "$2" --udid "$U"; sleep "${3:-1.2}"; }
shot()   { xcrun simctl io "$U" screenshot "$OUT/$1.png" >/dev/null 2>&1; }
# assert <flow> <step> <label substring>
assert() { if labels | grep -q -- "$3"; then echo "  ok   $2"; PASS=$((PASS+1)); else echo "  FAIL $2: no '$3' on screen"; shot "FAIL-$1-$2"; FAIL=$((FAIL+1)); fi; }
# refute <flow> <step> <label substring>: passes when the label is NOT on screen
refute() { if labels | grep -q -- "$3"; then echo "  FAIL $2: '$3' still on screen"; shot "FAIL-$1-$2"; FAIL=$((FAIL+1)); else echo "  ok   $2"; PASS=$((PASS+1)); fi; }
# tapl <label substring>: tap the centre of the first element with that label
# tapl <label>: tap the element whose label equals it, else the first that contains it
tapl()   { tree | python3 -c "
import json,sys
ns=[n for n in json.load(sys.stdin) if n.get('AXLabel')]
hit=next((n for n in ns if n['AXLabel']=='$1'), None) or next((n for n in ns if '$1' in n['AXLabel']), None)
if hit: f=hit['frame']; print(int(f['x']+f['width']/2), int(f['y']+f['height']/2))" | { read x y; [ -n "${x:-}" ] && tap "$x" "$y" "${2:-1.2}" || { echo "  FAIL tap '$1': not found"; FAIL=$((FAIL+1)); }; }; }
# tapr <label>: like tapl, but 30pt in from the element's right edge (a row's check box)
tapr()   { tree | python3 -c "
import json,sys
ns=[n for n in json.load(sys.stdin) if n.get('AXLabel')]
hit=next((n for n in ns if n['AXLabel']=='$1'), None) or next((n for n in ns if '$1' in n['AXLabel']), None)
if hit: f=hit['frame']; print(int(f['x']+f['width']-30), int(f['y']+f['height']/2))" | { read x y; [ -n "${x:-}" ] && tap "$x" "$y" "${2:-1.2}" || { echo "  FAIL tap '$1': not found"; FAIL=$((FAIL+1)); }; }; }
# Every flow starts from a fresh launch on Home, so a sheet or deck left open by
# a failed step cannot take the next flow down with it.
home() { xcrun simctl terminate "$U" com.prepkin.canvas >/dev/null 2>&1
         xcrun simctl launch "$U" com.prepkin.canvas >/dev/null 2>&1; sleep 2.5; tap 43 812 0.8; }

flow_focus() {
  echo "focus"; tap 122 812
  assert focus ready "Start focus"
  tapl "Start focus" 2;         assert focus running "Pause"; shot focus-running
  tapl "Pause";                 assert focus paused "Resume"
  tapl "Resume";                assert focus resumed "Pause"
  tapl "Clock out early";       assert focus quit-sheet "Keep working"; shot focus-quit
  tapl "Keep working";          assert focus kept "Pause"
  tapl "Clock out early"; tapl "no pay yet"; assert focus back-to-ready "Start focus"
}
flow_lesson() {
  echo "lesson"; tap 201 812
  assert lesson learn-root "Saved cards"
  # The first card is a lesson (opens a preview with Start) or, after a half-read
  # lesson, a resume card that opens the deck directly. Both are fine.
  tap 201 275 1.5
  if labels | grep -q "^Start$"; then
    echo "  ok   preview"; PASS=$((PASS+1)); shot lesson-preview
    tapl "Start" 2
  fi
  assert lesson deck "Card "; shot lesson-card1
  labels | grep -q "Got it" && tapl "Got it"
  n=$(labels | grep -o "Card [0-9]* of [0-9]*" | head -1 | awk '{print $2}')
  total=$(labels | grep -o "Card [0-9]* of [0-9]*" | head -1 | awk '{print $4}')
  if [ "$n" -ge "$((total-1))" ]; then
    # Resumed on the last cards, where the check card owns its taps. Restart the deck.
    tap 60 300; tap 60 300; n=$(labels | grep -o "Card [0-9]* of" | head -1 | grep -o "[0-9]*")
  fi
  tap 201 300;                  assert lesson picture-turns-card "Card $((n+1)) of"   # the figure band must advance
  tap 60 300;                   assert lesson back "Card $n of"
  tapl "Close";                 assert lesson closed "Saved cards"
}
flow_shop() {
  echo "shop"; home; tap 326 81
  assert shop open "Reroll picks"; shot shop
  assert shop legend "Collection"
  tapl "Close";                 assert shop closed "goals left today"
}
flow_shophold() {
  echo "shophold"; home; tap 326 81
  # Pick slots are tap targets, not buttons, so they are addressed by position:
  # the row sits between the −20% strips (y 157) and the "to go" pills (y 258).
  # A hold persists in the save, so the flow is relative to whatever it finds:
  # each long-press must flip the HELD strip, whichever way it starts.
  if labels | grep -q "HELD"; then was=held; else was=free; fi
  idb ui tap 56 205 --duration 0.8 --udid "$U"; sleep 1.6
  if [ "$was" = free ]; then assert shophold held "HELD"; shot shop-held; else refute shophold released "HELD"; fi
  idb ui tap 56 205 --duration 0.8 --udid "$U"; sleep 1.6
  if [ "$was" = free ]; then refute shophold released "HELD"; else assert shophold held-again "HELD"; shot shop-held; fi
  tapl "Close"
}
flow_shopshort() {
  echo "shopshort"; home; tap 326 81
  # A slot the student cannot afford: its "to go" pill is on screen. Tap it; the
  # toast must say so instead of failing silently (the 4 Sept finding).
  labels | grep -q "to go" || { echo "  skip: every pick is affordable on this save"; tapl "Close"; return; }
  # Tap the slot above the first "to go" pill (the slot itself is not a button).
  x=$(tree | python3 -c "
import json,sys
for n in json.load(sys.stdin):
    if n.get('AXLabel') and 'to go' in n['AXLabel']: f=n['frame']; print(int(f['x']+f['width']/2)); break")
  tap "$x" 205 0.6;             assert shopshort toast "to go. Nothing here expires."
  sleep 1.5; tapl "Close"
}
flow_pod() {
  echo "pod"; tap 280 812
  if labels | grep -q "Join a pod"; then
    tapl "Join a pod" 4
    if labels | grep -q "No pod yet\|Looking for a pod"; then echo "  ok   honest-state"; PASS=$((PASS+1)); shot pod-joined; else echo "  FAIL join: no honest state on screen"; shot FAIL-pod-join; FAIL=$((FAIL+1)); fi
    tapl "Leave the pod" 1.5
    labels | grep -q "^Leave$" && tapl "Leave" 3
    assert pod left "Join a pod"
  else
    echo "  skip: already in a pod on this save"
  fi
}
flow_yourday() {
  echo "yourday"; home; tapl "Edit your day"
  assert yourday open "Done"; shot yourday
  assert yourday no-banned-word-bridge "Canvas"
  if labels | grep -qi "bridge"; then echo "  FAIL banned word 'bridge' on screen"; FAIL=$((FAIL+1)); else echo "  ok   no banned words"; PASS=$((PASS+1)); fi
  tapl "Done";                  assert yourday closed "goals left today"
}
flow_task() {
  echo "task"; home
  before=$(labels | grep -o "[0-9]* coins" | head -1)
  # A hand-checkable row: Canvas rows ("due …") are paid by Canvas, never by a tap.
  first=$(labels | grep "Study, \|Life, " | head -1 | cut -c1-30)
  # Hand-checkable rows sit under the Canvas rows, below the fold: scroll them up.
  idb ui swipe 200 750 200 150 --duration 0.5 --udid "$U"; sleep 0.8
  idb ui swipe 200 750 200 150 --duration 0.5 --udid "$U"; sleep 1
  tapr "$first" 2;              shot task-checked   # the check box sits at the row's right edge
  after=$(labels | grep -o "[0-9]* coins" | head -1)
  if [ "$before" != "$after" ]; then echo "  ok   check pays ($before -> $after)"; PASS=$((PASS+1)); else echo "  FAIL check did not change coins ($before)"; FAIL=$((FAIL+1)); fi
  tapr "$first" 2
  undone=$(labels | grep -o "[0-9]* coins" | head -1)
  if [ "$before" = "$undone" ]; then echo "  ok   undo refunds ($undone)"; PASS=$((PASS+1)); else echo "  FAIL undo left $undone, expected $before"; FAIL=$((FAIL+1)); fi
}

home
for f in $FLOWS; do "flow_$f"; done
echo "passed $PASS · failed $FAIL · shots in $OUT"; [ "$FAIL" -eq 0 ]

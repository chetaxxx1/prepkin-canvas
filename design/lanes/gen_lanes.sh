#!/bin/bash
# Lane concept art round 2: Sail (manta) x3, orca x2, axolotl x2. Style locked to the Sprout still.
set -e
PY=~/.claude/skills/nano-banana/.venv/bin/python
GEN=~/.claude/skills/nano-banana/scripts/genimage.py
S="/private/tmp/claude-501/-Users-georgeshi-Desktop-app-prepkin-canvas/4a1ab280-f061-4265-84b5-2bcf38bb8d53/scratchpad"
OUT="$S/lanes2"; mkdir -p "$OUT"
STILL=/Users/georgeshi/Desktop/app/prepkin-canvas/design/sprout-stills/out/sprout-mint-2@3x.png
AX="$S/lane-axolotl.png"
STYLE="Flat vector illustration in the exact style of the first attached mascot: one smooth silhouette, no outlines, matte soft colors, simple black dot eyes, a tiny simple mouth, front facing, centered, filling about 70 percent of the frame, plain flat background color #F6F4EE, no text, no shadow, no extra objects. A water animal chibi companion for a study app aimed at 18 to 22 year olds: cute, but calm and a little cool, never babyish."

gen() { local name=$1 prompt=$2; shift 2; "$PY" "$GEN" --prompt "$prompt $STYLE" --aspect-ratio 1:1 --output "$OUT/$name.png" --images "$STILL" "$@" 2>&1 | tail -1; }

gen sail-a "A chibi manta ray: a wide soft diamond body with long graceful wings that sweep out and curve slightly up at the tips, a pale belly, two small rounded cephalic fins at the front of the head, a short tapered tail, sky blue #6BAFE0 with belly #D4EBF8, eyes set wide on the top of the head, small calm smile. Elegant and gliding."
gen sail-b "A chibi manta ray: a wide soft diamond body with long graceful wings that sweep out and curve slightly up at the tips, a pale belly, two small rounded cephalic fins at the front of the head, a short tapered tail, deep ocean blue-grey #4A6A8A with belly #DCE8F2, relaxed half-open eyes, flat calm mouth. Cool and unbothered, the confident one."
gen sail-c "A chibi manta ray seen slightly from above: broad rounded wings like a soft cape, small eyes close together on the head, tiny smile, two small cephalic fins, short tail, teal blue #5EA8C8 with belly #D8EFF5, faint pale spots on the back. Playful and sleek."
gen orca-a "A chibi orca: glossy black body #1F2A33 with a white belly and white oval eye patches, half-lidded deadpan eyes, a flat unimpressed mouth, one small curved dorsal fin, stubby flipper arms, small tail flukes tucked behind. The one that is too cool for this."
gen orca-b "A chibi orca: black body #1F2A33 with a white belly and white eye patches, calm slightly lowered eyes, the smallest confident smirk, one small curved dorsal fin, stubby flipper arms. Quietly amused, not grumpy."
gen axo-a "A chibi axolotl like the second attached image but cleaner: dusty lilac body #9C8DB8, three feathery gill fronds each side of the head in pale pink, small calm dot eyes, a tiny flat mouth, stubby arms, pale belly. Keep it unbothered and soft." "$AX"
gen axo-b "A chibi axolotl like the second attached image: dusty rose-pink body #D9A0A8 with pale peach belly, three feathery gill fronds each side in deeper pink, small calm dot eyes, the tiniest gentle smile, stubby arms. Warm and sleepy." "$AX"
echo done

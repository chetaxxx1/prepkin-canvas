# Brief: moves and ults for the five new legendary costumes

Paste everything below this line into a fresh Claude Code session opened at
`~/Desktop/app/prepkin-canvas`.

---

Five new legendary Sprout costumes were built today (2026-09-11) and are in the iOS Wardrobe:
**Champ** (boxer), **Headliner** (DJ), **Netrunner** (cyberpunk), **Count** (vampire), **Abyss**
(anglerfish). They exist but they cannot move yet: each has five placeholder signatures that
are plain base emotes and no ult. Your job is the owed slice: **five keyframed acts plus one
ult per costume**, the way the Ninja, Sorcerer, Grad and Hex already have them. Nothing else.

## Where things are

- Sprout rig repo: `~/Downloads/Sprout-handoff` (Vite + TypeScript). Costumes are in
  `src/costumes.ts`, signatures in `src/signatures.ts`, acts in `src/acts.ts`, effects in
  `public/vfx/*.json`. The tree is DIRTY with uncommitted work from today (mine and another
  session's). Do not commit, do not reset, do not reformat. Touch only `src/acts.ts`,
  `src/signatures.ts`, and new effect files.
- App repo: `~/Desktop/app/prepkin-canvas`. Effect generator `design/vfx/gen_effects.py`
  (+ `lottie.py` helpers), capture tool `design/vfx/capture_act.py`, output `design/vfx/out/`.
- Read the header comment of `src/acts.ts` first: it is the authoring contract (channels,
  eases, cues, `mirror`, the hat rule). Then read one finished set end to end, `ninja*` in
  `acts.ts` plus its `SIGNATURES.ninja` and `ULTS.ninja` entries, and copy that shape.
- Design page for the five (what each move and ult should look like):
  https://claude.ai/code/artifact/beb0999b-27a6-4f24-9307-9d2716ddd164 — durable copy at
  `design/lanes/costumes/legendary/page/legendary-round-two.html`. Built stills:
  `design/lanes/costumes/legendary/built.png`.
- Memory notes in this project cover the build: `legendary-round-two`, `costume-acts`,
  `hats-sit-flush`, `sprout-rim-is-8`.

## What each costume has on the rig (so an act can use it)

Head slots carry class `.hat`, which is what `hatY` / `hatRot` move. Held props live in the
arm groups and swing with the arm; `swing` rotates them from the shoulder.

| id | head slot (`.hat`) | face slot | back slot | held | notes |
|---|---|---|---|---|---|
| `champ` | none | none | none | none | gloves ARE the fins (red, white tape at the root); robe hangs open, belt on the bare belly; tuft shows |
| `headliner` | chrome headphones, magenta lit rings | none | none | none | cropped holographic bomber, black tee; tuft shows |
| `netrunner` | none | translucent HUD visor over the eyes (eyes and every mouth show through) | none | none | chrome cyber arm is the LEFT fin only |
| `count` | none | two fangs under the smile | tall collar + full cape (`#costume-back`, behind the whole body) | bat perched on the RIGHT fin tip | the back slot has no channel of its own; it rides the body |
| `abyss` | anglerfish head hood: needle teeth over the brow, tiny eyes, lure off the snout (`HIDES_TUFT`) | none | none | fin frills (both arms, unclipped) | four small lower teeth sit on the chin |

## The moves (names are final; the description is the brief)

Replace the five placeholder entries in `SIGNATURES.<id>` with `act:` ids and add an
`ULTS.<id>` entry. Keep the names.

**Champ** — "Undefeated. Ask anyone."
1. Jab: two fast straight punches with the left fin, a little forward lean each time.
2. Guard up: both fins come up in front of the face, small bob, eyes narrow.
3. Ring walk: slow side-to-side strut, chin up, a `spotlights` beam behind him.
4. Shadowbox: a quick flurry of alternating fin swings with `speed-lines`.
5. Bell: one big hop, both fins up, `confetti`.
Ult **Knockout**: a flurry, then one huge hook (big `rot` + forward `x`), the whole view
shakes (short alternating `x` keys), `flash` 3, a `shockwave`, then bell + `confetti`.

**Headliner** — "Never leaves before the drop."
1. Cue: one fin to the ear cup, head tilt, hold.
2. Hands up: both fins straight up, slow sway, `notes`.
3. Scratch: fast small back-and-forth with one fin, body bob on the beat.
4. Crowd point: point out at the glass, wink.
5. Fader: one fin slides across in front of the belly, slow.
Ult **The Drop**: `dim` the tank, four bars of build where each bounce is bigger than the last
(`y` and `squash` growing), then `flash` 2 with two `spotlights` sweeping and `shockwave`
rings on every beat for two seconds. Generate a magenta charge (`charge-pink` exists).

**Netrunner** — "Already patched it."
1. Boot: the visor flickers (use `flash` 0.3 pulses, eyes closed then open), a small startle.
2. Jack in: the chrome arm reaches forward and holds, body leans in, `sparks` at the fin tip.
3. Glitch step: three short sideways teleports (`jump` cues with `alpha` 0 → 1 and a
   `squash` snap), `speed-lines`.
4. Scan: slow head turn left then right with the eyes narrowed, `lightning` tiny.
5. Reboot: sinks a little, `alpha` dips to 0.4, snaps back with a `sparkle-burst`.
Ult **Overclock**: `dim` to near black, he splits into a cyan and a magenta ghost (two extra
effects offset by ±0.3 radii; generate `ghost-cyan.json` and `ghost-magenta.json` as tinted
Sprout-sized discs), dashes the width of the tank three times (`to:` cues, `home: true`),
a `lightning` data burst, resolves to one with `flash` 2.

**Count** — "Up all night anyway."
1. Cape sweep: a wide slow turn with both fins spread, small rise, `bats` behind.
2. Fangs: the smile opens, eyes narrow, a tiny lean toward the glass.
3. Hiss: a sharp forward jolt with the open mouth, `roar-lines`.
4. Hover: rises slowly (`y` −40px over 1.5 s) and holds, arms slightly out, gentle bob.
5. Mist: fades to `alpha` 0.15 and drifts sideways, fades back in on the other side.
Ult **Nightfall**: `dim` with a crimson `dimColor`, `bat-swarm` at his position as he goes to
`alpha` 0, the swarm circles (two more `bat-swarm` cues on a wide `to:` path), he reappears
with a `scale` snap and both fins flared, `flash` 1.

**Abyss** — "Lives where the light doesn't."
1. Lure bob: slow rhythmic head nod so the lure bobs (this is body `rot`, NOT `hatRot`).
2. Lights on: the dots pulse — three quick `flash` 0.25 pulses with a small squash each.
3. Lurk: sinks 30px, eyes half-lidded, holds still for two seconds, one slow blink.
4. Gulp: a big open-mouth squash-and-stretch, `bubbles` (make a `bubbles.json` if
   `brew-bubbles` reads too green).
5. Drift: a slow figure-eight glide, arms trailing.
Ult **Lights Out**: `dim` to black over 0.6 s, everything but the lure's glow gone (`alpha`
0.08 on him; the glow is part of the hood so it fades too — instead put a teal `lantern`
effect at the lure's position, fxDy about −1.6 radii), a slow drift, then every dot flashes at
once (`flash` 2.5) and a `shockwave` in teal rolls out to the glass (tint `shockwave` or
generate `shockwave-teal.json`).

## Rules that are not negotiable

- **Hats sit flush.** Never key `hatY`/`hatRot` for a bow, nod, sway or lean; the body `rot`
  carries the hat. Those channels are only for a piece that deliberately leaves the head.
  For these five that means: nothing. The Headliner's headphones and the Abyss hood stay put.
- **Read the scale track on every hidden/shown beat.** The ninja ult once shipped tiny
  because `scale` stayed at 0.2 through the reappearances. The contact sheet is the check.
- One direction only: anything one-sided goes in `mirror`, so it leans the right way on
  either side of the tank.
- Effects run on the page clock; generate new ones with `gen_effects.py` (radial gradients
  and shapes only — no layer effects, so lottie-web and Creator render the same). Reuse the
  47 files in `public/vfx/` where one fits before making a new one.
- The white outline is 8 units everywhere. Do not touch rim strokes, filters or `OVERSIZE`.

## How to check and hand over

1. `npm run build` in the Sprout repo after every change; `npx tsc --noEmit -p .` must be
   clean (`SIGNATURES` is a full `Record<CostumeId, …>`, so a missing id fails the build).
2. Add the five to `SETS["legendary"]` in `design/vfx/capture_act.py` (coats: champ coral,
   headliner sky, netrunner butter, count lilac, abyss mint), then
   `python3 design/vfx/capture_act.py --set legendary` writes a GIF and a contact sheet per
   move to `design/vfx/out/`. Read every sheet yourself before showing anything.
3. Put the GIFs on one page (small, 0.42 scale — 30 acts at full size passes the artifact's
   16 MB limit) and get George's sign-off. **Nothing ships before the GIF sign-off.**
4. After sign-off: `rsync -a dist/ ~/Desktop/app/prepkin-canvas/ios/SproutWeb/` and delete
   the old hashed `index-*.js` / `index-*.css` in `ios/SproutWeb/assets` by hand (no
   `--delete`; `SproutWeb/skins` is an empty folder the repo keeps). Do not commit.
5. Report in under 100 words: what moves, what you could not do, and the sheet link.

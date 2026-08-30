# Rive rig setup — Prepkin slime (hybrid plan, 2026-08-30)

Decision: limb/acting animations (wave, slump, future emotes) move to a Rive rig;
the shipped code animations in `SlimeView.swift` (idle, bounce, dance, peek,
celebrate, startle) stay as-is. George animates in the Rive editor; the app
flips state-machine inputs.

## Files here

- `slime-layers.svg` — import THIS into Rive. Exact traced geometry from the
  approved renders, split into rig-ready layers. Limb layers sit BEHIND the
  body and their roots extend inside it, so they can rotate without seams.
- `slime-layers-debug.svg` — same file with limbs tinted + body translucent,
  to see the layer split.
- `gen_layers.py` — regenerates both from `ios/Sources/SlimeView.swift`
  (run it again if the traced art ever changes).

## Layers in the SVG (bottom → top)

| id | what | note |
|---|---|---|
| `antenna` | droplet antenna, root buried in the dome | bone chain: 2 bones from base → tip |
| `armLeft` | left mitten, root buried in the flank | 1 bone, pivot at the root |
| `armRight` | right mitten, root buried | 1 bone, pivot ≈ (770, 517) px |
| `body` | dome with arms+antenna spliced out | bind to a mesh for squash/stretch |
| `belly` | mint belly patch | parent to body |
| `face-idle` … `face-wink` | all 9 approved faces, stacked in place | only `face-idle` visible in the SVG; keep them as a "faces" group and toggle visibility per state |

Canvas is 886×795 (the reference render size). Palette is exact: body
`#51CFA0`, belly `#B1EDD4`, ink `#101820` — do not let Rive re-quantize it.

## Editor checklist

1. New file → Import `slime-layers.svg`.
2. Root bone at bottom-center (443, 795); child bones: body, antenna chain,
   both arms at their roots.
3. Bind `body` to a mesh (weights heavier at the top) so squash-and-stretch
   bows the dome, not just scales it.
4. Animations to author first: `wave` (arm raises + waves, wink face —
   reference clip: `~/Downloads/Green_slime_character_waving_hello_202608300339.mp4`)
   and `slump` (sag + antenna wilt + sad face, per the Flow slump clip).
5. State machine named `SlimeMachine`, inputs:
   - `trigger wave`, `trigger slump` (more later as they migrate)
   - `number face` (0–8, same order as the SVG face layers)
6. Export → `Slime.riv`.

## App side (already planned, waiting on the .riv)

- Add SPM package `https://github.com/rive-app/rive-ios` (RiveRuntime) in
  `ios/project.yml`.
- `RiveSlimeView` wraps `Slime.riv`; `SlimeView` routes `.wave`/`.slump`
  to it and keeps drawing everything else itself. Recolors: bind the body
  fill to a color input (ember/droplet/sprout use the same 57% belly blend).

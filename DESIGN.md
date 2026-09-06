# Prepkin Canvas, extension surfaces: design system

Three surfaces. The **Canvas page** (skin.css) is the school's: papers, no
decoration, rules in design/canvas-skin/SPEC-RECEIPT.md. The **popup** and the
**buddy panel** are Prepkin's, and this file is theirs. Register: product.

## Scene

A student at 11pm, laptop on a bed, room lit by the screen, one Canvas tab, a problem
set due at 8am. The surfaces are a warm lamp beside the page: cream paper, one mint
accent, amber only when something slipped, the buddy small and at rest.

## Color (OKLCH, warm-tinted neutrals, one accent)

Strategy: Restrained. Accent ≤10% of any surface.

| Token | Light | Dark | Role |
|---|---|---|---|
| `--pk-paper` | inherits the page paper (Newsprint `#F7F6F3` default) | Carbon `#17191D` | ground |
| `--pk-card` / `--pk-paper-2` | `#FFFFFF` | `#1E2126` | raised surface |
| `--pk-inset` / `--pk-paper-sunk` | `#EFEDE8` | `#121417` | recessed surface |
| `--pk-line` / `--pk-rule` | `#E3E0D9` | `#2C3037` | hairline |
| `--pk-text` / `--pk-ink` | `#1B1F24` | `#E6E8EA` | primary ink |
| `--pk-text-2` / `--pk-ink-2` | `#454B54` | `#B4BAC1` | secondary ink |
| `--pk-mint` | `#51CFA0` | same | the one accent: primary action, current selection |
| `--pk-green` | `#2E7D57` | `#7FDDB8` | mint's text-safe form |
| `--pk-coin` | `#DE9A22` | `#ECB35C` | coins only |
| `--pk-amber-text` | `#8A5A12` | `#E0B25C` | "still counts", nothing else |
| course colours | from Canvas | from Canvas | read, never written; dots and bars only |

Never `#000` or pure red. Every ink pair is AA on every ground it touches (the papers are
AAA for body text; measured numbers print on the shop cards).

Twelve papers exist (`extension/receipt.js`); the table above shows the default pair.
Every paper's body ratio is 9.6:1 or better and every link ink 4.5:1 or better.

## Typography

One family: `ui-rounded, "SF Pro Rounded", -apple-system, system-ui, sans-serif`, the
same voice as the iPhone app (Theme.font is SF Pro Rounded). No web font is ever loaded.

| Step | Size / line | Weight | Use |
|---|---|---|---|
| title | 20 / 24 | 800 | the buddy's headline, a sheet title |
| heading | 16 / 20 | 800 | section heads inside a view |
| body | 14 / 20 | 600 (700 for a task title) | rows, buttons |
| meta | 13 / 16 | 600 | course names, times, hints |
| label | 11 / 14, +0.06em, uppercase | 800 | section labels |

Ratio 1.2 between steps. Nothing below 11px; nothing a student reads below 13px.
Tabular figures on every time and count.

## Spacing and shape

4-pt grid: 4 · 8 · 12 · 16 · 20 · 24. Popup 360px wide, 16px gutters. Panel 360px.
Radii: 8 (chips), 12 (fields, buttons), 16 (blocks), 20 (the panel shell), 999 (pills).
Hairlines separate rows; blocks are recessed (`--pk-inset`) or raised (`--pk-card`),
never a card inside a card. A list is a list: rows divided by hairlines, not stacked
cards.

## Components

- **Press button** (`.pk-press`): mint, ink text, 12px radius, 3px solid bottom edge that
  collapses on :active. The one signature affordance; used for Start, Wear, Save, Link.
- **Quiet button** (`.link` / `.pk-no`): text only, green ink.
- **Chip**: pill, recessed, 13px 700. States: default, `.on` (mint tint, green ink),
  `.amber` (amber tint, amber ink).
- **Row**: 44px min, title 14/700 on the first line, meta 13/600 on the second, a
  leading dot or tick, hairline between rows. Done rows strike through at 60%.
- **Day rail**: rows grouped by day; a 2px vertical rule with a course-colour dot per row.
- **Switch**: 38×22 pill, mint when on.
- **Field**: white, hairline inset, 12px radius, mint 2px ring on focus.
- **Sprout**: from slime.js/looks.js only, at 36 (popup head), 44 (shop), 64 (panel
  launcher). Never redrawn.

Every interactive element has default, hover, focus-visible (2px mint ring, 2px offset),
active, disabled. Focus is never removed.

## Motion

150 to 220ms, `cubic-bezier(.22, 1, .36, 1)` (ease-out-quint). Motion conveys state:
a view sliding in, a row settling after Put back, the progress fill catching up. Never a
bounce, never a loop, never on layout properties. Under `prefers-reduced-motion`
durations go to 0.01ms.

## Copy

Plain, warm, no exclamation marks. "still counts", "Put back", "Show me", "Nothing due.
Enjoy the space." No engineering words. The buddy speaks in one short line and one
smaller line.

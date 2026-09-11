(function(){let e=document.createElement(`link`).relList;if(e&&e.supports&&e.supports(`modulepreload`))return;for(let e of document.querySelectorAll(`link[rel="modulepreload"]`))n(e);new MutationObserver(e=>{for(let t of e)if(t.type===`childList`)for(let e of t.addedNodes)e.tagName===`LINK`&&e.rel===`modulepreload`&&n(e)}).observe(document,{childList:!0,subtree:!0});function t(e){let t={};return e.integrity&&(t.integrity=e.integrity),e.referrerPolicy&&(t.referrerPolicy=e.referrerPolicy),t.credentials=e.crossOrigin===`use-credentials`?`include`:e.crossOrigin===`anonymous`?`omit`:`same-origin`,t}function n(e){if(e.ep)return;e.ep=!0;let n=t(e);fetch(e.href,n)}})();var e=`<svg id="sprout" class="mascot-svg" viewBox="0 0 982 849" fill="none" overflow="visible" aria-hidden="true">
  <defs>
    <filter
      id="sprout-outline"
      x="-560"
      y="-400"
      width="2100"
      height="1520"
      filterUnits="userSpaceOnUse"
      primitiveUnits="userSpaceOnUse"
    >
      <feMorphology in="SourceAlpha" operator="dilate" radius="6" result="wide" />
      <feFlood flood-color="#F4FFFC" result="rim" />
      <feComposite in="rim" in2="wide" operator="in" result="outline" />
      <feMerge>
        <feMergeNode in="outline" />
        <feMergeNode in="SourceGraphic" />
      </feMerge>
    </filter>
    <!--
      Lumen (Sprout III) is drawn with radial gradients, NOT blur filters.
      It was filters first: a dilate+blur copy of the silhouette for the aura
      and three feGaussianBlurs for the belly, strands and sheen. Because his
      arms get a new transform every frame, the aura filter re-rasterised the
      whole character every frame — measured at 86ms per frame on its own,
      about 8fps against 30fps with it off. Gradients cost nothing to re-draw.
    -->
    <radialGradient id="lumen-aura-grad">
      <stop offset="0" stop-color="#D8FFEF" stop-opacity="0.42" />
      <stop offset="0.25" stop-color="#D8FFEF" stop-opacity="0.34" />
      <stop offset="0.45" stop-color="#D8FFEF" stop-opacity="0.24" />
      <stop offset="0.62" stop-color="#D8FFEF" stop-opacity="0.15" />
      <stop offset="0.78" stop-color="#D8FFEF" stop-opacity="0.07" />
      <stop offset="0.9" stop-color="#D8FFEF" stop-opacity="0.02" />
      <stop offset="1" stop-color="#D8FFEF" stop-opacity="0" />
    </radialGradient>
    <radialGradient id="lumen-soft-grad">
      <stop offset="0" stop-color="#EFFFF6" stop-opacity="0.9" />
      <stop offset="0.25" stop-color="#EFFFF6" stop-opacity="0.74" />
      <stop offset="0.45" stop-color="#EFFFF6" stop-opacity="0.5" />
      <stop offset="0.62" stop-color="#EFFFF6" stop-opacity="0.3" />
      <stop offset="0.78" stop-color="#EFFFF6" stop-opacity="0.14" />
      <stop offset="0.9" stop-color="#EFFFF6" stop-opacity="0.04" />
      <stop offset="1" stop-color="#EFFFF6" stop-opacity="0" />
    </radialGradient>
    <radialGradient id="lumen-hot-grad">
      <stop offset="0" stop-color="#FFFFFF" stop-opacity="0.8" />
      <stop offset="0.28" stop-color="#FFFFFF" stop-opacity="0.6" />
      <stop offset="0.5" stop-color="#FFFFFF" stop-opacity="0.36" />
      <stop offset="0.7" stop-color="#FFFFFF" stop-opacity="0.17" />
      <stop offset="0.87" stop-color="#FFFFFF" stop-opacity="0.05" />
      <stop offset="1" stop-color="#FFFFFF" stop-opacity="0" />
    </radialGradient>
    <radialGradient id="lumen-lamp" cx="0.5" cy="0.5" r="0.5">
      <stop offset="0" stop-color="#FFFFFF" />
      <stop id="lamp-pale" offset="0.34" stop-color="#B8EED4" />
      <stop id="lamp-chroma" offset="0.7" stop-color="#58CC9F" />
      <stop id="lamp-edge" offset="1" stop-color="#58CC9F" stop-opacity="0" />
    </radialGradient>
    <!-- Ninja II+: the arm guards are cropped to the long fin, so they follow its taper. -->
    <clipPath id="fin-l-clip"><use href="#fin-l" /></clipPath>
    <clipPath id="fin-r-clip"><use href="#fin-r" /></clipPath>
    <clipPath id="sprout-body-clip">
      <path
        d="M 512 94
           C 600 94 670 116 722 174
           C 774 232 830 338 854 458
           C 878 578 876 698 826 792
           C 786 850 640 850 512 850
           C 384 850 238 850 198 792
           C 148 698 146 578 170 458
           C 194 338 250 232 302 174
           C 354 116 424 94 512 94 Z"
      />
    </clipPath>
    <!--
      Rim for things held in a fin. #sprout-outline cannot be reused: its region is authored in
      BODY coordinates (x -320..1300), and a held item lives in arm-local space where the fin tip
      is already at x -441 — the katana fell straight outside it and vanished. This region is
      centred on the arm instead.
    -->
    <filter id="held-outline" x="-900" y="-760" width="1900" height="1620"
            filterUnits="userSpaceOnUse" primitiveUnits="userSpaceOnUse">
      <feMorphology in="SourceAlpha" operator="dilate" radius="6" result="wide" />
      <feFlood flood-color="#F4FFFC" result="rim" />
      <feComposite in="rim" in2="wide" operator="in" result="outline" />
      <feMerge><feMergeNode in="outline" /><feMergeNode in="SourceGraphic" /></feMerge>
    </filter>
  </defs>

  <g id="sprout-root">
    <!--
      Tuft is outlined on its own so it does not melt into the crown
      and leave a lumpy head silhouette.
    -->
    <!--
      Lumen aura. Sized to cover the silhouette including the fins (they reach
      about x -130..1150), so the light reads as coming off all of him rather
      than tracing his edge.
    -->
    <ellipse id="lumen-aura" class="lumen" cx="512" cy="520" rx="720" ry="470" fill="url(#lumen-aura-grad)" />

    <!--
      The rim, drawn rather than filtered.

      It used to be #sprout-outline on this whole group: dilate the alpha, flood it
      white, put the group back on top. Correct, and 17ms a frame — a filter re-runs
      whenever anything inside it moves, the arms move every frame, and by the time
      the body and a costume raster were in the group the whole character was being
      re-rasterised sixty times a second. Measured at 390x680 CSS px, DPR 3: 26.6ms a
      frame with the filter, 9.9ms without.

      So the rim is now a white-stroked copy of each silhouette shape, drawn behind
      the real one. A <use> clone inherits the stroke set on the <use> because the
      originals never set one, and keeps its own fill, which does not matter: the real
      shape draws over it at the same place. Order does the rest — body rim first, then
      each arm's rim inside the arm group so it swings with it, then the fills, so the
      body covers the arm rims where a fin meets it and the seam never shows. Zero
      per-frame cost: a stroke is just more path.
    -->
    <g id="sprout-silhouette">
      <use href="#body" class="rim" stroke="#F4FFFC" stroke-linejoin="round" stroke-linecap="round" stroke-width="16" />
      <g id="arm-l" transform="translate(318 452)">
        <use href="#fin-l-stub" class="rim" stroke="#F4FFFC" stroke-linejoin="round" stroke-linecap="round" stroke-width="12" />
        <use href="#fin-l" class="rim" stroke="#F4FFFC" stroke-linejoin="round" stroke-linecap="round" stroke-width="12" />
        <path
          id="fin-l-stub"
          class="flipper sprout-fill suit wing-stub"
          fill="#58CC9F"
          d="M 68 0
             C 60 -24, 15 -54, -75 -82
             C -173 -110, -270 -64, -353 4
             C -396 42, -390 104, -323 116
             C -233 110, -143 68, -75 50
             C 15 30, 60 22, 68 0 Z"
        />
        <path
          id="fin-l"
          class="flipper sprout-fill suit wing-full"
          fill="#58CC9F"
          d="M 85 0
             C 75 -24, 19 -54, -94 -82
             C -216 -110, -338 -64, -441 4
             C -495 42, -488 104, -404 116
             C -291 110, -179 68, -94 50
             C 19 30, 75 22, 85 0 Z"
        />
        <!--
          Tekko: a red cuff on the forearm, bound at both hems, carrying the same
          plate as the headband. Cropped to the fin, so it follows the taper and
          rides every arm rotation.
        -->
        <g class="ninja-guard" display="none" clip-path="url(#fin-l-clip)">
          <path fill="#C43B3B"
                d="M -256 -196
                   C -282 -70, -286 60, -282 226
                   L -414 230
                   C -410 60, -414 -68, -388 -198 Z" />
          <path fill="#9E2F2F"
                d="M -256 -196
                   C -282 -70, -286 60, -282 226
                   L -302 227
                   C -306 60, -302 -70, -276 -197 Z" />
          <path fill="#9E2F2F"
                d="M -414 230
                   C -410 60, -414 -68, -388 -198
                   L -369 -199
                   C -395 -68, -391 60, -395 231 Z" />
          <g fill="none" stroke="#9E2F2F" stroke-width="6" opacity="0.85">
            <path d="M -315 -190 C -338 -70, -342 60, -338 226" />
            <path d="M -356 -194 C -378 -70, -382 60, -378 228" />
          </g>
          <path fill="#E05A5A"
                d="M -292 -104
                   C -320 -116, -352 -114, -378 -98
                   C -352 -84, -320 -86, -292 -74 Z" />
          <g transform="translate(-336 30) rotate(-13)">
            <rect x="-36" y="-22" width="72" height="44" rx="11" fill="#5F666E" />
            <rect x="-29" y="-16" width="58" height="29" rx="8" fill="#D4DAE0" />
            <circle cx="-21" cy="-7" r="3.1" fill="#3A4046" />
            <circle cx="21" cy="-7" r="3.1" fill="#3A4046" />
            <circle cx="-21" cy="8" r="3.1" fill="#3A4046" />
            <circle cx="21" cy="8" r="3.1" fill="#3A4046" />
          </g>
        </g>
        <g class="costume-arm-l"></g>
      </g>
      <g id="arm-r" transform="translate(706 452)">
        <use href="#fin-r-stub" class="rim" stroke="#F4FFFC" stroke-linejoin="round" stroke-linecap="round" stroke-width="12" />
        <use href="#fin-r" class="rim" stroke="#F4FFFC" stroke-linejoin="round" stroke-linecap="round" stroke-width="12" />
        <path
          id="fin-r-stub"
          class="flipper sprout-fill suit wing-stub"
          fill="#58CC9F"
          d="M -68 0
             C -60 -24, -15 -54, 75 -82
             C 173 -110, 270 -64, 353 4
             C 396 42, 390 104, 323 116
             C 233 110, 143 68, 75 50
             C -15 30, -60 22, -68 0 Z"
        />
        <path
          id="fin-r"
          class="flipper sprout-fill suit wing-full"
          fill="#58CC9F"
          d="M -85 0
             C -75 -24, -19 -54, 94 -82
             C 216 -110, 338 -64, 441 4
             C 495 42, 488 104, 404 116
             C 291 110, 179 68, 94 50
             C -19 30, -75 22, -85 0 Z"
        />
        <!--
          Tekko: a red cuff on the forearm, bound at both hems, carrying the same
          plate as the headband. Cropped to the fin, so it follows the taper and
          rides every arm rotation.
        -->
        <g class="ninja-guard" display="none" clip-path="url(#fin-r-clip)">
          <path fill="#C43B3B"
                d="M 256 -196
                   C 282 -70, 286 60, 282 226
                   L 414 230
                   C 410 60, 414 -68, 388 -198 Z" />
          <path fill="#9E2F2F"
                d="M 256 -196
                   C 282 -70, 286 60, 282 226
                   L 302 227
                   C 306 60, 302 -70, 276 -197 Z" />
          <path fill="#9E2F2F"
                d="M 414 230
                   C 410 60, 414 -68, 388 -198
                   L 369 -199
                   C 395 -68, 391 60, 395 231 Z" />
          <g fill="none" stroke="#9E2F2F" stroke-width="6" opacity="0.85">
            <path d="M 315 -190 C 338 -70, 342 60, 338 226" />
            <path d="M 356 -194 C 378 -70, 382 60, 378 228" />
          </g>
          <path fill="#E05A5A"
                d="M 292 -104
                   C 320 -116, 352 -114, 378 -98
                   C 352 -84, 320 -86, 292 -74 Z" />
          <g transform="translate(336 30) rotate(13)">
            <rect x="-36" y="-22" width="72" height="44" rx="11" fill="#5F666E" />
            <rect x="-29" y="-16" width="58" height="29" rx="8" fill="#D4DAE0" />
            <circle cx="-21" cy="-7" r="3.1" fill="#3A4046" />
            <circle cx="21" cy="-7" r="3.1" fill="#3A4046" />
            <circle cx="-21" cy="8" r="3.1" fill="#3A4046" />
            <circle cx="21" cy="8" r="3.1" fill="#3A4046" />
          </g>
        </g>
        <g class="costume-arm-r"></g>
      </g>
      <path
        id="body"
        class="sprout-fill suit"
        fill="#58CC9F"
        d="M 512 94
           C 600 94 670 116 722 174
           C 774 232 830 338 854 458
           C 878 578 876 698 826 792
           C 786 850 640 850 512 850
           C 384 850 238 850 198 792
           C 148 698 146 578 170 458
           C 194 338 250 232 302 174
           C 354 116 424 94 512 94 Z"
      />

    <!--
      Lumen (Sprout III). Halo sits under the belly so the light spills onto the
      body; the core sits over it. Puppet drives opacity and the halo pulse.
      Hidden unless the evolution has glow.
    -->
    <ellipse id="lumen-sheen" class="lumen" clip-path="url(#sprout-body-clip)" cx="756" cy="286" rx="150" ry="220" transform="rotate(-24 756 286)" fill="url(#lumen-hot-grad)" opacity="0.28" />
    <ellipse id="lumen-halo" class="lumen" cx="512" cy="655" rx="300" ry="184" fill="url(#lumen-soft-grad)" opacity="0.9" />
    <ellipse id="belly" cx="512" cy="655" rx="176" ry="92" fill="#B3EBD0" />

    <!--
      Stage III badge (George, 2026-09-04): the three-star reward is an emblem
      on the belly, one per coat, a shuriken for the Ninja. It replaced Lumen
      (the glow), whose layers are still here but never shown. The emblems are
      generated flat-illustration PNGs in \`public/badges/\`, each painted on its
      coat's belly tint so it can sit over \`#belly\` with no seam, clipped to
      the taller stage III belly. \`applyPalette\` / \`applySkin\` pick which shows.
    -->
    <clipPath id="badge-clip"><ellipse cx="512" cy="660" rx="182" ry="128" /></clipPath>
    <g id="badge" display="none" clip-path="url(#badge-clip)">
      <image id="badge-sapling" class="badge" display="none" href="badges/sapling.png" x="332" y="480" width="360" height="360" />
      <image id="badge-flame" class="badge" display="none" href="badges/flame.png" x="332" y="480" width="360" height="360" />
      <image id="badge-wave" class="badge" display="none" href="badges/wave.png" x="332" y="480" width="360" height="360" />
      <image id="badge-sun" class="badge" display="none" href="badges/sun.png" x="332" y="480" width="360" height="360" />
      <image id="badge-moon" class="badge" display="none" href="badges/moon.png" x="332" y="480" width="360" height="360" />
      <image id="badge-bolt" class="badge" display="none" href="badges/bolt.png" x="332" y="480" width="360" height="360" />
      <image id="badge-shuriken" class="badge" display="none" href="badges/shuriken.png" x="332" y="480" width="360" height="360" />
    </g>

      <!--
        Stage III costume slots (costumes.ts pours markup in at load). Body clothing sits
        over the belly.

        Inside #sprout-silhouette on purpose, and this is where the group closes. The rim
        is one filter over the union of everything in here, so a garment that overhangs the
        pear — most of them do, the fit pipeline dilates the body mask — used to paint over
        the body's own rim and leave him outlined on the fins and the hat and nowhere else.
        A filter on this group alone is not the answer: it drops the art entirely.
      -->
      <g id="costume-body"></g>
    </g>
    <ellipse id="ninja-lamp" display="none" cx="512" cy="655" rx="198" ry="102" fill="url(#lumen-lamp)" />
    <ellipse id="lumen-core" class="lumen" cx="512" cy="655" rx="196" ry="104" fill="url(#lumen-soft-grad)" />
    <ellipse id="lumen-hot" class="lumen" cx="512" cy="655" rx="132" ry="66" fill="url(#lumen-hot-grad)" opacity="0.6" />

    <!--
      Ninja only. Clip keeps the mint eye-hole on the pear.
      Face sits on top of this strip. Hidden unless skin=ninja.
    -->
    <g id="ninja" class="no-flip" display="none">
      <rect
        id="eye-strip"
        x="188"
        y="298"
        width="648"
        height="154"
        rx="77"
        fill="#58CC9F"
        clip-path="url(#sprout-body-clip)"
      />

      <!--
        The band is stroked, not filled: one centreline with a uniform width, run
        well past the pear on both sides so \`#sprout-body-clip\` — not the path —
        decides where it ends. A filled path stopped short of the silhouette and
        left a notch at both corners of the head.
      -->
      <g id="headband">
        <g clip-path="url(#sprout-body-clip)" fill="none" stroke-linecap="butt">
          <path id="band" stroke="#C43B3B" stroke-width="62"
                d="M 108 289 C 288 231, 736 231, 916 289" />
          <path id="band-hem" stroke="#9E2F2F" stroke-width="12"
                d="M 108 313 C 288 255, 736 255, 916 313" />
          <path id="band-shine" stroke="#E05A5A" stroke-width="14"
                d="M 108 266 C 288 208, 736 208, 916 266" />
          <g id="plate" stroke="none">
            <rect x="455" y="221" width="114" height="50" rx="12" fill="#5F666E" />
            <rect x="463" y="228" width="98" height="33" rx="8" fill="#D4DAE0" />
            <circle cx="474" cy="236" r="3.7" fill="#3A4046" />
            <circle cx="550" cy="236" r="3.7" fill="#3A4046" />
            <circle cx="474" cy="253" r="3.7" fill="#3A4046" />
            <circle cx="550" cy="253" r="3.7" fill="#3A4046" />
          </g>
        </g>
        <g id="headband-tails" transform="translate(240 262)">
          <g filter="url(#sprout-outline)">
            <path
              fill="#C43B3B"
              d="M 6 2
                 C -16 -16, -58 -44, -108 -48
                 C -130 -50, -140 -24, -116 -12
                 C -88 2, -36 12, 10 12
                 Z"
            />
            <path
              fill="#C43B3B"
              d="M 8 10
                 C -14 30, -56 68, -94 102
                 C -114 118, -100 140, -74 122
                 C -42 100, -4 44, 12 16
                 Z"
            />
            <ellipse cx="8" cy="6" rx="16" ry="13" fill="#C43B3B" />
          </g>
          <path
            fill="#9E2F2F"
            d="M 0 2
               C -24 -10, -64 -28, -100 -30
               C -108 -30, -110 -22, -96 -18
               C -70 -12, -28 4, 4 8
               Z"
          />
          <path
            fill="#9E2F2F"
            d="M 2 12
               C -20 30, -56 64, -86 92
               C -94 100, -88 108, -74 98
               C -46 78, -10 36, 6 16
               Z"
          />
          <ellipse cx="6" cy="4" rx="9" ry="7" fill="#E05A5A" />
        </g>
      </g>
    </g>

    <g id="tuft" transform="translate(512 90)">
      <use href="#tuft-leaf" class="rim" stroke="#F4FFFC" stroke-linejoin="round" stroke-linecap="round" stroke-width="12" />
      <g id="tuft-leaf">
        <path class="sprout-fill" fill="#58CC9F" d="M 1 8 C 16 -10 36 -40 56 -56 C 68 -64 84 -52 76 -36 C 68 -18 30 4 6 14 Z" />
        <path class="sprout-fill" fill="#58CC9F" d="M -2 10 C -16 -4 -28 -28 -22 -46 C -18 -56 -2 -54 4 -40 C 10 -22 8 2 0 12 Z" />
      </g>
    </g>
    <!-- Lumen strands. Follows the tuft pivot; no rim so it sits inside the leaf outline. -->
    <g id="lumen-tuft" class="lumen" transform="translate(512 90)">
      <circle cx="18" cy="-38" r="70" fill="url(#lumen-soft-grad)" opacity="0.42" />
      <path fill="#EFFFF6" d="M 1 8 C 16 -10 36 -40 56 -56 C 68 -64 84 -52 76 -36 C 68 -18 30 4 6 14 Z" />
      <path fill="#EFFFF6" d="M -2 10 C -16 -4 -28 -28 -22 -46 C -18 -56 -2 -54 4 -40 C 10 -22 8 2 0 12 Z" />
    </g>

    <g id="costume-head"></g>
    <g id="face">
      <ellipse class="blush" cx="272" cy="424" rx="42" ry="22" fill="#F4B3C0" opacity="0.2" />
      <ellipse class="blush" cx="752" cy="424" rx="42" ry="22" fill="#F4B3C0" opacity="0.2" />

      <g id="eye-l">
        <circle class="eye-dot" cx="352" cy="371" r="52" fill="#121B22" />
        <path class="eye-happy" d="M 298 378 Q 352 342 406 378" fill="none" stroke="#121B22" stroke-width="12" stroke-linecap="round" />
        <path class="eye-sleep" d="M 302 376 Q 352 400 402 376" fill="none" stroke="#121B22" stroke-width="12" stroke-linecap="round" />
      </g>
      <g id="eye-r">
        <circle class="eye-dot" cx="671" cy="371" r="52" fill="#121B22" />
        <path class="eye-happy" d="M 617 378 Q 671 342 725 378" fill="none" stroke="#121B22" stroke-width="12" stroke-linecap="round" />
        <path class="eye-sleep" d="M 621 376 Q 671 400 721 376" fill="none" stroke="#121B22" stroke-width="12" stroke-linecap="round" />
      </g>
      <path class="mouth smile" d="M 468 392 Q 512 430 556 392" fill="none" stroke="#121B22" stroke-width="10" stroke-linecap="round" />
      <path class="mouth open" d="M 464 388 Q 512 442 560 388" fill="none" stroke="#121B22" stroke-width="11" stroke-linecap="round" />
      <ellipse class="mouth o" cx="512" cy="404" rx="16" ry="18" fill="none" stroke="#121B22" stroke-width="9" />
      <path class="mouth flat" d="M 486 400 H 538" fill="none" stroke="#121B22" stroke-width="10" stroke-linecap="round" />
    </g>
    <g id="costume-face"></g>
  </g>
</svg>
`,t=`<svg id="sail" class="mascot-svg" viewBox="0 0 982 849" fill="none" overflow="visible" aria-hidden="true">
  <defs>
    <filter
      id="sail-outline"
      x="-460"
      y="-260"
      width="1900"
      height="1460"
      filterUnits="userSpaceOnUse"
      primitiveUnits="userSpaceOnUse"
    >
      <feMorphology in="SourceAlpha" operator="dilate" radius="6" result="wide" />
      <feFlood flood-color="#F5FBFE" result="rim" />
      <feComposite in="rim" in2="wide" operator="in" result="outline" />
      <feMerge>
        <feMergeNode in="outline" />
        <feMergeNode in="SourceGraphic" />
      </feMerge>
    </filter>
  </defs>

  <g id="sail-root">
    <!--
      Two cephalic scoops, Sprout-leaf simple: comma blobs that
      curl in. Outlined alone so they stay two fins. Hidden at I.
    -->
    <g id="tuft" transform="translate(512 268)">
      <g filter="url(#sail-outline)">
        <path
          class="sprout-fill lobe"
          fill="#6BAFE0"
          d="M -46 32
             C -86 6, -108 -40, -84 -88
             C -68 -118, -36 -112, -22 -76
             C -12 -48, -22 10, -46 32 Z"
        />
      </g>
      <g filter="url(#sail-outline)">
        <path
          class="sprout-fill lobe"
          fill="#6BAFE0"
          d="M 46 32
             C 86 6, 108 -40, 84 -88
             C 68 -118, 36 -112, 22 -76
             C 12 -48, 22 10, 46 32 Z"
        />
      </g>
    </g>

    <!-- Simple whip + small spade. III only. -->
    <g id="tail" class="evo-full" transform="translate(512 586)" filter="url(#sail-outline)">
      <path
        class="sprout-fill"
        fill="#6BAFE0"
        d="M -4 -8
           C 10 36, 16 100, 8 158
           C 2 206, 6 244, 28 268
           C 50 290, 82 284, 88 254
           C 92 232, 70 222, 44 228
           C 22 214, 16 176, 22 132
           C 26 76, 14 28, -4 -8 Z"
      />
    </g>

    <g id="sail-silhouette" filter="url(#sail-outline)">
      <!--
        Pectorals are diamond corners, not paddles.
        Stub = I. Full span = II/III.
      -->
      <g id="arm-l" transform="translate(300 428)">
        <path
          class="flipper sprout-fill wing-stub"
          fill="#6BAFE0"
          d="M 48 -70
             C 8 -78, -40 -56, -78 -18
             C -92 -2, -90 18, -70 28
             C -36 40, 8 28, 48 16
             C 60 -8, 62 -44, 48 -70 Z"
        />
        <path
          class="flipper sprout-fill wing-full"
          fill="#6BAFE0"
          d="M 56 -86
             C -10 -100, -90 -70, -172 -8
             C -188 8, -184 30, -156 40
             C -88 58, -10 36, 56 18
             C 72 -12, 74 -54, 56 -86 Z"
        />
      </g>
      <g id="arm-r" transform="translate(724 428)">
        <path
          class="flipper sprout-fill wing-stub"
          fill="#6BAFE0"
          d="M -48 -70
             C -8 -78, 40 -56, 78 -18
             C 92 -2, 90 18, 70 28
             C 36 40, -8 28, -48 16
             C -60 -8, -62 -44, -48 -70 Z"
        />
        <path
          class="flipper sprout-fill wing-full"
          fill="#6BAFE0"
          d="M -56 -86
             C 10 -100, 90 -70, 172 -8
             C 188 8, 184 30, 156 40
             C 88 58, 10 36, -56 18
             C -72 -12, -74 -54, -56 -86 Z"
        />
      </g>
      <!-- Wide kite disc. Concave crown. Sides sit on the wing line. -->
      <path
        id="body"
        class="sprout-fill"
        fill="#6BAFE0"
        d="M 380 246
           C 430 266, 486 276, 512 276
           C 538 276, 594 266, 644 246
           C 700 300, 748 364, 768 428
           C 748 500, 700 546, 644 570
           C 594 582, 538 586, 512 586
           C 486 586, 430 582, 380 570
           C 324 546, 276 500, 256 428
           C 276 364, 324 300, 380 246 Z"
      />
    </g>

    <path
      id="belly"
      fill="#D4EBF8"
      d="M 512 396
         C 548 418, 598 458, 628 508
         C 598 548, 548 566, 512 570
         C 476 566, 426 548, 396 508
         C 426 458, 476 418, 512 396 Z"
    />

    <g id="face">
      <ellipse class="blush" cx="385" cy="374" rx="30" ry="14" fill="#F3B5A6" opacity="0.45" />
      <ellipse class="blush" cx="639" cy="374" rx="30" ry="14" fill="#F3B5A6" opacity="0.45" />

      <g id="eye-l">
        <circle class="eye-dot" cx="436" cy="344" r="44" fill="#121B22" />
        <path class="eye-happy" d="M 392 350 Q 436 318 480 350" fill="none" stroke="#121B22" stroke-width="12" stroke-linecap="round" />
        <path class="eye-sleep" d="M 396 348 Q 436 368 476 348" fill="none" stroke="#121B22" stroke-width="12" stroke-linecap="round" />
      </g>
      <g id="eye-r">
        <circle class="eye-dot" cx="588" cy="344" r="44" fill="#121B22" />
        <path class="eye-happy" d="M 544 350 Q 588 318 632 350" fill="none" stroke="#121B22" stroke-width="12" stroke-linecap="round" />
        <path class="eye-sleep" d="M 548 348 Q 588 368 628 348" fill="none" stroke="#121B22" stroke-width="12" stroke-linecap="round" />
      </g>
      <path class="mouth smile" d="M 488 384 Q 512 408 536 384" fill="none" stroke="#121B22" stroke-width="10" stroke-linecap="round" />
      <path class="mouth open" d="M 484 380 Q 512 420 540 380" fill="none" stroke="#121B22" stroke-width="11" stroke-linecap="round" />
      <ellipse class="mouth o" cx="512" cy="394" rx="12" ry="13" fill="none" stroke="#121B22" stroke-width="9" />
      <path class="mouth flat" d="M 494 390 H 530" fill="none" stroke="#121B22" stroke-width="10" stroke-linecap="round" />
    </g>
  </g>
</svg>
`,n=`<svg id="orca" class="mascot-svg" viewBox="0 0 982 849" fill="none" overflow="visible" aria-hidden="true">
  <defs>
    <filter
      id="sprout-outline"
      x="-560"
      y="-400"
      width="2100"
      height="1520"
      filterUnits="userSpaceOnUse"
      primitiveUnits="userSpaceOnUse"
    >
      <feMorphology in="SourceAlpha" operator="dilate" radius="6" result="wide" />
      <feFlood flood-color="#F4FFFC" result="rim" />
      <feComposite in="rim" in2="wide" operator="in" result="outline" />
      <feMerge>
        <feMergeNode in="outline" />
        <feMergeNode in="SourceGraphic" />
      </feMerge>
    </filter>
    <!--
      Lumen (Sprout III) is drawn with radial gradients, NOT blur filters.
      It was filters first: a dilate+blur copy of the silhouette for the aura
      and three feGaussianBlurs for the belly, strands and sheen. Because his
      arms get a new transform every frame, the aura filter re-rasterised the
      whole character every frame — measured at 86ms per frame on its own,
      about 8fps against 30fps with it off. Gradients cost nothing to re-draw.
    -->
    <radialGradient id="lumen-aura-grad">
      <stop offset="0" stop-color="#D8FFEF" stop-opacity="0.42" />
      <stop offset="0.25" stop-color="#D8FFEF" stop-opacity="0.34" />
      <stop offset="0.45" stop-color="#D8FFEF" stop-opacity="0.24" />
      <stop offset="0.62" stop-color="#D8FFEF" stop-opacity="0.15" />
      <stop offset="0.78" stop-color="#D8FFEF" stop-opacity="0.07" />
      <stop offset="0.9" stop-color="#D8FFEF" stop-opacity="0.02" />
      <stop offset="1" stop-color="#D8FFEF" stop-opacity="0" />
    </radialGradient>
    <radialGradient id="lumen-soft-grad">
      <stop offset="0" stop-color="#EFFFF6" stop-opacity="0.9" />
      <stop offset="0.25" stop-color="#EFFFF6" stop-opacity="0.74" />
      <stop offset="0.45" stop-color="#EFFFF6" stop-opacity="0.5" />
      <stop offset="0.62" stop-color="#EFFFF6" stop-opacity="0.3" />
      <stop offset="0.78" stop-color="#EFFFF6" stop-opacity="0.14" />
      <stop offset="0.9" stop-color="#EFFFF6" stop-opacity="0.04" />
      <stop offset="1" stop-color="#EFFFF6" stop-opacity="0" />
    </radialGradient>
    <radialGradient id="lumen-hot-grad">
      <stop offset="0" stop-color="#FFFFFF" stop-opacity="0.8" />
      <stop offset="0.28" stop-color="#FFFFFF" stop-opacity="0.6" />
      <stop offset="0.5" stop-color="#FFFFFF" stop-opacity="0.36" />
      <stop offset="0.7" stop-color="#FFFFFF" stop-opacity="0.17" />
      <stop offset="0.87" stop-color="#FFFFFF" stop-opacity="0.05" />
      <stop offset="1" stop-color="#FFFFFF" stop-opacity="0" />
    </radialGradient>
    <radialGradient id="lumen-lamp" cx="0.5" cy="0.5" r="0.5">
      <stop offset="0" stop-color="#FFFFFF" />
      <stop id="lamp-pale" offset="0.34" stop-color="#B8EED4" />
      <stop id="lamp-chroma" offset="0.7" stop-color="#58CC9F" />
      <stop id="lamp-edge" offset="1" stop-color="#58CC9F" stop-opacity="0" />
    </radialGradient>
    <!-- Ninja II+: the arm guards are cropped to the long fin, so they follow its taper. -->
    <clipPath id="fin-l-clip"><use href="#fin-l" /></clipPath>
    <clipPath id="fin-r-clip"><use href="#fin-r" /></clipPath>
    <clipPath id="sprout-body-clip">
      <path
        d="M 512 94
           C 600 94 670 116 722 174
           C 774 232 830 338 854 458
           C 878 578 876 698 826 792
           C 786 850 640 850 512 850
           C 384 850 238 850 198 792
           C 148 698 146 578 170 458
           C 194 338 250 232 302 174
           C 354 116 424 94 512 94 Z"
      />
    </clipPath>
    <!--
      Rim for things held in a fin. #sprout-outline cannot be reused: its region is authored in
      BODY coordinates (x -320..1300), and a held item lives in arm-local space where the fin tip
      is already at x -441 — the katana fell straight outside it and vanished. This region is
      centred on the arm instead.
    -->
    <filter id="held-outline" x="-900" y="-760" width="1900" height="1620"
            filterUnits="userSpaceOnUse" primitiveUnits="userSpaceOnUse">
      <feMorphology in="SourceAlpha" operator="dilate" radius="6" result="wide" />
      <feFlood flood-color="#F4FFFC" result="rim" />
      <feComposite in="rim" in2="wide" operator="in" result="outline" />
      <feMerge><feMergeNode in="outline" /><feMergeNode in="SourceGraphic" /></feMerge>
    </filter>
  </defs>

  <g id="orca-root">
    <!--
      Tuft is outlined on its own so it does not melt into the crown
      and leave a lumpy head silhouette.
    -->
    <!--
      Lumen aura. Sized to cover the silhouette including the fins (they reach
      about x -130..1150), so the light reads as coming off all of him rather
      than tracing his edge.
    -->
    <ellipse id="lumen-aura" class="lumen" cx="512" cy="520" rx="720" ry="470" fill="url(#lumen-aura-grad)" />

    <g id="sprout-silhouette" filter="url(#sprout-outline)">
      <g id="arm-l" transform="translate(318 452)">
        <path
          class="flipper suit wing-stub"
          fill="#46566A"
          d="M 68 0
             C 60 -24, 15 -54, -75 -82
             C -173 -110, -270 -64, -353 4
             C -396 42, -390 104, -323 116
             C -233 110, -143 68, -75 50
             C 15 30, 60 22, 68 0 Z"
        />
        <path
          id="fin-l"
          class="flipper suit wing-full"
          fill="#46566A"
          d="M 85 0
             C 75 -24, 19 -54, -94 -82
             C -216 -110, -338 -64, -441 4
             C -495 42, -488 104, -404 116
             C -291 110, -179 68, -94 50
             C 19 30, 75 22, 85 0 Z"
        />
        <!--
          Tekko: a red cuff on the forearm, bound at both hems, carrying the same
          plate as the headband. Cropped to the fin, so it follows the taper and
          rides every arm rotation.
        -->
        <g class="ninja-guard" display="none" clip-path="url(#fin-l-clip)">
          <path fill="#C43B3B"
                d="M -256 -196
                   C -282 -70, -286 60, -282 226
                   L -414 230
                   C -410 60, -414 -68, -388 -198 Z" />
          <path fill="#9E2F2F"
                d="M -256 -196
                   C -282 -70, -286 60, -282 226
                   L -302 227
                   C -306 60, -302 -70, -276 -197 Z" />
          <path fill="#9E2F2F"
                d="M -414 230
                   C -410 60, -414 -68, -388 -198
                   L -369 -199
                   C -395 -68, -391 60, -395 231 Z" />
          <g fill="none" stroke="#9E2F2F" stroke-width="6" opacity="0.85">
            <path d="M -315 -190 C -338 -70, -342 60, -338 226" />
            <path d="M -356 -194 C -378 -70, -382 60, -378 228" />
          </g>
          <path fill="#E05A5A"
                d="M -292 -104
                   C -320 -116, -352 -114, -378 -98
                   C -352 -84, -320 -86, -292 -74 Z" />
          <g transform="translate(-336 30) rotate(-13)">
            <rect x="-36" y="-22" width="72" height="44" rx="11" fill="#5F666E" />
            <rect x="-29" y="-16" width="58" height="29" rx="8" fill="#D4DAE0" />
            <circle cx="-21" cy="-7" r="3.1" fill="#3A4046" />
            <circle cx="21" cy="-7" r="3.1" fill="#3A4046" />
            <circle cx="-21" cy="8" r="3.1" fill="#3A4046" />
            <circle cx="21" cy="8" r="3.1" fill="#3A4046" />
          </g>
        </g>
        <g class="costume-arm-l"></g>
      </g>
      <g id="arm-r" transform="translate(706 452)">
        <path
          class="flipper suit wing-stub"
          fill="#46566A"
          d="M -68 0
             C -60 -24, -15 -54, 75 -82
             C 173 -110, 270 -64, 353 4
             C 396 42, 390 104, 323 116
             C 233 110, 143 68, 75 50
             C -15 30, -60 22, -68 0 Z"
        />
        <path
          id="fin-r"
          class="flipper suit wing-full"
          fill="#46566A"
          d="M -85 0
             C -75 -24, -19 -54, 94 -82
             C 216 -110, 338 -64, 441 4
             C 495 42, 488 104, 404 116
             C 291 110, 179 68, 94 50
             C -19 30, -75 22, -85 0 Z"
        />
        <!--
          Tekko: a red cuff on the forearm, bound at both hems, carrying the same
          plate as the headband. Cropped to the fin, so it follows the taper and
          rides every arm rotation.
        -->
        <g class="ninja-guard" display="none" clip-path="url(#fin-r-clip)">
          <path fill="#C43B3B"
                d="M 256 -196
                   C 282 -70, 286 60, 282 226
                   L 414 230
                   C 410 60, 414 -68, 388 -198 Z" />
          <path fill="#9E2F2F"
                d="M 256 -196
                   C 282 -70, 286 60, 282 226
                   L 302 227
                   C 306 60, 302 -70, 276 -197 Z" />
          <path fill="#9E2F2F"
                d="M 414 230
                   C 410 60, 414 -68, 388 -198
                   L 369 -199
                   C 395 -68, 391 60, 395 231 Z" />
          <g fill="none" stroke="#9E2F2F" stroke-width="6" opacity="0.85">
            <path d="M 315 -190 C 338 -70, 342 60, 338 226" />
            <path d="M 356 -194 C 378 -70, 382 60, 378 228" />
          </g>
          <path fill="#E05A5A"
                d="M 292 -104
                   C 320 -116, 352 -114, 378 -98
                   C 352 -84, 320 -86, 292 -74 Z" />
          <g transform="translate(336 30) rotate(13)">
            <rect x="-36" y="-22" width="72" height="44" rx="11" fill="#5F666E" />
            <rect x="-29" y="-16" width="58" height="29" rx="8" fill="#D4DAE0" />
            <circle cx="-21" cy="-7" r="3.1" fill="#3A4046" />
            <circle cx="21" cy="-7" r="3.1" fill="#3A4046" />
            <circle cx="-21" cy="8" r="3.1" fill="#3A4046" />
            <circle cx="21" cy="8" r="3.1" fill="#3A4046" />
          </g>
        </g>
        <g class="costume-arm-r"></g>
      </g>
      <!--
        Dorsal fin. Rides the tuft pivot so it sways with the same spring, but it
        lives INSIDE the silhouette group, before the body, so the one white rim
        wraps fin and pear together and no line cuts across the crown. Wide base,
        convex leading edge, swept-back tip, concave trailing edge.
      -->
      <g id="tuft" transform="translate(512 90)">
        <path fill="#46566A" d="M -100 90 L -92 22 C -72 -56 -16 -130 40 -168 C 54 -178 68 -168 62 -150 C 48 -108 58 -50 84 20 L 92 90 Z" />
      </g>
      <path
        id="body"
        class="suit"
        fill="#46566A"
        d="M 512 94
           C 600 94 670 116 722 174
           C 774 232 830 338 854 458
           C 878 578 876 698 826 792
           C 786 850 640 850 512 850
           C 384 850 238 850 198 792
           C 148 698 146 578 170 458
           C 194 338 250 232 302 174
           C 354 116 424 94 512 94 Z"
      />
    </g>

    <!--
      Lumen (Sprout III). Halo sits under the belly so the light spills onto the
      body; the core sits over it. Puppet drives opacity and the halo pulse.
      Hidden unless the evolution has glow.
    -->
    <ellipse id="lumen-sheen" class="lumen" clip-path="url(#sprout-body-clip)" cx="756" cy="286" rx="150" ry="220" transform="rotate(-24 756 286)" fill="url(#lumen-hot-grad)" opacity="0.28" />
    <ellipse id="lumen-halo" class="lumen" cx="512" cy="655" rx="300" ry="184" fill="url(#lumen-soft-grad)" opacity="0.9" />
    <ellipse id="belly" cx="512" cy="655" rx="176" ry="92" fill="#B3EBD0" />

    <!--
      Stage III badge (George, 2026-09-04): the three-star reward is an emblem
      on the belly, one per coat, a shuriken for the Ninja. It replaced Lumen
      (the glow), whose layers are still here but never shown. The emblems are
      generated flat-illustration PNGs in \`public/badges/\`, each painted on its
      coat's belly tint so it can sit over \`#belly\` with no seam, clipped to
      the taller stage III belly. \`applyPalette\` / \`applySkin\` pick which shows.
    -->
    <clipPath id="badge-clip"><ellipse cx="512" cy="660" rx="182" ry="128" /></clipPath>
    <g id="badge" display="none" clip-path="url(#badge-clip)">
      <image id="badge-sapling" class="badge" display="none" href="badges/sapling.png" x="332" y="480" width="360" height="360" />
      <image id="badge-flame" class="badge" display="none" href="badges/flame.png" x="332" y="480" width="360" height="360" />
      <image id="badge-wave" class="badge" display="none" href="badges/wave.png" x="332" y="480" width="360" height="360" />
      <image id="badge-sun" class="badge" display="none" href="badges/sun.png" x="332" y="480" width="360" height="360" />
      <image id="badge-moon" class="badge" display="none" href="badges/moon.png" x="332" y="480" width="360" height="360" />
      <image id="badge-bolt" class="badge" display="none" href="badges/bolt.png" x="332" y="480" width="360" height="360" />
      <image id="badge-shuriken" class="badge" display="none" href="badges/shuriken.png" x="332" y="480" width="360" height="360" />
    </g>

    <!-- Stage III costume slots (costumes.ts pours markup in at load). Body clothing sits over the belly. -->
    <g id="costume-body"></g>
    <ellipse id="ninja-lamp" display="none" cx="512" cy="655" rx="198" ry="102" fill="url(#lumen-lamp)" />
    <ellipse id="lumen-core" class="lumen" cx="512" cy="655" rx="196" ry="104" fill="url(#lumen-soft-grad)" />
    <ellipse id="lumen-hot" class="lumen" cx="512" cy="655" rx="132" ry="66" fill="url(#lumen-hot-grad)" opacity="0.6" />

    <!--
      Ninja only. Clip keeps the mint eye-hole on the pear.
      Face sits on top of this strip. Hidden unless skin=ninja.
    -->
    <g id="ninja" class="no-flip" display="none">
      <rect
        id="eye-strip"
        x="188"
        y="298"
        width="648"
        height="154"
        rx="77"
        fill="#58CC9F"
        clip-path="url(#sprout-body-clip)"
      />

      <!--
        The band is stroked, not filled: one centreline with a uniform width, run
        well past the pear on both sides so \`#sprout-body-clip\` — not the path —
        decides where it ends. A filled path stopped short of the silhouette and
        left a notch at both corners of the head.
      -->
      <g id="headband">
        <g clip-path="url(#sprout-body-clip)" fill="none" stroke-linecap="butt">
          <path id="band" stroke="#C43B3B" stroke-width="62"
                d="M 108 289 C 288 231, 736 231, 916 289" />
          <path id="band-hem" stroke="#9E2F2F" stroke-width="12"
                d="M 108 313 C 288 255, 736 255, 916 313" />
          <path id="band-shine" stroke="#E05A5A" stroke-width="14"
                d="M 108 266 C 288 208, 736 208, 916 266" />
          <g id="plate" stroke="none">
            <rect x="455" y="221" width="114" height="50" rx="12" fill="#5F666E" />
            <rect x="463" y="228" width="98" height="33" rx="8" fill="#D4DAE0" />
            <circle cx="474" cy="236" r="3.7" fill="#3A4046" />
            <circle cx="550" cy="236" r="3.7" fill="#3A4046" />
            <circle cx="474" cy="253" r="3.7" fill="#3A4046" />
            <circle cx="550" cy="253" r="3.7" fill="#3A4046" />
          </g>
        </g>
        <g id="headband-tails" transform="translate(240 262)">
          <g filter="url(#sprout-outline)">
            <path
              fill="#C43B3B"
              d="M 6 2
                 C -16 -16, -58 -44, -108 -48
                 C -130 -50, -140 -24, -116 -12
                 C -88 2, -36 12, 10 12
                 Z"
            />
            <path
              fill="#C43B3B"
              d="M 8 10
                 C -14 30, -56 68, -94 102
                 C -114 118, -100 140, -74 122
                 C -42 100, -4 44, 12 16
                 Z"
            />
            <ellipse cx="8" cy="6" rx="16" ry="13" fill="#C43B3B" />
          </g>
          <path
            fill="#9E2F2F"
            d="M 0 2
               C -24 -10, -64 -28, -100 -30
               C -108 -30, -110 -22, -96 -18
               C -70 -12, -28 4, 4 8
               Z"
          />
          <path
            fill="#9E2F2F"
            d="M 2 12
               C -20 30, -56 64, -86 92
               C -94 100, -88 108, -74 98
               C -46 78, -10 36, 6 16
               Z"
          />
          <ellipse cx="6" cy="4" rx="9" ry="7" fill="#E05A5A" />
        </g>
      </g>
    </g>

    <!-- Lumen strands. Follows the tuft pivot; no rim so it sits inside the leaf outline. -->
    <g id="lumen-tuft" class="lumen" transform="translate(512 90)">
      <circle cx="18" cy="-38" r="70" fill="url(#lumen-soft-grad)" opacity="0.42" />
      <path fill="#EFFFF6" d="M 1 8 C 16 -10 36 -40 56 -56 C 68 -64 84 -52 76 -36 C 68 -18 30 4 6 14 Z" />
      <path fill="#EFFFF6" d="M -2 10 C -16 -4 -28 -28 -22 -46 C -18 -56 -2 -54 4 -40 C 10 -22 8 2 0 12 Z" />
    </g>

    <g id="costume-head"></g>
    <g id="face">
      <ellipse class="blush" cx="272" cy="430" rx="40" ry="20" fill="#F4B3C0" opacity="0" />
      <ellipse class="blush" cx="752" cy="430" rx="40" ry="20" fill="#F4B3C0" opacity="0" />

      <!--
        Half-lidded by construction: a white sclera, a pupil, then a lid in the
        body colour that covers the top of the eye. All three carry \`eye-dot\`
        so the puppet blinks and hides them together; the lid is an ellipse so
        it has the cx/cy the blink transform reads.
      -->
      <g id="eye-l">
        <ellipse class="eye-dot" cx="352" cy="371" rx="60" ry="52" fill="#F4F6F8" />
        <circle class="eye-dot" cx="356" cy="376" r="30" fill="#121B22" />
        <ellipse class="eye-dot" cx="352" cy="312" rx="76" ry="44" fill="#46566A" />
        <path class="eye-happy" d="M 298 378 Q 352 342 406 378" fill="none" stroke="#121B22" stroke-width="12" stroke-linecap="round" />
        <path class="eye-sleep" d="M 302 376 Q 352 400 402 376" fill="none" stroke="#121B22" stroke-width="12" stroke-linecap="round" />
      </g>
      <g id="eye-r">
        <ellipse class="eye-dot" cx="671" cy="371" rx="60" ry="52" fill="#F4F6F8" />
        <circle class="eye-dot" cx="667" cy="376" r="30" fill="#121B22" />
        <ellipse class="eye-dot" cx="671" cy="312" rx="76" ry="44" fill="#46566A" />
        <path class="eye-happy" d="M 617 378 Q 671 342 725 378" fill="none" stroke="#121B22" stroke-width="12" stroke-linecap="round" />
        <path class="eye-sleep" d="M 621 376 Q 671 400 721 376" fill="none" stroke="#121B22" stroke-width="12" stroke-linecap="round" />
      </g>
      <!-- Resting "smile" is the flat line George picked; open and o stay for the emotes. -->
      <path class="mouth smile" d="M 488 404 Q 512 410 536 402" fill="none" stroke="#121B22" stroke-width="10" stroke-linecap="round" />
      <path class="mouth open" d="M 464 392 Q 512 446 560 392" fill="none" stroke="#121B22" stroke-width="11" stroke-linecap="round" />
      <ellipse class="mouth o" cx="512" cy="408" rx="16" ry="18" fill="none" stroke="#121B22" stroke-width="9" />
      <path class="mouth flat" d="M 486 404 H 538" fill="none" stroke="#121B22" stroke-width="10" stroke-linecap="round" />
    </g>
    <g id="costume-face"></g>
  </g>
</svg>
`,r=`<svg id="axolotl" class="mascot-svg" viewBox="0 0 982 849" fill="none" overflow="visible" aria-hidden="true">
  <defs>
    <filter
      id="sprout-outline"
      x="-560"
      y="-400"
      width="2100"
      height="1520"
      filterUnits="userSpaceOnUse"
      primitiveUnits="userSpaceOnUse"
    >
      <feMorphology in="SourceAlpha" operator="dilate" radius="6" result="wide" />
      <feFlood flood-color="#F4FFFC" result="rim" />
      <feComposite in="rim" in2="wide" operator="in" result="outline" />
      <feMerge>
        <feMergeNode in="outline" />
        <feMergeNode in="SourceGraphic" />
      </feMerge>
    </filter>
    <!--
      Lumen (Sprout III) is drawn with radial gradients, NOT blur filters.
      It was filters first: a dilate+blur copy of the silhouette for the aura
      and three feGaussianBlurs for the belly, strands and sheen. Because his
      arms get a new transform every frame, the aura filter re-rasterised the
      whole character every frame — measured at 86ms per frame on its own,
      about 8fps against 30fps with it off. Gradients cost nothing to re-draw.
    -->
    <radialGradient id="lumen-aura-grad">
      <stop offset="0" stop-color="#D8FFEF" stop-opacity="0.42" />
      <stop offset="0.25" stop-color="#D8FFEF" stop-opacity="0.34" />
      <stop offset="0.45" stop-color="#D8FFEF" stop-opacity="0.24" />
      <stop offset="0.62" stop-color="#D8FFEF" stop-opacity="0.15" />
      <stop offset="0.78" stop-color="#D8FFEF" stop-opacity="0.07" />
      <stop offset="0.9" stop-color="#D8FFEF" stop-opacity="0.02" />
      <stop offset="1" stop-color="#D8FFEF" stop-opacity="0" />
    </radialGradient>
    <radialGradient id="lumen-soft-grad">
      <stop offset="0" stop-color="#EFFFF6" stop-opacity="0.9" />
      <stop offset="0.25" stop-color="#EFFFF6" stop-opacity="0.74" />
      <stop offset="0.45" stop-color="#EFFFF6" stop-opacity="0.5" />
      <stop offset="0.62" stop-color="#EFFFF6" stop-opacity="0.3" />
      <stop offset="0.78" stop-color="#EFFFF6" stop-opacity="0.14" />
      <stop offset="0.9" stop-color="#EFFFF6" stop-opacity="0.04" />
      <stop offset="1" stop-color="#EFFFF6" stop-opacity="0" />
    </radialGradient>
    <radialGradient id="lumen-hot-grad">
      <stop offset="0" stop-color="#FFFFFF" stop-opacity="0.8" />
      <stop offset="0.28" stop-color="#FFFFFF" stop-opacity="0.6" />
      <stop offset="0.5" stop-color="#FFFFFF" stop-opacity="0.36" />
      <stop offset="0.7" stop-color="#FFFFFF" stop-opacity="0.17" />
      <stop offset="0.87" stop-color="#FFFFFF" stop-opacity="0.05" />
      <stop offset="1" stop-color="#FFFFFF" stop-opacity="0" />
    </radialGradient>
    <radialGradient id="lumen-lamp" cx="0.5" cy="0.5" r="0.5">
      <stop offset="0" stop-color="#FFFFFF" />
      <stop id="lamp-pale" offset="0.34" stop-color="#B8EED4" />
      <stop id="lamp-chroma" offset="0.7" stop-color="#58CC9F" />
      <stop id="lamp-edge" offset="1" stop-color="#58CC9F" stop-opacity="0" />
    </radialGradient>
    <!-- Ninja II+: the arm guards are cropped to the long fin, so they follow its taper. -->
    <clipPath id="fin-l-clip"><use href="#fin-l" /></clipPath>
    <clipPath id="fin-r-clip"><use href="#fin-r" /></clipPath>
    <clipPath id="sprout-body-clip">
      <path
        d="M 512 94
           C 600 94 670 116 722 174
           C 774 232 830 338 854 458
           C 878 578 876 698 826 792
           C 786 850 640 850 512 850
           C 384 850 238 850 198 792
           C 148 698 146 578 170 458
           C 194 338 250 232 302 174
           C 354 116 424 94 512 94 Z"
      />
    </clipPath>
    <!--
      Rim for things held in a fin. #sprout-outline cannot be reused: its region is authored in
      BODY coordinates (x -320..1300), and a held item lives in arm-local space where the fin tip
      is already at x -441 — the katana fell straight outside it and vanished. This region is
      centred on the arm instead.
    -->
    <filter id="held-outline" x="-900" y="-760" width="1900" height="1620"
            filterUnits="userSpaceOnUse" primitiveUnits="userSpaceOnUse">
      <feMorphology in="SourceAlpha" operator="dilate" radius="6" result="wide" />
      <feFlood flood-color="#F4FFFC" result="rim" />
      <feComposite in="rim" in2="wide" operator="in" result="outline" />
      <feMerge><feMergeNode in="outline" /><feMergeNode in="SourceGraphic" /></feMerge>
    </filter>
  </defs>

  <g id="axolotl-root">
    <!--
      Tuft is outlined on its own so it does not melt into the crown
      and leave a lumpy head silhouette.
    -->
    <!--
      Lumen aura. Sized to cover the silhouette including the fins (they reach
      about x -130..1150), so the light reads as coming off all of him rather
      than tracing his edge.
    -->
    <ellipse id="lumen-aura" class="lumen" cx="512" cy="520" rx="720" ry="470" fill="url(#lumen-aura-grad)" />

    <!-- Gill fronds: three a side, behind the head, outlined on their own like Sail's lobes. -->
    <g id="gills" filter="url(#sprout-outline)">
      <path class="gill" fill="#EFA8B8" transform="translate(228 292) rotate(232)" d="M 0 0 C 44 -36, 102 -44, 151 -28 C 190 -36, 229 -20, 244 0 C 229 20, 190 36, 151 28 C 102 44, 44 36, 0 0 Z" />
      <path class="gill" fill="#EFA8B8" transform="translate(228 292) rotate(196)" d="M 0 0 C 48 -38, 113 -46, 166 -29 C 209 -38, 252 -21, 268 0 C 252 21, 209 38, 166 29 C 113 46, 48 38, 0 0 Z" />
      <path class="gill" fill="#EFA8B8" transform="translate(228 292) rotate(160)" d="M 0 0 C 43 -36, 101 -44, 149 -28 C 187 -36, 226 -20, 240 0 C 226 20, 187 36, 149 28 C 101 44, 43 36, 0 0 Z" />
      <path class="gill" fill="#EFA8B8" transform="translate(796 292) rotate(308)" d="M 0 0 C 44 -36, 102 -44, 151 -28 C 190 -36, 229 -20, 244 0 C 229 20, 190 36, 151 28 C 102 44, 44 36, 0 0 Z" />
      <path class="gill" fill="#EFA8B8" transform="translate(796 292) rotate(344)" d="M 0 0 C 48 -38, 113 -46, 166 -29 C 209 -38, 252 -21, 268 0 C 252 21, 209 38, 166 29 C 113 46, 48 38, 0 0 Z" />
      <path class="gill" fill="#EFA8B8" transform="translate(796 292) rotate(20)" d="M 0 0 C 43 -36, 101 -44, 149 -28 C 187 -36, 226 -20, 240 0 C 226 20, 187 36, 149 28 C 101 44, 43 36, 0 0 Z" />
    </g>

    <g id="sprout-silhouette" filter="url(#sprout-outline)">
      <g id="arm-l" transform="translate(318 452)">
        <path
          class="flipper sprout-fill suit wing-stub"
          fill="#58CC9F"
          d="M 68 0
             C 60 -24, 15 -54, -75 -82
             C -173 -110, -270 -64, -353 4
             C -396 42, -390 104, -323 116
             C -233 110, -143 68, -75 50
             C 15 30, 60 22, 68 0 Z"
        />
        <path
          id="fin-l"
          class="flipper sprout-fill suit wing-full"
          fill="#58CC9F"
          d="M 85 0
             C 75 -24, 19 -54, -94 -82
             C -216 -110, -338 -64, -441 4
             C -495 42, -488 104, -404 116
             C -291 110, -179 68, -94 50
             C 19 30, 75 22, 85 0 Z"
        />
        <!--
          Tekko: a red cuff on the forearm, bound at both hems, carrying the same
          plate as the headband. Cropped to the fin, so it follows the taper and
          rides every arm rotation.
        -->
        <g class="ninja-guard" display="none" clip-path="url(#fin-l-clip)">
          <path fill="#C43B3B"
                d="M -256 -196
                   C -282 -70, -286 60, -282 226
                   L -414 230
                   C -410 60, -414 -68, -388 -198 Z" />
          <path fill="#9E2F2F"
                d="M -256 -196
                   C -282 -70, -286 60, -282 226
                   L -302 227
                   C -306 60, -302 -70, -276 -197 Z" />
          <path fill="#9E2F2F"
                d="M -414 230
                   C -410 60, -414 -68, -388 -198
                   L -369 -199
                   C -395 -68, -391 60, -395 231 Z" />
          <g fill="none" stroke="#9E2F2F" stroke-width="6" opacity="0.85">
            <path d="M -315 -190 C -338 -70, -342 60, -338 226" />
            <path d="M -356 -194 C -378 -70, -382 60, -378 228" />
          </g>
          <path fill="#E05A5A"
                d="M -292 -104
                   C -320 -116, -352 -114, -378 -98
                   C -352 -84, -320 -86, -292 -74 Z" />
          <g transform="translate(-336 30) rotate(-13)">
            <rect x="-36" y="-22" width="72" height="44" rx="11" fill="#5F666E" />
            <rect x="-29" y="-16" width="58" height="29" rx="8" fill="#D4DAE0" />
            <circle cx="-21" cy="-7" r="3.1" fill="#3A4046" />
            <circle cx="21" cy="-7" r="3.1" fill="#3A4046" />
            <circle cx="-21" cy="8" r="3.1" fill="#3A4046" />
            <circle cx="21" cy="8" r="3.1" fill="#3A4046" />
          </g>
        </g>
        <g class="costume-arm-l"></g>
      </g>
      <g id="arm-r" transform="translate(706 452)">
        <path
          class="flipper sprout-fill suit wing-stub"
          fill="#58CC9F"
          d="M -68 0
             C -60 -24, -15 -54, 75 -82
             C 173 -110, 270 -64, 353 4
             C 396 42, 390 104, 323 116
             C 233 110, 143 68, 75 50
             C -15 30, -60 22, -68 0 Z"
        />
        <path
          id="fin-r"
          class="flipper sprout-fill suit wing-full"
          fill="#58CC9F"
          d="M -85 0
             C -75 -24, -19 -54, 94 -82
             C 216 -110, 338 -64, 441 4
             C 495 42, 488 104, 404 116
             C 291 110, 179 68, 94 50
             C -19 30, -75 22, -85 0 Z"
        />
        <!--
          Tekko: a red cuff on the forearm, bound at both hems, carrying the same
          plate as the headband. Cropped to the fin, so it follows the taper and
          rides every arm rotation.
        -->
        <g class="ninja-guard" display="none" clip-path="url(#fin-r-clip)">
          <path fill="#C43B3B"
                d="M 256 -196
                   C 282 -70, 286 60, 282 226
                   L 414 230
                   C 410 60, 414 -68, 388 -198 Z" />
          <path fill="#9E2F2F"
                d="M 256 -196
                   C 282 -70, 286 60, 282 226
                   L 302 227
                   C 306 60, 302 -70, 276 -197 Z" />
          <path fill="#9E2F2F"
                d="M 414 230
                   C 410 60, 414 -68, 388 -198
                   L 369 -199
                   C 395 -68, 391 60, 395 231 Z" />
          <g fill="none" stroke="#9E2F2F" stroke-width="6" opacity="0.85">
            <path d="M 315 -190 C 338 -70, 342 60, 338 226" />
            <path d="M 356 -194 C 378 -70, 382 60, 378 228" />
          </g>
          <path fill="#E05A5A"
                d="M 292 -104
                   C 320 -116, 352 -114, 378 -98
                   C 352 -84, 320 -86, 292 -74 Z" />
          <g transform="translate(336 30) rotate(13)">
            <rect x="-36" y="-22" width="72" height="44" rx="11" fill="#5F666E" />
            <rect x="-29" y="-16" width="58" height="29" rx="8" fill="#D4DAE0" />
            <circle cx="-21" cy="-7" r="3.1" fill="#3A4046" />
            <circle cx="21" cy="-7" r="3.1" fill="#3A4046" />
            <circle cx="-21" cy="8" r="3.1" fill="#3A4046" />
            <circle cx="21" cy="8" r="3.1" fill="#3A4046" />
          </g>
        </g>
        <g class="costume-arm-r"></g>
      </g>
      <path
        id="body"
        class="sprout-fill suit"
        fill="#58CC9F"
        d="M 512 94
           C 600 94 670 116 722 174
           C 774 232 830 338 854 458
           C 878 578 876 698 826 792
           C 786 850 640 850 512 850
           C 384 850 238 850 198 792
           C 148 698 146 578 170 458
           C 194 338 250 232 302 174
           C 354 116 424 94 512 94 Z"
      />
    </g>

    <!--
      Lumen (Sprout III). Halo sits under the belly so the light spills onto the
      body; the core sits over it. Puppet drives opacity and the halo pulse.
      Hidden unless the evolution has glow.
    -->
    <ellipse id="lumen-sheen" class="lumen" clip-path="url(#sprout-body-clip)" cx="756" cy="286" rx="150" ry="220" transform="rotate(-24 756 286)" fill="url(#lumen-hot-grad)" opacity="0.28" />
    <ellipse id="lumen-halo" class="lumen" cx="512" cy="655" rx="300" ry="184" fill="url(#lumen-soft-grad)" opacity="0.9" />
    <ellipse id="belly" cx="512" cy="655" rx="176" ry="92" fill="#B3EBD0" />

    <!--
      Stage III badge (George, 2026-09-04): the three-star reward is an emblem
      on the belly, one per coat, a shuriken for the Ninja. It replaced Lumen
      (the glow), whose layers are still here but never shown. The emblems are
      generated flat-illustration PNGs in \`public/badges/\`, each painted on its
      coat's belly tint so it can sit over \`#belly\` with no seam, clipped to
      the taller stage III belly. \`applyPalette\` / \`applySkin\` pick which shows.
    -->
    <clipPath id="badge-clip"><ellipse cx="512" cy="660" rx="182" ry="128" /></clipPath>
    <g id="badge" display="none" clip-path="url(#badge-clip)">
      <image id="badge-sapling" class="badge" display="none" href="badges/sapling.png" x="332" y="480" width="360" height="360" />
      <image id="badge-flame" class="badge" display="none" href="badges/flame.png" x="332" y="480" width="360" height="360" />
      <image id="badge-wave" class="badge" display="none" href="badges/wave.png" x="332" y="480" width="360" height="360" />
      <image id="badge-sun" class="badge" display="none" href="badges/sun.png" x="332" y="480" width="360" height="360" />
      <image id="badge-moon" class="badge" display="none" href="badges/moon.png" x="332" y="480" width="360" height="360" />
      <image id="badge-bolt" class="badge" display="none" href="badges/bolt.png" x="332" y="480" width="360" height="360" />
      <image id="badge-shuriken" class="badge" display="none" href="badges/shuriken.png" x="332" y="480" width="360" height="360" />
    </g>

    <!-- Stage III costume slots (costumes.ts pours markup in at load). Body clothing sits over the belly. -->
    <g id="costume-body"></g>
    <ellipse id="ninja-lamp" display="none" cx="512" cy="655" rx="198" ry="102" fill="url(#lumen-lamp)" />
    <ellipse id="lumen-core" class="lumen" cx="512" cy="655" rx="196" ry="104" fill="url(#lumen-soft-grad)" />
    <ellipse id="lumen-hot" class="lumen" cx="512" cy="655" rx="132" ry="66" fill="url(#lumen-hot-grad)" opacity="0.6" />

    <!--
      Ninja only. Clip keeps the mint eye-hole on the pear.
      Face sits on top of this strip. Hidden unless skin=ninja.
    -->
    <g id="ninja" class="no-flip" display="none">
      <rect
        id="eye-strip"
        x="188"
        y="298"
        width="648"
        height="154"
        rx="77"
        fill="#58CC9F"
        clip-path="url(#sprout-body-clip)"
      />

      <!--
        The band is stroked, not filled: one centreline with a uniform width, run
        well past the pear on both sides so \`#sprout-body-clip\` — not the path —
        decides where it ends. A filled path stopped short of the silhouette and
        left a notch at both corners of the head.
      -->
      <g id="headband">
        <g clip-path="url(#sprout-body-clip)" fill="none" stroke-linecap="butt">
          <path id="band" stroke="#C43B3B" stroke-width="62"
                d="M 108 289 C 288 231, 736 231, 916 289" />
          <path id="band-hem" stroke="#9E2F2F" stroke-width="12"
                d="M 108 313 C 288 255, 736 255, 916 313" />
          <path id="band-shine" stroke="#E05A5A" stroke-width="14"
                d="M 108 266 C 288 208, 736 208, 916 266" />
          <g id="plate" stroke="none">
            <rect x="455" y="221" width="114" height="50" rx="12" fill="#5F666E" />
            <rect x="463" y="228" width="98" height="33" rx="8" fill="#D4DAE0" />
            <circle cx="474" cy="236" r="3.7" fill="#3A4046" />
            <circle cx="550" cy="236" r="3.7" fill="#3A4046" />
            <circle cx="474" cy="253" r="3.7" fill="#3A4046" />
            <circle cx="550" cy="253" r="3.7" fill="#3A4046" />
          </g>
        </g>
        <g id="headband-tails" transform="translate(240 262)">
          <g filter="url(#sprout-outline)">
            <path
              fill="#C43B3B"
              d="M 6 2
                 C -16 -16, -58 -44, -108 -48
                 C -130 -50, -140 -24, -116 -12
                 C -88 2, -36 12, 10 12
                 Z"
            />
            <path
              fill="#C43B3B"
              d="M 8 10
                 C -14 30, -56 68, -94 102
                 C -114 118, -100 140, -74 122
                 C -42 100, -4 44, 12 16
                 Z"
            />
            <ellipse cx="8" cy="6" rx="16" ry="13" fill="#C43B3B" />
          </g>
          <path
            fill="#9E2F2F"
            d="M 0 2
               C -24 -10, -64 -28, -100 -30
               C -108 -30, -110 -22, -96 -18
               C -70 -12, -28 4, 4 8
               Z"
          />
          <path
            fill="#9E2F2F"
            d="M 2 12
               C -20 30, -56 64, -86 92
               C -94 100, -88 108, -74 98
               C -46 78, -10 36, 6 16
               Z"
          />
          <ellipse cx="6" cy="4" rx="9" ry="7" fill="#E05A5A" />
        </g>
      </g>
    </g>

    <!-- No tuft. The group stays so the puppet has its pivot. -->
    <g id="tuft" transform="translate(512 90)"></g>
    <!-- Lumen strands. Follows the tuft pivot; no rim so it sits inside the leaf outline. -->
    <g id="lumen-tuft" class="lumen" transform="translate(512 90)">
      <circle cx="18" cy="-38" r="70" fill="url(#lumen-soft-grad)" opacity="0.42" />
      <path fill="#EFFFF6" d="M 1 8 C 16 -10 36 -40 56 -56 C 68 -64 84 -52 76 -36 C 68 -18 30 4 6 14 Z" />
      <path fill="#EFFFF6" d="M -2 10 C -16 -4 -28 -28 -22 -46 C -18 -56 -2 -54 4 -40 C 10 -22 8 2 0 12 Z" />
    </g>

    <g id="costume-head"></g>
    <g id="face">
      <ellipse class="blush" cx="272" cy="430" rx="40" ry="20" fill="#EFA8B8" opacity="0.35" />
      <ellipse class="blush" cx="752" cy="430" rx="40" ry="20" fill="#EFA8B8" opacity="0.35" />

      <g id="eye-l">
        <circle class="eye-dot" cx="356" cy="378" r="46" fill="#121B22" />
        <path class="eye-happy" d="M 306 384 Q 356 350 406 384" fill="none" stroke="#121B22" stroke-width="12" stroke-linecap="round" />
        <path class="eye-sleep" d="M 310 382 Q 356 404 402 382" fill="none" stroke="#121B22" stroke-width="12" stroke-linecap="round" />
      </g>
      <g id="eye-r">
        <circle class="eye-dot" cx="667" cy="378" r="46" fill="#121B22" />
        <path class="eye-happy" d="M 617 384 Q 667 350 717 384" fill="none" stroke="#121B22" stroke-width="12" stroke-linecap="round" />
        <path class="eye-sleep" d="M 621 382 Q 667 404 713 382" fill="none" stroke="#121B22" stroke-width="12" stroke-linecap="round" />
      </g>
      <path class="mouth smile" d="M 490 406 Q 512 412 534 406" fill="none" stroke="#121B22" stroke-width="10" stroke-linecap="round" />
      <path class="mouth open" d="M 464 394 Q 512 446 560 394" fill="none" stroke="#121B22" stroke-width="11" stroke-linecap="round" />
      <ellipse class="mouth o" cx="512" cy="410" rx="16" ry="18" fill="none" stroke="#121B22" stroke-width="9" />
      <path class="mouth flat" d="M 488 406 H 536" fill="none" stroke="#121B22" stroke-width="10" stroke-linecap="round" />
    </g>
    <g id="costume-face"></g>
  </g>
</svg>
`,i=null,a=!1;function o(){return i||=new AudioContext,i}function s(){if(a)return;let e=o();e.state===`suspended`&&e.resume(),a=!0}function c(e,t,n,r=.045,i=0,a=0){let s=o(),c=s.currentTime+i,l=s.createOscillator(),u=s.createGain(),d=s.createBiquadFilter();d.type=`lowpass`,d.frequency.value=1400,l.type=n,l.frequency.setValueAtTime(e,c),a&&l.frequency.exponentialRampToValueAtTime(Math.max(40,e+a),c+t),u.gain.setValueAtTime(1e-4,c),u.gain.exponentialRampToValueAtTime(r,c+.03),u.gain.exponentialRampToValueAtTime(1e-4,c+t),l.connect(d),d.connect(u),u.connect(s.destination),l.start(c),l.stop(c+t+.02)}function l(e){if(a)try{e===`spin`?(c(420,.35,`sine`,.04,0,280),c(640,.28,`triangle`,.02,.08,180)):e===`happy`?(c(523,.16,`sine`,.05),c(784,.22,`sine`,.045,.12)):e===`wave`?(c(360,.2,`sine`,.03,0,80),c(300,.18,`triangle`,.02,.14,60)):e===`dazzle`?(c(880,.12,`triangle`,.04),c(1174,.14,`sine`,.035,.08),c(1568,.2,`sine`,.03,.16,-400)):e===`sleep`?(c(392,.28,`sine`,.03,0,-80),c(294,.4,`sine`,.025,.18,-60)):e===`wake`?(c(440,.12,`sine`,.03),c(660,.16,`sine`,.03,.08)):e===`love`?(c(523,.14,`sine`,.04),c(659,.18,`sine`,.035,.1),c(784,.22,`sine`,.03,.2)):e===`bounce`?(c(392,.1,`triangle`,.035,0,120),c(392,.1,`triangle`,.03,.28,120),c(392,.1,`triangle`,.03,.56,160)):e===`dance`?(c(330,.12,`triangle`,.03,0,40),c(392,.12,`triangle`,.028,.18,40),c(494,.16,`sine`,.03,.36,80)):e===`shy`?(c(349,.18,`sine`,.025,0,-40),c(294,.22,`sine`,.02,.16,30)):e===`surprise`?(c(880,.1,`square`,.025),c(1320,.16,`sine`,.03,.06,-200)):e===`stretch`?(c(262,.28,`sine`,.03,0,80),c(330,.3,`sine`,.025,.2,40)):e===`cheer`?(c(523,.1,`triangle`,.035),c(659,.12,`triangle`,.03,.16),c(784,.16,`sine`,.03,.3)):e===`pout`?(c(247,.28,`sine`,.03,0,-50),c(196,.32,`sine`,.022,.18,-30)):e===`curious`?(c(440,.12,`sine`,.028,0,60),c(494,.14,`sine`,.025,.2,-40),c(523,.16,`sine`,.025,.4,80)):e===`wiggle`&&(c(370,.08,`triangle`,.03,0,90),c(415,.08,`triangle`,.028,.1,-70),c(370,.1,`triangle`,.028,.2,110))}catch{}}var u=[{stage:1,roman:`I`,radius:72,belly:!0,blush:!0,markings:!1,extra:!1,wings:!1,glow:!1,badge:!1,costume:!1},{stage:2,roman:`II`,radius:86,belly:!0,blush:!0,markings:!1,extra:!1,wings:!0,glow:!1,badge:!1,costume:!1},{stage:3,roman:`III`,radius:100,belly:!0,blush:!0,markings:!1,extra:!1,wings:!0,glow:!1,badge:!1,costume:!0}],d=[{stage:1,roman:`I`,radius:44,belly:!1,blush:!1,markings:!1,extra:!1,wings:!1,glow:!1,badge:!1,costume:!1},{stage:2,roman:`II`,radius:58,belly:!0,blush:!1,markings:!0,extra:!1,wings:!0,glow:!1,badge:!1,costume:!1},{stage:3,roman:`III`,radius:72,belly:!0,blush:!0,markings:!0,extra:!0,wings:!0,glow:!1,badge:!1,costume:!1}];function f(e){return e===`sail`?d:u}var p=e=>e===`sprout`?`sprout-evo`:`sprout-evo-${e}`;function ee(e,t=`sprout`){let n=Number(e),r=f(t);return r.find(e=>e.stage===n)??r[2]}function te(e=`sprout`){try{return ee(localStorage.getItem(p(e)),e)}catch{return f(e)[2]}}function m(e,t=`sprout`){try{localStorage.setItem(p(t),String(e))}catch{}}function h(e,t){let n=e.querySelector(`#belly`);n&&(n.style.display=t.belly&&!t.glow?``:`none`),n?.setAttribute(`rx`,t.badge?`182`:`176`),n?.setAttribute(`ry`,t.badge?`128`:`92`);let r=e.querySelector(`#badge`);t.badge?r?.removeAttribute(`display`):r?.setAttribute(`display`,`none`);for(let n of e.querySelectorAll(`.blush`))n.style.display=t.blush?``:`none`;for(let n of e.querySelectorAll(`.lobe, .marking`))n.style.display=t.markings?``:`none`;for(let n of e.querySelectorAll(`.evo-full`))n.style.display=t.extra?``:`none`;for(let n of e.querySelectorAll(`.evo-stub`))n.style.display=t.extra?`none`:``;for(let n of e.querySelectorAll(`.wing-full`))n.style.display=t.wings?``:`none`;for(let n of e.querySelectorAll(`.wing-stub`))n.style.display=t.wings?`none`:``;for(let n of e.querySelectorAll(`.lumen`))n.style.display=t.glow?``:`none`}var g=[{id:`sprout`,name:`Sprout`,defaultPalette:`mint`,reach:{left:640,right:680,up:470,down:380}},{id:`sail`,name:`Sail`,defaultPalette:`sky`,reach:{left:400,right:430,up:360,down:400}},{id:`orca`,name:`Orca`,defaultPalette:`sky`,reach:{left:640,right:680,up:470,down:380}},{id:`axolotl`,name:`Axolotl`,defaultPalette:`lilac`,reach:{left:640,right:680,up:500,down:380}}],ne=`sprout-kind`;function re(e){return e===`keel`?g[1]:g.find(t=>t.id===e)??g[0]}function ie(){try{return re(localStorage.getItem(ne))}catch{return g[0]}}function ae(e){try{localStorage.setItem(ne,e)}catch{}}var _=[{id:`mint`,name:`Mint`,body:`#58CC9F`,belly:`#B8EED4`,blush:`#F4B3C0`,rim:`#F4FFFC`,accent:`#2f9d86`,stroke:`rgba(47, 157, 134, 0.22)`,badge:`sapling`},{id:`sky`,name:`Sky`,body:`#6BAFE0`,belly:`#D4EBF8`,blush:`#F3B5A6`,rim:`#F5FBFE`,accent:`#3d7eab`,stroke:`rgba(61, 126, 171, 0.22)`,badge:`wave`},{id:`peach`,name:`Peach`,body:`#E9A07C`,belly:`#F8E0D2`,blush:`#E07A90`,rim:`#FFF8F4`,accent:`#c46d4e`,stroke:`rgba(196, 109, 78, 0.22)`,badge:`sun`},{id:`lilac`,name:`Lilac`,body:`#B08EE0`,belly:`#E6D9F6`,blush:`#EFA8B8`,rim:`#FBF7FE`,accent:`#7d5aa8`,stroke:`rgba(125, 90, 168, 0.22)`,badge:`moon`},{id:`butter`,name:`Butter`,body:`#E4C45C`,belly:`#F6ECC4`,blush:`#E99286`,rim:`#FFFBF0`,accent:`#b8942e`,stroke:`rgba(184, 148, 46, 0.22)`,badge:`bolt`},{id:`coral`,name:`Coral`,body:`#E07A72`,belly:`#F6D4CE`,blush:`#D46A9A`,rim:`#FFF6F4`,accent:`#c45c56`,stroke:`rgba(196, 92, 86, 0.22)`,badge:`flame`}];function v(e,t){for(let n of e.querySelectorAll(`#badge .badge`))n.id===`badge-${t}`?n.removeAttribute(`display`):n.setAttribute(`display`,`none`)}var oe=`sprout-palette`;function se(e){return _.find(t=>t.id===e)??_[0]}function ce(e){return e===`sprout`?oe:`${oe}-${e}`}function le(e=`sprout`,t=`mint`){try{return se(localStorage.getItem(ce(e))??t)}catch{return se(t)}}function ue(e,t=`sprout`){try{localStorage.setItem(ce(t),e)}catch{}}function de(e,t,n=!0){for(let n of e.querySelectorAll(`.sprout-fill`))n.setAttribute(`fill`,t.body);e.querySelector(`#belly`)?.setAttribute(`fill`,t.belly);for(let n of e.querySelectorAll(`.blush`))n.setAttribute(`fill`,t.blush);for(let n of e.querySelectorAll(`.gill`))n.setAttribute(`fill`,t.blush);for(let n of e.querySelectorAll(`.marking`))n.setAttribute(`fill`,t.body);if(e.querySelector(`feFlood`)?.setAttribute(`flood-color`,t.rim),v(e,t.badge),!n)return;let r=document.documentElement;r.style.setProperty(`--mint`,t.accent),r.style.setProperty(`--stroke`,t.stroke)}var y={width:982,height:849,originX:491,originY:478,size:2.52,body:`#58CC9F`,face:`#0F181F`,eyeL:{x:352,y:371,r:52},eyeR:{x:671,y:371,r:52},mouth:{x:512,y:392,rx:44,ry:20},armL:{x:318,y:452},armR:{x:706,y:452},sprout:{x:512,y:90}};function fe(e,t){return e*y.size/y.height*t}var b=(e,t,n)=>Math.min(n,Math.max(t,e)),x=(e,t,n)=>e+(t-e)*n,S=(e,t,n,r)=>x(e,t,1-Math.exp(-n*r)),C=(e,t)=>e+Math.random()*(t-e),w=e=>1-(1-e)**3,pe=e=>e<.5?4*e*e*e:1-(-2*e+2)**3/2,me=e=>{let t=e-1;return 1+2.70158*t*t*t+1.70158*t*t},T=e=>b(e,0,1),he=[{id:`classic`,name:`Classic`},{id:`ninja`,name:`Ninja`}],ge=`#1C1F24`,_e=`#3A3F46`,ve={aura:`#D8FFEF`,halo:`#EFFFF6`,core:`#F4FFF9`,tuft:`#EFFFF6`},ye=`sprout-skin`;function be(e){return he.find(t=>t.id===e)??he[0]}function xe(){try{return be(localStorage.getItem(ye))}catch{return he[0]}}function Se(e){try{localStorage.setItem(ye,e)}catch{}}function Ce(e,t){e.querySelector(`#aura-flood`)?.setAttribute(`flood-color`,t.aura),e.querySelector(`#lumen-halo`)?.setAttribute(`fill`,t.halo),e.querySelector(`#lumen-core`)?.setAttribute(`fill`,t.core);for(let n of e.querySelectorAll(`#lumen-tuft path`))n.setAttribute(`fill`,t.tuft);e.querySelector(`#lumen-tuft circle`)?.setAttribute(`fill`,t.tuft)}function we(e,t){e.querySelector(`#lamp-pale`)?.setAttribute(`stop-color`,t.belly);for(let n of[`#lamp-chroma`,`#lamp-edge`])e.querySelector(n)?.setAttribute(`stop-color`,t.body)}function Te(e,t,n,r){let i=t.id===`ninja`,a=e.querySelector(`#ninja`);a&&(i?a.removeAttribute(`display`):a.setAttribute(`display`,`none`));for(let t of e.querySelectorAll(`.ninja-guard`))i&&r.wings?t.removeAttribute(`display`):t.setAttribute(`display`,`none`);let o=!r.glow||i?`none`:``;for(let t of[`#lumen-sheen`,`#lumen-hot`,`#lumen-core`,`#lumen-halo`])e.querySelector(t)?.style.setProperty(`display`,o);let s=e.querySelector(`#ninja-lamp`);if(i&&r.glow?s?.removeAttribute(`display`):s?.setAttribute(`display`,`none`),!i){for(let t of e.querySelectorAll(`.suit`))t.setAttribute(`fill`,n.body);e.querySelector(`#belly`)?.setAttribute(`fill`,n.belly),v(e,n.badge),Ce(e,ve);return}for(let t of e.querySelectorAll(`.suit`))t.setAttribute(`fill`,ge);v(e,`shuriken`),e.querySelector(`#eye-strip`)?.setAttribute(`fill`,n.body),e.querySelector(`#belly`)?.setAttribute(`fill`,r.glow?ge:_e),we(e,n),Ce(e,{aura:n.body,halo:ve.halo,core:ve.core,tuft:n.belly})}var Ee={scholar:{armL:`<g clip-path="url(#fin-l-clip)"><g transform="rotate(14.8969) translate(-318.000 -452.000)"><g transform="matrix(5.29290 -0.02185 0.02244 5.15547 -360.82989 -659.51934)"><image href="costumes/scholar-l.png" x="60.67" y="201.00" width="42.67" height="72.33" /></g></g></g>`,armR:`<g clip-path="url(#fin-r-clip)"><g transform="rotate(-11.1631) translate(-706.000 -452.000)"><g transform="matrix(5.29290 -0.02185 0.02244 5.15547 -360.82989 -659.51934)"><image href="costumes/scholar-r.png" x="224.67" y="201.00" width="41.00" height="67.00" /></g></g></g>`,face:`<g transform="matrix(5.29290 -0.02185 0.02244 5.15547 -360.82989 -659.51934)"><image href="costumes/scholar-top.png" x="76.00" y="140.00" width="172.33" height="163.00" /></g>`},hoodie:{armL:`<g clip-path="url(#fin-l-clip)"><g transform="rotate(5.1462) translate(-318.000 -452.000)"><g transform="matrix(5.12896 0.19200 -0.18531 5.31417 -287.74033 -754.10401)"><image href="costumes/hoodie-l.png" x="39.67" y="223.67" width="57.67" height="33.00" /></g></g></g>`,armR:`<g clip-path="url(#fin-r-clip)"><g transform="rotate(-8.4509) translate(-706.000 -452.000)"><g transform="matrix(5.12896 0.19200 -0.18531 5.31417 -287.74033 -754.10401)"><image href="costumes/hoodie-r.png" x="231.67" y="223.67" width="57.00" height="29.67" /></g></g></g>`,face:`<g transform="matrix(5.12896 0.19200 -0.18531 5.31417 -287.74033 -754.10401)"><image href="costumes/hoodie-top.png" x="45.00" y="70.33" width="241.33" height="228.00" /></g>`},baker:{armL:`<g clip-path="url(#fin-l-clip)"><g transform="rotate(19.0965) translate(-318.000 -452.000)"><g transform="matrix(5.29155 -0.16522 0.16971 5.15162 -392.49195 -614.01515)"><image href="costumes/baker-l.png" x="35.33" y="194.33" width="69.00" height="84.67" /></g></g></g>`,armR:`<g clip-path="url(#fin-r-clip)"><g transform="rotate(-18.7555) translate(-706.000 -452.000)"><g transform="matrix(5.29155 -0.16522 0.16971 5.15162 -392.49195 -614.01515)"><image href="costumes/baker-r.png" x="223.67" y="194.33" width="69.67" height="82.00" /></g></g></g>`,face:`<g transform="matrix(5.29155 -0.16522 0.16971 5.15162 -392.49195 -614.01515)"><image href="costumes/baker-top.png" x="83.00" y="120.33" width="155.33" height="199.33" /></g>`},astronaut:{armL:`<g clip-path="url(#fin-l-clip)"><g transform="rotate(15.7623) translate(-318.000 -452.000)"><g transform="matrix(5.24572 -0.19661 0.19858 5.19372 -392.03812 -634.07226)"><image href="costumes/astronaut-l.png" x="54.67" y="200.67" width="48.00" height="50.00" /></g></g></g>`,armR:`<g clip-path="url(#fin-r-clip)"><g transform="rotate(-17.6801) translate(-706.000 -452.000)"><g transform="matrix(5.24572 -0.19661 0.19858 5.19372 -392.03812 -634.07226)"><image href="costumes/astronaut-r.png" x="225.33" y="200.67" width="45.33" height="58.33" /></g></g></g>`,face:`<g transform="matrix(5.24572 -0.19661 0.19858 5.19372 -392.03812 -634.07226)"><image href="costumes/astronaut-top.png" x="93.33" y="182.00" width="141.67" height="111.00" /></g>`},racer:{armL:`<g clip-path="url(#fin-l-clip)"><g transform="rotate(16.5852) translate(-318.000 -452.000)"><g transform="matrix(5.30543 -0.04655 0.04802 5.14331 -368.42436 -645.07553)"><image href="costumes/racer-l.png" x="55.33" y="199.00" width="48.33" height="63.67" /></g></g></g>`,armR:`<g clip-path="url(#fin-r-clip)"><g transform="rotate(-12.8103) translate(-706.000 -452.000)"><g transform="matrix(5.30543 -0.04655 0.04802 5.14331 -368.42436 -645.07553)"><image href="costumes/racer-r.png" x="224.33" y="199.00" width="49.33" height="62.33" /></g></g></g>`,face:`<g transform="matrix(5.30543 -0.04655 0.04802 5.14331 -368.42436 -645.07553)"><image href="costumes/racer-top.png" x="95.33" y="113.33" width="137.00" height="168.00" /></g>`},biker:{armL:`<g clip-path="url(#fin-l-clip)"><g transform="rotate(6.2629) translate(-318.000 -452.000)"><g transform="matrix(5.12737 0.20156 -0.19443 5.31516 -285.72787 -747.52284)"><image href="costumes/biker-l.png" x="46.00" y="209.00" width="54.33" height="53.33" /></g></g></g>`,armR:`<g clip-path="url(#fin-r-clip)"><g transform="rotate(-9.9105) translate(-706.000 -452.000)"><g transform="matrix(5.12737 0.20156 -0.19443 5.31516 -285.72787 -747.52284)"><image href="costumes/biker-r.png" x="228.00" y="209.00" width="53.33" height="51.00" /></g></g></g>`,face:`<g transform="matrix(5.12737 0.20156 -0.19443 5.31516 -285.72787 -747.52284)"><image href="costumes/biker-top.png" x="80.00" y="170.67" width="176.00" height="114.00" /></g>`},pajamas:{armL:`<g clip-path="url(#fin-l-clip)"><g transform="rotate(4.9452) translate(-318.000 -452.000)"><g transform="matrix(5.12991 0.18943 -0.18289 5.31334 -288.38086 -755.16722)"><image href="costumes/pajamas-l.png" x="35.33" y="210.67" width="75.67" height="102.00" /></g></g></g>`,armR:`<g clip-path="url(#fin-r-clip)"><g transform="rotate(-8.1455) translate(-706.000 -452.000)"><g transform="matrix(5.12991 0.18943 -0.18289 5.31334 -288.38086 -755.16722)"><image href="costumes/pajamas-r.png" x="219.00" y="210.67" width="73.33" height="98.00" /></g></g></g>`,face:`<g transform="matrix(5.12991 0.18943 -0.18289 5.31334 -288.38086 -755.16722)"><image href="costumes/pajamas-top.png" x="35.00" y="151.33" width="257.67" height="168.33" /></g>`}},E={astronaut:{armL:`<image href="costumes/astronaut-cuff-l.png?v=20" x="-550" y="-200" width="1000" height="1000" />`,armR:`<image href="costumes/astronaut-cuff-r.png?v=20" x="-450" y="-200" width="1000" height="1000" />`,body:`<image href="costumes/astronaut-body.png?v=23" x="-193" y="13" width="1411" height="854" /><g clip-path="url(#sprout-body-clip)"><path d="M 120 378.0 L 144 378.0 L 168 382.0 L 192 390.4 L 216 398.1 L 240 405.3 L 264 411.8 L 288 417.7 L 312 423.1 L 336 427.8 L 360 431.9 L 384 435.4 L 408 438.3 L 432 440.6 L 456 442.4 L 480 443.5 L 504 444.0 L 528 443.9 L 552 443.2 L 576 441.9 L 600 439.9 L 624 437.4 L 648 434.3 L 672 430.6 L 696 426.3 L 720 421.3 L 744 415.8 L 768 409.7 L 792 402.9 L 816 395.6 L 840 387.7 L 864 379.1 L 888 378.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.05" /><path d="M 120 384.0 L 144 384.0 L 168 388.0 L 192 396.4 L 216 404.1 L 240 411.3 L 264 417.8 L 288 423.7 L 312 429.1 L 336 433.8 L 360 437.9 L 384 441.4 L 408 444.3 L 432 446.6 L 456 448.4 L 480 449.5 L 504 450.0 L 528 449.9 L 552 449.2 L 576 447.9 L 600 445.9 L 624 443.4 L 648 440.3 L 672 436.6 L 696 432.3 L 720 427.3 L 744 421.8 L 768 415.7 L 792 408.9 L 816 401.6 L 840 393.7 L 864 385.1 L 888 384.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.08" /><path d="M 120 390.0 L 144 390.0 L 168 394.0 L 192 402.4 L 216 410.1 L 240 417.3 L 264 423.8 L 288 429.7 L 312 435.1 L 336 439.8 L 360 443.9 L 384 447.4 L 408 450.3 L 432 452.6 L 456 454.4 L 480 455.5 L 504 456.0 L 528 455.9 L 552 455.2 L 576 453.9 L 600 451.9 L 624 449.4 L 648 446.3 L 672 442.6 L 696 438.3 L 720 433.3 L 744 427.8 L 768 421.7 L 792 414.9 L 816 407.6 L 840 399.7 L 864 391.1 L 888 390.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.11" /><path d="M 120 396.0 L 144 396.0 L 168 400.0 L 192 408.4 L 216 416.1 L 240 423.3 L 264 429.8 L 288 435.7 L 312 441.1 L 336 445.8 L 360 449.9 L 384 453.4 L 408 456.3 L 432 458.6 L 456 460.4 L 480 461.5 L 504 462.0 L 528 461.9 L 552 461.2 L 576 459.9 L 600 457.9 L 624 455.4 L 648 452.3 L 672 448.6 L 696 444.3 L 720 439.3 L 744 433.8 L 768 427.7 L 792 420.9 L 816 413.6 L 840 405.7 L 864 397.1 L 888 396.0" fill="none" stroke="#A1A4A8" stroke-width="15" stroke-linecap="round" /><path d="M 120 409.0 L 144 409.0 L 168 413.0 L 192 421.4 L 216 429.1 L 240 436.3 L 264 442.8 L 288 448.7 L 312 454.1 L 336 458.8 L 360 462.9 L 384 466.4 L 408 469.3 L 432 471.6 L 456 473.4 L 480 474.5 L 504 475.0 L 528 474.9 L 552 474.2 L 576 472.9 L 600 470.9 L 624 468.4 L 648 465.3 L 672 461.6 L 696 457.3 L 720 452.3 L 744 446.8 L 768 440.7 L 792 433.9 L 816 426.6 L 840 418.7 L 864 410.1 L 888 409.0" fill="none" stroke="#FFFFFF" stroke-width="8" stroke-linecap="round" opacity="0.75" /></g>`},scholar:{armL:`<image href="costumes/scholar-cuff-l.png?v=14" x="-550" y="-200" width="1000" height="1000" />`,armR:`<image href="costumes/scholar-cuff-r.png?v=14" x="-450" y="-200" width="1000" height="1000" />`,body:`<image href="costumes/scholar-body.png?v=23" x="-193" y="13" width="1411" height="854" /><g clip-path="url(#sprout-body-clip)"><path d="M 120 382.0 L 144 382.0 L 168 390.1 L 192 407.2 L 216 423.5 L 240 438.8 L 264 453.2 L 288 466.7 L 312 479.2 L 336 490.7 L 360 501.1 L 384 510.5 L 408 518.6 L 432 525.6 L 456 531.2 L 480 535.4 L 504 537.8 L 528 537.2 L 552 534.2 L 576 529.5 L 600 523.4 L 624 516.1 L 648 507.5 L 672 497.8 L 696 487.0 L 720 475.1 L 744 462.3 L 768 448.5 L 792 433.8 L 816 418.2 L 840 401.6 L 864 384.2 L 888 382.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.05" /><path d="M 120 388.0 L 144 388.0 L 168 396.1 L 192 413.2 L 216 429.5 L 240 444.8 L 264 459.2 L 288 472.7 L 312 485.2 L 336 496.7 L 360 507.1 L 384 516.5 L 408 524.6 L 432 531.6 L 456 537.2 L 480 541.4 L 504 543.8 L 528 543.2 L 552 540.2 L 576 535.5 L 600 529.4 L 624 522.1 L 648 513.5 L 672 503.8 L 696 493.0 L 720 481.1 L 744 468.3 L 768 454.5 L 792 439.8 L 816 424.2 L 840 407.6 L 864 390.2 L 888 388.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.08" /><path d="M 120 394.0 L 144 394.0 L 168 402.1 L 192 419.2 L 216 435.5 L 240 450.8 L 264 465.2 L 288 478.7 L 312 491.2 L 336 502.7 L 360 513.1 L 384 522.5 L 408 530.6 L 432 537.6 L 456 543.2 L 480 547.4 L 504 549.8 L 528 549.2 L 552 546.2 L 576 541.5 L 600 535.4 L 624 528.1 L 648 519.5 L 672 509.8 L 696 499.0 L 720 487.1 L 744 474.3 L 768 460.5 L 792 445.8 L 816 430.2 L 840 413.6 L 864 396.2 L 888 394.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.11" /><path d="M 120 400.0 L 144 400.0 L 168 408.1 L 192 425.2 L 216 441.5 L 240 456.8 L 264 471.2 L 288 484.7 L 312 497.2 L 336 508.7 L 360 519.1 L 384 528.5 L 408 536.6 L 432 543.6 L 456 549.2 L 480 553.4 L 504 555.8 L 528 555.2 L 552 552.2 L 576 547.5 L 600 541.4 L 624 534.1 L 648 525.5 L 672 515.8 L 696 505.0 L 720 493.1 L 744 480.3 L 768 466.5 L 792 451.8 L 816 436.2 L 840 419.6 L 864 402.2 L 888 400.0" fill="none" stroke="#1B3728" stroke-width="15" stroke-linecap="round" /><path d="M 120 413.0 L 144 413.0 L 168 421.1 L 192 438.2 L 216 454.5 L 240 469.8 L 264 484.2 L 288 497.7 L 312 510.2 L 336 521.7 L 360 532.1 L 384 541.5 L 408 549.6 L 432 556.6 L 456 562.2 L 480 566.4 L 504 568.8 L 528 568.2 L 552 565.2 L 576 560.5 L 600 554.4 L 624 547.1 L 648 538.5 L 672 528.8 L 696 518.0 L 720 506.1 L 744 493.3 L 768 479.5 L 792 464.8 L 816 449.2 L 840 432.6 L 864 415.2 L 888 413.0" fill="none" stroke="#3C6C51" stroke-width="8" stroke-linecap="round" opacity="0.75" /></g>`},hoodie:{armL:`<image href="costumes/hoodie-cuff-l.png?v=11" x="-550" y="-200" width="1000" height="1000" />`,armR:`<image href="costumes/hoodie-cuff-r.png?v=11" x="-450" y="-200" width="1000" height="1000" />`,body:`<image href="costumes/hoodie-body.png?v=23" x="-193" y="13" width="1411" height="854" /><g clip-path="url(#sprout-body-clip)"><path d="M 120 392.0 L 144 392.0 L 168 396.0 L 192 404.5 L 216 412.7 L 240 420.5 L 264 427.8 L 288 434.7 L 312 441.3 L 336 447.3 L 360 452.9 L 384 458.0 L 408 462.5 L 432 466.4 L 456 469.7 L 480 472.3 L 504 473.8 L 528 473.4 L 552 471.5 L 576 468.7 L 600 465.2 L 624 461.1 L 648 456.3 L 672 451.1 L 696 445.3 L 720 439.1 L 744 432.5 L 768 425.4 L 792 417.9 L 816 410.0 L 840 401.7 L 864 393.1 L 888 392.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.05" /><path d="M 120 398.0 L 144 398.0 L 168 402.0 L 192 410.5 L 216 418.7 L 240 426.5 L 264 433.8 L 288 440.7 L 312 447.3 L 336 453.3 L 360 458.9 L 384 464.0 L 408 468.5 L 432 472.4 L 456 475.7 L 480 478.3 L 504 479.8 L 528 479.4 L 552 477.5 L 576 474.7 L 600 471.2 L 624 467.1 L 648 462.3 L 672 457.1 L 696 451.3 L 720 445.1 L 744 438.5 L 768 431.4 L 792 423.9 L 816 416.0 L 840 407.7 L 864 399.1 L 888 398.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.08" /><path d="M 120 404.0 L 144 404.0 L 168 408.0 L 192 416.5 L 216 424.7 L 240 432.5 L 264 439.8 L 288 446.7 L 312 453.3 L 336 459.3 L 360 464.9 L 384 470.0 L 408 474.5 L 432 478.4 L 456 481.7 L 480 484.3 L 504 485.8 L 528 485.4 L 552 483.5 L 576 480.7 L 600 477.2 L 624 473.1 L 648 468.3 L 672 463.1 L 696 457.3 L 720 451.1 L 744 444.5 L 768 437.4 L 792 429.9 L 816 422.0 L 840 413.7 L 864 405.1 L 888 404.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.11" /><path d="M 120 410.0 L 144 410.0 L 168 414.0 L 192 422.5 L 216 430.7 L 240 438.5 L 264 445.8 L 288 452.7 L 312 459.3 L 336 465.3 L 360 470.9 L 384 476.0 L 408 480.5 L 432 484.4 L 456 487.7 L 480 490.3 L 504 491.8 L 528 491.4 L 552 489.5 L 576 486.7 L 600 483.2 L 624 479.1 L 648 474.3 L 672 469.1 L 696 463.3 L 720 457.1 L 744 450.5 L 768 443.4 L 792 435.9 L 816 428.0 L 840 419.7 L 864 411.1 L 888 410.0" fill="none" stroke="#7D3F2B" stroke-width="15" stroke-linecap="round" /><path d="M 120 423.0 L 144 423.0 L 168 427.0 L 192 435.5 L 216 443.7 L 240 451.5 L 264 458.8 L 288 465.7 L 312 472.3 L 336 478.3 L 360 483.9 L 384 489.0 L 408 493.5 L 432 497.4 L 456 500.7 L 480 503.3 L 504 504.8 L 528 504.4 L 552 502.5 L 576 499.7 L 600 496.2 L 624 492.1 L 648 487.3 L 672 482.1 L 696 476.3 L 720 470.1 L 744 463.5 L 768 456.4 L 792 448.9 L 816 441.0 L 840 432.7 L 864 424.1 L 888 423.0" fill="none" stroke="#E17A57" stroke-width="8" stroke-linecap="round" opacity="0.75" /></g>`},baker:{armL:`<image href="costumes/baker-cuff-l.png?v=4" x="-550" y="-200" width="1000" height="1000" />`,armR:`<image href="costumes/baker-cuff-r.png?v=4" x="-450" y="-200" width="1000" height="1000" />`,body:`<image href="costumes/baker-body.png?v=23" x="-193" y="13" width="1411" height="854" />`},flannel:{armL:`<image href="costumes/flannel-cuff-l.png?v=5" x="-550" y="-200" width="1000" height="1000" />`,armR:`<image href="costumes/flannel-cuff-r.png?v=5" x="-450" y="-200" width="1000" height="1000" />`,body:`<image href="costumes/flannel-body.png?v=23" x="-193" y="13" width="1411" height="854" /><g clip-path="url(#sprout-body-clip)"><path d="M 120 382.0 L 144 382.0 L 168 390.1 L 192 407.2 L 216 423.5 L 240 438.8 L 264 453.2 L 288 466.7 L 312 479.2 L 336 490.7 L 360 501.1 L 384 510.5 L 408 518.6 L 432 525.6 L 456 531.2 L 480 535.4 L 504 537.8 L 528 537.2 L 552 534.2 L 576 529.5 L 600 523.4 L 624 516.1 L 648 507.5 L 672 497.8 L 696 487.0 L 720 475.1 L 744 462.3 L 768 448.5 L 792 433.8 L 816 418.2 L 840 401.6 L 864 384.2 L 888 382.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.05" /><path d="M 120 388.0 L 144 388.0 L 168 396.1 L 192 413.2 L 216 429.5 L 240 444.8 L 264 459.2 L 288 472.7 L 312 485.2 L 336 496.7 L 360 507.1 L 384 516.5 L 408 524.6 L 432 531.6 L 456 537.2 L 480 541.4 L 504 543.8 L 528 543.2 L 552 540.2 L 576 535.5 L 600 529.4 L 624 522.1 L 648 513.5 L 672 503.8 L 696 493.0 L 720 481.1 L 744 468.3 L 768 454.5 L 792 439.8 L 816 424.2 L 840 407.6 L 864 390.2 L 888 388.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.08" /><path d="M 120 394.0 L 144 394.0 L 168 402.1 L 192 419.2 L 216 435.5 L 240 450.8 L 264 465.2 L 288 478.7 L 312 491.2 L 336 502.7 L 360 513.1 L 384 522.5 L 408 530.6 L 432 537.6 L 456 543.2 L 480 547.4 L 504 549.8 L 528 549.2 L 552 546.2 L 576 541.5 L 600 535.4 L 624 528.1 L 648 519.5 L 672 509.8 L 696 499.0 L 720 487.1 L 744 474.3 L 768 460.5 L 792 445.8 L 816 430.2 L 840 413.6 L 864 396.2 L 888 394.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.11" /><path d="M 120 400.0 L 144 400.0 L 168 408.1 L 192 425.2 L 216 441.5 L 240 456.8 L 264 471.2 L 288 484.7 L 312 497.2 L 336 508.7 L 360 519.1 L 384 528.5 L 408 536.6 L 432 543.6 L 456 549.2 L 480 553.4 L 504 555.8 L 528 555.2 L 552 552.2 L 576 547.5 L 600 541.4 L 624 534.1 L 648 525.5 L 672 515.8 L 696 505.0 L 720 493.1 L 744 480.3 L 768 466.5 L 792 451.8 L 816 436.2 L 840 419.6 L 864 402.2 L 888 400.0" fill="none" stroke="#480E0B" stroke-width="15" stroke-linecap="round" /><path d="M 120 413.0 L 144 413.0 L 168 421.1 L 192 438.2 L 216 454.5 L 240 469.8 L 264 484.2 L 288 497.7 L 312 510.2 L 336 521.7 L 360 532.1 L 384 541.5 L 408 549.6 L 432 556.6 L 456 562.2 L 480 566.4 L 504 568.8 L 528 568.2 L 552 565.2 L 576 560.5 L 600 554.4 L 624 547.1 L 648 538.5 L 672 528.8 L 696 518.0 L 720 506.1 L 744 493.3 L 768 479.5 L 792 464.8 L 816 449.2 L 840 432.6 L 864 415.2 L 888 413.0" fill="none" stroke="#892621" stroke-width="8" stroke-linecap="round" opacity="0.75" /></g>`},happi:{armL:`<image href="costumes/happi-cuff-l.png?v=7" x="-550" y="-200" width="1000" height="1000" />`,armR:`<image href="costumes/happi-cuff-r.png?v=7" x="-450" y="-200" width="1000" height="1000" />`,body:`<image href="costumes/happi-body.png?v=23" x="-193" y="13" width="1411" height="854" /><g clip-path="url(#sprout-body-clip)"><path d="M 120 374.0 L 144 374.0 L 168 380.5 L 192 394.5 L 216 407.9 L 240 420.8 L 264 433.1 L 288 444.8 L 312 456.0 L 336 466.4 L 360 476.2 L 384 485.3 L 408 493.5 L 432 500.8 L 456 507.1 L 480 512.2 L 504 515.5 L 528 514.6 L 552 510.6 L 576 505.1 L 600 498.5 L 624 490.8 L 648 482.3 L 672 473.0 L 696 463.0 L 720 452.3 L 744 441.0 L 768 429.0 L 792 416.5 L 816 403.5 L 840 389.9 L 864 375.8 L 888 374.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.05" /><path d="M 120 380.0 L 144 380.0 L 168 386.5 L 192 400.5 L 216 413.9 L 240 426.8 L 264 439.1 L 288 450.8 L 312 462.0 L 336 472.4 L 360 482.2 L 384 491.3 L 408 499.5 L 432 506.8 L 456 513.1 L 480 518.2 L 504 521.5 L 528 520.6 L 552 516.6 L 576 511.1 L 600 504.5 L 624 496.8 L 648 488.3 L 672 479.0 L 696 469.0 L 720 458.3 L 744 447.0 L 768 435.0 L 792 422.5 L 816 409.5 L 840 395.9 L 864 381.8 L 888 380.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.08" /><path d="M 120 386.0 L 144 386.0 L 168 392.5 L 192 406.5 L 216 419.9 L 240 432.8 L 264 445.1 L 288 456.8 L 312 468.0 L 336 478.4 L 360 488.2 L 384 497.3 L 408 505.5 L 432 512.8 L 456 519.1 L 480 524.2 L 504 527.5 L 528 526.6 L 552 522.6 L 576 517.1 L 600 510.5 L 624 502.8 L 648 494.3 L 672 485.0 L 696 475.0 L 720 464.3 L 744 453.0 L 768 441.0 L 792 428.5 L 816 415.5 L 840 401.9 L 864 387.8 L 888 386.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.11" /><path d="M 120 392.0 L 144 392.0 L 168 398.5 L 192 412.5 L 216 425.9 L 240 438.8 L 264 451.1 L 288 462.8 L 312 474.0 L 336 484.4 L 360 494.2 L 384 503.3 L 408 511.5 L 432 518.8 L 456 525.1 L 480 530.2 L 504 533.5 L 528 532.6 L 552 528.6 L 576 523.1 L 600 516.5 L 624 508.8 L 648 500.3 L 672 491.0 L 696 481.0 L 720 470.3 L 744 459.0 L 768 447.0 L 792 434.5 L 816 421.5 L 840 407.9 L 864 393.8 L 888 392.0" fill="none" stroke="#AFAAA3" stroke-width="15" stroke-linecap="round" /><path d="M 120 405.0 L 144 405.0 L 168 411.5 L 192 425.5 L 216 438.9 L 240 451.8 L 264 464.1 L 288 475.8 L 312 487.0 L 336 497.4 L 360 507.2 L 384 516.3 L 408 524.5 L 432 531.8 L 456 538.1 L 480 543.2 L 504 546.5 L 528 545.6 L 552 541.6 L 576 536.1 L 600 529.5 L 624 521.8 L 648 513.3 L 672 504.0 L 696 494.0 L 720 483.3 L 744 472.0 L 768 460.0 L 792 447.5 L 816 434.5 L 840 420.9 L 864 406.8 L 888 405.0" fill="none" stroke="#FFFFFF" stroke-width="8" stroke-linecap="round" opacity="0.75" /></g>`},varsity:{armL:`<image href="costumes/varsity-cuff-l.png?v=6" x="-550" y="-200" width="1000" height="1000" />`,armR:`<image href="costumes/varsity-cuff-r.png?v=6" x="-450" y="-200" width="1000" height="1000" />`,body:`<image href="costumes/varsity-body.png?v=23" x="-193" y="13" width="1411" height="854" /><g clip-path="url(#sprout-body-clip)"><path d="M 120 386.0 L 144 386.0 L 168 392.5 L 192 406.0 L 216 418.7 L 240 430.5 L 264 441.3 L 288 451.3 L 312 460.4 L 336 468.5 L 360 475.6 L 384 481.9 L 408 487.1 L 432 491.4 L 456 494.6 L 480 496.8 L 504 497.9 L 528 497.7 L 552 496.2 L 576 493.7 L 600 490.1 L 624 485.5 L 648 479.9 L 672 473.4 L 696 465.9 L 720 457.4 L 744 448.1 L 768 437.8 L 792 426.7 L 816 414.6 L 840 401.6 L 864 387.8 L 888 386.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.05" /><path d="M 120 392.0 L 144 392.0 L 168 398.5 L 192 412.0 L 216 424.7 L 240 436.5 L 264 447.3 L 288 457.3 L 312 466.4 L 336 474.5 L 360 481.6 L 384 487.9 L 408 493.1 L 432 497.4 L 456 500.6 L 480 502.8 L 504 503.9 L 528 503.7 L 552 502.2 L 576 499.7 L 600 496.1 L 624 491.5 L 648 485.9 L 672 479.4 L 696 471.9 L 720 463.4 L 744 454.1 L 768 443.8 L 792 432.7 L 816 420.6 L 840 407.6 L 864 393.8 L 888 392.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.08" /><path d="M 120 398.0 L 144 398.0 L 168 404.5 L 192 418.0 L 216 430.7 L 240 442.5 L 264 453.3 L 288 463.3 L 312 472.4 L 336 480.5 L 360 487.6 L 384 493.9 L 408 499.1 L 432 503.4 L 456 506.6 L 480 508.8 L 504 509.9 L 528 509.7 L 552 508.2 L 576 505.7 L 600 502.1 L 624 497.5 L 648 491.9 L 672 485.4 L 696 477.9 L 720 469.4 L 744 460.1 L 768 449.8 L 792 438.7 L 816 426.6 L 840 413.6 L 864 399.8 L 888 398.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.11" /><path d="M 120 404.0 L 144 404.0 L 168 410.5 L 192 424.0 L 216 436.7 L 240 448.5 L 264 459.3 L 288 469.3 L 312 478.4 L 336 486.5 L 360 493.6 L 384 499.9 L 408 505.1 L 432 509.4 L 456 512.6 L 480 514.8 L 504 515.9 L 528 515.7 L 552 514.2 L 576 511.7 L 600 508.1 L 624 503.5 L 648 497.9 L 672 491.4 L 696 483.9 L 720 475.4 L 744 466.1 L 768 455.8 L 792 444.7 L 816 432.6 L 840 419.6 L 864 405.8 L 888 404.0" fill="none" stroke="#ADA497" stroke-width="15" stroke-linecap="round" /><path d="M 120 417.0 L 144 417.0 L 168 423.5 L 192 437.0 L 216 449.7 L 240 461.5 L 264 472.3 L 288 482.3 L 312 491.4 L 336 499.5 L 360 506.6 L 384 512.9 L 408 518.1 L 432 522.4 L 456 525.6 L 480 527.8 L 504 528.9 L 528 528.7 L 552 527.2 L 576 524.7 L 600 521.1 L 624 516.5 L 648 510.9 L 672 504.4 L 696 496.9 L 720 488.4 L 744 479.1 L 768 468.8 L 792 457.7 L 816 445.6 L 840 432.6 L 864 418.8 L 888 417.0" fill="none" stroke="#FFFFFF" stroke-width="8" stroke-linecap="round" opacity="0.75" /></g>`},racer:{armL:`<image href="costumes/racer-cuff-l.png?v=3" x="-550" y="-200" width="1000" height="1000" />`,armR:`<image href="costumes/racer-cuff-r.png?v=3" x="-450" y="-200" width="1000" height="1000" />`,body:`<image href="costumes/racer-body.png?v=23" x="-193" y="13" width="1411" height="854" /><g clip-path="url(#sprout-body-clip)"><path d="M 120 386.0 L 144 386.0 L 168 392.5 L 192 406.0 L 216 418.7 L 240 430.5 L 264 441.3 L 288 451.3 L 312 460.4 L 336 468.5 L 360 475.6 L 384 481.9 L 408 487.1 L 432 491.4 L 456 494.6 L 480 496.8 L 504 497.9 L 528 497.7 L 552 496.2 L 576 493.7 L 600 490.1 L 624 485.5 L 648 479.9 L 672 473.4 L 696 465.9 L 720 457.4 L 744 448.1 L 768 437.8 L 792 426.7 L 816 414.6 L 840 401.6 L 864 387.8 L 888 386.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.05" /><path d="M 120 392.0 L 144 392.0 L 168 398.5 L 192 412.0 L 216 424.7 L 240 436.5 L 264 447.3 L 288 457.3 L 312 466.4 L 336 474.5 L 360 481.6 L 384 487.9 L 408 493.1 L 432 497.4 L 456 500.6 L 480 502.8 L 504 503.9 L 528 503.7 L 552 502.2 L 576 499.7 L 600 496.1 L 624 491.5 L 648 485.9 L 672 479.4 L 696 471.9 L 720 463.4 L 744 454.1 L 768 443.8 L 792 432.7 L 816 420.6 L 840 407.6 L 864 393.8 L 888 392.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.08" /><path d="M 120 398.0 L 144 398.0 L 168 404.5 L 192 418.0 L 216 430.7 L 240 442.5 L 264 453.3 L 288 463.3 L 312 472.4 L 336 480.5 L 360 487.6 L 384 493.9 L 408 499.1 L 432 503.4 L 456 506.6 L 480 508.8 L 504 509.9 L 528 509.7 L 552 508.2 L 576 505.7 L 600 502.1 L 624 497.5 L 648 491.9 L 672 485.4 L 696 477.9 L 720 469.4 L 744 460.1 L 768 449.8 L 792 438.7 L 816 426.6 L 840 413.6 L 864 399.8 L 888 398.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.11" /><path d="M 120 404.0 L 144 404.0 L 168 410.5 L 192 424.0 L 216 436.7 L 240 448.5 L 264 459.3 L 288 469.3 L 312 478.4 L 336 486.5 L 360 493.6 L 384 499.9 L 408 505.1 L 432 509.4 L 456 512.6 L 480 514.8 L 504 515.9 L 528 515.7 L 552 514.2 L 576 511.7 L 600 508.1 L 624 503.5 L 648 497.9 L 672 491.4 L 696 483.9 L 720 475.4 L 744 466.1 L 768 455.8 L 792 444.7 L 816 432.6 L 840 419.6 L 864 405.8 L 888 404.0" fill="none" stroke="#1B2540" stroke-width="15" stroke-linecap="round" /><path d="M 120 417.0 L 144 417.0 L 168 423.5 L 192 437.0 L 216 449.7 L 240 461.5 L 264 472.3 L 288 482.3 L 312 491.4 L 336 499.5 L 360 506.6 L 384 512.9 L 408 518.1 L 432 522.4 L 456 525.6 L 480 527.8 L 504 528.9 L 528 528.7 L 552 527.2 L 576 524.7 L 600 521.1 L 624 516.5 L 648 510.9 L 672 504.4 L 696 496.9 L 720 488.4 L 744 479.1 L 768 468.8 L 792 457.7 L 816 445.6 L 840 432.6 L 864 418.8 L 888 417.0" fill="none" stroke="#3D4D7B" stroke-width="8" stroke-linecap="round" opacity="0.75" /></g>`},biker:{armL:`<image href="costumes/biker-cuff-l.png?v=3" x="-550" y="-200" width="1000" height="1000" />`,armR:`<image href="costumes/biker-cuff-r.png?v=3" x="-450" y="-200" width="1000" height="1000" />`,body:`<image href="costumes/biker-body.png?v=23" x="-193" y="13" width="1411" height="854" /><g clip-path="url(#sprout-body-clip)"><path d="M 120 382.0 L 144 382.0 L 168 390.1 L 192 407.2 L 216 423.5 L 240 438.8 L 264 453.2 L 288 466.7 L 312 479.2 L 336 490.7 L 360 501.1 L 384 510.5 L 408 518.6 L 432 525.6 L 456 531.2 L 480 535.4 L 504 537.8 L 528 537.2 L 552 534.2 L 576 529.5 L 600 523.4 L 624 516.1 L 648 507.5 L 672 497.8 L 696 487.0 L 720 475.1 L 744 462.3 L 768 448.5 L 792 433.8 L 816 418.2 L 840 401.6 L 864 384.2 L 888 382.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.05" /><path d="M 120 388.0 L 144 388.0 L 168 396.1 L 192 413.2 L 216 429.5 L 240 444.8 L 264 459.2 L 288 472.7 L 312 485.2 L 336 496.7 L 360 507.1 L 384 516.5 L 408 524.6 L 432 531.6 L 456 537.2 L 480 541.4 L 504 543.8 L 528 543.2 L 552 540.2 L 576 535.5 L 600 529.4 L 624 522.1 L 648 513.5 L 672 503.8 L 696 493.0 L 720 481.1 L 744 468.3 L 768 454.5 L 792 439.8 L 816 424.2 L 840 407.6 L 864 390.2 L 888 388.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.08" /><path d="M 120 394.0 L 144 394.0 L 168 402.1 L 192 419.2 L 216 435.5 L 240 450.8 L 264 465.2 L 288 478.7 L 312 491.2 L 336 502.7 L 360 513.1 L 384 522.5 L 408 530.6 L 432 537.6 L 456 543.2 L 480 547.4 L 504 549.8 L 528 549.2 L 552 546.2 L 576 541.5 L 600 535.4 L 624 528.1 L 648 519.5 L 672 509.8 L 696 499.0 L 720 487.1 L 744 474.3 L 768 460.5 L 792 445.8 L 816 430.2 L 840 413.6 L 864 396.2 L 888 394.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.11" /><path d="M 120 400.0 L 144 400.0 L 168 408.1 L 192 425.2 L 216 441.5 L 240 456.8 L 264 471.2 L 288 484.7 L 312 497.2 L 336 508.7 L 360 519.1 L 384 528.5 L 408 536.6 L 432 543.6 L 456 549.2 L 480 553.4 L 504 555.8 L 528 555.2 L 552 552.2 L 576 547.5 L 600 541.4 L 624 534.1 L 648 525.5 L 672 515.8 L 696 505.0 L 720 493.1 L 744 480.3 L 768 466.5 L 792 451.8 L 816 436.2 L 840 419.6 L 864 402.2 L 888 400.0" fill="none" stroke="#1A1A1E" stroke-width="15" stroke-linecap="round" /><path d="M 120 413.0 L 144 413.0 L 168 421.1 L 192 438.2 L 216 454.5 L 240 469.8 L 264 484.2 L 288 497.7 L 312 510.2 L 336 521.7 L 360 532.1 L 384 541.5 L 408 549.6 L 432 556.6 L 456 562.2 L 480 566.4 L 504 568.8 L 528 568.2 L 552 565.2 L 576 560.5 L 600 554.4 L 624 547.1 L 648 538.5 L 672 528.8 L 696 518.0 L 720 506.1 L 744 493.3 L 768 479.5 L 792 464.8 L 816 449.2 L 840 432.6 L 864 415.2 L 888 413.0" fill="none" stroke="#3B3A40" stroke-width="8" stroke-linecap="round" opacity="0.75" /></g>`},pajamas:{armL:`<image href="costumes/pajamas-cuff-l.png?v=3" x="-550" y="-200" width="1000" height="1000" />`,armR:`<image href="costumes/pajamas-cuff-r.png?v=3" x="-450" y="-200" width="1000" height="1000" />`,body:`<image href="costumes/pajamas-body.png?v=23" x="-193" y="13" width="1411" height="854" /><g clip-path="url(#sprout-body-clip)"><path d="M 120 386.0 L 144 386.0 L 168 392.5 L 192 406.0 L 216 418.7 L 240 430.5 L 264 441.3 L 288 451.3 L 312 460.4 L 336 468.5 L 360 475.6 L 384 481.9 L 408 487.1 L 432 491.4 L 456 494.6 L 480 496.8 L 504 497.9 L 528 497.7 L 552 496.2 L 576 493.7 L 600 490.1 L 624 485.5 L 648 479.9 L 672 473.4 L 696 465.9 L 720 457.4 L 744 448.1 L 768 437.8 L 792 426.7 L 816 414.6 L 840 401.6 L 864 387.8 L 888 386.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.05" /><path d="M 120 392.0 L 144 392.0 L 168 398.5 L 192 412.0 L 216 424.7 L 240 436.5 L 264 447.3 L 288 457.3 L 312 466.4 L 336 474.5 L 360 481.6 L 384 487.9 L 408 493.1 L 432 497.4 L 456 500.6 L 480 502.8 L 504 503.9 L 528 503.7 L 552 502.2 L 576 499.7 L 600 496.1 L 624 491.5 L 648 485.9 L 672 479.4 L 696 471.9 L 720 463.4 L 744 454.1 L 768 443.8 L 792 432.7 L 816 420.6 L 840 407.6 L 864 393.8 L 888 392.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.08" /><path d="M 120 398.0 L 144 398.0 L 168 404.5 L 192 418.0 L 216 430.7 L 240 442.5 L 264 453.3 L 288 463.3 L 312 472.4 L 336 480.5 L 360 487.6 L 384 493.9 L 408 499.1 L 432 503.4 L 456 506.6 L 480 508.8 L 504 509.9 L 528 509.7 L 552 508.2 L 576 505.7 L 600 502.1 L 624 497.5 L 648 491.9 L 672 485.4 L 696 477.9 L 720 469.4 L 744 460.1 L 768 449.8 L 792 438.7 L 816 426.6 L 840 413.6 L 864 399.8 L 888 398.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.11" /><path d="M 120 404.0 L 144 404.0 L 168 410.5 L 192 424.0 L 216 436.7 L 240 448.5 L 264 459.3 L 288 469.3 L 312 478.4 L 336 486.5 L 360 493.6 L 384 499.9 L 408 505.1 L 432 509.4 L 456 512.6 L 480 514.8 L 504 515.9 L 528 515.7 L 552 514.2 L 576 511.7 L 600 508.1 L 624 503.5 L 648 497.9 L 672 491.4 L 696 483.9 L 720 475.4 L 744 466.1 L 768 455.8 L 792 444.7 L 816 432.6 L 840 419.6 L 864 405.8 L 888 404.0" fill="none" stroke="#AFA69D" stroke-width="15" stroke-linecap="round" /><path d="M 120 417.0 L 144 417.0 L 168 423.5 L 192 437.0 L 216 449.7 L 240 461.5 L 264 472.3 L 288 482.3 L 312 491.4 L 336 499.5 L 360 506.6 L 384 512.9 L 408 518.1 L 432 522.4 L 456 525.6 L 480 527.8 L 504 528.9 L 528 528.7 L 552 527.2 L 576 524.7 L 600 521.1 L 624 516.5 L 648 510.9 L 672 504.4 L 696 496.9 L 720 488.4 L 744 479.1 L 768 468.8 L 792 457.7 L 816 445.6 L 840 432.6 L 864 418.8 L 888 417.0" fill="none" stroke="#FFFFFF" stroke-width="8" stroke-linecap="round" opacity="0.75" /></g>`},sorcerer:{armL:`<image href="costumes/sorcerer-cuff-l.png?v=3" x="-550" y="-200" width="1000" height="1000" />`,armR:`<image href="costumes/sorcerer-cuff-r.png?v=3" x="-450" y="-200" width="1000" height="1000" />`,body:`<image href="costumes/sorcerer-body.png?v=23" x="-193" y="13" width="1411" height="854" /><g clip-path="url(#sprout-body-clip)"><path d="M 120 374.0 L 144 374.0 L 168 380.5 L 192 394.5 L 216 407.9 L 240 420.8 L 264 433.1 L 288 444.8 L 312 456.0 L 336 466.4 L 360 476.2 L 384 485.3 L 408 493.5 L 432 500.8 L 456 507.1 L 480 512.2 L 504 515.5 L 528 514.6 L 552 510.6 L 576 505.1 L 600 498.5 L 624 490.8 L 648 482.3 L 672 473.0 L 696 463.0 L 720 452.3 L 744 441.0 L 768 429.0 L 792 416.5 L 816 403.5 L 840 389.9 L 864 375.8 L 888 374.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.05" /><path d="M 120 380.0 L 144 380.0 L 168 386.5 L 192 400.5 L 216 413.9 L 240 426.8 L 264 439.1 L 288 450.8 L 312 462.0 L 336 472.4 L 360 482.2 L 384 491.3 L 408 499.5 L 432 506.8 L 456 513.1 L 480 518.2 L 504 521.5 L 528 520.6 L 552 516.6 L 576 511.1 L 600 504.5 L 624 496.8 L 648 488.3 L 672 479.0 L 696 469.0 L 720 458.3 L 744 447.0 L 768 435.0 L 792 422.5 L 816 409.5 L 840 395.9 L 864 381.8 L 888 380.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.08" /><path d="M 120 386.0 L 144 386.0 L 168 392.5 L 192 406.5 L 216 419.9 L 240 432.8 L 264 445.1 L 288 456.8 L 312 468.0 L 336 478.4 L 360 488.2 L 384 497.3 L 408 505.5 L 432 512.8 L 456 519.1 L 480 524.2 L 504 527.5 L 528 526.6 L 552 522.6 L 576 517.1 L 600 510.5 L 624 502.8 L 648 494.3 L 672 485.0 L 696 475.0 L 720 464.3 L 744 453.0 L 768 441.0 L 792 428.5 L 816 415.5 L 840 401.9 L 864 387.8 L 888 386.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.11" /><path d="M 120 392.0 L 144 392.0 L 168 398.5 L 192 412.5 L 216 425.9 L 240 438.8 L 264 451.1 L 288 462.8 L 312 474.0 L 336 484.4 L 360 494.2 L 384 503.3 L 408 511.5 L 432 518.8 L 456 525.1 L 480 530.2 L 504 533.5 L 528 532.6 L 552 528.6 L 576 523.1 L 600 516.5 L 624 508.8 L 648 500.3 L 672 491.0 L 696 481.0 L 720 470.3 L 744 459.0 L 768 447.0 L 792 434.5 L 816 421.5 L 840 407.9 L 864 393.8 L 888 392.0" fill="none" stroke="#191D41" stroke-width="15" stroke-linecap="round" /><path d="M 120 405.0 L 144 405.0 L 168 411.5 L 192 425.5 L 216 438.9 L 240 451.8 L 264 464.1 L 288 475.8 L 312 487.0 L 336 497.4 L 360 507.2 L 384 516.3 L 408 524.5 L 432 531.8 L 456 538.1 L 480 543.2 L 504 546.5 L 528 545.6 L 552 541.6 L 576 536.1 L 600 529.5 L 624 521.8 L 648 513.3 L 672 504.0 L 696 494.0 L 720 483.3 L 744 472.0 L 768 460.0 L 792 447.5 L 816 434.5 L 840 420.9 L 864 406.8 L 888 405.0" fill="none" stroke="#39407D" stroke-width="8" stroke-linecap="round" opacity="0.75" /></g>`},ninja:{armL:`<image href="costumes/ninja-cuff-l.png?v=2" x="-550" y="-200" width="1000" height="1000" />`,armR:`<image href="costumes/ninja-cuff-r.png?v=2" x="-450" y="-200" width="1000" height="1000" />`,body:`<image href="costumes/ninja-body.png?v=23" x="-193" y="13" width="1411" height="854" /><g clip-path="url(#sprout-body-clip)"><path d="M 120 374.0 L 144 374.0 L 168 380.5 L 192 394.5 L 216 407.9 L 240 420.8 L 264 433.1 L 288 444.8 L 312 456.0 L 336 466.4 L 360 476.2 L 384 485.3 L 408 493.5 L 432 500.8 L 456 507.1 L 480 512.2 L 504 515.5 L 528 514.6 L 552 510.6 L 576 505.1 L 600 498.5 L 624 490.8 L 648 482.3 L 672 473.0 L 696 463.0 L 720 452.3 L 744 441.0 L 768 429.0 L 792 416.5 L 816 403.5 L 840 389.9 L 864 375.8 L 888 374.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.05" /><path d="M 120 380.0 L 144 380.0 L 168 386.5 L 192 400.5 L 216 413.9 L 240 426.8 L 264 439.1 L 288 450.8 L 312 462.0 L 336 472.4 L 360 482.2 L 384 491.3 L 408 499.5 L 432 506.8 L 456 513.1 L 480 518.2 L 504 521.5 L 528 520.6 L 552 516.6 L 576 511.1 L 600 504.5 L 624 496.8 L 648 488.3 L 672 479.0 L 696 469.0 L 720 458.3 L 744 447.0 L 768 435.0 L 792 422.5 L 816 409.5 L 840 395.9 L 864 381.8 L 888 380.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.08" /><path d="M 120 386.0 L 144 386.0 L 168 392.5 L 192 406.5 L 216 419.9 L 240 432.8 L 264 445.1 L 288 456.8 L 312 468.0 L 336 478.4 L 360 488.2 L 384 497.3 L 408 505.5 L 432 512.8 L 456 519.1 L 480 524.2 L 504 527.5 L 528 526.6 L 552 522.6 L 576 517.1 L 600 510.5 L 624 502.8 L 648 494.3 L 672 485.0 L 696 475.0 L 720 464.3 L 744 453.0 L 768 441.0 L 792 428.5 L 816 415.5 L 840 401.9 L 864 387.8 L 888 386.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.11" /><path d="M 120 392.0 L 144 392.0 L 168 398.5 L 192 412.5 L 216 425.9 L 240 438.8 L 264 451.1 L 288 462.8 L 312 474.0 L 336 484.4 L 360 494.2 L 384 503.3 L 408 511.5 L 432 518.8 L 456 525.1 L 480 530.2 L 504 533.5 L 528 532.6 L 552 528.6 L 576 523.1 L 600 516.5 L 624 508.8 L 648 500.3 L 672 491.0 L 696 481.0 L 720 470.3 L 744 459.0 L 768 447.0 L 792 434.5 L 816 421.5 L 840 407.9 L 864 393.8 L 888 392.0" fill="none" stroke="#15161B" stroke-width="15" stroke-linecap="round" /><path d="M 120 405.0 L 144 405.0 L 168 411.5 L 192 425.5 L 216 438.9 L 240 451.8 L 264 464.1 L 288 475.8 L 312 487.0 L 336 497.4 L 360 507.2 L 384 516.3 L 408 524.5 L 432 531.8 L 456 538.1 L 480 543.2 L 504 546.5 L 528 545.6 L 552 541.6 L 576 536.1 L 600 529.5 L 624 521.8 L 648 513.3 L 672 504.0 L 696 494.0 L 720 483.3 L 744 472.0 L 768 460.0 L 792 447.5 L 816 434.5 L 840 420.9 L 864 406.8 L 888 405.0" fill="none" stroke="#32343C" stroke-width="8" stroke-linecap="round" opacity="0.75" /></g>`},idol:{armL:`<image href="costumes/idol-cuff-l.png?v=1" x="-550" y="-200" width="1000" height="1000" />`,armR:`<image href="costumes/idol-cuff-r.png?v=1" x="-450" y="-200" width="1000" height="1000" />`,body:`<image href="costumes/idol-body.png?v=23" x="-193" y="13" width="1411" height="854" /><g clip-path="url(#sprout-body-clip)"><path d="M 120 378.0 L 144 378.0 L 168 382.0 L 192 390.4 L 216 398.1 L 240 405.3 L 264 411.8 L 288 417.7 L 312 423.1 L 336 427.8 L 360 431.9 L 384 435.4 L 408 438.3 L 432 440.6 L 456 442.4 L 480 443.5 L 504 444.0 L 528 443.9 L 552 443.2 L 576 441.9 L 600 439.9 L 624 437.4 L 648 434.3 L 672 430.6 L 696 426.3 L 720 421.3 L 744 415.8 L 768 409.7 L 792 402.9 L 816 395.6 L 840 387.7 L 864 379.1 L 888 378.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.05" /><path d="M 120 384.0 L 144 384.0 L 168 388.0 L 192 396.4 L 216 404.1 L 240 411.3 L 264 417.8 L 288 423.7 L 312 429.1 L 336 433.8 L 360 437.9 L 384 441.4 L 408 444.3 L 432 446.6 L 456 448.4 L 480 449.5 L 504 450.0 L 528 449.9 L 552 449.2 L 576 447.9 L 600 445.9 L 624 443.4 L 648 440.3 L 672 436.6 L 696 432.3 L 720 427.3 L 744 421.8 L 768 415.7 L 792 408.9 L 816 401.6 L 840 393.7 L 864 385.1 L 888 384.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.08" /><path d="M 120 390.0 L 144 390.0 L 168 394.0 L 192 402.4 L 216 410.1 L 240 417.3 L 264 423.8 L 288 429.7 L 312 435.1 L 336 439.8 L 360 443.9 L 384 447.4 L 408 450.3 L 432 452.6 L 456 454.4 L 480 455.5 L 504 456.0 L 528 455.9 L 552 455.2 L 576 453.9 L 600 451.9 L 624 449.4 L 648 446.3 L 672 442.6 L 696 438.3 L 720 433.3 L 744 427.8 L 768 421.7 L 792 414.9 L 816 407.6 L 840 399.7 L 864 391.1 L 888 390.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.11" /><path d="M 120 396.0 L 144 396.0 L 168 400.0 L 192 408.4 L 216 416.1 L 240 423.3 L 264 429.8 L 288 435.7 L 312 441.1 L 336 445.8 L 360 449.9 L 384 453.4 L 408 456.3 L 432 458.6 L 456 460.4 L 480 461.5 L 504 462.0 L 528 461.9 L 552 461.2 L 576 459.9 L 600 457.9 L 624 455.4 L 648 452.3 L 672 448.6 L 696 444.3 L 720 439.3 L 744 433.8 L 768 427.7 L 792 420.9 L 816 413.6 L 840 405.7 L 864 397.1 L 888 396.0" fill="none" stroke="#9D3157" stroke-width="15" stroke-linecap="round" /><path d="M 120 409.0 L 144 409.0 L 168 413.0 L 192 421.4 L 216 429.1 L 240 436.3 L 264 442.8 L 288 448.7 L 312 454.1 L 336 458.8 L 360 462.9 L 384 466.4 L 408 469.3 L 432 471.6 L 456 473.4 L 480 474.5 L 504 475.0 L 528 474.9 L 552 474.2 L 576 472.9 L 600 470.9 L 624 468.4 L 648 465.3 L 672 461.6 L 696 457.3 L 720 452.3 L 744 446.8 L 768 440.7 L 792 433.9 L 816 426.6 L 840 418.7 L 864 410.1 L 888 409.0" fill="none" stroke="#FF61A1" stroke-width="8" stroke-linecap="round" opacity="0.75" /></g>`},monster:{armL:`<image href="costumes/monster-cuff-l.png?v=1" x="-550" y="-200" width="1000" height="1000" />`,armR:`<image href="costumes/monster-cuff-r.png?v=1" x="-450" y="-200" width="1000" height="1000" />`,body:`<image href="costumes/monster-body.png?v=23" x="-193" y="13" width="1411" height="854" /><g clip-path="url(#sprout-body-clip)"><path d="M 120 392.0 L 144 392.0 L 168 396.0 L 192 404.5 L 216 412.7 L 240 420.5 L 264 427.8 L 288 434.7 L 312 441.3 L 336 447.3 L 360 452.9 L 384 458.0 L 408 462.5 L 432 466.4 L 456 469.7 L 480 472.3 L 504 473.8 L 528 473.4 L 552 471.5 L 576 468.7 L 600 465.2 L 624 461.1 L 648 456.3 L 672 451.1 L 696 445.3 L 720 439.1 L 744 432.5 L 768 425.4 L 792 417.9 L 816 410.0 L 840 401.7 L 864 393.1 L 888 392.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.05" /><path d="M 120 398.0 L 144 398.0 L 168 402.0 L 192 410.5 L 216 418.7 L 240 426.5 L 264 433.8 L 288 440.7 L 312 447.3 L 336 453.3 L 360 458.9 L 384 464.0 L 408 468.5 L 432 472.4 L 456 475.7 L 480 478.3 L 504 479.8 L 528 479.4 L 552 477.5 L 576 474.7 L 600 471.2 L 624 467.1 L 648 462.3 L 672 457.1 L 696 451.3 L 720 445.1 L 744 438.5 L 768 431.4 L 792 423.9 L 816 416.0 L 840 407.7 L 864 399.1 L 888 398.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.08" /><path d="M 120 404.0 L 144 404.0 L 168 408.0 L 192 416.5 L 216 424.7 L 240 432.5 L 264 439.8 L 288 446.7 L 312 453.3 L 336 459.3 L 360 464.9 L 384 470.0 L 408 474.5 L 432 478.4 L 456 481.7 L 480 484.3 L 504 485.8 L 528 485.4 L 552 483.5 L 576 480.7 L 600 477.2 L 624 473.1 L 648 468.3 L 672 463.1 L 696 457.3 L 720 451.1 L 744 444.5 L 768 437.4 L 792 429.9 L 816 422.0 L 840 413.7 L 864 405.1 L 888 404.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.11" /><path d="M 120 410.0 L 144 410.0 L 168 414.0 L 192 422.5 L 216 430.7 L 240 438.5 L 264 445.8 L 288 452.7 L 312 459.3 L 336 465.3 L 360 470.9 L 384 476.0 L 408 480.5 L 432 484.4 L 456 487.7 L 480 490.3 L 504 491.8 L 528 491.4 L 552 489.5 L 576 486.7 L 600 483.2 L 624 479.1 L 648 474.3 L 672 469.1 L 696 463.3 L 720 457.1 L 744 450.5 L 768 443.4 L 792 435.9 L 816 428.0 L 840 419.7 L 864 411.1 L 888 410.0" fill="none" stroke="#415B2D" stroke-width="15" stroke-linecap="round" /><path d="M 120 423.0 L 144 423.0 L 168 427.0 L 192 435.5 L 216 443.7 L 240 451.5 L 264 458.8 L 288 465.7 L 312 472.3 L 336 478.3 L 360 483.9 L 384 489.0 L 408 493.5 L 432 497.4 L 456 500.7 L 480 503.3 L 504 504.8 L 528 504.4 L 552 502.5 L 576 499.7 L 600 496.2 L 624 492.1 L 648 487.3 L 672 482.1 L 696 476.3 L 720 470.1 L 744 463.5 L 768 456.4 L 792 448.9 L 816 441.0 L 840 432.7 L 864 424.1 L 888 423.0" fill="none" stroke="#7DA85B" stroke-width="8" stroke-linecap="round" opacity="0.75" /></g>`},grad:{armL:`<image href="costumes/grad-cuff-l.png?v=1" x="-550" y="-200" width="1000" height="1000" />`,armR:`<image href="costumes/grad-cuff-r.png?v=1" x="-450" y="-200" width="1000" height="1000" />`,body:`<image href="costumes/grad-body.png?v=23" x="-193" y="13" width="1411" height="854" /><g clip-path="url(#sprout-body-clip)"><path d="M 120 382.0 L 144 382.0 L 168 390.1 L 192 407.2 L 216 423.5 L 240 438.8 L 264 453.2 L 288 466.7 L 312 479.2 L 336 490.7 L 360 501.1 L 384 510.5 L 408 518.6 L 432 525.6 L 456 531.2 L 480 535.4 L 504 537.8 L 528 537.2 L 552 534.2 L 576 529.5 L 600 523.4 L 624 516.1 L 648 507.5 L 672 497.8 L 696 487.0 L 720 475.1 L 744 462.3 L 768 448.5 L 792 433.8 L 816 418.2 L 840 401.6 L 864 384.2 L 888 382.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.05" /><path d="M 120 388.0 L 144 388.0 L 168 396.1 L 192 413.2 L 216 429.5 L 240 444.8 L 264 459.2 L 288 472.7 L 312 485.2 L 336 496.7 L 360 507.1 L 384 516.5 L 408 524.6 L 432 531.6 L 456 537.2 L 480 541.4 L 504 543.8 L 528 543.2 L 552 540.2 L 576 535.5 L 600 529.4 L 624 522.1 L 648 513.5 L 672 503.8 L 696 493.0 L 720 481.1 L 744 468.3 L 768 454.5 L 792 439.8 L 816 424.2 L 840 407.6 L 864 390.2 L 888 388.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.08" /><path d="M 120 394.0 L 144 394.0 L 168 402.1 L 192 419.2 L 216 435.5 L 240 450.8 L 264 465.2 L 288 478.7 L 312 491.2 L 336 502.7 L 360 513.1 L 384 522.5 L 408 530.6 L 432 537.6 L 456 543.2 L 480 547.4 L 504 549.8 L 528 549.2 L 552 546.2 L 576 541.5 L 600 535.4 L 624 528.1 L 648 519.5 L 672 509.8 L 696 499.0 L 720 487.1 L 744 474.3 L 768 460.5 L 792 445.8 L 816 430.2 L 840 413.6 L 864 396.2 L 888 394.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.11" /><path d="M 120 400.0 L 144 400.0 L 168 408.1 L 192 425.2 L 216 441.5 L 240 456.8 L 264 471.2 L 288 484.7 L 312 497.2 L 336 508.7 L 360 519.1 L 384 528.5 L 408 536.6 L 432 543.6 L 456 549.2 L 480 553.4 L 504 555.8 L 528 555.2 L 552 552.2 L 576 547.5 L 600 541.4 L 624 534.1 L 648 525.5 L 672 515.8 L 696 505.0 L 720 493.1 L 744 480.3 L 768 466.5 L 792 451.8 L 816 436.2 L 840 419.6 L 864 402.2 L 888 400.0" fill="none" stroke="#916323" stroke-width="15" stroke-linecap="round" /><path d="M 120 413.0 L 144 413.0 L 168 421.1 L 192 438.2 L 216 454.5 L 240 469.8 L 264 484.2 L 288 497.7 L 312 510.2 L 336 521.7 L 360 532.1 L 384 541.5 L 408 549.6 L 432 556.6 L 456 562.2 L 480 566.4 L 504 568.8 L 528 568.2 L 552 565.2 L 576 560.5 L 600 554.4 L 624 547.1 L 648 538.5 L 672 528.8 L 696 518.0 L 720 506.1 L 744 493.3 L 768 479.5 L 792 464.8 L 816 449.2 L 840 432.6 L 864 415.2 L 888 413.0" fill="none" stroke="#FFB649" stroke-width="8" stroke-linecap="round" opacity="0.75" /></g>`},barista:{armL:`<image href="costumes/barista-cuff-l.png?v=20" x="-550" y="-200" width="1000" height="1000" />`,armR:`<image href="costumes/barista-cuff-r.png?v=20" x="-450" y="-200" width="1000" height="1000" />`,body:`<image href="costumes/barista-body.png?v=23" x="-193" y="13" width="1411" height="854" /><g clip-path="url(#sprout-body-clip)"><path d="M 120 386.0 L 144 386.0 L 168 392.5 L 192 406.0 L 216 418.7 L 240 430.5 L 264 441.3 L 288 451.3 L 312 460.4 L 336 468.5 L 360 475.6 L 384 481.9 L 408 487.1 L 432 491.4 L 456 494.6 L 480 496.8 L 504 497.9 L 528 497.7 L 552 496.2 L 576 493.7 L 600 490.1 L 624 485.5 L 648 479.9 L 672 473.4 L 696 465.9 L 720 457.4 L 744 448.1 L 768 437.8 L 792 426.7 L 816 414.6 L 840 401.6 L 864 387.8 L 888 386.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.05" /><path d="M 120 392.0 L 144 392.0 L 168 398.5 L 192 412.0 L 216 424.7 L 240 436.5 L 264 447.3 L 288 457.3 L 312 466.4 L 336 474.5 L 360 481.6 L 384 487.9 L 408 493.1 L 432 497.4 L 456 500.6 L 480 502.8 L 504 503.9 L 528 503.7 L 552 502.2 L 576 499.7 L 600 496.1 L 624 491.5 L 648 485.9 L 672 479.4 L 696 471.9 L 720 463.4 L 744 454.1 L 768 443.8 L 792 432.7 L 816 420.6 L 840 407.6 L 864 393.8 L 888 392.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.08" /><path d="M 120 398.0 L 144 398.0 L 168 404.5 L 192 418.0 L 216 430.7 L 240 442.5 L 264 453.3 L 288 463.3 L 312 472.4 L 336 480.5 L 360 487.6 L 384 493.9 L 408 499.1 L 432 503.4 L 456 506.6 L 480 508.8 L 504 509.9 L 528 509.7 L 552 508.2 L 576 505.7 L 600 502.1 L 624 497.5 L 648 491.9 L 672 485.4 L 696 477.9 L 720 469.4 L 744 460.1 L 768 449.8 L 792 438.7 L 816 426.6 L 840 413.6 L 864 399.8 L 888 398.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.11" /><path d="M 120 404.0 L 144 404.0 L 168 410.5 L 192 424.0 L 216 436.7 L 240 448.5 L 264 459.3 L 288 469.3 L 312 478.4 L 336 486.5 L 360 493.6 L 384 499.9 L 408 505.1 L 432 509.4 L 456 512.6 L 480 514.8 L 504 515.9 L 528 515.7 L 552 514.2 L 576 511.7 L 600 508.1 L 624 503.5 L 648 497.9 L 672 491.4 L 696 483.9 L 720 475.4 L 744 466.1 L 768 455.8 L 792 444.7 L 816 432.6 L 840 419.6 L 864 405.8 L 888 404.0" fill="none" stroke="#2B3E53" stroke-width="15" stroke-linecap="round" /><path d="M 120 417.0 L 144 417.0 L 168 423.5 L 192 437.0 L 216 449.7 L 240 461.5 L 264 472.3 L 288 482.3 L 312 491.4 L 336 499.5 L 360 506.6 L 384 512.9 L 408 518.1 L 432 522.4 L 456 525.6 L 480 527.8 L 504 528.9 L 528 528.7 L 552 527.2 L 576 524.7 L 600 521.1 L 624 516.5 L 648 510.9 L 672 504.4 L 696 496.9 L 720 488.4 L 744 479.1 L 768 468.8 L 792 457.7 L 816 445.6 L 840 432.6 L 864 418.8 L 888 417.0" fill="none" stroke="#57789C" stroke-width="8" stroke-linecap="round" opacity="0.75" /></g>`},ballet:{armL:`<image href="costumes/ballet-cuff-l.png?v=20" x="-550" y="-200" width="1000" height="1000" />`,armR:`<image href="costumes/ballet-cuff-r.png?v=20" x="-450" y="-200" width="1000" height="1000" />`,body:`<image href="costumes/ballet-body.png?v=23" x="-193" y="13" width="1411" height="854" /><g clip-path="url(#sprout-body-clip)"><path d="M 120 374.0 L 144 374.0 L 168 380.5 L 192 394.5 L 216 407.9 L 240 420.8 L 264 433.1 L 288 444.8 L 312 456.0 L 336 466.4 L 360 476.2 L 384 485.3 L 408 493.5 L 432 500.8 L 456 507.1 L 480 512.2 L 504 515.5 L 528 514.6 L 552 510.6 L 576 505.1 L 600 498.5 L 624 490.8 L 648 482.3 L 672 473.0 L 696 463.0 L 720 452.3 L 744 441.0 L 768 429.0 L 792 416.5 L 816 403.5 L 840 389.9 L 864 375.8 L 888 374.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.05" /><path d="M 120 380.0 L 144 380.0 L 168 386.5 L 192 400.5 L 216 413.9 L 240 426.8 L 264 439.1 L 288 450.8 L 312 462.0 L 336 472.4 L 360 482.2 L 384 491.3 L 408 499.5 L 432 506.8 L 456 513.1 L 480 518.2 L 504 521.5 L 528 520.6 L 552 516.6 L 576 511.1 L 600 504.5 L 624 496.8 L 648 488.3 L 672 479.0 L 696 469.0 L 720 458.3 L 744 447.0 L 768 435.0 L 792 422.5 L 816 409.5 L 840 395.9 L 864 381.8 L 888 380.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.08" /><path d="M 120 386.0 L 144 386.0 L 168 392.5 L 192 406.5 L 216 419.9 L 240 432.8 L 264 445.1 L 288 456.8 L 312 468.0 L 336 478.4 L 360 488.2 L 384 497.3 L 408 505.5 L 432 512.8 L 456 519.1 L 480 524.2 L 504 527.5 L 528 526.6 L 552 522.6 L 576 517.1 L 600 510.5 L 624 502.8 L 648 494.3 L 672 485.0 L 696 475.0 L 720 464.3 L 744 453.0 L 768 441.0 L 792 428.5 L 816 415.5 L 840 401.9 L 864 387.8 L 888 386.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.11" /><path d="M 120 392.0 L 144 392.0 L 168 398.5 L 192 412.5 L 216 425.9 L 240 438.8 L 264 451.1 L 288 462.8 L 312 474.0 L 336 484.4 L 360 494.2 L 384 503.3 L 408 511.5 L 432 518.8 L 456 525.1 L 480 530.2 L 504 533.5 L 528 532.6 L 552 528.6 L 576 523.1 L 600 516.5 L 624 508.8 L 648 500.3 L 672 491.0 L 696 481.0 L 720 470.3 L 744 459.0 L 768 447.0 L 792 434.5 L 816 421.5 L 840 407.9 L 864 393.8 L 888 392.0" fill="none" stroke="#AE969C" stroke-width="15" stroke-linecap="round" /><path d="M 120 405.0 L 144 405.0 L 168 411.5 L 192 425.5 L 216 438.9 L 240 451.8 L 264 464.1 L 288 475.8 L 312 487.0 L 336 497.4 L 360 507.2 L 384 516.3 L 408 524.5 L 432 531.8 L 456 538.1 L 480 543.2 L 504 546.5 L 528 545.6 L 552 541.6 L 576 536.1 L 600 529.5 L 624 521.8 L 648 513.3 L 672 504.0 L 696 494.0 L 720 483.3 L 744 472.0 L 768 460.0 L 792 447.5 L 816 434.5 L 840 420.9 L 864 406.8 L 888 405.0" fill="none" stroke="#FFFFFF" stroke-width="8" stroke-linecap="round" opacity="0.75" /></g>`},hanbok:{armL:`<image href="costumes/hanbok-cuff-l.png?v=21" x="-550" y="-200" width="1000" height="1000" />`,armR:`<image href="costumes/hanbok-cuff-r.png?v=21" x="-450" y="-200" width="1000" height="1000" />`,body:`<image href="costumes/hanbok-body.png?v=23" x="-193" y="13" width="1411" height="854" /><g clip-path="url(#sprout-body-clip)"><path d="M 120 382.0 L 144 382.0 L 168 390.1 L 192 407.2 L 216 423.5 L 240 438.8 L 264 453.2 L 288 466.7 L 312 479.2 L 336 490.7 L 360 501.1 L 384 510.5 L 408 518.6 L 432 525.6 L 456 531.2 L 480 535.4 L 504 537.8 L 528 537.2 L 552 534.2 L 576 529.5 L 600 523.4 L 624 516.1 L 648 507.5 L 672 497.8 L 696 487.0 L 720 475.1 L 744 462.3 L 768 448.5 L 792 433.8 L 816 418.2 L 840 401.6 L 864 384.2 L 888 382.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.05" /><path d="M 120 388.0 L 144 388.0 L 168 396.1 L 192 413.2 L 216 429.5 L 240 444.8 L 264 459.2 L 288 472.7 L 312 485.2 L 336 496.7 L 360 507.1 L 384 516.5 L 408 524.6 L 432 531.6 L 456 537.2 L 480 541.4 L 504 543.8 L 528 543.2 L 552 540.2 L 576 535.5 L 600 529.4 L 624 522.1 L 648 513.5 L 672 503.8 L 696 493.0 L 720 481.1 L 744 468.3 L 768 454.5 L 792 439.8 L 816 424.2 L 840 407.6 L 864 390.2 L 888 388.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.08" /><path d="M 120 394.0 L 144 394.0 L 168 402.1 L 192 419.2 L 216 435.5 L 240 450.8 L 264 465.2 L 288 478.7 L 312 491.2 L 336 502.7 L 360 513.1 L 384 522.5 L 408 530.6 L 432 537.6 L 456 543.2 L 480 547.4 L 504 549.8 L 528 549.2 L 552 546.2 L 576 541.5 L 600 535.4 L 624 528.1 L 648 519.5 L 672 509.8 L 696 499.0 L 720 487.1 L 744 474.3 L 768 460.5 L 792 445.8 L 816 430.2 L 840 413.6 L 864 396.2 L 888 394.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.11" /><path d="M 120 400.0 L 144 400.0 L 168 408.1 L 192 425.2 L 216 441.5 L 240 456.8 L 264 471.2 L 288 484.7 L 312 497.2 L 336 508.7 L 360 519.1 L 384 528.5 L 408 536.6 L 432 543.6 L 456 549.2 L 480 553.4 L 504 555.8 L 528 555.2 L 552 552.2 L 576 547.5 L 600 541.4 L 624 534.1 L 648 525.5 L 672 515.8 L 696 505.0 L 720 493.1 L 744 480.3 L 768 466.5 L 792 451.8 L 816 436.2 L 840 419.6 L 864 402.2 L 888 400.0" fill="none" stroke="#722D41" stroke-width="15" stroke-linecap="round" /><path d="M 120 413.0 L 144 413.0 L 168 421.1 L 192 438.2 L 216 454.5 L 240 469.8 L 264 484.2 L 288 497.7 L 312 510.2 L 336 521.7 L 360 532.1 L 384 541.5 L 408 549.6 L 432 556.6 L 456 562.2 L 480 566.4 L 504 568.8 L 528 568.2 L 552 565.2 L 576 560.5 L 600 554.4 L 624 547.1 L 648 538.5 L 672 528.8 L 696 518.0 L 720 506.1 L 744 493.3 L 768 479.5 L 792 464.8 L 816 449.2 L 840 432.6 L 864 415.2 L 888 413.0" fill="none" stroke="#D05B7C" stroke-width="8" stroke-linecap="round" opacity="0.75" /></g>`},hex:{armL:`<image href="costumes/hex-cuff-l.png?v=20" x="-550" y="-200" width="1000" height="1000" />`,armR:`<image href="costumes/hex-cuff-r.png?v=20" x="-450" y="-200" width="1000" height="1000" />`,body:`<image href="costumes/hex-body.png?v=24" x="-193" y="13" width="1411" height="854" /><g clip-path="url(#sprout-body-clip)"><path d="M 120 378.0 L 144 378.0 L 168 382.0 L 192 390.4 L 216 398.1 L 240 405.3 L 264 411.8 L 288 417.7 L 312 423.1 L 336 427.8 L 360 431.9 L 384 435.4 L 408 438.3 L 432 440.6 L 456 442.4 L 480 443.5 L 504 444.0 L 528 443.9 L 552 443.2 L 576 441.9 L 600 439.9 L 624 437.4 L 648 434.3 L 672 430.6 L 696 426.3 L 720 421.3 L 744 415.8 L 768 409.7 L 792 402.9 L 816 395.6 L 840 387.7 L 864 379.1 L 888 378.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.05" /><path d="M 120 384.0 L 144 384.0 L 168 388.0 L 192 396.4 L 216 404.1 L 240 411.3 L 264 417.8 L 288 423.7 L 312 429.1 L 336 433.8 L 360 437.9 L 384 441.4 L 408 444.3 L 432 446.6 L 456 448.4 L 480 449.5 L 504 450.0 L 528 449.9 L 552 449.2 L 576 447.9 L 600 445.9 L 624 443.4 L 648 440.3 L 672 436.6 L 696 432.3 L 720 427.3 L 744 421.8 L 768 415.7 L 792 408.9 L 816 401.6 L 840 393.7 L 864 385.1 L 888 384.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.08" /><path d="M 120 390.0 L 144 390.0 L 168 394.0 L 192 402.4 L 216 410.1 L 240 417.3 L 264 423.8 L 288 429.7 L 312 435.1 L 336 439.8 L 360 443.9 L 384 447.4 L 408 450.3 L 432 452.6 L 456 454.4 L 480 455.5 L 504 456.0 L 528 455.9 L 552 455.2 L 576 453.9 L 600 451.9 L 624 449.4 L 648 446.3 L 672 442.6 L 696 438.3 L 720 433.3 L 744 427.8 L 768 421.7 L 792 414.9 L 816 407.6 L 840 399.7 L 864 391.1 L 888 390.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.11" /><path d="M 120 396.0 L 144 396.0 L 168 400.0 L 192 408.4 L 216 416.1 L 240 423.3 L 264 429.8 L 288 435.7 L 312 441.1 L 336 445.8 L 360 449.9 L 384 453.4 L 408 456.3 L 432 458.6 L 456 460.4 L 480 461.5 L 504 462.0 L 528 461.9 L 552 461.2 L 576 459.9 L 600 457.9 L 624 455.4 L 648 452.3 L 672 448.6 L 696 444.3 L 720 439.3 L 744 433.8 L 768 427.7 L 792 420.9 L 816 413.6 L 840 405.7 L 864 397.1 L 888 396.0" fill="none" stroke="#151119" stroke-width="15" stroke-linecap="round" /><path d="M 120 409.0 L 144 409.0 L 168 413.0 L 192 421.4 L 216 429.1 L 240 436.3 L 264 442.8 L 288 448.7 L 312 454.1 L 336 458.8 L 360 462.9 L 384 466.4 L 408 469.3 L 432 471.6 L 456 473.4 L 480 474.5 L 504 475.0 L 528 474.9 L 552 474.2 L 576 472.9 L 600 470.9 L 624 468.4 L 648 465.3 L 672 461.6 L 696 457.3 L 720 452.3 L 744 446.8 L 768 440.7 L 792 433.9 L 816 426.6 L 840 418.7 L 864 410.1 L 888 409.0" fill="none" stroke="#332C38" stroke-width="8" stroke-linecap="round" opacity="0.75" /></g>`},keynote:{armL:`<image href="costumes/keynote-cuff-l.png?v=22" x="-550" y="-200" width="1000" height="1000" />`,armR:`<image href="costumes/keynote-cuff-r.png?v=22" x="-450" y="-200" width="1000" height="1000" />`,body:`<image href="costumes/keynote-body.png?v=23" x="-193" y="13" width="1411" height="854" /><g clip-path="url(#sprout-body-clip)"><path d="M 120 378.0 L 144 378.0 L 168 382.0 L 192 390.4 L 216 398.1 L 240 405.3 L 264 411.8 L 288 417.7 L 312 423.1 L 336 427.8 L 360 431.9 L 384 435.4 L 408 438.3 L 432 440.6 L 456 442.4 L 480 443.5 L 504 444.0 L 528 443.9 L 552 443.2 L 576 441.9 L 600 439.9 L 624 437.4 L 648 434.3 L 672 430.6 L 696 426.3 L 720 421.3 L 744 415.8 L 768 409.7 L 792 402.9 L 816 395.6 L 840 387.7 L 864 379.1 L 888 378.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.05" /><path d="M 120 384.0 L 144 384.0 L 168 388.0 L 192 396.4 L 216 404.1 L 240 411.3 L 264 417.8 L 288 423.7 L 312 429.1 L 336 433.8 L 360 437.9 L 384 441.4 L 408 444.3 L 432 446.6 L 456 448.4 L 480 449.5 L 504 450.0 L 528 449.9 L 552 449.2 L 576 447.9 L 600 445.9 L 624 443.4 L 648 440.3 L 672 436.6 L 696 432.3 L 720 427.3 L 744 421.8 L 768 415.7 L 792 408.9 L 816 401.6 L 840 393.7 L 864 385.1 L 888 384.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.08" /><path d="M 120 390.0 L 144 390.0 L 168 394.0 L 192 402.4 L 216 410.1 L 240 417.3 L 264 423.8 L 288 429.7 L 312 435.1 L 336 439.8 L 360 443.9 L 384 447.4 L 408 450.3 L 432 452.6 L 456 454.4 L 480 455.5 L 504 456.0 L 528 455.9 L 552 455.2 L 576 453.9 L 600 451.9 L 624 449.4 L 648 446.3 L 672 442.6 L 696 438.3 L 720 433.3 L 744 427.8 L 768 421.7 L 792 414.9 L 816 407.6 L 840 399.7 L 864 391.1 L 888 390.0" fill="none" stroke="#2B2622" stroke-width="14" opacity="0.11" /><path d="M 120 396.0 L 144 396.0 L 168 400.0 L 192 408.4 L 216 416.1 L 240 423.3 L 264 429.8 L 288 435.7 L 312 441.1 L 336 445.8 L 360 449.9 L 384 453.4 L 408 456.3 L 432 458.6 L 456 460.4 L 480 461.5 L 504 462.0 L 528 461.9 L 552 461.2 L 576 459.9 L 600 457.9 L 624 455.4 L 648 452.3 L 672 448.6 L 696 444.3 L 720 439.3 L 744 433.8 L 768 427.7 L 792 420.9 L 816 413.6 L 840 405.7 L 864 397.1 L 888 396.0" fill="none" stroke="#16161A" stroke-width="15" stroke-linecap="round" /><path d="M 120 409.0 L 144 409.0 L 168 413.0 L 192 421.4 L 216 429.1 L 240 436.3 L 264 442.8 L 288 448.7 L 312 454.1 L 336 458.8 L 360 462.9 L 384 466.4 L 408 469.3 L 432 471.6 L 456 473.4 L 480 474.5 L 504 475.0 L 528 474.9 L 552 474.2 L 576 472.9 L 600 470.9 L 624 468.4 L 648 465.3 L 672 461.6 L 696 457.3 L 720 452.3 L 744 446.8 L 768 440.7 L 792 433.9 L 816 426.6 L 840 418.7 L 864 410.1 L 888 409.0" fill="none" stroke="#34333A" stroke-width="8" stroke-linecap="round" opacity="0.75" /></g>`}},De=[{id:`hoodie`,name:`Hoodie`,rarity:`common`,price:150},{id:`flannel`,name:`Flannel`,rarity:`common`,price:150},{id:`scholar`,name:`Blazer`,rarity:`uncommon`,price:300},{id:`varsity`,name:`Varsity`,rarity:`uncommon`,price:300},{id:`pajamas`,name:`Pajamas`,rarity:`uncommon`,price:300},{id:`happi`,name:`Happi`,rarity:`rare`,price:500},{id:`idol`,name:`Idol`,rarity:`rare`,price:500},{id:`racer`,name:`Racer`,rarity:`rare`,price:500},{id:`biker`,name:`Biker`,rarity:`epic`,price:800},{id:`astronaut`,name:`Astronaut`,rarity:`epic`,price:800},{id:`monster`,name:`Monster`,rarity:`epic`,price:800},{id:`ninja`,name:`Ninja`,rarity:`legendary`,price:1200},{id:`sorcerer`,name:`Sorcerer`,rarity:`legendary`,price:1200},{id:`grad`,name:`Grad`,rarity:`legendary`,price:1200},{id:`barista`,name:`Barista`,rarity:`common`,price:150},{id:`keynote`,name:`Keynote`,rarity:`uncommon`,price:300},{id:`ballet`,name:`Ballet`,rarity:`rare`,price:500},{id:`hanbok`,name:`Hanbok`,rarity:`rare`,price:500},{id:`hex`,name:`Hex`,rarity:`legendary`,price:1200}],Oe=Object.fromEntries(De.map(e=>[e.id,e]));function ke(e,t){return De.map(e=>e.id)}var Ae={mint:`scholar`,coral:`ninja`,sky:`hoodie`,peach:`flannel`,lilac:`astronaut`,butter:`racer`},je=e=>`sprout-costume-${e}`;function Me(e,t,n){let r=ke(e,t);if(n&&r.includes(n))return n;try{let n=localStorage.getItem(je(e===`sprout`?t.id:e));if(n&&r.includes(n))return n}catch{}return e===`orca`?`biker`:e===`axolotl`?`pajamas`:Ae[t.id]}function Ne(e,t,n){try{localStorage.setItem(je(e===`sprout`?t.id:e),n)}catch{}}var Pe=new Set([`sorcerer`,`monster`,`ballet`,`hanbok`,`hex`]),D=`clip-path="url(#sprout-body-clip)"`,O=`clip-path="url(#fin-l-clip)"`,k=`clip-path="url(#fin-r-clip)"`,A=`filter="url(#sprout-outline)"`,j=`class="held-swing" filter="url(#held-outline)"`,M=(e,t,n)=>`<rect x="${Math.min(e,t)}" y="-170" width="${Math.abs(t-e)}" height="340" fill="${n}" />`,N=(e,t,n)=>`<rect x="${-Math.max(e,t)}" y="-170" width="${Math.abs(t-e)}" height="340" fill="${n}" />`,P=(e,t,n,r,i=``)=>{let a=[];for(let r=0;r<10;r++){let i=-Math.PI/2+r*Math.PI/5,o=r%2?n*.45:n;a.push(`${(e+o*Math.cos(i)).toFixed(1)},${(t+o*Math.sin(i)).toFixed(1)}`)}return`<polygon points="${a.join(` `)}" fill="${r}"${i?` class="${i}"`:``} />`},Fe={scholar:{body:`
      <g ${D}>
        <!-- Two cloak panels, open down the front so the coat and belly show. -->
        <path d="M 0 440 H 466 C 436 570 436 730 470 850 H 0 Z" fill="#2F6B4F" />
        <path d="M 982 440 H 558 C 588 570 588 730 554 850 H 982 Z" fill="#2F6B4F" />
        <path d="M 466 440 C 436 570 436 730 470 850" fill="none" stroke="#4C9A72" stroke-width="16" />
        <path d="M 558 440 C 588 570 588 730 554 850" fill="none" stroke="#4C9A72" stroke-width="16" />
        <!-- Hood down: bunched at the back of the neck. -->
        <path d="M 236 468 C 320 402 704 402 788 468 C 720 508 304 508 236 468 Z" fill="#3E8663" />
        <path d="M 300 466 C 380 436 644 436 724 466" fill="none" stroke="#2F6B4F" stroke-width="8" opacity="0.6" />
        <!-- Satchel strap and buckle. -->
        <path d="M 286 430 L 348 430 L 736 790 L 686 826 Z" fill="#8A5A3C" />
        <path d="M 302 430 L 316 430 L 704 802 L 692 812 Z" fill="#6E4630" opacity="0.6" />
        <g transform="translate(600 668) rotate(43)">
          <rect x="-26" y="-18" width="52" height="36" rx="6" fill="#C9A85B" />
          <rect x="-12" y="-8" width="24" height="16" rx="3" fill="#8A5A3C" />
        </g>
        <!-- A rolled scroll tucked under the strap. -->
        <g transform="translate(662 596) rotate(-34)">
          <rect x="-22" y="-56" width="44" height="112" rx="20" fill="#F3E6D3" />
          <ellipse cx="0" cy="-56" rx="22" ry="9" fill="#E4C9A8" />
          <ellipse cx="0" cy="56" rx="22" ry="9" fill="#E4C9A8" />
        </g>
      </g>`,armL:`<g ${O}>${M(-236,60,`#2F6B4F`)}<rect x="-244" y="-170" width="14" height="340" fill="#4C9A72" /></g>`,armR:`<g ${k}>${N(-236,60,`#2F6B4F`)}<rect x="230" y="-170" width="14" height="340" fill="#4C9A72" /></g>`,faceOverFit:`
      <!--
        Round wire glasses. They sit on the bare face window, which the paint never touches, so
        they are vector rather than paint. Thin and dark, not brass: a heavy gold frame fought
        the dot eyes. Temples stop on the head's edge instead of running off into space.
      -->
      <g fill="none" stroke="#3A2E28" stroke-width="11" stroke-linecap="round">
        <circle cx="352" cy="371" r="70" /><circle cx="671" cy="371" r="70" />
        <path d="M 422 366 Q 512 344 601 366" />
        <path d="M 282 366 Q 244 352 222 334" /><path d="M 741 366 Q 779 352 801 334" />
      </g>
      <circle cx="330" cy="344" r="12" fill="#FFFFFF" opacity="0.5" /><circle cx="649" cy="344" r="12" fill="#FFFFFF" opacity="0.5" />
    `,face:`
      <g fill="none" stroke="#3A2E28" stroke-width="11">
        <circle cx="352" cy="371" r="70" /><circle cx="671" cy="371" r="70" />
        <path d="M 422 366 Q 512 344 601 366" />
        <path d="M 282 366 Q 236 350 214 322" /><path d="M 741 366 Q 787 350 809 322" />
      </g>
      <circle cx="330" cy="344" r="12" fill="#FFFFFF" opacity="0.5" /><circle cx="649" cy="344" r="12" fill="#FFFFFF" opacity="0.5" />`},ninja:{armLHeld:`
      <!--
        Katana. The first pass was a 200-unit hairline with a tick for a guard and read as a
        razor blade. A sword needs three things to be legible at this size: real blade WIDTH
        (30 units at the base, tapering only near the point), a CURVE, and a tsuba you can
        actually see. Blade runs 400 units from guard to tip, about half his body height.
      -->
      <g ${j}>
        <!--
          One continuous silhouette. Pommel, grip, tsuba and blade are all measured along a single
          straight axis and closed into ONE path, so the group's white rim wraps the sword as one
          object — drawn as three stacked pieces it read as three props stuck together. The colour
          blocks below sit inside that silhouette and share its edges exactly.
        -->
        <path d="M -404.5 155.1 L -397.3 146.4 L -394.3 136.0 L -406.3 14.6 L -386.8 8.7 L -380.3 4.0 L -381.8 -11.9 L -389.2 -15.2 L -406.7 -19.5 L -442.5 -329.5 L -453.8 -382.6 L -468.0 -404.0 L -477.7 -380.3 L -478.3 -325.9 L -452.5 -15.0 L -468.8 -7.3 L -475.4 -2.6 L -473.8 13.3 L -466.4 16.6 L -446.2 18.6 L -434.1 140.0 L -429.1 149.5 L -420.4 156.7 Z" fill="#D9E1E9" />
        <path d="M -404.5 155.1 L -397.3 146.4 L -394.3 136.0 L -406.3 14.6 L -404.0 8.4 L -449.7 12.9 L -446.2 18.6 L -434.1 140.0 L -429.1 149.5 L -420.4 156.7 Z" fill="#23262B" />
        <g stroke="#5C646E" stroke-width="5" stroke-linecap="round" opacity="0.9"><path d="M -433.3 127.8 L -399.6 102.4" /><path d="M -397.5 124.3 L -435.5 106.0" /><path d="M -437.0 90.0 L -403.4 64.6" /><path d="M -401.2 86.5 L -439.2 68.1" /><path d="M -440.8 52.2 L -407.2 26.8" /><path d="M -405.0 48.7 L -443.0 30.3" /></g>
        <path d="M -386.6 10.7 L -380.3 4.0 L -381.8 -11.9 L -389.4 -17.2 L -469.0 -9.3 L -475.4 -2.6 L -473.8 13.3 L -466.3 18.6 Z" fill="#C9A33A" />
        <path d="M -386.6 10.7 L -380.3 4.0 L -381.8 -11.9 L -389.4 -17.2 L -469.0 -9.3 L -475.4 -2.6 L -473.8 13.3 L -466.3 18.6 Z" fill="none" stroke="#8F7226" stroke-width="4" />
        <path d="M -446.9 -19.5 L -481.5 -367.8" fill="none" stroke="#8A97A4" stroke-width="8" />
        <path d="M -421.8 -30.1 L -457.4 -358.1" fill="none" stroke="#FFFFFF" stroke-width="9" opacity="0.8" />
      </g>
    `,headOverFit:`
      <!--
        The headband, rebuilt 2026-09-06. Stroked on a centreline that runs well past the pear so
        the body clip decides where it ends, the plate centred on it, and the knot placed ON the
        band's own curve at x 240 (y 262, solved from the cubic) rather than 22 units below it.
      -->
      <g>
        <g clip-path="url(#sprout-body-clip)" fill="none" stroke-linecap="butt">
          <path stroke="#C43B3B" stroke-width="60" d="M 100 290 C 286 232, 738 232, 924 290" />
          <path stroke="#E05A5A" stroke-width="13" d="M 100 268 C 286 210, 738 210, 924 268" />
          <path stroke="#9E2F2F" stroke-width="12" d="M 100 312 C 286 254, 738 254, 924 312" />
          <g stroke="none">
            <rect x="452" y="220" width="120" height="52" rx="13" fill="#5F666E" />
            <rect x="461" y="228" width="102" height="35" rx="9" fill="#D4DAE0" />
            <circle cx="473" cy="237" r="3.9" fill="#3A4046" /><circle cx="551" cy="237" r="3.9" fill="#3A4046" />
            <circle cx="473" cy="255" r="3.9" fill="#3A4046" /><circle cx="551" cy="255" r="3.9" fill="#3A4046" />
          </g>
        </g>
        <g transform="translate(240 256)" ${A}>
          <path fill="#C43B3B" d="M 6 2 C -16 -16, -58 -44, -108 -48 C -130 -50, -140 -24, -116 -12 C -88 2, -36 12, 10 12 Z" />
          <path fill="#C43B3B" d="M 8 10 C -14 30, -56 68, -94 102 C -114 118, -100 140, -74 122 C -42 100, -4 44, 12 16 Z" />
          <ellipse cx="8" cy="6" rx="17" ry="14" fill="#C43B3B" />
        </g>
        <g transform="translate(240 256)">
          <path fill="#9E2F2F" d="M 0 2 C -24 -10, -64 -28, -100 -30 C -108 -30, -110 -22, -96 -18 C -70 -12, -28 4, 4 8 Z" />
          <path fill="#9E2F2F" d="M 2 12 C -20 30, -56 64, -86 92 C -94 100, -88 108, -74 98 C -46 78, -10 36, 6 16 Z" />
          <ellipse cx="6" cy="4" rx="9" ry="7" fill="#E05A5A" />
        </g>
      </g>
    `},hoodie:{body:`
      <g ${D}>
        <rect x="0" y="480" width="982" height="400" fill="#B8BCC4" />
        <!-- Kangaroo pocket, drawstrings with aglets, one enamel pin. -->
        <rect x="392" y="650" width="240" height="104" rx="34" fill="#A6ABB4" />
        <path d="M 484 560 C 480 600 474 650 468 690" fill="none" stroke="#F4F4F4" stroke-width="9" stroke-linecap="round" />
        <path d="M 540 560 C 544 600 550 650 556 690" fill="none" stroke="#F4F4F4" stroke-width="9" stroke-linecap="round" />
        <rect x="458" y="686" width="14" height="26" rx="5" fill="#C9CED6" /><rect x="550" y="686" width="14" height="26" rx="5" fill="#C9CED6" />
        <circle cx="632" cy="560" r="17" fill="#E8B04B" /><circle cx="632" cy="560" r="8" fill="#F6E7A8" />
      </g>`,headOverFit:`
      <!--
        Over-ear headphones. They arc past the crown and hug the head's outer edge, so they are
        vector rather than paint: the paint can only ever live inside the pear.
      -->
      <g ${A}>
        <path d="M 178 404 C 168 168 318 46 512 44 C 706 46 856 168 846 404" fill="none" stroke="#2B2F33" stroke-width="34" stroke-linecap="round" />
        <path d="M 178 404 C 168 168 318 46 512 44 C 706 46 856 168 846 404" fill="none" stroke="#5B6672" stroke-width="12" stroke-linecap="round" />
        <rect x="118" y="368" width="120" height="152" rx="54" fill="#2B2F33" />
        <rect x="786" y="368" width="120" height="152" rx="54" fill="#2B2F33" />
        <rect x="146" y="394" width="64" height="100" rx="30" fill="#5B6672" />
        <rect x="814" y="394" width="64" height="100" rx="30" fill="#5B6672" />
      </g>
    `,head:`
      <!-- Hood up: the head silhouette pushed out, with the face cut through it. -->
      <g ${A}>
        <path fill="#B8BCC4" fill-rule="evenodd"
              d="M 168 540 C 172 300 318 62 512 58 C 706 62 852 300 856 540 C 780 516 640 508 512 508 C 384 508 244 516 168 540 Z
                 M 512 168 C 672 168 804 268 804 392 C 804 516 672 616 512 616 C 352 616 220 516 220 392 C 220 268 352 168 512 168 Z" />
        <path d="M 220 392 C 220 516 352 616 512 616 C 672 616 804 516 804 392" fill="none" stroke="#A6ABB4" stroke-width="14" />
      </g>
      <!-- Headphones over the hood. -->
      <g ${A}>
        <path d="M 250 430 C 236 200 336 78 512 72 C 688 78 788 200 774 430" fill="none" stroke="#2B2F33" stroke-width="32" stroke-linecap="round" />
        <path d="M 250 430 C 236 200 336 78 512 72 C 688 78 788 200 774 430" fill="none" stroke="#5B6672" stroke-width="12" stroke-linecap="round" />
        <rect x="192" y="386" width="92" height="140" rx="40" fill="#2B2F33" /><rect x="740" y="386" width="92" height="140" rx="40" fill="#2B2F33" />
        <rect x="214" y="410" width="48" height="92" rx="24" fill="#5B6672" /><rect x="762" y="410" width="48" height="92" rx="24" fill="#5B6672" />
      </g>`,armL:`<g ${O}>${M(-520,100,`#B8BCC4`)}<rect x="-470" y="-170" width="30" height="340" fill="#A6ABB4" /></g>`,armR:`<g ${k}>${N(-520,100,`#B8BCC4`)}<rect x="440" y="-170" width="30" height="340" fill="#A6ABB4" /></g>`},baker:{headOverFit:`
      <g>
        <g clip-path="url(#sprout-body-clip)" fill="none" stroke-linecap="butt">
          <path stroke="#2F4562" stroke-width="56" d="M 100 292 C 286 234, 738 234, 924 292" />
          <path stroke="#22344B" stroke-width="11" d="M 100 314 C 286 256, 738 256, 924 314" />
          <path stroke="#43597A" stroke-width="12" d="M 100 270 C 286 212, 738 212, 924 270" />
        </g>
        <!-- Knot, off the left, with its own rim so it reads clear of the head. -->
        <g transform="translate(236 261)" ${A}>
          <path fill="#2F4562" d="M 4 -2 C -18 -22, -52 -34, -78 -30 C -94 -28, -96 -8, -76 -2 C -52 6, -18 10, 8 8 Z" />
          <path fill="#2F4562" d="M 6 6 C -14 24, -42 46, -66 58 C -82 66, -74 84, -54 76 C -30 66, -6 36, 10 14 Z" />
          <ellipse cx="6" cy="4" rx="17" ry="14" fill="#43597A" />
        </g>
      </g>
    `,body:`
      <g ${D}>
        <!-- Apron bib, waist tie, pocket, spoon. -->
        <path d="M 404 476 H 620 L 640 566 C 706 590 706 850 660 850 H 364 C 318 850 318 590 384 566 Z" fill="#F3E6D3" />
        <rect x="120" y="560" width="742" height="34" rx="10" fill="#E4C9A8" />
        <rect x="428" y="646" width="168" height="92" rx="18" fill="#E9D9C0" />
        <path d="M 444 662 H 580" fill="none" stroke="#D9C2A0" stroke-width="5" stroke-dasharray="8 8" />
        <g transform="translate(566 636) rotate(-22)">
          <rect x="-9" y="-90" width="18" height="120" rx="9" fill="#B07A46" />
          <ellipse cx="0" cy="-102" rx="20" ry="28" fill="#C48E58" />
        </g>
        <ellipse cx="716" cy="472" rx="30" ry="18" fill="#FFFFFF" opacity="0.8" />
      </g>
      <!-- Tie bow at the right hip, outside the pear. -->
      <g ${A} transform="translate(838 578)">
        <path d="M 0 0 C 30 -40 66 -44 70 -14 C 50 -6 24 2 0 0 Z" fill="#E4C9A8" />
        <path d="M 0 0 C 30 36 66 42 70 14 C 50 6 24 -2 0 0 Z" fill="#E4C9A8" />
        <circle r="10" fill="#D9BE98" />
      </g>`,head:`
      <g ${D} fill="none" stroke-linecap="butt">
        <path d="M 108 289 C 288 231, 736 231, 916 289" stroke="#D9534F" stroke-width="62" />
        <g stroke="#FFFFFF" stroke-width="6" opacity="0.55">
          <path d="M 108 276 C 288 218, 736 218, 916 276" /><path d="M 108 300 C 288 242, 736 242, 916 300" />
          <path d="M 260 234 V 306" /><path d="M 340 224 V 296" /><path d="M 420 218 V 290" /><path d="M 512 216 V 288" /><path d="M 604 218 V 290" /><path d="M 684 224 V 296" /><path d="M 764 234 V 306" />
        </g>
      </g>
      <!-- Knot off the right side, like the Ninja's tails but tied. -->
      <g transform="translate(790 268)" ${A}>
        <path d="M -4 2 C 20 -18 56 -40 100 -34 C 118 -30 122 -10 100 -2 C 66 8 30 12 -6 12 Z" fill="#D9534F" />
        <path d="M -6 10 C 16 30 50 60 82 92 C 100 108 84 128 60 112 C 34 92 8 48 -10 16 Z" fill="#D9534F" />
        <ellipse cx="-4" cy="6" rx="16" ry="13" fill="#C43B3B" />
      </g>`,armL:`<g ${O}>${M(-150,60,`#F3E6D3`)}<rect x="-158" y="-170" width="16" height="340" fill="#E4C9A8" /></g>`,armR:`<g ${k}>${N(-150,60,`#F3E6D3`)}<rect x="142" y="-170" width="16" height="340" fill="#E4C9A8" /></g>`},flannel:{},happi:{headOverFit:`
      <g>
        <g clip-path="url(#sprout-body-clip)" fill="none" stroke-linecap="butt">
          <path stroke="#F2EFE6" stroke-width="56" d="M 100 292 C 286 234, 738 234, 924 292" />
          <path stroke="#D8D2C4" stroke-width="11" d="M 100 314 C 286 256, 738 256, 924 314" />
        </g>
        <g transform="translate(236 261)" ${A}>
          <path fill="#F2EFE6" d="M 4 -2 C -18 -22, -52 -34, -78 -30 C -94 -28, -96 -8, -76 -2 C -52 6, -18 10, 8 8 Z" />
          <path fill="#F2EFE6" d="M 6 6 C -14 24, -42 46, -66 58 C -82 66, -74 84, -54 76 C -30 66, -6 36, 10 14 Z" />
          <ellipse cx="6" cy="4" rx="17" ry="14" fill="#E4DED0" />
        </g>
      </g>
    `},varsity:{},barista:{armRHeld:`
      <!--
        Takeaway cup, held upright at the same near-vertical angle as the flag, the katana and the
        wand. Barista has no hat on purpose: the apron and the cup carry it, and a fifth piece of
        head gear on a fourteen-strong rack is where costumes start looking the same.
      -->
      <g ${j}>
        <g transform="rotate(-7 440 -110)">
          <path fill="#F2EFE6" d="M 384 60 L 496 60 L 516 -194 L 364 -194 Z" />
          <path fill="#E4E0D2" d="M 384 60 L 420 60 L 400 -194 L 364 -194 Z" />
          <path fill="#C9A26B" d="M 372 -68 L 508 -68 L 514 -152 L 366 -152 Z" />
          <path fill="#DBBB86" d="M 372 -68 L 508 -68 L 509 -86 L 371 -86 Z" />
          <rect x="348" y="-240" width="184" height="48" rx="18" fill="#3B4149" />
          <rect x="372" y="-260" width="136" height="30" rx="14" fill="#4A515B" />
        </g>
      </g>
    `},keynote:{faceOverFit:`
      <!--
        Rimless round glasses. Blazer already wears round wire frames in a heavy dark stroke and
        Sorcerer wears gold half-moons, so these are RIMLESS - a pale lens, a hairline rim and a
        thin silver bridge - which is both the real thing and the only way three pairs of glasses
        on one rack stay told apart at a glance.

        They live in faceOverFit because they belong ON his eyes: #costume-head is poured BEFORE
        the face group, so a pair placed there would have his eye dots draw straight over them.
        Lenses are centred on the dots at (352, 371) and (671, 371), the same centres the other
        two pairs use. Temples stop at the edge of his head rather than running off into water.

        There is NO lens fill. A tint at even a third opacity sat over his eye dots and turned them
        grey, which cost him his expression - and expression is the whole mascot. Rimless glasses
        read from the rim and the glint anyway.
      -->
      <g>
        <g fill="none" stroke="#AEB8C2" stroke-width="5" stroke-linecap="round">
          <circle cx="352" cy="371" r="66" /><circle cx="671" cy="371" r="66" />
        </g>
        <g fill="none" stroke="#C3CBD3" stroke-width="9" stroke-linecap="round">
          <path d="M 418 362 Q 512 342 605 362" />
          <path d="M 286 362 Q 248 350 226 332" /><path d="M 737 362 Q 775 350 797 332" />
        </g>
        <path d="M 318 336 Q 336 322 358 320" fill="none" stroke="#FFFFFF" stroke-width="9"
              stroke-linecap="round" opacity="0.7" />
        <path d="M 637 336 Q 655 322 677 320" fill="none" stroke="#FFFFFF" stroke-width="9"
              stroke-linecap="round" opacity="0.7" />
      </g>
    `},ballet:{headOverFit:`
      <!--
        Flower crown, not a bun. A bun needs a hair colour and this rig has no hair - the pear is
        the head - so a bun would read as a lump. The flowers are placed on an ARC around
        (512, 300) at radius 230, generated rather than dropped by eye, so they sit evenly on the
        crown at any size. Lowest point y 194, well clear of his face at y 319.
      -->
      <g ${A}>
        <path d="M 318 196 C 372 116 440 78 512 78 C 584 78 652 116 706 196" fill="none"
              stroke="#C9738A" stroke-width="22" stroke-linecap="round" />
        <g><circle cx="331" cy="132" r="19" fill="#F6DCE4" /><circle cx="355" cy="150" r="19" fill="#F6DCE4" /><circle cx="346" cy="179" r="19" fill="#F6DCE4" /><circle cx="315" cy="179" r="19" fill="#F6DCE4" /><circle cx="306" cy="150" r="19" fill="#F6DCE4" /><circle cx="331" cy="158" r="13" fill="#E4C45C" /></g>
        <g><circle cx="411" cy="67" r="19" fill="#F6DCE4" /><circle cx="436" cy="85" r="19" fill="#F6DCE4" /><circle cx="426" cy="114" r="19" fill="#F6DCE4" /><circle cx="396" cy="114" r="19" fill="#F6DCE4" /><circle cx="386" cy="85" r="19" fill="#F6DCE4" /><circle cx="411" cy="93" r="13" fill="#E4C45C" /></g>
        <g><circle cx="512" cy="44" r="19" fill="#F6DCE4" /><circle cx="537" cy="62" r="19" fill="#F6DCE4" /><circle cx="527" cy="91" r="19" fill="#F6DCE4" /><circle cx="497" cy="91" r="19" fill="#F6DCE4" /><circle cx="487" cy="62" r="19" fill="#F6DCE4" /><circle cx="512" cy="70" r="13" fill="#E4C45C" /></g>
        <g><circle cx="613" cy="67" r="19" fill="#F6DCE4" /><circle cx="638" cy="85" r="19" fill="#F6DCE4" /><circle cx="628" cy="114" r="19" fill="#F6DCE4" /><circle cx="598" cy="114" r="19" fill="#F6DCE4" /><circle cx="588" cy="85" r="19" fill="#F6DCE4" /><circle cx="613" cy="93" r="13" fill="#E4C45C" /></g>
        <g><circle cx="693" cy="132" r="19" fill="#F6DCE4" /><circle cx="718" cy="150" r="19" fill="#F6DCE4" /><circle cx="709" cy="179" r="19" fill="#F6DCE4" /><circle cx="678" cy="179" r="19" fill="#F6DCE4" /><circle cx="669" cy="150" r="19" fill="#F6DCE4" /><circle cx="693" cy="158" r="13" fill="#E4C45C" /></g>
      </g>
    `},hanbok:{headOverFit:`
      <!--
        Jokduri, the jewelled cap worn with hanbok.

        The first two sat ON him rather than covering him: 232 then 364 units wide against a head
        that measures 476 at y 210 and 516 at y 240, so his head showed on both sides of it and it
        read as a bead perched on his forehead. This one COVERS the head, and it does it the way
        the grad cap's crown does - the sides are clipped to #sprout-body-clip so they follow the
        pear exactly at every row instead of following a curve I guessed, and a small unclipped
        dome fills in above y 110 where the body stops and the clip would otherwise cut it off.

        Base is y 252, which is the sorcerer hat's lowest point and clears his face at y 319 by 67.
        The two gold bands follow the base curve, the coral and jade stones sit on the cap face,
        and the cerulean ribbon ends pick up the goreum bow on the jeogori.
      -->
      <g ${A}>
        <path fill="#2A2230" d="M 356 152 C 356 56 668 56 668 152 Z" />
        <path clip-path="url(#sprout-body-clip)" fill="#2A2230"
              d="M 172 88 L 852 88 L 852 196 C 724 240 618 252 512 252
                 C 406 252 300 240 172 196 Z" />
        <path clip-path="url(#sprout-body-clip)" fill="#221A28"
              d="M 172 172 C 300 218 406 232 512 232 C 618 232 724 218 852 172
                 L 852 196 C 724 240 618 252 512 252 C 406 252 300 240 172 196 Z" />
        <path clip-path="url(#sprout-body-clip)" fill="none" stroke="#C9A33A" stroke-width="12"
              d="M 178 180 C 302 226 408 240 512 240 C 616 240 722 226 846 180" />
        <path clip-path="url(#sprout-body-clip)" fill="none" stroke="#C9A33A" stroke-width="7" opacity="0.75"
              d="M 176 204 C 302 248 408 260 512 260 C 616 260 722 248 848 204" />
        <circle cx="512" cy="104" r="21" fill="#E07A72" />
        <circle cx="512" cy="166" r="23" fill="#E07A72" />
        <circle cx="404" cy="182" r="16" fill="#58CC9F" /><circle cx="620" cy="182" r="16" fill="#58CC9F" />
        <circle cx="330" cy="200" r="12" fill="#C9A33A" /><circle cx="694" cy="200" r="12" fill="#C9A33A" />
        <path d="M 268 246 C 238 272 216 278 198 272" fill="none" stroke="#2E6FA8" stroke-width="16" stroke-linecap="round" />
        <path d="M 756 246 C 786 272 808 278 826 272" fill="none" stroke="#2E6FA8" stroke-width="16" stroke-linecap="round" />
      </g>
    `},hex:{headOverFit:`
      <!--
        Bow with bat-wing loops. This is the piece that carries the whole costume: the lane it is
        for is "cute but not sweet", so a plain round bow would land on the wrong side of that and
        a skull would land far past it. The loops are notched into points, the trim is lilac, and
        the knot carries one small skull the size of a dot - at 40px it reads as a highlight, and
        up close it reads as the joke.
      -->
      <g ${A}>
        <path fill="#1A1720" d="M 496 100 L 340 44 L 368 88 L 334 96 L 372 124 L 348 154 L 402 142 L 496 130 Z" />
        <path fill="#1A1720" d="M 528 100 L 684 44 L 656 88 L 690 96 L 652 124 L 676 154 L 622 142 L 528 130 Z" />
        <path fill="none" stroke="#EFE9F4" stroke-width="6" opacity="0.9" d="M 496 100 L 340 44 L 368 88 L 334 96 L 372 124 L 348 154 L 402 142 L 496 130 Z" />
        <path fill="none" stroke="#EFE9F4" stroke-width="6" opacity="0.9" d="M 528 100 L 684 44 L 656 88 L 690 96 L 652 124 L 676 154 L 622 142 L 528 130 Z" />
        <path fill="#1A1720" d="M 486 128 L 538 128 L 556 226 L 512 206 L 468 226 Z" />
        <path fill="#1A1720" d="M 470 92 C 470 66 554 66 554 92 L 554 130 C 554 152 470 152 470 130 Z" />
        <circle cx="512" cy="108" r="15" fill="#F2ECF6" />
        <circle cx="505" cy="105" r="4" fill="#1A1720" /><circle cx="519" cy="105" r="4" fill="#1A1720" />
      </g>
    `},sorcerer:{armRHeld:`
      <g ${j}>
        <!-- Held upright, the same near-vertical angle as the astronaut's flag and the katana. -->
        <path d="M 404 66 L 452 -252" fill="none" stroke="#4A3524" stroke-width="23" stroke-linecap="round" />
        <path d="M 404 66 L 420 -38" fill="none" stroke="#2F2116" stroke-width="28" stroke-linecap="round" />
        <path d="M 424 -44 L 430 -78" fill="none" stroke="#C9A33A" stroke-width="17" stroke-linecap="round" />
        <!--
          No stars. There used to be a gold topper past the tip and two sparkles floating
          beside the shaft; George, 2026-09-10: "make it so that the wand is just the wand,
          don't have stars around the wand". Losing the topper also brings the sorcerer back
          inside the stills' shared box, which its 46-unit star was the tallest thing in.
        -->
      </g>
    `,headOverFit:`
      <!--
        Wizard hat: a filled cone leaning back off a wide brim, with a curled tip and a gold band.
        It covers the tuft, which is why sorcerer is in HIDES_TUFT — a leaf through felt reads as
        a bug. Drawn as one silhouette so the rim filter wraps hat and brim together.
      -->
      <g ${A}>
        <!--
          The tip stops at y -132. #sprout-outline is a userSpaceOnUse filter whose region starts
          at y -160, so anything taller is simply cut off — which is what happened to the first
          version. Keep head gear inside that region.
        -->
        <path fill="#1E2352"
              d="M 302 190 C 336 60 420 -60 542 -122 C 582 -142 622 -140 634 -122
                 C 646 -104 630 -80 602 -62 C 668 4 716 104 722 190 Z" />
        <path fill="#2B3170"
              d="M 302 190 C 336 60 420 -60 542 -122 C 570 -136 598 -140 618 -136
                 C 566 -100 494 -22 452 62 C 424 118 412 168 410 190 Z" />
        <ellipse cx="512" cy="196" rx="300" ry="58" fill="#171B41" />
        <ellipse cx="512" cy="184" rx="300" ry="54" fill="#1E2352" />
        <path d="M 330 166 C 392 126 640 126 700 166" fill="none" stroke="#E7C24B" stroke-width="24" />
        <path d="M 334 180 C 394 144 638 144 696 180" fill="none" stroke="#C9A33A" stroke-width="7" />
        ${P(534,-34,24,`#E7C24B`)}${P(596,-78,16,`#E7C24B`)}${P(470,62,20,`#E7C24B`)}
      </g>
    `,faceOverFit:`
      <!-- Half-moon spectacles, sitting low so the dot eyes still read over the top. -->
      <g fill="none" stroke="#D9B24B" stroke-width="10" stroke-linecap="round">
        <path d="M 286 378 A 66 48 0 0 1 418 378" /><path d="M 286 378 H 418" />
        <path d="M 604 378 A 66 48 0 0 1 736 378" /><path d="M 604 378 H 736" />
        <path d="M 418 376 Q 511 346 604 376" />
        <path d="M 286 378 Q 250 366 224 344" /><path d="M 736 378 Q 772 366 798 344" />
      </g>
    `},idol:{armRHeld:`
      <!-- Handheld mic. Fat grip, not a stick: a thin one reads as a grey lollipop at 40px. -->
      <g ${j}>
        <path d="M 408 74 L 448 -54" fill="none" stroke="#26282C" stroke-width="34" stroke-linecap="round" />
        <path d="M 418 42 L 444 34" fill="none" stroke="#4A4E55" stroke-width="7" stroke-linecap="round" />
        <circle cx="456" cy="-84" r="38" fill="#C8CED6" />
        <circle cx="456" cy="-84" r="38" fill="none" stroke="#9AA2AC" stroke-width="5" />
        <path d="M 432 -96 L 480 -96 M 430 -80 L 482 -80 M 436 -64 L 476 -64" fill="none" stroke="#9AA2AC" stroke-width="5" stroke-linecap="round" />
      </g>
    `},monster:{headOverFit:`
      <!--
        Dinosaur hood. The read that makes it work: the animal's own head sits ABOVE the wearer's -
        eyes on the crown, jaw and teeth arching over the brow, wearer's face in the mouth. The
        versions with teeth and a ridge but no eyes read as a green arch with a comb stuck on it.

        ONE flat green, and it is #587838 - sampled from monster-body.png, not picked by eye. A second
        shade made the hood look like a separate garment sitting on the suit, and the near-miss
        green it used before was not the suit's green either. Cream is #E8D0A8, the suit's own.

        The walls STOP at the collar. The suit's neckline was measured off monster-body.png -
        y 418 at x 180, 490 at the centre, 420 at x 840 - and both feet close at y 444 on a short
        edge that follows it, so the hood tucks into the collar instead of hanging down the body.
        The foot has to land ON the pear (x 172 against a pear edge of 173); a foot beside the
        body would leave a green tab floating in open water. Higher up the wall does sit proud of
        the pear, which is correct - a hood is bulkier than the head inside it.

        Both walls were SOLVED, not drawn: a search over the control points for the shape that
        clears his eyes most while keeping a wall at least 50 thick and the foot on the body.
        Result clears eyes and brow by 28 units, wall 50 at its thinnest, checked against
        mask-face-parts.png - every face element in every state forced visible.

        Teeth and spikes are SAMPLED off the curves, base on the curve and apex along the normal,
        cut few and wide - an even fine row reads as a picket fence and dies at 40px.
      -->
      <g ${A}>
        <path fill="#587838" d="M 172 444 C 104 220 280 10 512 10 C 744 10 920 220 852 444 L 802 468 C 816 268 700 210 512 210 C 324 210 208 268 222 468 Z" />
        <path fill="#E8D0A8" d="M 242 129 L 287 86 L 211 51 Z M 340 52 L 399 27 L 340 -32 Z M 444 16 L 512 10 L 471 -64 Z M 512 10 L 580 16 L 553 -64 Z M 625 27 L 684 52 L 684 -32 Z M 737 86 L 782 129 L 813 51 Z" />
        <path fill="none" stroke="#33501F" stroke-width="24" opacity="0.5" d="M 802 468 C 816 268 700 210 512 210 C 324 210 208 268 222 468" />
        <path fill="none" stroke="#41602A" stroke-width="13" d="M 802 468 C 816 268 700 210 512 210 C 324 210 208 268 222 468" />
        <path fill="none" stroke="#79A257" stroke-width="5" opacity="0.85" d="M 802 468 C 816 268 700 210 512 210 C 324 210 208 268 222 468" />
        <path fill="#E8D0A8" d="M 699 243 L 653 226 L 651 303 Z M 647 224 L 593 214 L 607 291 Z M 591 214 L 530 210 L 556 285 Z M 494 210 L 433 214 L 468 285 Z M 431 214 L 377 224 L 417 291 Z M 371 226 L 325 243 L 373 303 Z" />
        <g>
          <ellipse cx="390" cy="118" rx="54" ry="47" fill="#F3E7C4" />
          <ellipse cx="634" cy="118" rx="54" ry="47" fill="#F3E7C4" />
          <circle cx="399" cy="124" r="26" fill="#22331A" />
          <circle cx="625" cy="124" r="26" fill="#22331A" />
          <circle cx="389" cy="112" r="9" fill="#FFFFFF" opacity="0.8" />
          <circle cx="615" cy="112" r="9" fill="#FFFFFF" opacity="0.8" />
          <path d="M 328 74 L 456 104" fill="none" stroke="#33501F" stroke-width="22" stroke-linecap="round" />
          <path d="M 696 74 L 568 104" fill="none" stroke="#33501F" stroke-width="22" stroke-linecap="round" />
        </g>
      </g>
    `},grad:{headOverFit:`
      <!--
        Mortarboard. Vector, like the sorcerer hat - the generated head pieces are the -top.png
        files in costumes-raster.ts and those are the ones that got thrown out. Crisp edges on a
        piece this size come from paths, not from a 1024px paint upscaled 2.7x.

        What was wrong with the last one, and the actual cause: I made the CROWN cover his tuft.
        The tuft reaches y 19, so the crown had to run from y -14 down to the hem - 268 units of
        rounded black - and that is the fat dome. The BOARD should do that job. It is a diamond,
        so a point is inside it when |dx|/360 + |dy|/80 <= 1, and all four corners of the tuft's box
        (x 477..603, y 19..111, read out of sprout.svg) come to 0.83. The board swallows it whole,
        which frees the crown to be what a real skull-cap is: a shallow BAND that hugs the head.

        That band is clipped to #sprout-body-clip, so it follows the pear exactly instead of being
        a shape I guessed at. It is 85 units deep. On the Pauling photograph the cap below the
        board is about that share of the head, and it hugs - it does not bulge.

        Hem is y 254, which is the sorcerer hat's own lowest point (brim ellipse cy 196 + ry 58).
        His face starts at y 319, so both clear him by 65. An earlier version ran to y 330 and
        sat on his eyes; the asserts above now make that unbuildable.

        Board proportions are off the photograph too: 720 across a head 476 wide at y 210, depth 160
        against that width so it reads as a flat plate seen from above, and a real thickness band
        of 24 under the two front edges rather than an outline.
      -->
      <g ${A}>
        <path clip-path="url(#sprout-body-clip)" fill="#262A32"
              d="M 108 96 L 916 96 L 916 188 C 792 232 648 254 512 254 C 376 254 232 232 108 188 Z" />
        <path clip-path="url(#sprout-body-clip)" fill="#1C1F26"
              d="M 108 172 C 232 220 376 240 512 240 C 648 240 792 220 916 172
                 L 916 190 C 792 234 648 256 512 256 C 376 256 232 234 108 190 Z" />
        <path fill="#171A20" d="M 152 65 L 512 145 L 872 65 L 872 89 L 512 169 L 152 89 Z" />
        <path fill="#2F343D" d="M 152 65 L 512 145 L 872 65 L 512 -15 Z" />
        <path fill="#3C434F" d="M 152 65 L 512 145 L 512 -15 Z" />
        <path d="M 170 61 L 512 -19" fill="none" stroke="#5A6373"
              stroke-width="7" stroke-linecap="round" opacity="0.55" />
        <circle cx="512" cy="65" r="14" fill="#C98A2E" />
      </g>
    `,faceOverFit:`
      <!--
        Tassel, built off a real one rather than as three gold sticks. What a tassel actually is,
        top to bottom: a DOUBLED twisted cord, a short ferrule, a fat rounded KNOB where the cord
        is bound off, a band under it, then a dense COLUMN of strands with a blunt end - and that
        column is several times longer than the knob, not the same size as it.

        So the skirt is a filled shape with strand lines drawn over it, not separate strokes. Three
        thin sticks read as a broom at any size and vanished entirely at 40px. The cord is drawn
        twice, offset, because a real cap cord is two lengths twisted together.

        This lives in faceOverFit, not headOverFit: #costume-head is poured BEFORE the face group,
        so a tassel there would have his blush and eye draw on top of it. It is also the one part
        of the cap allowed below his brow at y 319 - the skirt hangs at x 863..921, beside his
        head in open water, and his face only reaches x 794. The assert holds that gap.
      -->
      <g>
        <path d="M 512 65 C 648 89 782 87 868 67" fill="none"
              stroke="#A96C1C" stroke-width="10" stroke-linecap="round" />
        <path d="M 512 60 C 648 83 782 81 870 61" fill="none"
              stroke="#D9A63F" stroke-width="7" stroke-linecap="round" />
        <path d="M 866 65 C 888 73 892 79 892 91" fill="none"
              stroke="#B0761F" stroke-width="11" stroke-linecap="round" />
        <ellipse cx="892" cy="123" rx="27" ry="33" fill="#D9A63F" />
        <path d="M 872 111 C 868 129 871 141 877 149"
              fill="none" stroke="#F0C976" stroke-width="8" stroke-linecap="round" opacity="0.85" />
        <ellipse cx="892" cy="160" rx="22" ry="9" fill="#A96C1C" />
        <path fill="#C98A2E"
              d="M 870 166 C 863 246 863 253 868 313
                 C 878 327 906 327 916 313
                 C 921 253 921 246 914 166 Z" />
        <g fill="none" stroke="#A96C1C" stroke-width="5" stroke-linecap="round" opacity="0.75">
          <path d="M 878 172 C 875 256 875 263 877 315" />
          <path d="M 892 172 C 889 256 889 263 891 315" />
          <path d="M 906 172 C 903 256 903 263 905 315" />
        </g>
        <path d="M 873 174 C 869 256 869 253 872 309"
              fill="none" stroke="#EFC470" stroke-width="6" stroke-linecap="round" opacity="0.7" />
      </g>
    `,armLHeld:`
      <!--
        Rolled diploma. Held UPRIGHT at the same near-vertical angle as the flag, katana and wand
        — a prop lying across the fin read as a different rig. Deliberately fat: the other three
        props are all thin sticks, so a chunky cylinder is new silhouette for free.
      -->
      <g ${j}>
        <g transform="rotate(-6.4 -439 -60)">
          <rect x="-480" y="-232" width="82" height="344" rx="41" fill="#F2EFE6" />
          <ellipse cx="-439" cy="-232" rx="41" ry="15" fill="#FFFFFF" />
          <ellipse cx="-439" cy="112" rx="41" ry="15" fill="#E0DCD0" />
          <rect x="-490" y="-88" width="102" height="62" rx="10" fill="#C98A2E" />
          <rect x="-490" y="-88" width="102" height="16" rx="8" fill="#DCA945" />
        </g>
      </g>
    `},astronaut:{armRHeld:`
      <!--
        Pulled in 40 units and scaled to 0.75 about the grip, angle untouched (all three held
        props share one angle). At full size the flag reached 1384px of art where the stills'
        shared box is 1293, so its fly was cut off on every card outside Home. Measured, not
        guessed: see design/capture_costumes.py.
      -->
      <g ${j}>
        <!--
          The offset goes on an INNER group. SvgPuppet.apply writes a transform attribute onto
          every held-swing element every frame to swing it from the shoulder, so a transform on
          the outer group is silently wiped - two measuring rounds were lost to that.
        -->
        <g transform="translate(-75 0)">
          <path d="M 406 66 L 452 -318" fill="none" stroke="#C9CED6" stroke-width="19" stroke-linecap="round" />
          <circle cx="454" cy="-326" r="16" fill="#C9CED6" />
          <path fill="#EDF0F4" d="M 452 -306 L 602 -273 L 590 -149 L 440 -182 Z" />
          <path fill="#2E3A5C" d="M 452 -306 L 602 -273 L 597 -211 L 446 -244 Z" />
          <circle cx="506" cy="-272" r="13" fill="#F6E7A8" />
          <circle cx="558" cy="-252" r="9" fill="#F6E7A8" />
        </g>
      </g>
    `,body:`
      <defs>
        <linearGradient id="astro-suit" x1="0" y1="470" x2="0" y2="850" gradientUnits="userSpaceOnUse">
          <stop offset="0" stop-color="#F1F3F7" /><stop offset="0.35" stop-color="#E6EAEF" /><stop offset="1" stop-color="#DADFE6" />
        </linearGradient>
        <linearGradient id="astro-shade" x1="0" y1="500" x2="0" y2="600" gradientUnits="userSpaceOnUse">
          <stop offset="0" stop-color="#9AA3AE" stop-opacity="0.55" /><stop offset="1" stop-color="#9AA3AE" stop-opacity="0" />
        </linearGradient>
        <radialGradient id="astro-panel" cx="0.4" cy="0.35" r="0.8">
          <stop offset="0" stop-color="#D6DBE2" /><stop offset="1" stop-color="#BCC3CC" />
        </radialGradient>
        <linearGradient id="astro-ring" x1="0" y1="430" x2="0" y2="575" gradientUnits="userSpaceOnUse">
          <stop offset="0" stop-color="#EEF1F5" /><stop offset="0.45" stop-color="#B9C0C9" /><stop offset="1" stop-color="#7E8791" />
        </linearGradient>
        <radialGradient id="astro-glass" cx="0.42" cy="0.38" r="0.62">
          <stop offset="0" stop-color="#DDF0FA" stop-opacity="0.04" /><stop offset="0.72" stop-color="#BFE3F4" stop-opacity="0.16" /><stop offset="1" stop-color="#AFD6EC" stop-opacity="0.42" />
        </radialGradient>
        <linearGradient id="astro-cuff" x1="0" y1="-170" x2="0" y2="170" gradientUnits="userSpaceOnUse">
          <stop offset="0" stop-color="#D9DEE5" /><stop offset="1" stop-color="#AEB5BF" />
        </linearGradient>
      </defs>
      <g class="el-suit" ${D}>
        <rect x="0" y="440" width="982" height="440" fill="url(#astro-suit)" />
        <rect x="0" y="500" width="982" height="100" fill="url(#astro-shade)" />
      </g>
      <g class="el-panel" ${D}>
        <ellipse cx="512" cy="704" rx="200" ry="114" fill="url(#astro-panel)" />
        <path d="M 512 520 V 850" fill="none" stroke="#C4CAD2" stroke-width="9" />
        <path d="M 512 590 V 818" fill="none" stroke="#A8B0BA" stroke-width="7" />
      </g>
      <g class="el-patch" ${D}>
        <circle cx="656" cy="602" r="41" fill="#2E3A5C" stroke="#8E969F" stroke-width="6" />
        <circle cx="656" cy="602" r="11" fill="#F6E7A8" />
        <ellipse cx="656" cy="602" rx="27" ry="7" fill="none" stroke="#F6E7A8" stroke-width="3.5" transform="rotate(-24 656 602)" />
      </g>`,head:`
      <g class="el-ring">
        <!-- Back rim of the torus. The head, re-drawn in the coat colour, hides it where it crosses him. -->
        <ellipse cx="512" cy="462" rx="380" ry="62" fill="none" stroke="#D5DCE3" stroke-width="34" />
        <path class="sprout-fill" fill="#B08EE0"
              d="M 512 94 C 600 94 670 116 722 174 C 774 232 830 338 854 458 L 858 472 L 166 472 L 170 458 C 194 338 250 232 302 174 C 354 116 424 94 512 94 Z" />
      </g>`,headOverFit:`
      <g class="el-ring">
        <!--
          Collar measured off the approved mockup (wisp/mock-5-dome-tight.png): centre line at y 478,
          just under the mouth, 760 wide, a little wider than the pear. Back rim first, then the head
          re-drawn in the coat colour down to the centre line, so he rises out of the ring.
        -->
        <ellipse cx="512" cy="478" rx="380" ry="72" fill="none" stroke="#D7DDE4" stroke-width="44" />
        <ellipse cx="512" cy="478" rx="380" ry="72" fill="none" stroke="#8E969F" stroke-width="5" transform="translate(0 -22)" />
        <path class="sprout-fill" fill="#B08EE0"
              d="M 512 94 C 600 94 670 116 722 174 C 774 232 830 338 854 458 L 858 478 L 166 478 L 170 458 C 194 338 250 232 302 174 C 354 116 424 94 512 94 Z" />
      </g>
    `,faceOverFit:`
      <defs>
        <radialGradient id="astro-glass2" cx="0.42" cy="0.36" r="0.64">
          <stop offset="0" stop-color="#E8F5FC" stop-opacity="0.02" />
          <stop offset="0.66" stop-color="#C6E4F3" stop-opacity="0.14" />
          <stop offset="0.9" stop-color="#A9CFE6" stop-opacity="0.36" />
          <stop offset="1" stop-color="#8FB8D6" stop-opacity="0.55" />
        </radialGradient>
        <linearGradient id="astro-torus" x1="0" y1="430" x2="0" y2="560" gradientUnits="userSpaceOnUse">
          <stop offset="0" stop-color="#F0F3F6" /><stop offset="0.42" stop-color="#C3CAD2" /><stop offset="1" stop-color="#7E8791" />
        </linearGradient>
      </defs>
      <g class="el-dome">
        <!--
          Glass bubble, same width as the ring (r 381 about 512,297: top at -84 like the mockup). Its
          base follows the front band's inner edge, and the band is drawn over it, so no head shows between glass and collar, so it sits IN
          the collar, not on top of it.
        -->
        <path d="M 189 498 A 381 381 0 1 1 835 498 A 380 39 0 0 1 189 498 Z" fill="url(#astro-glass2)" />
        <path d="M 189 498 A 381 381 0 1 1 835 498" fill="none" stroke="#9FA9B4" stroke-width="22" opacity="0.55" />
        <path d="M 189 498 A 381 381 0 1 1 835 498" fill="none" stroke="#D9E1E8" stroke-width="13" />
        <path d="M 189 498 A 381 381 0 1 1 835 498" fill="none" stroke="#FFFFFF" stroke-width="5" opacity="0.9" />
        <path d="M 236 190 C 268 104 330 40 414 4" fill="none" stroke="#FFFFFF" stroke-width="26" stroke-linecap="round" opacity="0.92" />
        <path d="M 202 296 C 208 258 220 224 238 194" fill="none" stroke="#FFFFFF" stroke-width="16" stroke-linecap="round" opacity="0.7" />
        <path d="M 800 470 C 844 410 866 340 862 266" fill="none" stroke="#FFFFFF" stroke-width="9" stroke-linecap="round" opacity="0.32" />
      </g>
      <g class="el-ring">
        <!-- Front of the torus over the glass base: graded band, glint on top, dark lip under, rounded ends. -->
        <path d="M 132 478 A 380 72 0 0 0 892 478" fill="none" stroke="url(#astro-torus)" stroke-width="66" />
        <path d="M 132 478 A 380 50 0 0 0 892 478" fill="none" stroke="#FFFFFF" stroke-width="7" opacity="0.7" />
        <path d="M 132 478 A 380 100 0 0 0 892 478" fill="none" stroke="#6F7883" stroke-width="8" />
        <circle cx="132" cy="478" r="33" fill="url(#astro-torus)" /><circle cx="892" cy="478" r="33" fill="url(#astro-torus)" />
        <circle cx="132" cy="478" r="33" fill="none" stroke="#6F7883" stroke-width="4" opacity="0.6" /><circle cx="892" cy="478" r="33" fill="none" stroke="#6F7883" stroke-width="4" opacity="0.6" />
      </g>
    `,face:`
      <g class="el-dome">
        <!-- Glass: circle r 381 about (512, 297), cut where it meets the ring's back rim. -->
        <path d="M 219 540 A 381 381 0 1 1 805 540 A 380 42 0 0 0 219 540 Z" fill="url(#astro-glass)" />
        <path d="M 219 540 A 381 381 0 1 1 805 540" fill="none" stroke="#C9D1DA" stroke-width="16" />
        <path d="M 219 540 A 381 381 0 1 1 805 540" fill="none" stroke="#FFFFFF" stroke-width="6" opacity="0.75" />
        <path d="M 228 172 C 262 92 328 30 410 -12" fill="none" stroke="#FFFFFF" stroke-width="22" stroke-linecap="round" opacity="0.8" />
        <path d="M 190 278 C 196 244 208 212 226 184" fill="none" stroke="#FFFFFF" stroke-width="14" stroke-linecap="round" opacity="0.55" />
        <path d="M 760 640 C 810 590 838 530 846 470" fill="none" stroke="#FFFFFF" stroke-width="10" stroke-linecap="round" opacity="0.35" />
      </g>
      <g class="el-ring">
        <!-- Front of the torus: one graded band reads as a round tube; a glint on top, a dark lip below. -->
        <path d="M 132 462 A 380 62 0 0 0 892 462" fill="none" stroke="url(#astro-ring)" stroke-width="72" />
        <path d="M 132 462 A 380 40 0 0 0 892 462" fill="none" stroke="#FFFFFF" stroke-width="9" opacity="0.7" />
        <path d="M 132 462 A 380 92 0 0 0 892 462" fill="none" stroke="#6F7883" stroke-width="8" />
      </g>`,armL:`<g class="el-suit" ${O}>${M(-520,100,`#E6EAEF`)}<rect x="-520" y="-170" width="620" height="340" fill="url(#astro-shade)" opacity="0" /></g><g class="el-panel" ${O}><rect x="-474" y="-170" width="44" height="340" fill="url(#astro-cuff)" /><rect x="-436" y="-170" width="7" height="340" fill="#8E969F" /></g>`,armR:`<g class="el-suit" ${k}>${N(-520,100,`#E6EAEF`)}</g><g class="el-panel" ${k}><rect x="430" y="-170" width="44" height="340" fill="url(#astro-cuff)" /><rect x="429" y="-170" width="7" height="340" fill="#8E969F" /></g>`},racer:{faceOverFit:`
      <!--
        Worn, not pushed up: the lenses sit on the dot eyes and the whole thing stays inside the
        head, which is 200..824 wide at eye height. The first pass had them on the forehead with
        frames hanging off both sides of his face.
      -->
      <g>
        <path d="M 246 356 C 300 336 724 336 778 356" fill="none" stroke="#22315C" stroke-width="26" stroke-linecap="round" />
        <rect x="258" y="318" width="190" height="112" rx="50" fill="#2B2F33" />
        <rect x="576" y="318" width="190" height="112" rx="50" fill="#2B2F33" />
        <rect x="278" y="336" width="150" height="76" rx="34" fill="#8FCBE8" />
        <rect x="596" y="336" width="150" height="76" rx="34" fill="#8FCBE8" />
        <path d="M 296 348 L 340 388" stroke="#FFFFFF" stroke-width="12" opacity="0.5" stroke-linecap="round" fill="none" />
        <path d="M 614 348 L 658 388" stroke="#FFFFFF" stroke-width="12" opacity="0.5" stroke-linecap="round" fill="none" />
        <path d="M 448 372 H 576" fill="none" stroke="#2B2F33" stroke-width="20" stroke-linecap="round" />
      </g>
    `,body:`
      <g ${D}>
        <rect x="0" y="480" width="982" height="400" fill="#23305A" />
        <!-- Collar, sponsor stripes, and a blocky 7. -->
        <path d="M 420 480 L 512 560 L 604 480 Z" fill="#F2F4F6" />
        <rect x="300" y="520" width="118" height="22" rx="6" fill="#E8433C" /><rect x="300" y="550" width="80" height="18" rx="6" fill="#F2F4F6" />
        <rect x="664" y="520" width="118" height="22" rx="6" fill="#F2F4F6" /><rect x="702" y="550" width="80" height="18" rx="6" fill="#E8433C" />
        <polygon points="446,606 578,606 578,640 528,776 480,776 528,640 446,640" fill="#F2F4F6" />
        <path d="M 0 800 H 982" stroke="#E8433C" stroke-width="14" />
      </g>`,head:`
      <g ${D}><path d="M 108 276 C 288 218, 736 218, 916 276" fill="none" stroke="#2B2F33" stroke-width="30" /></g>
      <g ${A}>
        <rect x="360" y="226" width="130" height="74" rx="32" fill="#BFE3F4" stroke="#2B2F33" stroke-width="11" />
        <rect x="492" y="226" width="130" height="74" rx="32" fill="#BFE3F4" stroke="#2B2F33" stroke-width="11" />
        <rect x="484" y="250" width="16" height="26" rx="6" fill="#2B2F33" />
        <path d="M 386 248 C 400 236 424 234 440 240" fill="none" stroke="#FFFFFF" stroke-width="8" stroke-linecap="round" opacity="0.8" />
        <path d="M 518 248 C 532 236 556 234 572 240" fill="none" stroke="#FFFFFF" stroke-width="8" stroke-linecap="round" opacity="0.8" />
      </g>`,armL:`<g ${O}>${M(-520,100,`#23305A`)}<rect x="-300" y="-170" width="22" height="340" fill="#F2F4F6" /><rect x="-270" y="-170" width="22" height="340" fill="#E8433C" /></g>`,armR:`<g ${k}>${N(-520,100,`#23305A`)}<rect x="278" y="-170" width="22" height="340" fill="#F2F4F6" /><rect x="248" y="-170" width="22" height="340" fill="#E8433C" /></g>`},biker:{faceOverFit:`
      <!-- Aviators. Teardrop lenses over the dot eyes, a brow bar, and temples that stop on the head. -->
      <g>
        <path d="M 262 340 H 438 C 438 424 402 456 352 456 C 300 456 262 410 262 340 Z" fill="#1E2024" opacity="0.9" />
        <path d="M 585 340 H 761 C 761 424 725 456 671 456 C 621 456 585 410 585 340 Z" fill="#1E2024" opacity="0.9" />
        <path d="M 438 356 C 482 344 541 344 585 356" fill="none" stroke="#2B2F33" stroke-width="13" />
        <path d="M 256 340 H 767" fill="none" stroke="#2B2F33" stroke-width="15" stroke-linecap="round" />
        <path d="M 262 350 Q 230 342 212 326" fill="none" stroke="#2B2F33" stroke-width="12" stroke-linecap="round" />
        <path d="M 761 350 Q 793 342 811 326" fill="none" stroke="#2B2F33" stroke-width="12" stroke-linecap="round" />
        <path d="M 292 362 L 344 408" stroke="#FFFFFF" stroke-width="11" opacity="0.32" stroke-linecap="round" fill="none" />
        <path d="M 615 362 L 667 408" stroke="#FFFFFF" stroke-width="11" opacity="0.32" stroke-linecap="round" fill="none" />
      </g>
    `,body:`
      <g ${D}>
        <rect x="0" y="476" width="982" height="400" fill="#1B1D22" />
        <!-- White tee in the V, lapels, zip, studs, belt. -->
        <path d="M 426 476 L 512 660 L 598 476 Z" fill="#F4F4F4" />
        <path d="M 426 476 L 482 476 L 512 660 Z" fill="#2A2E35" /><path d="M 598 476 L 542 476 L 512 660 Z" fill="#2A2E35" />
        <path d="M 512 660 V 850" fill="none" stroke="#C9CED6" stroke-width="7" />
        <rect x="503" y="700" width="18" height="30" rx="5" fill="#C9CED6" />
        <g fill="#C9CED6"><circle cx="286" cy="506" r="8" /><circle cx="316" cy="496" r="8" /><circle cx="346" cy="490" r="8" /><circle cx="696" cy="506" r="8" /><circle cx="666" cy="496" r="8" /><circle cx="636" cy="490" r="8" /></g>
        <rect x="0" y="796" width="982" height="34" fill="#0F1114" />
        <rect x="488" y="790" width="48" height="46" rx="8" fill="#C9CED6" /><rect x="500" y="802" width="24" height="22" rx="4" fill="#0F1114" />
      </g>`,face:`
      <!-- Aviators: wide at the brow, narrowing to the cheek, big enough to cover the whole eye. -->
      <g stroke="#C9A85B" stroke-width="6">
        <path d="M 262 340 C 262 300 300 292 352 294 C 404 292 442 300 442 340 C 442 400 414 446 358 446 C 302 446 262 400 262 340 Z" fill="#23262B" opacity="0.95" />
        <path d="M 720 340 C 720 300 682 292 630 294 C 578 292 540 300 540 340 C 540 400 568 446 624 446 C 680 446 720 400 720 340 Z" fill="#23262B" opacity="0.95" />
        <path d="M 442 330 Q 491 314 540 330" fill="none" stroke-width="8" />
        <path d="M 262 334 Q 224 322 206 296" fill="none" stroke-width="8" /><path d="M 720 334 Q 758 322 776 296" fill="none" stroke-width="8" />
      </g>
      <path d="M 292 322 C 306 306 332 300 356 304" fill="none" stroke="#FFFFFF" stroke-width="8" stroke-linecap="round" opacity="0.35" />
      <path d="M 570 322 C 584 306 610 300 634 304" fill="none" stroke="#FFFFFF" stroke-width="8" stroke-linecap="round" opacity="0.35" />`,armL:`<g ${O}>${M(-520,100,`#1B1D22`)}<rect x="-456" y="-170" width="8" height="340" fill="#C9CED6" /></g>`,armR:`<g ${k}>${N(-520,100,`#1B1D22`)}<rect x="448" y="-170" width="8" height="340" fill="#C9CED6" /></g>`},pajamas:{body:`
      <g ${D}>
        <rect x="0" y="446" width="982" height="440" fill="#F5EBD9" />
        <path d="M 270 474 C 340 420 684 420 754 474 C 690 506 334 506 270 474 Z" fill="#EADCC6" />
        <g fill="#EADCC6"><circle cx="512" cy="566" r="11" /><circle cx="512" cy="632" r="11" /><circle cx="512" cy="698" r="11" /></g>
        ${P(330,560,16,`#B08EE0`,`costume-blush`)}${P(420,700,14,`#B08EE0`,`costume-blush`)}${P(300,700,13,`#B08EE0`,`costume-blush`)}
        ${P(610,590,15,`#B08EE0`,`costume-blush`)}${P(690,690,14,`#B08EE0`,`costume-blush`)}${P(560,780,13,`#B08EE0`,`costume-blush`)}
        ${P(380,800,12,`#B08EE0`,`costume-blush`)}${P(700,560,12,`#B08EE0`,`costume-blush`)}
      </g>`,armL:`<g ${O}>${M(-520,100,`#F5EBD9`)}<rect x="-470" y="-170" width="44" height="340" fill="#EADCC6" /></g>`,armR:`<g ${k}>${N(-520,100,`#F5EBD9`)}<rect x="426" y="-170" width="44" height="340" fill="#EADCC6" /></g>
      <!-- Cocoa, held at the fin tip so it rides the wave. -->
      <g transform="translate(404 40)" ${A}>
        <rect x="-30" y="-24" width="60" height="58" rx="10" fill="#FFFFFF" />
        <path d="M 30 -8 C 54 -8 54 22 30 22" fill="none" stroke="#FFFFFF" stroke-width="10" />
        <ellipse cx="0" cy="-22" rx="26" ry="8" fill="#6B4A2E" />
        <rect x="-30" y="8" width="60" height="10" fill="#EADCC6" />
      </g>`}},Ie=(e,t)=>t?`<g class="costume" data-costume="${e}" display="none">${t}</g>`:``;function Le(e,t){let n=De.map(e=>e.id),r=e=>{let t=E[e];if(t){let n=Fe[e];return{...t,armL:(t.armL??``)+(n.armLHeld??``),armR:(t.armR??``)+(n.armRHeld??``),head:n.headOverFit??``,face:n.faceOverFit??``}}return Ee[e]??Fe[e]},i=e=>n.map(t=>Ie(t,r(t)[e])).join(``);return e.replace(`<g class="costume-arm-l"></g>`,`<g class="costume-arm-l">${i(`armL`)}</g>`).replace(`<g class="costume-arm-r"></g>`,`<g class="costume-arm-r">${i(`armR`)}</g>`).replace(`<g id="costume-body"></g>`,`<g id="costume-body" class="no-flip">${i(`body`)}</g>`).replace(`<g id="costume-head"></g>`,`<g id="costume-head" class="no-flip">${i(`head`)}</g>`).replace(`<g id="costume-face"></g>`,`<g id="costume-face" class="no-flip">${i(`face`)}</g>`)}function Re(e,t,n,r,i){let a=r.costume?Me(t,n,i):null;for(let t of e.querySelectorAll(`.costume`))t.dataset.costume===a?t.removeAttribute(`display`):t.setAttribute(`display`,`none`);for(let t of e.querySelectorAll(`.costume-blush`))t.setAttribute(`fill`,n.blush);let o=e.querySelector(`#tuft`);o&&(o.style.display=a&&Pe.has(a)?`none`:``),Te(e,he[0],n,r)}function ze(e,t,n=!1){let r=n?Math.random()*Math.PI*2:Math.PI/2+(Math.random()-.5)*.8,i=n?40+Math.random()*80:8+Math.random()*18;return{kind:`drop`,x:e+(Math.random()-.5)*16,y:t+(Math.random()-.5)*8,vx:Math.cos(r)*i,vy:Math.sin(r)*i,life:0,maxLife:.45+Math.random()*.5,size:3+Math.random()*4,rot:0,spin:0,alpha:.7}}function Be(e,t){let n=Math.random()*Math.PI*2,r=50+Math.random()*150;return{kind:`spark`,x:e,y:t,vx:Math.cos(n)*r,vy:Math.sin(n)*r,life:0,maxLife:.35+Math.random()*.4,size:1.5+Math.random()*2.4,rot:n,spin:(Math.random()-.5)*8,alpha:1}}function Ve(e,t){return{kind:`zzz`,x:e+18+Math.random()*10,y:t-28,vx:8+Math.random()*10,vy:-22-Math.random()*12,life:0,maxLife:1.6,size:14+Math.random()*6,rot:(Math.random()-.5)*.4,spin:.4,alpha:.9}}function He(e,t,n=20){return{kind:`ring`,x:e,y:t,vx:0,vy:0,life:0,maxLife:.7,size:n,rot:0,spin:0,alpha:.7}}function Ue(e,t){return{kind:`heart`,x:e+(Math.random()-.5)*48,y:t-24-Math.random()*22,vx:(Math.random()-.5)*36,vy:-56-Math.random()*36,life:0,maxLife:1.15+Math.random()*.5,size:11+Math.random()*7,rot:(Math.random()-.5)*.5,spin:(Math.random()-.5)*1.4,alpha:1}}function We(e,t,n={}){let r=n.burst??!1,i=n.size??(r?3+Math.random()*7:5+Math.random()*11);return{kind:`bubble`,x:e+(Math.random()-.5)*(r?28:10),y:t+(Math.random()-.5)*(r?18:8),vx:(Math.random()-.5)*(r?56:18),vy:n.rise??-28-Math.random()*(r?70:42),life:0,maxLife:r?.7+Math.random()*.7:2.2+Math.random()*2.6,size:i,rot:Math.random()*Math.PI*2,spin:1.4+Math.random()*2.2,alpha:.42+Math.random()*.28}}function Ge(e,t,n){let r=Math.random()*Math.PI*2,i=1.12+Math.random()*.33;return{kind:`mote`,x:e+Math.cos(r)*n*2.05*i,y:t+Math.sin(r)*n*1.3*i,vx:(Math.random()-.5)*6,vy:-6-Math.random()*8,life:0,maxLife:2.6+Math.random()*1.6,size:2+Math.random()*2,rot:Math.random()*Math.PI*2,spin:.8+Math.random()*.8,alpha:0}}function Ke(e,t){for(let n=e.length-1;n>=0;n--){let r=e[n];r.life+=t;let i=r.life/r.maxLife;r.x+=r.vx*t,r.y+=r.vy*t,r.rot+=r.spin*t,r.kind===`drop`?(r.vy+=70*t,r.alpha=(1-i)*.65):r.kind===`spark`?(r.vx*=1-1.8*t,r.vy*=1-1.8*t,r.alpha=1-i):r.kind===`zzz`?r.alpha=i<.15?i/.15:1-(i-.15)/.85:r.kind===`heart`?(r.vy+=18*t,r.alpha=i<.12?i/.12:1-(i-.12)/.88):r.kind===`bubble`?(r.x+=Math.sin(r.rot)*18*t,r.vx*=1-.55*t,r.vy*=1-.12*t,r.vy-=8*t,r.size+=3.4*t,r.alpha=(i<.08?i/.08:i>.78?1-(i-.78)/.22:1)*.38):r.kind===`mote`?(r.x+=Math.sin(r.rot)*10*t,r.vy-=2*t,r.alpha=(i<.25?i/.25:i>.7?1-(i-.7)/.3:1)*.9):(r.size+=140*t,r.alpha=(1-i)*.5),r.life>=r.maxLife&&e.splice(n,1)}}function qe(e,t){for(let n of t){if(e.save(),e.translate(n.x,n.y),e.rotate(n.kind===`bubble`?0:n.rot),e.globalAlpha=Math.max(0,n.alpha),n.kind===`drop`)e.fillStyle=`#9BE8D0`,e.beginPath(),e.ellipse(0,0,n.size*.85,n.size*.65,0,0,Math.PI*2),e.fill();else if(n.kind===`spark`)e.strokeStyle=`#F6C84C`,e.lineWidth=1.6,e.lineCap=`round`,e.beginPath(),e.moveTo(-n.size*2.2,0),e.lineTo(n.size*2.2,0),e.stroke();else if(n.kind===`zzz`)e.fillStyle=`rgba(70, 120, 108, 0.8)`,e.font=`600 ${n.size}px ui-rounded, -apple-system, sans-serif`,e.fillText(`z`,0,0);else if(n.kind===`heart`){e.fillStyle=`#F4A0B4`,e.beginPath();let t=n.size;e.moveTo(0,t*.4),e.bezierCurveTo(-t,-t*.15,-t*.55,-t,0,-t*.4),e.bezierCurveTo(t*.55,-t,t,-t*.15,0,t*.4),e.fill()}else if(n.kind===`bubble`){let t=n.size;e.fillStyle=`rgba(210, 242, 255, 0.16)`,e.strokeStyle=`rgba(255, 255, 255, 0.55)`,e.lineWidth=Math.max(1,t*.12),e.beginPath(),e.arc(0,0,t,0,Math.PI*2),e.fill(),e.stroke(),e.strokeStyle=`rgba(255, 255, 255, 0.95)`,e.lineWidth=Math.max(1.1,t*.14),e.lineCap=`round`,e.beginPath(),e.arc(-t*.22,-t*.28,t*.42,-Math.PI*.85,-Math.PI*.15),e.stroke(),e.fillStyle=`rgba(255, 255, 255, 0.55)`,e.beginPath(),e.arc(-t*.28,-t*.32,t*.16,0,Math.PI*2),e.fill()}else n.kind===`mote`?(e.fillStyle=`rgba(214, 255, 238, 0.22)`,e.beginPath(),e.arc(0,0,n.size*3.6,0,Math.PI*2),e.fill(),e.fillStyle=`rgba(224, 255, 242, 0.45)`,e.beginPath(),e.arc(0,0,n.size*2,0,Math.PI*2),e.fill(),e.fillStyle=`#F2FFF8`,e.beginPath(),e.arc(0,0,n.size,0,Math.PI*2),e.fill()):(e.strokeStyle=`rgba(80, 190, 160, ${n.alpha})`,e.lineWidth=2.5,e.beginPath(),e.arc(0,0,n.size,0,Math.PI*2),e.stroke());e.restore()}}var Je={sprout:{l:{x:318,y:452},r:{x:706,y:452},tuft:{x:512,y:90},tail:null,restL:-12,restR:12},sail:{l:{x:300,y:428},r:{x:724,y:428},tuft:{x:512,y:268},tail:{x:512,y:586},restL:0,restR:0}},Ye=class{root;held=[];armL;armR;tuft;tail;pivots;eyeDots;eyeShine;eyeHappy;eyeSleep;mouths;lumen;lumenTuft;lumenHalo;lumenCore;lumenHot;noFlip;constructor(e){this.root=e,this.armL=Xe(e,`#arm-l`),this.armR=Xe(e,`#arm-r`),this.tuft=Xe(e,`#tuft`),this.tail=e.querySelector(`#tail`),this.held=[...e.querySelectorAll(`.held-swing`)],this.lumen=[...e.querySelectorAll(`.lumen`)],this.lumenTuft=e.querySelector(`#lumen-tuft`),this.lumenHalo=e.querySelector(`#lumen-halo`),this.lumenCore=e.querySelector(`#lumen-core`),this.lumenHot=e.querySelector(`#lumen-hot`),this.pivots=Je[e.id]??Je.sprout;let t=[...e.querySelectorAll(`.no-flip`)];this.noFlip=t.filter(e=>!t.some(t=>t!==e&&t.contains(e))).map(e=>({node:e,base:e.getAttribute(`transform`)??``})),this.eyeDots=[...e.querySelectorAll(`.eye-dot`)],this.eyeShine=[...e.querySelectorAll(`.eye-shine`)],this.eyeHappy=[...e.querySelectorAll(`.eye-happy`)],this.eyeSleep=[...e.querySelectorAll(`.eye-sleep`)],this.mouths={smile:[...e.querySelectorAll(`.mouth.smile`)],open:[...e.querySelectorAll(`.mouth.open`)],o:[...e.querySelectorAll(`.mouth.o`)],flat:[...e.querySelectorAll(`.mouth.flat`)]}}apply(e,t){let n=fe(t,e.scale),r=e.facing*n*e.squashX,i=n*e.squashY,a=e.rot*180/Math.PI;this.root.style.transform=`translate(${e.x}px, ${e.y}px) rotate(${a}deg) scale(${r}, ${i}) translate(${-y.originX}px, ${-y.originY}px)`,this.root.style.filter=Math.abs(e.brightness-1)>.005?`brightness(${e.brightness})`:``,this.root.style.opacity=e.opacity<.995?String(e.opacity):``;let o=e.facing<0?`translate(1024 0) scale(-1 1)`:``;for(let{node:e,base:t}of this.noFlip){let n=o?`${o} ${t}`.trim():t;n?e.setAttribute(`transform`,n):e.removeAttribute(`transform`)}for(let t of this.held)t.setAttribute(`transform`,e.heldSwing?`rotate(${e.heldSwing.toFixed(2)})`:``);let s=e.armL*180/Math.PI,c=e.armR*180/Math.PI,l=e.sprout*180/Math.PI,u=this.pivots;this.armL.setAttribute(`transform`,`translate(${u.l.x} ${u.l.y}) rotate(${u.restL+s})`),this.armR.setAttribute(`transform`,`translate(${u.r.x} ${u.r.y}) rotate(${u.restR+c})`),this.tuft.setAttribute(`transform`,`translate(${u.tuft.x} ${u.tuft.y}) rotate(${l})`),this.lumenTuft&&this.lumenTuft.setAttribute(`transform`,`translate(${u.tuft.x} ${u.tuft.y}) rotate(${l})`);for(let t of this.lumen)t!==this.lumenCore&&t!==this.lumenHot&&(t.style.opacity=String(Math.min(1,e.glow)));let d=Math.min(1,Math.max(0,(e.glow-.72)/.58));if(this.lumenCore&&(this.lumenCore.style.opacity=String(.5+.5*d)),this.lumenHot&&(this.lumenHot.style.opacity=String(.12+.6*d)),this.lumenHalo){let t=.9+e.glow*.18;this.lumenHalo.setAttribute(`transform`,`translate(512 655) scale(${t}) translate(-512 -655)`)}this.tail&&u.tail&&this.tail.setAttribute(`transform`,`translate(${u.tail.x} ${u.tail.y}) rotate(${-l*.7})`);let f=e.happyEyes>.4,p=e.eyeOpen<.08&&!f;for(let t of this.eyeDots)if(t.style.display=f||p?`none`:`block`,!f&&!p){let n=t.getAttribute(`cx`),r=t.getAttribute(`cy`);t.setAttribute(`transform`,`translate(${n} ${r}) scale(1 ${Math.max(e.eyeOpen,.12)}) translate(${-Number(n)} ${-Number(r)})`)}else t.removeAttribute(`transform`);for(let e of this.eyeShine)e.style.display=f||p?`none`:`block`;for(let e of this.eyeHappy)e.style.display=f?`block`:`none`;for(let e of this.eyeSleep)e.style.display=p?`block`:`none`;for(let[t,n]of Object.entries(this.mouths))for(let r of n)r.style.display=t===e.mouth?`block`:`none`}};function Xe(e,t){let n=e.querySelector(t);if(!n)throw Error(`Missing ${t}`);return n}var Ze=class{canvas;fx;ctx;fxCtx;puppet;playground;tank;transparent;anchorBottom=!1;w=0;h=0;dpr=1;constructor(e,t,n,r,i,a=!1){let o=e.getContext(`2d`,{alpha:a}),s=t.getContext(`2d`,{alpha:!0});if(!o||!s)throw Error(`Canvas 2D is unavailable`);this.canvas=e,this.fx=t,this.ctx=o,this.fxCtx=s,this.playground=r,this.tank=i,this.transparent=a,this.puppet=new Ye(n)}resize(){this.dpr=Math.min(window.devicePixelRatio||1,2.25),this.w=window.innerWidth,this.h=window.innerHeight,Qe(this.canvas,this.ctx,this.w,this.h,this.dpr),Qe(this.fx,this.fxCtx,this.w,this.h,this.dpr)}setTank(e,t){this.tank=e,this.playground=t}setPuppet(e){this.puppet=new Ye(e)}draw(e,t){Ke(e.particles,t);let n=e.pose(),r=this.ctx;this.drawPlayground(r),this.puppet.apply(n,e.radius);let i=this.fxCtx;i.clearRect(0,0,this.w,this.h),qe(i,e.particles),n.flash>0&&(i.fillStyle=`rgba(255, 248, 210, ${n.flash*.28})`,i.fillRect(0,0,this.w,this.h))}drawPlayground(e){if(this.transparent){e.clearRect(0,0,this.w,this.h);return}let t=this.playground;if(e.fillStyle=this.anchorBottom?this.tank.floor:this.tank.wash,e.fillRect(0,0,this.w,this.h),!t.width||!t.height)return;let n=Math.max(this.w/t.width,this.h/t.height),r=t.width*n,i=t.height*n,a=this.anchorBottom?this.h-i:(this.h-i)/2;e.drawImage(t,(this.w-r)/2,a,r,i)}};function Qe(e,t,n,r,i){e.width=Math.round(n*i),e.height=Math.round(r*i),e.style.width=`${n}px`,e.style.height=`${r}px`,t.setTransform(i,0,0,i,0,0),t.imageSmoothingEnabled=!0,t.imageSmoothingQuality=`high`}function $e(e){return new Promise((t,n)=>{let r=new Image;r.onload=()=>t(r),r.onerror=()=>n(Error(`Failed to load ${e}`)),r.src=e})}var et={linear:e=>e,in:e=>e*e*e,out:w,inOut:pe,outBack:me};function F(e,t){if(t<=e[0][0])return e[0][1];for(let n=1;n<e.length;n++){let[r,i,a=`linear`]=e[n];if(t>r)continue;let[o,s]=e[n-1];if(a===`hold`)return s;let c=r===o?1:(t-o)/(r-o);return x(s,i,et[a](c))}return e[e.length-1][1]}function tt(e,t){let n=e[0][1];for(let[r,i]of e)if(t>=r)n=i;else break;return n}var nt={vanish:{id:`vanish`,name:`Vanish`,duration:2,mirror:[`rot`,`x`],tracks:{alpha:[[0,1],[.4,1,`hold`],[.5,0,`in`],[1.08,0,`hold`],[1.14,1,`out`]],scale:[[0,1],[.28,.93,`inOut`],[.36,1.07,`out`],[.5,.22,`in`],[1.08,.22,`hold`],[1.22,1.17,`outBack`],[1.48,1,`inOut`]],squash:[[0,1],[.28,1.2,`inOut`],[.36,.82,`out`],[.5,1,`in`],[1.08,1,`hold`],[1.18,.86,`out`],[1.32,1.09,`inOut`],[1.54,1,`inOut`]],y:[[0,0],[.28,12,`inOut`],[.36,-14,`out`],[.5,-38,`in`],[1.08,24,`hold`],[1.26,-8,`out`],[1.54,0,`inOut`]],rot:[[0,0],[.28,-.08,`inOut`],[.36,.05,`out`],[.5,.55,`in`],[1.08,-.32,`hold`],[1.24,.09,`outBack`],[1.54,0,`inOut`]],eye:[[0,1],[.22,.38,`inOut`],[1.08,.38,`hold`],[1.14,1,`out`],[1.38,1,`hold`],[1.46,.6,`inOut`],[1.8,.8,`inOut`]],armL:[[0,0],[.24,-.5,`inOut`],[.36,1.2,`out`],[.96,1.2,`hold`],[.98,1.05,`hold`],[1.24,1.05,`hold`],[1.36,-1.15,`out`],[1.7,0,`inOut`]],armR:[[0,0],[.24,.5,`inOut`],[.36,-1.2,`out`],[.96,-1.2,`hold`],[.98,.85,`hold`],[1.6,0,`inOut`]],tuft:[[0,0],[.24,-.4,`inOut`],[.36,.5,`out`],[.96,.5,`hold`],[.98,.8,`hold`],[1.6,.2,`inOut`],[2,0,`inOut`]],swing:[[0,0],[1.08,0,`hold`],[1.1,-8,`hold`],[1.36,12,`out`],[1.7,0,`inOut`]],mouth:[[0,`flat`],[1.14,`smile`]]},cues:[{t:.32,fx:`ninja-smoke`,fxScale:1,particles:`ring`},{t:.7,jump:1.7},{t:1.02,fx:`ninja-smoke`,fxScale:.7},{t:1.14,particles:`bubbles`}]}},rt=[`spin`,`happy`,`wave`,`dazzle`,`love`,`bounce`,`dance`,`shy`,`surprise`,`stretch`,`cheer`,`pout`,`curious`,`wiggle`,`sleep`],it=new Set([`happy`,`cheer`,`dazzle`,`love`]),at={spin:1.2,happy:1.1,wave:1.45,dazzle:1.45,love:1.6,bounce:1.4,dance:1.7,shy:1.55,surprise:1.1,stretch:1.5,cheer:1.35,pout:1.4,curious:1.55,wiggle:1.15,sleep:1.15},ot=new Set([`happy`,`spin`,`dazzle`,`love`,`bounce`,`dance`,`shy`,`surprise`,`stretch`,`cheer`,`pout`,`curious`,`wiggle`]),st=class{x=0;y=0;vx=0;vy=0;targetX=0;targetY=0;following=!1;dragging=!1;wanderIn=C(2.5,5);bob=Math.random()*Math.PI*2;blinkT=C(2.2,4.2);personality=null;signature=null;act=null;actT=0;actDir=1;actHome={x:0,y:0};actCuesFired=0;lastBounds=null;onFx=null;idleEmoteIn=C(10,20);blinking=0;emote=null;emoteT=0;sleeping=!1;sleepBob=0;zzzIn=.4;radius=72;glow=!1;glowLevel=.5;moteIn=.6;anchored=!1;reduceMotion=!1;particles=[];facing=1;armL=0;armR=0;footL=0;footR=0;sprout=0;gait=0;trailAcc=0;constructor(e,t){this.x=e,this.y=t,this.targetX=e,this.targetY=t}get status(){return this.act?this.act.name:this.emote===`sleep`||this.sleeping?`Sleeping`:this.emote===`spin`?`Spin`:this.emote===`happy`?`Happy`:this.emote===`wave`?`Wave`:this.emote===`dazzle`?`Dazzle`:this.emote===`love`?`Love`:this.emote===`bounce`?`Bounce`:this.emote===`dance`?`Dance`:this.emote===`shy`?`Shy`:this.emote===`surprise`?`Surprise`:this.emote===`stretch`?`Stretch`:this.emote===`cheer`?`Cheer`:this.emote===`pout`?`Pout`:this.emote===`curious`?`Curious`:this.emote===`wiggle`?`Wiggle`:this.dragging?`Held`:this.following?`Swimming`:`Idle`}contains(e,t){let n=e-this.x,r=t-this.y;return n*n+r*r<=(this.radius*1.2)**2}playSignature(e){if(e.act){this.playAct(nt[e.act]);return}this.signature=e,this.play(e.emote)}playAct(e){this.sleeping&&this.wake(),this.emote=null,this.emoteT=0,this.signature=null,this.following=!1,this.dragging=!1,this.vx=0,this.vy=0,this.act=e,this.actT=0,this.actDir=this.facing,this.actHome={x:this.x,y:this.y},this.actCuesFired=0}endAct(){let e=this.anchored;this.act=null,this.actT=0,e&&this.goTo(this.actHome.x,this.actHome.y);let t=this.personality?.settle??0;t>0&&(this.wanderIn=Math.max(this.wanderIn,t),this.idleEmoteIn=Math.max(this.idleEmoteIn,t))}fireCue(e){if(e.jump&&this.lastBounds){let t=this.lastBounds,n=this.x-t.left,r=t.right-this.x,i=this.y-t.top,a=this.reduceMotion?0:e.jump*this.radius,o=Math.max(n,r);i>o*1.15?this.y-=Math.min(a,Math.max(0,i-4)):(this.actDir=Math.abs(r-n)<1?this.facing:r>n?1:-1,this.x+=this.actDir*Math.min(a,Math.max(0,o-4)),this.facing=this.actDir),this.targetX=this.x,this.targetY=this.y}if(e.fx&&this.onFx?.(e.fx,this.x,this.y,e.fxScale??1),e.particles===`ring`){this.particles.push(He(this.x,this.y,18));for(let e=0;e<6;e++)this.particles.push(ze(this.x,this.y+10,!0))}else if(e.particles===`puff`)for(let e=0;e<8;e++)this.particles.push(ze(this.x,this.y+10,!0));else if(e.particles===`bubbles`&&!this.reduceMotion)for(let e=0;e<4;e++)this.particles.push(We(this.x,this.y+12,{burst:!0}))}play(e){if(this.act&&this.endAct(),e===`sleep`){if(this.sleeping){this.wake();return}this.sleeping=!0,this.following=!1,this.dragging=!1}else this.sleeping&&this.wake();if(this.emote=e,this.emoteT=0,e!==`sleep`&&(this.following=!1,this.vx=0,this.vy=0),e===`dazzle`){this.particles.push(He(this.x,this.y,24));for(let e=0;e<22;e++)this.particles.push(Be(this.x,this.y))}if(e===`spin`){if(!this.reduceMotion)for(let e=0;e<3;e++)this.particles.push(We(this.x,this.y+16,{burst:!0}));for(let e=0;e<6;e++)this.particles.push(ze(this.x,this.y+30,!0))}if(e===`happy`&&this.particles.push(He(this.x,this.y+10,16)),e===`love`)for(let e=0;e<14;e++)this.particles.push(Ue(this.x,this.y-12));if(e===`cheer`&&(this.particles.push(He(this.x,this.y+8,14)),!this.reduceMotion))for(let e=0;e<3;e++)this.particles.push(We(this.x,this.y+12,{burst:!0}));if(e===`surprise`){this.particles.push(He(this.x,this.y,12));for(let e=0;e<12;e++)this.particles.push(Be(this.x,this.y))}}wake(){if(this.sleeping=!1,this.emote===`sleep`&&(this.emote=null),this.emoteT=0,this.blinkT=.2,!this.reduceMotion)for(let e=0;e<3;e++)this.particles.push(We(this.x,this.y+8,{burst:!0}))}goTo(e,t){this.sleeping&&this.wake(),this.targetX=e,this.targetY=t,this.following=!0}hold(e,t){this.sleeping&&this.wake(),this.dragging=!0,this.following=!0,this.targetX=e,this.targetY=t}release(){this.dragging=!1}update(e,t){let n=Math.min(e,1/20);if(this.lastBounds=t,this.bob+=n*(this.sleeping?1.15:2.2)*(this.personality?.breath??1),this.sleepBob+=n,!this.sleeping&&this.emote!==`sleep`&&(this.wanderIn-=n,!this.anchored&&!this.reduceMotion&&!this.following&&!this.dragging&&this.wanderIn<=0&&!this.emote&&!this.act)){let e=this.personality?.reach??.56;this.targetX=C(Math.max(t.left,t.w*(.5-e/2)),Math.min(t.right,t.w*(.5+e/2))),this.targetY=C(t.top,t.bottom),this.following=!0;let[n,r]=this.personality?.wander??[3.5,7];this.wanderIn=C(n,r)}let r=this.dragging?10:3.4;if(this.following||this.dragging){let e=this.targetX-this.x,t=this.targetY-this.y,i=Math.hypot(e,t);if(i>(this.dragging?2:16)){let a=this.dragging?300:b(i*r,18,156)*(this.dragging?1:this.personality?.speed??1);this.vx=S(this.vx,e/i*a,4.2,n),this.vy=S(this.vy,t/i*a,4.2,n)}else this.vx=S(this.vx,0,2.6,n),this.vy=S(this.vy,0,2.6,n),this.dragging||(this.following=!1)}else{let e=this.personality?.drift??1,t=Math.sin(this.bob*.35)*10*e,r=Math.sin(this.bob*.48+1.1)*14*e,i=this.sleeping||this.anchored;this.vx=S(this.vx,i?0:t,1.4,n),this.vy=S(this.vy,i?0:r,1.4,n)}(this.emote&&ot.has(this.emote)||this.act)&&(this.vx*=1-4*n,this.vy*=1-4*n),this.x+=this.vx*n,this.y+=this.vy*n,this.x=b(this.x,t.left,t.right),this.y=b(this.y,t.top,t.bottom),this.vx>18?this.facing=1:this.vx<-18&&(this.facing=-1);let i=Math.hypot(this.vx,this.vy);if(this.gait+=(.9+i*.028)*n,i>48&&!this.sleeping&&!this.reduceMotion){this.trailAcc+=n;let e=this.particles.filter(e=>e.kind===`bubble`).length;this.trailAcc>.95&&e<7&&(this.trailAcc=0,this.particles.push(We(this.x-this.facing*16,this.y+30,{size:3+Math.random()*3.5,rise:-22-Math.random()*16})))}else this.trailAcc=0;if(this.glow&&!this.sleeping&&!this.reduceMotion){this.moteIn-=n;let e=this.particles.filter(e=>e.kind===`mote`).length;this.moteIn<=0&&e<5&&(this.moteIn=C(.7,1.4),this.particles.push(Ge(this.x,this.y,this.radius)))}if(this.personality&&!this.reduceMotion&&!this.sleeping&&(this.idleEmoteIn-=n,this.idleEmoteIn<=0)){if(this.emote||this.act||this.dragging)this.idleEmoteIn=.6;else{let e=this.personality.idle;this.play(e[Math.floor(Math.random()*e.length)]);let[t,n]=this.personality.idleEvery;this.idleEmoteIn=C(t,n)}}if(this.blinkT-=n,this.blinkT<=0&&!this.sleeping){this.blinking=this.personality?.blinkFor??.14;let[e,t]=this.personality?.blink??[2.4,5.5];this.blinkT=C(e,t)}if(this.blinking>0&&(this.blinking-=n),this.sleeping&&(this.zzzIn-=n,this.zzzIn<=0&&(this.particles.push(Ve(this.x,this.y-20)),this.zzzIn=C(.9,1.5))),this.emote){this.emoteT+=n*(this.personality?.emoteRate??1)*(this.signature?.rate??1);let e=at[this.emote];if(this.emote===`dazzle`&&this.emoteT<.35&&Math.random()<.55&&this.particles.push(Be(this.x,this.y)),this.emote===`love`&&this.emoteT<1.1&&Math.random()<.22&&this.particles.push(Ue(this.x,this.y-6)),this.emote===`happy`&&this.emoteT>.52&&this.emoteT<.58&&(this.particles.push(He(this.x,this.y+28,18)),!this.reduceMotion))for(let e=0;e<3;e++)this.particles.push(We(this.x,this.y+18,{burst:!0}));if(this.emote===`bounce`){let e=Math.floor(this.emoteT/.35);if(e!==Math.floor((this.emoteT-n)/.35)&&e>0&&e<4&&!this.reduceMotion)for(let e=0;e<2;e++)this.particles.push(We(this.x,this.y+30,{burst:!0}))}if(this.emote!==`sleep`&&this.emoteT>=e){this.emote=null,this.emoteT=0,this.signature=null;let e=this.personality?.settle??0;e>0&&(this.wanderIn=Math.max(this.wanderIn,e),this.idleEmoteIn=Math.max(this.idleEmoteIn,e))}}if(this.act){this.actT+=n*(this.personality?.emoteRate??1);let e=this.act.cues;for(;this.actCuesFired<e.length&&e[this.actCuesFired].t<=this.actT;)this.fireCue(e[this.actCuesFired]),this.actCuesFired++;this.actT>=this.act.duration&&this.endAct()}this.springLimbs(n,i)}pose(){let e=Math.hypot(this.vx,this.vy),t=b(e/140,0,1),n=e>6?Math.atan2(this.vx,160)*.42:0,r=e>6?Math.atan2(this.vy,180)*.38:0,i=this.reduceMotion,a=i?Math.sin(this.bob)*2:Math.sin(this.bob)*(this.sleeping?4:8)+Math.sin(this.bob*.47)*3,o=n+r+(i?0:Math.sin(this.bob*.5)*.04),s=1,c=this.personality?.breath??1,l=1+(i?0:Math.sin(this.bob*.9)*.018*c)+t*.07,u=2-l-t*.02,d=this.personality?.lid??1,f=(this.personality?.blinkFor??.14)/2,p=this.blinking>0?d*T(Math.abs(this.blinking-f)/f):d,ee=1,te=0,m=.74+Math.sin(this.bob*.4)*.14,h=0,g=this.personality?.restMouth??`smile`,ne=0,re=this.facing*.22,ie=0,ae=1,_=this.y+a+Math.sin(this.gait*1.6)*t*6,v=this.x,oe=v,se=_,ce=o,le=l,ue=u;if(this.emote){let e=at[this.emote],t=T(this.emoteT/e);if(this.emote===`spin`)re=this.facing*.22+pe(t)*Math.PI*2*this.facing,o+=i?0:pe(t)*Math.PI*2,s+=Math.sin(t*Math.PI)*.1,l=1+Math.sin(t*Math.PI*2)*.08,u=2-l,g=`open`;else if(this.emote===`happy`){if(t<.16){let e=t/.16;l=x(1,1.22,e),u=x(1,.78,e)}else if(t<.55){let e=(t-.16)/.39;l=x(1.22,.82,w(e)),u=x(.78,1.22,w(e)),_-=i?0:me(e)*112}else if(t<.72){let e=(t-.55)/.17;l=x(.82,1.28,e),u=x(1.22,.72,e),_-=(1-e)*(i?0:16)}else{let e=(t-.72)/.28;l=x(1.28,1,w(e)),u=x(.72,1,w(e))}h=+(t>.12&&t<.85),p=h?.12:p,g=`open`}else if(this.emote===`wave`)o+=Math.sin(t*Math.PI)*.12*this.facing,g=`smile`;else if(this.emote===`dazzle`)s+=Math.sin(t*Math.PI)*.16,te=t<.18?1-t/.18:Math.max(0,.25-t)*2,o+=Math.sin(t*Math.PI*6)*.06,g=`o`,p=1;else if(this.emote===`sleep`)p=1-w(t),ee=x(1,.78,w(t)),_+=w(t)*10,g=`flat`;else if(this.emote===`love`)o+=Math.sin(t*Math.PI*4)*.1,s+=Math.sin(t*Math.PI)*.06,h=+(t>.08&&t<.88),g=`open`,l=1+Math.sin(t*Math.PI*3)*.04,u=2-l;else if(this.emote===`bounce`){let e=t*4%1,n=Math.sin(e*Math.PI);_-=n*(i?0:54),l=1+(1-n)*.16,u=2-l,g=`open`,h=+(n>.35)}else if(this.emote===`dance`)v+=Math.sin(t*Math.PI*6)*(i?0:18),o+=Math.sin(t*Math.PI*6)*.22,_-=Math.abs(Math.sin(t*Math.PI*6))*(i?0:10),l=1+Math.sin(t*Math.PI*6)*.08,u=2-l,g=`open`,h=1;else if(this.emote===`shy`){let e=t<.55?w(t/.55):1-pe((t-.55)/.45);o+=-.28*e*this.facing,_+=e*8,l=1+e*.08,u=2-l,p=x(1,.28,e),g=t>.35&&t<.8?`smile`:`flat`}else if(this.emote===`surprise`){if(t<.18){let e=t/.18;l=x(1,1.36,e),u=x(1,.64,e)}else if(t<.55){let e=(t-.18)/.37;l=x(1.36,.78,me(e)),u=x(.64,1.28,me(e)),_-=me(e)*72,s=1+(1-e)*.08}else{let e=(t-.55)/.45;l=x(.86,1,w(e)),u=x(1.18,1,w(e)),_-=(1-e)*48}g=t<.82?`o`:`smile`,p=1}else if(this.emote===`stretch`){if(t<.25){let e=t/.25;l=x(1,.82,e),u=x(1,1.22,e)}else if(t<.72)l=.78,u=1.28,o+=Math.sin((t-.25)*Math.PI*2)*.04,_-=10;else{let e=(t-.72)/.28;l=x(.78,1,w(e)),u=x(1.28,1,w(e))}g=t>.2&&t<.75?`open`:`smile`,p=t>.3&&t<.7?.35:p}else if(this.emote===`cheer`){let e=Math.abs(Math.sin(t*Math.PI*3));_-=e*64,l=1+(1-e)*.14,u=2-l,h=1,g=`open`}else if(this.emote===`pout`)o+=.12*this.facing,_+=12,l=1.08,u=.94,p=.55,g=`flat`;else if(this.emote===`curious`){let e=Math.sin(t*Math.PI*3);o+=e*.32,v+=e*10,l=1+Math.abs(e)*.04,u=2-l,g=`o`,p=1}else this.emote===`wiggle`&&(o+=Math.sin(t*Math.PI*12)*.18,l=1+Math.sin(t*Math.PI*10)*.1,u=2-l,_-=Math.abs(Math.sin(t*Math.PI*8))*8,h=1,g=`open`)}if(this.act){let e=this.act.tracks,t=this.actT,n=new Set(this.act.mirror??[]),r=e=>n.has(e)?this.actDir:1;e.x&&(v+=F(e.x,t)*+!i*r(`x`)),e.y&&(_+=F(e.y,t)*+!i*r(`y`)),e.rot&&(o+=F(e.rot,t)*r(`rot`)),e.scale&&(s=Math.max(0,F(e.scale,t))),e.squash&&(l=F(e.squash,t),u=2-l),e.eye&&(p=Math.min(p,1)*F(e.eye,t)),e.happy&&(h=F(e.happy,t)),e.swing&&(ie=F(e.swing,t)),e.alpha&&(ae=T(F(e.alpha,t))),e.mouth&&(g=tt(e.mouth,t))}if(this.emote&&it.has(this.emote)){let e=T(this.emoteT/at[this.emote]);m=.9+Math.sin(e*Math.PI)*.4}else this.emote===`sleep`&&(m=x(m,.3,w(T(this.emoteT/at.sleep))));if(this.sleeping&&this.emote!==`sleep`&&(p=0,ee=.78,m=.3+Math.sin(this.sleepBob*.6)*.05,_+=10+Math.sin(this.sleepBob*1.1)*2,o=Math.sin(this.sleepBob*.7)*.05,g=`flat`),this.personality&&(this.emote||this.act)&&!this.sleeping){let e=this.act?1:this.personality.amp*(this.signature?.amp??1);if(e!==1&&(v=oe+(v-oe)*e,_=se+(_-se)*e,o=ce+(o-ce)*e,s=1+(s-1)*e,l=le+(l-le)*e,u=ue+(u-ue)*e,ne*=e),p=Math.min(p,this.personality.eyeCap),this.signature&&this.emote&&this.signature.swing!==0){let e=at[this.emote];ie=Math.sin(T(this.emoteT/e)*Math.PI)*this.signature.swing}g===`smile`&&this.personality.restMouth===`flat`&&(g=`flat`)}return m*=this.glowLevel,this.glow&&(ee*=1.02+m*.05),{x:v,y:_,rot:o,scale:s,squashX:l,squashY:u,eyeOpen:p,happyEyes:h,flash:te,brightness:ee,glow:m,facing:this.facing,armL:this.armL,armR:this.armR,footL:this.footL,footR:this.footR,sprout:this.sprout,mouth:g,hop:ne,yaw:re,heldSwing:ie,opacity:ae}}springLimbs(e,t){let n=b(t/120,0,1),r=Math.sin(this.bob),i=this.reduceMotion?.35:1,a=r*.14*i,o=Math.sin(this.bob+.5)*-.12*i,s=0,c=0,l=Math.sin(this.bob*.7+.4)*.16*i;if(n>.06&&!this.emote){let e=Math.sin(this.gait*2.1),t=Math.max(0,-e);a=e*.72*n,o=-e*.72*n,s=t*n*.55,c=t*n*.55,l=-e*.22*n}if(this.emote){let e=at[this.emote],t=T(this.emoteT/e);if(this.emote===`spin`){let e=Math.sin(t*Math.PI)*.55;a=-e,o=e,l=.6}else if(this.emote===`happy`)a=x(0,1.05,T(t*3)),o=x(0,-1.05,T(t*3)),t>.75&&(a=x(1.05,0,(t-.75)/.25),o=x(-1.05,0,(t-.75)/.25)),s=t>.16&&t<.6?.7:0,c=s;else if(this.emote===`wave`)a=.06,o=-1.05+Math.sin(t*Math.PI*6)*.38,l=.45+Math.sin(t*Math.PI*7)*.15;else if(this.emote===`dazzle`)a=-.7,o=.7,s=.45,c=.45,l=.7;else if(this.emote===`sleep`)a=-.22,o=.22,l=-.25;else if(this.emote===`love`)a=.55,o=-.55,l=.35+Math.sin(t*Math.PI*5)*.2;else if(this.emote===`bounce`){let e=Math.sin(t*Math.PI*8)*.7;a=e,o=-e,l=e*.4}else if(this.emote===`dance`){let e=Math.sin(t*Math.PI*6);a=e*.85,o=e*.85,l=e*.45}else if(this.emote===`shy`)a=1.28,o=-1.28,l=-.15;else if(this.emote===`surprise`)a=t<.2?.2:-.85,o=t<.2?-.2:.85,l=.85;else if(this.emote===`stretch`)a=-.35,o=.35,l=.55;else if(this.emote===`cheer`)a=1.12,o=-1.12,l=.5+Math.sin(t*Math.PI*6)*.25;else if(this.emote===`pout`)a=-.35,o=.35,l=-.4;else if(this.emote===`curious`){let e=Math.sin(t*Math.PI*3);a=.15+e*.25,o=-.15+e*.25,l=e*.35}else if(this.emote===`wiggle`){let e=Math.sin(t*Math.PI*12)*.9;a=e,o=e,l=-e*.5}}if(this.sleeping&&this.emote!==`sleep`&&(a=-.22,o=.22,l=-.25),this.act){let e=this.act.tracks;e.armL&&(a=F(e.armL,this.actT)),e.armR&&(o=F(e.armR,this.actT)),e.tuft&&(l=F(e.tuft,this.actT))}this.armL=S(this.armL,a,12,e),this.armR=S(this.armR,o,12,e),this.footL=S(this.footL,s,14,e),this.footR=S(this.footR,c,14,e),this.sprout=S(this.sprout,l,8,e)}},ct={mint:{id:`mint`,name:`Moss`,lane:`Steady · restraint (Miffy, Notion)`,blurb:`Warm and unhurried. Turns up, does the work, does not make a speech about it.`,blink:[3,4.2],wander:[4.5,8],reach:.56,drift:1,speed:1,idleEvery:[16,28],idle:[`wave`,`stretch`,`happy`],tap:`happy`,lid:1,restMouth:`smile`,breath:1,blinkFor:.15,emoteRate:1,amp:1,settle:2,eyeCap:1,lines:[`Ready when you are.`,`That's one down.`,`Same time tomorrow.`]},sky:{id:`sky`,name:`Droplet`,lane:`Unbothered · capybara / Gen Z stare`,blurb:`Deadpan and completely unhurried. Nothing is urgent. It gets done anyway.`,blink:[5.5,9],wander:[10,18],reach:.3,drift:.55,speed:.6,idleEvery:[28,48],idle:[`stretch`,`curious`,`sleep`],tap:`stretch`,lid:.62,restMouth:`flat`,breath:.78,blinkFor:.3,emoteRate:.86,amp:.66,settle:3.5,eyeCap:.7,lines:[`Sure.`,`It'll keep.`,`We got there.`]},coral:{id:`coral`,name:`Ember`,lane:`Competitive · edge (Kuromi, leagues)`,blurb:`Hot and fast. Keeps score, wants the rematch, does not sit still between rounds.`,blink:[2.2,3.2],wander:[3.6,6.5],reach:.74,drift:1.15,speed:1.5,idleEvery:[11,20],idle:[`spin`,`bounce`,`cheer`],tap:`spin`,lid:1.06,restMouth:`smile`,breath:1.15,blinkFor:.11,emoteRate:1.18,amp:1.18,settle:1.6,eyeCap:1.1,lines:[`Again.`,`Beat it by four.`,`Go.`]},lilac:{id:`lilac`,name:`Wisp`,lane:`Dreamy · soft fantasy (Dimoo)`,blurb:`Somewhere else, fondly. Drifts wide, notices small things, has to be called twice.`,blink:[4,6.5],wander:[6,11],reach:.68,drift:1.6,speed:.75,idleEvery:[18,32],idle:[`dazzle`,`love`,`curious`],tap:`dazzle`,lid:.82,restMouth:`smile`,breath:.86,blinkFor:.22,emoteRate:.9,amp:.85,settle:2.4,eyeCap:.9,lines:[`Oh — hello.`,`I was somewhere else.`,`Wasn't that nice.`]},butter:{id:`butter`,name:`Comet`,lane:`Big feelings · raw emotion (Crybaby)`,blurb:`Everything at full volume, up and down. Thrilled, then wounded, then thrilled again.`,blink:[2,3],wander:[3.2,6],reach:.8,drift:1.35,speed:1.35,idleEvery:[10,18],idle:[`cheer`,`dance`,`surprise`,`pout`],tap:`cheer`,lid:1.18,restMouth:`open`,breath:1.2,blinkFor:.12,emoteRate:1.12,amp:1.22,settle:1.4,eyeCap:1.25,lines:[`YES.`,`I missed you.`,`That was SO close.`]},peach:{id:`peach`,name:`Sprout`,lane:`Burnout · the Gudetama seat`,blurb:`Running on fumes and honest about it. Will do one more, under protest.`,blink:[6.5,11],wander:[13,22],reach:.24,drift:.45,speed:.5,idleEvery:[32,55],idle:[`sleep`,`stretch`,`pout`],tap:`stretch`,lid:.55,restMouth:`flat`,breath:.74,blinkFor:.36,emoteRate:.82,amp:.58,settle:4,eyeCap:.62,lines:[`Five more minutes.`,`Fine. One.`,`Bed?`]}},lt={hoodie:[{name:`Hood up`,emote:`shy`,rate:.9,amp:.9,swing:0},{name:`Pocket bounce`,emote:`bounce`,rate:1.05,amp:1.1,swing:0},{name:`Nod`,emote:`wiggle`,rate:.85,amp:.6,swing:0}],flannel:[{name:`Sleeve roll`,emote:`stretch`,rate:.95,amp:1.05,swing:0},{name:`Lean in`,emote:`curious`,rate:.9,amp:1,swing:0},{name:`Shrug`,emote:`pout`,rate:1.1,amp:.8,swing:0}],barista:[{name:`Sip`,emote:`curious`,rate:.8,amp:.7,swing:14},{name:`Pour`,emote:`wave`,rate:.9,amp:1,swing:26},{name:`Order up`,emote:`happy`,rate:1.15,amp:1.1,swing:10}],scholar:[{name:`Adjust glasses`,emote:`curious`,rate:.85,amp:.7,swing:0},{name:`Take a bow`,emote:`shy`,rate:.9,amp:1.1,swing:0},{name:`Point made`,emote:`happy`,rate:1,amp:1.05,swing:0}],varsity:[{name:`Flex`,emote:`cheer`,rate:1.1,amp:1.25,swing:0},{name:`Sprint`,emote:`spin`,rate:1.35,amp:1.15,swing:0},{name:`Victory`,emote:`bounce`,rate:1.15,amp:1.3,swing:0}],pajamas:[{name:`Yawn`,emote:`sleep`,rate:.7,amp:.8,swing:0},{name:`Big stretch`,emote:`stretch`,rate:.65,amp:1.25,swing:0},{name:`Flop`,emote:`pout`,rate:.75,amp:1.1,swing:0}],keynote:[{name:`One more thing`,emote:`wave`,rate:.8,amp:.85,swing:0},{name:`Pace the stage`,emote:`spin`,rate:.7,amp:.75,swing:0},{name:`The reveal`,emote:`dazzle`,rate:.9,amp:1.15,swing:0}],happi:[{name:`Festival clap`,emote:`cheer`,rate:1.1,amp:1.05,swing:0},{name:`Fan sweep`,emote:`wave`,rate:1,amp:1.15,swing:0},{name:`Bow`,emote:`shy`,rate:.85,amp:.9,swing:0}],idol:[{name:`Mic drop`,emote:`cheer`,rate:1.2,amp:1.3,swing:34},{name:`Wink`,emote:`love`,rate:1.05,amp:.85,swing:8},{name:`Dance break`,emote:`dance`,rate:1.15,amp:1.2,swing:20}],racer:[{name:`Rev`,emote:`wiggle`,rate:1.3,amp:.9,swing:0},{name:`Chequered flag`,emote:`cheer`,rate:1.2,amp:1.2,swing:0},{name:`Visor down`,emote:`curious`,rate:1,amp:.7,swing:0}],ballet:[{name:`Pirouette`,emote:`spin`,rate:.95,amp:1.15,swing:0},{name:`Plié`,emote:`stretch`,rate:.7,amp:1.1,swing:0},{name:`Curtsy`,emote:`shy`,rate:.8,amp:1,swing:0}],hanbok:[{name:`Greeting bow`,emote:`shy`,rate:.75,amp:1.05,swing:0},{name:`Ribbon twirl`,emote:`spin`,rate:.8,amp:1,swing:0},{name:`Welcome`,emote:`wave`,rate:.85,amp:.95,swing:0}],biker:[{name:`Rev engine`,emote:`wiggle`,rate:1.25,amp:1,swing:0},{name:`Lean back`,emote:`stretch`,rate:.85,amp:1.15,swing:0},{name:`The nod`,emote:`curious`,rate:.9,amp:.6,swing:0}],astronaut:[{name:`Zero-g float`,emote:`stretch`,rate:.55,amp:1.2,swing:12},{name:`Flag plant`,emote:`cheer`,rate:.9,amp:1.15,swing:30},{name:`Salute`,emote:`wave`,rate:.8,amp:.85,swing:16}],monster:[{name:`Roar`,emote:`surprise`,rate:1.15,amp:1.3,swing:0},{name:`Chomp`,emote:`bounce`,rate:1.25,amp:1.15,swing:0},{name:`Lurk`,emote:`curious`,rate:.7,amp:.75,swing:0}],ninja:[{name:`Draw`,emote:`spin`,rate:1.35,amp:1.1,swing:38},{name:`Vanish`,emote:`shy`,rate:1.4,amp:.9,swing:14,act:`vanish`},{name:`Stance`,emote:`curious`,rate:.8,amp:.7,swing:22}],sorcerer:[{name:`Cast`,emote:`dazzle`,rate:.95,amp:1.2,swing:32},{name:`Levitate`,emote:`stretch`,rate:.6,amp:1.15,swing:10},{name:`Fizzle`,emote:`pout`,rate:1.1,amp:.85,swing:24}],grad:[{name:`Cap toss`,emote:`cheer`,rate:1.15,amp:1.3,swing:18},{name:`Diploma up`,emote:`wave`,rate:.9,amp:1.1,swing:34},{name:`Tassel flick`,emote:`wiggle`,rate:1.05,amp:.7,swing:12}],baker:[{name:`Knead`,emote:`wiggle`,rate:.95,amp:.9,swing:0},{name:`Taste test`,emote:`curious`,rate:.85,amp:.75,swing:0},{name:`Ta-da`,emote:`happy`,rate:1.05,amp:1.15,swing:0}],hex:[{name:`Bat flit`,emote:`dance`,rate:1.1,amp:1.15,swing:0},{name:`Smirk`,emote:`love`,rate:.9,amp:.7,swing:0},{name:`Hex`,emote:`dazzle`,rate:1.05,amp:1.2,swing:0}]};function ut(e){"@babel/helpers - typeof";return ut=typeof Symbol==`function`&&typeof Symbol.iterator==`symbol`?function(e){return typeof e}:function(e){return e&&typeof Symbol==`function`&&e.constructor===Symbol&&e!==Symbol.prototype?`symbol`:typeof e},ut(e)}function dt(e,t){if(ut(e)!=`object`||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var r=n.call(e,t||`default`);if(ut(r)!=`object`)return r;throw TypeError(`@@toPrimitive must return a primitive value.`)}return(t===`string`?String:Number)(e)}function ft(e){var t=dt(e,`string`);return ut(t)==`symbol`?t:t+``}function I(e,t,n){return(t=ft(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}var pt=class{requestAnimationFrame(e){return requestAnimationFrame(e)}cancelAnimationFrame(e){cancelAnimationFrame(e)}},mt=class{constructor(){I(this,`_lastHandleId`,0),I(this,`_lastImmediate`,null)}requestAnimationFrame(e){return this._lastHandleId>=2**53-1&&(this._lastHandleId=0),this._lastHandleId+=1,this._lastImmediate=setImmediate(()=>{e(performance.now())}),this._lastHandleId}cancelAnimationFrame(e){this._lastImmediate&&clearImmediate(this._lastImmediate)}},ht=class{constructor(){I(this,`_strategy`,void 0),this._strategy=typeof requestAnimationFrame==`function`?new pt:new mt}requestAnimationFrame(e){return this._strategy.requestAnimationFrame(e)}cancelAnimationFrame(e){this._strategy.cancelAnimationFrame(e)}},L=typeof window<`u`&&window.document!==void 0,gt=new Uint8Array([80,75,3,4]),_t=[`v`,`ip`,`op`,`layers`,`fr`,`w`,`h`],R,z=Array(128).fill(void 0);z.push(void 0,null,!0,!1);function B(e){return z[e]}var vt=z.length;function V(e){vt===z.length&&z.push(z.length+1);let t=vt;return vt=z[t],z[t]=e,t}function H(e,t){try{return e.apply(this,t)}catch(e){R.__wbindgen_export_0(V(e))}}function U(e){return e==null}var yt=typeof TextDecoder<`u`?new TextDecoder(`utf-8`,{ignoreBOM:!0,fatal:!0}):{decode:()=>{throw Error(`TextDecoder not available`)}};typeof TextDecoder<`u`&&yt.decode();var bt=null;function xt(){return(bt===null||bt.byteLength===0)&&(bt=new Uint8Array(R.memory.buffer)),bt}function W(e,t){return e>>>=0,yt.decode(xt().subarray(e,e+t))}var G=0,St=typeof TextEncoder<`u`?new TextEncoder(`utf-8`):{encode:()=>{throw Error(`TextEncoder not available`)}},Ct=typeof St.encodeInto==`function`?function(e,t){return St.encodeInto(e,t)}:function(e,t){let n=St.encode(e);return t.set(n),{read:e.length,written:n.length}};function K(e,t,n){if(n===void 0){let n=St.encode(e),r=t(n.length,1)>>>0;return xt().subarray(r,r+n.length).set(n),G=n.length,r}let r=e.length,i=t(r,1)>>>0,a=xt(),o=0;for(;o<r;o++){let t=e.charCodeAt(o);if(t>127)break;a[i+o]=t}if(o!==r){o!==0&&(e=e.slice(o)),i=n(i,r,r=o+e.length*3,1)>>>0;let t=xt().subarray(i+o,i+r),a=Ct(e,t);o+=a.written,i=n(i,r,o,1)>>>0}return G=o,i}var wt=null;function q(){return(wt===null||wt.buffer.detached===!0||wt.buffer.detached===void 0&&wt.buffer!==R.memory.buffer)&&(wt=new DataView(R.memory.buffer)),wt}function Tt(e,t){let n=t(e.length*1,1)>>>0;return xt().set(e,n/1),G=e.length,n}function Et(e){e<132||(z[e]=vt,vt=e)}function J(e){let t=B(e);return Et(e),t}var Dt=typeof FinalizationRegistry>`u`?{register:()=>{},unregister:()=>{}}:new FinalizationRegistry(e=>{R.__wbindgen_export_4.get(e.dtor)(e.a,e.b)});function Ot(e,t,n,r){let i={a:e,b:t,cnt:1,dtor:n},a=(...e)=>{i.cnt++;let t=i.a;i.a=0;try{return r(t,i.b,...e)}finally{--i.cnt===0?(R.__wbindgen_export_4.get(i.dtor)(t,i.b),Dt.unregister(i)):i.a=t}};return a.original=i,Dt.register(a,i,i),a}function kt(e,t){let n=K(e,R.__wbindgen_export_1,R.__wbindgen_export_2),r=G,i=Tt(t,R.__wbindgen_export_1),a=G;return R.register_font(n,r,i,a)!==0}var At=null;function jt(){return(At===null||At.byteLength===0)&&(At=new Float32Array(R.memory.buffer)),At}function Mt(e,t){let n=t(e.length*4,4)>>>0;return jt().set(e,n/4),G=e.length,n}function Nt(e,t){let n=t(e.length*4,4)>>>0,r=q();for(let t=0;t<e.length;t++)r.setUint32(n+4*t,V(e[t]),!0);return G=e.length,n}function Pt(e,t,n){R.__wbindgen_export_5(e,t,V(n))}var Ft=Object.freeze({Forward:0,0:`Forward`,Reverse:1,1:`Reverse`,Bounce:2,2:`Bounce`,ReverseBounce:3,3:`ReverseBounce`}),Y=Object.freeze({Idle:0,0:`Idle`,Playing:1,1:`Playing`,Paused:2,2:`Paused`,Stopped:3,3:`Stopped`,Tweening:4,4:`Tweening`}),It=typeof FinalizationRegistry>`u`?{register:()=>{},unregister:()=>{}}:new FinalizationRegistry(e=>R.__wbg_dotlottieplayerwasm_free(e>>>0,1)),Lt=class{__destroy_into_raw(){let e=this.__wbg_ptr;return this.__wbg_ptr=0,It.unregister(this),e}free(){let e=this.__destroy_into_raw();R.__wbg_dotlottieplayerwasm_free(e,0)}clear_slot(e){let t=K(e,R.__wbindgen_export_1,R.__wbindgen_export_2),n=G;return R.dotlottieplayerwasm_clear_slot(this.__wbg_ptr,t,n)!==0}layout_fit(){let e,t;try{let i=R.__wbindgen_add_to_stack_pointer(-16);R.dotlottieplayerwasm_layout_fit(i,this.__wbg_ptr);var n=q().getInt32(i+0,!0),r=q().getInt32(i+4,!0);return e=n,t=r,W(n,r)}finally{R.__wbindgen_add_to_stack_pointer(16),R.__wbindgen_export_3(e,t,1)}}loop_count(){return R.dotlottieplayerwasm_loop_count(this.__wbg_ptr)>>>0}poll_event(){return J(R.dotlottieplayerwasm_poll_event(this.__wbg_ptr))}reset_slot(e){let t=K(e,R.__wbindgen_export_1,R.__wbindgen_export_2),n=G;return R.dotlottieplayerwasm_reset_slot(this.__wbg_ptr,t,n)!==0}set_layout(e,t,n){let r=K(e,R.__wbindgen_export_1,R.__wbindgen_export_2),i=G;return R.dotlottieplayerwasm_set_layout(this.__wbg_ptr,r,i,t,n)!==0}set_marker(e){let t=K(e,R.__wbindgen_export_1,R.__wbindgen_export_2),n=G;R.dotlottieplayerwasm_set_marker(this.__wbg_ptr,t,n)}clear_slots(){return R.dotlottieplayerwasm_clear_slots(this.__wbg_ptr)!==0}is_complete(){return R.dotlottieplayerwasm_is_complete(this.__wbg_ptr)!==0}reset_slots(){return R.dotlottieplayerwasm_reset_slots(this.__wbg_ptr)!==0}reset_theme(){return R.dotlottieplayerwasm_reset_theme(this.__wbg_ptr)!==0}segment_end(){return R.dotlottieplayerwasm_segment_end(this.__wbg_ptr)}set_quality(e){return R.dotlottieplayerwasm_set_quality(this.__wbg_ptr,e)!==0}set_segment(e,t){return R.dotlottieplayerwasm_set_segment(this.__wbg_ptr,e,t)!==0}sm_set_seed(e){return R.dotlottieplayerwasm_sm_set_seed(this.__wbg_ptr,e)!==0}static unload_font(e){let t=K(e,R.__wbindgen_export_1,R.__wbindgen_export_2),n=G;return R.dotlottieplayerwasm_unload_font(t,n)!==0}animation_id(){try{let n=R.__wbindgen_add_to_stack_pointer(-16);R.dotlottieplayerwasm_animation_id(n,this.__wbg_ptr);var e=q().getInt32(n+0,!0),t=q().getInt32(n+4,!0);let r;return e!==0&&(r=W(e,t).slice(),R.__wbindgen_export_3(e,t*1,1)),r}finally{R.__wbindgen_add_to_stack_pointer(16)}}audio_volume(){return R.dotlottieplayerwasm_audio_volume(this.__wbg_ptr)}background_a(){return R.dotlottieplayerwasm_background_a(this.__wbg_ptr)}background_b(){return R.dotlottieplayerwasm_background_b(this.__wbg_ptr)}background_g(){return R.dotlottieplayerwasm_background_g(this.__wbg_ptr)}background_r(){return R.dotlottieplayerwasm_background_r(this.__wbg_ptr)}clear_marker(){R.dotlottieplayerwasm_clear_marker(this.__wbg_ptr)}emit_on_loop(){R.dotlottieplayerwasm_emit_on_loop(this.__wbg_ptr)}get_slot_ids(){return J(R.dotlottieplayerwasm_get_slot_ids(this.__wbg_ptr))}get_slot_str(e){try{let r=R.__wbindgen_add_to_stack_pointer(-16),i=K(e,R.__wbindgen_export_1,R.__wbindgen_export_2),a=G;R.dotlottieplayerwasm_get_slot_str(r,this.__wbg_ptr,i,a);var t=q().getInt32(r+0,!0),n=q().getInt32(r+4,!0);let o;return t!==0&&(o=W(t,n).slice(),R.__wbindgen_export_3(t,n*1,1)),o}finally{R.__wbindgen_add_to_stack_pointer(16)}}marker_names(){return J(R.dotlottieplayerwasm_marker_names(this.__wbg_ptr))}set_autoplay(e){R.dotlottieplayerwasm_set_autoplay(this.__wbg_ptr,e)}set_slot_str(e,t){let n=K(e,R.__wbindgen_export_1,R.__wbindgen_export_2),r=G,i=K(t,R.__wbindgen_export_1,R.__wbindgen_export_2),a=G;return R.dotlottieplayerwasm_set_slot_str(this.__wbg_ptr,n,r,i,a)!==0}set_viewport(e,t,n,r){return R.dotlottieplayerwasm_set_viewport(this.__wbg_ptr,e,t,n,r)!==0}total_frames(){return R.dotlottieplayerwasm_total_frames(this.__wbg_ptr)}clear_segment(){return R.dotlottieplayerwasm_clear_segment(this.__wbg_ptr)!==0}current_frame(){return R.dotlottieplayerwasm_current_frame(this.__wbg_ptr)}get_slot_type(e){try{let r=R.__wbindgen_add_to_stack_pointer(-16),i=K(e,R.__wbindgen_export_1,R.__wbindgen_export_2),a=G;R.dotlottieplayerwasm_get_slot_type(r,this.__wbg_ptr,i,a);var t=q().getInt32(r+0,!0),n=q().getInt32(r+4,!0);let o;return t!==0&&(o=W(t,n).slice(),R.__wbindgen_export_3(t,n*1,1)),o}finally{R.__wbindgen_add_to_stack_pointer(16)}}get_slots_str(){let e,t;try{let i=R.__wbindgen_add_to_stack_pointer(-16);R.dotlottieplayerwasm_get_slots_str(i,this.__wbg_ptr);var n=q().getInt32(i+0,!0),r=q().getInt32(i+4,!0);return e=n,t=r,W(n,r)}finally{R.__wbindgen_add_to_stack_pointer(16),R.__wbindgen_export_3(e,t,1)}}get_transform(){return J(R.dotlottieplayerwasm_get_transform(this.__wbg_ptr))}segment_start(){return R.dotlottieplayerwasm_segment_start(this.__wbg_ptr)}set_slots_str(e){let t=K(e,R.__wbindgen_export_1,R.__wbindgen_export_2),n=G;return R.dotlottieplayerwasm_set_slots_str(this.__wbg_ptr,t,n)!==0}set_text_slot(e,t){let n=K(e,R.__wbindgen_export_1,R.__wbindgen_export_2),r=G,i=K(t,R.__wbindgen_export_1,R.__wbindgen_export_2),a=G;return R.dotlottieplayerwasm_set_text_slot(this.__wbg_ptr,n,r,i,a)!==0}set_transform(e){let t=Mt(e,R.__wbindgen_export_1),n=G;return R.dotlottieplayerwasm_set_transform(this.__wbg_ptr,t,n)!==0}sm_get_inputs(){return J(R.dotlottieplayerwasm_sm_get_inputs(this.__wbg_ptr))}sm_poll_event(){return J(R.dotlottieplayerwasm_sm_poll_event(this.__wbg_ptr))}sm_post_click(e,t){R.dotlottieplayerwasm_sm_post_click(this.__wbg_ptr,e,t)}animation_size(){return J(R.dotlottieplayerwasm_animation_size(this.__wbg_ptr))}current_marker(){try{let n=R.__wbindgen_add_to_stack_pointer(-16);R.dotlottieplayerwasm_current_marker(n,this.__wbg_ptr);var e=q().getInt32(n+0,!0),t=q().getInt32(n+4,!0);let r;return e!==0&&(r=W(e,t).slice(),R.__wbindgen_export_3(e,t*1,1)),r}finally{R.__wbindgen_add_to_stack_pointer(16)}}layout_align_x(){return R.dotlottieplayerwasm_layout_align_x(this.__wbg_ptr)}layout_align_y(){return R.dotlottieplayerwasm_layout_align_y(this.__wbg_ptr)}load_animation(e){let t=K(e,R.__wbindgen_export_1,R.__wbindgen_export_2),n=G;return R.dotlottieplayerwasm_load_animation(this.__wbg_ptr,t,n)!==0}loop_animation(){return R.dotlottieplayerwasm_loop_animation(this.__wbg_ptr)!==0}set_background(e,t,n,r){return R.dotlottieplayerwasm_set_background(this.__wbg_ptr,e,t,n,r)!==0}set_color_slot(e,t,n,r){let i=K(e,R.__wbindgen_export_1,R.__wbindgen_export_2),a=G;return R.dotlottieplayerwasm_set_color_slot(this.__wbg_ptr,i,a,t,n,r)!==0}set_image_slot(e,t){let n=K(e,R.__wbindgen_export_1,R.__wbindgen_export_2),r=G,i=K(t,R.__wbindgen_export_1,R.__wbindgen_export_2),a=G;return R.dotlottieplayerwasm_set_image_slot(this.__wbg_ptr,n,r,i,a)!==0}set_loop_count(e){R.dotlottieplayerwasm_set_loop_count(this.__wbg_ptr,e)}set_theme_data(e){let t=K(e,R.__wbindgen_export_1,R.__wbindgen_export_2),n=G;return R.dotlottieplayerwasm_set_theme_data(this.__wbg_ptr,t,n)!==0}sm_reset_input(e){let t=K(e,R.__wbindgen_export_1,R.__wbindgen_export_2),n=G;R.dotlottieplayerwasm_sm_reset_input(this.__wbg_ptr,t,n)}manifest_string(){let e,t;try{let i=R.__wbindgen_add_to_stack_pointer(-16);R.dotlottieplayerwasm_manifest_string(i,this.__wbg_ptr);var n=q().getInt32(i+0,!0),r=q().getInt32(i+4,!0);return e=n,t=r,W(n,r)}finally{R.__wbindgen_add_to_stack_pointer(16),R.__wbindgen_export_3(e,t,1)}}set_scalar_slot(e,t){let n=K(e,R.__wbindgen_export_1,R.__wbindgen_export_2),r=G;return R.dotlottieplayerwasm_set_scalar_slot(this.__wbg_ptr,n,r,t)!==0}set_vector_slot(e,t,n){let r=K(e,R.__wbindgen_export_1,R.__wbindgen_export_2),i=G;return R.dotlottieplayerwasm_set_vector_slot(this.__wbg_ptr,r,i,t,n)!==0}setup_sw_target(e,t){return R.dotlottieplayerwasm_setup_sw_target(this.__wbg_ptr,e,t)!==0}get_pixel_buffer(){return J(R.dotlottieplayerwasm_get_pixel_buffer(this.__wbg_ptr))}set_audio_volume(e){R.dotlottieplayerwasm_set_audio_volume(this.__wbg_ptr,e)}sm_current_state(){let e,t;try{let i=R.__wbindgen_add_to_stack_pointer(-16);R.dotlottieplayerwasm_sm_current_state(i,this.__wbg_ptr);var n=q().getInt32(i+0,!0),r=q().getInt32(i+4,!0);return e=n,t=r,W(n,r)}finally{R.__wbindgen_add_to_stack_pointer(16),R.__wbindgen_export_3(e,t,1)}}state_machine_id(){try{let n=R.__wbindgen_add_to_stack_pointer(-16);R.dotlottieplayerwasm_state_machine_id(n,this.__wbg_ptr);var e=q().getInt32(n+0,!0),t=q().getInt32(n+4,!0);let r;return e!==0&&(r=W(e,t).slice(),R.__wbindgen_export_3(e,t*1,1)),r}finally{R.__wbindgen_add_to_stack_pointer(16)}}get_state_machine(e){try{let r=R.__wbindgen_add_to_stack_pointer(-16),i=K(e,R.__wbindgen_export_1,R.__wbindgen_export_2),a=G;R.dotlottieplayerwasm_get_state_machine(r,this.__wbg_ptr,i,a);var t=q().getInt32(r+0,!0),n=q().getInt32(r+4,!0);let o;return t!==0&&(o=W(t,n).slice(),R.__wbindgen_export_3(t,n*1,1)),o}finally{R.__wbindgen_add_to_stack_pointer(16)}}set_position_slot(e,t,n){let r=K(e,R.__wbindgen_export_1,R.__wbindgen_export_2),i=G;return R.dotlottieplayerwasm_set_position_slot(this.__wbg_ptr,r,i,t,n)!==0}current_loop_count(){return R.dotlottieplayerwasm_current_loop_count(this.__wbg_ptr)>>>0}set_asset_resolver(e){R.dotlottieplayerwasm_set_asset_resolver(this.__wbg_ptr,U(e)?0:V(e))}sm_framework_setup(){return J(R.dotlottieplayerwasm_sm_framework_setup(this.__wbg_ptr))}sm_post_pointer_up(e,t){R.dotlottieplayerwasm_sm_post_pointer_up(this.__wbg_ptr,e,t)}state_machine_load(e){let t=K(e,R.__wbindgen_export_1,R.__wbindgen_export_2),n=G;return R.dotlottieplayerwasm_state_machine_load(this.__wbg_ptr,t,n)!==0}load_dotlottie_data(e){let t=Tt(e,R.__wbindgen_export_1),n=G;return R.dotlottieplayerwasm_load_dotlottie_data(this.__wbg_ptr,t,n)!==0}sm_get_string_input(e){try{let r=R.__wbindgen_add_to_stack_pointer(-16),i=K(e,R.__wbindgen_export_1,R.__wbindgen_export_2),a=G;R.dotlottieplayerwasm_sm_get_string_input(r,this.__wbg_ptr,i,a);var t=q().getInt32(r+0,!0),n=q().getInt32(r+4,!0);let o;return t!==0&&(o=W(t,n).slice(),R.__wbindgen_export_3(t,n*1,1)),o}finally{R.__wbindgen_add_to_stack_pointer(16)}}sm_set_string_input(e,t){let n=K(e,R.__wbindgen_export_1,R.__wbindgen_export_2),r=G,i=K(t,R.__wbindgen_export_1,R.__wbindgen_export_2),a=G;return R.dotlottieplayerwasm_sm_set_string_input(this.__wbg_ptr,n,r,i,a)!==0}sm_get_boolean_input(e){let t=K(e,R.__wbindgen_export_1,R.__wbindgen_export_2),n=G,r=R.dotlottieplayerwasm_sm_get_boolean_input(this.__wbg_ptr,t,n);return r===16777215?void 0:r!==0}sm_get_numeric_input(e){let t=K(e,R.__wbindgen_export_1,R.__wbindgen_export_2),n=G,r=R.dotlottieplayerwasm_sm_get_numeric_input(this.__wbg_ptr,t,n);return r===4294967297?void 0:r}sm_post_pointer_down(e,t){R.dotlottieplayerwasm_sm_post_pointer_down(this.__wbg_ptr,e,t)}sm_post_pointer_exit(e,t){R.dotlottieplayerwasm_sm_post_pointer_exit(this.__wbg_ptr,e,t)}sm_post_pointer_move(e,t){R.dotlottieplayerwasm_sm_post_pointer_move(this.__wbg_ptr,e,t)}sm_set_boolean_input(e,t){let n=K(e,R.__wbindgen_export_1,R.__wbindgen_export_2),r=G;return R.dotlottieplayerwasm_sm_set_boolean_input(this.__wbg_ptr,n,r,t)!==0}sm_set_numeric_input(e,t){let n=K(e,R.__wbindgen_export_1,R.__wbindgen_export_2),r=G;return R.dotlottieplayerwasm_sm_set_numeric_input(this.__wbg_ptr,n,r,t)!==0}state_machine_unload(){R.dotlottieplayerwasm_state_machine_unload(this.__wbg_ptr)}sm_post_pointer_enter(e,t){R.dotlottieplayerwasm_sm_post_pointer_enter(this.__wbg_ptr,e,t)}load_animation_from_id(e){let t=K(e,R.__wbindgen_export_1,R.__wbindgen_export_2),n=G;return R.dotlottieplayerwasm_load_animation_from_id(this.__wbg_ptr,t,n)!==0}sm_poll_internal_event(){return J(R.dotlottieplayerwasm_sm_poll_internal_event(this.__wbg_ptr))}use_frame_interpolation(){return R.dotlottieplayerwasm_use_frame_interpolation(this.__wbg_ptr)!==0}reset_current_loop_count(){R.dotlottieplayerwasm_reset_current_loop_count(this.__wbg_ptr)}sm_override_current_state(e,t){let n=K(e,R.__wbindgen_export_1,R.__wbindgen_export_2),r=G;return R.dotlottieplayerwasm_sm_override_current_state(this.__wbg_ptr,n,r,t)!==0}state_machine_load_from_id(e){let t=K(e,R.__wbindgen_export_1,R.__wbindgen_export_2),n=G;return R.dotlottieplayerwasm_state_machine_load_from_id(this.__wbg_ptr,t,n)!==0}set_use_frame_interpolation(e){R.dotlottieplayerwasm_set_use_frame_interpolation(this.__wbg_ptr,e)}constructor(){let e=R.dotlottieplayerwasm_new();return this.__wbg_ptr=e>>>0,It.register(this,this.__wbg_ptr,this),this}mode(){return R.dotlottieplayerwasm_mode(this.__wbg_ptr)}play(){return R.dotlottieplayerwasm_play(this.__wbg_ptr)!==0}stop(){return R.dotlottieplayerwasm_stop(this.__wbg_ptr)!==0}tick(e){return R.dotlottieplayerwasm_tick(this.__wbg_ptr,e)!==0}pause(){return R.dotlottieplayerwasm_pause(this.__wbg_ptr)!==0}speed(){return R.dotlottieplayerwasm_speed(this.__wbg_ptr)}width(){return R.dotlottieplayerwasm_width(this.__wbg_ptr)>>>0}height(){return R.dotlottieplayerwasm_height(this.__wbg_ptr)>>>0}render(){return R.dotlottieplayerwasm_render(this.__wbg_ptr)!==0}status(){return R.dotlottieplayerwasm_status(this.__wbg_ptr)}markers(){return J(R.dotlottieplayerwasm_markers(this.__wbg_ptr))}sm_fire(e){let t=K(e,R.__wbindgen_export_1,R.__wbindgen_export_2),n=G;return R.dotlottieplayerwasm_sm_fire(this.__wbg_ptr,t,n)!==0}sm_stop(){return R.dotlottieplayerwasm_sm_stop(this.__wbg_ptr)!==0}sm_tick(e){return R.dotlottieplayerwasm_sm_tick(this.__wbg_ptr,e)!==0}autoplay(){return R.dotlottieplayerwasm_autoplay(this.__wbg_ptr)!==0}duration(){return R.dotlottieplayerwasm_duration(this.__wbg_ptr)}set_loop(e){R.dotlottieplayerwasm_set_loop(this.__wbg_ptr,e)}set_mode(e){R.dotlottieplayerwasm_set_mode(this.__wbg_ptr,e)}sm_start(e,t){let n=Nt(t,R.__wbindgen_export_1),r=G;return R.dotlottieplayerwasm_sm_start(this.__wbg_ptr,e,n,r)!==0}theme_id(){try{let n=R.__wbindgen_add_to_stack_pointer(-16);R.dotlottieplayerwasm_theme_id(n,this.__wbg_ptr);var e=q().getInt32(n+0,!0),t=q().getInt32(n+4,!0);let r;return e!==0&&(r=W(e,t).slice(),R.__wbindgen_export_3(e,t*1,1)),r}finally{R.__wbindgen_add_to_stack_pointer(16)}}load_font(e,t){let n=K(e,R.__wbindgen_export_1,R.__wbindgen_export_2),r=G,i=Tt(t,R.__wbindgen_export_1),a=G;return R.dotlottieplayerwasm_load_font(this.__wbg_ptr,n,r,i,a)!==0}set_frame(e){return R.dotlottieplayerwasm_set_frame(this.__wbg_ptr,e)!==0}set_speed(e){R.dotlottieplayerwasm_set_speed(this.__wbg_ptr,e)}set_theme(e){let t=K(e,R.__wbindgen_export_1,R.__wbindgen_export_2),n=G;return R.dotlottieplayerwasm_set_theme(this.__wbg_ptr,t,n)!==0}sm_status(){let e,t;try{let i=R.__wbindgen_add_to_stack_pointer(-16);R.dotlottieplayerwasm_sm_status(i,this.__wbg_ptr);var n=q().getInt32(i+0,!0),r=q().getInt32(i+4,!0);return e=n,t=r,W(n,r)}finally{R.__wbindgen_add_to_stack_pointer(16),R.__wbindgen_export_3(e,t,1)}}};async function Rt(e,t){if(typeof Response==`function`&&e instanceof Response){if(typeof WebAssembly.instantiateStreaming==`function`)try{return await WebAssembly.instantiateStreaming(e,t)}catch(t){if(e.headers.get(`Content-Type`)!=`application/wasm`)console.warn("`WebAssembly.instantiateStreaming` failed because your server does not serve Wasm with `application/wasm` MIME type. Falling back to `WebAssembly.instantiate` which is slower. Original error:\n",t);else throw t}let n=await e.arrayBuffer();return await WebAssembly.instantiate(n,t)}{let n=await WebAssembly.instantiate(e,t);return n instanceof WebAssembly.Instance?{instance:n,module:e}:n}}function zt(){let e={};return e.wbg={},e.wbg.__wbg_appendChild_8204974b7328bf98=function(){return H(function(e,t){return V(B(e).appendChild(B(t)))},arguments)},e.wbg.__wbg_body_942ea927546a04ba=function(e){let t=B(e).body;return U(t)?0:V(t)},e.wbg.__wbg_buffer_609cc3eee51ed158=function(e){let t=B(e).buffer;return V(t)},e.wbg.__wbg_call_672a4d21634d4a24=function(){return H(function(e,t){return V(B(e).call(B(t)))},arguments)},e.wbg.__wbg_call_7cccdd69e0791ae2=function(){return H(function(e,t,n){return V(B(e).call(B(t),B(n)))},arguments)},e.wbg.__wbg_catch_a6e601879b2610e9=function(e,t){return V(B(e).catch(B(t)))},e.wbg.__wbg_createElement_8c9931a732ee2fea=function(){return H(function(e,t,n){return V(B(e).createElement(W(t,n)))},arguments)},e.wbg.__wbg_createObjectURL_6e98d2f9c7bd9764=function(){return H(function(e,t){let n=K(URL.createObjectURL(B(t)),R.__wbindgen_export_1,R.__wbindgen_export_2),r=G;q().setInt32(e+4,r,!0),q().setInt32(e+0,n,!0)},arguments)},e.wbg.__wbg_currentTime_7940fe39798a1ca0=function(e){return B(e).currentTime},e.wbg.__wbg_data_d1ed736c1e42b10e=function(e,t){let n=B(t).data,r=Tt(n,R.__wbindgen_export_1),i=G;q().setInt32(e+4,i,!0),q().setInt32(e+0,r,!0)},e.wbg.__wbg_document_d249400bd7bd996d=function(e){let t=B(e).document;return U(t)?0:V(t)},e.wbg.__wbg_drawImage_803dcc46897223c9=function(){return H(function(e,t,n,r){B(e).drawImage(B(t),n,r)},arguments)},e.wbg.__wbg_duration_4d32c501d87796c1=function(e){return B(e).duration},e.wbg.__wbg_error_7534b8e9a36f1ab4=function(e,t){let n,r;try{n=e,r=t,console.error(W(e,t))}finally{R.__wbindgen_export_3(n,r,1)}},e.wbg.__wbg_getContext_e9cf379449413580=function(){return H(function(e,t,n){let r=B(e).getContext(W(t,n));return U(r)?0:V(r)},arguments)},e.wbg.__wbg_getImageData_c02374a30b126dab=function(){return H(function(e,t,n,r,i){return V(B(e).getImageData(t,n,r,i))},arguments)},e.wbg.__wbg_instanceof_CanvasRenderingContext2d_df82a4d3437bf1cc=function(e){let t;try{t=B(e)instanceof CanvasRenderingContext2D}catch{t=!1}return t},e.wbg.__wbg_instanceof_HtmlCanvasElement_2ea67072a7624ac5=function(e){let t;try{t=B(e)instanceof HTMLCanvasElement}catch{t=!1}return t},e.wbg.__wbg_instanceof_HtmlVideoElement_7f414b32f362e317=function(e){let t;try{t=B(e)instanceof HTMLVideoElement}catch{t=!1}return t},e.wbg.__wbg_instanceof_Window_def73ea0955fc569=function(e){let t;try{t=B(e)instanceof Window}catch{t=!1}return t},e.wbg.__wbg_length_a446193dc22c12f8=function(e){return B(e).length},e.wbg.__wbg_load_2671477a3293aadb=function(e){B(e).load()},e.wbg.__wbg_new_405e22f390576ce2=function(){return V({})},e.wbg.__wbg_new_78feb108b6472713=function(){return V([])},e.wbg.__wbg_new_8a6f238a6ece86ea=function(){return V(Error())},e.wbg.__wbg_new_a12002a7f91c75be=function(e){return V(new Uint8Array(B(e)))},e.wbg.__wbg_newnoargs_105ed471475aaf50=function(e,t){return V(Function(W(e,t)))},e.wbg.__wbg_newwithbyteoffsetandlength_d97e637ebe145a9a=function(e,t,n){return V(new Uint8Array(B(e),t>>>0,n>>>0))},e.wbg.__wbg_newwithlength_5a5efe313cfd59f1=function(e){return V(new Float32Array(e>>>0))},e.wbg.__wbg_newwithsrc_20307ca7e8762a81=function(){return H(function(e,t){return V(new Audio(W(e,t)))},arguments)},e.wbg.__wbg_newwithu8arraysequenceandoptions_068570c487f69127=function(){return H(function(e,t){return V(new Blob(B(e),B(t)))},arguments)},e.wbg.__wbg_pause_b74c96d69f769518=function(){return H(function(e){B(e).pause()},arguments)},e.wbg.__wbg_paused_9b2affc0a8a62e86=function(e){return B(e).paused},e.wbg.__wbg_play_f6ec5fc4e84b0d26=function(){return H(function(e){return V(B(e).play())},arguments)},e.wbg.__wbg_push_737cfc8c1432c2c6=function(e,t){return B(e).push(B(t))},e.wbg.__wbg_readyState_017c08aa5e73517e=function(e){return B(e).readyState},e.wbg.__wbg_remove_e2d2659f3128c045=function(e){B(e).remove()},e.wbg.__wbg_revokeObjectURL_27267efebeb457c7=function(){return H(function(e,t){URL.revokeObjectURL(W(e,t))},arguments)},e.wbg.__wbg_seeking_c0427be38e698dcd=function(e){return B(e).seeking},e.wbg.__wbg_setAttribute_2704501201f15687=function(){return H(function(e,t,n,r,i){B(e).setAttribute(W(t,n),W(r,i))},arguments)},e.wbg.__wbg_set_65595bdd868b3009=function(e,t,n){B(e).set(B(t),n>>>0)},e.wbg.__wbg_set_bb8cecf6a62b9f46=function(){return H(function(e,t,n){return Reflect.set(B(e),B(t),B(n))},arguments)},e.wbg.__wbg_setcssText_e018c236104b0233=function(e,t,n){B(e).cssText=W(t,n)},e.wbg.__wbg_setcurrentTime_64727eddd3966512=function(e,t){B(e).currentTime=t},e.wbg.__wbg_setheight_da683a33fa99843c=function(e,t){B(e).height=t>>>0},e.wbg.__wbg_setindex_4e73afdcd9bb95cd=function(e,t,n){B(e)[t>>>0]=n},e.wbg.__wbg_setmuted_e93fc48340c43e67=function(e,t){B(e).muted=t!==0},e.wbg.__wbg_setplaybackRate_f5c3b8896f82425e=function(e,t){B(e).playbackRate=t},e.wbg.__wbg_setpreload_d2fb02758e3f8e3a=function(e,t,n){B(e).preload=W(t,n)},e.wbg.__wbg_setsrc_3a759736e2659904=function(e,t,n){B(e).src=W(t,n)},e.wbg.__wbg_settype_39ed370d3edd403c=function(e,t,n){B(e).type=W(t,n)},e.wbg.__wbg_setvolume_3895e06a030ca4f7=function(e,t){B(e).volume=t},e.wbg.__wbg_setwidth_c5fed9f5e7f0b406=function(e,t){B(e).width=t>>>0},e.wbg.__wbg_stack_0ed75d68575b0f3c=function(e,t){let n=B(t).stack,r=K(n,R.__wbindgen_export_1,R.__wbindgen_export_2),i=G;q().setInt32(e+4,i,!0),q().setInt32(e+0,r,!0)},e.wbg.__wbg_static_accessor_GLOBAL_88a902d13a557d07=function(){let e=typeof global>`u`?null:global;return U(e)?0:V(e)},e.wbg.__wbg_static_accessor_GLOBAL_THIS_56578be7e9f832b0=function(){let e=typeof globalThis>`u`?null:globalThis;return U(e)?0:V(e)},e.wbg.__wbg_static_accessor_SELF_37c5d418e4bf5819=function(){let e=typeof self>`u`?null:self;return U(e)?0:V(e)},e.wbg.__wbg_static_accessor_WINDOW_5de37043a91a9c40=function(){let e=typeof window>`u`?null:window;return U(e)?0:V(e)},e.wbg.__wbg_style_fb30c14e5815805c=function(e){let t=B(e).style;return V(t)},e.wbg.__wbg_videoHeight_3a43327a766c1f03=function(e){return B(e).videoHeight},e.wbg.__wbg_videoWidth_4b400cf6f4744a4d=function(e){return B(e).videoWidth},e.wbg.__wbindgen_cb_drop=function(e){let t=J(e).original;return t.cnt--==1&&(t.a=0,!0)},e.wbg.__wbindgen_closure_wrapper109=function(e,t,n){return V(Ot(e,t,7,Pt))},e.wbg.__wbindgen_is_null=function(e){return B(e)===null},e.wbg.__wbindgen_is_undefined=function(e){return B(e)===void 0},e.wbg.__wbindgen_memory=function(){let e=R.memory;return V(e)},e.wbg.__wbindgen_number_new=function(e){return V(e)},e.wbg.__wbindgen_object_clone_ref=function(e){return V(B(e))},e.wbg.__wbindgen_object_drop_ref=function(e){J(e)},e.wbg.__wbindgen_string_get=function(e,t){let n=B(t),r=typeof n==`string`?n:void 0;var i=U(r)?0:K(r,R.__wbindgen_export_1,R.__wbindgen_export_2),a=G;q().setInt32(e+4,a,!0),q().setInt32(e+0,i,!0)},e.wbg.__wbindgen_string_new=function(e,t){return V(W(e,t))},e.wbg.__wbindgen_throw=function(e,t){throw Error(W(e,t))},e}function Bt(e,t){return R=e.exports,Vt.__wbindgen_wasm_module=t,wt=null,At=null,bt=null,R}async function Vt(e){if(R!==void 0)return R;if(e!==void 0&&(Object.getPrototypeOf(e)===Object.prototype?{module_or_path:e}=e:console.warn(`using deprecated parameters for the initialization function; pass a single object instead`)),e===void 0)throw Error(`WASM module URL must be provided via DotLottieWasmLoader or setWasmUrl().`);let t=zt();(typeof e==`string`||typeof Request==`function`&&e instanceof Request||typeof URL==`function`&&e instanceof URL)&&(e=fetch(e));let{instance:n,module:r}=await Rt(await e,t);return Bt(n,r)}var Ht=class{constructor(){I(this,`_eventListeners`,new Map)}addEventListener(e,t){let n=this._eventListeners.get(e);n||(n=new Set,this._eventListeners.set(e,n)),n.add(t)}removeEventListener(e,t){let n=this._eventListeners.get(e);n&&(t?(n.delete(t),n.size===0&&this._eventListeners.delete(e)):this._eventListeners.delete(e))}dispatch(e){this._eventListeners.get(e.type)?.forEach(t=>t(e))}removeAllEventListeners(){this._eventListeners.clear()}},Ut=class e{static _initializeObserver(){e._observer||=new IntersectionObserver(t=>{t.forEach(t=>{let n=e._observedCanvases.get(t.target);n&&(t.isIntersecting?n.unfreeze():n.freeze())})},{threshold:0})}static observe(t,n){e._initializeObserver(),!e._observedCanvases.has(t)&&(e._observedCanvases.set(t,n),e._observer?.observe(t))}static unobserve(t){e._observer?.unobserve(t),e._observedCanvases.delete(t),e._observedCanvases.size===0&&(e._observer?.disconnect(),e._observer=null)}};I(Ut,`_observer`,null),I(Ut,`_observedCanvases`,new Map);var Wt=class e{static _initializeObserver(){e._observer||=new ResizeObserver(t=>{t.forEach(t=>{let n=e._observedCanvases.get(t.target);if(!n)return;let[r,i]=n;clearTimeout(i);let a=setTimeout(()=>{r.resize()},100);e._observedCanvases.set(t.target,[r,a])})})}static observe(t,n){e._initializeObserver(),!e._observedCanvases.has(t)&&(e._observedCanvases.set(t,[n,0]),e._observer?.observe(t))}static unobserve(t){let n=e._observedCanvases.get(t);if(n){let e=n[1];e&&clearTimeout(e)}e._observer?.unobserve(t),e._observedCanvases.delete(t),!e._observedCanvases.size&&e._observer&&(e._observer.disconnect(),e._observer=null)}};I(Wt,`_observer`,null),I(Wt,`_observedCanvases`,new Map);function Gt(e){return/^#([\da-f]{6}|[\da-f]{8})$/iu.test(e)}function Kt(e){if(!Gt(e))return[0,0,0,0];let t=e.replace(`#`,``);return t=t.length===6?`${t}ff`:t,[parseInt(t.slice(0,2),16)/255,parseInt(t.slice(2,4),16)/255,parseInt(t.slice(4,6),16)/255,parseInt(t.slice(6,8),16)/255]}function qt(e){if(e.byteLength<4)return!1;let t=new Uint8Array(e.slice(0,gt.byteLength));for(let e=0;e<gt.length;e+=1)if(gt[e]!==t[e])return!1;return!0}function Jt(e){return _t.every(t=>Object.hasOwn(e,t))}function Yt(e){return typeof e==`string`?/^\s*\{/u.test(e)&&/\}\s*$/u.test(e):Jt(e)}function Xt(){return 1+((L?window.devicePixelRatio:1)-1)*.75}function Zt(e){let t=e.getBoundingClientRect(),n=window.innerHeight||document.documentElement.clientHeight,r=window.innerWidth||document.documentElement.clientWidth;return!(t.bottom<0||t.top>n||t.right<0||t.left>r)}function Qt(e){let t=e.target;if(t instanceof HTMLCanvasElement){let n=t.getBoundingClientRect();if(n.width===0||n.height===0||t.width===0||t.height===0)return null;let r=t.width/n.width,i=t.height/n.height,a=(e.clientX-n.left)*r,o=(e.clientY-n.top)*i;return!Number.isFinite(a)||!Number.isFinite(o)||Number.isNaN(a)||Number.isNaN(o)?null:{x:a,y:o}}return null}function $t(e){return new Promise((t,n)=>{let r=new FileReader;r.onerror=()=>n(r.error??Error(`Failed to read image slot source`)),r.onload=()=>t(r.result),r.readAsDataURL(e)})}async function en(e){if(!/^https?:\/\//i.test(e))return e;let t=await fetch(e);if(!t.ok)throw Error(`Failed to fetch image slot source from URL: ${e}. ${t.status}: ${t.statusText}`);return $t(await t.blob())}function tn(e){let t=e.replace(`OpenUrl: `,``),n=t.indexOf(` | Target: `),r,i;n===-1?(r=t,i=`_blank`):(r=t.substring(0,n),i=t.substring(n+11)),window.open(r,i)}function nn(e,t,n){let r=null,i=t,a=n;async function o(t){await e({module_or_path:t})}async function s(t){let n=await fetch(t);if(!n.ok)throw Error(`fetch ${t} responded with ${n.status} ${n.statusText}`);await e({module_or_path:await n.arrayBuffer()})}async function c(e,t){try{return await e(t),null}catch(e){return e}}return{load(){if(!r){let e=i,t=null;t=(async()=>{let n=await c(o,e);if(!n)return;console.warn(`Primary WASM load failed from ${e}: ${n.message}`);let i=null;if(a!==null){if(console.warn(`Attempting to load WASM from backup URL: ${a}`),i=await c(o,a),!i)return;console.warn(`Backup WASM load failed from ${a}: ${i.message}`)}console.warn(`Retrying WASM load with buffered instantiation`);let l=await c(s,e);if(l&&(console.warn(`Buffered WASM load from ${e} failed: ${l.message}`),!(a!==null&&(l=await c(s,a),!l))))throw console.error(`Primary WASM URL failed: ${n.message}`),i&&console.error(`Backup WASM URL failed: ${i.message}`),console.error(`Buffered fallback failed: ${l.message}`),r===t&&(r=null),Error(`WASM loading failed from all sources.`)})(),r=t}return r},setWasmUrl(e){if(typeof e!=`string`||e.trim()===``)throw TypeError(`setWasmUrl() expects a non-empty URL string`);a=null,e!==i&&(i=e,r=null)}}}var rn=null;function an(){return rn??=nn(Vt,`https://cdn.jsdelivr.net/npm/@lottiefiles/dotlottie-web@0.80.0/dist/dotlottie-player.wasm`,`https://unpkg.com/@lottiefiles/dotlottie-web@0.80.0/dist/dotlottie-player.wasm`),rn}var on=e=>{switch(e){case`reverse`:return Ft.Reverse;case`bounce`:return Ft.Bounce;case`reverse-bounce`:return Ft.ReverseBounce;default:return Ft.Forward}},sn=e=>{switch(e){case Ft.Reverse:return`reverse`;case Ft.Bounce:return`bounce`;case Ft.ReverseBounce:return`reverse-bounce`;default:return`forward`}},cn=e=>{switch(e){case`contain`:return`contain`;case`cover`:return`cover`;case`fill`:return`fill`;case`fit-height`:return`fit-height`;case`fit-width`:return`fit-width`;case`none`:return`none`;default:return`contain`}},ln=class{constructor(e){I(this,`_canvas`,null),I(this,`_pendingLoad`,null),I(this,`_srcFetchAbort`,null),I(this,`_context`,null),I(this,`_eventManager`,void 0),I(this,`_animationFrameId`,null),I(this,`_frameManager`,void 0),I(this,`_boundAnimationLoop`,void 0),I(this,`_dotLottieCore`,null),I(this,`_stateMachineId`,``),I(this,`_stateMachineConfig`,null),I(this,`_isStateMachineRunning`,!1),I(this,`_renderConfig`,{}),I(this,`_isFrozen`,!1),I(this,`_backgroundColor`,null),I(this,`_lastFrameTime`,null),I(this,`_boundOnClick`,null),I(this,`_boundOnPointerUp`,null),I(this,`_boundOnPointerDown`,null),I(this,`_boundOnPointerMove`,null),I(this,`_boundOnPointerEnter`,null),I(this,`_boundOnPointerLeave`,null),I(this,`_bufferMismatchCount`,0),I(this,`_lastExpectedBufferSize`,0),I(this,`_cachedImageData`,null),I(this,`_cachedImageDataBuffer`,null),I(this,`_cachedImageDataByteOffset`,0),I(this,`_marker`,``),I(this,`_segment`,null),this._canvas=e.canvas??null,this._eventManager=new Ht,this._frameManager=new ht,this._boundAnimationLoop=this._animationLoop.bind(this),this._renderConfig={...e.renderConfig,devicePixelRatio:e.renderConfig?.devicePixelRatio||Xt(),freezeOnOffscreen:e.renderConfig?.freezeOnOffscreen??!0};let t=null;e.src&&!e.data&&(this._srcFetchAbort=new AbortController,t=this._fetchData(e.src,this._srcFetchAbort.signal),t.catch(()=>{})),this._initWasm().then(()=>{this._dotLottieCore=this._createCore(),this._dotLottieCore.set_autoplay(e.autoplay??!1),this._dotLottieCore.set_loop(e.loop??!1),this._dotLottieCore.set_loop_count(e.loopCount??0),this._dotLottieCore.set_mode(on(e.mode??`forward`)),this._dotLottieCore.set_speed(e.speed??1),this._dotLottieCore.set_use_frame_interpolation(e.useFrameInterpolation??!0),e.segment&&e.segment.length===2&&(this._segment=[e.segment[0],e.segment[1]],this._dotLottieCore.set_segment(this._segment[0],this._segment[1])),this._marker=e.marker??``,this._marker&&this._dotLottieCore.set_marker(this._marker),this._dotLottieCore.set_layout(e.layout?.fit??`contain`,e.layout?.align?.[0]??.5,e.layout?.align?.[1]??.5),this._applyAssetResolver(e.assetResolver??null),this._stateMachineId=e.stateMachineId??``,this._stateMachineConfig=e.stateMachineConfig??null,this._onCoreCreated(),this._eventManager.dispatch({type:`ready`}),e.data?this._canvas?this._loadFromData(e.data):this._pendingLoad={data:e.data}:e.src&&(this._canvas?this._loadFromSrc(e.src,t):this._pendingLoad={src:e.src,dataPromise:t}),e.backgroundColor&&this.setBackgroundColor(e.backgroundColor)}).catch(e=>{this._srcFetchAbort?.abort(),console.error(`[dotlottie-web] Initialization failed:`,e),this._eventManager.dispatch({type:`loadError`,error:Error(`Failed to load wasm module: ${e}`)})})}async _initWasm(){return an().load()}_createCore(){return new Lt}_onCoreCreated(){}_setupTarget(e,t){return this._dotLottieCore?this._dotLottieCore.setup_sw_target(e,t):!1}_drainPlayerEvents({skipFrame:e=!1}={}){if(this._dotLottieCore)for(;;){let t=this._dotLottieCore.poll_event();if(t==null)break;switch(t.type){case`Load`:setTimeout(()=>this._eventManager.dispatch({type:`load`}),0);break;case`LoadError`:setTimeout(()=>this._eventManager.dispatch({type:`loadError`,error:Error(`failed to load`)}),0);break;case`Play`:queueMicrotask(()=>this._eventManager.dispatch({type:`play`}));break;case`Pause`:queueMicrotask(()=>this._eventManager.dispatch({type:`pause`}));break;case`Stop`:queueMicrotask(()=>this._eventManager.dispatch({type:`stop`}));break;case`Frame`:{let n=t.frameNo??0;e||queueMicrotask(()=>this._eventManager.dispatch({type:`frame`,currentFrame:n}));break}case`Render`:{let n=t.frameNo??0;e||queueMicrotask(()=>this._eventManager.dispatch({type:`render`,currentFrame:n}));break}case`Loop`:{let e=t.loopCount??0;queueMicrotask(()=>this._eventManager.dispatch({type:`loop`,loopCount:e}));break}case`Complete`:queueMicrotask(()=>this._eventManager.dispatch({type:`complete`}))}}}_discardPlayerEvents(){for(;this._dotLottieCore?.poll_event()!=null;);}_drainSmEvents(){if(this._dotLottieCore){for(;;){let e=this._dotLottieCore.sm_poll_event();if(e==null)break;switch(e.type){case`Start`:queueMicrotask(()=>{this._isStateMachineRunning=!0,this._eventManager.dispatch({type:`stateMachineStart`}),this._startAnimationLoop()});break;case`Stop`:queueMicrotask(()=>{this._isStateMachineRunning=!1,this._eventManager.dispatch({type:`stateMachineStop`}),this._dotLottieCore?.status()!==Y.Playing&&this._stopAnimationLoop()});break;case`CustomEvent`:this._eventManager.dispatch({type:`stateMachineCustomEvent`,eventName:e.message??``});break;case`BooleanInputChange`:this._eventManager.dispatch({type:`stateMachineBooleanInputValueChange`,inputName:e.name??``,newValue:e.newValue,oldValue:e.oldValue});break;case`NumericInputChange`:this._eventManager.dispatch({type:`stateMachineNumericInputValueChange`,inputName:e.name??``,newValue:e.newValue,oldValue:e.oldValue});break;case`StringInputChange`:this._eventManager.dispatch({type:`stateMachineStringInputValueChange`,inputName:e.name??``,newValue:e.newValue,oldValue:e.oldValue});break;case`InputFired`:this._eventManager.dispatch({type:`stateMachineInputFired`,inputName:e.name??``});break;case`Transition`:this._eventManager.dispatch({type:`stateMachineTransition`,fromState:e.previousState??``,toState:e.newState??``});break;case`StateEntered`:this._eventManager.dispatch({type:`stateMachineStateEntered`,state:e.state??``});break;case`StateExit`:this._eventManager.dispatch({type:`stateMachineStateExit`,state:e.state??``});break;case`Error`:this._eventManager.dispatch({type:`stateMachineError`,error:e.message??``})}}for(;;){let e=this._dotLottieCore.sm_poll_internal_event();if(e==null)break;if(e.type===`Message`){let t=e.message??``;L&&t.startsWith(`OpenUrl: `)?tn(t):this._eventManager.dispatch({type:`stateMachineInternalMessage`,message:t})}}}}_dispatchError(e){console.error(e),this._eventManager.dispatch({type:`loadError`,error:Error(e)})}async _fetchData(e,t=null){let n=await fetch(e,{signal:t});if(!n.ok)throw Error(`Failed to fetch animation data from URL: ${e}. ${n.status}: ${n.statusText}`);let r=await n.arrayBuffer();return qt(r)?r:new TextDecoder().decode(r)}_loadFromData(e){if(this._dotLottieCore===null)return;if(!this._canvas){console.warn(`[dotlottie-web] Cannot load animation without canvas. Call setCanvas() first.`);return}this._syncCanvasSize(),this._setupTarget(this._canvas.width,this._canvas.height);let t=!1;if(typeof e==`string`){if(t=this._dotLottieCore.load_animation(e),!t&&!Yt(e)){this._discardPlayerEvents(),this._dispatchError(`Invalid Lottie JSON string: The provided string does not conform to the Lottie JSON format.`);return}}else if(e instanceof ArrayBuffer){if(!qt(e)){this._dispatchError(`Invalid dotLottie ArrayBuffer: The provided ArrayBuffer does not conform to the dotLottie format.`);return}t=this._dotLottieCore.load_dotlottie_data(new Uint8Array(e))}else if(typeof e==`object`){if(!Yt(e)){this._dispatchError(`Invalid Lottie JSON object: The provided object does not conform to the Lottie JSON format.`);return}t=this._dotLottieCore.load_animation(JSON.stringify(e))}else{this._dispatchError(`Unsupported data type for animation data. Expected:
          - string (Lottie JSON),
          - ArrayBuffer (dotLottie),
          - object (Lottie JSON).
          Received: ${typeof e}`);return}if(t){if(this._renderConfig.quality!==void 0&&this._dotLottieCore.set_quality(this._renderConfig.quality),this._drainPlayerEvents({skipFrame:!!this._marker||!!this._segment}),this._marker&&this._dotLottieCore.set_marker(this._marker),this._segment){this._dotLottieCore.set_segment(this._segment[0],this._segment[1]);let e=sn(this._dotLottieCore.mode()),t=e===`reverse`||e===`reverse-bounce`?this._segment[1]:this._segment[0];this._dotLottieCore.set_frame(t)}setTimeout(()=>{this._eventManager.dispatch({type:`frame`,currentFrame:this.currentFrame})},0),this._dotLottieCore.render(),this._drainPlayerEvents(),this._draw(),this._stateMachineId?this.stateMachineLoad(this._stateMachineId)&&this.stateMachineStart()&&this._startAnimationLoop():this._dotLottieCore.status()===Y.Playing&&this._startAnimationLoop(),L&&this._canvas instanceof HTMLCanvasElement&&(this._renderConfig.freezeOnOffscreen&&(Ut.observe(this._canvas,this),Zt(this._canvas)||this.freeze()),this._renderConfig.autoResize&&Wt.observe(this._canvas,this))}else this._drainPlayerEvents()}_loadFromSrc(e,t){(t??this._fetchData(e)).then(e=>this._loadFromData(e)).catch(t=>this._dispatchError(`Failed to load animation data from URL: ${e}. ${t}`))}get buffer(){return this._dotLottieCore?this._dotLottieCore.get_pixel_buffer():null}get activeAnimationId(){return this._dotLottieCore?.animation_id()??void 0}get activeThemeId(){return this._dotLottieCore?.theme_id()??void 0}get layout(){if(this._dotLottieCore)return{align:[this._dotLottieCore.layout_align_x(),this._dotLottieCore.layout_align_y()],fit:cn(this._dotLottieCore.layout_fit())}}get marker(){return this._dotLottieCore?.current_marker()??``}get manifest(){try{let e=this._dotLottieCore?.manifest_string();if(this._dotLottieCore===null||!e)return null;let t=JSON.parse(e);return Object.keys(t).length===0?null:t}catch{return null}}get renderConfig(){return this._renderConfig}get segment(){if(this._dotLottieCore)return[this._dotLottieCore.segment_start(),this._dotLottieCore.segment_end()]}get loop(){return this._dotLottieCore?.loop_animation()??!1}get mode(){return this._dotLottieCore?sn(this._dotLottieCore.mode()):`forward`}get isFrozen(){return this._isFrozen}get isStateMachineRunning(){return this._isStateMachineRunning}get backgroundColor(){return this._backgroundColor??``}get autoplay(){return this._dotLottieCore?.autoplay()??!1}get useFrameInterpolation(){return this._dotLottieCore?.use_frame_interpolation()??!1}get speed(){return this._dotLottieCore?.speed()??0}get isReady(){return this._dotLottieCore!==null}get isLoaded(){return(this._dotLottieCore?.status()??Y.Idle)!==Y.Idle}get isPlaying(){return this._dotLottieCore?.status()===Y.Playing}get isPaused(){return this._dotLottieCore?.status()===Y.Paused}get isStopped(){return this._dotLottieCore?.status()===Y.Stopped}get currentFrame(){return this._dotLottieCore?Math.round(this._dotLottieCore.current_frame()*100)/100:0}get loopCount(){return this._dotLottieCore?.current_loop_count()??0}get totalFrames(){return this._dotLottieCore?.total_frames()??0}get duration(){return(this._dotLottieCore?.duration()??0)/1e3}get canvas(){return this._canvas}load(e){this._dotLottieCore!==null&&(this._stopAnimationLoop(),this._cleanupCanvas(),this._isFrozen=!1,this._dotLottieCore.set_autoplay(e.autoplay??!1),this._dotLottieCore.set_loop(e.loop??!1),this._dotLottieCore.set_loop_count(e.loopCount??0),this._dotLottieCore.set_mode(on(e.mode??`forward`)),this._dotLottieCore.set_speed(e.speed??1),this._dotLottieCore.set_use_frame_interpolation(e.useFrameInterpolation??!0),e.segment&&e.segment.length===2?(this._segment=[e.segment[0],e.segment[1]],this._dotLottieCore.set_segment(this._segment[0],this._segment[1])):(this._segment=null,this._dotLottieCore.clear_segment()),this._marker=e.marker??``,this._marker?this._dotLottieCore.set_marker(this._marker):this._dotLottieCore.clear_marker(),this._dotLottieCore.set_layout(e.layout?.fit??`contain`,e.layout?.align?.[0]??.5,e.layout?.align?.[1]??.5),this._applyAssetResolver(e.assetResolver??null),e.data?this._canvas?this._loadFromData(e.data):this._pendingLoad={data:e.data}:e.src&&(this._canvas?this._loadFromSrc(e.src):this._pendingLoad={src:e.src}),e.backgroundColor&&this.setBackgroundColor(e.backgroundColor))}_draw(){if(this._dotLottieCore===null||this._canvas===null||(!this._context&&`getContext`in this._canvas&&typeof this._canvas.getContext==`function`&&(!L||typeof HTMLCanvasElement<`u`&&this._canvas instanceof HTMLCanvasElement||typeof OffscreenCanvas<`u`&&this._canvas instanceof OffscreenCanvas)&&(this._context=this._canvas.getContext(`2d`)),!this._context))return;let e=this._dotLottieCore.get_pixel_buffer(),t=this._canvas.width,n=this._canvas.height,r=t*n*4;if(e.byteLength!==r){this._lastExpectedBufferSize===r?this._bufferMismatchCount+=1:(this._bufferMismatchCount=1,this._lastExpectedBufferSize=r),this._bufferMismatchCount===10&&console.warn(`[dotlottie-web] Persistent buffer size mismatch detected. Expected ${r} bytes for canvas ${t}x${n}, but got ${e.byteLength} bytes. This may indicate a WASM memory allocation issue or invalid canvas dimensions.`);return}this._bufferMismatchCount=0,this._lastExpectedBufferSize=r;let i=this._cachedImageData;if(i===null||i.width!==t||i.height!==n||i.data.byteLength!==r||this._cachedImageDataBuffer!==e.buffer||this._cachedImageDataByteOffset!==e.byteOffset){if(typeof ImageData>`u`)this._cachedImageData=this._context.createImageData(t,n);else{let r=new Uint8ClampedArray(e.buffer,e.byteOffset,e.byteLength);this._cachedImageData=new ImageData(r,t,n)}this._cachedImageDataBuffer=e.buffer,this._cachedImageDataByteOffset=e.byteOffset}if(typeof ImageData>`u`){let t=new Uint8ClampedArray(e.buffer,e.byteOffset,e.byteLength);this._cachedImageData.data.set(t)}this._context.putImageData(this._cachedImageData,0,0)}_cleanupCanvas(){this._canvas&&L&&this._canvas instanceof HTMLCanvasElement&&(Ut.unobserve(this._canvas),Wt.unobserve(this._canvas),this._cleanupStateMachineListeners())}_initializeCanvas(){this._setupRendererOnCanvas(),this._canvas&&L&&this._canvas instanceof HTMLCanvasElement&&this.isLoaded&&(this._renderConfig.freezeOnOffscreen&&(Ut.observe(this._canvas,this),Zt(this._canvas)||this.freeze()),this._renderConfig.autoResize&&Wt.observe(this._canvas,this),this._isStateMachineRunning&&this._setupStateMachineListeners()),this._canvas&&this._dotLottieCore&&this.isLoaded&&this._setupTarget(this._canvas.width,this._canvas.height)&&(this._dotLottieCore.render(),this._draw())}_setupRendererOnCanvas(){this._context=null}_stopAnimationLoop(){this._animationFrameId!==null&&(this._frameManager.cancelAnimationFrame(this._animationFrameId),this._animationFrameId=null),this._lastFrameTime=null}_startAnimationLoop(){this._animationFrameId===null&&this._dotLottieCore&&!this._isFrozen&&(this._dotLottieCore.status()===Y.Playing||this._isStateMachineRunning)&&(this._animationFrameId=this._frameManager.requestAnimationFrame(this._boundAnimationLoop))}_animationLoop(e){if(this._dotLottieCore===null){this._stopAnimationLoop();return}if(this._dotLottieCore.status()!==Y.Playing&&!this._isStateMachineRunning){this._stopAnimationLoop();return}try{let t=this._lastFrameTime===null?0:e-this._lastFrameTime;this._lastFrameTime=e;let n=this._isStateMachineRunning?this._dotLottieCore.sm_tick(t):this._dotLottieCore.tick(t);this._isStateMachineRunning?this._drainSmEvents():this._drainPlayerEvents(),n&&this._draw(),this._animationFrameId=this._frameManager.requestAnimationFrame(this._boundAnimationLoop)}catch(e){console.error(`Error in animation frame:`,e),this._eventManager.dispatch({type:`renderError`,error:e}),e instanceof WebAssembly.RuntimeError&&this.destroy()}}play(){if(this._dotLottieCore===null||!this.isLoaded)return;this._stopAnimationLoop();let e=this._dotLottieCore.play();this._drainPlayerEvents(),(e||this._dotLottieCore.status()===Y.Playing)&&(this._isFrozen=!1,this._startAnimationLoop()),this._canvas&&L&&this._canvas instanceof HTMLCanvasElement&&this._renderConfig.freezeOnOffscreen&&!Zt(this._canvas)&&this.freeze()}pause(){this._dotLottieCore!==null&&(this._dotLottieCore.pause(),this._drainPlayerEvents(),this._stopAnimationLoop())}stop(){if(this._dotLottieCore===null)return;let e=this._dotLottieCore.stop();this._drainPlayerEvents(),this._stopAnimationLoop(),e&&(this._eventManager.dispatch({type:`frame`,currentFrame:this.currentFrame}),this._dotLottieCore.render(),this._draw())}setFrame(e){if(this._dotLottieCore!==null&&this._dotLottieCore.set_frame(e)){let e=this._dotLottieCore.render();this._drainPlayerEvents(),e&&this._draw()}}setSpeed(e){this._dotLottieCore!==null&&this._dotLottieCore.set_speed(e)}setBackgroundColor(e){if(this._dotLottieCore!==null){if(L&&this._canvas instanceof HTMLCanvasElement)this._canvas.style.backgroundColor=e;else{let[t,n,r,i]=Kt(e);this._dotLottieCore.set_background(t,n,r,i)}this._backgroundColor=e}}setLoop(e){this._dotLottieCore!==null&&this._dotLottieCore.set_loop(e)}setLoopCount(e){this._dotLottieCore!==null&&this._dotLottieCore.set_loop_count(e)}setUseFrameInterpolation(e){this._dotLottieCore!==null&&this._dotLottieCore.set_use_frame_interpolation(e)}_applyAssetResolver(e){if(this._dotLottieCore!==null){if(e===null){this._dotLottieCore.set_asset_resolver(null);return}this._dotLottieCore.set_asset_resolver(t=>{try{return e(t)??null}catch(e){return console.error(`[dotlottie-web] assetResolver threw for "${t}":`,e),null}})}}addEventListener(e,t){this._eventManager.addEventListener(e,t)}removeEventListener(e,t){this._eventManager.removeEventListener(e,t)}destroy(){this._stopAnimationLoop(),this._isStateMachineRunning=!1,this._cleanupCanvas(),this._srcFetchAbort?.abort(),this._srcFetchAbort=null,this._pendingLoad=null;let e=this._dotLottieCore;if(this._dotLottieCore=null,this._context=null,e)try{e.free()}catch(e){console.warn(`[dotlottie-web] Error freeing wasm core during destroy:`,e)}this._eventManager.dispatch({type:`destroy`}),this._eventManager.removeAllEventListeners(),this._cleanupStateMachineListeners()}freeze(){this._animationFrameId!==null&&(this._stopAnimationLoop(),this._isFrozen=!0,this._eventManager.dispatch({type:`freeze`}))}unfreeze(){this._animationFrameId===null&&(this._isFrozen=!1,this._eventManager.dispatch({type:`unfreeze`}),this._startAnimationLoop())}_syncCanvasSize(){if(!(L&&this._canvas instanceof HTMLCanvasElement))return;let e=this._renderConfig.devicePixelRatio||window.devicePixelRatio||1,{height:t,width:n}=this._canvas.getBoundingClientRect();t!==0&&n!==0&&(this._canvas.width=n*e,this._canvas.height=t*e)}resize(){!this._dotLottieCore||!this.isLoaded||!this._canvas||(this._syncCanvasSize(),this._setupTarget(this._canvas.width,this._canvas.height)&&(this._dotLottieCore.render(),this._draw()))}setCanvas(e){if(!(!e||this._canvas===e)&&(this._canvas&&this._cleanupCanvas(),this._canvas=e,this._initializeCanvas(),this._pendingLoad)){let e=this._pendingLoad;this._pendingLoad=null,e.data?this._loadFromData(e.data):e.src&&this._loadFromSrc(e.src,e.dataPromise)}}setTransform(e){if(!this._dotLottieCore)return!1;let t=this._dotLottieCore.set_transform(new Float32Array(e));return t&&this._dotLottieCore.render()&&this._draw(),t}getTransform(){if(!this._dotLottieCore)return;let e=this._dotLottieCore.get_transform();return Array.from(e)}setSegment(e,t){this._dotLottieCore!==null&&(this._segment=[e,t],this._dotLottieCore.set_segment(e,t))}resetSegment(){this._dotLottieCore!==null&&(this._segment=null,this._dotLottieCore.clear_segment())}setMode(e){this._dotLottieCore!==null&&this._dotLottieCore.set_mode(on(e))}setRenderConfig(e){let{devicePixelRatio:t,freezeOnOffscreen:n,quality:r,...i}=e;this._renderConfig={...this._renderConfig,...i,devicePixelRatio:t||Xt(),freezeOnOffscreen:n??!0,...r!==void 0&&{quality:r}},r!==void 0&&this._dotLottieCore&&this._dotLottieCore.set_quality(r),L&&this._canvas instanceof HTMLCanvasElement&&(this._renderConfig.autoResize?Wt.observe(this._canvas,this):Wt.unobserve(this._canvas),this._renderConfig.freezeOnOffscreen?(Ut.observe(this._canvas,this),Zt(this._canvas)||this.freeze()):(Ut.unobserve(this._canvas),this._isFrozen&&this.unfreeze()))}loadAnimation(e){this._dotLottieCore===null||this._dotLottieCore.animation_id()===e||!this._canvas||(this._syncCanvasSize(),this._setupTarget(this._canvas.width,this._canvas.height),this._dotLottieCore.load_animation_from_id(e)?(this._renderConfig.quality!==void 0&&this._dotLottieCore.set_quality(this._renderConfig.quality),this._drainPlayerEvents(),this._dotLottieCore.render(),this._draw()):this._dispatchError(`Failed to load animation with id: ${e}`))}setMarker(e){this._dotLottieCore!==null&&(this.markers().some(t=>t.name===e)?(this._marker=e,this._dotLottieCore.set_marker(e)):(this._marker=``,this._segment=null,this._dotLottieCore.clear_marker(),this._dotLottieCore.clear_segment()))}markers(){let e=this._dotLottieCore?.markers();return e&&Array.isArray(e)?e:[]}setTheme(e){if(this._dotLottieCore===null)return!1;let t=this._dotLottieCore.set_theme(e);return t&&(this._dotLottieCore.render(),this._draw()),t}resetTheme(){if(this._dotLottieCore===null)return!1;let e=this._dotLottieCore.reset_theme();return e&&(this._dotLottieCore.render(),this._draw()),e}setThemeData(e){if(this._dotLottieCore===null)return!1;let t=typeof e==`string`?e:JSON.stringify(e),n=this._dotLottieCore.set_theme_data(t);return n&&(this._dotLottieCore.render(),this._draw()),n}setSlots(e){this._dotLottieCore!==null&&this._dotLottieCore.set_slots_str(JSON.stringify(e))&&(this._dotLottieCore.render(),this._draw())}_isKeyframeArray(e){return Array.isArray(e)&&e.length>0&&typeof e[0]==`object`&&e[0]!==null&&`t`in e[0]&&`s`in e[0]}getSlotIds(){if(!this._dotLottieCore)return[];let e=this._dotLottieCore.get_slot_ids();return Array.isArray(e)?e:[]}getSlotType(e){if(!this._dotLottieCore)return;let t=this._dotLottieCore.get_slot_type(e);if(t)return t}getSlot(e){if(!this._dotLottieCore)return;let t=this._dotLottieCore.get_slot_str(e);if(t)try{return JSON.parse(t)}catch{return}}getSlots(){if(!this._dotLottieCore)return{};try{return JSON.parse(this._dotLottieCore.get_slots_str())}catch{return{}}}setColorSlot(e,t){if(this._dotLottieCore===null)return!1;let n=this._isKeyframeArray(t),r=JSON.stringify({a:+!!n,k:t}),i=this._dotLottieCore.set_slot_str(e,r);return this._dotLottieCore.render(),this._draw(),i}setScalarSlot(e,t){if(this._dotLottieCore===null)return!1;let n=JSON.stringify({a:typeof t==`number`?0:1,k:t}),r=this._dotLottieCore.set_slot_str(e,n);return this._dotLottieCore.render(),this._draw(),r}setVectorSlot(e,t){if(this._dotLottieCore===null)return!1;let n=this._isKeyframeArray(t),r=JSON.stringify({a:+!!n,k:t}),i=this._dotLottieCore.set_slot_str(e,r);return this._dotLottieCore.render(),this._draw(),i}setGradientSlot(e,t,n){if(this._dotLottieCore===null)return!1;let r=this._isKeyframeArray(t),i=JSON.stringify({k:{a:+!!r,k:t},p:n}),a=this._dotLottieCore.set_slot_str(e,i);return this._dotLottieCore.render(),this._draw(),a}setTextSlot(e,t){if(this._dotLottieCore===null)return!1;let n=this._dotLottieCore.get_slot_str(e),r=t;if(n){let e=JSON.parse(n);if(e&&`k`in e&&Array.isArray(e.k)){let n=e.k[0];`s`in n&&typeof n.s==`object`&&(r={...n.s,...t})}}let i=JSON.stringify({a:0,k:[{t:0,s:r}]}),a=this._dotLottieCore.set_slot_str(e,i);return this._dotLottieCore.render(),this._draw(),a}async setImageSlot(e,t){if(this._dotLottieCore===null)return!1;let n=await en(t);if(this._dotLottieCore===null)return!1;let r=this._dotLottieCore.set_image_slot(e,n);return this._dotLottieCore.render(),this._draw(),r}resetSlot(e){if(this._dotLottieCore===null)return!1;let t=this._dotLottieCore.reset_slot(e);return this._dotLottieCore.render(),this._draw(),t}clearSlot(e){if(this._dotLottieCore===null)return!1;let t=this._dotLottieCore.clear_slot(e);return this._dotLottieCore.render(),this._draw(),t}resetSlots(){if(this._dotLottieCore===null)return!1;let e=this._dotLottieCore.reset_slots();return this._dotLottieCore.render(),this._draw(),e}clearSlots(){if(this._dotLottieCore===null)return!1;let e=this._dotLottieCore.clear_slots();return this._dotLottieCore.render(),this._draw(),e}setLayout(e){this._dotLottieCore!==null&&this._dotLottieCore.set_layout(e.fit??`contain`,e.align?.[0]??.5,e.align?.[1]??.5)}setViewport(e,t,n,r){return this._dotLottieCore!==null&&this._dotLottieCore.set_viewport(e,t,n,r)}static setWasmUrl(e){an().setWasmUrl(e)}static preload(){return an().load()}static async registerFont(e,t){try{await an().load();let n;if(typeof t==`string`){let e=await fetch(t);if(!e.ok)return console.error(`Failed to fetch font from URL: ${t}. Status: ${e.status}`),!1;n=new Uint8Array(await e.arrayBuffer())}else n=t instanceof Uint8Array?t:new Uint8Array(t);let r=kt(e,n);return r||console.error(`Failed to register font "${e}". Font data may be invalid.`),r}catch(t){return console.error(`Error registering font "${e}":`,t),!1}}animationSize(){let e=this._dotLottieCore?.animation_size();return{width:e?.[0]??0,height:e?.[1]??0}}stateMachineLoad(e){return this._dotLottieCore?this._dotLottieCore.state_machine_load_from_id(e):!1}stateMachineLoadData(e){return this._dotLottieCore?this._dotLottieCore.state_machine_load(e):!1}stateMachineSetConfig(e){this._stateMachineConfig=e}stateMachineStart(){if(this._dotLottieCore===null)return!1;let e=this._dotLottieCore.sm_start(this._stateMachineConfig?.openUrlPolicy?.requireUserInteraction??!0,this._stateMachineConfig?.openUrlPolicy?.whitelist??[]);return this._drainSmEvents(),e&&(this._isStateMachineRunning=!0,this._setupStateMachineListeners(),this._startAnimationLoop()),e}stateMachineStop(){if(!this._dotLottieCore)return!1;let e=this._dotLottieCore.sm_stop();return this._drainSmEvents(),e&&(this._isStateMachineRunning=!1,this._cleanupStateMachineListeners(),this._dotLottieCore.status()!==Y.Playing&&this._stopAnimationLoop()),e}stateMachineGetStatus(){return this._dotLottieCore?.sm_status()??``}stateMachineGetCurrentState(){return this._dotLottieCore?.sm_current_state()??``}stateMachineGetActiveId(){return this._dotLottieCore?.state_machine_id()??``}stateMachineOverrideState(e,t=!1){return this._dotLottieCore?.sm_override_current_state(e,t)??!1}stateMachineSetSeed(e){return this._dotLottieCore?.sm_set_seed(BigInt(Math.trunc(e)))??!1}stateMachineGet(e){return this._dotLottieCore?.get_state_machine(e)??``}stateMachineGetListeners(){if(!this._dotLottieCore)return[];let e=this._dotLottieCore.sm_framework_setup();return Array.isArray(e)?e:[]}stateMachineSetBooleanInput(e,t){return this._dotLottieCore?.sm_set_boolean_input(e,t)??!1}stateMachineSetNumericInput(e,t){return this._dotLottieCore?.sm_set_numeric_input(e,t)??!1}stateMachineSetStringInput(e,t){return this._dotLottieCore?.sm_set_string_input(e,t)??!1}stateMachineGetBooleanInput(e){return this._dotLottieCore?.sm_get_boolean_input(e)??void 0}stateMachineGetNumericInput(e){return this._dotLottieCore?.sm_get_numeric_input(e)??void 0}stateMachineGetStringInput(e){return this._dotLottieCore?.sm_get_string_input(e)??void 0}stateMachineGetInputs(){if(!this._dotLottieCore)return[];let e=this._dotLottieCore.sm_get_inputs();return Array.isArray(e)?e:[]}stateMachineFireEvent(e){this._dotLottieCore?.sm_fire(e)}stateMachinePostClickEvent(e,t){this._dotLottieCore?.sm_post_click(e,t)}stateMachinePostPointerUpEvent(e,t){this._dotLottieCore?.sm_post_pointer_up(e,t)}stateMachinePostPointerDownEvent(e,t){this._dotLottieCore?.sm_post_pointer_down(e,t)}stateMachinePostPointerMoveEvent(e,t){this._dotLottieCore?.sm_post_pointer_move(e,t)}stateMachinePostPointerEnterEvent(e,t){this._dotLottieCore?.sm_post_pointer_enter(e,t)}stateMachinePostPointerExitEvent(e,t){this._dotLottieCore?.sm_post_pointer_exit(e,t)}_onClick(e){let t=Qt(e);t&&this.stateMachinePostClickEvent(t.x,t.y)}_onPointerUp(e){let t=Qt(e);t&&this.stateMachinePostPointerUpEvent(t.x,t.y)}_onPointerDown(e){let t=Qt(e);t&&this.stateMachinePostPointerDownEvent(t.x,t.y)}_onPointerMove(e){let t=Qt(e);t&&this.stateMachinePostPointerMoveEvent(t.x,t.y)}_onPointerEnter(e){let t=Qt(e);t&&this.stateMachinePostPointerEnterEvent(t.x,t.y)}_onPointerLeave(e){let t=Qt(e);t&&this.stateMachinePostPointerExitEvent(t.x,t.y)}_setupStateMachineListeners(){if(L&&this._canvas instanceof HTMLCanvasElement&&this._dotLottieCore!==null&&this.isLoaded){let e=this.stateMachineGetListeners();this._cleanupStateMachineListeners(),e.includes(`Click`)&&(this._boundOnClick=this._onClick.bind(this),this._canvas.addEventListener(`click`,this._boundOnClick)),e.includes(`PointerUp`)&&(this._boundOnPointerUp=this._onPointerUp.bind(this),this._canvas.addEventListener(`pointerup`,this._boundOnPointerUp)),e.includes(`PointerDown`)&&(this._boundOnPointerDown=this._onPointerDown.bind(this),this._canvas.addEventListener(`pointerdown`,this._boundOnPointerDown)),e.includes(`PointerMove`)&&(this._boundOnPointerMove=this._onPointerMove.bind(this),this._canvas.addEventListener(`pointermove`,this._boundOnPointerMove)),e.includes(`PointerEnter`)&&(this._boundOnPointerEnter=this._onPointerEnter.bind(this),this._canvas.addEventListener(`pointerenter`,this._boundOnPointerEnter)),e.includes(`PointerExit`)&&(this._boundOnPointerLeave=this._onPointerLeave.bind(this),this._canvas.addEventListener(`pointerleave`,this._boundOnPointerLeave))}}_cleanupStateMachineListeners(){L&&this._canvas instanceof HTMLCanvasElement&&(this._boundOnClick&&=(this._canvas.removeEventListener(`click`,this._boundOnClick),null),this._boundOnPointerUp&&=(this._canvas.removeEventListener(`pointerup`,this._boundOnPointerUp),null),this._boundOnPointerDown&&=(this._canvas.removeEventListener(`pointerdown`,this._boundOnPointerDown),null),this._boundOnPointerMove&&=(this._canvas.removeEventListener(`pointermove`,this._boundOnPointerMove),null),this._boundOnPointerEnter&&=(this._canvas.removeEventListener(`pointerenter`,this._boundOnPointerEnter),null),this._boundOnPointerLeave&&=(this._canvas.removeEventListener(`pointerleave`,this._boundOnPointerLeave),null))}},un=``+new URL(`dotlottie-player-vUNKgFai.wasm`,import.meta.url).href;ln.setWasmUrl(un);var dn=3.8,fn=class{host;data=new Map;slots=[];constructor(e){this.host=e}preload(e){for(let t of e)this.load(t);let t=this.slot();t.busy=!0;let n=new ln({canvas:t.canvas,autoplay:!1,loop:!1});n.addEventListener(`ready`,()=>{n.destroy(),t.busy=!1})}play(e,t,n,r,i=1){let a=Math.round(r*dn*i),o=this.slot();o.busy=!0,o.t=0;let s=o.canvas;s.style.width=`${a}px`,s.style.height=`${a}px`,s.style.transform=`translate(${Math.round(t-a/2)}px, ${Math.round(n-a/2)}px)`,s.hidden=!1,this.load(e).then(t=>{if(!o.busy)return;let n=new ln({canvas:s,data:t,autoplay:!1,loop:!1,renderConfig:{autoResize:!1,freezeOnOffscreen:!1}});o.player=n,n.addEventListener(`loadError`,t=>{console.warn(`[vfx]`,e,t.error),this.finish(o)})}).catch(t=>{console.warn(`[vfx]`,e,t),this.finish(o)})}tick(e){for(let t of this.slots){if(!t.busy||!t.player||!t.player.isLoaded)continue;t.t+=e;let n=t.player.totalFrames,r=t.t/t.player.duration*n;r>=n-1?this.finish(t):t.player.setFrame(r)}}finish(e){e.player?.destroy(),e.player=null,e.busy=!1,e.canvas.hidden=!0}load(e){let t=this.data.get(e);if(!t){let n=new URL(`vfx/${e}.json`,document.baseURI).toString();t=fetch(n).then(e=>{if(!e.ok)throw Error(`${n} ${e.status}`);return e.text()}),this.data.set(e,t)}return t}slot(){let e=this.slots.find(e=>!e.busy);if(!e){let t=document.createElement(`canvas`);t.className=`vfx`,t.hidden=!0,this.host.appendChild(t),e={canvas:t,player:null,busy:!1,t:0},this.slots.push(e)}return e}},pn=[{id:`lagoon`,name:`Lagoon`,src:`/tanks/lagoon.png`,iosSrc:`/tanks/ios/lagoon.png?v=3`,wash:`#dff3ea`,floor:`#ADE2CB`,swatch:`#9ed9c4`,swatchFloor:`#c8ead8`,swatchGlow:`#f3f0c4`},{id:`reef`,name:`Reef`,src:`/tanks/reef.png?v=2`,iosSrc:`/tanks/ios/reef.png?v=3`,wash:`#f7d8c4`,floor:`#ECB28A`,swatch:`#f0b896`,swatchFloor:`#f8d4bc`,swatchGlow:`#ffe8d0`},{id:`deep`,name:`Deep`,src:`/tanks/deep.png?v=2`,iosSrc:`/tanks/ios/deep.png?v=3`,wash:`#2d5a72`,floor:`#0C1E3F`,swatch:`#3d7a96`,swatchFloor:`#2a4e64`,swatchGlow:`#8ec8d8`},{id:`kelp`,name:`Kelp`,src:`/tanks/kelp.png?v=2`,iosSrc:`/tanks/ios/kelp.png?v=3`,wash:`#d4e08a`,floor:`#C6A841`,swatch:`#b4c86a`,swatchFloor:`#c8d878`,swatchGlow:`#f0e8a0`},{id:`dusk`,name:`Dusk`,src:`/tanks/dusk.png?v=2`,iosSrc:`/tanks/ios/dusk.png?v=3`,wash:`#d4c4e4`,floor:`#AE89BF`,swatch:`#c4a8d8`,swatchFloor:`#d8c4e4`,swatchGlow:`#f0c8c8`}],mn=`sprout-tank`;function hn(e){return pn.find(t=>t.id===e)??pn[0]}function gn(){try{return hn(localStorage.getItem(mn))}catch{return pn[0]}}function _n(e){try{localStorage.setItem(mn,e)}catch{}}function vn(e,t=e.wash){document.documentElement.style.setProperty(`--tank-wash`,t),document.body.style.background=t}function yn(e,t){return e.replace(/\sid="sprout"/,` id="${t}"`).replace(/\sid="sail"/,` id="${t}"`).replace(/\sid="orca"/,` id="${t}"`).replace(/\sid="axolotl"/,` id="${t}"`).replace(/id="sprout-outline"/g,`id="${t}-outline"`).replace(/id="sail-outline"/g,`id="${t}-outline"`).replace(/url\(#sprout-outline\)/g,`url(#${t}-outline)`).replace(/url\(#sail-outline\)/g,`url(#${t}-outline)`).replace(/id="sprout-body-clip"/g,`id="${t}-body-clip"`).replace(/url\(#sprout-body-clip\)/g,`url(#${t}-body-clip)`).replace(/id="(fin-[lr]|fin-[lr]-clip|lumen-lamp|sprout-aura|badge-clip)"/g,`id="${t}-$1"`).replace(/href="#(fin-[lr])"/g,`href="#${t}-$1"`).replace(/url\(#(fin-[lr]-clip|lumen-lamp|sprout-aura|badge-clip)\)/g,`url(#${t}-$1)`)}function bn(e,t,n,r,i){let a=document.createElement(`template`);a.innerHTML=yn(e,t).trim();let o=a.content.firstElementChild;if(!(o instanceof SVGSVGElement))throw Error(`Collection portrait failed to load`);return o.classList.remove(`mascot-svg`),o.classList.add(`collection-svg`),o.removeAttribute(`aria-hidden`),de(o,n,!1),h(o,r),Re(o,i.id,n,r),o.style.transform=`scale(0.1) translate(${-y.originX}px, ${-y.originY}px)`,o}function xn(e,t,n,r,i){let a=document.createElement(`article`);a.className=`collection-card`,a.classList.toggle(`in-tank`,e.id===n),a.dataset.kind=e.id;let o=document.createElement(`div`);o.className=`collection-portrait`,o.append(bn(t,`col-${e.id}`,r,i,e));let s=document.createElement(`div`);s.className=`collection-meta`;let c=document.createElement(`h3`);c.textContent=e.name;let l=document.createElement(`p`);l.className=`collection-badge`,l.textContent=e.id===n?`In the tank`:`Little legend`;let u=document.createElement(`div`);u.className=`collection-stars`,u.setAttribute(`role`,`radiogroup`),u.setAttribute(`aria-label`,`${e.name} stars`);for(let t of f(e.id)){let n=document.createElement(`button`);n.type=`button`,n.className=`collection-star`,n.classList.toggle(`active`,t.stage===i.stage),n.dataset.evo=String(t.stage),n.title=`${e.name} ${t.roman}`,n.setAttribute(`aria-label`,`${e.name} ${t.roman}`),n.textContent=t.roman,u.append(n)}let d=document.createElement(`div`);d.className=`collection-chromas`,d.setAttribute(`role`,`radiogroup`),d.setAttribute(`aria-label`,`${e.name} chromas`);for(let t of _){let n=document.createElement(`button`);n.type=`button`,n.className=`collection-chroma`,n.classList.toggle(`active`,t.id===r.id),n.dataset.palette=t.id,n.title=t.name,n.setAttribute(`aria-label`,`${e.name} ${t.name}`),n.style.setProperty(`--swatch`,t.body),n.style.setProperty(`--swatch-belly`,t.belly),d.append(n)}return s.append(c,l,u,d),a.append(o,s),a}function Sn(){let e=document.createElement(`article`);e.className=`collection-card collection-soon`,e.setAttribute(`aria-hidden`,`true`);let t=document.createElement(`p`);return t.textContent=`More legends`,e.append(t),e}function Cn(e,t,n,r){e.replaceChildren();for(let r of g){let i=le(r.id,r.defaultPalette),a=te(r.id);e.append(xn(r,t[r.id],n,i,a))}e.append(Sn()),e.onclick=e=>{let t=e.target;if(!(t instanceof HTMLElement))return;let n=t.closest(`.collection-card`);if(!n||n.classList.contains(`collection-soon`))return;let i=g.find(e=>e.id===n.dataset.kind);if(!i)return;let a=t.closest(`.collection-star`);if(a){let e=f(i.id).find(e=>e.stage===Number(a.dataset.evo));e&&r.pickEvo(i,e);return}let o=t.closest(`.collection-chroma`);if(o){let e=_.find(e=>e.id===o.dataset.palette);e&&r.pickPalette(i,e);return}r.pickKind(i)}}var wn={sprout:Le(e,`sprout`),sail:t,orca:Le(n,`orca`),axolotl:Le(r,`axolotl`)},Tn=document.querySelector(`#stage`),En=document.querySelector(`#fx`),Dn=document.querySelector(`#status`),On=document.querySelector(`#hint`),kn=document.querySelector(`.sleep-label`),An=document.querySelector(`#kind-name`),jn=document.querySelector(`#collection-btn`),X=document.querySelector(`#collection`),Mn=document.querySelector(`#collection-grid`),Nn=document.querySelector(`#collection-close`);if(!Tn||!En||!Dn||!On||!kn||!An)throw Error(`Sprout markup is missing`);var Pn=Tn,Fn=En,In=Dn,Ln=On,Rn=kn,zn=An,Z=new URLSearchParams(location.search),Q=window.__sprout??{},$=Z.has(`embed`)||Q.embed===!0,Bn=Z.has(`tray`),Vn=Z.get(`coat`)??Q.coat??null,Hn=Z.get(`evo`)??Q.evo??`3`,Un=Z.get(`type`)??Q.type??null,Wn=Z.get(`skin`)??Q.skin??null,Gn=Z.get(`costume`)??Q.costume??null,Kn=Z.get(`tank`)??Q.tank??null,qn=Number(Z.get(`radius`)??Q.radius??0),Jn=Number(Z.get(`glow`)??Q.glow??0);$&&document.documentElement.classList.add(`embed`),$&&Bn&&document.documentElement.classList.add(`embed-tray`);function Yn(e){document.querySelector(`svg.mascot-svg`)?.remove();let t=document.createElement(`template`);t.innerHTML=wn[e].trim();let n=t.content.firstElementChild;if(!(n instanceof SVGSVGElement))throw Error(`Mascot SVG failed to load`);return Pn.after(n),n}function Xn(e,t={}){(window.webkit?.messageHandlers?.riverSprite)?.postMessage({event:e,...t})}async function Zn(){let e=$?re(Un):ie(),t=Yn(e.id),n=$&&Kn?hn(Kn):gn(),r=$&&!Kn,i=e=>$?e.iosSrc:e.src;r||vn(n,$?n.floor:n.wash);let a=r?new Image:await $e(i(n)),o=new Ze(Pn,Fn,t,a,n,r);o.anchorBottom=$,o.resize();let c=new st(o.w*.5,o.h*($?.5:.46));Jn>0&&(c.glowLevel=Jn);let u=new fn(document.body);u.preload([...new Set(Object.values(nt).flatMap(e=>e.cues.flatMap(e=>e.fx?[e.fx]:[])))]),c.onFx=(e,t,n,r)=>u.play(e,t,n,c.radius,r),c.anchored=$;let d=window.matchMedia?.(`(prefers-reduced-motion: reduce)`);d&&(c.reduceMotion=d.matches,d.addEventListener?.(`change`,e=>{c.reduceMotion=e.matches}));let p=Array.from(document.querySelectorAll(`[data-emote]`)),ne=Array.from(document.querySelectorAll(`[data-palette]`)),v=Array.from(document.querySelectorAll(`[data-tank]`)),oe=Array.from(document.querySelectorAll(`[data-evo]`)),ce=Array.from(document.querySelectorAll(`[data-kind]`)),fe=Array.from(document.querySelectorAll(`[data-skin]`)),x=document.querySelector(`#costumes`),S=$?be(Wn):xe(),C=$?se(Vn??e.defaultPalette):le(e.id,e.defaultPalette);c.personality=ct[C.id]??null,queueMicrotask(()=>ge());let w=()=>e.id===`sprout`?S:he[0],pe=n=>{C=n,c.personality=ct[n.id]??null,de(t,n),Re(t,e.id,n,E,Gn),me(),$||ue(n.id,e.id);for(let e of ne)e.classList.toggle(`active`,e.dataset.palette===n.id)},me=()=>{if(!x||$&&!Bn)return;let t=E.costume?ke(e.id,C):[];if(x.hidden=t.length<2,t.length<2)return;let n=Me(e.id,C,Gn);x.replaceChildren(...t.map(e=>{let t=document.createElement(`button`);t.type=`button`,t.className=`kind-swatch${e===n?` active`:``}`;let r=Oe[e];return t.textContent=r?.name??e,t.title=r?`${r.name} — ${r.rarity}, ${r.price} coins`:e,r&&(t.dataset.rarity=r.rarity),t.addEventListener(`pointerdown`,e=>e.stopPropagation()),t.addEventListener(`click`,()=>_e(e)),t}))},T=document.getElementById(`signatures`),ge=()=>{if(!T||$&&!Bn)return;let t=E.costume?Me(e.id,C,Gn):null,n=t?lt[t]:null;T.hidden=!n,n&&T.replaceChildren(...n.map(e=>{let t=document.createElement(`button`);return t.type=`button`,t.className=`kind-swatch`,t.textContent=e.name,t.title=`${e.name} — ${e.emote} at ${e.rate}x`,t.addEventListener(`pointerdown`,e=>e.stopPropagation()),t.addEventListener(`click`,()=>c.playSignature(e)),t}))},_e=n=>{Ne(e.id,C,n),Re(t,e.id,C,E,Gn),me(),ge(),X?.hidden||je()},ve=t=>{if(!E.costume)return;let n=ke(e.id,C);if(n.length<2)return;let r=Me(e.id,C,Gn),i=r?n.indexOf(r):-1;_e(n[(i+t+n.length)%n.length])};$||window.addEventListener(`keydown`,e=>{if(!(e.metaKey||e.ctrlKey||e.altKey)&&!(X&&!X.hidden)){if(e.key===`]`||e.key===`ArrowRight`)ve(1);else if(e.key===`[`||e.key===`ArrowLeft`)ve(-1);else return;e.preventDefault()}});let ye=()=>{document.documentElement.dataset.kind=e.id,document.documentElement.dataset.skin=w().id;for(let e of fe)e.classList.toggle(`active`,e.dataset.skin===S.id)},Ce=(t,n=e)=>{if(!$)return t.radius;let r=t.radius/f(n.id)[2].radius;if(qn>0)return qn*r;let i=n.reach;return Math.min(o.w/(2*Math.max(i.left,i.right)),o.h/(2*Math.max(i.up,i.down)))*y.height/y.size*.98*r},we=1.18,Te=()=>{let t=c.radius*y.size/y.height,n=e.reach,r=Math.max(n.left,n.right)*t*1.22+18,i=n.up*t*we+112,a=n.down*t*we+12,s=Math.min(r,o.w*.5);return{left:s,right:o.w-s,top:Math.min(i,o.h*.5),bottom:Math.max(o.h-a,Math.min(i,o.h*.5))}},Ee=()=>{let t=c.radius*y.size/y.height,n=Kn?o.h*.07:0,r=Te();c.x=o.w*.5,c.y=b(o.h-e.reach.down*t-n,r.top,r.bottom)},E=te(e.id),De=()=>{zn.textContent=`${(E.costume?Me(e.id,C):null)===`ninja`?`Ninja`:e.name} ${E.roman}`},Ae=n=>{E=n,h(t,n),Re(t,e.id,C,n,Gn),me(),c.radius=Ce(n),c.glow=n.glow,$||m(n.stage,e.id),De();for(let e of oe)e.classList.toggle(`active`,Number(e.dataset.evo)===n.stage)},je=()=>{!Mn||$||Cn(Mn,wn,e.id,{pickKind:e=>D(e),pickEvo:(t,n)=>{t.id!==e.id&&D(t),Ae(n),je()},pickPalette:(t,n)=>{t.id!==e.id&&D(t),pe(n),je()}})},Pe=e=>{!X||$||(X.hidden=!e,document.documentElement.classList.toggle(`collection-open`,e),e&&je())},D=n=>{t.id!==n.id&&(t=Yn(n.id),o.setPuppet(t)),e=n,$||ae(n.id);for(let e of ce)e.classList.toggle(`active`,e.dataset.kind===n.id);pe($?se(Vn??n.defaultPalette):le(n.id,n.defaultPalette)),Ae($?ee(Hn,n.id):te(n.id)),ye(),De(),$&&Ee(),X?.hidden||je()};D(e),$&&Ee(),jn&&X&&Nn&&(jn.addEventListener(`pointerdown`,e=>e.stopPropagation()),Nn.addEventListener(`pointerdown`,e=>e.stopPropagation()),X.addEventListener(`pointerdown`,e=>e.stopPropagation()),jn.addEventListener(`click`,()=>Pe(!0)),Nn.addEventListener(`click`,()=>Pe(!1)),X.addEventListener(`click`,e=>{e.target===X&&Pe(!1)}),window.addEventListener(`keydown`,e=>{e.key===`Escape`&&!X.hidden&&Pe(!1)}));for(let e of ce)e.addEventListener(`pointerdown`,e=>e.stopPropagation()),e.addEventListener(`click`,()=>{let t=g.find(t=>t.id===e.dataset.kind);t&&D(t)});for(let t of fe)t.addEventListener(`pointerdown`,e=>e.stopPropagation()),t.addEventListener(`click`,()=>{if(e.id!==`sprout`)return;let n=he.find(e=>e.id===t.dataset.skin);n&&(S=n,$||Se(n.id),pe(C),ye(),De(),X?.hidden||je())});for(let t of oe)t.addEventListener(`pointerdown`,e=>e.stopPropagation()),t.addEventListener(`click`,()=>{Ae(ee(t.dataset.evo??`3`,e.id))});let O=async e=>{vn(e,$?e.floor:e.wash),_n(e.id);for(let t of v)t.classList.toggle(`active`,t.dataset.tank===e.id);let t=i(e);if(!(o.tank.id===e.id&&o.playground.src.endsWith(t.replace(/^\//,``)))){o.tank=e;try{let n=await $e(t);o.tank.id===e.id&&o.setTank(e,n)}catch(e){console.error(e)}}};for(let e of v)e.classList.toggle(`active`,e.dataset.tank===n.id);for(let e of ne)e.addEventListener(`pointerdown`,e=>e.stopPropagation()),e.addEventListener(`click`,()=>{let t=_.find(t=>t.id===e.dataset.palette);t&&pe(t)});for(let e of v)e.addEventListener(`pointerdown`,e=>e.stopPropagation()),e.addEventListener(`click`,()=>{let t=pn.find(t=>t.id===e.dataset.tank);t&&O(t)});let k=()=>{if($)return{w:o.w,h:o.h,...Te()};let e=c.radius*.7;return{w:o.w,h:o.h,left:e,right:o.w-e,top:110+e,bottom:o.h-372-e}},A=()=>{In.textContent=c.status,Rn.textContent=c.sleeping?`Wake`:`Sleep`;for(let e of p){let t=e.dataset.emote;e.classList.toggle(`active`,t===c.emote||t===`sleep`&&c.sleeping)}},j=e=>{let t=e===`sleep`&&c.sleeping;c.play(e),l(t?`wake`:e),Ln.classList.add(`hide`),A(),Xn(`emote`,{name:t?`wake`:e})},M=performance.now(),N=0,P=!1,Fe=()=>{};window.RiverSprite={state:()=>({x:c.x,y:c.y,emote:c.emote,blinking:c.blinking>0,coat:C.id}),play:e=>{rt.includes(e)&&j(e)},wake:()=>{c.wake(),l(`wake`),A()},goTo:(e,t)=>{let n=Te(),r=e>1?e:e*o.w,i=t>1?t:t*o.h;c.goTo(b(r,n.left,n.right),b(i,n.top,n.bottom))},layout:()=>({w:o.w,h:o.h,radius:c.radius,...Te()}),isSleeping:()=>c.sleeping,signature:t=>{let n=E.costume?Me(e.id,C,Gn):null,r=n?lt[n]:null,i=r?t===void 0?r.find(e=>e.act)??r[0]:r[t]:void 0;i&&(c.playSignature(i),A())},setReduceMotion:e=>{c.reduceMotion=!!e},step:e=>{P&&(c.update(e,k()),o.draw(c,e),u.tick(e),A())},setPaused:e=>{let t=!!e;t!==P&&(P=t,P?(N&&cancelAnimationFrame(N),N=0):(M=performance.now(),N=requestAnimationFrame(Fe)))}};for(let e of p)e.addEventListener(`pointerdown`,e=>e.stopPropagation()),e.addEventListener(`click`,()=>{s();let t=e.dataset.emote;j(t)});let Ie=null;if(!$){Pn.addEventListener(`pointerdown`,e=>{s(),Ie=e.pointerId,Pn.setPointerCapture(e.pointerId);let t=e.clientX,n=e.clientY;c.contains(t,n)?(c.hold(t,n),c.sleeping&&l(`wake`)):c.goTo(t,n),Ln.classList.add(`hide`),A()}),Pn.addEventListener(`pointermove`,e=>{Ie===e.pointerId&&c.dragging&&c.hold(e.clientX,e.clientY)});let e=e=>{Ie===e.pointerId&&(Ie=null,c.release(),A())};Pn.addEventListener(`pointerup`,e),Pn.addEventListener(`pointercancel`,e)}window.addEventListener(`resize`,()=>{if(o.resize(),$){c.radius=Ce(E),Ee(),Xn(`layout`,{w:o.w,h:o.h,...Te()});return}c.x=Math.min(c.x,o.w-40),c.y=Math.min(c.y,o.h-40)}),Fe=e=>{let t=Math.min(.05,(e-M)/1e3);M=e,c.update(t,k()),o.draw(c,t),u.tick(t),A(),N=requestAnimationFrame(Fe)},N=requestAnimationFrame(Fe),Xn(`ready`,{w:o.w,h:o.h,...Te()}),document.querySelector(`#boot`)?.classList.add(`hide`)}Zn().catch(e=>{let t=document.querySelector(`#boot`);t&&(t.textContent=`Could not wake the mascot`),In.textContent=`Could not load mascot`,console.error(e)});
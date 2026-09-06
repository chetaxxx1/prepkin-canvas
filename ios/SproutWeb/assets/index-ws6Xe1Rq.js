(function(){let e=document.createElement(`link`).relList;if(e&&e.supports&&e.supports(`modulepreload`))return;for(let e of document.querySelectorAll(`link[rel="modulepreload"]`))n(e);new MutationObserver(e=>{for(let t of e)if(t.type===`childList`)for(let e of t.addedNodes)e.tagName===`LINK`&&e.rel===`modulepreload`&&n(e)}).observe(document,{childList:!0,subtree:!0});function t(e){let t={};return e.integrity&&(t.integrity=e.integrity),e.referrerPolicy&&(t.referrerPolicy=e.referrerPolicy),t.credentials=e.crossOrigin===`use-credentials`?`include`:e.crossOrigin===`anonymous`?`omit`:`same-origin`,t}function n(e){if(e.ep)return;e.ep=!0;let n=t(e);fetch(e.href,n)}})();var e=`<svg id="sprout" class="mascot-svg" viewBox="0 0 982 849" fill="none" overflow="visible" aria-hidden="true">
  <defs>
    <filter
      id="sprout-outline"
      x="-320"
      y="-160"
      width="1620"
      height="1180"
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
        <g id="headband-tails" transform="translate(240 284)">
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

    <g id="tuft" transform="translate(512 90)" filter="url(#sprout-outline)">
      <path class="sprout-fill" fill="#58CC9F" d="M 1 8 C 16 -10 36 -40 56 -56 C 68 -64 84 -52 76 -36 C 68 -18 30 4 6 14 Z" />
      <path class="sprout-fill" fill="#58CC9F" d="M -2 10 C -16 -4 -28 -28 -22 -46 C -18 -56 -2 -54 4 -40 C 10 -22 8 2 0 12 Z" />
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
      x="-320"
      y="-160"
      width="1620"
      height="1180"
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
        <g id="headband-tails" transform="translate(240 284)">
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
      x="-320"
      y="-160"
      width="1620"
      height="1180"
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
        <g id="headband-tails" transform="translate(240 284)">
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
`,i=null,a=!1;function o(){return i||=new AudioContext,i}function s(){if(a)return;let e=o();e.state===`suspended`&&e.resume(),a=!0}function c(e,t,n,r=.045,i=0,a=0){let s=o(),c=s.currentTime+i,l=s.createOscillator(),u=s.createGain(),d=s.createBiquadFilter();d.type=`lowpass`,d.frequency.value=1400,l.type=n,l.frequency.setValueAtTime(e,c),a&&l.frequency.exponentialRampToValueAtTime(Math.max(40,e+a),c+t),u.gain.setValueAtTime(1e-4,c),u.gain.exponentialRampToValueAtTime(r,c+.03),u.gain.exponentialRampToValueAtTime(1e-4,c+t),l.connect(d),d.connect(u),u.connect(s.destination),l.start(c),l.stop(c+t+.02)}function l(e){if(a)try{e===`spin`?(c(420,.35,`sine`,.04,0,280),c(640,.28,`triangle`,.02,.08,180)):e===`happy`?(c(523,.16,`sine`,.05),c(784,.22,`sine`,.045,.12)):e===`wave`?(c(360,.2,`sine`,.03,0,80),c(300,.18,`triangle`,.02,.14,60)):e===`dazzle`?(c(880,.12,`triangle`,.04),c(1174,.14,`sine`,.035,.08),c(1568,.2,`sine`,.03,.16,-400)):e===`sleep`?(c(392,.28,`sine`,.03,0,-80),c(294,.4,`sine`,.025,.18,-60)):e===`wake`?(c(440,.12,`sine`,.03),c(660,.16,`sine`,.03,.08)):e===`love`?(c(523,.14,`sine`,.04),c(659,.18,`sine`,.035,.1),c(784,.22,`sine`,.03,.2)):e===`bounce`?(c(392,.1,`triangle`,.035,0,120),c(392,.1,`triangle`,.03,.28,120),c(392,.1,`triangle`,.03,.56,160)):e===`dance`?(c(330,.12,`triangle`,.03,0,40),c(392,.12,`triangle`,.028,.18,40),c(494,.16,`sine`,.03,.36,80)):e===`shy`?(c(349,.18,`sine`,.025,0,-40),c(294,.22,`sine`,.02,.16,30)):e===`surprise`?(c(880,.1,`square`,.025),c(1320,.16,`sine`,.03,.06,-200)):e===`stretch`?(c(262,.28,`sine`,.03,0,80),c(330,.3,`sine`,.025,.2,40)):e===`cheer`?(c(523,.1,`triangle`,.035),c(659,.12,`triangle`,.03,.16),c(784,.16,`sine`,.03,.3)):e===`pout`?(c(247,.28,`sine`,.03,0,-50),c(196,.32,`sine`,.022,.18,-30)):e===`curious`?(c(440,.12,`sine`,.028,0,60),c(494,.14,`sine`,.025,.2,-40),c(523,.16,`sine`,.025,.4,80)):e===`wiggle`&&(c(370,.08,`triangle`,.03,0,90),c(415,.08,`triangle`,.028,.1,-70),c(370,.1,`triangle`,.028,.2,110))}catch{}}var u=[{stage:1,roman:`I`,radius:72,belly:!0,blush:!0,markings:!1,extra:!1,wings:!1,glow:!1,badge:!1,costume:!1},{stage:2,roman:`II`,radius:86,belly:!0,blush:!0,markings:!1,extra:!1,wings:!0,glow:!1,badge:!1,costume:!1},{stage:3,roman:`III`,radius:100,belly:!0,blush:!0,markings:!1,extra:!1,wings:!0,glow:!1,badge:!1,costume:!0}],d=[{stage:1,roman:`I`,radius:44,belly:!1,blush:!1,markings:!1,extra:!1,wings:!1,glow:!1,badge:!1,costume:!1},{stage:2,roman:`II`,radius:58,belly:!0,blush:!1,markings:!0,extra:!1,wings:!0,glow:!1,badge:!1,costume:!1},{stage:3,roman:`III`,radius:72,belly:!0,blush:!0,markings:!0,extra:!0,wings:!0,glow:!1,badge:!1,costume:!1}];function f(e){return e===`sail`?d:u}var p=e=>e===`sprout`?`sprout-evo`:`sprout-evo-${e}`;function m(e,t=`sprout`){let n=Number(e),r=f(t);return r.find(e=>e.stage===n)??r[2]}function h(e=`sprout`){try{return m(localStorage.getItem(p(e)),e)}catch{return f(e)[2]}}function ee(e,t=`sprout`){try{localStorage.setItem(p(t),String(e))}catch{}}function g(e,t){let n=e.querySelector(`#belly`);n&&(n.style.display=t.belly&&!t.glow?``:`none`),n?.setAttribute(`rx`,t.badge?`182`:`176`),n?.setAttribute(`ry`,t.badge?`128`:`92`);let r=e.querySelector(`#badge`);t.badge?r?.removeAttribute(`display`):r?.setAttribute(`display`,`none`);for(let n of e.querySelectorAll(`.blush`))n.style.display=t.blush?``:`none`;for(let n of e.querySelectorAll(`.lobe, .marking`))n.style.display=t.markings?``:`none`;for(let n of e.querySelectorAll(`.evo-full`))n.style.display=t.extra?``:`none`;for(let n of e.querySelectorAll(`.evo-stub`))n.style.display=t.extra?`none`:``;for(let n of e.querySelectorAll(`.wing-full`))n.style.display=t.wings?``:`none`;for(let n of e.querySelectorAll(`.wing-stub`))n.style.display=t.wings?`none`:``;for(let n of e.querySelectorAll(`.lumen`))n.style.display=t.glow?``:`none`}var _=[{id:`sprout`,name:`Sprout`,defaultPalette:`mint`,reach:{left:640,right:680,up:470,down:380}},{id:`sail`,name:`Sail`,defaultPalette:`sky`,reach:{left:400,right:430,up:360,down:400}},{id:`orca`,name:`Orca`,defaultPalette:`sky`,reach:{left:640,right:680,up:470,down:380}},{id:`axolotl`,name:`Axolotl`,defaultPalette:`lilac`,reach:{left:640,right:680,up:500,down:380}}],v=`sprout-kind`;function te(e){return e===`keel`?_[1]:_.find(t=>t.id===e)??_[0]}function ne(){try{return te(localStorage.getItem(v))}catch{return _[0]}}function re(e){try{localStorage.setItem(v,e)}catch{}}var y=[{id:`mint`,name:`Mint`,body:`#58CC9F`,belly:`#B8EED4`,blush:`#F4B3C0`,rim:`#F4FFFC`,accent:`#2f9d86`,stroke:`rgba(47, 157, 134, 0.22)`,badge:`sapling`},{id:`sky`,name:`Sky`,body:`#6BAFE0`,belly:`#D4EBF8`,blush:`#F3B5A6`,rim:`#F5FBFE`,accent:`#3d7eab`,stroke:`rgba(61, 126, 171, 0.22)`,badge:`wave`},{id:`peach`,name:`Peach`,body:`#E9A07C`,belly:`#F8E0D2`,blush:`#E07A90`,rim:`#FFF8F4`,accent:`#c46d4e`,stroke:`rgba(196, 109, 78, 0.22)`,badge:`sun`},{id:`lilac`,name:`Lilac`,body:`#B08EE0`,belly:`#E6D9F6`,blush:`#EFA8B8`,rim:`#FBF7FE`,accent:`#7d5aa8`,stroke:`rgba(125, 90, 168, 0.22)`,badge:`moon`},{id:`butter`,name:`Butter`,body:`#E4C45C`,belly:`#F6ECC4`,blush:`#E99286`,rim:`#FFFBF0`,accent:`#b8942e`,stroke:`rgba(184, 148, 46, 0.22)`,badge:`bolt`},{id:`coral`,name:`Coral`,body:`#E07A72`,belly:`#F6D4CE`,blush:`#D46A9A`,rim:`#FFF6F4`,accent:`#c45c56`,stroke:`rgba(196, 92, 86, 0.22)`,badge:`flame`}];function b(e,t){for(let n of e.querySelectorAll(`#badge .badge`))n.id===`badge-${t}`?n.removeAttribute(`display`):n.setAttribute(`display`,`none`)}var ie=`sprout-palette`;function ae(e){return y.find(t=>t.id===e)??y[0]}function oe(e){return e===`sprout`?ie:`${ie}-${e}`}function se(e=`sprout`,t=`mint`){try{return ae(localStorage.getItem(oe(e))??t)}catch{return ae(t)}}function ce(e,t=`sprout`){try{localStorage.setItem(oe(t),e)}catch{}}function le(e,t,n=!0){for(let n of e.querySelectorAll(`.sprout-fill`))n.setAttribute(`fill`,t.body);e.querySelector(`#belly`)?.setAttribute(`fill`,t.belly);for(let n of e.querySelectorAll(`.blush`))n.setAttribute(`fill`,t.blush);for(let n of e.querySelectorAll(`.gill`))n.setAttribute(`fill`,t.blush);for(let n of e.querySelectorAll(`.marking`))n.setAttribute(`fill`,t.body);if(e.querySelector(`feFlood`)?.setAttribute(`flood-color`,t.rim),b(e,t.badge),!n)return;let r=document.documentElement;r.style.setProperty(`--mint`,t.accent),r.style.setProperty(`--stroke`,t.stroke)}var x={width:982,height:849,originX:491,originY:478,size:2.52,body:`#58CC9F`,face:`#0F181F`,eyeL:{x:352,y:371,r:52},eyeR:{x:671,y:371,r:52},mouth:{x:512,y:392,rx:44,ry:20},armL:{x:318,y:452},armR:{x:706,y:452},sprout:{x:512,y:90}};function ue(e,t){return e*x.size/x.height*t}var S=(e,t,n)=>Math.min(n,Math.max(t,e)),C=(e,t,n)=>e+(t-e)*n,w=(e,t,n,r)=>C(e,t,1-Math.exp(-n*r)),T=(e,t)=>e+Math.random()*(t-e),E=e=>1-(1-e)**3,D=e=>e<.5?4*e*e*e:1-(-2*e+2)**3/2,O=e=>{let t=e-1;return 1+2.70158*t*t*t+1.70158*t*t},k=e=>S(e,0,1),A=[{id:`classic`,name:`Classic`},{id:`ninja`,name:`Ninja`}],j=`#1C1F24`,M=`#3A3F46`,N={aura:`#D8FFEF`,halo:`#EFFFF6`,core:`#F4FFF9`,tuft:`#EFFFF6`},P=`sprout-skin`;function de(e){return A.find(t=>t.id===e)??A[0]}function fe(){try{return de(localStorage.getItem(P))}catch{return A[0]}}function pe(e){try{localStorage.setItem(P,e)}catch{}}function F(e,t){e.querySelector(`#aura-flood`)?.setAttribute(`flood-color`,t.aura),e.querySelector(`#lumen-halo`)?.setAttribute(`fill`,t.halo),e.querySelector(`#lumen-core`)?.setAttribute(`fill`,t.core);for(let n of e.querySelectorAll(`#lumen-tuft path`))n.setAttribute(`fill`,t.tuft);e.querySelector(`#lumen-tuft circle`)?.setAttribute(`fill`,t.tuft)}function I(e,t){e.querySelector(`#lamp-pale`)?.setAttribute(`stop-color`,t.belly);for(let n of[`#lamp-chroma`,`#lamp-edge`])e.querySelector(n)?.setAttribute(`stop-color`,t.body)}function L(e,t,n,r){let i=t.id===`ninja`,a=e.querySelector(`#ninja`);a&&(i?a.removeAttribute(`display`):a.setAttribute(`display`,`none`));for(let t of e.querySelectorAll(`.ninja-guard`))i&&r.wings?t.removeAttribute(`display`):t.setAttribute(`display`,`none`);let o=!r.glow||i?`none`:``;for(let t of[`#lumen-sheen`,`#lumen-hot`,`#lumen-core`,`#lumen-halo`])e.querySelector(t)?.style.setProperty(`display`,o);let s=e.querySelector(`#ninja-lamp`);if(i&&r.glow?s?.removeAttribute(`display`):s?.setAttribute(`display`,`none`),!i){for(let t of e.querySelectorAll(`.suit`))t.setAttribute(`fill`,n.body);e.querySelector(`#belly`)?.setAttribute(`fill`,n.belly),b(e,n.badge),F(e,N);return}for(let t of e.querySelectorAll(`.suit`))t.setAttribute(`fill`,j);b(e,`shuriken`),e.querySelector(`#eye-strip`)?.setAttribute(`fill`,n.body),e.querySelector(`#belly`)?.setAttribute(`fill`,r.glow?j:M),I(e,n),F(e,{aura:n.body,halo:N.halo,core:N.core,tuft:n.belly})}var me={scholar:{armL:`<g clip-path="url(#fin-l-clip)"><g transform="rotate(14.8969) translate(-318.000 -452.000)"><g transform="matrix(5.29290 -0.02185 0.02244 5.15547 -360.82989 -659.51934)"><image href="costumes/scholar-l.png" x="60.67" y="201.00" width="42.67" height="72.33" /></g></g></g>`,armR:`<g clip-path="url(#fin-r-clip)"><g transform="rotate(-11.1631) translate(-706.000 -452.000)"><g transform="matrix(5.29290 -0.02185 0.02244 5.15547 -360.82989 -659.51934)"><image href="costumes/scholar-r.png" x="224.67" y="201.00" width="41.00" height="67.00" /></g></g></g>`,face:`<g transform="matrix(5.29290 -0.02185 0.02244 5.15547 -360.82989 -659.51934)"><image href="costumes/scholar-top.png" x="76.00" y="140.00" width="172.33" height="163.00" /></g>`},hoodie:{armL:`<g clip-path="url(#fin-l-clip)"><g transform="rotate(5.1462) translate(-318.000 -452.000)"><g transform="matrix(5.12896 0.19200 -0.18531 5.31417 -287.74033 -754.10401)"><image href="costumes/hoodie-l.png" x="39.67" y="223.67" width="57.67" height="33.00" /></g></g></g>`,armR:`<g clip-path="url(#fin-r-clip)"><g transform="rotate(-8.4509) translate(-706.000 -452.000)"><g transform="matrix(5.12896 0.19200 -0.18531 5.31417 -287.74033 -754.10401)"><image href="costumes/hoodie-r.png" x="231.67" y="223.67" width="57.00" height="29.67" /></g></g></g>`,face:`<g transform="matrix(5.12896 0.19200 -0.18531 5.31417 -287.74033 -754.10401)"><image href="costumes/hoodie-top.png" x="45.00" y="70.33" width="241.33" height="228.00" /></g>`},baker:{armL:`<g clip-path="url(#fin-l-clip)"><g transform="rotate(19.0965) translate(-318.000 -452.000)"><g transform="matrix(5.29155 -0.16522 0.16971 5.15162 -392.49195 -614.01515)"><image href="costumes/baker-l.png" x="35.33" y="194.33" width="69.00" height="84.67" /></g></g></g>`,armR:`<g clip-path="url(#fin-r-clip)"><g transform="rotate(-18.7555) translate(-706.000 -452.000)"><g transform="matrix(5.29155 -0.16522 0.16971 5.15162 -392.49195 -614.01515)"><image href="costumes/baker-r.png" x="223.67" y="194.33" width="69.67" height="82.00" /></g></g></g>`,face:`<g transform="matrix(5.29155 -0.16522 0.16971 5.15162 -392.49195 -614.01515)"><image href="costumes/baker-top.png" x="83.00" y="120.33" width="155.33" height="199.33" /></g>`},astronaut:{armL:`<g clip-path="url(#fin-l-clip)"><g transform="rotate(15.7623) translate(-318.000 -452.000)"><g transform="matrix(5.24572 -0.19661 0.19858 5.19372 -392.03812 -634.07226)"><image href="costumes/astronaut-l.png" x="54.67" y="200.67" width="48.00" height="50.00" /></g></g></g>`,armR:`<g clip-path="url(#fin-r-clip)"><g transform="rotate(-17.6801) translate(-706.000 -452.000)"><g transform="matrix(5.24572 -0.19661 0.19858 5.19372 -392.03812 -634.07226)"><image href="costumes/astronaut-r.png" x="225.33" y="200.67" width="45.33" height="58.33" /></g></g></g>`,face:`<g transform="matrix(5.24572 -0.19661 0.19858 5.19372 -392.03812 -634.07226)"><image href="costumes/astronaut-top.png" x="93.33" y="182.00" width="141.67" height="111.00" /></g>`},racer:{armL:`<g clip-path="url(#fin-l-clip)"><g transform="rotate(16.5852) translate(-318.000 -452.000)"><g transform="matrix(5.30543 -0.04655 0.04802 5.14331 -368.42436 -645.07553)"><image href="costumes/racer-l.png" x="55.33" y="199.00" width="48.33" height="63.67" /></g></g></g>`,armR:`<g clip-path="url(#fin-r-clip)"><g transform="rotate(-12.8103) translate(-706.000 -452.000)"><g transform="matrix(5.30543 -0.04655 0.04802 5.14331 -368.42436 -645.07553)"><image href="costumes/racer-r.png" x="224.33" y="199.00" width="49.33" height="62.33" /></g></g></g>`,face:`<g transform="matrix(5.30543 -0.04655 0.04802 5.14331 -368.42436 -645.07553)"><image href="costumes/racer-top.png" x="95.33" y="113.33" width="137.00" height="168.00" /></g>`},biker:{armL:`<g clip-path="url(#fin-l-clip)"><g transform="rotate(6.2629) translate(-318.000 -452.000)"><g transform="matrix(5.12737 0.20156 -0.19443 5.31516 -285.72787 -747.52284)"><image href="costumes/biker-l.png" x="46.00" y="209.00" width="54.33" height="53.33" /></g></g></g>`,armR:`<g clip-path="url(#fin-r-clip)"><g transform="rotate(-9.9105) translate(-706.000 -452.000)"><g transform="matrix(5.12737 0.20156 -0.19443 5.31516 -285.72787 -747.52284)"><image href="costumes/biker-r.png" x="228.00" y="209.00" width="53.33" height="51.00" /></g></g></g>`,face:`<g transform="matrix(5.12737 0.20156 -0.19443 5.31516 -285.72787 -747.52284)"><image href="costumes/biker-top.png" x="80.00" y="170.67" width="176.00" height="114.00" /></g>`},pajamas:{armL:`<g clip-path="url(#fin-l-clip)"><g transform="rotate(4.9452) translate(-318.000 -452.000)"><g transform="matrix(5.12991 0.18943 -0.18289 5.31334 -288.38086 -755.16722)"><image href="costumes/pajamas-l.png" x="35.33" y="210.67" width="75.67" height="102.00" /></g></g></g>`,armR:`<g clip-path="url(#fin-r-clip)"><g transform="rotate(-8.1455) translate(-706.000 -452.000)"><g transform="matrix(5.12991 0.18943 -0.18289 5.31334 -288.38086 -755.16722)"><image href="costumes/pajamas-r.png" x="219.00" y="210.67" width="73.33" height="98.00" /></g></g></g>`,face:`<g transform="matrix(5.12991 0.18943 -0.18289 5.31334 -288.38086 -755.16722)"><image href="costumes/pajamas-top.png" x="35.00" y="151.33" width="257.67" height="168.33" /></g>`}},he={astronaut:{armL:`<image href="costumes/astronaut-cuff-l.png?v=16" x="-550" y="-200" width="1000" height="1000" />`,armR:`<image href="costumes/astronaut-cuff-r.png?v=16" x="-450" y="-200" width="1000" height="1000" />`,body:`<image href="costumes/astronaut-body.png?v=16" x="-193" y="13" width="1411" height="854" />`},scholar:{armL:`<image href="costumes/scholar-cuff-l.png?v=7" x="-550" y="-200" width="1000" height="1000" />`,armR:`<image href="costumes/scholar-cuff-r.png?v=7" x="-450" y="-200" width="1000" height="1000" />`,body:`<image href="costumes/scholar-body.png?v=7" x="-193" y="13" width="1411" height="854" />`},hoodie:{armL:`<image href="costumes/hoodie-cuff-l.png?v=3" x="-550" y="-200" width="1000" height="1000" />`,armR:`<image href="costumes/hoodie-cuff-r.png?v=3" x="-450" y="-200" width="1000" height="1000" />`,body:`<image href="costumes/hoodie-body.png?v=3" x="-193" y="13" width="1411" height="854" />`}},R={mint:`scholar`,coral:`ninja`,sky:`hoodie`,peach:`baker`,lilac:`astronaut`,butter:`racer`};function ge(e,t){return e===`sprout`?R[t.id]:e===`orca`?`biker`:e===`axolotl`?`pajamas`:null}var _e=new Set([`hoodie`].filter(e=>!(e in me))),z=`clip-path="url(#sprout-body-clip)"`,B=`clip-path="url(#fin-l-clip)"`,V=`clip-path="url(#fin-r-clip)"`,H=`filter="url(#sprout-outline)"`,U=(e,t,n)=>`<rect x="${Math.min(e,t)}" y="-170" width="${Math.abs(t-e)}" height="340" fill="${n}" />`,W=(e,t,n)=>`<rect x="${-Math.max(e,t)}" y="-170" width="${Math.abs(t-e)}" height="340" fill="${n}" />`,G=(e,t,n,r,i=``)=>{let a=[];for(let r=0;r<10;r++){let i=-Math.PI/2+r*Math.PI/5,o=r%2?n*.45:n;a.push(`${(e+o*Math.cos(i)).toFixed(1)},${(t+o*Math.sin(i)).toFixed(1)}`)}return`<polygon points="${a.join(` `)}" fill="${r}"${i?` class="${i}"`:``} />`},ve={scholar:{body:`
      <g ${z}>
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
      </g>`,armL:`<g ${B}>${U(-236,60,`#2F6B4F`)}<rect x="-244" y="-170" width="14" height="340" fill="#4C9A72" /></g>`,armR:`<g ${V}>${W(-236,60,`#2F6B4F`)}<rect x="230" y="-170" width="14" height="340" fill="#4C9A72" /></g>`,faceOverFit:`
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
      <circle cx="330" cy="344" r="12" fill="#FFFFFF" opacity="0.5" /><circle cx="649" cy="344" r="12" fill="#FFFFFF" opacity="0.5" />`},ninja:{},hoodie:{body:`
      <g ${z}>
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
      <g ${H}>
        <path d="M 178 404 C 168 168 318 46 512 44 C 706 46 856 168 846 404" fill="none" stroke="#2B2F33" stroke-width="34" stroke-linecap="round" />
        <path d="M 178 404 C 168 168 318 46 512 44 C 706 46 856 168 846 404" fill="none" stroke="#5B6672" stroke-width="12" stroke-linecap="round" />
        <rect x="118" y="368" width="120" height="152" rx="54" fill="#2B2F33" />
        <rect x="786" y="368" width="120" height="152" rx="54" fill="#2B2F33" />
        <rect x="146" y="394" width="64" height="100" rx="30" fill="#5B6672" />
        <rect x="814" y="394" width="64" height="100" rx="30" fill="#5B6672" />
      </g>
    `,head:`
      <!-- Hood up: the head silhouette pushed out, with the face cut through it. -->
      <g ${H}>
        <path fill="#B8BCC4" fill-rule="evenodd"
              d="M 168 540 C 172 300 318 62 512 58 C 706 62 852 300 856 540 C 780 516 640 508 512 508 C 384 508 244 516 168 540 Z
                 M 512 168 C 672 168 804 268 804 392 C 804 516 672 616 512 616 C 352 616 220 516 220 392 C 220 268 352 168 512 168 Z" />
        <path d="M 220 392 C 220 516 352 616 512 616 C 672 616 804 516 804 392" fill="none" stroke="#A6ABB4" stroke-width="14" />
      </g>
      <!-- Headphones over the hood. -->
      <g ${H}>
        <path d="M 250 430 C 236 200 336 78 512 72 C 688 78 788 200 774 430" fill="none" stroke="#2B2F33" stroke-width="32" stroke-linecap="round" />
        <path d="M 250 430 C 236 200 336 78 512 72 C 688 78 788 200 774 430" fill="none" stroke="#5B6672" stroke-width="12" stroke-linecap="round" />
        <rect x="192" y="386" width="92" height="140" rx="40" fill="#2B2F33" /><rect x="740" y="386" width="92" height="140" rx="40" fill="#2B2F33" />
        <rect x="214" y="410" width="48" height="92" rx="24" fill="#5B6672" /><rect x="762" y="410" width="48" height="92" rx="24" fill="#5B6672" />
      </g>`,armL:`<g ${B}>${U(-520,100,`#B8BCC4`)}<rect x="-470" y="-170" width="30" height="340" fill="#A6ABB4" /></g>`,armR:`<g ${V}>${W(-520,100,`#B8BCC4`)}<rect x="440" y="-170" width="30" height="340" fill="#A6ABB4" /></g>`},baker:{body:`
      <g ${z}>
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
      <g ${H} transform="translate(838 578)">
        <path d="M 0 0 C 30 -40 66 -44 70 -14 C 50 -6 24 2 0 0 Z" fill="#E4C9A8" />
        <path d="M 0 0 C 30 36 66 42 70 14 C 50 6 24 -2 0 0 Z" fill="#E4C9A8" />
        <circle r="10" fill="#D9BE98" />
      </g>`,head:`
      <g ${z} fill="none" stroke-linecap="butt">
        <path d="M 108 289 C 288 231, 736 231, 916 289" stroke="#D9534F" stroke-width="62" />
        <g stroke="#FFFFFF" stroke-width="6" opacity="0.55">
          <path d="M 108 276 C 288 218, 736 218, 916 276" /><path d="M 108 300 C 288 242, 736 242, 916 300" />
          <path d="M 260 234 V 306" /><path d="M 340 224 V 296" /><path d="M 420 218 V 290" /><path d="M 512 216 V 288" /><path d="M 604 218 V 290" /><path d="M 684 224 V 296" /><path d="M 764 234 V 306" />
        </g>
      </g>
      <!-- Knot off the right side, like the Ninja's tails but tied. -->
      <g transform="translate(790 268)" ${H}>
        <path d="M -4 2 C 20 -18 56 -40 100 -34 C 118 -30 122 -10 100 -2 C 66 8 30 12 -6 12 Z" fill="#D9534F" />
        <path d="M -6 10 C 16 30 50 60 82 92 C 100 108 84 128 60 112 C 34 92 8 48 -10 16 Z" fill="#D9534F" />
        <ellipse cx="-4" cy="6" rx="16" ry="13" fill="#C43B3B" />
      </g>`,armL:`<g ${B}>${U(-150,60,`#F3E6D3`)}<rect x="-158" y="-170" width="16" height="340" fill="#E4C9A8" /></g>`,armR:`<g ${V}>${W(-150,60,`#F3E6D3`)}<rect x="142" y="-170" width="16" height="340" fill="#E4C9A8" /></g>`},astronaut:{body:`
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
      <g class="el-suit" ${z}>
        <rect x="0" y="440" width="982" height="440" fill="url(#astro-suit)" />
        <rect x="0" y="500" width="982" height="100" fill="url(#astro-shade)" />
      </g>
      <g class="el-panel" ${z}>
        <ellipse cx="512" cy="704" rx="200" ry="114" fill="url(#astro-panel)" />
        <path d="M 512 520 V 850" fill="none" stroke="#C4CAD2" stroke-width="9" />
        <path d="M 512 590 V 818" fill="none" stroke="#A8B0BA" stroke-width="7" />
      </g>
      <g class="el-patch" ${z}>
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
      </g>`,armL:`<g class="el-suit" ${B}>${U(-520,100,`#E6EAEF`)}<rect x="-520" y="-170" width="620" height="340" fill="url(#astro-shade)" opacity="0" /></g><g class="el-panel" ${B}><rect x="-474" y="-170" width="44" height="340" fill="url(#astro-cuff)" /><rect x="-436" y="-170" width="7" height="340" fill="#8E969F" /></g>`,armR:`<g class="el-suit" ${V}>${W(-520,100,`#E6EAEF`)}</g><g class="el-panel" ${V}><rect x="430" y="-170" width="44" height="340" fill="url(#astro-cuff)" /><rect x="429" y="-170" width="7" height="340" fill="#8E969F" /></g>`},racer:{body:`
      <g ${z}>
        <rect x="0" y="480" width="982" height="400" fill="#23305A" />
        <!-- Collar, sponsor stripes, and a blocky 7. -->
        <path d="M 420 480 L 512 560 L 604 480 Z" fill="#F2F4F6" />
        <rect x="300" y="520" width="118" height="22" rx="6" fill="#E8433C" /><rect x="300" y="550" width="80" height="18" rx="6" fill="#F2F4F6" />
        <rect x="664" y="520" width="118" height="22" rx="6" fill="#F2F4F6" /><rect x="702" y="550" width="80" height="18" rx="6" fill="#E8433C" />
        <polygon points="446,606 578,606 578,640 528,776 480,776 528,640 446,640" fill="#F2F4F6" />
        <path d="M 0 800 H 982" stroke="#E8433C" stroke-width="14" />
      </g>`,head:`
      <g ${z}><path d="M 108 276 C 288 218, 736 218, 916 276" fill="none" stroke="#2B2F33" stroke-width="30" /></g>
      <g ${H}>
        <rect x="360" y="226" width="130" height="74" rx="32" fill="#BFE3F4" stroke="#2B2F33" stroke-width="11" />
        <rect x="492" y="226" width="130" height="74" rx="32" fill="#BFE3F4" stroke="#2B2F33" stroke-width="11" />
        <rect x="484" y="250" width="16" height="26" rx="6" fill="#2B2F33" />
        <path d="M 386 248 C 400 236 424 234 440 240" fill="none" stroke="#FFFFFF" stroke-width="8" stroke-linecap="round" opacity="0.8" />
        <path d="M 518 248 C 532 236 556 234 572 240" fill="none" stroke="#FFFFFF" stroke-width="8" stroke-linecap="round" opacity="0.8" />
      </g>`,armL:`<g ${B}>${U(-520,100,`#23305A`)}<rect x="-300" y="-170" width="22" height="340" fill="#F2F4F6" /><rect x="-270" y="-170" width="22" height="340" fill="#E8433C" /></g>`,armR:`<g ${V}>${W(-520,100,`#23305A`)}<rect x="278" y="-170" width="22" height="340" fill="#F2F4F6" /><rect x="248" y="-170" width="22" height="340" fill="#E8433C" /></g>`},biker:{body:`
      <g ${z}>
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
      <path d="M 570 322 C 584 306 610 300 634 304" fill="none" stroke="#FFFFFF" stroke-width="8" stroke-linecap="round" opacity="0.35" />`,armL:`<g ${B}>${U(-520,100,`#1B1D22`)}<rect x="-456" y="-170" width="8" height="340" fill="#C9CED6" /></g>`,armR:`<g ${V}>${W(-520,100,`#1B1D22`)}<rect x="448" y="-170" width="8" height="340" fill="#C9CED6" /></g>`},pajamas:{body:`
      <g ${z}>
        <rect x="0" y="446" width="982" height="440" fill="#F5EBD9" />
        <path d="M 270 474 C 340 420 684 420 754 474 C 690 506 334 506 270 474 Z" fill="#EADCC6" />
        <g fill="#EADCC6"><circle cx="512" cy="566" r="11" /><circle cx="512" cy="632" r="11" /><circle cx="512" cy="698" r="11" /></g>
        ${G(330,560,16,`#B08EE0`,`costume-blush`)}${G(420,700,14,`#B08EE0`,`costume-blush`)}${G(300,700,13,`#B08EE0`,`costume-blush`)}
        ${G(610,590,15,`#B08EE0`,`costume-blush`)}${G(690,690,14,`#B08EE0`,`costume-blush`)}${G(560,780,13,`#B08EE0`,`costume-blush`)}
        ${G(380,800,12,`#B08EE0`,`costume-blush`)}${G(700,560,12,`#B08EE0`,`costume-blush`)}
      </g>`,armL:`<g ${B}>${U(-520,100,`#F5EBD9`)}<rect x="-470" y="-170" width="44" height="340" fill="#EADCC6" /></g>`,armR:`<g ${V}>${W(-520,100,`#F5EBD9`)}<rect x="426" y="-170" width="44" height="340" fill="#EADCC6" /></g>
      <!-- Cocoa, held at the fin tip so it rides the wave. -->
      <g transform="translate(404 40)" ${H}>
        <rect x="-30" y="-24" width="60" height="58" rx="10" fill="#FFFFFF" />
        <path d="M 30 -8 C 54 -8 54 22 30 22" fill="none" stroke="#FFFFFF" stroke-width="10" />
        <ellipse cx="0" cy="-22" rx="26" ry="8" fill="#6B4A2E" />
        <rect x="-30" y="8" width="60" height="10" fill="#EADCC6" />
      </g>`}},ye=(e,t)=>t?`<g class="costume" data-costume="${e}" display="none">${t}</g>`:``;function be(e,t){let n=t===`sprout`?[`scholar`,`hoodie`,`baker`,`astronaut`,`racer`]:t===`orca`?[`biker`]:t===`axolotl`?[`pajamas`]:[],r=e=>{let t=he[e];return t?{...t,head:ve[e].headOverFit??``,face:ve[e].faceOverFit??``}:me[e]??ve[e]},i=e=>n.map(t=>ye(t,r(t)[e])).join(``);return e.replace(`<g class="costume-arm-l"></g>`,`<g class="costume-arm-l">${i(`armL`)}</g>`).replace(`<g class="costume-arm-r"></g>`,`<g class="costume-arm-r">${i(`armR`)}</g>`).replace(`<g id="costume-body"></g>`,`<g id="costume-body" class="no-flip">${i(`body`)}</g>`).replace(`<g id="costume-head"></g>`,`<g id="costume-head" class="no-flip">${i(`head`)}</g>`).replace(`<g id="costume-face"></g>`,`<g id="costume-face" class="no-flip">${i(`face`)}</g>`)}function xe(e,t,n,r){let i=r.costume?ge(t,n):null;for(let t of e.querySelectorAll(`.costume`))t.dataset.costume===i?t.removeAttribute(`display`):t.setAttribute(`display`,`none`);for(let t of e.querySelectorAll(`.costume-blush`))t.setAttribute(`fill`,n.blush);let a=e.querySelector(`#tuft`);a&&(a.style.display=i&&_e.has(i)?`none`:``),L(e,i===`ninja`?A[1]:A[0],n,r)}function Se(e,t,n=!1){let r=n?Math.random()*Math.PI*2:Math.PI/2+(Math.random()-.5)*.8,i=n?40+Math.random()*80:8+Math.random()*18;return{kind:`drop`,x:e+(Math.random()-.5)*16,y:t+(Math.random()-.5)*8,vx:Math.cos(r)*i,vy:Math.sin(r)*i,life:0,maxLife:.45+Math.random()*.5,size:3+Math.random()*4,rot:0,spin:0,alpha:.7}}function Ce(e,t){let n=Math.random()*Math.PI*2,r=50+Math.random()*150;return{kind:`spark`,x:e,y:t,vx:Math.cos(n)*r,vy:Math.sin(n)*r,life:0,maxLife:.35+Math.random()*.4,size:1.5+Math.random()*2.4,rot:n,spin:(Math.random()-.5)*8,alpha:1}}function we(e,t){return{kind:`zzz`,x:e+18+Math.random()*10,y:t-28,vx:8+Math.random()*10,vy:-22-Math.random()*12,life:0,maxLife:1.6,size:14+Math.random()*6,rot:(Math.random()-.5)*.4,spin:.4,alpha:.9}}function K(e,t,n=20){return{kind:`ring`,x:e,y:t,vx:0,vy:0,life:0,maxLife:.7,size:n,rot:0,spin:0,alpha:.7}}function Te(e,t){return{kind:`heart`,x:e+(Math.random()-.5)*48,y:t-24-Math.random()*22,vx:(Math.random()-.5)*36,vy:-56-Math.random()*36,life:0,maxLife:1.15+Math.random()*.5,size:11+Math.random()*7,rot:(Math.random()-.5)*.5,spin:(Math.random()-.5)*1.4,alpha:1}}function q(e,t,n={}){let r=n.burst??!1,i=n.size??(r?3+Math.random()*7:5+Math.random()*11);return{kind:`bubble`,x:e+(Math.random()-.5)*(r?28:10),y:t+(Math.random()-.5)*(r?18:8),vx:(Math.random()-.5)*(r?56:18),vy:n.rise??-28-Math.random()*(r?70:42),life:0,maxLife:r?.7+Math.random()*.7:2.2+Math.random()*2.6,size:i,rot:Math.random()*Math.PI*2,spin:1.4+Math.random()*2.2,alpha:.42+Math.random()*.28}}function Ee(e,t,n){let r=Math.random()*Math.PI*2,i=1.12+Math.random()*.33;return{kind:`mote`,x:e+Math.cos(r)*n*2.05*i,y:t+Math.sin(r)*n*1.3*i,vx:(Math.random()-.5)*6,vy:-6-Math.random()*8,life:0,maxLife:2.6+Math.random()*1.6,size:2+Math.random()*2,rot:Math.random()*Math.PI*2,spin:.8+Math.random()*.8,alpha:0}}function De(e,t){for(let n=e.length-1;n>=0;n--){let r=e[n];r.life+=t;let i=r.life/r.maxLife;r.x+=r.vx*t,r.y+=r.vy*t,r.rot+=r.spin*t,r.kind===`drop`?(r.vy+=70*t,r.alpha=(1-i)*.65):r.kind===`spark`?(r.vx*=1-1.8*t,r.vy*=1-1.8*t,r.alpha=1-i):r.kind===`zzz`?r.alpha=i<.15?i/.15:1-(i-.15)/.85:r.kind===`heart`?(r.vy+=18*t,r.alpha=i<.12?i/.12:1-(i-.12)/.88):r.kind===`bubble`?(r.x+=Math.sin(r.rot)*18*t,r.vx*=1-.55*t,r.vy*=1-.12*t,r.vy-=8*t,r.size+=3.4*t,r.alpha=(i<.08?i/.08:i>.78?1-(i-.78)/.22:1)*.38):r.kind===`mote`?(r.x+=Math.sin(r.rot)*10*t,r.vy-=2*t,r.alpha=(i<.25?i/.25:i>.7?1-(i-.7)/.3:1)*.9):(r.size+=140*t,r.alpha=(1-i)*.5),r.life>=r.maxLife&&e.splice(n,1)}}function Oe(e,t){for(let n of t){if(e.save(),e.translate(n.x,n.y),e.rotate(n.kind===`bubble`?0:n.rot),e.globalAlpha=Math.max(0,n.alpha),n.kind===`drop`)e.fillStyle=`#9BE8D0`,e.beginPath(),e.ellipse(0,0,n.size*.85,n.size*.65,0,0,Math.PI*2),e.fill();else if(n.kind===`spark`)e.strokeStyle=`#F6C84C`,e.lineWidth=1.6,e.lineCap=`round`,e.beginPath(),e.moveTo(-n.size*2.2,0),e.lineTo(n.size*2.2,0),e.stroke();else if(n.kind===`zzz`)e.fillStyle=`rgba(70, 120, 108, 0.8)`,e.font=`600 ${n.size}px ui-rounded, -apple-system, sans-serif`,e.fillText(`z`,0,0);else if(n.kind===`heart`){e.fillStyle=`#F4A0B4`,e.beginPath();let t=n.size;e.moveTo(0,t*.4),e.bezierCurveTo(-t,-t*.15,-t*.55,-t,0,-t*.4),e.bezierCurveTo(t*.55,-t,t,-t*.15,0,t*.4),e.fill()}else if(n.kind===`bubble`){let t=n.size;e.fillStyle=`rgba(210, 242, 255, 0.16)`,e.strokeStyle=`rgba(255, 255, 255, 0.55)`,e.lineWidth=Math.max(1,t*.12),e.beginPath(),e.arc(0,0,t,0,Math.PI*2),e.fill(),e.stroke(),e.strokeStyle=`rgba(255, 255, 255, 0.95)`,e.lineWidth=Math.max(1.1,t*.14),e.lineCap=`round`,e.beginPath(),e.arc(-t*.22,-t*.28,t*.42,-Math.PI*.85,-Math.PI*.15),e.stroke(),e.fillStyle=`rgba(255, 255, 255, 0.55)`,e.beginPath(),e.arc(-t*.28,-t*.32,t*.16,0,Math.PI*2),e.fill()}else n.kind===`mote`?(e.fillStyle=`rgba(214, 255, 238, 0.22)`,e.beginPath(),e.arc(0,0,n.size*3.6,0,Math.PI*2),e.fill(),e.fillStyle=`rgba(224, 255, 242, 0.45)`,e.beginPath(),e.arc(0,0,n.size*2,0,Math.PI*2),e.fill(),e.fillStyle=`#F2FFF8`,e.beginPath(),e.arc(0,0,n.size,0,Math.PI*2),e.fill()):(e.strokeStyle=`rgba(80, 190, 160, ${n.alpha})`,e.lineWidth=2.5,e.beginPath(),e.arc(0,0,n.size,0,Math.PI*2),e.stroke());e.restore()}}var ke={sprout:{l:{x:318,y:452},r:{x:706,y:452},tuft:{x:512,y:90},tail:null,restL:-12,restR:12},sail:{l:{x:300,y:428},r:{x:724,y:428},tuft:{x:512,y:268},tail:{x:512,y:586},restL:0,restR:0}},Ae=class{root;armL;armR;tuft;tail;pivots;eyeDots;eyeShine;eyeHappy;eyeSleep;mouths;lumen;lumenTuft;lumenHalo;lumenCore;lumenHot;noFlip;constructor(e){this.root=e,this.armL=je(e,`#arm-l`),this.armR=je(e,`#arm-r`),this.tuft=je(e,`#tuft`),this.tail=e.querySelector(`#tail`),this.lumen=[...e.querySelectorAll(`.lumen`)],this.lumenTuft=e.querySelector(`#lumen-tuft`),this.lumenHalo=e.querySelector(`#lumen-halo`),this.lumenCore=e.querySelector(`#lumen-core`),this.lumenHot=e.querySelector(`#lumen-hot`),this.pivots=ke[e.id]??ke.sprout;let t=[...e.querySelectorAll(`.no-flip`)];this.noFlip=t.filter(e=>!t.some(t=>t!==e&&t.contains(e))).map(e=>({node:e,base:e.getAttribute(`transform`)??``})),this.eyeDots=[...e.querySelectorAll(`.eye-dot`)],this.eyeShine=[...e.querySelectorAll(`.eye-shine`)],this.eyeHappy=[...e.querySelectorAll(`.eye-happy`)],this.eyeSleep=[...e.querySelectorAll(`.eye-sleep`)],this.mouths={smile:[...e.querySelectorAll(`.mouth.smile`)],open:[...e.querySelectorAll(`.mouth.open`)],o:[...e.querySelectorAll(`.mouth.o`)],flat:[...e.querySelectorAll(`.mouth.flat`)]}}apply(e,t){let n=ue(t,e.scale),r=e.facing*n*e.squashX,i=n*e.squashY,a=e.rot*180/Math.PI;this.root.style.transform=`translate(${e.x}px, ${e.y}px) rotate(${a}deg) scale(${r}, ${i}) translate(${-x.originX}px, ${-x.originY}px)`,this.root.style.filter=Math.abs(e.brightness-1)>.005?`brightness(${e.brightness})`:``;let o=e.facing<0?`translate(1024 0) scale(-1 1)`:``;for(let{node:e,base:t}of this.noFlip){let n=o?`${o} ${t}`.trim():t;n?e.setAttribute(`transform`,n):e.removeAttribute(`transform`)}let s=e.armL*180/Math.PI,c=e.armR*180/Math.PI,l=e.sprout*180/Math.PI,u=this.pivots;this.armL.setAttribute(`transform`,`translate(${u.l.x} ${u.l.y}) rotate(${u.restL+s})`),this.armR.setAttribute(`transform`,`translate(${u.r.x} ${u.r.y}) rotate(${u.restR+c})`),this.tuft.setAttribute(`transform`,`translate(${u.tuft.x} ${u.tuft.y}) rotate(${l})`),this.lumenTuft&&this.lumenTuft.setAttribute(`transform`,`translate(${u.tuft.x} ${u.tuft.y}) rotate(${l})`);for(let t of this.lumen)t!==this.lumenCore&&t!==this.lumenHot&&(t.style.opacity=String(Math.min(1,e.glow)));let d=Math.min(1,Math.max(0,(e.glow-.72)/.58));if(this.lumenCore&&(this.lumenCore.style.opacity=String(.5+.5*d)),this.lumenHot&&(this.lumenHot.style.opacity=String(.12+.6*d)),this.lumenHalo){let t=.9+e.glow*.18;this.lumenHalo.setAttribute(`transform`,`translate(512 655) scale(${t}) translate(-512 -655)`)}this.tail&&u.tail&&this.tail.setAttribute(`transform`,`translate(${u.tail.x} ${u.tail.y}) rotate(${-l*.7})`);let f=e.happyEyes>.4,p=e.eyeOpen<.08&&!f;for(let t of this.eyeDots)if(t.style.display=f||p?`none`:`block`,!f&&!p){let n=t.getAttribute(`cx`),r=t.getAttribute(`cy`);t.setAttribute(`transform`,`translate(${n} ${r}) scale(1 ${Math.max(e.eyeOpen,.12)}) translate(${-Number(n)} ${-Number(r)})`)}else t.removeAttribute(`transform`);for(let e of this.eyeShine)e.style.display=f||p?`none`:`block`;for(let e of this.eyeHappy)e.style.display=f?`block`:`none`;for(let e of this.eyeSleep)e.style.display=p?`block`:`none`;for(let[t,n]of Object.entries(this.mouths))for(let r of n)r.style.display=t===e.mouth?`block`:`none`}};function je(e,t){let n=e.querySelector(t);if(!n)throw Error(`Missing ${t}`);return n}var Me=class{canvas;fx;ctx;fxCtx;puppet;playground;tank;transparent;anchorBottom=!1;w=0;h=0;dpr=1;constructor(e,t,n,r,i,a=!1){let o=e.getContext(`2d`,{alpha:a}),s=t.getContext(`2d`,{alpha:!0});if(!o||!s)throw Error(`Canvas 2D is unavailable`);this.canvas=e,this.fx=t,this.ctx=o,this.fxCtx=s,this.playground=r,this.tank=i,this.transparent=a,this.puppet=new Ae(n)}resize(){this.dpr=Math.min(window.devicePixelRatio||1,2.25),this.w=window.innerWidth,this.h=window.innerHeight,Ne(this.canvas,this.ctx,this.w,this.h,this.dpr),Ne(this.fx,this.fxCtx,this.w,this.h,this.dpr)}setTank(e,t){this.tank=e,this.playground=t}setPuppet(e){this.puppet=new Ae(e)}draw(e,t){De(e.particles,t);let n=e.pose(),r=this.ctx;this.drawPlayground(r),this.puppet.apply(n,e.radius);let i=this.fxCtx;i.clearRect(0,0,this.w,this.h),Oe(i,e.particles),n.flash>0&&(i.fillStyle=`rgba(255, 248, 210, ${n.flash*.28})`,i.fillRect(0,0,this.w,this.h))}drawPlayground(e){if(this.transparent){e.clearRect(0,0,this.w,this.h);return}let t=this.playground;if(e.fillStyle=this.anchorBottom?this.tank.floor:this.tank.wash,e.fillRect(0,0,this.w,this.h),!t.width||!t.height)return;let n=Math.max(this.w/t.width,this.h/t.height),r=t.width*n,i=t.height*n,a=this.anchorBottom?this.h-i:(this.h-i)/2;e.drawImage(t,(this.w-r)/2,a,r,i)}};function Ne(e,t,n,r,i){e.width=Math.round(n*i),e.height=Math.round(r*i),e.style.width=`${n}px`,e.style.height=`${r}px`,t.setTransform(i,0,0,i,0,0),t.imageSmoothingEnabled=!0,t.imageSmoothingQuality=`high`}function Pe(e){return new Promise((t,n)=>{let r=new Image;r.onload=()=>t(r),r.onerror=()=>n(Error(`Failed to load ${e}`)),r.src=e})}var Fe=[`spin`,`happy`,`wave`,`dazzle`,`love`,`bounce`,`dance`,`shy`,`surprise`,`stretch`,`cheer`,`pout`,`curious`,`wiggle`,`sleep`],Ie=new Set([`happy`,`cheer`,`dazzle`,`love`]),J={spin:1.2,happy:1.1,wave:1.45,dazzle:1.45,love:1.6,bounce:1.4,dance:1.7,shy:1.55,surprise:1.1,stretch:1.5,cheer:1.35,pout:1.4,curious:1.55,wiggle:1.15,sleep:1.15},Le=new Set([`happy`,`spin`,`dazzle`,`love`,`bounce`,`dance`,`shy`,`surprise`,`stretch`,`cheer`,`pout`,`curious`,`wiggle`]),Re=class{x=0;y=0;vx=0;vy=0;targetX=0;targetY=0;following=!1;dragging=!1;wanderIn=T(2.5,5);bob=Math.random()*Math.PI*2;blinkT=T(2.2,4.2);blinking=0;emote=null;emoteT=0;sleeping=!1;sleepBob=0;zzzIn=.4;radius=72;glow=!1;glowLevel=.5;moteIn=.6;anchored=!1;reduceMotion=!1;particles=[];facing=1;armL=0;armR=0;footL=0;footR=0;sprout=0;gait=0;trailAcc=0;constructor(e,t){this.x=e,this.y=t,this.targetX=e,this.targetY=t}get status(){return this.emote===`sleep`||this.sleeping?`Sleeping`:this.emote===`spin`?`Spin`:this.emote===`happy`?`Happy`:this.emote===`wave`?`Wave`:this.emote===`dazzle`?`Dazzle`:this.emote===`love`?`Love`:this.emote===`bounce`?`Bounce`:this.emote===`dance`?`Dance`:this.emote===`shy`?`Shy`:this.emote===`surprise`?`Surprise`:this.emote===`stretch`?`Stretch`:this.emote===`cheer`?`Cheer`:this.emote===`pout`?`Pout`:this.emote===`curious`?`Curious`:this.emote===`wiggle`?`Wiggle`:this.dragging?`Held`:this.following?`Swimming`:`Idle`}contains(e,t){let n=e-this.x,r=t-this.y;return n*n+r*r<=(this.radius*1.2)**2}play(e){if(e===`sleep`){if(this.sleeping){this.wake();return}this.sleeping=!0,this.following=!1,this.dragging=!1}else this.sleeping&&this.wake();if(this.emote=e,this.emoteT=0,e!==`sleep`&&(this.following=!1,this.vx=0,this.vy=0),e===`dazzle`){this.particles.push(K(this.x,this.y,24));for(let e=0;e<22;e++)this.particles.push(Ce(this.x,this.y))}if(e===`spin`){if(!this.reduceMotion)for(let e=0;e<3;e++)this.particles.push(q(this.x,this.y+16,{burst:!0}));for(let e=0;e<6;e++)this.particles.push(Se(this.x,this.y+30,!0))}if(e===`happy`&&this.particles.push(K(this.x,this.y+10,16)),e===`love`)for(let e=0;e<14;e++)this.particles.push(Te(this.x,this.y-12));if(e===`cheer`&&(this.particles.push(K(this.x,this.y+8,14)),!this.reduceMotion))for(let e=0;e<3;e++)this.particles.push(q(this.x,this.y+12,{burst:!0}));if(e===`surprise`){this.particles.push(K(this.x,this.y,12));for(let e=0;e<12;e++)this.particles.push(Ce(this.x,this.y))}}wake(){if(this.sleeping=!1,this.emote===`sleep`&&(this.emote=null),this.emoteT=0,this.blinkT=.2,!this.reduceMotion)for(let e=0;e<3;e++)this.particles.push(q(this.x,this.y+8,{burst:!0}))}goTo(e,t){this.sleeping&&this.wake(),this.targetX=e,this.targetY=t,this.following=!0}hold(e,t){this.sleeping&&this.wake(),this.dragging=!0,this.following=!0,this.targetX=e,this.targetY=t}release(){this.dragging=!1}update(e,t){let n=Math.min(e,1/20);this.bob+=n*(this.sleeping?1.15:2.2),this.sleepBob+=n,!this.sleeping&&this.emote!==`sleep`&&(this.wanderIn-=n,!this.anchored&&!this.reduceMotion&&!this.following&&!this.dragging&&this.wanderIn<=0&&!this.emote&&(this.targetX=T(Math.max(t.left,t.w*.22),Math.min(t.right,t.w*.78)),this.targetY=T(t.top,t.bottom),this.following=!0,this.wanderIn=T(3.5,7)));let r=this.dragging?10:3.4;if(this.following||this.dragging){let e=this.targetX-this.x,t=this.targetY-this.y,i=Math.hypot(e,t);if(i>(this.dragging?2:16)){let a=this.dragging?300:S(i*r,18,156);this.vx=w(this.vx,e/i*a,4.2,n),this.vy=w(this.vy,t/i*a,4.2,n)}else this.vx=w(this.vx,0,2.6,n),this.vy=w(this.vy,0,2.6,n),this.dragging||(this.following=!1)}else{let e=Math.sin(this.bob*.35)*10,t=Math.sin(this.bob*.48+1.1)*14,r=this.sleeping||this.anchored;this.vx=w(this.vx,r?0:e,1.4,n),this.vy=w(this.vy,r?0:t,1.4,n)}this.emote&&Le.has(this.emote)&&(this.vx*=1-4*n,this.vy*=1-4*n),this.x+=this.vx*n,this.y+=this.vy*n,this.x=S(this.x,t.left,t.right),this.y=S(this.y,t.top,t.bottom),this.vx>18?this.facing=1:this.vx<-18&&(this.facing=-1);let i=Math.hypot(this.vx,this.vy);if(this.gait+=(.9+i*.028)*n,i>48&&!this.sleeping&&!this.reduceMotion){this.trailAcc+=n;let e=this.particles.filter(e=>e.kind===`bubble`).length;this.trailAcc>.95&&e<7&&(this.trailAcc=0,this.particles.push(q(this.x-this.facing*16,this.y+30,{size:3+Math.random()*3.5,rise:-22-Math.random()*16})))}else this.trailAcc=0;if(this.glow&&!this.sleeping&&!this.reduceMotion){this.moteIn-=n;let e=this.particles.filter(e=>e.kind===`mote`).length;this.moteIn<=0&&e<5&&(this.moteIn=T(.7,1.4),this.particles.push(Ee(this.x,this.y,this.radius)))}if(this.blinkT-=n,this.blinkT<=0&&!this.sleeping&&(this.blinking=.14,this.blinkT=T(2.4,5.5)),this.blinking>0&&(this.blinking-=n),this.sleeping&&(this.zzzIn-=n,this.zzzIn<=0&&(this.particles.push(we(this.x,this.y-20)),this.zzzIn=T(.9,1.5))),this.emote){this.emoteT+=n;let e=J[this.emote];if(this.emote===`dazzle`&&this.emoteT<.35&&Math.random()<.55&&this.particles.push(Ce(this.x,this.y)),this.emote===`love`&&this.emoteT<1.1&&Math.random()<.22&&this.particles.push(Te(this.x,this.y-6)),this.emote===`happy`&&this.emoteT>.52&&this.emoteT<.58&&(this.particles.push(K(this.x,this.y+28,18)),!this.reduceMotion))for(let e=0;e<3;e++)this.particles.push(q(this.x,this.y+18,{burst:!0}));if(this.emote===`bounce`){let e=Math.floor(this.emoteT/.35);if(e!==Math.floor((this.emoteT-n)/.35)&&e>0&&e<4&&!this.reduceMotion)for(let e=0;e<2;e++)this.particles.push(q(this.x,this.y+30,{burst:!0}))}this.emote!==`sleep`&&this.emoteT>=e&&(this.emote=null,this.emoteT=0)}this.springLimbs(n,i)}pose(){let e=Math.hypot(this.vx,this.vy),t=S(e/140,0,1),n=e>6?Math.atan2(this.vx,160)*.42:0,r=e>6?Math.atan2(this.vy,180)*.38:0,i=this.reduceMotion,a=i?Math.sin(this.bob)*2:Math.sin(this.bob)*(this.sleeping?4:8)+Math.sin(this.bob*.47)*3,o=n+r+(i?0:Math.sin(this.bob*.5)*.04),s=1,c=1+(i?0:Math.sin(this.bob*.9)*.018)+t*.07,l=2-c-t*.02,u=this.blinking>0?k(Math.abs(this.blinking-.07)/.07):1,d=1,f=0,p=.74+Math.sin(this.bob*.4)*.14,m=0,h=`smile`,ee=this.facing*.22,g=this.y+a+Math.sin(this.gait*1.6)*t*6,_=this.x;if(this.emote){let e=J[this.emote],t=k(this.emoteT/e);if(this.emote===`spin`)ee=this.facing*.22+D(t)*Math.PI*2*this.facing,o+=i?0:D(t)*Math.PI*2,s+=Math.sin(t*Math.PI)*.1,c=1+Math.sin(t*Math.PI*2)*.08,l=2-c,h=`open`;else if(this.emote===`happy`){if(t<.16){let e=t/.16;c=C(1,1.22,e),l=C(1,.78,e)}else if(t<.55){let e=(t-.16)/.39;c=C(1.22,.82,E(e)),l=C(.78,1.22,E(e)),g-=i?0:O(e)*112}else if(t<.72){let e=(t-.55)/.17;c=C(.82,1.28,e),l=C(1.22,.72,e),g-=(1-e)*(i?0:16)}else{let e=(t-.72)/.28;c=C(1.28,1,E(e)),l=C(.72,1,E(e))}m=+(t>.12&&t<.85),u=m?.12:u,h=`open`}else if(this.emote===`wave`)o+=Math.sin(t*Math.PI)*.12*this.facing,h=`smile`;else if(this.emote===`dazzle`)s+=Math.sin(t*Math.PI)*.16,f=t<.18?1-t/.18:Math.max(0,.25-t)*2,o+=Math.sin(t*Math.PI*6)*.06,h=`o`,u=1;else if(this.emote===`sleep`)u=1-E(t),d=C(1,.78,E(t)),g+=E(t)*10,h=`flat`;else if(this.emote===`love`)o+=Math.sin(t*Math.PI*4)*.1,s+=Math.sin(t*Math.PI)*.06,m=+(t>.08&&t<.88),h=`open`,c=1+Math.sin(t*Math.PI*3)*.04,l=2-c;else if(this.emote===`bounce`){let e=t*4%1,n=Math.sin(e*Math.PI);g-=n*(i?0:54),c=1+(1-n)*.16,l=2-c,h=`open`,m=+(n>.35)}else if(this.emote===`dance`)_+=Math.sin(t*Math.PI*6)*(i?0:18),o+=Math.sin(t*Math.PI*6)*.22,g-=Math.abs(Math.sin(t*Math.PI*6))*(i?0:10),c=1+Math.sin(t*Math.PI*6)*.08,l=2-c,h=`open`,m=1;else if(this.emote===`shy`){let e=t<.55?E(t/.55):1-D((t-.55)/.45);o+=-.28*e*this.facing,g+=e*8,c=1+e*.08,l=2-c,u=C(1,.28,e),h=t>.35&&t<.8?`smile`:`flat`}else if(this.emote===`surprise`){if(t<.18){let e=t/.18;c=C(1,1.36,e),l=C(1,.64,e)}else if(t<.55){let e=(t-.18)/.37;c=C(1.36,.78,O(e)),l=C(.64,1.28,O(e)),g-=O(e)*72,s=1+(1-e)*.08}else{let e=(t-.55)/.45;c=C(.86,1,E(e)),l=C(1.18,1,E(e)),g-=(1-e)*48}h=t<.82?`o`:`smile`,u=1}else if(this.emote===`stretch`){if(t<.25){let e=t/.25;c=C(1,.82,e),l=C(1,1.22,e)}else if(t<.72)c=.78,l=1.28,o+=Math.sin((t-.25)*Math.PI*2)*.04,g-=10;else{let e=(t-.72)/.28;c=C(.78,1,E(e)),l=C(1.28,1,E(e))}h=t>.2&&t<.75?`open`:`smile`,u=t>.3&&t<.7?.35:u}else if(this.emote===`cheer`){let e=Math.abs(Math.sin(t*Math.PI*3));g-=e*64,c=1+(1-e)*.14,l=2-c,m=1,h=`open`}else if(this.emote===`pout`)o+=.12*this.facing,g+=12,c=1.08,l=.94,u=.55,h=`flat`;else if(this.emote===`curious`){let e=Math.sin(t*Math.PI*3);o+=e*.32,_+=e*10,c=1+Math.abs(e)*.04,l=2-c,h=`o`,u=1}else this.emote===`wiggle`&&(o+=Math.sin(t*Math.PI*12)*.18,c=1+Math.sin(t*Math.PI*10)*.1,l=2-c,g-=Math.abs(Math.sin(t*Math.PI*8))*8,m=1,h=`open`)}if(this.emote&&Ie.has(this.emote)){let e=k(this.emoteT/J[this.emote]);p=.9+Math.sin(e*Math.PI)*.4}else this.emote===`sleep`&&(p=C(p,.3,E(k(this.emoteT/J.sleep))));return this.sleeping&&this.emote!==`sleep`&&(u=0,d=.78,p=.3+Math.sin(this.sleepBob*.6)*.05,g+=10+Math.sin(this.sleepBob*1.1)*2,o=Math.sin(this.sleepBob*.7)*.05,h=`flat`),p*=this.glowLevel,this.glow&&(d*=1.02+p*.05),{x:_,y:g,rot:o,scale:s,squashX:c,squashY:l,eyeOpen:u,happyEyes:m,flash:f,brightness:d,glow:p,facing:this.facing,armL:this.armL,armR:this.armR,footL:this.footL,footR:this.footR,sprout:this.sprout,mouth:h,hop:0,yaw:ee}}springLimbs(e,t){let n=S(t/120,0,1),r=Math.sin(this.bob),i=this.reduceMotion?.35:1,a=r*.14*i,o=Math.sin(this.bob+.5)*-.12*i,s=0,c=0,l=Math.sin(this.bob*.7+.4)*.16*i;if(n>.06&&!this.emote){let e=Math.sin(this.gait*2.1),t=Math.max(0,-e);a=e*.72*n,o=-e*.72*n,s=t*n*.55,c=t*n*.55,l=-e*.22*n}if(this.emote){let e=J[this.emote],t=k(this.emoteT/e);if(this.emote===`spin`){let e=Math.sin(t*Math.PI)*.55;a=-e,o=e,l=.6}else if(this.emote===`happy`)a=C(0,1.05,k(t*3)),o=C(0,-1.05,k(t*3)),t>.75&&(a=C(1.05,0,(t-.75)/.25),o=C(-1.05,0,(t-.75)/.25)),s=t>.16&&t<.6?.7:0,c=s;else if(this.emote===`wave`)a=.06,o=-1.05+Math.sin(t*Math.PI*6)*.38,l=.45+Math.sin(t*Math.PI*7)*.15;else if(this.emote===`dazzle`)a=-.7,o=.7,s=.45,c=.45,l=.7;else if(this.emote===`sleep`)a=-.22,o=.22,l=-.25;else if(this.emote===`love`)a=.55,o=-.55,l=.35+Math.sin(t*Math.PI*5)*.2;else if(this.emote===`bounce`){let e=Math.sin(t*Math.PI*8)*.7;a=e,o=-e,l=e*.4}else if(this.emote===`dance`){let e=Math.sin(t*Math.PI*6);a=e*.85,o=e*.85,l=e*.45}else if(this.emote===`shy`)a=1.28,o=-1.28,l=-.15;else if(this.emote===`surprise`)a=t<.2?.2:-.85,o=t<.2?-.2:.85,l=.85;else if(this.emote===`stretch`)a=-.35,o=.35,l=.55;else if(this.emote===`cheer`)a=1.12,o=-1.12,l=.5+Math.sin(t*Math.PI*6)*.25;else if(this.emote===`pout`)a=-.35,o=.35,l=-.4;else if(this.emote===`curious`){let e=Math.sin(t*Math.PI*3);a=.15+e*.25,o=-.15+e*.25,l=e*.35}else if(this.emote===`wiggle`){let e=Math.sin(t*Math.PI*12)*.9;a=e,o=e,l=-e*.5}}this.sleeping&&this.emote!==`sleep`&&(a=-.22,o=.22,l=-.25),this.armL=w(this.armL,a,12,e),this.armR=w(this.armR,o,12,e),this.footL=w(this.footL,s,14,e),this.footR=w(this.footR,c,14,e),this.sprout=w(this.sprout,l,8,e)}},ze=[{id:`lagoon`,name:`Lagoon`,src:`/tanks/lagoon.png`,iosSrc:`/tanks/ios/lagoon.png?v=3`,wash:`#dff3ea`,floor:`#ADE2CB`,swatch:`#9ed9c4`,swatchFloor:`#c8ead8`,swatchGlow:`#f3f0c4`},{id:`reef`,name:`Reef`,src:`/tanks/reef.png?v=2`,iosSrc:`/tanks/ios/reef.png?v=3`,wash:`#f7d8c4`,floor:`#ECB28A`,swatch:`#f0b896`,swatchFloor:`#f8d4bc`,swatchGlow:`#ffe8d0`},{id:`deep`,name:`Deep`,src:`/tanks/deep.png?v=2`,iosSrc:`/tanks/ios/deep.png?v=3`,wash:`#2d5a72`,floor:`#0C1E3F`,swatch:`#3d7a96`,swatchFloor:`#2a4e64`,swatchGlow:`#8ec8d8`},{id:`kelp`,name:`Kelp`,src:`/tanks/kelp.png?v=2`,iosSrc:`/tanks/ios/kelp.png?v=3`,wash:`#d4e08a`,floor:`#C6A841`,swatch:`#b4c86a`,swatchFloor:`#c8d878`,swatchGlow:`#f0e8a0`},{id:`dusk`,name:`Dusk`,src:`/tanks/dusk.png?v=2`,iosSrc:`/tanks/ios/dusk.png?v=3`,wash:`#d4c4e4`,floor:`#AE89BF`,swatch:`#c4a8d8`,swatchFloor:`#d8c4e4`,swatchGlow:`#f0c8c8`}],Be=`sprout-tank`;function Ve(e){return ze.find(t=>t.id===e)??ze[0]}function He(){try{return Ve(localStorage.getItem(Be))}catch{return ze[0]}}function Ue(e){try{localStorage.setItem(Be,e)}catch{}}function We(e,t=e.wash){document.documentElement.style.setProperty(`--tank-wash`,t),document.body.style.background=t}function Ge(e,t){return e.replace(/\sid="sprout"/,` id="${t}"`).replace(/\sid="sail"/,` id="${t}"`).replace(/\sid="orca"/,` id="${t}"`).replace(/\sid="axolotl"/,` id="${t}"`).replace(/id="sprout-outline"/g,`id="${t}-outline"`).replace(/id="sail-outline"/g,`id="${t}-outline"`).replace(/url\(#sprout-outline\)/g,`url(#${t}-outline)`).replace(/url\(#sail-outline\)/g,`url(#${t}-outline)`).replace(/id="sprout-body-clip"/g,`id="${t}-body-clip"`).replace(/url\(#sprout-body-clip\)/g,`url(#${t}-body-clip)`).replace(/id="(fin-[lr]|fin-[lr]-clip|lumen-lamp|sprout-aura|badge-clip)"/g,`id="${t}-$1"`).replace(/href="#(fin-[lr])"/g,`href="#${t}-$1"`).replace(/url\(#(fin-[lr]-clip|lumen-lamp|sprout-aura|badge-clip)\)/g,`url(#${t}-$1)`)}function Ke(e,t,n,r,i){let a=document.createElement(`template`);a.innerHTML=Ge(e,t).trim();let o=a.content.firstElementChild;if(!(o instanceof SVGSVGElement))throw Error(`Collection portrait failed to load`);return o.classList.remove(`mascot-svg`),o.classList.add(`collection-svg`),o.removeAttribute(`aria-hidden`),le(o,n,!1),g(o,r),xe(o,i.id,n,r),o.style.transform=`scale(0.1) translate(${-x.originX}px, ${-x.originY}px)`,o}function qe(e,t,n,r,i){let a=document.createElement(`article`);a.className=`collection-card`,a.classList.toggle(`in-tank`,e.id===n),a.dataset.kind=e.id;let o=document.createElement(`div`);o.className=`collection-portrait`,o.append(Ke(t,`col-${e.id}`,r,i,e));let s=document.createElement(`div`);s.className=`collection-meta`;let c=document.createElement(`h3`);c.textContent=e.name;let l=document.createElement(`p`);l.className=`collection-badge`,l.textContent=e.id===n?`In the tank`:`Little legend`;let u=document.createElement(`div`);u.className=`collection-stars`,u.setAttribute(`role`,`radiogroup`),u.setAttribute(`aria-label`,`${e.name} stars`);for(let t of f(e.id)){let n=document.createElement(`button`);n.type=`button`,n.className=`collection-star`,n.classList.toggle(`active`,t.stage===i.stage),n.dataset.evo=String(t.stage),n.title=`${e.name} ${t.roman}`,n.setAttribute(`aria-label`,`${e.name} ${t.roman}`),n.textContent=t.roman,u.append(n)}let d=document.createElement(`div`);d.className=`collection-chromas`,d.setAttribute(`role`,`radiogroup`),d.setAttribute(`aria-label`,`${e.name} chromas`);for(let t of y){let n=document.createElement(`button`);n.type=`button`,n.className=`collection-chroma`,n.classList.toggle(`active`,t.id===r.id),n.dataset.palette=t.id,n.title=t.name,n.setAttribute(`aria-label`,`${e.name} ${t.name}`),n.style.setProperty(`--swatch`,t.body),n.style.setProperty(`--swatch-belly`,t.belly),d.append(n)}return s.append(c,l,u,d),a.append(o,s),a}function Je(){let e=document.createElement(`article`);e.className=`collection-card collection-soon`,e.setAttribute(`aria-hidden`,`true`);let t=document.createElement(`p`);return t.textContent=`More legends`,e.append(t),e}function Ye(e,t,n,r){e.replaceChildren();for(let r of _){let i=se(r.id,r.defaultPalette),a=h(r.id);e.append(qe(r,t[r.id],n,i,a))}e.append(Je()),e.onclick=e=>{let t=e.target;if(!(t instanceof HTMLElement))return;let n=t.closest(`.collection-card`);if(!n||n.classList.contains(`collection-soon`))return;let i=_.find(e=>e.id===n.dataset.kind);if(!i)return;let a=t.closest(`.collection-star`);if(a){let e=f(i.id).find(e=>e.stage===Number(a.dataset.evo));e&&r.pickEvo(i,e);return}let o=t.closest(`.collection-chroma`);if(o){let e=y.find(e=>e.id===o.dataset.palette);e&&r.pickPalette(i,e);return}r.pickKind(i)}}var Xe={sprout:be(e,`sprout`),sail:t,orca:be(n,`orca`),axolotl:be(r,`axolotl`)},Ze=document.querySelector(`#stage`),Qe=document.querySelector(`#fx`),$e=document.querySelector(`#status`),et=document.querySelector(`#hint`),tt=document.querySelector(`.sleep-label`),nt=document.querySelector(`#kind-name`),rt=document.querySelector(`#collection-btn`),Y=document.querySelector(`#collection`),it=document.querySelector(`#collection-grid`),at=document.querySelector(`#collection-close`);if(!Ze||!Qe||!$e||!et||!tt||!nt)throw Error(`Sprout markup is missing`);var X=Ze,ot=Qe,st=$e,ct=et,lt=tt,ut=nt,Z=new URLSearchParams(location.search),Q=window.__sprout??{},$=Z.has(`embed`)||Q.embed===!0,dt=Z.get(`coat`)??Q.coat??null,ft=Z.get(`evo`)??Q.evo??`3`,pt=Z.get(`type`)??Q.type??null,mt=Z.get(`skin`)??Q.skin??null,ht=Z.get(`tank`)??Q.tank??null,gt=Number(Z.get(`radius`)??Q.radius??0),_t=Number(Z.get(`glow`)??Q.glow??0);$&&document.documentElement.classList.add(`embed`);function vt(e){document.querySelector(`svg.mascot-svg`)?.remove();let t=document.createElement(`template`);t.innerHTML=Xe[e].trim();let n=t.content.firstElementChild;if(!(n instanceof SVGSVGElement))throw Error(`Mascot SVG failed to load`);return X.after(n),n}function yt(e,t={}){(window.webkit?.messageHandlers?.riverSprite)?.postMessage({event:e,...t})}async function bt(){let e=$?te(pt):ne(),t=vt(e.id),n=$&&ht?Ve(ht):He(),r=$&&!ht,i=e=>$?e.iosSrc:e.src;r||We(n,$?n.floor:n.wash);let a=r?new Image:await Pe(i(n)),o=new Me(X,ot,t,a,n,r);o.anchorBottom=$,o.resize();let c=new Re(o.w*.5,o.h*($?.5:.46));_t>0&&(c.glowLevel=_t),c.anchored=$;let u=window.matchMedia?.(`(prefers-reduced-motion: reduce)`);u&&(c.reduceMotion=u.matches,u.addEventListener?.(`change`,e=>{c.reduceMotion=e.matches}));let d=Array.from(document.querySelectorAll(`[data-emote]`)),p=Array.from(document.querySelectorAll(`[data-palette]`)),v=Array.from(document.querySelectorAll(`[data-tank]`)),b=Array.from(document.querySelectorAll(`[data-evo]`)),ie=Array.from(document.querySelectorAll(`[data-kind]`)),oe=Array.from(document.querySelectorAll(`[data-skin]`)),ue=$?de(mt):fe(),C=$?ae(dt??e.defaultPalette):se(e.id,e.defaultPalette),w=()=>e.id===`sprout`?ue:A[0],T=n=>{C=n,le(t,n),xe(t,e.id,n,M),$||ce(n.id,e.id);for(let e of p)e.classList.toggle(`active`,e.dataset.palette===n.id)},E=()=>{document.documentElement.dataset.kind=e.id,document.documentElement.dataset.skin=w().id;for(let e of oe)e.classList.toggle(`active`,e.dataset.skin===ue.id)},D=(t,n=e)=>{if(!$)return t.radius;let r=t.radius/f(n.id)[2].radius;if(gt>0)return gt*r;let i=n.reach;return Math.min(o.w/(2*Math.max(i.left,i.right)),o.h/(2*Math.max(i.up,i.down)))*x.height/x.size*.98*r},O=1.18,k=()=>{let t=c.radius*x.size/x.height,n=e.reach,r=Math.max(n.left,n.right)*t*1.22+18,i=n.up*t*O+112,a=n.down*t*O+12,s=Math.min(r,o.w*.5);return{left:s,right:o.w-s,top:Math.min(i,o.h*.5),bottom:Math.max(o.h-a,Math.min(i,o.h*.5))}},j=()=>{let t=c.radius*x.size/x.height,n=ht?o.h*.07:0,r=k();c.x=o.w*.5,c.y=S(o.h-e.reach.down*t-n,r.top,r.bottom)},M=h(e.id),N=()=>{ut.textContent=`${(M.costume?ge(e.id,C):null)===`ninja`?`Ninja`:e.name} ${M.roman}`},P=n=>{M=n,g(t,n),xe(t,e.id,C,n),c.radius=D(n),c.glow=n.glow,$||ee(n.stage,e.id),N();for(let e of b)e.classList.toggle(`active`,Number(e.dataset.evo)===n.stage)},F=()=>{!it||$||Ye(it,Xe,e.id,{pickKind:e=>L(e),pickEvo:(t,n)=>{t.id!==e.id&&L(t),P(n),F()},pickPalette:(t,n)=>{t.id!==e.id&&L(t),T(n),F()}})},I=e=>{!Y||$||(Y.hidden=!e,document.documentElement.classList.toggle(`collection-open`,e),e&&F())},L=n=>{t.id!==n.id&&(t=vt(n.id),o.setPuppet(t)),e=n,$||re(n.id);for(let e of ie)e.classList.toggle(`active`,e.dataset.kind===n.id);T($?ae(dt??n.defaultPalette):se(n.id,n.defaultPalette)),P($?m(ft,n.id):h(n.id)),E(),N(),$&&j(),Y?.hidden||F()};L(e),$&&j(),rt&&Y&&at&&(rt.addEventListener(`pointerdown`,e=>e.stopPropagation()),at.addEventListener(`pointerdown`,e=>e.stopPropagation()),Y.addEventListener(`pointerdown`,e=>e.stopPropagation()),rt.addEventListener(`click`,()=>I(!0)),at.addEventListener(`click`,()=>I(!1)),Y.addEventListener(`click`,e=>{e.target===Y&&I(!1)}),window.addEventListener(`keydown`,e=>{e.key===`Escape`&&!Y.hidden&&I(!1)}));for(let e of ie)e.addEventListener(`pointerdown`,e=>e.stopPropagation()),e.addEventListener(`click`,()=>{let t=_.find(t=>t.id===e.dataset.kind);t&&L(t)});for(let t of oe)t.addEventListener(`pointerdown`,e=>e.stopPropagation()),t.addEventListener(`click`,()=>{if(e.id!==`sprout`)return;let n=A.find(e=>e.id===t.dataset.skin);n&&(ue=n,$||pe(n.id),T(C),E(),N(),Y?.hidden||F())});for(let t of b)t.addEventListener(`pointerdown`,e=>e.stopPropagation()),t.addEventListener(`click`,()=>{P(m(t.dataset.evo??`3`,e.id))});let me=async e=>{We(e,$?e.floor:e.wash),Ue(e.id);for(let t of v)t.classList.toggle(`active`,t.dataset.tank===e.id);let t=i(e);if(!(o.tank.id===e.id&&o.playground.src.endsWith(t.replace(/^\//,``)))){o.tank=e;try{let n=await Pe(t);o.tank.id===e.id&&o.setTank(e,n)}catch(e){console.error(e)}}};for(let e of v)e.classList.toggle(`active`,e.dataset.tank===n.id);for(let e of p)e.addEventListener(`pointerdown`,e=>e.stopPropagation()),e.addEventListener(`click`,()=>{let t=y.find(t=>t.id===e.dataset.palette);t&&T(t)});for(let e of v)e.addEventListener(`pointerdown`,e=>e.stopPropagation()),e.addEventListener(`click`,()=>{let t=ze.find(t=>t.id===e.dataset.tank);t&&me(t)});let he=()=>{if($)return{w:o.w,h:o.h,...k()};let e=c.radius*.7;return{w:o.w,h:o.h,left:e,right:o.w-e,top:110+e,bottom:o.h-372-e}},R=()=>{st.textContent=c.status,lt.textContent=c.sleeping?`Wake`:`Sleep`;for(let e of d){let t=e.dataset.emote;e.classList.toggle(`active`,t===c.emote||t===`sleep`&&c.sleeping)}},_e=e=>{let t=e===`sleep`&&c.sleeping;c.play(e),l(t?`wake`:e),ct.classList.add(`hide`),R(),yt(`emote`,{name:t?`wake`:e})};window.RiverSprite={play:e=>{Fe.includes(e)&&_e(e)},wake:()=>{c.wake(),l(`wake`),R()},goTo:(e,t)=>{let n=k(),r=e>1?e:e*o.w,i=t>1?t:t*o.h;c.goTo(S(r,n.left,n.right),S(i,n.top,n.bottom))},layout:()=>({w:o.w,h:o.h,radius:c.radius,...k()}),isSleeping:()=>c.sleeping,setReduceMotion:e=>{c.reduceMotion=!!e}};for(let e of d)e.addEventListener(`pointerdown`,e=>e.stopPropagation()),e.addEventListener(`click`,()=>{s();let t=e.dataset.emote;_e(t)});let z=null;if(!$){X.addEventListener(`pointerdown`,e=>{s(),z=e.pointerId,X.setPointerCapture(e.pointerId);let t=e.clientX,n=e.clientY;c.contains(t,n)?(c.hold(t,n),c.sleeping&&l(`wake`)):c.goTo(t,n),ct.classList.add(`hide`),R()}),X.addEventListener(`pointermove`,e=>{z===e.pointerId&&c.dragging&&c.hold(e.clientX,e.clientY)});let e=e=>{z===e.pointerId&&(z=null,c.release(),R())};X.addEventListener(`pointerup`,e),X.addEventListener(`pointercancel`,e)}window.addEventListener(`resize`,()=>{if(o.resize(),$){c.radius=D(M),j(),yt(`layout`,{w:o.w,h:o.h,...k()});return}c.x=Math.min(c.x,o.w-40),c.y=Math.min(c.y,o.h-40)});let B=performance.now(),V=e=>{let t=Math.min(.05,(e-B)/1e3);B=e,c.update(t,he()),o.draw(c,t),R(),requestAnimationFrame(V)};requestAnimationFrame(V),yt(`ready`,{w:o.w,h:o.h,...k()}),document.querySelector(`#boot`)?.classList.add(`hide`)}bt().catch(e=>{let t=document.querySelector(`#boot`);t&&(t.textContent=`Could not wake the mascot`),st.textContent=`Could not load mascot`,console.error(e)});
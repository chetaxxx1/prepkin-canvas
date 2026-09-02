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
  </defs>

  <g id="sprout-root">
    <!--
      Tuft is outlined on its own so it does not melt into the crown
      and leave a lumpy head silhouette.
    -->
    <g id="tuft" transform="translate(512 90)" filter="url(#sprout-outline)">
      <path class="sprout-fill" fill="#58CC9F" d="M 1 8 C 16 -10 36 -40 56 -56 C 68 -64 84 -52 76 -36 C 68 -18 30 4 6 14 Z" />
      <path class="sprout-fill" fill="#58CC9F" d="M -2 10 C -16 -4 -28 -28 -22 -46 C -18 -56 -2 -54 4 -40 C 10 -22 8 2 0 12 Z" />
    </g>

    <g id="sprout-silhouette" filter="url(#sprout-outline)">
      <g id="arm-l" transform="translate(318 452)">
        <path
          class="flipper sprout-fill"
          fill="#58CC9F"
          d="M 68 0
             C 60 -24, 15 -54, -75 -82
             C -173 -110, -270 -64, -353 4
             C -396 42, -390 104, -323 116
             C -233 110, -143 68, -75 50
             C 15 30, 60 22, 68 0 Z"
        />
      </g>
      <g id="arm-r" transform="translate(706 452)">
        <path
          class="flipper sprout-fill"
          fill="#58CC9F"
          d="M -68 0
             C -60 -24, -15 -54, 75 -82
             C 173 -110, 270 -64, 353 4
             C 396 42, 390 104, 323 116
             C 233 110, 143 68, 75 50
             C -15 30, -60 22, -68 0 Z"
        />
      </g>
      <path
        id="body"
        class="sprout-fill"
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

    <ellipse id="belly" cx="512" cy="655" rx="176" ry="92" fill="#B3EBD0" />

    <g id="face">
      <ellipse class="blush" cx="272" cy="424" rx="42" ry="22" fill="#F4B3C0" opacity="0.55" />
      <ellipse class="blush" cx="752" cy="424" rx="42" ry="22" fill="#F4B3C0" opacity="0.55" />

      <g id="eye-l">
        <circle class="eye-dot" cx="362" cy="371" r="63" fill="#121B22" />
        <path class="eye-happy" d="M 300 378 Q 362 338 424 378" fill="none" stroke="#121B22" stroke-width="12" stroke-linecap="round" />
        <path class="eye-sleep" d="M 304 376 Q 362 404 420 376" fill="none" stroke="#121B22" stroke-width="12" stroke-linecap="round" />
      </g>
      <g id="eye-r">
        <circle class="eye-dot" cx="661" cy="371" r="63" fill="#121B22" />
        <path class="eye-happy" d="M 599 378 Q 661 338 723 378" fill="none" stroke="#121B22" stroke-width="12" stroke-linecap="round" />
        <path class="eye-sleep" d="M 603 376 Q 661 404 719 376" fill="none" stroke="#121B22" stroke-width="12" stroke-linecap="round" />
      </g>
      <path class="mouth smile" d="M 468 392 Q 512 430 556 392" fill="none" stroke="#121B22" stroke-width="10" stroke-linecap="round" />
      <path class="mouth open" d="M 464 388 Q 512 442 560 388" fill="none" stroke="#121B22" stroke-width="11" stroke-linecap="round" />
      <ellipse class="mouth o" cx="512" cy="404" rx="16" ry="18" fill="none" stroke="#121B22" stroke-width="9" />
      <path class="mouth flat" d="M 486 400 H 538" fill="none" stroke="#121B22" stroke-width="10" stroke-linecap="round" />
    </g>
  </g>
</svg>
`,t=`<svg id="sail" class="mascot-svg" viewBox="0 0 982 849" fill="none" overflow="visible" aria-hidden="true">
  <defs>
    <filter
      id="sail-outline"
      x="-200"
      y="-220"
      width="1380"
      height="1280"
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
      Cephalic horns — two fins on the crown corners, curling in.
      Each gets its own outline so they stay two horns, not a heart.
      Hidden at I; unlocks at II.
    -->
    <g id="tuft" transform="translate(512 228)">
      <g filter="url(#sail-outline)">
        <path
          class="sprout-fill lobe"
          fill="#6BAFE0"
          d="M -78 22
             C -118 -2, -138 -52, -118 -112
             C -104 -148, -62 -142, -48 -88
             C -38 -50, -48 12, -78 22 Z"
        />
      </g>
      <g filter="url(#sail-outline)">
        <path
          class="sprout-fill lobe"
          fill="#6BAFE0"
          d="M 78 22
             C 118 -2, 138 -52, 118 -112
             C 104 -148, 62 -142, 48 -88
             C 38 -50, 48 12, 78 22 Z"
        />
      </g>
    </g>

    <!-- Whip tail from the kite's bottom point. III only. -->
    <g id="tail" class="evo-full" transform="translate(512 776)" filter="url(#sail-outline)">
      <path
        class="sprout-fill"
        fill="#6BAFE0"
        d="M 0 -20
           C 16 16, 20 88, 14 168
           C 8 248, -4 310, -14 342
           C -8 310, -10 248, -12 168
           C -14 88, -12 16, 0 -20 Z"
      />
    </g>

    <g id="sail-silhouette" filter="url(#sail-outline)">
      <!--
        Pectorals are the left/right POINTS of the kite, not teardrop flippers.
        Leading edge sweeps up; tip is a soft point. Stem tucks under the disc.
        Stub = I. Full span = II/III.
      -->
      <g id="arm-l" transform="translate(300 480)">
        <path
          class="flipper sprout-fill wing-stub"
          fill="#6BAFE0"
          d="M 70 0
             C 20 -50, -40 -90, -110 -70
             C -160 -54, -200 -16, -208 12
             C -196 48, -140 78, -80 64
             C -20 40, 40 16, 70 0 Z"
        />
        <path
          class="flipper sprout-fill wing-full"
          fill="#6BAFE0"
          d="M 80 4
             C 10 -70, -80 -150, -180 -120
             C -250 -96, -300 -50, -310 -16
             C -304 24, -250 90, -170 118
             C -90 108, 10 48, 80 4 Z"
        />
      </g>
      <g id="arm-r" transform="translate(724 480)">
        <path
          class="flipper sprout-fill wing-stub"
          fill="#6BAFE0"
          d="M -70 0
             C -20 -50, 40 -90, 110 -70
             C 160 -54, 200 -16, 208 12
             C 196 48, 140 78, 80 64
             C 20 40, -40 16, -70 0 Z"
        />
        <path
          class="flipper sprout-fill wing-full"
          fill="#6BAFE0"
          d="M -80 4
             C -10 -70, 80 -150, 180 -120
             C 250 -96, 300 -50, 310 -16
             C 304 24, 250 90, 170 118
             C 90 108, -10 48, -80 4 Z"
        />
      </g>
      <!--
        Flattened diamond disc. Concave crown between the horns.
        Side vertices sit on the wing line so the union is ONE kite,
        not a round blob with paddles glued on.
      -->
      <path
        id="body"
        class="sprout-fill"
        fill="#6BAFE0"
        d="M 430 232
           C 470 248, 500 258, 512 258
           C 524 258, 554 248, 594 232
           C 680 278, 742 388, 762 480
           C 742 590, 680 698, 594 750
           C 554 768, 524 776, 512 778
           C 500 776, 470 768, 430 750
           C 344 698, 282 590, 262 480
           C 282 388, 344 278, 430 232 Z"
      />
    </g>

    <path
      id="belly"
      fill="#D4EBF8"
      d="M 512 360
         C 585 385, 650 460, 662 540
         C 650 615, 585 680, 512 712
         C 439 680, 374 615, 362 540
         C 374 460, 439 385, 512 360 Z"
    />

    <g id="face">
      <ellipse class="blush" cx="338" cy="368" rx="36" ry="18" fill="#F3B5A6" opacity="0.42" />
      <ellipse class="blush" cx="686" cy="368" rx="36" ry="18" fill="#F3B5A6" opacity="0.42" />

      <g id="eye-l">
        <circle class="eye-dot" cx="402" cy="332" r="60" fill="#121B22" />
        <path class="eye-happy" d="M 342 339 Q 402 300 462 339" fill="none" stroke="#121B22" stroke-width="12" stroke-linecap="round" />
        <path class="eye-sleep" d="M 346 337 Q 402 364 458 337" fill="none" stroke="#121B22" stroke-width="12" stroke-linecap="round" />
      </g>
      <g id="eye-r">
        <circle class="eye-dot" cx="622" cy="332" r="60" fill="#121B22" />
        <path class="eye-happy" d="M 562 339 Q 622 300 682 339" fill="none" stroke="#121B22" stroke-width="12" stroke-linecap="round" />
        <path class="eye-sleep" d="M 566 337 Q 622 364 678 337" fill="none" stroke="#121B22" stroke-width="12" stroke-linecap="round" />
      </g>
      <path class="mouth smile" d="M 476 378 Q 512 410 548 378" fill="none" stroke="#121B22" stroke-width="10" stroke-linecap="round" />
      <path class="mouth open" d="M 472 374 Q 512 422 552 374" fill="none" stroke="#121B22" stroke-width="11" stroke-linecap="round" />
      <ellipse class="mouth o" cx="512" cy="390" rx="15" ry="16" fill="none" stroke="#121B22" stroke-width="9" />
      <path class="mouth flat" d="M 490 386 H 534" fill="none" stroke="#121B22" stroke-width="10" stroke-linecap="round" />
    </g>
  </g>
</svg>
`,n=null,r=!1;function i(){return n||=new AudioContext,n}function a(){if(r)return;let e=i();e.state===`suspended`&&e.resume(),r=!0}function o(e,t,n,r=.045,a=0,o=0){let s=i(),c=s.currentTime+a,l=s.createOscillator(),u=s.createGain(),d=s.createBiquadFilter();d.type=`lowpass`,d.frequency.value=1400,l.type=n,l.frequency.setValueAtTime(e,c),o&&l.frequency.exponentialRampToValueAtTime(Math.max(40,e+o),c+t),u.gain.setValueAtTime(1e-4,c),u.gain.exponentialRampToValueAtTime(r,c+.03),u.gain.exponentialRampToValueAtTime(1e-4,c+t),l.connect(d),d.connect(u),u.connect(s.destination),l.start(c),l.stop(c+t+.02)}function s(e){if(r)try{e===`spin`?(o(420,.35,`sine`,.04,0,280),o(640,.28,`triangle`,.02,.08,180)):e===`happy`?(o(523,.16,`sine`,.05),o(784,.22,`sine`,.045,.12)):e===`wave`?(o(360,.2,`sine`,.03,0,80),o(300,.18,`triangle`,.02,.14,60)):e===`dazzle`?(o(880,.12,`triangle`,.04),o(1174,.14,`sine`,.035,.08),o(1568,.2,`sine`,.03,.16,-400)):e===`sleep`?(o(392,.28,`sine`,.03,0,-80),o(294,.4,`sine`,.025,.18,-60)):e===`wake`?(o(440,.12,`sine`,.03),o(660,.16,`sine`,.03,.08)):e===`love`?(o(523,.14,`sine`,.04),o(659,.18,`sine`,.035,.1),o(784,.22,`sine`,.03,.2)):e===`bounce`?(o(392,.1,`triangle`,.035,0,120),o(392,.1,`triangle`,.03,.28,120),o(392,.1,`triangle`,.03,.56,160)):e===`dance`?(o(330,.12,`triangle`,.03,0,40),o(392,.12,`triangle`,.028,.18,40),o(494,.16,`sine`,.03,.36,80)):e===`shy`?(o(349,.18,`sine`,.025,0,-40),o(294,.22,`sine`,.02,.16,30)):e===`surprise`?(o(880,.1,`square`,.025),o(1320,.16,`sine`,.03,.06,-200)):e===`stretch`?(o(262,.28,`sine`,.03,0,80),o(330,.3,`sine`,.025,.2,40)):e===`cheer`?(o(523,.1,`triangle`,.035),o(659,.12,`triangle`,.03,.16),o(784,.16,`sine`,.03,.3)):e===`pout`?(o(247,.28,`sine`,.03,0,-50),o(196,.32,`sine`,.022,.18,-30)):e===`curious`?(o(440,.12,`sine`,.028,0,60),o(494,.14,`sine`,.025,.2,-40),o(523,.16,`sine`,.025,.4,80)):e===`wiggle`&&(o(370,.08,`triangle`,.03,0,90),o(415,.08,`triangle`,.028,.1,-70),o(370,.1,`triangle`,.028,.2,110))}catch{}}var c=[{stage:1,roman:`I`,radius:44,belly:!1,blush:!1,markings:!1,extra:!1,wings:!1},{stage:2,roman:`II`,radius:58,belly:!0,blush:!1,markings:!1,extra:!1,wings:!1},{stage:3,roman:`III`,radius:72,belly:!0,blush:!0,markings:!1,extra:!1,wings:!1}],l=[{stage:1,roman:`I`,radius:44,belly:!1,blush:!1,markings:!1,extra:!1,wings:!1},{stage:2,roman:`II`,radius:58,belly:!0,blush:!1,markings:!0,extra:!1,wings:!0},{stage:3,roman:`III`,radius:72,belly:!0,blush:!0,markings:!0,extra:!0,wings:!0}];function u(e){return e===`sail`?l:c}var d=e=>e===`sprout`?`sprout-evo`:`sprout-evo-${e}`;function f(e,t=`sprout`){let n=Number(e),r=u(t);return r.find(e=>e.stage===n)??r[2]}function p(e=`sprout`){try{return f(localStorage.getItem(d(e)),e)}catch{return u(e)[2]}}function m(e,t=`sprout`){try{localStorage.setItem(d(t),String(e))}catch{}}function h(e,t){let n=e.querySelector(`#belly`);n&&(n.style.display=t.belly?``:`none`);for(let n of e.querySelectorAll(`.blush`))n.style.display=t.blush?``:`none`;for(let n of e.querySelectorAll(`.lobe, .marking`))n.style.display=t.markings?``:`none`;for(let n of e.querySelectorAll(`.evo-full`))n.style.display=t.extra?``:`none`;for(let n of e.querySelectorAll(`.evo-stub`))n.style.display=t.extra?`none`:``;for(let n of e.querySelectorAll(`.wing-full`))n.style.display=t.wings?``:`none`;for(let n of e.querySelectorAll(`.wing-stub`))n.style.display=t.wings?`none`:``}var g=[{id:`sprout`,name:`Sprout`,defaultPalette:`mint`,reach:{left:550,right:592,up:456,down:380}},{id:`sail`,name:`Sail`,defaultPalette:`sky`,reach:{left:540,right:540,up:450,down:420}}],_=`sprout-kind`;function v(e){return e===`keel`?g[1]:g.find(t=>t.id===e)??g[0]}function ee(){try{return v(localStorage.getItem(_))}catch{return g[0]}}function te(e){try{localStorage.setItem(_,e)}catch{}}var y=[{id:`mint`,name:`Mint`,body:`#58CC9F`,belly:`#B8EED4`,blush:`#F4B3C0`,rim:`#F4FFFC`,accent:`#2f9d86`,stroke:`rgba(47, 157, 134, 0.22)`},{id:`sky`,name:`Sky`,body:`#6BAFE0`,belly:`#D4EBF8`,blush:`#F3B5A6`,rim:`#F5FBFE`,accent:`#3d7eab`,stroke:`rgba(61, 126, 171, 0.22)`},{id:`peach`,name:`Peach`,body:`#E9A07C`,belly:`#F8E0D2`,blush:`#E07A90`,rim:`#FFF8F4`,accent:`#c46d4e`,stroke:`rgba(196, 109, 78, 0.22)`},{id:`lilac`,name:`Lilac`,body:`#B08EE0`,belly:`#E6D9F6`,blush:`#EFA8B8`,rim:`#FBF7FE`,accent:`#7d5aa8`,stroke:`rgba(125, 90, 168, 0.22)`},{id:`butter`,name:`Butter`,body:`#E4C45C`,belly:`#F6ECC4`,blush:`#E99286`,rim:`#FFFBF0`,accent:`#b8942e`,stroke:`rgba(184, 148, 46, 0.22)`},{id:`coral`,name:`Coral`,body:`#E07A72`,belly:`#F6D4CE`,blush:`#D46A9A`,rim:`#FFF6F4`,accent:`#c45c56`,stroke:`rgba(196, 92, 86, 0.22)`}],b=`sprout-palette`;function x(e){return y.find(t=>t.id===e)??y[0]}function S(e){return e===`sprout`?b:`${b}-${e}`}function ne(e=`sprout`,t=`mint`){try{return x(localStorage.getItem(S(e))??t)}catch{return x(t)}}function re(e,t=`sprout`){try{localStorage.setItem(S(t),e)}catch{}}function ie(e,t){for(let n of e.querySelectorAll(`.sprout-fill`))n.setAttribute(`fill`,t.body);e.querySelector(`#belly`)?.setAttribute(`fill`,t.belly);for(let n of e.querySelectorAll(`.blush`))n.setAttribute(`fill`,t.blush);for(let n of e.querySelectorAll(`.marking`))n.setAttribute(`fill`,t.belly);e.querySelector(`feFlood`)?.setAttribute(`flood-color`,t.rim);let n=document.documentElement;n.style.setProperty(`--mint`,t.accent),n.style.setProperty(`--stroke`,t.stroke)}var C={width:982,height:849,originX:491,originY:478,size:2.52,body:`#58CC9F`,face:`#0F181F`,eyeL:{x:362,y:371,r:63},eyeR:{x:661,y:371,r:63},mouth:{x:512,y:392,rx:44,ry:20},armL:{x:318,y:452},armR:{x:706,y:452},sprout:{x:512,y:90}};function w(e,t){return e*C.size/C.height*t}function T(e,t,n=!1){let r=n?Math.random()*Math.PI*2:Math.PI/2+(Math.random()-.5)*.8,i=n?40+Math.random()*80:8+Math.random()*18;return{kind:`drop`,x:e+(Math.random()-.5)*16,y:t+(Math.random()-.5)*8,vx:Math.cos(r)*i,vy:Math.sin(r)*i,life:0,maxLife:.45+Math.random()*.5,size:3+Math.random()*4,rot:0,spin:0,alpha:.7}}function E(e,t){let n=Math.random()*Math.PI*2,r=50+Math.random()*150;return{kind:`spark`,x:e,y:t,vx:Math.cos(n)*r,vy:Math.sin(n)*r,life:0,maxLife:.35+Math.random()*.4,size:1.5+Math.random()*2.4,rot:n,spin:(Math.random()-.5)*8,alpha:1}}function D(e,t){return{kind:`zzz`,x:e+18+Math.random()*10,y:t-28,vx:8+Math.random()*10,vy:-22-Math.random()*12,life:0,maxLife:1.6,size:14+Math.random()*6,rot:(Math.random()-.5)*.4,spin:.4,alpha:.9}}function O(e,t,n=20){return{kind:`ring`,x:e,y:t,vx:0,vy:0,life:0,maxLife:.7,size:n,rot:0,spin:0,alpha:.7}}function k(e,t){return{kind:`heart`,x:e+(Math.random()-.5)*48,y:t-24-Math.random()*22,vx:(Math.random()-.5)*36,vy:-56-Math.random()*36,life:0,maxLife:1.15+Math.random()*.5,size:11+Math.random()*7,rot:(Math.random()-.5)*.5,spin:(Math.random()-.5)*1.4,alpha:1}}function A(e,t,n={}){let r=n.burst??!1,i=n.size??(r?3+Math.random()*7:5+Math.random()*11);return{kind:`bubble`,x:e+(Math.random()-.5)*(r?28:10),y:t+(Math.random()-.5)*(r?18:8),vx:(Math.random()-.5)*(r?56:18),vy:n.rise??-28-Math.random()*(r?70:42),life:0,maxLife:r?.7+Math.random()*.7:2.2+Math.random()*2.6,size:i,rot:Math.random()*Math.PI*2,spin:1.4+Math.random()*2.2,alpha:.42+Math.random()*.28}}function ae(e,t){for(let n=e.length-1;n>=0;n--){let r=e[n];r.life+=t;let i=r.life/r.maxLife;r.x+=r.vx*t,r.y+=r.vy*t,r.rot+=r.spin*t,r.kind===`drop`?(r.vy+=70*t,r.alpha=(1-i)*.65):r.kind===`spark`?(r.vx*=1-1.8*t,r.vy*=1-1.8*t,r.alpha=1-i):r.kind===`zzz`?r.alpha=i<.15?i/.15:1-(i-.15)/.85:r.kind===`heart`?(r.vy+=18*t,r.alpha=i<.12?i/.12:1-(i-.12)/.88):r.kind===`bubble`?(r.x+=Math.sin(r.rot)*18*t,r.vx*=1-.55*t,r.vy*=1-.12*t,r.vy-=8*t,r.size+=3.4*t,r.alpha=(i<.08?i/.08:i>.78?1-(i-.78)/.22:1)*.38):(r.size+=140*t,r.alpha=(1-i)*.5),r.life>=r.maxLife&&e.splice(n,1)}}function j(e,t){for(let n of t){if(e.save(),e.translate(n.x,n.y),e.rotate(n.kind===`bubble`?0:n.rot),e.globalAlpha=Math.max(0,n.alpha),n.kind===`drop`)e.fillStyle=`#9BE8D0`,e.beginPath(),e.ellipse(0,0,n.size*.85,n.size*.65,0,0,Math.PI*2),e.fill();else if(n.kind===`spark`)e.strokeStyle=`#F6C84C`,e.lineWidth=1.6,e.lineCap=`round`,e.beginPath(),e.moveTo(-n.size*2.2,0),e.lineTo(n.size*2.2,0),e.stroke();else if(n.kind===`zzz`)e.fillStyle=`rgba(70, 120, 108, 0.8)`,e.font=`600 ${n.size}px ui-rounded, -apple-system, sans-serif`,e.fillText(`z`,0,0);else if(n.kind===`heart`){e.fillStyle=`#F4A0B4`,e.beginPath();let t=n.size;e.moveTo(0,t*.4),e.bezierCurveTo(-t,-t*.15,-t*.55,-t,0,-t*.4),e.bezierCurveTo(t*.55,-t,t,-t*.15,0,t*.4),e.fill()}else if(n.kind===`bubble`){let t=n.size;e.fillStyle=`rgba(210, 242, 255, 0.16)`,e.strokeStyle=`rgba(255, 255, 255, 0.55)`,e.lineWidth=Math.max(1,t*.12),e.beginPath(),e.arc(0,0,t,0,Math.PI*2),e.fill(),e.stroke(),e.strokeStyle=`rgba(255, 255, 255, 0.95)`,e.lineWidth=Math.max(1.1,t*.14),e.lineCap=`round`,e.beginPath(),e.arc(-t*.22,-t*.28,t*.42,-Math.PI*.85,-Math.PI*.15),e.stroke(),e.fillStyle=`rgba(255, 255, 255, 0.55)`,e.beginPath(),e.arc(-t*.28,-t*.32,t*.16,0,Math.PI*2),e.fill()}else e.strokeStyle=`rgba(80, 190, 160, ${n.alpha})`,e.lineWidth=2.5,e.beginPath(),e.arc(0,0,n.size,0,Math.PI*2),e.stroke();e.restore()}}var M={sprout:{l:{x:318,y:452},r:{x:706,y:452},tuft:{x:512,y:90},tail:null,restL:-12,restR:12},sail:{l:{x:300,y:480},r:{x:724,y:480},tuft:{x:512,y:228},tail:{x:512,y:776},restL:-18,restR:18}},N=class{root;armL;armR;tuft;tail;pivots;eyeDots;eyeShine;eyeHappy;eyeSleep;mouths;constructor(e){this.root=e,this.armL=P(e,`#arm-l`),this.armR=P(e,`#arm-r`),this.tuft=P(e,`#tuft`),this.tail=e.querySelector(`#tail`),this.pivots=M[e.id]??M.sprout,this.eyeDots=[...e.querySelectorAll(`.eye-dot`)],this.eyeShine=[...e.querySelectorAll(`.eye-shine`)],this.eyeHappy=[...e.querySelectorAll(`.eye-happy`)],this.eyeSleep=[...e.querySelectorAll(`.eye-sleep`)],this.mouths={smile:[...e.querySelectorAll(`.mouth.smile`)],open:[...e.querySelectorAll(`.mouth.open`)],o:[...e.querySelectorAll(`.mouth.o`)],flat:[...e.querySelectorAll(`.mouth.flat`)]}}apply(e,t){let n=w(t,e.scale),r=e.facing*n*e.squashX,i=n*e.squashY,a=e.rot*180/Math.PI;this.root.style.transform=`translate(${e.x}px, ${e.y}px) rotate(${a}deg) scale(${r}, ${i}) translate(${-C.originX}px, ${-C.originY}px)`,this.root.style.filter=e.brightness<.995?`brightness(${e.brightness})`:``;let o=e.armL*180/Math.PI,s=e.armR*180/Math.PI,c=e.sprout*180/Math.PI,l=this.pivots;this.armL.setAttribute(`transform`,`translate(${l.l.x} ${l.l.y}) rotate(${l.restL+o})`),this.armR.setAttribute(`transform`,`translate(${l.r.x} ${l.r.y}) rotate(${l.restR+s})`),this.tuft.setAttribute(`transform`,`translate(${l.tuft.x} ${l.tuft.y}) rotate(${c})`),this.tail&&l.tail&&this.tail.setAttribute(`transform`,`translate(${l.tail.x} ${l.tail.y}) rotate(${-c*.7})`);let u=e.happyEyes>.4,d=e.eyeOpen<.08&&!u;for(let t of this.eyeDots)if(t.style.display=u||d?`none`:`block`,!u&&!d){let n=t.getAttribute(`cx`),r=t.getAttribute(`cy`);t.setAttribute(`transform`,`translate(${n} ${r}) scale(1 ${Math.max(e.eyeOpen,.12)}) translate(${-Number(n)} ${-Number(r)})`)}else t.removeAttribute(`transform`);for(let e of this.eyeShine)e.style.display=u||d?`none`:`block`;for(let e of this.eyeHappy)e.style.display=u?`block`:`none`;for(let e of this.eyeSleep)e.style.display=d?`block`:`none`;for(let[t,n]of Object.entries(this.mouths))for(let r of n)r.style.display=t===e.mouth?`block`:`none`}};function P(e,t){let n=e.querySelector(t);if(!n)throw Error(`Missing ${t}`);return n}var oe=class{canvas;fx;ctx;fxCtx;puppet;playground;tank;transparent;anchorBottom=!1;w=0;h=0;dpr=1;constructor(e,t,n,r,i,a=!1){let o=e.getContext(`2d`,{alpha:a}),s=t.getContext(`2d`,{alpha:!0});if(!o||!s)throw Error(`Canvas 2D is unavailable`);this.canvas=e,this.fx=t,this.ctx=o,this.fxCtx=s,this.playground=r,this.tank=i,this.transparent=a,this.puppet=new N(n)}resize(){this.dpr=Math.min(window.devicePixelRatio||1,2.25),this.w=window.innerWidth,this.h=window.innerHeight,F(this.canvas,this.ctx,this.w,this.h,this.dpr),F(this.fx,this.fxCtx,this.w,this.h,this.dpr)}setTank(e,t){this.tank=e,this.playground=t}setPuppet(e){this.puppet=new N(e)}draw(e,t){ae(e.particles,t);let n=e.pose(),r=this.ctx;this.drawPlayground(r),this.puppet.apply(n,e.radius);let i=this.fxCtx;i.clearRect(0,0,this.w,this.h),j(i,e.particles),n.flash>0&&(i.fillStyle=`rgba(255, 248, 210, ${n.flash*.28})`,i.fillRect(0,0,this.w,this.h))}drawPlayground(e){if(this.transparent){e.clearRect(0,0,this.w,this.h);return}let t=this.playground;if(e.fillStyle=this.anchorBottom?this.tank.floor:this.tank.wash,e.fillRect(0,0,this.w,this.h),!t.width||!t.height)return;let n=Math.max(this.w/t.width,this.h/t.height),r=t.width*n,i=t.height*n,a=this.anchorBottom?this.h-i:(this.h-i)/2;e.drawImage(t,(this.w-r)/2,a,r,i)}};function F(e,t,n,r,i){e.width=Math.round(n*i),e.height=Math.round(r*i),e.style.width=`${n}px`,e.style.height=`${r}px`,t.setTransform(i,0,0,i,0,0),t.imageSmoothingEnabled=!0,t.imageSmoothingQuality=`high`}function I(e){return new Promise((t,n)=>{let r=new Image;r.onload=()=>t(r),r.onerror=()=>n(Error(`Failed to load ${e}`)),r.src=e})}var L=(e,t,n)=>Math.min(n,Math.max(t,e)),R=(e,t,n)=>e+(t-e)*n,z=(e,t,n,r)=>R(e,t,1-Math.exp(-n*r)),B=(e,t)=>e+Math.random()*(t-e),V=e=>1-(1-e)**3,H=e=>e<.5?4*e*e*e:1-(-2*e+2)**3/2,U=e=>{let t=e-1;return 1+2.70158*t*t*t+1.70158*t*t},W=e=>L(e,0,1),se=[`spin`,`happy`,`wave`,`dazzle`,`love`,`bounce`,`dance`,`shy`,`surprise`,`stretch`,`cheer`,`pout`,`curious`,`wiggle`,`sleep`],G={spin:1.2,happy:1.1,wave:1.45,dazzle:1.45,love:1.6,bounce:1.4,dance:1.7,shy:1.55,surprise:1.1,stretch:1.5,cheer:1.35,pout:1.4,curious:1.55,wiggle:1.15,sleep:1.15},ce=new Set([`happy`,`spin`,`dazzle`,`love`,`bounce`,`dance`,`shy`,`surprise`,`stretch`,`cheer`,`pout`,`curious`,`wiggle`]),le=class{x=0;y=0;vx=0;vy=0;targetX=0;targetY=0;following=!1;dragging=!1;wanderIn=B(2.5,5);bob=Math.random()*Math.PI*2;blinkT=B(2.2,4.2);blinking=0;emote=null;emoteT=0;sleeping=!1;sleepBob=0;zzzIn=.4;radius=72;anchored=!1;particles=[];facing=1;armL=0;armR=0;footL=0;footR=0;sprout=0;gait=0;trailAcc=0;constructor(e,t){this.x=e,this.y=t,this.targetX=e,this.targetY=t}get status(){return this.emote===`sleep`||this.sleeping?`Sleeping`:this.emote===`spin`?`Spin`:this.emote===`happy`?`Happy`:this.emote===`wave`?`Wave`:this.emote===`dazzle`?`Dazzle`:this.emote===`love`?`Love`:this.emote===`bounce`?`Bounce`:this.emote===`dance`?`Dance`:this.emote===`shy`?`Shy`:this.emote===`surprise`?`Surprise`:this.emote===`stretch`?`Stretch`:this.emote===`cheer`?`Cheer`:this.emote===`pout`?`Pout`:this.emote===`curious`?`Curious`:this.emote===`wiggle`?`Wiggle`:this.dragging?`Held`:this.following?`Swimming`:`Idle`}contains(e,t){let n=e-this.x,r=t-this.y;return n*n+r*r<=(this.radius*1.2)**2}play(e){if(e===`sleep`){if(this.sleeping){this.wake();return}this.sleeping=!0,this.following=!1,this.dragging=!1}else this.sleeping&&this.wake();if(this.emote=e,this.emoteT=0,e!==`sleep`&&(this.following=!1,this.vx=0,this.vy=0),e===`dazzle`){this.particles.push(O(this.x,this.y,24));for(let e=0;e<22;e++)this.particles.push(E(this.x,this.y))}if(e===`spin`){for(let e=0;e<3;e++)this.particles.push(A(this.x,this.y+16,{burst:!0}));for(let e=0;e<6;e++)this.particles.push(T(this.x,this.y+30,!0))}if(e===`happy`&&this.particles.push(O(this.x,this.y+10,16)),e===`love`)for(let e=0;e<14;e++)this.particles.push(k(this.x,this.y-12));if(e===`cheer`){this.particles.push(O(this.x,this.y+8,14));for(let e=0;e<3;e++)this.particles.push(A(this.x,this.y+12,{burst:!0}))}if(e===`surprise`){this.particles.push(O(this.x,this.y,12));for(let e=0;e<12;e++)this.particles.push(E(this.x,this.y))}}wake(){this.sleeping=!1,this.emote===`sleep`&&(this.emote=null),this.emoteT=0,this.blinkT=.2;for(let e=0;e<3;e++)this.particles.push(A(this.x,this.y+8,{burst:!0}))}goTo(e,t){this.sleeping&&this.wake(),this.targetX=e,this.targetY=t,this.following=!0}hold(e,t){this.sleeping&&this.wake(),this.dragging=!0,this.following=!0,this.targetX=e,this.targetY=t}release(){this.dragging=!1}update(e,t){let n=Math.min(e,1/20);this.bob+=n*(this.sleeping?1.15:2.2),this.sleepBob+=n,!this.sleeping&&this.emote!==`sleep`&&(this.wanderIn-=n,!this.anchored&&!this.following&&!this.dragging&&this.wanderIn<=0&&!this.emote&&(this.targetX=B(t.w*.22,t.w*.78),this.targetY=B(t.top+80,t.bottom-90),this.following=!0,this.wanderIn=B(3.5,7)));let r=this.dragging?10:3.4;if(this.following||this.dragging){let e=this.targetX-this.x,t=this.targetY-this.y,i=Math.hypot(e,t);if(i>(this.dragging?2:16)){let a=this.dragging?300:L(i*r,18,156);this.vx=z(this.vx,e/i*a,4.2,n),this.vy=z(this.vy,t/i*a,4.2,n)}else this.vx=z(this.vx,0,2.6,n),this.vy=z(this.vy,0,2.6,n),this.dragging||(this.following=!1)}else{let e=Math.sin(this.bob*.35)*10,t=Math.sin(this.bob*.48+1.1)*14,r=this.sleeping||this.anchored;this.vx=z(this.vx,r?0:e,1.4,n),this.vy=z(this.vy,r?0:t,1.4,n)}this.emote&&ce.has(this.emote)&&(this.vx*=1-4*n,this.vy*=1-4*n),this.x+=this.vx*n,this.y+=this.vy*n;let i=this.radius*.7;this.x=L(this.x,i,t.w-i),this.y=L(this.y,t.top+i,t.bottom-i),this.vx>18?this.facing=1:this.vx<-18&&(this.facing=-1);let a=Math.hypot(this.vx,this.vy);if(this.gait+=(.9+a*.028)*n,a>48&&!this.sleeping){this.trailAcc+=n;let e=this.particles.filter(e=>e.kind===`bubble`).length;this.trailAcc>.95&&e<7&&(this.trailAcc=0,this.particles.push(A(this.x-this.facing*16,this.y+30,{size:3+Math.random()*3.5,rise:-22-Math.random()*16})))}else this.trailAcc=0;if(this.blinkT-=n,this.blinkT<=0&&!this.sleeping&&(this.blinking=.14,this.blinkT=B(2.4,5.5)),this.blinking>0&&(this.blinking-=n),this.sleeping&&(this.zzzIn-=n,this.zzzIn<=0&&(this.particles.push(D(this.x,this.y-20)),this.zzzIn=B(.9,1.5))),this.emote){this.emoteT+=n;let e=G[this.emote];if(this.emote===`dazzle`&&this.emoteT<.35&&Math.random()<.55&&this.particles.push(E(this.x,this.y)),this.emote===`love`&&this.emoteT<1.1&&Math.random()<.22&&this.particles.push(k(this.x,this.y-6)),this.emote===`happy`&&this.emoteT>.52&&this.emoteT<.58){this.particles.push(O(this.x,this.y+28,18));for(let e=0;e<3;e++)this.particles.push(A(this.x,this.y+18,{burst:!0}))}if(this.emote===`bounce`){let e=Math.floor(this.emoteT/.35);if(e!==Math.floor((this.emoteT-n)/.35)&&e>0&&e<4)for(let e=0;e<2;e++)this.particles.push(A(this.x,this.y+30,{burst:!0}))}this.emote!==`sleep`&&this.emoteT>=e&&(this.emote=null,this.emoteT=0)}this.springLimbs(n,a)}pose(){let e=Math.hypot(this.vx,this.vy),t=L(e/140,0,1),n=e>6?Math.atan2(this.vx,160)*.42:0,r=e>6?Math.atan2(this.vy,180)*.38:0,i=Math.sin(this.bob)*(this.sleeping?4:8)+Math.sin(this.bob*.47)*3,a=n+r+Math.sin(this.bob*.5)*.04,o=1,s=1+Math.sin(this.bob*.9)*.018+t*.07,c=2-s-t*.02,l=this.blinking>0?W(Math.abs(this.blinking-.07)/.07):1,u=1,d=0,f=0,p=`smile`,m=this.facing*.22,h=this.y+i+Math.sin(this.gait*1.6)*t*6,g=this.x;if(this.emote){let e=G[this.emote],t=W(this.emoteT/e);if(this.emote===`spin`)m=this.facing*.22+H(t)*Math.PI*2*this.facing,a+=H(t)*Math.PI*2,o+=Math.sin(t*Math.PI)*.1,s=1+Math.sin(t*Math.PI*2)*.08,c=2-s,p=`open`;else if(this.emote===`happy`){if(t<.16){let e=t/.16;s=R(1,1.22,e),c=R(1,.78,e)}else if(t<.55){let e=(t-.16)/.39;s=R(1.22,.82,V(e)),c=R(.78,1.22,V(e)),h-=U(e)*112}else if(t<.72){let e=(t-.55)/.17;s=R(.82,1.28,e),c=R(1.22,.72,e),h-=(1-e)*16}else{let e=(t-.72)/.28;s=R(1.28,1,V(e)),c=R(.72,1,V(e))}f=+(t>.12&&t<.85),l=f?.12:l,p=`open`}else if(this.emote===`wave`)a+=Math.sin(t*Math.PI)*.12*this.facing,p=`smile`;else if(this.emote===`dazzle`)o+=Math.sin(t*Math.PI)*.16,d=t<.18?1-t/.18:Math.max(0,.25-t)*2,a+=Math.sin(t*Math.PI*6)*.06,p=`o`,l=1;else if(this.emote===`sleep`)l=1-V(t),u=R(1,.78,V(t)),h+=V(t)*10,p=`flat`;else if(this.emote===`love`)a+=Math.sin(t*Math.PI*4)*.1,o+=Math.sin(t*Math.PI)*.06,f=+(t>.08&&t<.88),p=`open`,s=1+Math.sin(t*Math.PI*3)*.04,c=2-s;else if(this.emote===`bounce`){let e=t*4%1,n=Math.sin(e*Math.PI);h-=n*54,s=1+(1-n)*.16,c=2-s,p=`open`,f=+(n>.35)}else if(this.emote===`dance`)g+=Math.sin(t*Math.PI*6)*18,a+=Math.sin(t*Math.PI*6)*.22,h-=Math.abs(Math.sin(t*Math.PI*6))*10,s=1+Math.sin(t*Math.PI*6)*.08,c=2-s,p=`open`,f=1;else if(this.emote===`shy`){let e=t<.55?V(t/.55):1-H((t-.55)/.45);a+=-.28*e*this.facing,h+=e*8,s=1+e*.08,c=2-s,l=R(1,.28,e),p=t>.35&&t<.8?`smile`:`flat`}else if(this.emote===`surprise`){if(t<.18){let e=t/.18;s=R(1,1.36,e),c=R(1,.64,e)}else if(t<.55){let e=(t-.18)/.37;s=R(1.36,.78,U(e)),c=R(.64,1.28,U(e)),h-=U(e)*72,o=1+(1-e)*.08}else{let e=(t-.55)/.45;s=R(.86,1,V(e)),c=R(1.18,1,V(e)),h-=(1-e)*48}p=t<.82?`o`:`smile`,l=1}else if(this.emote===`stretch`){if(t<.25){let e=t/.25;s=R(1,.82,e),c=R(1,1.22,e)}else if(t<.72)s=.78,c=1.28,a+=Math.sin((t-.25)*Math.PI*2)*.04,h-=10;else{let e=(t-.72)/.28;s=R(.78,1,V(e)),c=R(1.28,1,V(e))}p=t>.2&&t<.75?`open`:`smile`,l=t>.3&&t<.7?.35:l}else if(this.emote===`cheer`){let e=Math.abs(Math.sin(t*Math.PI*3));h-=e*64,s=1+(1-e)*.14,c=2-s,f=1,p=`open`}else if(this.emote===`pout`)a+=.12*this.facing,h+=12,s=1.08,c=.94,l=.55,p=`flat`;else if(this.emote===`curious`){let e=Math.sin(t*Math.PI*3);a+=e*.32,g+=e*10,s=1+Math.abs(e)*.04,c=2-s,p=`o`,l=1}else this.emote===`wiggle`&&(a+=Math.sin(t*Math.PI*12)*.18,s=1+Math.sin(t*Math.PI*10)*.1,c=2-s,h-=Math.abs(Math.sin(t*Math.PI*8))*8,f=1,p=`open`)}return this.sleeping&&this.emote!==`sleep`&&(l=0,u=.78,h+=10+Math.sin(this.sleepBob*1.1)*2,a=Math.sin(this.sleepBob*.7)*.05,p=`flat`),{x:g,y:h,rot:a,scale:o,squashX:s,squashY:c,eyeOpen:l,happyEyes:f,flash:d,brightness:u,facing:this.facing,armL:this.armL,armR:this.armR,footL:this.footL,footR:this.footR,sprout:this.sprout,mouth:p,hop:0,yaw:m}}springLimbs(e,t){let n=L(t/120,0,1),r=Math.sin(this.bob)*.14,i=Math.sin(this.bob+.5)*-.12,a=0,o=0,s=Math.sin(this.bob*.7+.4)*.16;if(n>.06&&!this.emote){let e=Math.sin(this.gait*2.1),t=Math.max(0,-e);r=e*.72*n,i=-e*.72*n,a=t*n*.55,o=t*n*.55,s=-e*.22*n}if(this.emote){let e=G[this.emote],t=W(this.emoteT/e);if(this.emote===`spin`){let e=Math.sin(t*Math.PI)*.55;r=-e,i=e,s=.6}else if(this.emote===`happy`)r=R(0,1.05,W(t*3)),i=R(0,-1.05,W(t*3)),t>.75&&(r=R(1.05,0,(t-.75)/.25),i=R(-1.05,0,(t-.75)/.25)),a=t>.16&&t<.6?.7:0,o=a;else if(this.emote===`wave`)r=.06,i=-1.05+Math.sin(t*Math.PI*6)*.38,s=.45+Math.sin(t*Math.PI*7)*.15;else if(this.emote===`dazzle`)r=-.7,i=.7,a=.45,o=.45,s=.7;else if(this.emote===`sleep`)r=-.22,i=.22,s=-.25;else if(this.emote===`love`)r=.55,i=-.55,s=.35+Math.sin(t*Math.PI*5)*.2;else if(this.emote===`bounce`){let e=Math.sin(t*Math.PI*8)*.7;r=e,i=-e,s=e*.4}else if(this.emote===`dance`){let e=Math.sin(t*Math.PI*6);r=e*.85,i=e*.85,s=e*.45}else if(this.emote===`shy`)r=1.28,i=-1.28,s=-.15;else if(this.emote===`surprise`)r=t<.2?.2:-.85,i=t<.2?-.2:.85,s=.85;else if(this.emote===`stretch`)r=-.35,i=.35,s=.55;else if(this.emote===`cheer`)r=1.12,i=-1.12,s=.5+Math.sin(t*Math.PI*6)*.25;else if(this.emote===`pout`)r=-.35,i=.35,s=-.4;else if(this.emote===`curious`){let e=Math.sin(t*Math.PI*3);r=.15+e*.25,i=-.15+e*.25,s=e*.35}else if(this.emote===`wiggle`){let e=Math.sin(t*Math.PI*12)*.9;r=e,i=e,s=-e*.5}}this.sleeping&&this.emote!==`sleep`&&(r=-.22,i=.22,s=-.25),this.armL=z(this.armL,r,12,e),this.armR=z(this.armR,i,12,e),this.footL=z(this.footL,a,14,e),this.footR=z(this.footR,o,14,e),this.sprout=z(this.sprout,s,8,e)}},K=[{id:`lagoon`,name:`Lagoon`,src:`/tanks/lagoon.png`,iosSrc:`/tanks/ios/lagoon.png?v=3`,wash:`#dff3ea`,floor:`#ADE2CB`,swatch:`#9ed9c4`,swatchFloor:`#c8ead8`,swatchGlow:`#f3f0c4`},{id:`reef`,name:`Reef`,src:`/tanks/reef.png?v=2`,iosSrc:`/tanks/ios/reef.png?v=3`,wash:`#f7d8c4`,floor:`#ECB28A`,swatch:`#f0b896`,swatchFloor:`#f8d4bc`,swatchGlow:`#ffe8d0`},{id:`deep`,name:`Deep`,src:`/tanks/deep.png?v=2`,iosSrc:`/tanks/ios/deep.png?v=3`,wash:`#2d5a72`,floor:`#0C1E3F`,swatch:`#3d7a96`,swatchFloor:`#2a4e64`,swatchGlow:`#8ec8d8`},{id:`kelp`,name:`Kelp`,src:`/tanks/kelp.png?v=2`,iosSrc:`/tanks/ios/kelp.png?v=3`,wash:`#d4e08a`,floor:`#C6A841`,swatch:`#b4c86a`,swatchFloor:`#c8d878`,swatchGlow:`#f0e8a0`},{id:`dusk`,name:`Dusk`,src:`/tanks/dusk.png?v=2`,iosSrc:`/tanks/ios/dusk.png?v=3`,wash:`#d4c4e4`,floor:`#AE89BF`,swatch:`#c4a8d8`,swatchFloor:`#d8c4e4`,swatchGlow:`#f0c8c8`}],q=`sprout-tank`;function ue(e){return K.find(t=>t.id===e)??K[0]}function de(){try{return ue(localStorage.getItem(q))}catch{return K[0]}}function fe(e){try{localStorage.setItem(q,e)}catch{}}function pe(e,t=e.wash){document.documentElement.style.setProperty(`--tank-wash`,t),document.body.style.background=t}var me={sprout:e,sail:t},he=document.querySelector(`#stage`),ge=document.querySelector(`#fx`),_e=document.querySelector(`#status`),ve=document.querySelector(`#hint`),ye=document.querySelector(`.sleep-label`),be=document.querySelector(`#kind-name`);if(!he||!ge||!_e||!ve||!ye||!be)throw Error(`Sprout markup is missing`);var J=he,xe=ge,Se=_e,Ce=ve,we=ye,Te=be,Y=new URLSearchParams(location.search),X=window.__sprout??{},Z=Y.has(`embed`)||X.embed===!0,Ee=Y.get(`coat`)??X.coat??null,De=Y.get(`evo`)??X.evo??`3`,Oe=Y.get(`type`)??X.type??null,Q=Y.get(`tank`)??X.tank??null,ke=Number(Y.get(`radius`)??X.radius??0);Z&&document.documentElement.classList.add(`embed`);function Ae(e){document.querySelector(`svg.mascot-svg`)?.remove();let t=document.createElement(`template`);t.innerHTML=me[e].trim();let n=t.content.firstElementChild;if(!(n instanceof SVGSVGElement))throw Error(`Mascot SVG failed to load`);return J.after(n),n}function $(e,t={}){(window.webkit?.messageHandlers?.riverSprite)?.postMessage({event:e,...t})}async function je(){let e=Z?v(Oe):ee(),t=Ae(e.id),n=Z&&Q?ue(Q):de(),r=Z&&!Q,i=e=>Z?e.iosSrc:e.src;r||pe(n,Z?n.floor:n.wash);let o=r?new Image:await I(i(n)),c=new oe(J,xe,t,o,n,r);c.anchorBottom=Z,c.resize();let l=new le(c.w*.5,c.h*(Z?.5:.46));l.anchored=Z;let u=Array.from(document.querySelectorAll(`[data-emote]`)),d=Array.from(document.querySelectorAll(`[data-palette]`)),_=Array.from(document.querySelectorAll(`[data-tank]`)),b=Array.from(document.querySelectorAll(`[data-evo]`)),S=Array.from(document.querySelectorAll(`[data-kind]`)),w=n=>{ie(t,n),Z||re(n.id,e.id);for(let e of d)e.classList.toggle(`active`,e.dataset.palette===n.id)},T=(t,n=e)=>{if(!Z)return t.radius;let r=t.radius/72;if(ke>0)return ke*r;let i=n.reach;return Math.min(c.w/(2*Math.max(i.left,i.right)),c.h/(2*Math.max(i.up,i.down)))*C.height/C.size*.98*r},E=()=>{let t=l.radius*C.size/C.height,n=Q?c.h*.07:0;l.x=c.w*.5,l.y=c.h-e.reach.down*t-n},D=p(e.id),O=n=>{D=n,h(t,n),l.radius=T(n),Z||m(n.stage,e.id),Te.textContent=`${e.name} ${n.roman}`;for(let e of b)e.classList.toggle(`active`,Number(e.dataset.evo)===n.stage)},k=n=>{t.id!==n.id&&(t=Ae(n.id),c.setPuppet(t)),e=n,Z||te(n.id);for(let e of S)e.classList.toggle(`active`,e.dataset.kind===n.id);w(Z?x(Ee??n.defaultPalette):ne(n.id,n.defaultPalette)),O(Z?f(De,n.id):p(n.id)),Z&&E()};k(e),Z&&E();for(let e of S)e.addEventListener(`pointerdown`,e=>e.stopPropagation()),e.addEventListener(`click`,()=>{let t=g.find(t=>t.id===e.dataset.kind);t&&k(t)});for(let t of b)t.addEventListener(`pointerdown`,e=>e.stopPropagation()),t.addEventListener(`click`,()=>{O(f(t.dataset.evo??`3`,e.id))});let A=async e=>{pe(e,Z?e.floor:e.wash),fe(e.id);for(let t of _)t.classList.toggle(`active`,t.dataset.tank===e.id);let t=i(e);if(!(c.tank.id===e.id&&c.playground.src.endsWith(t.replace(/^\//,``)))){c.tank=e;try{let n=await I(t);c.tank.id===e.id&&c.setTank(e,n)}catch(e){console.error(e)}}};for(let e of _)e.classList.toggle(`active`,e.dataset.tank===n.id);for(let e of d)e.addEventListener(`pointerdown`,e=>e.stopPropagation()),e.addEventListener(`click`,()=>{let t=y.find(t=>t.id===e.dataset.palette);t&&w(t)});for(let e of _)e.addEventListener(`pointerdown`,e=>e.stopPropagation()),e.addEventListener(`click`,()=>{let t=K.find(t=>t.id===e.dataset.tank);t&&A(t)});let ae=()=>({w:c.w,h:c.h,top:Z?0:110,bottom:Z?c.h:c.h-372}),j=()=>{Se.textContent=l.status,we.textContent=l.sleeping?`Wake`:`Sleep`;for(let e of u){let t=e.dataset.emote;e.classList.toggle(`active`,t===l.emote||t===`sleep`&&l.sleeping)}},M=e=>{let t=e===`sleep`&&l.sleeping;l.play(e),s(t?`wake`:e),Ce.classList.add(`hide`),j(),$(`emote`,{name:t?`wake`:e})};window.RiverSprite={play:e=>{se.includes(e)&&M(e)},wake:()=>{l.wake(),s(`wake`),j()},goTo:(e,t)=>l.goTo(e,t),isSleeping:()=>l.sleeping};for(let e of u)e.addEventListener(`pointerdown`,e=>e.stopPropagation()),e.addEventListener(`click`,()=>{a();let t=e.dataset.emote;M(t)});let N=null;J.addEventListener(`pointerdown`,e=>{a(),N=e.pointerId,J.setPointerCapture(e.pointerId);let t=e.clientX,n=e.clientY;l.contains(t,n)?(l.hold(t,n),l.sleeping&&s(`wake`)):l.goTo(t,n),Ce.classList.add(`hide`),j()}),J.addEventListener(`pointermove`,e=>{N===e.pointerId&&l.dragging&&l.hold(e.clientX,e.clientY)});let P=e=>{N===e.pointerId&&(N=null,l.release(),j())};J.addEventListener(`pointerup`,P),J.addEventListener(`pointercancel`,P),window.addEventListener(`resize`,()=>{if(c.resize(),Z){l.radius=T(D),E();return}l.x=Math.min(l.x,c.w-40),l.y=Math.min(l.y,c.h-40)});let F=performance.now(),L=e=>{let t=Math.min(.05,(e-F)/1e3);F=e,l.update(t,ae()),c.draw(l,t),j(),requestAnimationFrame(L)};requestAnimationFrame(L),$(`ready`),document.querySelector(`#boot`)?.classList.add(`hide`)}je().catch(e=>{let t=document.querySelector(`#boot`);t&&(t.textContent=`Could not wake the mascot`),Se.textContent=`Could not load mascot`,console.error(e)});
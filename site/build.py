#!/usr/bin/env python3
"""Builds prepkin.com from bridge/PRIVACY.md and bridge/TERMS.md.

Dependency-free and CDN-free on purpose. The Canvas skin's claim is that it
makes zero external network requests; a site that pulls a font from Google would
undercut the one thing we lead with. Fonts are self-hosted in site/fonts/, the
CSS is inline, and the only script is the optional find field on the policy.

Design: design/handoff-site/ (turn-2 artboards 2a, 2b, 2c, 2d).

Run from anywhere:  python3 site/build.py
"""
import html
import json
import os
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "site"

# Neither listing exists yet. Every button and redirect below points at these,
# so there are exactly two lines to change on the day they go live.
STORE_URL = "https://chromewebstore.google.com/detail/PLACEHOLDER-EXTENSION-ID"
APP_URL = "https://apps.apple.com/app/idPLACEHOLDER"
MAIL = "support@prepkin.com"

# Channels we want to tell apart in Cloudflare Web Analytics. Each becomes
# /go/<slug>/, which is a page view Cloudflare counts, then bounces to the store.
CHANNELS = ["tiktok", "reels", "shorts", "reddit", "bio", "paper", "creator"]

# The before/after Canvas shot. Dropped from the page until the file exists, so
# the site never ships a placeholder. Shoot it, drop it in, rebuild.
SHOT_WIDE = OUT / "img/canvas-before-after.webp"
SHOT_CARD = OUT / "img/canvas-card.webp"
SHOT_LABELS = OUT / "img/shots.json"   # written by design/site-shots/compose.py

FACES = (OUT / "fonts/faces.css").read_text(encoding="utf-8")

# Three colour schemes, picked with PALETTE=paper|duolingo|spotify at build
# time. George chose `duolingo` on 2026-09-11 from real renders of all three;
# `paper` is the handoff's cream (follows the viewer's dark mode) and `spotify`
# the near-black one. Every page colour is a token here, so the markup never
# changes between them.
PALETTES = {
    # The handoff: cream paper, one mint, dark follows the system.
    "paper": {
        "light": """--paper:#FAF5EC; --card:#FFF; --inset:#F3EDE0; --hairline:#E8E0D2;
  --ink:#2E2822; --ink2:#5E554B; --muted:#776D62;
  --mint:#57C79B; --green:#2E8C68; --mint-soft:#E3F6EE; --mint-line:rgba(46,140,104,.25);
  --claim-bg:#E3F6EE; --claim-ink:#2E8C68; --claim-text:#2E2822; --claim-text2:#5E554B; --claim-line:rgba(46,140,104,.25);
  --glow-1:#DDF3E8; --glow-2:#F3EEDF; --glow-3:#FAF5EC; --tank:#CDEFE0;
  --pill:rgba(255,255,255,.72); --pill-line:rgba(46,40,34,.08);
  --pill-shadow:0 2px 12px rgba(46,40,34,.06);
  --ghost:rgba(255,255,255,.7); --ghost-line:rgba(46,40,34,.14); --ghost-hover:#F3EDE0;
  --dark-hover:#3A342D;""",
        "dark": """--paper:#17191D; --card:#1E2126; --inset:#121417; --hairline:#2C3037;
  --ink:#E6E8EA; --ink2:#B4BAC1; --muted:#8D949C;
  --green:#7FDDB8; --mint-soft:#172A23; --mint-line:rgba(127,221,184,.22);
  --claim-bg:#172A23; --claim-ink:#7FDDB8; --claim-text:#E6E8EA; --claim-text2:#B4BAC1; --claim-line:rgba(127,221,184,.22);
  --glow-1:#1E3A31; --glow-2:#1B1F24; --glow-3:#17191D; --tank:#1E3A31;
  --pill:rgba(30,33,38,.8); --pill-line:rgba(255,255,255,.1);
  --pill-shadow:0 2px 12px rgba(0,0,0,.3);
  --ghost:rgba(30,33,38,.7); --ghost-line:rgba(255,255,255,.16); --ghost-hover:#262A30;
  --dark-hover:#CFD2D5;""",
    },
    # Duolingo's register: white, one saturated brand colour in full-bleed
    # blocks, the mascot in the middle. Our hue, their confidence.
    "duolingo": {
        "light": """--paper:#FFFFFF; --card:#FFFFFF; --inset:#F3F6F5; --hairline:#E3E8E6;
  --ink:#1B1F24; --ink2:#4B5563; --muted:#6B7280;
  --mint:#34D399; --green:#0B7A55; --mint-soft:#D9F7EA; --mint-line:rgba(11,122,85,.25);
  --claim-bg:#34D399; --claim-ink:#0B2A1F; --claim-text:#0B2A1F; --claim-text2:#13402F; --claim-line:rgba(11,42,31,.22);
  --glow-1:#C9F5E3; --glow-2:#F1FBF7; --glow-3:#FFFFFF; --tank:#A7F3D0;
  --pill:rgba(255,255,255,.85); --pill-line:rgba(27,31,36,.1);
  --pill-shadow:0 2px 12px rgba(27,31,36,.08);
  --ghost:#FFFFFF; --ghost-line:rgba(27,31,36,.16); --ghost-hover:#F3F6F5;
  --dark-hover:#2D3440;""",
        "dark": None,
    },
    # Spotify's register: near-black, white type, one green that glows.
    # The dark pill inverts to white, the way their play button does.
    "spotify": {
        "light": """--paper:#121212; --card:#181818; --inset:#222222; --hairline:#2A2A2A;
  --ink:#FFFFFF; --ink2:#B3B3B3; --muted:#8C8C8C;
  --mint:#3DDC97; --green:#3DDC97; --mint-soft:#163326; --mint-line:rgba(61,220,151,.25);
  --claim-bg:#3DDC97; --claim-ink:#121212; --claim-text:#121212; --claim-text2:#0F3B2A; --claim-line:rgba(18,18,18,.22);
  --glow-1:#1B3A2E; --glow-2:#161A18; --glow-3:#121212; --tank:#1F4A3A;
  --pill:rgba(24,24,24,.85); --pill-line:rgba(255,255,255,.1);
  --pill-shadow:0 2px 12px rgba(0,0,0,.4);
  --ghost:rgba(255,255,255,.06); --ghost-line:rgba(255,255,255,.18); --ghost-hover:#2A2A2A;
  --dark-hover:#E6E6E6;""",
        "dark": None,
    },
}
PALETTE = os.environ.get("PALETTE", "duolingo")
_pal = PALETTES[PALETTE]
_dark_block = f"@media (prefers-color-scheme:dark){{:root{{\n  {_pal['dark']}\n}}}}" if _pal["dark"] else ""

CSS = FACES + ":root{\n  " + _pal["light"] + """
  --serif:Newsreader,Georgia,serif;
  --sans:Nunito,"SF Pro Rounded",ui-rounded,system-ui,sans-serif;
}
""" + _dark_block + """
*{box-sizing:border-box}
html{-webkit-text-size-adjust:100%}
body{
  margin:0;background:var(--paper);color:var(--ink);
  font:500 17px/1.65 var(--sans);-webkit-font-smoothing:antialiased;
  overflow-x:hidden;
}
img{max-width:100%;height:auto}
h1,h2,h3{font-family:var(--serif);font-weight:400;margin:0}
p{margin:0 0 18px}
a{color:var(--green);text-decoration-color:color-mix(in srgb,var(--green) 40%,transparent);
  text-underline-offset:3px}
a:hover{text-decoration-color:currentColor}
:focus-visible{outline:2px solid var(--mint);outline-offset:2px;border-radius:4px}
.skip{position:absolute;left:-9999px}
.skip:focus{left:16px;top:16px;z-index:9;background:var(--card);padding:10px 14px;
  border-radius:999px;border:1px solid var(--hairline)}
.shell{max-width:1280px;margin:0 auto;padding:0 80px}
.label{font:800 12px/1 var(--sans);letter-spacing:.12em;text-transform:uppercase;color:var(--muted)}

/* --- nav ------------------------------------------------------------- */
.navbar{display:flex;justify-content:center;padding-top:24px}
.nav{display:flex;align-items:center;gap:28px;padding:10px 12px 10px 16px;
  background:var(--pill);border:1px solid var(--pill-line);border-radius:999px;
  box-shadow:var(--pill-shadow);backdrop-filter:blur(8px)}
.nav .brand{display:flex;align-items:center;gap:8px;font:800 16px/1 var(--sans);
  color:var(--ink);text-decoration:none}
.nav .brand img{width:24px;height:24px;border-radius:6px}
.nav ul{display:flex;gap:22px;margin:0;padding:0;list-style:none}
.nav ul a{display:flex;align-items:center;gap:7px;font:700 14px/1 var(--sans);
  color:var(--ink2);text-decoration:none}
.nav ul a:hover{color:var(--ink)}
.nav i{width:6px;height:6px;border-radius:50%;display:block}
.nav [aria-current]{color:var(--ink);text-decoration:underline;
  text-decoration-color:var(--mint);text-underline-offset:6px;text-decoration-thickness:2px}

/* --- buttons --------------------------------------------------------- */
.btn{display:inline-block;padding:16px 26px;border-radius:999px;
  font:800 16px/1 var(--sans);text-decoration:none;white-space:nowrap;
  transition:background 150ms cubic-bezier(.22,1,.36,1),color 150ms cubic-bezier(.22,1,.36,1)}
.btn-dark{background:var(--ink);color:var(--paper)}
.btn-dark:hover{background:var(--dark-hover)}
.btn-ghost{background:var(--ghost);border:1px solid var(--ghost-line);color:var(--ink)}
.btn-ghost:hover{background:var(--ghost-hover)}
.btn-sm{padding:8px 14px;font-size:13px}
.btns{display:flex;gap:12px;flex-wrap:wrap}
@media(prefers-reduced-motion:reduce){*{transition-duration:.01ms!important}}

/* --- home ------------------------------------------------------------ */
.hero{position:relative;overflow:hidden;padding-bottom:56px;
  background:radial-gradient(ellipse 900px 520px at 50% 108%,
    var(--glow-1) 0%,var(--glow-2) 55%,var(--glow-3) 100%)}
.hero-in{margin-top:120px;display:flex;flex-direction:column;align-items:center;
  text-align:center;gap:22px;position:relative;z-index:1;padding:0 20px}
.hero h1{font-size:clamp(52px,7.2vw,92px);line-height:1.02;letter-spacing:-.025em;
  max-width:900px;text-wrap:balance}
.hero h1 em{color:var(--green);font-style:italic}
.hero p{font:600 20px/1.5 var(--sans);color:var(--ink2);max-width:520px;
  text-wrap:pretty;margin:0}
.hero .btns{margin-top:8px}
.hero .sprout{position:absolute;right:140px;bottom:-40px;width:234px;pointer-events:none}
.works{font:700 13px/1.6 var(--sans);color:var(--muted);margin:2px 0 0;
  letter-spacing:.02em}

.shotwide{margin:24px 0 0}
.shotwide figcaption{display:grid;grid-template-columns:1fr 1fr;gap:20px;
  font:800 12px/1 var(--sans);letter-spacing:.12em;text-transform:uppercase;
  color:var(--muted);padding:0 2px 12px}
.shotwide figcaption span+span{color:var(--green)}
.shotwide img{display:block;width:100%;height:auto}

.claimblock{margin:64px 0 0;background:var(--claim-bg);border-radius:28px;
  padding:72px 72px 64px}
.claimblock .label{color:var(--claim-ink);margin-bottom:28px}
.claimblock h2{font-size:clamp(38px,6.6vw,84px);line-height:1;letter-spacing:-.03em;
  color:var(--claim-ink);max-width:900px;text-wrap:balance}
.claimblock .three{display:grid;grid-template-columns:repeat(3,1fr);gap:40px;
  margin-top:64px;padding-top:28px;border-top:1px solid var(--claim-line)}
.claimblock dt{font:800 17px/1.3 var(--sans);color:var(--claim-text)}
.claimblock dd{margin:6px 0 0;font:500 15px/1.55 var(--sans);color:var(--claim-text2)}

.section{padding-top:128px}
.section-head{text-align:center;margin-bottom:44px}
.section-head h2{font-size:clamp(32px,3.6vw,44px);line-height:1.1;
  letter-spacing:-.02em;margin-bottom:12px;text-wrap:balance}
.section-head p{font:500 18px/1.5 var(--sans);color:var(--ink2);margin:0}

.twoup{display:grid;grid-template-columns:1fr 1fr;gap:24px;align-items:start}
.half{background:var(--card);border:2px solid var(--hairline);border-radius:28px;
  padding:36px;position:relative;overflow:hidden}
.half.pick{border-color:var(--mint)}
.half h3{font-size:clamp(26px,2.7vw,34px);line-height:1.1;letter-spacing:-.02em;
  margin-bottom:14px}
.half p{font:500 16px/1.6 var(--sans);color:var(--ink2);max-width:420px;
  text-wrap:pretty;margin:0}
.half .label{margin-bottom:12px}
.pip{position:absolute;top:22px;right:22px;font:800 11px/1 var(--sans);
  letter-spacing:.1em;text-transform:uppercase;color:var(--muted);
  background:var(--inset);padding:6px 10px;border-radius:999px}
.half.pick .pip{color:var(--green);background:var(--mint-soft)}
.frame{margin:28px -38px -38px;height:260px;border-radius:20px 20px 0 0;overflow:hidden;
  display:flex;align-items:flex-end;justify-content:center}
.frame.tank{background:radial-gradient(ellipse at 50% 100%,var(--tank),var(--mint-soft) 70%)}
.frame.tank img{width:180px;margin-bottom:-52px}
.frame.shot{border:1px solid var(--hairline);border-bottom:0;align-items:flex-start}
.frame.shot img{width:100%;object-fit:cover;object-position:top}

.sync{margin-top:128px;background:var(--inset);border-radius:28px;padding:56px 64px;
  display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr);gap:56px;
  align-items:center}
.sync h2{font-size:clamp(30px,3.3vw,40px);line-height:1.1;letter-spacing:-.02em;
  margin:0 0 18px;text-wrap:balance}
.sync p{font:500 17px/1.6 var(--sans);color:var(--ink2);text-wrap:pretty;margin:0}
.sync .label{margin-bottom:16px}
.sync .more{display:inline-block;margin-top:22px;font:800 15px/1 var(--sans)}
.wire{display:flex;align-items:center;justify-content:center}
.box{background:var(--card);border:1px solid var(--hairline);display:flex;
  align-items:center;justify-content:center;text-align:center;
  font:800 14px/1.3 var(--sans);color:var(--ink2)}
.box.laptop{width:150px;height:104px;border-radius:14px}
.box.phone{width:74px;height:130px;border-radius:16px;font-size:13px}
.link{display:flex;flex-direction:column;align-items:center;gap:6px;width:150px}
.link span{font:700 12px/1.4 var(--sans);color:var(--muted);text-align:center}
.link hr{border:0;height:2px;width:100%;margin:0;
  background:repeating-linear-gradient(90deg,var(--mint) 0 8px,transparent 8px 14px)}

.install{margin-top:128px;padding:64px 0;border-radius:28px;
  background:radial-gradient(ellipse 800px 360px at 50% 120%,var(--glow-1) 0%,var(--paper) 70%)}
.panel{background:var(--card);border:1px solid var(--hairline);border-radius:28px;
  padding:80px 60px 72px;display:flex;flex-direction:column;align-items:center;
  text-align:center;gap:20px}
.panel h2{font-size:clamp(32px,4.4vw,56px);line-height:1.02;letter-spacing:-.025em;
  max-width:620px;text-wrap:balance}
.panel p{font:600 19px/1.5 var(--sans);color:var(--ink2);max-width:460px;
  text-wrap:pretty;margin:0}
.panel .fine{font:700 13px/1.6 var(--sans);color:var(--muted);max-width:520px}
.browsers{display:flex;gap:10px;align-items:center;font:700 13px/1 var(--sans);
  color:var(--muted);margin:4px 0 2px;flex-wrap:wrap;justify-content:center}
.browsers b{font-weight:800;color:var(--ink2)}
.browsers em{font-style:normal;color:var(--hairline)}

.notlist{padding-top:128px;display:grid;grid-template-columns:1fr 1fr;gap:64px}
.notlist h2{font-size:clamp(32px,3.6vw,44px);line-height:1.1;letter-spacing:-.02em}
.notlist ul{list-style:none;padding:0;margin:0;font:500 19px/1.4 var(--sans)}
.notlist li{padding:16px 0;border-bottom:1px solid var(--hairline);display:flex;gap:14px}
.notlist li:last-child{border-bottom:0}
.notlist li::before{content:"—";color:var(--green);font-family:var(--serif)}

/* --- legal shell (2c) ------------------------------------------------ */
.band{background:var(--mint-soft);padding:24px 0 120px;display:flex;
  flex-direction:column;align-items:center;gap:72px}
.band .label{font-size:13px;letter-spacing:.16em;color:var(--green)}
.sheet{margin:-80px 80px 0;background:var(--card);border-radius:28px 28px 0 0;
  padding:56px 64px 0;display:grid;grid-template-columns:240px minmax(0,620px);
  gap:96px;align-items:start;justify-content:center}
.toc{position:sticky;top:24px;display:flex;flex-direction:column;gap:28px;padding-top:8px}
.toc .label{font-size:11px;margin-bottom:12px}
.toc .docs a{display:flex;justify-content:space-between;align-items:center;
  padding:10px 12px;border-radius:10px;font:700 15px/1.3 var(--sans);
  color:var(--ink2);text-decoration:none}
.toc .docs a:hover{color:var(--ink)}
.toc .docs [aria-current]{background:var(--inset);font-weight:800;color:var(--ink)}
.toc .docs [aria-current]::after{content:"";width:6px;height:6px;border-radius:50%;
  background:var(--mint)}
.toc ol{margin:0;padding:0;list-style:none;display:flex;flex-direction:column}
.toc ol a{display:flex;gap:10px;padding:7px 12px;border-left:2px solid var(--hairline);
  font:700 14px/1.35 var(--sans);color:var(--ink2);text-decoration:none}
.toc ol a:hover{color:var(--ink);border-left-color:var(--mint)}
.toc ol b{font:400 14px/1.35 var(--serif);color:var(--muted);min-width:18px}
.toc input{width:100%;padding:9px 12px;border:1px solid var(--hairline);border-radius:10px;
  background:var(--paper);font:500 14px/1.35 var(--sans);color:var(--ink);
  margin-bottom:10px}
.toc input::placeholder{color:var(--muted)}

.titlecard{border-radius:22px;padding:64px 40px 56px;display:flex;flex-direction:column;
  align-items:center;text-align:center;gap:14px;
  background:radial-gradient(ellipse 600px 260px at 50% 120%,
    var(--tank) 0%,var(--glow-2) 60%,var(--paper) 100%)}
.titlecard img{width:40px;height:40px;border-radius:10px}
.titlecard h1{font-size:clamp(38px,5vw,64px);line-height:1;letter-spacing:-.03em;
  margin-top:10px}
.titlecard .meta{font:700 14px/1.4 var(--sans);color:var(--muted)}
.tldr{padding:36px 4px 32px;border-bottom:2px dotted var(--hairline)}
.tldr p:first-child{font-size:19px;line-height:1.5;margin-bottom:14px}
.tldr b{color:var(--green)}
.tldr p:last-child{font-size:16px;color:var(--ink2);margin:0}

.doc{font:500 17px/1.65 var(--sans);color:var(--ink);min-width:0}
.doc h2{font-weight:500;font-size:clamp(24px,2.2vw,28px);line-height:1.2;
  letter-spacing:-.01em;margin:44px 0 14px;scroll-margin-top:24px}
.doc ul{margin:0 0 18px;padding-left:22px}
.doc li{margin:0 0 8px}
.doc strong{font-weight:800}
.doc hr{border:0;border-top:1px solid var(--hairline);margin:32px 0}
.doc-end{height:56px}

.pod{display:grid;grid-template-columns:1fr 1fr;gap:16px;margin:0 0 24px}
.pod>div{border-radius:18px;padding:20px 22px}
.pod .can{background:var(--card);border:2px solid var(--mint)}
.pod .cant{background:var(--inset);border:1px solid var(--hairline)}
.pod .label{margin-bottom:12px;font-size:11px}
.pod .can .label{color:var(--green)}
.pod ul{list-style:none;margin:0;padding:0;font:500 14.5px/1.5 var(--sans)}
.pod .can li{margin:0 0 8px;font-weight:800}
.pod .chips{display:flex;flex-wrap:wrap;gap:6px;margin:0;padding:0;list-style:none}
.pod .chips li{font:700 13.5px/1 var(--sans);color:var(--muted);
  text-decoration:line-through;background:var(--card);border:1px solid var(--hairline);
  border-radius:999px;padding:6px 10px;margin:0}
.pod .note{margin:12px 0 0;font:500 13.5px/1.5 var(--sans);color:var(--muted)}

/* --- support (2d) ---------------------------------------------------- */
.center-head{padding:150px 0 0;text-align:center;display:flex;flex-direction:column;
  align-items:center}
.center-head h1{font-size:clamp(40px,5.6vw,72px);line-height:1;letter-spacing:-.03em}
.center-head p{margin:18px 0 0;font:600 18px/1.5 var(--sans);color:var(--ink2);
  max-width:460px;text-wrap:pretty}
.tiles{padding:56px 0 0;display:flex;justify-content:center;gap:14px;flex-wrap:wrap}
.tile{width:230px;background:var(--card);border:1px solid var(--hairline);
  border-radius:18px;padding:22px 20px 24px;display:flex;flex-direction:column;
  align-items:center;text-align:center;gap:8px}
.tile .ic{width:34px;height:34px;border-radius:50%;background:var(--inset);
  display:flex;align-items:center;justify-content:center;margin-bottom:4px}
.tile.g .ic{background:var(--mint-soft)}
.tile .ic svg{width:17px;height:17px;stroke:var(--ink2);fill:none;stroke-width:1.7;
  stroke-linecap:round;stroke-linejoin:round}
.tile b{font:800 15px/1.3 var(--sans)}
.tile span{font:500 13.5px/1.5 var(--sans);color:var(--ink2)}
.pair{margin:72px auto 0;max-width:820px;display:grid;grid-template-columns:1fr 1fr;gap:16px}
.pair>div{background:var(--card);border:1px solid var(--hairline);border-radius:20px;
  padding:26px 26px 24px;display:flex;flex-direction:column;gap:10px}
.pair h2{display:flex;align-items:center;gap:10px;font:800 16px/1 var(--sans);
  font-family:var(--sans)}
.pair h2 i{width:18px;height:18px;border-radius:5px;background:var(--inset);display:block}
.pair h2 i.g{background:var(--mint-soft)}
.pair p{margin:0;font:500 15px/1.55 var(--sans);color:var(--ink2)}
.chip{align-self:flex-start;margin-top:6px;padding:8px 12px;border:1px solid var(--hairline);
  border-radius:8px;font:800 13px/1 var(--sans);color:var(--ink);text-decoration:none;
  transition:background 150ms cubic-bezier(.22,1,.36,1)}
.chip:hover{background:var(--inset)}
.notes{margin:64px auto 0;max-width:820px;display:grid;grid-template-columns:1fr 1fr;
  gap:40px;padding-bottom:40px;border-bottom:1px solid var(--hairline)}
.notes b{display:block;font:800 15px/1.3 var(--sans);margin-bottom:8px}
.notes p{margin:0 0 10px;font:500 14.5px/1.55 var(--sans);color:var(--ink2)}
.notes a{font:800 14.5px/1 var(--sans)}
.closer{padding:96px 0 0;display:flex;flex-direction:column;align-items:center;
  text-align:center;gap:20px}
.closer h2{font-size:clamp(34px,3.9vw,52px);line-height:1;letter-spacing:-.02em}

/* --- 404 ------------------------------------------------------------- */
.oops{padding:96px 0 0;position:relative;overflow:hidden}
.oops h1{font-size:clamp(40px,5.6vw,72px);line-height:1.05;letter-spacing:-.03em;
  max-width:720px;margin:12px 0 0}
.oops p{margin:18px 0 28px;font:500 17px/1.5 var(--sans);color:var(--ink2);max-width:520px}
.oops .sprout{position:absolute;right:60px;bottom:-30px;width:240px;pointer-events:none}
.oops .btns{position:relative;z-index:1}

/* --- footer ---------------------------------------------------------- */
.foot{margin-top:128px;padding:36px 0 40px;border-top:1px solid var(--hairline);
  display:flex;justify-content:space-between;align-items:flex-start;gap:40px;
  font:500 14px/1.55 var(--sans);color:var(--ink2)}
.foot .brand{display:flex;align-items:center;gap:8px;font:800 16px/1 var(--sans);
  color:var(--ink);text-decoration:none}
.foot .brand img{width:24px;height:24px;border-radius:6px}
.foot nav{display:flex;gap:64px}
.foot ul{list-style:none;margin:0;padding:0;display:flex;flex-direction:column;gap:10px}
.foot ul a{font-weight:700;color:var(--ink2);text-decoration:none}
.foot ul a:hover{color:var(--ink)}
.foot ul a.mail{color:var(--green)}
.foot .fine{max-width:300px;text-align:right}
.foot .fine span{color:var(--muted)}
.sheet .foot{margin-top:96px}

/* --- narrow ---------------------------------------------------------- */
@media(max-width:1080px){
  .shell{padding:0 40px}
  .sheet{margin:-80px 40px 0;padding:48px 40px 0;grid-template-columns:minmax(0,620px);
    gap:32px;justify-content:center}
  .toc{position:static;gap:16px}
  .toc .sections{display:none}
  .toc .docs{display:flex;gap:8px}
  .toc .docs a{border:1px solid var(--hairline);border-radius:999px;padding:8px 14px}
  .toc .docs [aria-current]{background:var(--inset)}
  .hero .sprout{right:20px;width:170px}
}
@media(max-width:900px){
  .claimblock .three,.twoup,.notlist,.pair,.notes{grid-template-columns:1fr}
  .sync{grid-template-columns:minmax(0,1fr)}
  .sync{gap:36px}
  .notlist{gap:24px}
  .claimblock .three{gap:24px}
}
@media(max-width:640px){
  body{font-size:16px}
  .shell{padding:0 20px}
  .nav{gap:14px;padding:8px 8px 8px 12px;flex-wrap:wrap;justify-content:center;
    max-width:calc(100vw - 24px)}
  .nav ul{gap:14px}
  .nav ul i{display:none}
  .hero-in{margin-top:64px;gap:18px}
  .hero p{font-size:18px}
  .hero .sprout{position:static;display:block;margin:28px auto -6px;width:150px}
  .hero{padding-bottom:0}
  .btns{width:100%;flex-direction:column}
  .btn{text-align:center}
  .claimblock{padding:40px 24px 36px;border-radius:20px;margin-top:48px}
  .claimblock .three{margin-top:32px}
  .section,.notlist{padding-top:72px}
  .install{margin-top:72px;padding:32px 0}
  .half{padding:24px;border-radius:20px}
  .frame{margin:24px -26px -26px;height:200px}
  .sync{margin-top:72px;padding:32px 24px;border-radius:20px}
  .box.laptop{width:118px;height:88px;font-size:13px}
  .link{width:104px}
  .box.phone{width:60px;height:108px;font-size:12px}
  .panel{padding:44px 24px 40px;border-radius:20px}
  .band{padding-bottom:96px;gap:40px}
  .sheet{margin:-64px 12px 0;padding:32px 20px 0;border-radius:20px 20px 0 0}
  .titlecard{padding:40px 20px 36px;border-radius:16px}
  .doc h2{margin:32px 0 12px}
  .pod{grid-template-columns:1fr}
  .center-head{padding-top:72px}
  .closer{padding-top:64px}
  .foot{flex-direction:column;gap:28px;margin-top:72px}
  .foot nav{gap:40px}
  .foot .fine{text-align:left;max-width:none}
  .oops{padding-top:56px}
  .oops .sprout{position:static;display:block;margin:32px auto -30px;width:160px}
}
"""

FIND_JS = """
// The find field only exists when this runs, so nothing is broken without it.
(function(){
  var list = document.getElementById('toc-list');
  if (!list) return;
  var box = document.createElement('input');
  box.type = 'search';
  box.placeholder = 'Find in this policy';
  box.setAttribute('aria-label', 'Find a section in this policy');
  list.parentNode.insertBefore(box, list);
  box.addEventListener('input', function(){
    var q = box.value.trim().toLowerCase();
    var rows = list.children, hit = 0;
    for (var i = 0; i < rows.length; i++) {
      var on = !q || rows[i].textContent.toLowerCase().indexOf(q) > -1;
      rows[i].hidden = !on;
      if (on) hit++;
    }
    list.setAttribute('data-empty', hit ? 'no' : 'yes');
  });
})();
"""

MARK = '<img src="/img/mark.svg" alt="" width="24" height="24">'
DOTS = [("#57C79B", "Privacy", "/privacy/"), ("#FFC24B", "Terms", "/terms/"),
        ("#FF8A7E", "Support", "/support/")]


def nav(active: str = "") -> str:
    items = "".join(
        f'<li><a href="{href}"{" aria-current=\"page\"" if label.lower() == active else ""}>'
        f'<i style="background:{dot}"></i>{label}</a></li>'
        for dot, label, href in DOTS)
    return f"""<div class="navbar"><nav class="nav" aria-label="Main">
<a class="brand" href="/">{MARK}Prepkin</a>
<ul>{items}</ul>
<a class="btn btn-dark btn-sm" href="{STORE_URL}">Add to Chrome</a>
</nav></div>"""


FOOT = f"""<footer class="foot">
<a class="brand" href="/">{MARK}Prepkin</a>
<nav aria-label="Footer">
<ul><li><a href="/privacy/">Privacy</a></li><li><a href="/terms/">Terms</a></li>
<li><a href="/support/">Support</a></li></ul>
<ul><li><a href="{STORE_URL}">Add to Chrome</a></li>
<li><a href="{APP_URL}">Get the iPhone app</a></li>
<li><a class="mail" href="mailto:{MAIL}">{MAIL}</a></li></ul>
</nav>
<p class="fine">Not made or endorsed by Instructure or by any school.<br>
<span>No cookies. No analytics. Nothing loads from anywhere but prepkin.com.</span></p>
</footer>"""


def page(title: str, desc: str, body: str, script: str = "", cls: str = "") -> str:
    tag = f' class="{cls}"' if cls else ""
    js = f"<script>{script}</script>" if script else ""
    return f"""<!doctype html>
<html lang="en"><head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{html.escape(title)}</title>
<meta name="description" content="{html.escape(desc)}">
<meta name="color-scheme" content="{"light dark" if _pal["dark"] else ("dark" if PALETTE == "spotify" else "light")}">
<link rel="icon" href="/img/mark.svg" type="image/svg+xml">
<style>{CSS}</style>
</head><body{tag}>
<a class="skip" href="#main">Skip to content</a>
{body}
{js}
</body></html>
"""


# --- markdown --------------------------------------------------------------

def inline(text: str) -> str:
    t = html.escape(text, quote=False)
    t = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r'<a href="\2">\1</a>', t)
    t = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", t)
    t = re.sub(r"`([^`]+)`", r"<code>\1</code>", t)
    return t


def slug(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


# The ids store reviewers may be sent to. Kept stable even if a heading is
# reworded, which is why they are spelled out instead of slugified.
PRIVACY_IDS = {
    "The short version": "short-version",
    "What it reads": "what-it-reads",
    "What leaves your laptop": "what-leaves",
    "Where your coursework goes, and who can read it": "where-it-goes",
    "The weekly pod, and what strangers can see": "the-pod",
    "How long it is kept": "how-long",
    "Who it is for": "who-for",
    "Third parties": "third-parties",
    "Your choices": "your-choices",
    "Changes": "changes",
    "Contact": "contact",
}


def md_to_html(md: str, ids: dict) -> tuple[str, list]:
    """Enough markdown for these two documents. Not a general converter."""
    out, para, items, heads = [], [], None, []

    def flush_para():
        if para:
            out.append(f"<p>{inline(' '.join(para))}</p>")
            para.clear()

    def flush_list():
        nonlocal items
        if items:
            out.append("<ul>" + "".join(f"<li>{inline(i)}</li>" for i in items) + "</ul>")
            items = None

    for raw in md.split("\n"):
        line = raw.rstrip()
        if not line.strip():
            flush_para(); flush_list(); continue
        if line.startswith("---"):
            flush_para(); flush_list(); out.append("<hr>"); continue
        m = re.match(r"^(#{1,4}) +(.*)$", line)
        if m:
            flush_para(); flush_list()
            text = m.group(2)
            hid = ids.get(text, slug(text))
            heads.append((hid, text))
            out.append(f'<h{len(m.group(1))} id="{hid}">{inline(text)}</h{len(m.group(1))}>')
            continue
        m = re.match(r"^[-*] +(.*)$", line)
        if m:
            flush_para()
            if items is None:
                items = []
            items.append(m.group(1))
            continue
        # A wrapped line inside a bullet belongs to that bullet, not to a new
        # paragraph. Markdown marks it by indenting; without this the policy
        # breaks mid-sentence.
        if items is not None and raw[:1] in (" ", "\t"):
            items[-1] += " " + line.strip()
            continue
        flush_list()
        para.append(line.strip())
    flush_para(); flush_list()
    return "\n".join(out), heads


def split_source(md: str) -> tuple[str, str, str]:
    """Drop the 'this file is the text' note, pull the date, split off the TLDR."""
    md = re.sub(r"\*\*This file is the text\..*?(?=^Last updated:)", "", md,
                flags=re.S | re.M)
    m = re.search(r"^Last updated: (.+)$", md, flags=re.M)
    updated = m.group(1).strip() if m else ""
    md = re.sub(r"^Last updated: .+$", "", md, flags=re.M)
    md = re.sub(r"^# .*$", "", md, count=1, flags=re.M)
    md = md.strip().lstrip("-").strip()
    m = re.search(r"^## The short version\s*(.*?)(?=^## )", md, flags=re.S | re.M)
    tldr = m.group(1).strip() if m else ""
    rest = md[m.end():].strip() if m else md
    return tldr, rest, updated


# The four things a pod shows, and the fifteen it cannot. Both lists are the
# policy's own words; the block is a summary of the paragraphs under it.
POD_CAN = ["A nickname the app picked", "Your fish", "Its stars",
           "The coins you earned that week"]
POD_CANT = ["coursework", "course names", "grades", "assignments", "due dates",
            "school", "Canvas site", "email", "real name", "student ID",
            "location", "your device", "when you last opened the app",
            "whether you are online", "your balance"]

POD_BLOCK = f"""<div class="pod">
<div class="can"><p class="label">They can see · four things</p>
<ul>{"".join(f"<li>{i}</li>" for i in POD_CAN)}</ul></div>
<div class="cant"><p class="label">They cannot see</p>
<ul class="chips">{"".join(f"<li>{i}</li>" for i in POD_CANT)}</ul>
<p class="note">No message box, no profile, no way to add a person.</p></div>
</div>"""


def legal(slug_name: str, src: str, title: str, sub: str, desc: str,
          find: bool, pod: bool) -> None:
    tldr_md, rest_md, updated = split_source((ROOT / src).read_text(encoding="utf-8"))
    ids = PRIVACY_IDS if slug_name == "privacy" else {}
    tldr_html, _ = md_to_html(tldr_md, ids)
    doc_html, heads = md_to_html(rest_md, ids)

    if pod:
        doc_html = doc_html.replace("about each of them:</p>",
                                    "about each of them:</p>\n" + POD_BLOCK, 1)
    # "TLDR:" leads the first paragraph, per 2c.
    tldr_html = tldr_html.replace("<p>", '<p><b>TLDR:</b> ', 1)

    rows = "".join(
        f'<li><a href="#{hid}"><b>{n}</b>{html.escape(text)}</a></li>'
        for n, (hid, text) in enumerate(heads, start=2))
    contents = f"""<div class="sections">
<p class="label">On this page</p>
<ol id="toc-list"><li><a href="#short-version"><b>1</b>The short version</a></li>{rows}</ol>
</div>"""

    docs = "".join(
        f'<a href="{href}"{" aria-current=\"page\"" if key == slug_name else ""}>{label}</a>'
        for key, href, label in [("privacy", "/privacy/", "Privacy policy"),
                                 ("terms", "/terms/", "Terms of Service")])

    body = f"""<div class="band">{nav(slug_name)}
<p class="label">Prepkin · legal</p></div>
<div class="sheet">
<aside class="toc" aria-label="Contents">
<div><p class="label">Documents</p><div class="docs">{docs}</div></div>
{contents}
</aside>
<div>
<main id="main" class="doc">
<div class="titlecard"><img src="/img/mark.svg" alt="" width="40" height="40">
<h1>{html.escape(title)}</h1>
<p class="meta">{html.escape(sub)} · Last updated {html.escape(updated)}</p></div>
<section class="tldr" id="short-version">{tldr_html}</section>
{doc_html}
<div class="doc-end"></div>
</main>
{FOOT}
</div>
</div>"""
    write(f"{slug_name}/index.html",
          page(f"{title} — Prepkin", desc, body, FIND_JS if find else ""))


def write(rel: str, text: str) -> None:
    path = OUT / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")
    print(f"  {rel}")


# --- pages -----------------------------------------------------------------

def home() -> None:
    labels = json.loads(SHOT_LABELS.read_text()) if SHOT_LABELS.exists() else {}
    wide = ""
    if SHOT_WIDE.exists():
        after = html.escape(labels.get("hero", "After, with Prepkin"))
        wide = ('<figure class="shotwide"><figcaption><span>Before</span>'
                f'<span>{after}</span></figcaption>'
                '<img src="/img/canvas-before-after.webp" '
                f'alt="The same Canvas dashboard: plain on the left, with Prepkin on the right ({after})." '
                'width="1120" height="480"></figure>')
    card = ""
    if SHOT_CARD.exists():
        what = html.escape(labels.get("card", "the Prepkin skin"))
        card = ('<div class="frame shot"><img src="/img/canvas-card.webp" '
                f'alt="A Canvas dashboard wearing Prepkin\'s {what}." '
                'width="520" height="260"></div>')

    three = [
        ("Pure CSS", "Over Canvas's own markup. It uses the login already in your "
                     "browser and never asks for a password."),
        ("Zero requests", "No fonts, images, scripts or analytics from anywhere else. "
                          "This site keeps the same rule."),
        ("Every change listed", "What was changed and put back is shown to you on your "
                                "laptop. It is not sent anywhere."),
    ]
    nots = ["Not a hunger meter. Sprout does not eat.",
            "Not an account. There is nothing to sign up for.",
            "Not tracking. No analytics, no ads, no cookies.",
            "Not a promise about your grades.",
            "Not test prep.",
            "Not made or endorsed by Instructure or by any school."]

    body = f"""<header class="hero">{nav()}
<div class="hero-in">
<h1>Canvas, but <em>calm.</em></h1>
<p>A Chrome extension that quiets your Canvas page with pure CSS. It reads nothing,
sends nothing.</p>
<div class="btns"><a class="btn btn-dark" href="{STORE_URL}">Add to Chrome</a>
<a class="btn btn-ghost" href="{APP_URL}">Get the iPhone app</a></div>
<p class="works">Works in Chrome, Edge, Brave and Arc.</p>
</div>
<img class="sprout" src="/img/sprout.png" alt="" width="535" height="334">
</header>

<main id="main"><div class="shell">
{wide}
<section class="claimblock" aria-labelledby="skin">
<p class="label">The skin</p>
<h2 id="skin">Reads nothing, sends nothing.</h2>
<dl class="three">{"".join(f"<div><dt>{t}</dt><dd>{d}</dd></div>" for t, d in three)}</dl>
</section>

<section class="section" aria-labelledby="halves">
<div class="section-head"><h2 id="halves">Two halves. Each one works alone.</h2>
<p>They pair only if you pair them.</p></div>
<div class="twoup">
<div class="half pick"><span class="pip">Start here</span>
<p class="label">On your laptop</p>
<h3>A Canvas you can look at at 11pm.</h3>
<p>Quieter page. A small buddy panel and a focus timer on Canvas itself. Free.</p>
{card}</div>
<div class="half"><span class="pip">Optional</span>
<p class="label">On your phone</p>
<h3>A fish called Sprout.</h3>
<p>Finish a Canvas task, earn 30 coins. Coins buy tank scenes, costumes and looks.
Sprout does not eat, so there is nothing to keep alive.</p>
<div class="frame tank"><img src="/img/sprout.png" alt="" width="535" height="334"></div>
</div>
</div></section>

<section class="sync" aria-labelledby="pairing">
<div><p class="label">If you pair them</p>
<h2 id="pairing">The pairing does send something. Here is exactly what.</h2>
<p>Your coursework list and your course grades, to your own phone, only after you
pair. Never your password, name, email or student ID. Never anything from another
site. Unpair, and the row is deleted.</p>
<a class="more" href="/privacy/">Read the full privacy policy →</a></div>
<div class="wire" aria-hidden="true">
<div class="box laptop">Your laptop</div>
<div class="link"><span>coursework list<br>course grades</span><hr>
<span>only after you pair</span></div>
<div class="box phone">Your<br>phone</div>
</div></section>

<section class="install" aria-labelledby="install">
<div class="panel">
<h2 id="install">Add it to Chrome. Open Canvas.</h2>
<p>The page is already quieter. Turn it off any time and Canvas goes back to how it was.</p>
<p class="browsers"><b>Chrome</b><em>·</em><b>Edge</b><em>·</em><b>Brave</b><em>·</em><b>Arc</b></p>
<div class="btns"><a class="btn btn-dark" href="{STORE_URL}">Add to Chrome</a>
<a class="btn btn-ghost" href="{APP_URL}">Get the iPhone app</a></div>
<p class="fine">Free. No account. Not made or endorsed by Instructure or by any school.</p>
</div></section>

<section class="notlist" aria-labelledby="isnot">
<h2 id="isnot">What Prepkin is not.</h2>
<ul>{"".join(f"<li>{n}</li>" for n in nots)}</ul>
</section>
{FOOT}
</div></main>"""
    write("index.html", page(
        "Prepkin — Canvas, but calm",
        "A pure-CSS Canvas skin for Chrome and an iPhone app with a fish. "
        "The skin reads nothing and sends nothing.", body))


ENVELOPE = ('<svg viewBox="0 0 24 24" aria-hidden="true"><rect x="3" y="5" width="18" '
            'height="14" rx="2.5"/><path d="M3.5 7 12 13l8.5-6"/></svg>')
SHIELD = ('<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 3l7 3v5.5c0 4.3-3 '
          '7.7-7 9-4-1.3-7-4.7-7-9V6z"/><path d="M9 12.2l2.1 2.1L15.2 10"/></svg>')
TRASH = ('<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M4.5 7h15"/><path '
         'd="M9 7V5.2A1.2 1.2 0 0 1 10.2 4h3.6A1.2 1.2 0 0 1 15 5.2V7"/><path '
         'd="M6.5 7l.8 11.3A1.7 1.7 0 0 0 9 20h6a1.7 1.7 0 0 0 1.7-1.7L17.5 7"/></svg>')


def support() -> None:
    tiles = [(ENVELOPE, "", "Email", "We read them all, we promise."),
             (SHIELD, " g", "Privacy", "Read it first. It is short and says everything."),
             (TRASH, "", "Delete", "Disconnect in the app. The row goes immediately.")]
    body = f"""{nav("support")}
<main id="main"><div class="shell">
<div class="center-head"><h1>How can we help?</h1>
<p>Questions about Canvas, the app, privacy, or anything else. One person makes
Prepkin and the same person answers.</p></div>

<div class="tiles">{"".join(
    f'<div class="tile{g}"><span class="ic">{ic}</span><b>{t}</b><span>{d}</span></div>'
    for ic, g, t, d in tiles)}</div>

<div class="pair">
<div><h2><i></i>Chrome</h2>
<p>If a Canvas page looks wrong, turn the look off in the popup. The page goes back
to Canvas as it was.</p>
<a class="chip" href="{STORE_URL}">Get the extension ›</a></div>
<div><h2><i class="g"></i>iPhone</h2>
<p>Disconnect deletes your coursework row right away. Forget me in the league deletes
your league identity.</p>
<a class="chip" href="{APP_URL}">Get the app ›</a></div>
</div>

<div class="notes">
<div><b>Writing in</b><p>Say which half you are writing about, iPhone or Chrome, your
school's Canvas address, and what you expected to happen.</p></div>
<div><b>Anything else</b><p>Deletion requests, a school asking about the extension, or
something that just seems off.</p>
<a href="mailto:{MAIL}">{MAIL}</a></div>
</div>

<div class="closer"><h2>Questions?</h2>
<a class="btn btn-dark" href="mailto:{MAIL}">Email {MAIL}</a></div>
{FOOT}
</div></main>"""
    write("support/index.html", page(
        "Support — Prepkin",
        "How to reach Prepkin, and how to delete your data.", body))


def notfound() -> None:
    body = f"""{nav()}
<main id="main"><div class="shell"><div class="oops">
<p class="label">404</p>
<h1>Nothing lives<br>at this address.</h1>
<p>The page may have moved. Everything on this site is one of four.</p>
<div class="btns"><a class="btn btn-dark" href="/">Home</a>
<a class="btn btn-ghost" href="/privacy/">Privacy</a>
<a class="btn btn-ghost" href="/terms/">Terms</a>
<a class="btn btn-ghost" href="/support/">Support</a></div>
<img class="sprout" src="/img/sprout.png" alt="" width="535" height="334">
</div>{FOOT}</div></main>"""
    write("404.html", page("Not found — Prepkin", "Page not found.", body))


def redirects() -> None:
    for ch in CHANNELS:
        body = f"""{nav()}
<main id="main"><div class="shell"><div class="center-head">
<h1>Opening the Chrome Web Store</h1>
<p>If nothing happens, <a href="{STORE_URL}">tap here</a>.</p></div></div></main>"""
        doc = page(f"Prepkin — {ch}", "Redirecting to the Chrome Web Store.", body)
        doc = doc.replace("<title>",
                          f'<meta http-equiv="refresh" content="0;url={STORE_URL}">\n'
                          '<meta name="robots" content="noindex">\n<title>', 1)
        write(f"go/{ch}/index.html", doc)
    write("go/index.html", notfound_body())


def notfound_body() -> str:
    body = f"""{nav()}
<main id="main"><div class="shell"><div class="oops">
<h1>Nothing here.</h1>
<p><a href="/">Start at the front</a>.</p></div>{FOOT}</div></main>"""
    return page("Prepkin", "Nothing here.", body)


def main() -> None:
    print("building site/")
    home()
    legal("privacy", "bridge/PRIVACY.md", "Privacy policy", "Prepkin for Canvas",
          "What Prepkin reads, what leaves your laptop, who can read it, and how "
          "long it is kept.", find=True, pod=True)
    legal("terms", "bridge/TERMS.md", "Terms of Service", "Prepkin",
          "The terms for the Prepkin Chrome extension and iPhone app.",
          find=False, pod=False)
    support()
    notfound()
    redirects()

    print()
    for name, path in [("wide hero shot", SHOT_WIDE), ("two-up card shot", SHOT_CARD)]:
        if not path.exists():
            print(f"no {name} at {path.relative_to(ROOT)} — that block is left out")
    print(f"STORE_URL is still a placeholder: {STORE_URL}")
    print(f"APP_URL is still a placeholder:   {APP_URL}")
    print("Change both in site/build.py the day the listings go live, then rerun.")


if __name__ == "__main__":
    main()

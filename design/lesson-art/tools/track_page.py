#!/usr/bin/env python3
"""Build a click-through review page for one track, straight from the app's own data:
lessons.json for the words and the imagesets for the pictures (base64, so the page is one
file). Output: design/lesson-art/pages/<track>.html (gitignored; a few MB).

  python3 design/lesson-art/tools/track_page.py work
"""
import base64, html, json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import plan as P

REPO = os.path.dirname(os.path.dirname(P.ROOT))
ASSETS = os.path.join(REPO, "ios", "Resources", "Assets.xcassets")
LESSONS = os.path.join(REPO, "ios", "Resources", "Content", "lessons.json")
PAGES = os.path.join(P.ROOT, "pages")
NAMES = {"finance": "Personal finance", "philosophy": "Philosophy", "study": "Study skills",
         "psychology": "Psychology", "people": "People skills", "work": "Work", "health": "Health"}

def img_uri(name):
    d = os.path.join(ASSETS, name + ".imageset")
    for f in os.listdir(d):
        if f.endswith(".jpg") or f.endswith(".png"):
            mime = "image/jpeg" if f.endswith(".jpg") else "image/png"
            return f"data:{mime};base64," + base64.b64encode(open(os.path.join(d, f), "rb").read()).decode()
    raise SystemExit(f"no image in {d}")

def build(track):
    lessons = [l for l in json.load(open(LESSONS)) if l["track"] == track]
    if not lessons: raise SystemExit(f"no lessons in track {track!r}")
    data = []
    for l in lessons:
        cards = []
        for c in l["cards"]:
            c = dict(c)
            if c["kind"] == "image": c["src"] = img_uri(c.pop("image"))
            cards.append(c)
        data.append({"id": l["id"], "title": l["title"], "blurb": l["blurb"], "takeaway": l["takeaway"],
                     "minutes": l["minutes"], "cards": cards})
    name = NAMES.get(track, track.capitalize())
    page = TEMPLATE.replace("__TITLE__", html.escape(f"{name} lessons")).replace("__TRACK__", html.escape(name)) \
                   .replace("__COUNT__", str(len(lessons))).replace("__DATA__", json.dumps(data).replace("</", "<\\/"))
    os.makedirs(PAGES, exist_ok=True)
    out = os.path.join(PAGES, f"{track}.html")
    open(out, "w").write(page)
    print(f"wrote {out}  ({os.path.getsize(out) // 1024} KB, {len(lessons)} lessons)")
    return out

TEMPLATE = r"""<title>__TITLE__</title>
<style>
:root{--paper:#FBF7F0;--ink:#2E2622;--muted:#96877F;--faint:#E8E0D2;--coral:#FF6F61;--coral-deep:#E4735F;--mint:#57C79B;--white:#FFFFFF;--card-ink:#2E2622;}
*{box-sizing:border-box}
body{background:#EFE9DF;color:var(--ink);font-family:ui-rounded,"SF Pro Rounded","Nunito",system-ui,-apple-system,sans-serif;margin:0;min-height:100vh}
.wrap{max-width:1040px;margin:0 auto;padding:28px 20px 60px}
header{display:flex;align-items:baseline;gap:14px;flex-wrap:wrap;margin-bottom:18px}
h1{font-size:22px;margin:0;font-weight:800;letter-spacing:-.01em}
header .n{color:var(--muted);font-weight:700;font-size:14px}
.picker{display:flex;gap:8px;flex-wrap:wrap;margin-bottom:22px}
.picker button{border:0;background:var(--white);color:var(--ink);font:inherit;font-weight:700;font-size:14px;padding:9px 14px;border-radius:999px;cursor:pointer;box-shadow:0 1px 0 rgba(46,38,34,.08)}
.picker button[aria-pressed="true"]{background:var(--ink);color:var(--paper)}
.picker button:focus-visible,.cta:focus-visible,.opt:focus-visible,.mode button:focus-visible{outline:3px solid var(--coral);outline-offset:2px}
.stage{display:grid;grid-template-columns:402px 1fr;gap:28px;align-items:start}
@media (max-width:760px){.stage{grid-template-columns:1fr}}
.phone{width:402px;height:874px;background:var(--paper);border-radius:44px;box-shadow:0 20px 60px rgba(46,38,34,.18),0 0 0 8px #1d1a18;overflow:hidden;position:relative;display:flex;flex-direction:column}
.top{padding:58px 24px 8px;display:flex;align-items:center;justify-content:space-between}
.top .t{font-size:13px;font-weight:800;color:var(--muted);letter-spacing:.06em;text-transform:uppercase}
.dots{display:flex;gap:5px;padding:0 24px 10px}
.dots i{flex:1;height:4px;border-radius:2px;background:var(--faint)}
.dots i.on{background:var(--ink)}
.card{flex:1;overflow:auto;padding:4px 20px 0}
.card img{display:block;width:100%;aspect-ratio:4/3;object-fit:cover;border-radius:22px;background:var(--faint)}
.eyebrow{margin:20px 4px 8px;font-size:12px;font-weight:800;letter-spacing:.1em;text-transform:uppercase;color:var(--coral-deep)}
.body{margin:0 4px;font-size:19px;line-height:1.38;font-weight:600}
.key{margin:6px 0 0;background:var(--ink);color:var(--paper);border-radius:26px;padding:40px 28px;min-height:420px;display:flex;flex-direction:column;justify-content:center}
.key .eyebrow{color:#C9B9A9;margin:0 0 14px}
.key p{font-size:26px;line-height:1.3;font-weight:800;margin:0;text-wrap:balance}
.check .q{font-size:21px;font-weight:800;line-height:1.3;margin:10px 4px 18px}
.opt{display:block;width:100%;text-align:left;border:2px solid var(--faint);background:var(--white);border-radius:18px;padding:16px 18px;font:inherit;font-size:16px;font-weight:700;color:var(--ink);margin-bottom:10px;cursor:pointer}
.opt.right{border-color:var(--mint);background:#DFF3E9}
.opt.wrong{border-color:var(--coral);background:#FFE9E5}
.why{margin:8px 4px 0;font-size:15px;line-height:1.4;color:var(--muted);font-weight:600;display:none}
.why.on{display:block}
.foot{padding:12px 20px 30px}
.cta{width:100%;border:0;border-radius:999px;background:var(--coral);color:#fff;font:inherit;font-weight:800;font-size:17px;padding:16px;cursor:pointer}
.cta.done{background:var(--mint)}
aside{background:var(--white);border-radius:20px;padding:22px 24px;font-size:15px;line-height:1.5}
aside h2{margin:0 0 6px;font-size:17px}
aside .blurb{color:var(--muted);font-weight:600;margin:0 0 14px}
aside dl{margin:0;display:grid;grid-template-columns:auto 1fr;gap:6px 14px;font-weight:600}
aside dt{color:var(--muted)}
.mode{display:flex;gap:8px;margin-top:16px}
.mode button{border:2px solid var(--faint);background:var(--white);font:inherit;font-weight:700;font-size:13px;padding:7px 12px;border-radius:999px;cursor:pointer}
.mode button[aria-pressed="true"]{border-color:var(--ink)}
.all{display:none;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:18px}
.all.on{display:grid}
.all .mini{background:var(--paper);border-radius:20px;padding:14px;box-shadow:0 1px 0 rgba(46,38,34,.08)}
.all .mini img{width:100%;aspect-ratio:4/3;object-fit:cover;border-radius:14px;display:block}
.all .mini .eyebrow{margin:12px 2px 6px}
.all .mini .body{font-size:15px}
.all .mini .num{font-size:12px;color:var(--muted);font-weight:800}
.all .mini.k{background:var(--ink);color:var(--paper)}
kbd{font:inherit;font-size:12px;background:var(--faint);padding:1px 6px;border-radius:6px}
</style>
<div class="wrap">
<header><h1>__TRACK__</h1><span class="n">__COUNT__ lessons · tap Continue or press <kbd>→</kbd></span></header>
<div class="picker" id="picker" role="tablist"></div>
<div class="stage">
  <div class="phone" id="phone">
    <div class="top"><span class="t" id="ttl"></span><span class="t" id="pos"></span></div>
    <div class="dots" id="dots"></div>
    <div class="card" id="card"></div>
    <div class="foot"><button class="cta" id="cta">Continue</button></div>
  </div>
  <div>
    <aside>
      <h2 id="aTitle"></h2>
      <p class="blurb" id="aBlurb"></p>
      <dl><dt>Takeaway</dt><dd id="aTake"></dd><dt>Cards</dt><dd id="aCards"></dd><dt>Words</dt><dd id="aWords"></dd></dl>
      <div class="mode"><button id="mPhone" aria-pressed="true">One card at a time</button><button id="mAll" aria-pressed="false">Every card</button></div>
    </aside>
    <div class="all" id="all" style="margin-top:18px"></div>
  </div>
</div>
</div>
<script>
const DATA = __DATA__;
let li = 0, ci = 0, answered = false;
const $ = id => document.getElementById(id);
function esc(s){return s.replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]))}
function words(l){return l.cards.reduce((n,c)=>n+((c.body||'')+' '+(c.question||'')+' '+(c.why||'')).trim().split(/\s+/).filter(Boolean).length,0)}
function picker(){
  $('picker').innerHTML = DATA.map((l,i)=>`<button role="tab" aria-pressed="${i===li}" data-i="${i}">${esc(l.title)}</button>`).join('');
  $('picker').querySelectorAll('button').forEach(b=>b.onclick=()=>{li=+b.dataset.i;ci=0;render()});
}
function render(){
  const l = DATA[li], c = l.cards[ci]; answered=false;
  $('picker').querySelectorAll('button').forEach((b,i)=>b.setAttribute('aria-pressed',i===li));
  $('ttl').textContent = l.title; $('pos').textContent = `${ci+1} / ${l.cards.length}`;
  $('dots').innerHTML = l.cards.map((_,i)=>`<i class="${i<=ci?'on':''}"></i>`).join('');
  let h='';
  if(c.kind==='image') h=`<img src="${c.src}" alt=""><div class="eyebrow">${esc(c.eyebrow)}</div><p class="body">${esc(c.body)}</p>`;
  else if(c.kind==='key') h=`<div class="key"><div class="eyebrow">The big idea</div><p>${esc(c.body)}</p></div>`;
  else h=`<div class="check"><div class="eyebrow">Check</div><p class="q">${esc(c.question)}</p>${c.choices.map((o,i)=>`<button class="opt" data-i="${i}">${esc(o)}</button>`).join('')}<p class="why" id="why">${esc(c.why)}</p></div>`;
  $('card').innerHTML = h; $('card').scrollTop = 0;
  $('card').querySelectorAll('.opt').forEach(b=>b.onclick=()=>{if(answered)return;answered=true;const i=+b.dataset.i;b.classList.add(i===c.answer?'right':'wrong');$('card').querySelectorAll('.opt')[c.answer].classList.add('right');$('why').classList.add('on')});
  const last = ci===l.cards.length-1;
  $('cta').textContent = last ? (li<DATA.length-1?'Finish · next lesson':'Finish') : 'Continue';
  $('cta').className = 'cta'+(last?' done':'');
  $('aTitle').textContent=l.title; $('aBlurb').textContent=l.blurb; $('aTake').textContent=l.takeaway;
  $('aCards').textContent=`${l.cards.length} (${l.cards.filter(c=>c.kind==='image').length} pictures, key, check)`; $('aWords').textContent=words(l);
  $('all').innerHTML = l.cards.map((c,i)=>{
    if(c.kind==='image') return `<div class="mini"><img src="${c.src}" alt=""><div class="num">${i+1}</div><div class="eyebrow">${esc(c.eyebrow)}</div><p class="body">${esc(c.body)}</p></div>`;
    if(c.kind==='key') return `<div class="mini k"><div class="num">${i+1}</div><div class="eyebrow" style="color:#C9B9A9">The big idea</div><p class="body">${esc(c.body)}</p></div>`;
    return `<div class="mini"><div class="num">${i+1}</div><div class="eyebrow">Check</div><p class="body">${esc(c.question)}</p><ul style="padding-left:18px;font-size:14px;font-weight:600">${c.choices.map((o,j)=>`<li${j===c.answer?' style="color:#3E9E78"':''}>${esc(o)}</li>`).join('')}</ul><p style="font-size:13px;color:#96877F;font-weight:600">${esc(c.why)}</p></div>`;
  }).join('');
}
function next(){const l=DATA[li]; if(ci<l.cards.length-1){ci++} else if(li<DATA.length-1){li++;ci=0} else {ci=0} render()}
$('cta').onclick=next;
document.addEventListener('keydown',e=>{if(e.key==='ArrowRight')next(); if(e.key==='ArrowLeft'&&ci>0){ci--;render()}});
$('mPhone').onclick=()=>{$('all').classList.remove('on');$('phone').style.display='';$('mPhone').setAttribute('aria-pressed',true);$('mAll').setAttribute('aria-pressed',false)};
$('mAll').onclick=()=>{$('all').classList.add('on');$('mAll').setAttribute('aria-pressed',true);$('mPhone').setAttribute('aria-pressed',false)};
picker(); render();
</script>
"""

if __name__ == "__main__":
    build(sys.argv[1])

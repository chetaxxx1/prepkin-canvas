"""For chosen families: find the twelve icons (six nav + six row types), download them, draw a sheet.
   python3 sets.py <slug> [<slug> ...]   -> sets/<slug>/*.svg, sets/sheet.html"""
import json, os, sys, time, urllib.request, urllib.parse, html
K = os.environ['SL_KEY']
BASE = 'https://public-api.streamlinehq.com/v1/'
def get(path, raw=False):
    req = urllib.request.Request(BASE + path, headers={'x-api-key': K, 'accept': 'image/svg+xml' if raw else 'application/json'})
    for attempt in range(4):
        try:
            r = urllib.request.urlopen(req, timeout=30)
            return r.read().decode() if raw else json.load(r)
        except urllib.error.HTTPError as e:
            if e.code == 429: print('429, waiting'); time.sleep(90); continue
            return None
    return None

# concept -> (queries, preferred name substrings in order)
CONCEPTS = {
  'dashboard': (['dashboard', 'home', 'grid'], ['dashboard', 'layout', 'home', 'grid']),
  'courses':   (['book', 'graduation cap'], ['book', 'graduation']),
  'calendar':  (['calendar'], ['calendar']),
  'inbox':     (['inbox', 'mail'], ['inbox', 'mail', 'envelope']),
  'history':   (['clock', 'history'], ['clock', 'history', 'time']),
  'help':      (['help question', 'question'], ['help', 'question']),
  # the row types
  'page':      (['document', 'file text'], ['document', 'file', 'page']),
  'assignment':(['pencil', 'edit'], ['pencil', 'edit', 'write']),
  'quiz':      (['checklist', 'check'], ['check', 'list', 'task']),
  'discussion':(['chat bubble', 'chat'], ['chat', 'bubble', 'message', 'comment']),
  'file':      (['paperclip', 'attachment'], ['paperclip', 'attach', 'clip']),
  'link':      (['link', 'chain'], ['link', 'chain']),
}
BAD = ['off', 'remove', 'delete', 'add', 'plus', 'minus', 'lock', 'download', 'upload', 'warning', 'alert', 'search', 'setting', 'user', 'star', 'heart', 'money', 'dollar', 'cancel', 'x ', 'slash', 'fire', 'flight', 'refresh', 'edit calendar', 'clear']

def pick(slug, key):
    queries, prefs = CONCEPTS[key]
    seen = []
    for q in queries:
        r = get('search/family/%s?%s' % (slug, urllib.parse.urlencode({'query': q, 'limit': 20})))
        for x in (r or {}).get('results', []):
            if x['hash'] not in [s['hash'] for s in seen]: seen.append(x)
        time.sleep(0.05)
    def score(x):
        n = x['name'].lower()
        s = 0
        for i, p in enumerate(prefs):
            if p in n: s += 100 - i * 10; break
        if any(b in n for b in BAD): s -= 60
        s -= len(n.split())  # the plainest name wins
        return -s
    seen.sort(key=score)
    return seen[0] if seen else None

def slim(s):
    import re
    s = re.sub(r'<desc>.*?</desc>', '', s, flags=re.S)
    s = re.sub(r'\s+id="[^"]*"', '', s)
    return s

fams = json.load(open('families.json')) if os.path.exists('families.json') else []
byslug = {f['slug']: f for f in fams}
chosen = sys.argv[1:]
os.makedirs('sets', exist_ok=True)
picked = json.load(open('sets/picked.json')) if os.path.exists('sets/picked.json') else {}
for slug in chosen:
    os.makedirs('sets/' + slug, exist_ok=True)
    picked.setdefault(slug, {})
    for key in CONCEPTS:
        if key in picked[slug] and os.path.exists('sets/%s/%s.svg' % (slug, key)): continue
        x = pick(slug, key)
        if not x: print('miss', slug, key); continue
        line = any(w in slug for w in ['line', 'light', 'regular', 'outline', 'linear', 'thin', 'broken', 'stroke'])
        q = 'size=48&responsive=true' + ('&strokeWidth=2.6' if line else '')
        svg = get('icons/%s/download/svg?%s' % (x['hash'], q), raw=True)
        if not svg or not svg.lstrip().startswith('<svg'): print('dl fail', slug, key); continue
        open('sets/%s/%s.svg' % (slug, key), 'w').write(slim(svg))
        picked[slug][key] = {'hash': x['hash'], 'name': x['name']}
        print(slug, key, '->', x['name'])
        time.sleep(0.1)
json.dump(picked, open('sets/picked.json', 'w'), indent=1)

out = ['<html><body style="font-family:system-ui;background:#f4f1ea;padding:16px;margin:0">']
for slug in picked:
    out.append('<div style="display:flex;align-items:center;gap:8px;margin:10px 0"><span style="width:180px;font-size:12px;font-weight:700;color:#333">%s</span>' % html.escape(byslug.get(slug, {}).get('family', slug)))
    for key in CONCEPTS:
        p = 'sets/%s/%s.svg' % (slug, key)
        if not os.path.exists(p): out.append('<span style="width:44px;height:44px;display:inline-block"></span>'); continue
        out.append('<span title="%s" style="width:44px;height:44px;border-radius:12px;background:#1f3a5f;display:inline-grid;place-items:center"><img src="%s" style="width:24px;height:24px;filter:invert(1)"></span>' % (html.escape(picked[slug][key]['name']), p))
    out.append('<span style="width:12px"></span>')
    for key in list(CONCEPTS)[:6]:
        p = 'sets/%s/%s.svg' % (slug, key)
        if os.path.exists(p): out.append('<span style="width:44px;height:44px;border-radius:12px;background:#fff;border:1px solid #ddd;display:inline-grid;place-items:center"><img src="%s" style="width:24px;height:24px"></span>' % p)
    out.append('</div>')
out.append('</body></html>')
open('sets/sheet.html', 'w').write('\n'.join(out))
print('sheet written')

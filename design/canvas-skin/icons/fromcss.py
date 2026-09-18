"""Rebuild sets/<slug>/<key>.svg from the icon block already inline in skin.css,
for when the downloaded SVGs are gone (they lived in a session scratchpad).
   python3 fromcss.py ../../../extension/skin.css
The data URIs hold the slimmed SVG; decoding them back gives gen2.py its input."""
import json, os, re, sys, urllib.parse
SETS = json.load(open('sets/sets.json'))
NAV = {'.ic-icon-svg--dashboard': 'dashboard', '.ic-icon-svg--courses': 'courses', '.ic-icon-svg--calendar': 'calendar',
       '.ic-icon-svg--inbox': 'inbox', '.ic-icon-svg--history': 'history', '.svg-icon-help': 'help'}
ROWS = {'icon-document': 'page', 'icon-assignment': 'assignment', 'icon-quiz': 'quiz', 'icon-discussion': 'discussion',
        'icon-paperclip': 'file', 'icon-link': 'link', 'icon-announcement': 'announcement'}
css = open(sys.argv[1]).read()
n = 0
for m in re.finditer(r'html\.pk-on\.pk-icons-(\w+)(\.pk-icons-soft)?[^{]*?(?::has\(([^)]+)\)::before|i\.(icon-\w+))\s*\{\s*--pk-(?:nav|row)-icon:\s*url\("data:image/svg\+xml;utf8,(.*?)"\);?\s*\}', css):
    name, soft, hook, cls, body = m.groups()
    key = NAV.get(hook) if hook else ROWS.get(cls)
    if not key or name not in SETS: continue
    slug = SETS[name]['dark' if soft else 'light'] if soft else SETS[name]['light']
    svg = body.replace('%23', '#').replace('%25', '%')
    os.makedirs('sets/' + slug, exist_ok=True)
    path = 'sets/%s/%s.svg' % (slug, key)
    open(path, 'w').write(svg + '\n'); n += 1
print('wrote', n, 'files')

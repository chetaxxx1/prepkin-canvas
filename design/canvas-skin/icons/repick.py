"""Pick the twelve icons by exact name patterns per family; print what was chosen and the
   top names where nothing matched, so a pattern can be added. Downloads only what changed."""
import json, os, re, sys, time, urllib.request, urllib.parse
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
Q = {
  'dashboard': ['dashboard', 'home'], 'courses': ['book', 'open book', 'notebook'], 'calendar': ['calendar'], 'inbox': ['inbox', 'mail', 'envelope'],
  'history': ['clock', 'history'], 'help': ['question', 'help'],
  'page': ['notepad', 'notes', 'paper', 'document', 'blank document', 'text file', 'page'], 'assignment': ['pencil', 'edit'], 'quiz': ['checklist', 'check mark', 'check', 'task'],
  'discussion': ['chat', 'message'], 'file': ['paperclip', 'attachment'], 'link': ['link', 'hyperlink'],
  'announcement': ['megaphone', 'bullhorn', 'announcement'],
}
# In order of preference. `^` anchors: the plain name wins over a variant.
P = {
  'dashboard': [r'^Dashboard [34]$', r'^Dashboard 2$', r'^Dashboard( 1)?$', r'^Layout Dashboard( \d)?$', r'^Dashboard (Square|Circle|Layout)( \d)?$', r'^Home( \d)?$', r'^Interface Essential Home.*', r'^Gauge Dashboard$', r'^Layout \d$'],
  'courses': [r'^Book( \d)?$', r'^Open Book$', r'^Book Open.*', r'^Books?( \d)?$', r'^Content Files Book Open.*', r'^Content Files Book \d$', r'^Content Files Notebook.*', r'^Content Files Book.*', r'^Book Bookmark$', r'^Book Pin$', r'^Manual Book$'],
  'calendar': [r'^Calendar( \d)?$', r'^Blank Calendar$', r'^Calendar Blank Solo$', r'^Monthly Calendar$', r'^Calendar (Grid|Date|Mark)$', r'^Interface Essential Calendar.*', r'^Calendar.*'],
  'inbox': [r'^Inbox( \d)?$', r'^Inbox Solo$', r'^Inbox Tray \d$', r'^Email Inbox( \d)?$', r'^Mail( \d)?$', r'^Mailbox.*', r'^Email Tray$', r'^Envelope( \d)?$', r'^Email( \d)?$', r'^Email Action Unread$', r'^Email Envelope.*', r'^Mail Inbox.*', r'^Inbox.*'],
  'history': [r'^Rewind Clock$', r'^History$', r'^Clock( \d)?$', r'^Circle Clock$', r'^Interface Essential Clock$', r'^Time Clock Circle( \d)?$', r'^Clock Solo$', r'^Time History.*', r'^Clock Circle$', r'^Time Clock.*', r'^Interface Essential Clock.*', r'^Clock.*'],
  'help': [r'^Help Question( \d)?$', r'^Question Circle$', r'^Help Circle$', r'^Question Mark Circle$', r'^Help Question Circle$', r'^Question Mark Circle.*', r'^Help( \d)?$', r'^Question( \d)?$', r'^Question Help.*', r'^Interface Essential Question.*', r'^Help Question.*', r'^Question.*'],
  'page': [r'^Document( \d)?$', r'^File Text( \d)?$', r'^Blank Document$', r'^Text Document$', r'^Page( \d)?$', r'^Notepad( \d)?$', r'^Notepad Text$', r'^Note Pad$', r'^Notes?( \d)?$', r'^Blank Notepad$', r'^Paper( \d)?$', r'^Content Files Note.*', r'^New File$', r'^Common File Text.*', r'^Content Files Note.*', r'^Document Text.*', r'^Notes( \d)?$', r'^Document.*'],
  'assignment': [r'^Pencil( \d)?$', r'^Edit( \d)?$', r'^Pencil Write.*', r'^Edit Pencil$', r'^Design Pencil.*', r'^Pencil.*'],
  'quiz': [r'^Checklist( \d)?$', r'^Task List( \d)?$', r'^Interface Essential Check( \d)?$', r'^Interface Essential Checklist.*', r'^Check Mark( \d)?$', r'^Business Product Check$', r'^Check Square$', r'^Check( \d)?$', r'^Checkmark.*', r'^Check List.*', r'^Checklist.*', r'^Check.*'],
  'discussion': [r'^Chat Bubble( \d)?$', r'^Chat( \d)?$', r'^Chat Bubble (Square|Oval)( \d)?$', r'^Message Chat (Bubble|Round|Square)( \d)?$', r'^Chat Two Bubbles.*', r'^Conversation Chat.*', r'^Message( \d)?$', r'^Conversation( \d)?$', r'^Chat Two Bubbles.*', r'^Chat Email$', r'^Messages( \d)?$', r'^Chat Bubble.*', r'^Chat.*'],
  'file': [r'^Paperclip( \d)?$', r'^Attachment( \d)?$', r'^Paper Clip.*', r'^Interface Essential Paperclip.*', r'^Interface Essential Clip \d$', r'^Link Paperclip$', r'^Paperclip.*', r'^Attachment.*'],
  'announcement': [r'^Megaphone( \d)?$', r'^Bullhorn( \d)?$', r'^Announcement( \d)?$', r'^Announcement Megaphone( \d)?$', r'^Megaphone Announcement.*', r'^Interface Essential Megaphone.*', r'^Megaphone.*', r'^Bullhorn.*', r'^Announcement.*', r'^Share Megaphone( \d)?$', r'^Campaign Megaphone$', r'^Interface Essential Speaker Announce$'],
  'link': [r'^Link( \d)?$', r'^Link Chain$', r'^Hyperlink( \d)?$', r'^Chain( \d)?$', r'^Hyperlink Circle$', r'^Link Chain \d$', r'^Interface Essential Link.*', r'^Link.*', r'^Hyperlink.*'],
}
BAD = re.compile(r'\b(off|remove|delete|add|plus|minus|lock|download|upload|warning|alert|search|setting|star|heart|dollar|cancel|slash|fire|refresh|clear|share|laptop|order|payment|transaction|linkedin|arrow|trash|certificate|zoom|scan|5g|3d|full|empty|gas|fuel|user|return|thinking|smiley|typing)\b', re.I)
fams = sys.argv[1:]
picked = json.load(open('sets/picked.json'))
for slug in fams:
    picked.setdefault(slug, {})
    os.makedirs('sets/' + slug, exist_ok=True)
    line = any(w in slug for w in ['line', 'light', 'regular', 'outline', 'linear', 'thin', 'broken', 'stroke', 'freehand'])
    # ONLY=announcement picks one icon and leaves the rest alone (one request in fifty).
    for key in (os.environ['ONLY'].split(',') if os.environ.get('ONLY') else Q):
        names = []
        for q in Q[key]:
            r = get('search/family/%s?%s' % (slug, urllib.parse.urlencode({'query': q, 'limit': 40})))
            for x in (r or {}).get('results', []):
                if x['hash'] not in [n['hash'] for n in names]: names.append(x)
            time.sleep(0.05)
        if os.environ.get('DEBUG') == key: print('   ', slug, key, '::', ' | '.join(x['name'] for x in names[:16]))
        choice = None
        for pat in P[key]:
            cands = [x for x in names if re.match(pat, x['name']) and not BAD.search(x['name'])]
            if cands:
                cands.sort(key=lambda x: (len(x['name']), x['name']))
                choice = cands[0]; break
        if not choice:
            print('NO MATCH', slug, key, '->', ' | '.join(x['name'] for x in names[:14])); continue
        if picked[slug].get(key, {}).get('hash') == choice['hash'] and os.path.exists('sets/%s/%s.svg' % (slug, key)):
            continue
        q = 'size=48&responsive=true' + ('&strokeWidth=2.6' if line and 'freehand' not in slug else '')
        svg = get('icons/%s/download/svg?%s' % (choice['hash'], q), raw=True)
        if not svg or not svg.lstrip().startswith('<svg'): print('dl fail', slug, key); continue
        svg = re.sub(r'<desc>.*?</desc>', '', svg, flags=re.S)
        open('sets/%s/%s.svg' % (slug, key), 'w').write(svg)
        picked[slug][key] = {'hash': choice['hash'], 'name': choice['name']}
        print(slug, key, '->', choice['name'])
        time.sleep(0.1)
json.dump(picked, open('sets/picked.json', 'w'), indent=1)

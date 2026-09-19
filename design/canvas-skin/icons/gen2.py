"""The icon sets, as one skin.css block: for each set, the six nav icons and the
six row-type icons, the line family on light papers and the solid family on the
dark stocks and image looks (pk-icons-soft), inline as masks.
   python3 gen2.py > block2.css"""
import json, re, os, sys
SETS = json.load(open('sets/sets.json'))   # {set: {"light": slug, "dark": slug}}
NAV = [('dashboard', '.ic-icon-svg--dashboard'), ('courses', '.ic-icon-svg--courses'), ('calendar', '.ic-icon-svg--calendar'),
       ('inbox', '.ic-icon-svg--inbox'), ('history', '.ic-icon-svg--history'), ('help', '.svg-icon-help')]
ROWS = [('page', 'icon-document'), ('assignment', 'icon-assignment'), ('quiz', 'icon-quiz'), ('discussion', 'icon-discussion'),
        ('file', 'icon-paperclip'), ('link', 'icon-link'), ('announcement', 'icon-announcement'),
        # A calendar event in a list (the syllabus summary): the bar's own calendar, as a row var.
        ('calendar', 'icon-calendar-month')]
# The four actions under a course card, by Canvas's own class on the link.
CARDS = [('announcement', 'announcements'), ('assignment', 'assignments'), ('discussion', 'discussions'), ('file', 'files')]

def slim(path):
    s = open(path).read()
    s = re.sub(r'<desc>.*?</desc>', '', s, flags=re.S)
    s = re.sub(r'\s+id="[^"]*"', '', s)
    s = re.sub(r'<svg[^>]*>', lambda m: re.sub(r'\s+(width|height)="[^"]*"', '', m.group(0)), s, count=1)
    s = s.replace('"', "'")
    s = re.sub(r'>\s+<', '><', s); s = re.sub(r'\s+', ' ', s).strip()
    # Two decimals on a 48-unit grid is sharper than any screen shows at 26px; five was a third of the file.
    s = re.sub(r'(\d+\.\d{2})\d+', r'\1', s)
    s = re.sub(r' (stroke-linecap|stroke-linejoin)=\'round\'', r' \1=\'round\'', s)
    return s.replace('%', '%25').replace('#', '%23')

def uri(slug, key):
    p = 'sets/%s/%s.svg' % (slug, key)
    return 'url("data:image/svg+xml;utf8,' + slim(p) + '")' if os.path.exists(p) else None

out = []
out.append('/* Icon sets: every look names one (themes.js `icons`); the classes are pk-icons-<set>, plus pk-icons-soft on the dark stocks and the image looks, where a set with a solid family wears it. Six nav icons on the left bar, six row-type icons in the lists. Streamline families, inline as masks: no request leaves the page. Put back with the rail (nav) or the paper (rows). */')
out.append('html.pk-on:not(.pk-back-rail) .ic-app-header__menu-list-item .menu-item-icon-container { position: relative; }')
for key, hook in NAV:
    out.append('html.pk-on:not(.pk-back-rail) .menu-item-icon-container:has(%s) .ic-icon-svg { visibility: hidden !important; }' % hook)
for name, fam in SETS.items():
    for key, hook in NAV:
        light = uri(fam['light'], key); dark = uri(fam.get('dark', fam['light']), key)
        if light: out.append('html.pk-on.pk-icons-%s:not(.pk-back-rail) .menu-item-icon-container:has(%s)::before { --pk-nav-icon: %s; }' % (name, hook, light))
        if dark and dark != light: out.append('html.pk-on.pk-icons-%s.pk-icons-soft:not(.pk-back-rail) .menu-item-icon-container:has(%s)::before { --pk-nav-icon: %s; }' % (name, hook, dark))
sel = ',\n'.join('html.pk-on:not(.pk-back-rail) .menu-item-icon-container:has(%s)::before' % hook for _, hook in NAV)
out.append(sel + ' {')
out.append('  content: ""; position: absolute; inset: 0; margin: auto; width: 26px; height: 26px;')
out.append('  background-color: color-mix(in srgb, var(--pk-rail-active) 42%, white);')
out.append('  -webkit-mask: var(--pk-nav-icon) center / contain no-repeat; mask: var(--pk-nav-icon) center / contain no-repeat;')
out.append('}')
out.append('html.pk-on:not(.pk-back-rail) .ic-app-header__menu-list-item--active .menu-item-icon-container::before { background-color: var(--pk-rail-active); }')
out.append('html.pk-on:not(.pk-back-rail) .ic-app-header__menu-list-item:not(.ic-app-header__menu-list-item--active) .ic-app-header__menu-list-link:hover .menu-item-icon-container::before,')
out.append('html.pk-on:not(.pk-back-rail) .ic-app-header__menu-list-item:not(.ic-app-header__menu-list-item--active) .ic-app-header__menu-list-link:focus .menu-item-icon-container::before { background-color: #fff; }')
# The row and card icons: one variable per icon per set on <html>, read by the
# list rows (the glyph goes clear and the <i> wears the mask) and by the four
# actions under a course card (Canvas's svg hides and a ::before wears it).
out.append('/* The row-type icons in the lists (modules, assignments, quizzes) and the four actions under a course card: the same set as the bar, one variable per icon on <html>. */')
for name, fam in SETS.items():
    light = {key: uri(fam['light'], key) for key, _ in ROWS}
    dark = {key: uri(fam.get('dark', fam['light']), key) for key, _ in ROWS}
    out.append('html.pk-on.pk-icons-%s:not(.pk-back-paper) { %s }' % (name, ' '.join('--pk-icon-%s: %s;' % (k, v) for k, v in light.items() if v)))
    soft = {k: v for k, v in dark.items() if v and v != light.get(k)}
    if soft: out.append('html.pk-on.pk-icons-%s.pk-icons-soft:not(.pk-back-paper) { %s }' % (name, ' '.join('--pk-icon-%s: %s;' % (k, v) for k, v in soft.items())))
def everywhere(key): return all(uri(fam['light'], key) for fam in SETS.values())
def sets_with(key): return [name for name, fam in SETS.items() if uri(fam['light'], key)]
for key, cls in ROWS:
    # An icon a set lacks keeps Canvas's glyph there: the rule is gated on the sets that have it.
    gates = ['html.pk-on:not(.pk-back-paper)'] if everywhere(key) else ['html.pk-on.pk-icons-%s:not(.pk-back-paper)' % n for n in sets_with(key)]
    for g in gates:
        out.append('%s .ig-row .ig-type-icon i.%s { color: transparent !important; width: 16px !important; height: 16px !important; -webkit-mask: var(--pk-icon-%s) center / contain no-repeat; mask: var(--pk-icon-%s) center / contain no-repeat; background-color: var(--pk-ink-2) !important; }' % (g, cls, key, key))
        out.append('%s .ig-row .ig-type-icon i.%s::before { content: none !important; }' % (g, cls))
out.append('html.pk-on:not(.pk-back-paper) .ic-DashboardCard__action .ic-DashboardCard__action-layout { position: relative !important; display: grid !important; place-items: center !important; width: 32px !important; height: 32px !important; }')
for key, cls in CARDS:
    gates = ['html.pk-on:not(.pk-back-paper)'] if everywhere(key) else ['html.pk-on.pk-icons-%s:not(.pk-back-paper)' % n for n in sets_with(key)]
    for g in gates:
        out.append('%s .ic-DashboardCard__action.%s .ic-DashboardCard__action-layout svg { visibility: hidden !important; }' % (g, cls))
        out.append('%s .ic-DashboardCard__action.%s .ic-DashboardCard__action-layout::before { content: ""; position: absolute; inset: 0; margin: auto; width: 18px; height: 18px; background-color: currentColor; -webkit-mask: var(--pk-icon-%s) center / contain no-repeat; mask: var(--pk-icon-%s) center / contain no-repeat; }' % (g, cls, key, key))
sys.stdout.write('\n'.join(out) + '\n')

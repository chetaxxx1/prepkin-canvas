#!/usr/bin/env python3
"""Deal a year of Play puzzles into ios/Resources/Content/.

Four files, all checked before they are written:

  ladders.json   [{words, clues, deal}]     hand-written in ladders.py (Crossclimb-type)
  threads.json   [{id, name, accept, clues}] hand-written below (Pinpoint-type)
  balance.json   [{n, givens, signs}]       6x6 Takuzu with = / x signs (Tango-type), one answer, by rule
  pearls.json    [{n, regions}]             Star Battle one-star (Queens-type), one answer, by rule
  trace.json     [{n, numbers, walls}]      one path through every cell, numbers in order (Zip-type), one answer

"Solvable by rule" means a small deduction solver that never guesses gets to the
answer. That is the difficulty gate: a puzzle that needs bifurcation is thrown out.
Seeded, so re-running reproduces the same files. Run from the repo root:

    python3 design/games/gen.py            # everything
    python3 design/games/gen.py trace      # one file
    python3 design/games/gen.py candidates # print ladder chains to author from
"""
import json, random, sys, os, itertools, collections

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CONTENT = os.path.join(ROOT, 'ios', 'Resources', 'Content')
SEED = 20260908

# ---------------------------------------------------------------- ladders

def word_graph(words):
    buckets = collections.defaultdict(list)
    for w in words:
        for i in range(5):
            buckets[w[:i] + '*' + w[i+1:]].append(w)
    nb = {w: set() for w in words}
    for group in buckets.values():
        for a in group:
            for b in group:
                if a != b:
                    nb[a].add(b)
    return nb

def bfs(nb, start, limit):
    dist = {start: 0}
    q = collections.deque([start])
    while q:
        w = q.popleft()
        if dist[w] >= limit:
            continue
        for n in nb[w]:
            if n not in dist:
                dist[n] = dist[w] + 1
                q.append(n)
    return dist

def common_words():
    return [w.upper() for w in json.load(open(os.path.join(CONTENT, 'words.json')))]

def gen_ladders(rng):
    """ladders.py, checked: common words, one letter a rung, no repeats, and the
    middle five have exactly one order (up to reversal). `deal` is the scrambled
    order the middle rows are shown in, never the answer or its reverse."""
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from ladders import LADDERS
    common = set(common_words())
    out, seen = [], set()
    for words, clues in LADDERS:
        assert len(words) == 7 and len(clues) == 7, words
        assert len(set(words)) == 7, f"repeat in {words}"
        for w in words:
            assert w in common, f"{w} is not in words.json"
        for a_, b_ in zip(words, words[1:]):
            assert sum(x != y for x, y in zip(a_, b_)) == 1, f"{a_}->{b_} is not one letter"
        assert all(c.strip() for c in clues), words
        mid = words[1:6]
        orders = [p for p in itertools.permutations(range(5))
                  if all(sum(x != y for x, y in zip(mid[p[i]], mid[p[i+1]])) == 1 for i in range(4))]
        assert len(orders) == 2, f"middle of {words} has {len(orders)//2} orders"
        key = tuple(words)
        assert key not in seen, f"duplicate ladder {words}"
        seen.add(key)
        while True:
            deal = list(range(1, 6)); rng.shuffle(deal)
            if deal != [1, 2, 3, 4, 5] and deal != [5, 4, 3, 2, 1]:
                break
        out.append({'words': words, 'clues': clues, 'deal': deal})
    return out

def print_candidates(rng, count=80):
    """Chains to author from: seven common words, one letter a rung, middle order unique."""
    common = common_words()
    nb = word_graph([w.lower() for w in common])
    seen = set(); shown = 0
    for _ in range(50000):
        if shown >= count: break
        w = rng.choice(common).lower(); path = [w]
        for _ in range(6):
            opts = [x for x in nb[path[-1]] if x not in path]
            if not opts: break
            path.append(rng.choice(opts))
        if len(path) != 7: continue
        mid = path[1:6]
        orders = [p for p in itertools.permutations(range(5))
                  if all(sum(x != y for x, y in zip(mid[p[i]], mid[p[i+1]])) == 1 for i in range(4))]
        if len(orders) != 2: continue
        key = tuple(sorted(path))
        if key in seen: continue
        seen.add(key); shown += 1
        print(' '.join(x.upper() for x in path))

# ---------------------------------------------------------------- threads

THREADS = [
  ('card',      '___ card',                  ['card'],                       ['Wild','Green','Report','Business','Credit']),
  ('drop',      'Things you drop',           ['drop'],                       ['A beat','A hint','The ball','A class','The mic']),
  ('bank',      '___ bank',                  ['bank'],                       ['Power','River','Blood','Piggy','Food']),
  ('money',     'Slang for money',           ['money','cash'],               ['Bands','Cheddar','Bread','Dough','Bucks']),
  ('keys',      'Things with keys',          ['key','keys'],                 ['Florida','Map','Locksmith','Piano','Keyboard']),
  ('schools',   'Fictional schools',         ['fictional school','made-up school','tv school','fake school','school'], ['Greendale','Bayside',"Xavier's",'Monsters University','Hogwarts']),
  ('pull',      'Things you pull',           ['pull'],                       ['Strings','A muscle','Weight','A prank','An all-nighter']),
  ('office',    'Office ___',                ['office'],                     ['Chair','Supplies','Space','Party','Hours']),
  ('loans',     'Kinds of loan',             ['loan','loans'],               ['Payday','Auto','Personal','Mortgage','Student']),
  ('due',       'Things that are due',       ['due'],                        ['Respect','A baby','Rent','A library book','An assignment']),
  ('elements',  'Elements named after places', ['element','elements','named after places','places'], ['Polonium','Germanium','Francium','Americium','Californium']),
  ('group',     'Group ___',                 ['group'],                      ['Therapy','Discount','Text','Project','Chat']),
  ('accounts',  'Kinds of account',          ['account','accounts'],         ['Roth IRA','Email','Checking','Savings','Instagram']),
  ('space',     '___ space',                 ['space'],                      ['White','Head','Outer','Storage','Office']),
  ('credits',   'Things with credits',       ['credit','credits'],           ['Tax','Film','Movies','Transfer','Classes']),
  ('dropouts',  'College dropouts',          ['dropout','dropouts','dropped out','drop out','left college','never graduated'], ['Lady Gaga','Steve Jobs','Kanye','Bill Gates','Zuckerberg']),
  ('run',       'Things you run',            ['run'],                        ['The numbers','A fever','Late','A business','A mile']),
  ('study',     'Study ___',                 ['study'],                      ['Buddy','Hall','Break','Abroad','Group']),
  ('compound',  'Things that compound',      ['compound'],                   ['Fractures','Sentences','Pharmacies','Words','Interest']),
  ('file',      'Things you file',           ['file'],                       ['For divorce','Nails','A complaint','Papers','Taxes']),
  ('coffee',    'Coffee orders',             ['coffee','espresso'],          ['Cortado','Flat white','Americano','Cold brew','Oat latte']),
  ('hall',      '___ hall',                  ['hall'],                       ['Town','Concert','Residence','Lecture','Dining']),
  ('shot',      '___ shot',                  ['shot'],                       ['Long','Mug','Moon','Flu','Screen']),
  ('take',      'Things you take',           ['take'],                       ['The L','A hint','A shot','A break','Notes']),
  ('terms',     'Things with terms',         ['term','terms'],               ['Presidents','Contracts','Dictionaries','Loans','Semesters']),
  ('major',     '___ major',                 ['major','majors'],             ['Ursa','Canis','Sergeant','Drum','Double']),
  # --- batch two, 2026-09-08. Hardest clue first, giveaway last. Adult voice.
  ('break',     'Things you break',          ['break'],                      ['A record','The ice','A habit','The news','A promise']),
  ('bar',       '___ bar',                   ['bar'],                        ['Crow','Sand','Space','Candy','Salad']),
  ('deadline',  'Things with deadlines',     ['deadline','deadlines'],       ['Taxes','Grant applications','Transfers','Newspapers','Essays']),
  ('rate',      'Kinds of rate',             ['rate','rates'],               ['Exchange','Heart','Interest','Tax','Hourly']),
  ('ball',      '___ ball',                  ['ball'],                       ['Curve','Eye','Odd','Snow','Foot']),
  ('lose',      'Things you lose',           ['lose'],                       ['Your voice','Track of time','Sleep','Weight','Your keys']),
  ('mac',       'Mac ___',                   ['mac','macs','apple','apple products'], ['Mini','Studio','Pro','Air','Book']),
  ('capital',   'Kinds of capital',          ['capital','capitals'],         ['Venture','Human','Social','Working','State']),
  ('degree',    'Things with degrees',       ['degree','degrees'],           ['Burns','Murder','Angles','Fevers','Graduates']),
  ('shift',     'Kinds of shift',            ['shift','shifts'],             ['Paradigm','Night','Gear','Stick','Key']),
  ('plan',      'Kinds of plan',             ['plan','plans'],               ['Floor','Lesson','Payment','Meal','Backup']),
  ('roman',     'Roman numerals',            ['roman numeral','roman numerals','numerals','roman'], ['M','D','C','L','X']),
  ('bond',      'Kinds of bond',             ['bond','bonds'],               ['James','Covalent','Municipal','Bail','Savings']),
  ('ghost',     'Things you ghost',          ['ghost','ghosting'],           ['A recruiter','A group chat','A landlord','A date','A friend']),
  ('cap',       'Things with caps',          ['cap','caps'],                 ['Bottles','Salaries','Knees','Mushrooms','Pens']),
  ('charge',    'Things you charge',         ['charge'],                     ['A battery','A fee','A suspect','The net','Your phone']),
  ('bass',      'Fish that are also words',  ['fish'],                       ['Bass','Perch','Sole','Ray','Fluke']),
  ('mouse',     'Things with a mouse',       ['mouse','mice'],               ['Mickey','A trap','A pad','A lab','A laptop']),
  ('interview', 'Interview questions',       ['interview question','interview questions','interview','job interview'], ['Tell me about yourself','Why here?','Biggest weakness?','Where in five years?','Any questions for us?']),
  ('season',    'Things with seasons',       ['season','seasons'],           ['Chefs','Tickets','Pans','TV shows','Years']),
  ('bill',      'Things with bills',         ['bill','bills'],               ['Ducks','Congress','Restaurants','Wallets','Utilities']),
  ('draw',      'Things you draw',           ['draw'],                       ['A bath','Blood','A conclusion','The line','A picture']),
  ('planet',    'Planets',                   ['planet','planets','solar system'], ['Neptune','Uranus','Mercury','Saturn','Mars']),
  ('hard',      'Hard ___',                  ['hard'],                       ['Drive','Copy','Cider','Launch','Boiled']),
  ('cover',     'Kinds of cover',            ['cover','covers'],             ['Album','Book','Cloud','Duvet','Song']),
  ('bank2',     'Things you bank',           ['bank'],                       ['Coins','A shot','On it','Hours','Blood']),
  ('cold',      'Cold ___',                  ['cold'],                       ['Call','Case','Turkey','Shoulder','Brew']),
  ('game',      'Things with games',         ['game','games'],               ['Hunger','Squid','The Olympics','Consoles','Friday nights']),
  ('chain',     'Kinds of chain',            ['chain','chains'],             ['Supply','Food','Block','Key','Bike']),
  ('stream',    'Things you stream',         ['stream'],                     ['A conscience','Data','A river','A game','A show']),
  ('flat',      'Flat ___',                  ['flat'],                       ['Earth','Iron','Rate','Tire','White']),
  ('quarter',   'Things with quarters',      ['quarter','quarters'],         ['Football','Fiscal years','Dollars','The moon','Semesters']),
  ('root',      'Kinds of root',             ['root','roots'],               ['Square','Grass','Tooth','Hair','Ginger']),
  ('crush',     'Things you crush',          ['crush'],                      ['Candy','A can','Ice','A test','An interview']),
  ('post',      '___ post',                  ['post'],                       ['Guard','Goal','Lamp','Blog','Sign']),
  ('bench',     'Things with benches',       ['bench','benches'],            ['Courts','Gyms','Labs','Parks','Teams']),
  ('open',      'Open ___',                  ['open'],                       ['Source','Mic','Bar','House','Tab']),
  ('notes',     'Things you take notes on',  ['note','notes','take notes'],  ['A phone','Sticky paper','Lectures','A napkin','A laptop']),
  ('spring',    'Spring ___',                ['spring'],                     ['Roll','Break','Cleaning','Onion','Water']),
  ('field',     'Kinds of field',            ['field','fields'],             ['Magnetic','Force','Track and','Corn','Football']),
  ('table',     'Things with tables',        ['table','tables'],             ['Contents','Periodic','Poker','Spreadsheets','Restaurants']),
  ('screen',    'Things you screen',         ['screen'],                     ['Calls','A film','Applicants','A window','A porch']),
  ('block',     'Kinds of block',            ['block','blocks'],             ['Writer\'s','Mental','City','Cinder','Butcher']),
  ('float',     'Things that float',         ['float','floats'],             ['Ideas','Currencies','Root beer','Parades','Boats']),
  ('order',     'Things you order',          ['order'],                      ['Someone around','Numbers','A pizza','Takeout','Groceries']),
  ('sharp',     'Things that are sharp',     ['sharp'],                      ['Cheddar','Dressers','A tongue','Knives','Pencils']),
  ('pitch',     'Kinds of pitch',            ['pitch','pitches'],            ['Elevator','Sales','Perfect','Cricket','Baseball']),
  ('save',      'Things you save',           ['save'],                       ['A seat','A file','A goal','Face','Money']),
  ('free',      'Free ___',                  ['free'],                       ['Fall','Trial','Range','Throw','Wifi']),
  ('press',     'Things you press',          ['press'],                      ['Charges','Flowers','A suit','Snooze','A button']),
  ('cycle',     'Kinds of cycle',            ['cycle','cycles'],             ['Krebs','Water','News','Spin','Wash']),
  ('lead',      'Things you lead',           ['lead'],                       ['A horse to water','A double life','A team','A meeting','The way']),
  ('mass',      'Kinds of mass',             ['mass'],                       ['Critical','Body','Sunday','Molar','Land']),
  ('mile',      'Kinds of mile',             ['mile','miles'],               ['Nautical','Green','Country','Extra','Air']),
  ('log',       'Kinds of log',              ['log','logs'],                 ['Yule','Captain\'s','Change','Natural','Fire']),
  ('ship',      '___ship',                   ['ship'],                       ['Friend','Intern','Scholar','Relation','Member']),
  ('trip',      'Kinds of trip',             ['trip','trips'],               ['Guilt','Ego','Power','Road','Field']),
  ('brand',     'Brands that became verbs',  ['brand','brands','verbs','company','companies'], ['Xerox','Hoover','Photoshop','Uber','Google']),
  ('zero',      'Things with zeros',         ['zero','zeros','zeroes'],      ['Coke','Binary','Patient','Ground','Absolute']),
  ('patch',     'Kinds of patch',            ['patch','patches'],            ['Software','Eye','Nicotine','Pumpkin','Bald']),
  ('pass',      'Things you pass',           ['pass'],                       ['Out','Judgment','A law','The salt','A test']),
  ('minor',     'Things that are minor',     ['minor','minors'],             ['Keys','Leagues','Injuries','Under-18s','Second majors']),
  ('gross',     'Gross ___',                 ['gross'],                      ['Domestic product','Margin','Income','Weight','Anatomy']),
  ('point',     'Kinds of point',            ['point','points'],             ['Boiling','Bullet','Tipping','Match','Power']),
  ('house',     '___ house',                 ['house'],                      ['Ware','Green','Light','Full','Open']),
  ('shell',     'Things with shells',        ['shell','shells'],             ['Companies','Pasta','Taco Bell','Beaches','Turtles']),
  ('fold',      'Things you fold',           ['fold'],                       ['In poker','A protein','A map','Laundry','Paper']),
  ('apple',     'Apple ___',                 ['apple'],                      ['Sauce','Cider','Pie','Watch','Music']),
  ('run2',      'Kinds of run',              ['run','runs'],                 ['Bank','Dry','Home','Fun','Trial']),
  ('circle',    'Kinds of circle',           ['circle','circles'],           ['Vicious','Arctic','Crop','Inner','Full']),
  ('rush',      'Kinds of rush',             ['rush'],                       ['Gold','Sugar','Sorority','Hour','Adrenaline']),
  ('current',   'Things with currents',      ['current','currents'],         ['Oceans','Events','Wires','Rivers','Batteries']),
  ('mean',      'Kinds of mean',             ['mean','means','average'],     ['Geometric','Golden','Harmonic','Arithmetic','Sample']),
  ('hook',      'Things with hooks',         ['hook','hooks'],               ['Songs','Essays','Pirates','Boxers','Fishing']),
  ('turn',      'Things you turn',           ['turn'],                       ['A phrase','A profit','21','A corner','A page']),
  ('school',    'Kinds of school',           ['school','schools'],           ['Fish','Old','Thought','Boarding','Grad']),
  ('cell',      'Kinds of cell',             ['cell','cells'],               ['Sleeper','Prison','Stem','Spreadsheet','Battery']),
  ('crash',     'Things that crash',         ['crash'],                      ['Waves','Markets','Parties','Apps','Cars']),
  ('gap',       'Kinds of gap',              ['gap','gaps'],                 ['Wage','Generation','Thigh','Year','Tooth']),
  ('drive',     'Kinds of drive',            ['drive','drives'],             ['Sex','Flash','Test','Four-wheel','Hard']),
  ('mid',       'Mid___',                    ['mid'],                        ['Life','Night','Terms','Town','West']),
  ('press2',    'Kinds of press',            ['press'],                      ['Garlic','French','Bench','Printing','Full-court']),
  ('nobel',     'Nobel Prize categories',    ['nobel','nobel prize','prize','prizes'], ['Economics','Literature','Peace','Chemistry','Physics']),
  ('date',      'Things you date',           ['date'],                       ['A cheque','A fossil','A letter','A coworker','A person']),
  ('law',       'Named laws',                ['law','laws','named laws'],    ["Godwin's","Moore's","Murphy's","Ohm's","Newton's"]),
  ('lab',       'Kinds of lab',              ['lab','labs'],                 ['Meth','Chem','Computer','Sleep','Labrador']),
  ('fee',       'Kinds of fee',              ['fee','fees'],                 ['Convenience','Late','Overdraft','Tuition','Delivery']),
  ('read',      'Things you read',           ['read'],                       ['The room','Minds','Lips','A meter','A book']),
  ('cast',      'Things you cast',           ['cast'],                       ['A spell','Doubt','A shadow','A vote','A line']),
  ('salt',      'Kinds of salt',             ['salt','salts'],               ['Epsom','Rock','Table','Sea','Bath']),
  ('battery',   'Things with batteries',     ['battery','batteries'],        ['Assault and','Tests','Remotes','Cars','Phones']),
  ('exam',      'Standardized tests',        ['test','tests','exam','exams','standardized'], ['LSAT','MCAT','GRE','ACT','SAT']),
  ('draft',     'Kinds of draft',            ['draft','drafts'],             ['Military','Beer','Fantasy','Rough','First']),
  ('sink',      'Things that sink',          ['sink'],                       ['Ships','Hearts','Putts','Stones','Teeth']),
]

def gen_threads():
    return [{'id': i, 'name': n, 'accept': a, 'clues': c} for i, n, a, c in THREADS]

# ---------------------------------------------------------------- balance (Takuzu)

def bal_ok(g, N, r, c, v, signs=()):
    old = g[r][c]; g[r][c] = v
    try:
        for (r1, c1), (r2, c2), same in signs:
            if (r, c) in ((r1, c1), (r2, c2)):
                other = g[r2][c2] if (r, c) == (r1, c1) else g[r1][c1]
                if other != -1 and (other == v) != same: return False
        if sum(1 for j in range(N) if g[r][j] == v) > N // 2: return False
        if sum(1 for i in range(N) if g[i][c] == v) > N // 2: return False
        for s in range(max(0, c - 2), min(c, N - 3) + 1):
            if g[r][s] == g[r][s+1] == g[r][s+2] == v: return False
        for s in range(max(0, r - 2), min(r, N - 3) + 1):
            if g[s][c] == g[s+1][c] == g[s+2][c] == v: return False
        return True
    finally:
        g[r][c] = old

def bal_count(p, N, limit=2, signs=()):
    h = [row[:] for row in p]; n = 0
    def rec(i):
        nonlocal n
        if n >= limit: return
        if i == N * N: n += 1; return
        r, c = divmod(i, N)
        if h[r][c] != -1: rec(i + 1); return
        for v in (0, 1):
            if bal_ok(h, N, r, c, v, signs):
                h[r][c] = v; rec(i + 1); h[r][c] = -1
    rec(0); return n

def bal_deduce(p, N, signs=()):
    """Fill by rule only: pairs force their ends, gaps force their middle, a full
    half forces the rest, a sign copies or flips its known neighbour. True if
    that alone finishes the grid."""
    g = [row[:] for row in p]
    def use_signs():
        changed = False
        for (r1, c1), (r2, c2), same in signs:
            a, b = g[r1][c1], g[r2][c2]
            if a != -1 and b == -1: g[r2][c2] = a if same else 1 - a; changed = True
            elif b != -1 and a == -1: g[r1][c1] = b if same else 1 - b; changed = True
        return changed
    def line(cells):
        vals = [g[r][c] for r, c in cells]
        changed = False
        for i in range(N - 1):
            if vals[i] != -1 and vals[i] == vals[i+1]:
                for j in (i - 1, i + 2):
                    if 0 <= j < N and vals[j] == -1:
                        vals[j] = 1 - vals[i]; changed = True
        for i in range(N - 2):
            if vals[i] != -1 and vals[i] == vals[i+2] and vals[i+1] == -1:
                vals[i+1] = 1 - vals[i]; changed = True
        for v in (0, 1):
            if vals.count(v) == N // 2:
                for i in range(N):
                    if vals[i] == -1:
                        vals[i] = 1 - v; changed = True
        for (r, c), v in zip(cells, vals):
            g[r][c] = v
        return changed
    while True:
        moved = False
        for r in range(N):
            moved |= line([(r, c) for c in range(N)])
        for c in range(N):
            moved |= line([(r, c) for r in range(N)])
        moved |= use_signs()
        if not moved: break
    return all(v != -1 for row in g for v in row)

def gen_balance_one(rng, N=6):
    g = [[-1] * N for _ in range(N)]
    def fill(i):
        if i == N * N: return True
        r, c = divmod(i, N)
        for v in ([0, 1] if rng.random() < 0.5 else [1, 0]):
            if bal_ok(g, N, r, c, v):
                g[r][c] = v
                if fill(i + 1): return True
                g[r][c] = -1
        return False
    fill(0)
    # Tango's signs: = between two alike, x between two different. Four to six
    # of them, on distinct pairs, read off the finished grid so they are true.
    pairs = [((r, c), (r, c + 1)) for r in range(N) for c in range(N - 1)] + \
            [((r, c), (r + 1, c)) for r in range(N - 1) for c in range(N)]
    rng.shuffle(pairs)
    signs = []
    for a, b in pairs[:rng.randint(4, 6)]:
        signs.append((a, b, g[a[0]][a[1]] == g[b[0]][b[1]]))
    puzzle = [row[:] for row in g]
    order = list(range(N * N)); rng.shuffle(order)
    for i in order:
        r, c = divmod(i, N)
        v = puzzle[r][c]; puzzle[r][c] = -1
        if not (bal_deduce(puzzle, N, signs) and bal_count(puzzle, N, signs=signs) == 1):
            puzzle[r][c] = v
    return puzzle, signs

def gen_balance(rng, count=400):
    out, seen = [], set()
    while len(out) < count:
        if len(out) % 50 == 0: print(f"  balance {len(out)}", file=sys.stderr, flush=True)
        p, signs = gen_balance_one(rng)
        key = json.dumps(p)
        if key in seen: continue
        seen.add(key)
        out.append({'n': 6, 'givens': p,
                    'signs': [{'a': list(a), 'b': list(b), 'same': same} for a, b, same in signs]})
    return out

# ---------------------------------------------------------------- pearls (Star Battle, 1 star)

def perm_no_touch(rng, N):
    p, used = [], set()
    def rec(r):
        if r == N: return True
        cs = list(range(N)); rng.shuffle(cs)
        for c in cs:
            if c in used or (r > 0 and abs(c - p[-1]) < 2): continue
            p.append(c); used.add(c)
            if rec(r + 1): return True
            p.pop(); used.discard(c)
        return False
    return p if rec(0) else None

def grow_regions(rng, N, perm, min_size):
    reg = [[-1] * N for _ in range(N)]
    for r in range(N): reg[r][perm[r]] = r
    remaining = N * N - N
    sizes = [1] * N
    while remaining:
        # smallest regions grow first, so none stays a single given cell
        order = sorted(range(N), key=lambda k: (sizes[k], rng.random()))
        grew = False
        for k in order:
            cands = []
            for r in range(N):
                for c in range(N):
                    if reg[r][c] != k: continue
                    for dr, dc in ((1,0),(-1,0),(0,1),(0,-1)):
                        nr, nc = r + dr, c + dc
                        if 0 <= nr < N and 0 <= nc < N and reg[nr][nc] == -1:
                            cands.append((nr, nc))
            if cands:
                nr, nc = rng.choice(cands); reg[nr][nc] = k; sizes[k] += 1; remaining -= 1; grew = True
                break
        if not grew: return None
    if min(sizes) < min_size: return None
    return reg

def pearl_count(reg, N, limit=2):
    n = 0; usedC, usedR = set(), set()
    def rec(r, prev):
        nonlocal n
        if n >= limit: return
        if r == N: n += 1; return
        for c in range(N):
            k = reg[r][c]
            if c in usedC or k in usedR or (prev >= 0 and abs(c - prev) < 2): continue
            usedC.add(c); usedR.add(k); rec(r + 1, c); usedC.discard(c); usedR.discard(k)
    rec(0, -1); return n

def pearl_deduce(reg, N):
    """Rule-only solver. 0 unknown, 1 no, 2 pearl. Rules: a unit with a pearl is
    otherwise empty; a unit with one cell left takes the pearl; a pearl clears its
    eight neighbours; a region confined to one row/column clears the rest of that
    line (and a line confined to one region clears the rest of the region); a cell
    touching every candidate of some unit can never hold a pearl."""
    st = [[0] * N for _ in range(N)]
    units = []
    for r in range(N): units.append([(r, c) for c in range(N)])
    for c in range(N): units.append([(r, c) for r in range(N)])
    regs = collections.defaultdict(list)
    for r in range(N):
        for c in range(N): regs[reg[r][c]].append((r, c))
    units += list(regs.values())
    def place(r, c):
        st[r][c] = 2
        for dr in (-1, 0, 1):
            for dc in (-1, 0, 1):
                nr, nc = r + dr, c + dc
                if (dr or dc) and 0 <= nr < N and 0 <= nc < N and st[nr][nc] == 0: st[nr][nc] = 1
        for u in units:
            if (r, c) in u:
                for (ur, uc) in u:
                    if st[ur][uc] == 0: st[ur][uc] = 1
    while True:
        changed = False
        for u in units:
            pearls = [x for x in u if st[x[0]][x[1]] == 2]
            unknown = [x for x in u if st[x[0]][x[1]] == 0]
            if not pearls and len(unknown) == 1:
                place(*unknown[0]); changed = True
        # confinement
        for k, cells in regs.items():
            if any(st[r][c] == 2 for r, c in cells): continue
            cand = [x for x in cells if st[x[0]][x[1]] == 0]
            rows = {r for r, c in cand}; cols = {c for r, c in cand}
            if len(rows) == 1:
                (r,) = rows
                for c in range(N):
                    if reg[r][c] != k and st[r][c] == 0: st[r][c] = 1; changed = True
            if len(cols) == 1:
                (c,) = cols
                for r in range(N):
                    if reg[r][c] != k and st[r][c] == 0: st[r][c] = 1; changed = True
        for line in units[:2 * N]:
            if any(st[r][c] == 2 for r, c in line): continue
            cand = [x for x in line if st[x[0]][x[1]] == 0]
            ks = {reg[r][c] for r, c in cand}
            if len(ks) == 1:
                (k,) = ks
                for (r, c) in regs[k]:
                    if (r, c) not in line and st[r][c] == 0: st[r][c] = 1; changed = True
        # touching every candidate of a unit
        for u in units:
            if any(st[r][c] == 2 for r, c in u): continue
            cand = [x for x in u if st[x[0]][x[1]] == 0]
            if not cand or len(cand) > 4: continue
            for r in range(N):
                for c in range(N):
                    if st[r][c] != 0 or (r, c) in cand: continue
                    if all(abs(r - cr) <= 1 and abs(c - cc) <= 1 for cr, cc in cand):
                        st[r][c] = 1; changed = True
        if not changed: break
    return sum(1 for row in st for v in row if v == 2) == N

def connected(reg, N, k, without=None):
    cells = [(r, c) for r in range(N) for c in range(N) if reg[r][c] == k and (r, c) != without]
    if not cells: return False
    seen = {cells[0]}; q = [cells[0]]
    while q:
        r, c = q.pop()
        for dr, dc in ((1,0),(-1,0),(0,1),(0,-1)):
            x = (r + dr, c + dc)
            if 0 <= x[0] < N and 0 <= x[1] < N and x not in seen and x != without and reg[x[0]][x[1]] == k:
                seen.add(x); q.append(x)
    return len(seen) == len(cells)

def carve_pearls(rng, N, min_size=3, budget=4000):
    """Random regions have dozens of answers. So start there and hill-climb: move
    one boundary cell to a neighbouring reef at a time, keep the move when the
    answer count does not go up, stop when it is one and the rule solver agrees."""
    perm = perm_no_touch(rng, N)
    if not perm: return None
    reg = grow_regions(rng, N, perm, min_size)
    if reg is None: return None
    fixed = {(r, perm[r]) for r in range(N)}
    sizes = collections.Counter(v for row in reg for v in row)
    score = pearl_count(reg, N, 64)
    for _ in range(budget):
        r, c = rng.randrange(N), rng.randrange(N)
        if (r, c) in fixed: continue
        k = reg[r][c]
        if sizes[k] <= min_size: continue
        nbs = {reg[r+dr][c+dc] for dr, dc in ((1,0),(-1,0),(0,1),(0,-1))
               if 0 <= r+dr < N and 0 <= c+dc < N and reg[r+dr][c+dc] != k}
        if not nbs: continue
        k2 = rng.choice(sorted(nbs))
        if not connected(reg, N, k, without=(r, c)): continue
        reg[r][c] = k2; sizes[k] -= 1; sizes[k2] += 1
        new = pearl_count(reg, N, 64)
        if new > score or (new == 1 and score == 1 and rng.random() < 0.5):
            reg[r][c] = k; sizes[k] += 1; sizes[k2] -= 1
            continue
        score = new
        if score == 1 and pearl_deduce(reg, N):
            return reg
    return None

def gen_pearls(rng, count7=340, count8=60):
    out, seen = [], set()
    tries = collections.Counter()
    for N, count in ((7, count7), (8, count8)):
        got = 0
        while got < count:
            tries[N] += 1
            reg = carve_pearls(rng, N)
            if reg is None: continue
            key = json.dumps(reg)
            if key in seen: continue
            seen.add(key); got += 1
            out.append({'n': N, 'regions': reg})
            if got % 50 == 0: print(f"  pearls {N}x{N} {got} ({tries[N]} tries)", file=sys.stderr, flush=True)
    print(f"  pearls: {tries[7]} tries for {count7} 7x7, {tries[8]} tries for {count8} 8x8", file=sys.stderr)
    return out

# ---------------------------------------------------------------- trace (Zip-type)

def trace_hamiltonian(rng, N):
    """A random path through every cell, by Warnsdorff with a random tie-break
    and backtracking. Cells are r*N+c."""
    def nbrs(i):
        r, c = divmod(i, N)
        for dr, dc in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            rr, cc = r + dr, c + dc
            if 0 <= rr < N and 0 <= cc < N: yield rr * N + cc
    start = rng.randrange(N * N)
    path = [start]; used = {start}
    def rec():
        if len(path) == N * N: return True
        opts = [j for j in nbrs(path[-1]) if j not in used]
        rng.shuffle(opts)
        opts.sort(key=lambda j: sum(1 for k in nbrs(j) if k not in used))
        for j in opts:
            path.append(j); used.add(j)
            if rec(): return True
            path.pop(); used.discard(j)
        return False
    sys.setrecursionlimit(10000)
    return path if rec() else None

def trace_count(N, numbers, walls, limit=2, budget=200000):
    """Paths through every cell that hit 1..k in order, end on k, and cross no
    wall. Stops at `limit`, or at `budget` steps (returned as -1: too slow, skip)."""
    k = max(numbers)
    pos = {numbers[i]: i for i in range(N * N) if numbers[i]}
    blocked = set()
    for a, b in walls: blocked.add((a, b)); blocked.add((b, a))
    def nbrs(i):
        r, c = divmod(i, N)
        for dr, dc in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            rr, cc = r + dr, c + dc
            if 0 <= rr < N and 0 <= cc < N and (i, rr * N + cc) not in blocked: yield rr * N + cc
    used = [False] * (N * N); found = 0; steps = 0
    def rec(i, need, depth):
        nonlocal found, steps
        steps += 1
        if steps > budget or found >= limit: return
        if depth == N * N:
            if need > k: found += 1
            return
        for j in nbrs(i):
            if used[j]: continue
            nj = numbers[j]
            if nj and nj != need: continue
            if nj == k and depth != N * N - 1: continue
            used[j] = True
            rec(j, need + 1 if nj else need, depth + 1)
            used[j] = False
    used[pos[1]] = True
    rec(pos[1], 2, 1)
    return -1 if steps > budget else found

def gen_trace_one(rng, N=6):
    path = trace_hamiltonian(rng, N)
    if not path: return None
    k = rng.randint(6, 9)
    # 1 at the start, k at the end, the rest spread along the path at least two
    # cells apart, so the line has to wander between numbers.
    inner = sorted(rng.sample(range(2, N * N - 2), k - 2))
    if any(b - a < 2 for a, b in zip(inner, inner[1:])): return None
    numbers = [0] * (N * N)
    for n, idx in enumerate([0] + inner + [N * N - 1], start=1):
        numbers[path[idx]] = n
    # Walls only between neighbours the path does not step across, so the answer
    # stays valid. Start with two and add more until the board has one line.
    step = set(zip(path, path[1:])) | set(zip(path[1:], path))
    cand = []
    for i in range(N * N):
        r, c = divmod(i, N)
        if c + 1 < N and (i, i + 1) not in step: cand.append((i, i + 1))
        if r + 1 < N and (i, i + N) not in step: cand.append((i, i + N))
    rng.shuffle(cand)
    walls = cand[:2]
    while True:
        c = trace_count(N, numbers, walls)
        if c == 1: break
        if c == -1 or len(walls) >= 10 or len(walls) + 2 > len(cand): return None
        walls = cand[:len(walls) + 2]
    return {'n': N, 'numbers': [numbers[r * N:(r + 1) * N] for r in range(N)],
            'walls': [list(w) for w in walls]}

def gen_trace(rng, count=400):
    out, seen = [], set()
    tries = 0
    while len(out) < count and tries < count * 40:
        tries += 1
        if len(out) % 50 == 0 and tries % 50 == 1: print(f"  trace {len(out)}", file=sys.stderr, flush=True)
        p = gen_trace_one(rng)
        if not p: continue
        key = json.dumps(p)
        if key in seen: continue
        seen.add(key); out.append(p)
    return out

# ---------------------------------------------------------------- main

def write(name, data):
    path = os.path.join(CONTENT, name)
    with open(path, 'w') as f:
        json.dump(data, f, separators=(',', ':'))
    print(f"  {name}: {len(data)} puzzles, {os.path.getsize(path)//1024} KB", file=sys.stderr, flush=True)

if __name__ == '__main__':
    only = set(sys.argv[1:])   # e.g. `gen.py ladders threads` re-deals just those
    if 'candidates' in only:
        print_candidates(random.Random()); sys.exit(0)
    print("dealing...", file=sys.stderr)
    if not only or 'ladders' in only: write('ladders.json', gen_ladders(random.Random(SEED + 1)))
    if not only or 'threads' in only: write('threads.json', gen_threads())
    if not only or 'balance' in only: write('balance.json', gen_balance(random.Random(SEED + 2)))
    if not only or 'pearls' in only: write('pearls.json', gen_pearls(random.Random(SEED + 3)))
    if not only or 'trace' in only: write('trace.json', gen_trace(random.Random(SEED + 4)))
    # Every re-deal invalidates the old ratings, so rate what was just written.
    import rate
    rate.main(only if only else ())

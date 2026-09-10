// Plays the second person, against the real bridge.
//
// There is nobody else to add. This mints a player the same way the app does,
// gives it a fish so its row is not a default grey slime, prints its code, and
// then sits on a 25-minute shift so the friend row on the phone has something to
// say. Point the simulator at the real bridge, open Add a friend, and type the
// code it printed.
//
//   node test/fake-friend.js
//   node test/fake-friend.js --minutes 45 --species ember --costume ninja --scene reef
//
// It reads ios/Resources/bridge-config.json for the address and the key, which is
// the same file the app reads, so there is nothing to configure twice.
//
// It calls only the functions the app calls: create_player, join_pod (the only
// anon-callable way to set a kin — see set_kin in bridge/schema.sql, which is
// revoked from public), set_tank, my_code, start_focus, push_today, push_result,
// fetch_friends and send_vibe. Every one of them is in bridge/schema.sql,
// schema-social.sql or schema-friends.sql, and all three have to have been run in
// the Supabase SQL editor first.

const fs = require('fs');
const path = require('path');

const CONFIG = path.join(__dirname, '..', 'ios', 'Resources', 'bridge-config.json');

function config() {
  if (!fs.existsSync(CONFIG)) {
    throw new Error(`no ${CONFIG} — run bridge/apply-config.sh first`);
  }
  const { url, publishableKey } = JSON.parse(fs.readFileSync(CONFIG, 'utf8'));
  if (!url || !publishableKey) throw new Error('bridge-config.json is half filled in');
  return { url: url.replace(/\/$/, ''), key: publishableKey };
}

function arg(name, fallback) {
  const i = process.argv.indexOf(`--${name}`);
  return i > 0 && process.argv[i + 1] ? process.argv[i + 1] : fallback;
}

class FakeFriend {
  constructor({ url, key }) {
    this.url = url; this.key = key; this.id = null; this.token = null;
  }

  async rpc(fn, body) {
    const res = await fetch(`${this.url}/rest/v1/rpc/${fn}`, {
      method: 'POST',
      headers: { apikey: this.key, Authorization: `Bearer ${this.key}`, 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    const text = await res.text();
    let parsed = null;
    try { parsed = text ? JSON.parse(text) : null; } catch { parsed = text; }
    if (res.status < 200 || res.status >= 300) {
      const why = parsed && parsed.message ? parsed.message : text.slice(0, 200);
      throw new Error(`${fn} answered ${res.status}: ${why}`);
    }
    return parsed;
  }

  who() { return { p_player: this.id, p_token: this.token }; }

  async mint() {
    const row = await this.rpc('create_player', {});
    if (!row || !row.id) throw new Error('create_player answered nothing');
    this.id = row.id; this.token = row.token; this.adj = row.adj; this.noun = row.noun;
    return row;
  }

  /// The kin. join_pod is what carries species, look and level onto the players
  /// row, so this is a real pod join and not a side door.
  async setKin({ species, look, level }) {
    return this.rpc('join_pod', { ...this.who(), p_species: species, p_look: look, p_level: level });
  }

  async setTank({ costume, scene }) {
    return this.rpc('set_tank', { ...this.who(), p_costume: costume, p_scene: scene });
  }

  async code() { return this.rpc('my_code', this.who()); }

  /// The bridge decides the end time; this returns whatever it decided.
  async startShift(minutes) {
    return this.rpc('start_focus', { ...this.who(), p_minutes: minutes });
  }

  async endShift() { return this.rpc('end_focus', this.who()); }

  /// Who has typed this player's code. Empty until the phone does.
  async friends() { return this.rpc('fetch_friends', this.who()); }

  /// Four small counts for today, the same four the phone pushes.
  async pushToday({ day, tasks, focus, lessons, games }) {
    return this.rpc('push_today', {
      ...this.who(), p_day: day, p_tasks: tasks, p_focus: focus,
      p_lessons: lessons, p_games: games,
    });
  }

  /// One board. First write wins on the bridge, so a repeat is a no-op rather
  /// than a better time.
  async pushResult({ puzzle, game, solved, seconds }) {
    return this.rpc('push_result', {
      ...this.who(), p_puzzle: puzzle, p_game: game,
      p_solved: solved, p_seconds: seconds ?? null,
    });
  }

  /// One vibe per pair per day. Answers false when today's is already sent,
  /// which is not an error.
  async sendVibe({ friend, kind, day }) {
    return this.rpc('send_vibe', { ...this.who(), p_friend: friend, p_kind: kind, p_day: day });
  }
}

/// The puzzle number the app is on, counted the same way `PlayDeal.number` counts
/// it: days from 2026-01-01 in the DEVICE's calendar, first day is 1. Keying on
/// this rather than a date is the single most load-bearing line in
/// bridge/schema-social.sql — two friends in different time zones reach the same
/// puzzle hours apart.
function puzzleNumber(now = new Date()) {
  const first = new Date(2026, 0, 1);
  const day = 24 * 60 * 60 * 1000;
  const start = (d) => new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime();
  return Math.max(1, Math.round((start(now) - start(first)) / day) + 1);
}

function today(now = new Date()) {
  const two = (n) => String(n).padStart(2, '0');
  return `${now.getFullYear()}-${two(now.getMonth() + 1)}-${two(now.getDate())}`;
}

(async () => {
  const friend = new FakeFriend(config());
  const minutes = Number(arg('minutes', 25));
  const species = arg('species', 'ember');
  const look = arg('look', 'classic');
  const level = Number(arg('level', 3));
  const costume = arg('costume', 'none');
  const scene = arg('scene', 'reef');
  // An index into the app's own list of drawn cards. The bridge only checks the
  // range, so this stays valid whatever the six turn out to look like.
  const vibeKind = Number(arg('vibe', 0));

  const row = await friend.mint();
  console.log(`minted ${row.id}`);

  await friend.setKin({ species, look, level });
  await friend.setTank({ costume, scene });
  console.log(`kin: ${species} / ${look} / stage ${level}, wearing ${costume} in ${scene}`);

  const code = await friend.code();
  console.log('');
  console.log(`  their code is  ${String(code).slice(0, 4)}-${String(code).slice(4)}`);
  console.log('');
  console.log('  Type it into the phone: Friends → Add a friend → THEIR CODE.');
  console.log('');

  const ends = await friend.startShift(minutes);
  console.log(`on shift until ${ends} (${minutes} min)`);

  // Today's four counts, pushed straight away so the phone has something to draw
  // the moment the friendship is made. Numbers a person could plausibly have done
  // in a day; the bridge caps them anyway.
  await friend.pushToday({ day: today(), tasks: 4, focus: 75, lessons: 2, games: 3 });
  console.log('today: 4 tasks, 75 min focus, 2 lessons, 3 games');

  // One solved board on today's puzzle. `word` is in every version of the
  // play_results check constraint, so it is the safe one to seed with.
  const puzzle = puzzleNumber();
  await friend.pushResult({ puzzle, game: 'word', solved: true, seconds: 96 });
  console.log(`board: word ${puzzle} solved in 96s`);

  console.log('');
  console.log('Leave this running. Ctrl-C ends the shift and leaves the friendship in place.');

  const stop = async () => {
    try { await friend.endShift(); console.log('\nshift ended'); } catch { /* the row expires on its own */ }
    process.exit(0);
  };
  process.on('SIGINT', stop);
  process.on('SIGTERM', stop);

  // Keeps the shift alive past its own end so the row on the phone stays useful
  // for as long as this is left open, and sends one vibe the first time the phone
  // shows up on the friend list. A vibe needs a friendship, so it cannot be sent
  // until somebody has typed the code above.
  let vibed = false;
  setInterval(async () => {
    try {
      await friend.startShift(minutes);
      if (vibed) return;
      const list = await friend.friends();
      if (!Array.isArray(list) || list.length === 0) return;
      const them = list[0];
      const landed = await friend.sendVibe({ friend: them.id, kind: vibeKind, day: today() });
      vibed = true;
      console.log(landed ? `sent vibe ${vibeKind} to ${them.id}` : 'vibe already sent today');
    } catch (e) {
      console.error(String(e.message));
    }
  }, 20 * 1000);
})().catch((e) => {
  console.error(String(e.message));
  console.error('\nIf that says a function does not exist, the three schema files have not');
  console.error('been pasted into the Supabase SQL editor yet: schema.sql, then');
  console.error('schema-social.sql, then schema-friends.sql.');
  process.exit(1);
});

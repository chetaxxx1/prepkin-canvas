// Calls every bridge function the app, the widget and the extension use, against
// the live Supabase project, with throwaway players, and prints one line each.
//
//   node test/bridge-probe.js
//
// It reads ios/Resources/bridge-config.json like the app does. It mints two
// players (A and B), makes them friends, walks every call the phone makes with
// the same argument names and checks the answer has the keys the Swift decoders
// read (FriendSync.swift, LeagueSync.swift, StudySync.swift, CanvasSync.swift).
// It also sends the ids the app really sends today — a picked coat as a species,
// a costume id as a look — and reads them back, because the bridge allowlists
// coalesce an unknown id away silently rather than erroring.
//
// At the end both players are deleted (forget_player cascades every row they
// own) and the pairing is deleted, so nothing is left behind.

const fs = require('fs');
const path = require('path');

const CONFIG = path.join(__dirname, '..', 'ios', 'Resources', 'bridge-config.json');
const { url, publishableKey: key } = JSON.parse(fs.readFileSync(CONFIG, 'utf8'));
const URL = url.replace(/\/$/, '');

async function rpc(fn, body) {
  const res = await fetch(`${URL}/rest/v1/rpc/${fn}`, {
    method: 'POST',
    headers: { apikey: key, Authorization: `Bearer ${key}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  const text = await res.text();
  let parsed = null;
  try { parsed = text ? JSON.parse(text) : null; } catch { parsed = text; }
  if (!res.ok) {
    const why = parsed && parsed.message ? parsed.message : text.slice(0, 160);
    throw new Error(`${res.status} ${why}`);
  }
  return parsed;
}

const results = [];
function line(name, ok, note = '') {
  results.push({ name, ok, note });
  console.log(`${ok ? 'ok  ' : 'FAIL'}  ${name.padEnd(18)} ${note}`);
}
async function probe(name, run) {
  try { line(name, true, (await run()) || ''); }
  catch (e) { line(name, false, String(e.message)); }
}
function need(obj, keys) {
  const missing = keys.filter((k) => obj == null || !(k in obj));
  if (missing.length) throw new Error(`missing keys ${missing.join(',')} in ${JSON.stringify(obj).slice(0, 160)}`);
}

const ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
function makeCode() {
  const s = Array.from({ length: 8 }, () => ALPHABET[Math.floor(Math.random() * ALPHABET.length)]).join('');
  return `${s.slice(0, 4)}-${s.slice(4)}`;
}
function today() {
  const n = new Date(), two = (x) => String(x).padStart(2, '0');
  return `${n.getFullYear()}-${two(n.getMonth() + 1)}-${two(n.getDate())}`;
}
function puzzleNumber() {
  const first = new Date(2026, 0, 1), now = new Date();
  const start = (d) => new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime();
  return Math.max(1, Math.round((start(now) - start(first)) / 86400000) + 1);
}
function isoWeek(d = new Date()) {
  const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
  const day = t.getUTCDay() || 7;
  t.setUTCDate(t.getUTCDate() + 4 - day);
  const y = t.getUTCFullYear();
  const w = Math.ceil(((t - Date.UTC(y, 0, 1)) / 86400000 + 1) / 7);
  return `${y}-W${String(w).padStart(2, '0')}`;
}

(async () => {
  const A = {}, B = {};
  const who = (p) => ({ p_player: p.id, p_token: p.token });

  // Ids the app really sends: FirstRun.publicSpecies sends the picked coat as a
  // species, join_pod's look is OwnedChibi.skinID (a costume id), set_tank's
  // costume is GameState.activeCostumeID (a costume id, or 'none').
  const SPECIES = 'coral', LOOK = 'hoodie', COSTUME = 'flannel', SCENE = 'deep';

  await probe('fetch_flags', async () => {
    const f = await rpc('fetch_flags', {});
    return JSON.stringify(f).slice(0, 80);
  });

  await probe('create_player', async () => {
    const a = await rpc('create_player', {}); need(a, ['id', 'token', 'adj', 'noun']);
    const b = await rpc('create_player', {}); need(b, ['id', 'token', 'adj', 'noun']);
    Object.assign(A, a); Object.assign(B, b);
    return `A=${a.id.slice(0, 8)} B=${b.id.slice(0, 8)}`;
  });

  await probe('join_pod', async () => {
    const r = await rpc('join_pod', { ...who(A), p_species: SPECIES, p_look: LOOK, p_level: 2 });
    need(r, ['pod', 'week', 'tier']);
    const r2 = await rpc('join_pod', { ...who(B), p_species: 'sprout', p_look: 'classic', p_level: 1 });
    need(r2, ['pod', 'week', 'tier']);
    A.pod = r.pod;
    return `pod=${r.pod.slice(0, 8)} week=${r.week} tier=${r.tier}${r.pod === r2.pod ? ' (same pod)' : ' (different pods)'}`;
  });

  await probe('fetch_pod', async () => {
    const r = await rpc('fetch_pod', who(A));
    need(r, ['pod', 'week', 'tier', 'members']);
    const me = r.members.find((m) => m.you);
    need(me, ['you', 'adj', 'noun', 'species', 'look', 'level', 'points']);
    const notes = [`${r.members.length} members`];
    if (me.species !== SPECIES) notes.push(`DRIFT species sent '${SPECIES}' read back '${me.species}' (kin_species allowlist)`);
    if (me.look !== LOOK) notes.push(`DRIFT look sent '${LOOK}' read back '${me.look}' (kin_looks allowlist)`);
    if (notes.length > 1) throw new Error(notes.join('; '));
    return notes.join('; ');
  });

  await probe('push_points', async () => {
    const r = await rpc('push_points', { ...who(A), p_points: 120, p_species: SPECIES, p_look: LOOK, p_level: 2 });
    need(r, ['pod', 'week', 'tier', 'members']);
    const me = r.members.find((m) => m.you);
    if (me.points !== 120) throw new Error(`points ${me.points} not 120`);
    const r2 = await rpc('push_points', { ...who(A), p_points: 60, p_species: SPECIES, p_look: LOOK, p_level: 2 });
    const me2 = r2.members.find((m) => m.you);
    return `120 then 60 → board shows ${me2.points} (${me2.points === 120 ? 'held at peak' : 'follows the phone; only the tier never drops'})`;
  });

  await probe('my_code', async () => {
    A.code = await rpc('my_code', who(A));
    if (typeof A.code !== 'string' || A.code.length !== 8) throw new Error(`code ${JSON.stringify(A.code)}`);
    const again = await rpc('my_code', who(A));
    return `${A.code} (${again === A.code ? 'stable' : 'CHANGED on second ask'})`;
  });

  await probe('set_tank', async () => {
    await rpc('set_tank', { ...who(A), p_costume: COSTUME, p_scene: SCENE });
    return `sent costume=${COSTUME} scene=${SCENE}`;
  });

  await probe('add_friend', async () => {
    const own = await rpc('add_friend', { ...who(A), p_code: A.code });
    const f = await rpc('add_friend', { ...who(B), p_code: A.code });
    need(f, ['id', 'adj', 'noun', 'species', 'look', 'level', 'costume', 'scene', 'tier']);
    const notes = [`own code → ${JSON.stringify(own)}`];
    if (f.costume !== COSTUME) notes.push(`DRIFT costume sent '${COSTUME}' read back '${f.costume}' (kin_costumes allowlist)`);
    if (f.scene !== SCENE) notes.push(`DRIFT scene sent '${SCENE}' read back '${f.scene}'`);
    if (notes.length > 1) throw new Error(notes.join('; '));
    const twice = await rpc('add_friend', { ...who(B), p_code: A.code });
    return `${notes[0]}; again → ${twice ? 'same row' : 'null'}`;
  });

  await probe('fetch_friends', async () => {
    const list = await rpc('fetch_friends', who(A));
    if (!Array.isArray(list) || list.length !== 1) throw new Error(`A sees ${JSON.stringify(list).slice(0, 120)}`);
    need(list[0], ['id', 'adj', 'noun', 'species', 'look', 'level', 'costume', 'scene', 'tier', 'since']);
    if (!('shift' in list[0])) throw new Error('no shift key');
    return `A sees B, since=${list[0].since} shift=${list[0].shift}`;
  });

  await probe('push_today', async () => {
    await rpc('push_today', { ...who(B), p_day: today(), p_tasks: 4, p_focus: 75, p_lessons: 2, p_games: 3 });
    await rpc('push_today', { ...who(A), p_day: today(), p_tasks: 1, p_focus: 20, p_lessons: 0, p_games: 1 });
    return 'B 4/75/2/3, A 1/20/0/1';
  });

  await probe('set_sharing', async () => {
    await rpc('set_sharing', { ...who(B), p_today: true, p_board: true });
    await rpc('set_sharing', { ...who(A), p_today: true, p_board: true });
    return 'both share today + board';
  });

  await probe('fetch_today', async () => {
    const rows = await rpc('fetch_today', { ...who(A), p_from: today(), p_to: today() });
    if (!Array.isArray(rows)) throw new Error(JSON.stringify(rows).slice(0, 120));
    const b = rows.find((r) => r.id === B.id);
    if (!b) throw new Error(`B's row missing: ${JSON.stringify(rows).slice(0, 160)}`);
    need(b, ['id', 'day', 'tasks', 'focus', 'lessons', 'games']);
    return `${rows.length} rows; B ${b.tasks}/${b.focus}/${b.lessons}/${b.games}`;
  });

  await probe('send_vibe', async () => {
    const first = await rpc('send_vibe', { ...who(B), p_friend: A.id, p_kind: 2, p_day: today() });
    const second = await rpc('send_vibe', { ...who(B), p_friend: A.id, p_kind: 3, p_day: today() });
    if (first !== true) throw new Error(`first answered ${JSON.stringify(first)}`);
    return `first=true second=${second} (one per day ${second === false ? 'held' : 'NOT held'})`;
  });

  await probe('fetch_visits', async () => {
    const rows = await rpc('fetch_visits', { ...who(A), p_day: today() });
    if (!Array.isArray(rows) || rows.length !== 1) throw new Error(JSON.stringify(rows).slice(0, 160));
    need(rows[0], ['id', 'adj', 'noun', 'species', 'look', 'level', 'costume', 'scene', 'tier', 'kind']);
    return `1 visitor, kind=${rows[0].kind}`;
  });

  await probe('fetch_sent', async () => {
    const ids = await rpc('fetch_sent', { ...who(B), p_day: today() });
    if (!Array.isArray(ids) || ids[0] !== A.id) throw new Error(JSON.stringify(ids).slice(0, 120));
    return `B sent to ${ids.length}`;
  });

  await probe('push_result', async () => {
    await rpc('push_result', { ...who(B), p_puzzle: puzzleNumber(), p_game: 'word', p_solved: true, p_seconds: 96 });
    await rpc('push_result', { ...who(A), p_puzzle: puzzleNumber(), p_game: 'sort', p_solved: true, p_seconds: 140 });
    return `puzzle ${puzzleNumber()} (not called by the app; fake-friend.js only)`;
  });

  await probe('friend_board', async () => {
    const rows = await rpc('friend_board', { ...who(A), p_puzzle: puzzleNumber() });
    if (!Array.isArray(rows)) throw new Error(JSON.stringify(rows).slice(0, 120));
    return `${rows.length} rows: ${JSON.stringify(rows[0] || null).slice(0, 100)} (not called by the app)`;
  });

  await probe('start_focus', async () => {
    const ends = await rpc('start_focus', { ...who(B), p_minutes: 25 });
    if (typeof ends !== 'string') throw new Error(JSON.stringify(ends));
    const ms = Date.parse(ends) - Date.now();
    if (!(ms > 20 * 60000 && ms < 30 * 60000)) throw new Error(`ends ${ends} is ${Math.round(ms / 60000)} min away`);
    return `B on shift, raw ends='${ends}' (${Math.round(ms / 60000)} min)`;
  });

  await probe('friends_focusing', async () => {
    const rows = await rpc('friends_focusing', who(A));
    if (!Array.isArray(rows) || rows.length !== 1) throw new Error(JSON.stringify(rows).slice(0, 160));
    need(rows[0], ['id', 'adj', 'noun', 'species', 'look', 'level', 'ends']);
    const list = await rpc('fetch_friends', who(A));
    return `A sees B on shift, ends=${rows[0].ends}; fetch_friends shift=${list[0].shift}`;
  });

  await probe('end_focus', async () => {
    await rpc('end_focus', who(B));
    const rows = await rpc('friends_focusing', who(A));
    if (rows.length !== 0) throw new Error(`still ${rows.length} after end`);
    return 'row gone';
  });

  await probe('propose_pact', async () => {
    const p = await rpc('propose_pact', { ...who(A), p_other: B.id, p_week: isoWeek() });
    need(p, ['id', 'week', 'mine', 'accepted', 'other']);
    need(p.other, ['id', 'adj', 'noun', 'species']);
    A.pact = p.id;
    return `id=${String(p.id).slice(0, 8)} week=${p.week} mine=${p.mine}`;
  });

  await probe('answer_pact', async () => {
    const p = await rpc('answer_pact', { ...who(B), p_id: A.pact, p_accept: true });
    need(p, ['id', 'accepted']);
    return `accepted=${p.accepted}`;
  });

  await probe('fetch_pacts', async () => {
    const rows = await rpc('fetch_pacts', { ...who(A), p_from: isoWeek() });
    if (!Array.isArray(rows) || rows.length !== 1) throw new Error(JSON.stringify(rows).slice(0, 160));
    return `1 race, accepted=${rows[0].accepted}`;
  });

  await probe('report_player', async () => {
    await rpc('report_player', { ...who(A), p_other: B.id });
    return 'reported B';
  });

  await probe('rotate_code', async () => {
    const fresh = await rpc('rotate_code', who(A));
    if (typeof fresh !== 'string' || fresh === A.code) throw new Error(`rotate gave ${JSON.stringify(fresh)}`);
    const old = await rpc('add_friend', { ...who(B), p_code: A.code });
    A.code = fresh;
    return `new code; old code now opens ${JSON.stringify(old)}`;
  });

  await probe('remove_friend', async () => {
    await rpc('remove_friend', { ...who(A), p_friend: B.id });
    const list = await rpc('fetch_friends', who(B));
    if (list.length !== 0) throw new Error(`B still sees ${list.length}`);
    const back = await rpc('add_friend', { ...who(B), p_code: A.code });
    if (!back) throw new Error('re-add after remove gave null');
    return 'removed both ways; re-add by new code works';
  });

  await probe('block_player', async () => {
    await rpc('block_player', { ...who(A), p_other: B.id });
    const list = await rpc('fetch_friends', who(A));
    const again = await rpc('add_friend', { ...who(B), p_code: A.code });
    if (list.length !== 0) throw new Error(`A still sees ${list.length} after block`);
    if (again !== null) throw new Error(`blocked B could re-add: ${JSON.stringify(again)}`);
    return 'friendship gone; B re-adding → null';
  });

  await probe('leave_pod', async () => {
    await rpc('leave_pod', who(B));
    const r = await rpc('fetch_pod', who(B));
    return `B fetch_pod after leave → ${JSON.stringify(r)}`;
  });

  // The pairing half: the phone claims a code, the laptop binds and pushes.
  const P = { code: null, phone: null, writer: null };
  await probe('claim_code', async () => {
    for (let i = 0; i < 5 && !P.phone; i += 1) {
      const c = makeCode();
      try { const t = await rpc('claim_code', { p_code: c }); if (typeof t === 'string') { P.code = c; P.phone = t; } }
      catch (e) { if (!String(e.message).includes('taken')) throw e; }
    }
    if (!P.phone) throw new Error('no free code in 5 tries');
    return P.code;
  });

  await probe('bind_writer', async () => {
    P.writer = await rpc('bind_writer', { p_code: P.code });
    if (typeof P.writer !== 'string') throw new Error(`bind gave ${JSON.stringify(P.writer)}`);
    const twice = await rpc('bind_writer', { p_code: P.code });
    return `bound; second bind → ${JSON.stringify(twice)}`;
  });

  await probe('push_todo', async () => {
    await rpc('push_todo', { p_code: P.code, p_token: P.writer, p_todo: {
      tasks: [{ id: 'probe-1', title: 'Probe task', course: 'PROBE 101', due: new Date(Date.now() + 86400000).toISOString(), url: '' }],
      events: [], updatedAt: new Date().toISOString(),
    } });
    return '1 task';
  });

  await probe('fetch_todo', async () => {
    const t = await rpc('fetch_todo', { p_code: P.code, p_token: P.phone });
    if (!t || !Array.isArray(t.tasks) || t.tasks.length !== 1) throw new Error(JSON.stringify(t).slice(0, 160));
    return `phone reads ${t.tasks.length} task: ${t.tasks[0].title}`;
  });

  await probe('push_state', async () => {
    await rpc('push_state', { p_code: P.code, p_token: P.phone, p_state: { coins: 30, owned: ['classic'] } });
    const s = await rpc('fetch_state', { p_code: P.code, p_token: P.writer });
    if (!s || s.coins !== 30) throw new Error(`laptop reads ${JSON.stringify(s).slice(0, 120)}`);
    return 'laptop reads coins=30 back';
  });

  await probe('delete_pairing', async () => {
    await rpc('delete_pairing', { p_code: P.code, p_token: P.phone });
    let after;
    try { after = JSON.stringify(await rpc('fetch_todo', { p_code: P.code, p_token: P.phone })); }
    catch (e) { after = `error ${e.message}`; }
    return `gone; fetch_todo after → ${after.slice(0, 60)}`;
  });

  await probe('forget_player', async () => {
    await rpc('forget_player', who(A));
    await rpc('forget_player', who(B));
    let after;
    try { after = JSON.stringify(await rpc('my_code', who(A))); } catch (e) { after = `error ${e.message}`; }
    return `A and B deleted; A my_code after → ${after.slice(0, 60)}`;
  });

  const failed = results.filter((r) => !r.ok);
  console.log(`\n${results.length - failed.length}/${results.length} ok${failed.length ? `; failed: ${failed.map((f) => f.name).join(', ')}` : ''}`);
  process.exit(failed.length ? 1 : 0);
})().catch((e) => { console.error('probe died:', e.message); process.exit(2); });

// Delete what live.test.js creates on the sandbox: the "Live: …" assignments
// in the physics course. No admin token needed — a teacher's own browser
// session (the login form, then the `_csrf_token` cookie Rails hands back)
// is enough to delete an assignment, the same way the Canvas UI does it.
//
//   node test/live-clean.js            (sweep every "Live:" assignment)
//
// live.test.js requires this and calls it in test.after with the ids it made.

const UPSTREAM = process.env.CANVAS_UPSTREAM || 'http://127.0.0.1:3000';
const TEACHER = { login: 'teacher@prepkin.test', password: 'PrepkinSandbox!2026' };

/// A cookie jar the size of this file: Rails sets a handful, we send them back.
function jar() {
  const c = {};
  return {
    take(res) { for (const line of res.headers.getSetCookie?.() ?? []) { const [kv] = line.split(';'); const i = kv.indexOf('='); c[kv.slice(0, i).trim()] = kv.slice(i + 1); } },
    header() { return Object.entries(c).map(([k, v]) => `${k}=${v}`).join('; '); },
    get(k) { return c[k]; },
  };
}

/// Log someone in through the real form and come back with a session that
/// can call the API, the way the Canvas UI does. `_csrf_token` is URL-encoded
/// in the cookie; the header wants it plain. Defaults to the teacher.
async function teacherSession(upstream = UPSTREAM, who = TEACHER) {
  const cookies = jar();
  const form = await fetch(`${upstream}/login/canvas`, { redirect: 'manual' });
  cookies.take(form);
  const html = await form.text();
  const auth = html.match(/name="authenticity_token" value="([^"]+)"/)?.[1];
  if (!auth) throw new Error('no authenticity_token on the login page');
  const res = await fetch(`${upstream}/login/canvas`, {
    method: 'POST', redirect: 'manual',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded', Cookie: cookies.header() },
    body: new URLSearchParams({ authenticity_token: auth, 'pseudonym_session[unique_id]': who.login, 'pseudonym_session[password]': who.password }),
  });
  cookies.take(res);
  if (res.status !== 302 || !cookies.get('_csrf_token')) throw new Error(`login as ${who.login} -> ${res.status}`);
  const api = async (method, p, params = null) => {
    const r = await fetch(`${upstream}/api/v1/${p.replace(/^\//, '')}`, {
      method, redirect: 'manual',
      headers: { Cookie: cookies.header(), 'X-CSRF-Token': decodeURIComponent(cookies.get('_csrf_token')), Accept: 'application/json' },
      body: params ? new URLSearchParams(params) : undefined,
    });
    cookies.take(r);
    const text = (await r.text()).replace(/^while\(1\);/, '');
    if (!r.ok) throw new Error(`${method} ${p} -> ${r.status}: ${text.slice(0, 200)}`);
    return text ? JSON.parse(text) : null;
  };
  return { api };
}

/// Delete assignments by id in one course. Returns the ids that went.
async function deleteAssignments(session, courseId, ids) {
  const gone = [];
  for (const id of ids) {
    try { await session.api('DELETE', `courses/${courseId}/assignments/${id}`); gone.push(id); }
    catch (e) { console.log(`live-clean: ${id} stayed (${e.message})`); }
  }
  return gone;
}

/// Every "Live: …" assignment left in the physics course, from earlier runs.
async function sweep(upstream = UPSTREAM) {
  const s = await teacherSession(upstream);
  const courses = await s.api('GET', 'courses?per_page=100&enrollment_type=teacher');
  const physics = courses.find((c) => c.name?.startsWith('AP Physics'));
  if (!physics) throw new Error('no AP Physics course for the teacher');
  const all = await s.api('GET', `courses/${physics.id}/assignments?per_page=100`);
  const stale = all.filter((a) => /^Live: /.test(a.name));
  const gone = await deleteAssignments(s, physics.id, stale.map((a) => a.id));
  console.log(`live-clean: course ${physics.id}, ${all.length} assignments, ${stale.length} "Live:", ${gone.length} deleted`);
  return gone.length;
}

module.exports = { teacherSession, deleteAssignments, sweep };

if (require.main === module) sweep().catch((e) => { console.error(e.message); process.exit(1); });

#!/usr/bin/env python3
"""Fill a sandbox Canvas with every page state the Prepkin skin has to survive.

    python3 seed.py --url http://localhost:3000 --token <admin access token>

Stdlib only, so there is nothing to install. Get the token from
<your canvas>/profile/settings -> "+ New Access Token".

Everything a student does is done by masquerading (`as_user_id`), so one admin
token drives the whole round trip: teacher creates, student submits, teacher grades.
That needs the "Act as users" permission, which a site admin has by default.

Safe to re-run. Users are looked up by login id before being created, and the
script refuses to touch a host that is not obviously a sandbox unless you pass
--i-know-what-im-doing.
"""

import argparse
import json
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timedelta, timezone

NOW = datetime.now(timezone.utc)


def at(**kw):
    """An ISO8601 UTC timestamp offset from now, e.g. at(days=-3, hours=2)."""
    return (NOW + timedelta(**kw)).strftime("%Y-%m-%dT%H:%M:%SZ")


class Canvas:
    def __init__(self, base, token, verbose=False):
        self.base = base.rstrip("/")
        self.token = token
        self.verbose = verbose

    def _call(self, method, path, params=None, as_user=None):
        url = f"{self.base}/api/v1/{path.lstrip('/')}"
        if as_user:
            url += ("&" if "?" in url else "?") + urllib.parse.urlencode({"as_user_id": as_user})
        body = None
        if params:
            # Canvas takes nested params as bracketed form keys. Repeat a key for a list.
            pairs = []
            for k, v in params.items():
                if isinstance(v, (list, tuple)):
                    pairs.extend((k, str(i)) for i in v)
                elif isinstance(v, bool):
                    pairs.append((k, "true" if v else "false"))
                elif v is not None:
                    pairs.append((k, str(v)))
            body = urllib.parse.urlencode(pairs).encode()
        req = urllib.request.Request(url, data=body, method=method)
        req.add_header("Authorization", f"Bearer {self.token}")
        if body:
            req.add_header("Content-Type", "application/x-www-form-urlencoded")
        try:
            with urllib.request.urlopen(req, timeout=90) as r:
                raw = r.read().decode()
        except urllib.error.HTTPError as e:
            detail = e.read().decode()[:600]
            raise SystemExit(
                f"\n  {method} {path} failed with HTTP {e.code}\n  {detail}\n\n"
                f"  If this is a field-name mismatch, send me this whole block and I will fix it."
            )
        except urllib.error.URLError as e:
            raise SystemExit(
                f"\n  Could not reach {self.base} ({e.reason}).\n"
                f"  Is the SSH tunnel up?  ssh -N -L 3000:localhost:3000 canvas@YOUR_SERVER_IP"
            )
        if raw.startswith("while(1);"):        # Canvas anti-JSON-hijack prefix
            raw = raw[len("while(1);"):]
        return json.loads(raw) if raw.strip() else {}

    def get(self, path, **kw):
        return self._call("GET", path, **kw)

    def post(self, path, params=None, **kw):
        return self._call("POST", path, params, **kw)

    def put(self, path, params=None, **kw):
        return self._call("PUT", path, params, **kw)


def find_user(api, account, login):
    """Return an existing user with this login id, or None. Makes re-runs safe."""
    hits = api.get(f"accounts/{account}/users?search_term={urllib.parse.quote(login)}&per_page=50")
    for u in hits if isinstance(hits, list) else []:
        if u.get("login_id") == login:
            return u
    return None


def user(api, account, name, login, password):
    existing = find_user(api, account, login)
    if existing:
        print(f"    = {name} (exists, id {existing['id']})")
        return existing
    u = api.post(f"accounts/{account}/users", {
        "user[name]": name,
        "user[skip_registration]": True,
        "user[terms_of_use]": True,
        "pseudonym[unique_id]": login,
        "pseudonym[password]": password,
        "pseudonym[send_confirmation]": False,
        "communication_channel[type]": "email",
        "communication_channel[address]": login,
        "communication_channel[skip_confirmation]": True,
    })
    print(f"    + {name} (id {u['id']})")
    return u


def course(api, account, name, code):
    for c in api.get(f"accounts/{account}/courses?search_term={urllib.parse.quote(code)}&per_page=50"):
        if c.get("course_code") == code:
            print(f"    = course {name} (exists, id {c['id']})")
            return c
    c = api.post(f"accounts/{account}/courses", {
        "course[name]": name,
        "course[course_code]": code,
        "course[is_public]": False,
        "offer": True,
    })
    print(f"    + course {name} (id {c['id']})")
    return c


def enrol(api, course_id, user_id, kind):
    return api.post(f"courses/{course_id}/enrollments", {
        "enrollment[user_id]": user_id,
        "enrollment[type]": kind,
        "enrollment[enrollment_state]": "active",
        "enrollment[notify]": False,
    })


def assignment(api, course_id, name, points=100, due=None, kind="online_text_entry",
               unlock=None, omit_from_final=False):
    p = {
        "assignment[name]": name,
        "assignment[points_possible]": points,
        "assignment[published]": True,
        "assignment[submission_types][]": kind,
        "assignment[description]": (
            "<p>Read the chapter, then write a short response. Three paragraphs is plenty.</p>"
            "<ul><li>State the claim.</li><li>Give one piece of evidence.</li>"
            "<li>Say what it does not explain.</li></ul>"
        ),
    }
    if due:
        p["assignment[due_at]"] = due
    if unlock:
        p["assignment[unlock_at]"] = unlock
    if omit_from_final:
        p["assignment[omit_from_final_grade]"] = True
    a = api.post(f"courses/{course_id}/assignments", p)
    return a


def submit(api, course_id, assignment_id, student_id, text):
    # A student cannot backdate `submitted_at`, masquerade or not (Canvas answers
    # 403). Lateness is the teacher's call: see mark_late().
    return api.post(f"courses/{course_id}/assignments/{assignment_id}/submissions", {
        "submission[submission_type]": "online_text_entry",
        "submission[body]": f"<p>{text}</p>",
    }, as_user=student_id)


def mark_late(api, course_id, assignment_id, student_id, days):
    """What a teacher does in the gradebook: status Late, N days late."""
    return api.put(f"courses/{course_id}/assignments/{assignment_id}/submissions/{student_id}", {
        "submission[late_policy_status]": "late",
        "submission[seconds_late_override]": int(days * 86400),
    })


def mark_missing(api, course_id, assignment_id, student_id):
    return api.put(f"courses/{course_id}/assignments/{assignment_id}/submissions/{student_id}", {
        "submission[late_policy_status]": "missing",
    })


def grade(api, course_id, assignment_id, student_id, score=None, comment=None, excuse=False):
    p = {}
    if excuse:
        p["submission[excuse]"] = True
    elif score is not None:
        p["submission[posted_grade]"] = score
    if comment:
        p["comment[text_comment]"] = comment
    return api.put(f"courses/{course_id}/assignments/{assignment_id}/submissions/{student_id}", p)


def build(api, account, verbose=False):
    print("\n  People")
    pw = "PrepkinSandbox!2026"
    teacher = user(api, account, "Dana Whitmore", "teacher@prepkin.test", pw)
    students = [
        user(api, account, "Alex Rivera", "alex@prepkin.test", pw),
        user(api, account, "Sam Okonkwo", "sam@prepkin.test", pw),
        user(api, account, "Jules Park", "jules@prepkin.test", pw),
        user(api, account, "Robin Hale", "robin@prepkin.test", pw),
    ]
    me = students[0]          # the student whose view we design against

    print("\n  Courses")
    physics = course(api, account, "AP Physics C: Mechanics", "PHYS-C-1")
    english = course(api, account, "English 11: American Voices", "ENG-11")
    empty = course(api, account, "Ceramics I", "ART-CER-1")

    for c in (physics, english, empty):
        enrol(api, c["id"], teacher["id"], "TeacherEnrollment")
        for s in students:
            enrol(api, c["id"], s["id"], "StudentEnrollment")
    print("    = everyone enrolled in all three")

    pid, eid = physics["id"], english["id"]

    print("\n  Assignments, one per state the skin has to handle")

    # --- the urgency ramp, all unsubmitted -------------------------------
    states = []
    for label, due in [
        ("Problem Set 7: Rotational Inertia", at(hours=2)),
        ("Lab writeup: Conservation of Momentum", at(days=1)),
        ("Problem Set 8: Angular Momentum", at(days=6)),
        ("Unit 4 project proposal", at(days=27)),
    ]:
        a = assignment(api, pid, label, points=50, due=due)
        states.append((label, "unsubmitted", a))
        print(f"    + {label}")

    # --- no due date at all: breaks layouts that assume a date -----------
    a = assignment(api, pid, "Extra practice (optional)", points=10, due=None, omit_from_final=True)
    print("    + Extra practice — no due date")

    # --- submitted, waiting on the teacher ------------------------------
    a_wait = assignment(api, eid, "Close reading: Song of Myself", points=40, due=at(days=-1))
    submit(api, eid, a_wait["id"], me["id"], "Whitman keeps switching who 'I' is, and that is the point.")
    print("    + Close reading — submitted, ungraded")

    # --- graded, with a comment: feeds Recent Feedback -------------------
    a_fb = assignment(api, eid, "Rhetorical analysis: Letter from Birmingham Jail", points=60, due=at(days=-5))
    submit(api, eid, a_fb["id"], me["id"], "King builds the argument on the difference between just and unjust law.")
    grade(api, eid, a_fb["id"], me["id"], score=54,
          comment="Strong on the legal distinction. Next time, quote the text earlier so the reader has it in front of them.")
    print("    + Rhetorical analysis — graded 54/60 with a comment")

    # --- a long title, to prove truncation -------------------------------
    a_long = assignment(
        api, eid,
        "Comparative essay: how do Douglass and Jacobs each construct the reader they are writing for, "
        "and what does each of them refuse to say out loud?",
        points=100, due=at(days=9))
    print("    + a deliberately very long title")

    # --- late but accepted ----------------------------------------------
    a_late = assignment(api, pid, "Problem Set 6: Work and Energy", points=50, due=at(days=-4))
    submit(api, pid, a_late["id"], me["id"], "Late. Got stuck on the pulley system.")
    mark_late(api, pid, a_late["id"], me["id"], days=2)
    grade(api, pid, a_late["id"], me["id"], score=41)
    print("    + Problem Set 6 — late, accepted, graded")

    # --- missing: scored zero. Must read neutral, never red. -------------
    a_miss = assignment(api, pid, "Reading check: Chapter 9", points=10, due=at(days=-8))
    mark_missing(api, pid, a_miss["id"], me["id"])
    grade(api, pid, a_miss["id"], me["id"], score=0,
          comment="Come see me and we will find a time to make this up.")
    print("    + Reading check — missing, 0/10  <- the tone rule's hardest case")

    # --- excused: the state most skins forget ----------------------------
    a_ex = assignment(api, pid, "Quiz corrections", points=20, due=at(days=-6))
    grade(api, pid, a_ex["id"], me["id"], excuse=True)
    print("    + Quiz corrections — excused")

    # --- other students submit too, so the gradebook is not a single row -
    for s in students[1:]:
        submit(api, eid, a_wait["id"], s["id"], "Placeholder response.")
        grade(api, eid, a_fb["id"], s["id"], score=48)

    # --- resubmitted after grading: same assignment, second attempt ---------
    a_re = assignment(api, pid, "Problem Set 5: Kinematics", points=50, due=at(days=-3))
    submit(api, pid, a_re["id"], me["id"], "First try.")
    grade(api, pid, a_re["id"], me["id"], score=30, comment="Redo part (c) and resubmit.")
    submit(api, pid, a_re["id"], me["id"], "Second try, part (c) fixed.")
    print("    + Problem Set 5 — graded 30, then resubmitted")

    # --- graded on paper: no online submission, just a score ----------------
    a_paper = assignment(api, pid, "In-class derivation check", points=20, due=at(days=-2), kind="on_paper")
    grade(api, pid, a_paper["id"], me["id"], score=18)
    print("    + In-class derivation check — on paper, graded 18/20")

    # --- a section override: my section is due Friday, the course default has no date
    section = api.post(f"courses/{pid}/sections", {"course_section[name]": "Section B"})
    api.post(f"sections/{section['id']}/enrollments", {
        "enrollment[user_id]": me["id"], "enrollment[type]": "StudentEnrollment",
        "enrollment[enrollment_state]": "active", "enrollment[notify]": False,
    })
    a_ov = assignment(api, pid, "Reading response: Chapter 10", points=15, due=None)
    api.post(f"courses/{pid}/assignments/{a_ov['id']}/overrides", {
        "assignment_override[course_section_id]": section["id"],
        "assignment_override[due_at]": at(days=4),
    })
    print("    + Reading response — no course due date, Section B due in 4 days")

    # --- a graded discussion: replying is submitting ------------------------
    gd = api.post(f"courses/{eid}/discussion_topics", {
        "title": "Graded: one sentence on Douglass's audience",
        "message": "<p>One sentence. Who is he writing to?</p>",
        "published": True, "assignment[points_possible]": 10,
        "assignment[due_at]": at(days=2), "assignment[grading_type]": "points",
    })
    print("    + Graded discussion, due in 2 days, no reply yet")

    # --- a course where the primary student is a TA: marking is not homework -
    lab = course(api, account, "Intro Lab (TA)", "LAB-TA")
    enrol(api, lab["id"], teacher["id"], "TeacherEnrollment")
    enrol(api, lab["id"], me["id"], "TaEnrollment")
    enrol(api, lab["id"], students[1]["id"], "StudentEnrollment")
    a_lab = assignment(api, lab["id"], "Lab 1 report", points=10, due=at(days=2))
    submit(api, lab["id"], a_lab["id"], students[1]["id"], "Sam's lab report.")
    print("    + Intro Lab: Alex is the TA, Sam handed in Lab 1 (a 'grading' to-do for Alex)")

    # --- Files and Outcomes tabs only exist for students once they are used ---
    # (Canvas marks an unused tab admins-only), and the skin's nav rule needs them.
    up = api.post(f"courses/{pid}/files", {"name": "notes.txt", "size": 15, "content_type": "text/plain", "parent_folder_path": "/"})
    fields = list(up["upload_params"].items()) + [("file", ("notes.txt", b"syllabus notes\n"))]
    boundary = "----prepkinseed"
    body = b""
    for k, v in fields:
        body += f"--{boundary}\r\nContent-Disposition: form-data; name=\"{k}\"".encode()
        if isinstance(v, tuple):
            body += f"; filename=\"{v[0]}\"\r\nContent-Type: text/plain\r\n\r\n".encode() + v[1] + b"\r\n"
        else:
            body += b"\r\n\r\n" + str(v).encode() + b"\r\n"
    body += f"--{boundary}--\r\n".encode()
    req = urllib.request.Request(up["upload_url"], data=body, method="POST")
    req.add_header("Content-Type", f"multipart/form-data; boundary={boundary}")
    urllib.request.urlopen(req, timeout=90).read()
    root = api.get(f"courses/{pid}/root_outcome_group")
    api.post(f"courses/{pid}/outcome_groups/{root['id']}/outcomes", {
        "title": "Rotation mastery", "description": "Can solve rotation problems", "mastery_points": 3,
        "ratings[][description]": ["Exceeds", "Meets", "Below"], "ratings[][points]": [5, 3, 0],
    })
    print("    + one file and one outcome, so Files and Outcomes show in the course nav")

    print("\n  A quiz")
    quiz = api.post(f"courses/{pid}/quizzes", {
        "quiz[title]": "Unit 4 concept check",
        "quiz[quiz_type]": "assignment",
        "quiz[published]": False,
        "quiz[due_at]": at(days=3),
        "quiz[allowed_attempts]": -1,
        "quiz[description]": "<p>Five questions. Open notes.</p>",
    })
    for q in [
        ("Angular momentum is conserved when...", "no external torque acts on the system",
         "no external force acts on the system"),
        ("A hoop and a disc roll down the same ramp. Which arrives first?", "the disc", "the hoop"),
        ("Torque is largest when the force is applied...", "perpendicular to the lever arm",
         "parallel to the lever arm"),
    ]:
        api.post(f"courses/{pid}/quizzes/{quiz['id']}/questions", {
            "question[question_name]": q[0][:40],
            "question[question_text]": q[0],
            "question[question_type]": "multiple_choice_question",
            "question[points_possible]": 2,
            "question[answers][0][answer_text]": q[1],
            "question[answers][0][answer_weight]": 100,
            "question[answers][1][answer_text]": q[2],
            "question[answers][1][answer_weight]": 0,
        })
    api.put(f"courses/{pid}/quizzes/{quiz['id']}", {"quiz[published]": True})
    print(f"    + Unit 4 concept check, 3 questions, published")

    print("\n  A discussion with replies")
    topic = api.post(f"courses/{eid}/discussion_topics", {
        "title": "Who is Whitman talking to?",
        "message": "<p>Pick one section and say who you think the 'you' is. Two or three sentences.</p>",
        "published": True,
        "discussion_type": "threaded",
    })
    for s, line in zip(students, [
        "I think the 'you' is the reader, but a future one he has not met yet.",
        "Reading it out loud changed my answer. It sounds like he is talking to one person.",
        "Section 6 feels like he is talking to the grass, honestly.",
    ]):
        api.post(f"courses/{eid}/discussion_topics/{topic['id']}/entries",
                 {"message": f"<p>{line}</p>"}, as_user=s["id"])
    print("    + 3 replies")

    print("\n  Modules, with completion requirements and a prerequisite")
    m1 = api.post(f"courses/{pid}/modules", {
        "module[name]": "Unit 4 — Rotation", "module[published]": True,
        "module[require_sequential_progress]": True,
    })
    m2 = api.post(f"courses/{pid}/modules", {
        "module[name]": "Unit 5 — Oscillation", "module[published]": True,
        "module[prerequisite_module_ids][]": m1["id"],
    })
    page = api.post(f"courses/{pid}/pages", {
        "wiki_page[title]": "Rotation: the short version",
        "wiki_page[body]": "<h2>What actually matters</h2><p>Three equations. That is the unit.</p>",
        "wiki_page[published]": True,
    })
    api.post(f"courses/{pid}/modules/{m1['id']}/items", {
        "module_item[title]": "Rotation: the short version",
        "module_item[type]": "Page", "module_item[page_url]": page["url"],
        "module_item[completion_requirement][type]": "must_view",
    })
    api.post(f"courses/{pid}/modules/{m1['id']}/items", {
        "module_item[title]": "Problem Set 7", "module_item[type]": "Assignment",
        "module_item[content_id]": states[0][2]["id"],
        "module_item[completion_requirement][type]": "must_submit",
        "module_item[indent]": 1,
    })
    api.post(f"courses/{pid}/modules/{m1['id']}/items", {
        "module_item[title]": "Unit 4 concept check", "module_item[type]": "Quiz",
        "module_item[content_id]": quiz["id"],
        "module_item[completion_requirement][type]": "min_score",
        "module_item[completion_requirement][min_score]": 4,
        "module_item[indent]": 1,
    })
    api.post(f"courses/{pid}/modules/{m2['id']}/items", {
        "module_item[title]": "Read: Hooke's law", "module_item[type]": "ExternalUrl",
        "module_item[external_url]": "https://example.org/hookes-law",
        "module_item[new_tab]": True,
    })
    # Modules are created unpublished whatever the create call says; a student
    # sees nothing until each is published after its items exist.
    for m in (m1, m2):
        api.put(f"courses/{pid}/modules/{m['id']}", {"module[published]": True})
    print("    + 2 modules, must_view / must_submit / min_score, Unit 5 locked behind Unit 4, both published")

    return {
        "teacher": teacher, "students": students, "primary_student": me,
        "courses": {"physics": physics, "english": english, "empty": empty, "lab": lab},
        "password": pw,
    }


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--url", required=True, help="e.g. http://localhost:3000")
    ap.add_argument("--token", required=True, help="admin access token from /profile/settings")
    ap.add_argument("--account", default="1", help="account id, usually 1")
    ap.add_argument("--i-know-what-im-doing", action="store_true",
                    help="allow running against a host that is not obviously a sandbox")
    args = ap.parse_args()

    host = urllib.parse.urlparse(args.url).hostname or ""
    looks_local = host in ("localhost", "127.0.0.1") or host.endswith(".test") or host.endswith(".local")
    if not looks_local and not args.i_know_what_im_doing:
        sys.exit(
            f"\n  Refusing to seed {host}.\n"
            f"  This creates users, courses and fake grades. That is fine on a sandbox and\n"
            f"  very much not fine on a real school Canvas.\n"
            f"  Pass --i-know-what-im-doing if you are certain.\n"
        )

    api = Canvas(args.url, args.token)
    who = api.get("users/self")
    print(f"\n  Connected to {args.url} as {who.get('name')} (id {who.get('id')})")

    out = build(api, args.account)

    s = out["primary_student"]
    pid = out["courses"]["physics"]["id"]
    print(f"""
  Done.

  Sign in as any of these. Password for all of them: {out['password']}

    teacher@prepkin.test   Dana Whitmore   (teacher)
    alex@prepkin.test      Alex Rivera     (student — design against this one)
    sam@prepkin.test       Sam Okonkwo     (student)
    jules@prepkin.test     Jules Park      (student)
    robin@prepkin.test     Robin Hale      (student)

  The pages worth opening first, as Alex:

    {args.url}/                            dashboard, cards + the right sidebar
    {args.url}/?dashboard_view=planner     the list view
    {args.url}/courses/{pid}/modules{' ' * 12}completion requirements, a locked module
    {args.url}/courses/{pid}/grades{' ' * 13}every grade state including excused and 0
    {args.url}/courses/{pid}/assignments{' ' * 8}the urgency ramp on one page

  Then flip the feature flags in README.md step 6 and watch what breaks.
""")


if __name__ == "__main__":
    main()

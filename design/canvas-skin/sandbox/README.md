# A Canvas you can break

A sandbox Canvas where we are both the teacher and the student, so we can make an
assignment, submit it, grade it, and see every page in every state the skin has to
survive.

Written 2026-09-04.

## Why not just use a free account

There isn't one any more. Instructure's own page says:

> The Free for Teacher program is now discontinued. Stay tuned for updates on an enhanced
> Canvas product for former Free for Teacher users launching this fall.

Free-for-Teacher went down in the April 2026 breach — 8,809 institutions, roughly 275
million users, 3.65 TB taken, and a House Homeland Security investigation. Instructure
traced the exploit to Free-for-Teacher accounts. The program did not come back.

So the sandbox is our own Canvas. That turns out to be better anyway, for a reason in
`../RESEARCH.md`: two of the seven selectors this skin leans on sit on pages Instructure
has already rewritten in React, hidden behind feature flags a school admin cannot see.
`#grades_summary` is **already gone** at any school with `restrict_quantitative_data` on.
Only an instance where we are site admin lets us flip those flags and prove the skin
degrades to plain instead of broken. No hosted Canvas will ever give us that.

## The machine

Canvas's own docs ask for 8 GB RAM, a quad-core CPU, and 150 GB of disk. The 150 GB is
generous — it counts build caches — but do not go under 80 GB.

| | Minimum | Comfortable |
|---|---|---|
| vCPU | 4 | 8 |
| RAM | 8 GB | 16 GB |
| Disk | 80 GB | 160 GB |
| OS | Ubuntu 24.04 LTS | Ubuntu 24.04 LTS |

Any provider works. The build is CPU-bound and takes roughly 45–90 minutes the first
time, so paying for more cores is paying to wait less, once.

**Do not use an ARM instance.** Several Canvas build dependencies do not have clean
aarch64 paths, and debugging that is not the project. Pick x86_64.

## Step 1 — provision and lock it down

A Canvas dev instance runs in development mode: verbose errors, relaxed settings, a known
default admin. **Never expose port 3000 to the internet.** We reach it through an SSH
tunnel, so Canvas only ever listens on localhost.

On the server, as root:

```bash
adduser --gecos "" canvas && usermod -aG sudo canvas
mkdir -p /home/canvas/.ssh && cp ~/.ssh/authorized_keys /home/canvas/.ssh/ && chown -R canvas:canvas /home/canvas/.ssh && chmod 700 /home/canvas/.ssh
sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config && systemctl reload ssh
ufw default deny incoming && ufw default allow outgoing && ufw allow 22/tcp && ufw --force enable
```

That leaves exactly one open port, key-only.

## Step 2 — Docker

As the `canvas` user:

```bash
curl -fsSL https://get.docker.com | sudo sh && sudo usermod -aG docker $USER && newgrp docker
```

## Step 3 — build Canvas

```bash
git clone --depth 1 https://github.com/instructure/canvas-lms.git ~/canvas-lms && cd ~/canvas-lms && ./script/docker_dev_setup.sh
```

Go and do something else. Near the end it runs `bundle exec rails db:initial_setup`,
which **stops and asks for the admin email and password** — that is the only interactive
moment, so check back. Use a throwaway email and a password you write down.

If the build dies on a Docker permission error, export these and run it again:

```bash
export DOCKER_BUILDKIT=0 COMPOSE_DOCKER_CLI_BUILD=0
```

Then start it:

```bash
cd ~/canvas-lms && docker compose up -d
```

## Step 4 — reach it from your Mac

```bash
ssh -N -L 3000:localhost:3000 canvas@YOUR_SERVER_IP
```

Leave that running and open `http://localhost:3000` in Chrome. Canvas thinks it is
talking to localhost, the traffic goes over SSH, and nothing is exposed.

The extension refuses plain http (`originOf()` in `background.js`, and the Connect button),
so put an https front on the tunnel. Caddy does it in one line and makes its own cert:

```bash
caddy reverse-proxy --from https://localhost:8443 --to localhost:3000
```

`https://localhost:8443` is the same origin the end-to-end harness in `test/` already
grants, so nothing in the manifest changes.

## Step 5 — fill it with every state the skin has to handle

An empty Canvas is useless for design work. `seed.py` in this folder builds a course that
already contains every page state we need to look at:

```bash
python3 seed.py --url http://localhost:3000 --token YOUR_ADMIN_TOKEN
```

Get the token from `http://localhost:3000/profile/settings` → **+ New Access Token**.

It creates one teacher, four students, two courses, and then deliberately manufactures:

| State | Why the skin needs it |
|---|---|
| Assignment not yet submitted, due in 2 hours | The amber "still counts" treatment at its tightest |
| Due tomorrow, next week, next month | The full urgency ramp on one page |
| Submitted, awaiting grading | The "you did your part" state |
| Graded with a comment | Recent Feedback in the right sidebar |
| Graded 0, missing | Must read as neutral, never red — the hardest case for the tone rule |
| Late submission, accepted | Canvas's own `.late` styling that the skin has to sit beside |
| Excused | A state most skins forget entirely |
| No due date | Breaks any layout that assumes a date is present |
| A quiz, taken and scored | `.question.correct` / `.incorrect` |
| A discussion with replies | The React redesign path |
| Modules with completion requirements | `.completion_requirement`, the #1 complaint page |
| A module locked by prerequisite | The state the no-padlocks rule has to coexist with |
| A very long assignment title | Truncation, `.ellipsis` |
| A course with no assignments at all | Every empty state |
| Graded, then resubmitted | One task, one payment, whatever the attempt count |
| Graded on paper, never submitted online | Counts as handed in |
| A section override with no course-level date | The due date is the student's own |
| A graded discussion | Replying is submitting |
| A course where the student is the TA | Someone else's work to mark is not homework |

It uses masquerade (`as_user_id`) so one admin token can submit *as* each student and then
grade as the teacher. One command, whole round trip.

## Step 6 — flip the flags that change the markup

This is the part no hosted Canvas gives you. Go to
`http://localhost:3000/accounts/site_admin/settings#tab-features` and toggle these one at
a time, reloading the affected page each time to see what the skin does:

| Flag | What it replaces | What the skin must survive |
|---|---|---|
| `modules_page_rewrite` | The whole Modules page, React | Only `.context_module` and `.context_module_item` survive |
| `student_grade_summary_upgrade` | The grades table | Everything goes; `#grade-summary-react` appears instead |
| `instui_nav` | The entire global nav rail | Every `#global_nav_*_link` id disappears |
| `instui_topnav` | The breadcrumb bar | `#breadcrumbs` stops existing |
| `files_v2` | Files | Already unstyleable; confirm it fails plain |
| `widget_dashboard` | The dashboard | Server returns an empty body |

**Checked on the sandbox, 2026-09-05:** this build (canvas-lms source as of April 2026) does
not carry those six names. Only two switchable flags remain — `modules_page_rewrite_student_view`
(per course) and `responsive_student_grades_page` (root account); the nav and top-bar rewrites
have shipped and cannot be turned off. With the modules flag on, this build disables the
Modules page entirely ("That page has been disabled for this course", then "No modules found"
on the course home) — Canvas's own behaviour, not the skin's. The grades flag changed nothing
visible. `test/live.test.js` flips both and screenshots the result.

A rule that survives all six is a rule worth shipping. Anything that leaves a half-styled
page when a flag flips gets rewritten before it ships.

Also worth setting on a course, because it needs no flag and is live at real schools
today: **Course Settings → more options → Restrict quantitative data**. That alone kills
`#grades_summary`.

## Cost control

Nothing here needs to run all the time. Snapshot the disk and destroy the box between
work sessions, or just power it off — most providers bill compute by the hour and storage
separately. A box that is off for three weeks costs the price of its disk.

## What I could not test

I wrote `seed.py` against Canvas's documented REST API but have not run it, because there
is no instance yet. Expect one or two field names to need fixing on first run. Send me the
traceback and I will fix it against the live box — that is faster than me guessing
defensively now.

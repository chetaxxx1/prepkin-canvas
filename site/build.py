#!/usr/bin/env python3
"""Turns bridge/PRIVACY.md and bridge/TERMS.md into the pages at prepkin.com.

Deliberately dependency-free and CDN-free. The Canvas skin's claim is that it
makes zero external network requests; a site that pulls a font from Google would
undercut the one thing we lead with. Everything here is inline.

Run from the repo root:  python3 site/build.py
"""
import html
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "site"

# The Chrome Web Store URL does not exist yet. Every redirect page below points
# here, so there is exactly one line to change on the day the listing goes live.
STORE_URL = "https://chromewebstore.google.com/detail/PLACEHOLDER-EXTENSION-ID"
APP_URL = "https://apps.apple.com/app/idPLACEHOLDER"

# Channels we want to tell apart in Cloudflare Web Analytics. Each becomes
# /go/<slug>/, which is a page view Cloudflare counts, then bounces to the store.
CHANNELS = ["tiktok", "reels", "shorts", "reddit", "bio", "paper", "creator"]

CSS = """
:root{
  --bg:#FBFAF7; --card:#FFFFFF; --ink:#1C1D1A; --soft:#5E625B;
  --line:#E4E2DA; --accent:#2F6E52; --accent-soft:#EAF2ED;
}
@media (prefers-color-scheme: dark){
  :root:not([data-theme="light"]){
    --bg:#14161A; --card:#1B1E23; --ink:#ECEDE9; --soft:#A3A8A0;
    --line:#2B2F35; --accent:#79C79B; --accent-soft:#1E2A24;
  }
}
:root[data-theme="dark"]{
  --bg:#14161A; --card:#1B1E23; --ink:#ECEDE9; --soft:#A3A8A0;
  --line:#2B2F35; --accent:#79C79B; --accent-soft:#1E2A24;
}
*{box-sizing:border-box}
body{
  margin:0; background:var(--bg); color:var(--ink);
  font:16px/1.65 ui-rounded,-apple-system,"SF Pro Rounded","Segoe UI",Roboto,sans-serif;
  -webkit-font-smoothing:antialiased;
}
.wrap{max-width:44rem;margin:0 auto;padding:2.5rem 1.25rem 5rem}
header.site{display:flex;align-items:center;gap:.6rem;margin-bottom:2.5rem}
header.site a.brand{
  display:flex;align-items:center;gap:.55rem;
  color:var(--ink);text-decoration:none;font-weight:650;font-size:1.05rem;
}
.dot{width:.7rem;height:.7rem;border-radius:50%;background:var(--accent);flex:0 0 auto}
nav.site{margin-left:auto;display:flex;gap:1.1rem;flex-wrap:wrap}
nav.site a{color:var(--soft);text-decoration:none;font-size:.9rem}
nav.site a:hover{color:var(--accent)}
h1{font-size:1.9rem;line-height:1.25;letter-spacing:-.01em;margin:0 0 .4rem}
h2{font-size:1.15rem;margin:2.4rem 0 .6rem;letter-spacing:-.005em}
h3{font-size:1rem;margin:1.6rem 0 .4rem}
p,ul,ol{margin:0 0 1rem}
ul,ol{padding-left:1.3rem}
li{margin:.3rem 0}
a{color:var(--accent)}
hr{border:0;border-top:1px solid var(--line);margin:2rem 0}
.updated{color:var(--soft);font-size:.88rem;margin:0 0 2rem}
.lede{font-size:1.05rem;color:var(--soft);margin:0 0 2rem}
.card{
  background:var(--card);border:1px solid var(--line);border-radius:14px;
  padding:1.1rem 1.25rem;margin:0 0 1rem;
}
.card p:last-child,.card ul:last-child{margin-bottom:0}
.card h3{margin-top:0}
.claim{
  background:var(--accent-soft);border:1px solid var(--line);border-radius:14px;
  padding:1.1rem 1.25rem;margin:0 0 2rem;font-weight:600;
}
.grid{display:grid;gap:1rem;grid-template-columns:1fr}
@media(min-width:34rem){.grid{grid-template-columns:1fr 1fr}}
code{
  font:.9em ui-monospace,SFMono-Regular,Menlo,monospace;
  background:var(--accent-soft);padding:.1em .35em;border-radius:5px;
}
footer.site{
  margin-top:4rem;padding-top:1.5rem;border-top:1px solid var(--line);
  color:var(--soft);font-size:.85rem;
}
footer.site a{color:var(--soft)}
"""


def inline(text: str) -> str:
    """Escape, then re-apply the only inline markdown these documents use."""
    t = html.escape(text, quote=False)
    t = re.sub(r"\[([^\]]+)\]\((https?://[^)]+)\)", r'<a href="\2">\1</a>', t)
    t = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", t)
    t = re.sub(r"`([^`]+)`", r"<code>\1</code>", t)
    return t


def md_to_html(md: str) -> str:
    """Enough markdown for these two documents. Not a general converter."""
    out, buf, lst = [], [], None

    def flush_para():
        if buf:
            out.append(f"<p>{inline(' '.join(buf))}</p>")
            buf.clear()

    def flush_list():
        nonlocal lst
        if lst:
            out.append("<ul>" + "".join(f"<li>{inline(i)}</li>" for i in lst) + "</ul>")
            lst = None

    for raw in md.split("\n"):
        line = raw.rstrip()
        if not line.strip():
            flush_para(); flush_list(); continue
        if line.startswith("---"):
            flush_para(); flush_list(); out.append("<hr>"); continue
        m = re.match(r"^(#{1,4}) +(.*)$", line)
        if m:
            flush_para(); flush_list()
            lvl = len(m.group(1))
            out.append(f"<h{lvl}>{inline(m.group(2))}</h{lvl}>")
            continue
        m = re.match(r"^[-*] +(.*)$", line)
        if m:
            flush_para()
            if lst is None:
                lst = []
            lst.append(m.group(1))
            continue
        flush_list()
        buf.append(line.strip())
    flush_para(); flush_list()
    return "\n".join(out)


def page(title: str, body: str, desc: str, active: str = "") -> str:
    def nav(href, label, key):
        cur = ' aria-current="page"' if key == active else ""
        return f'<a href="{href}"{cur}>{label}</a>'
    return f"""<!doctype html>
<html lang="en"><head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{html.escape(title)}</title>
<meta name="description" content="{html.escape(desc)}">
<meta name="color-scheme" content="light dark">
<style>{CSS}</style>
</head><body>
<div class="wrap">
<header class="site">
  <a class="brand" href="/"><span class="dot"></span>Prepkin</a>
  <nav class="site">
    {nav('/privacy/','Privacy','privacy')}
    {nav('/terms/','Terms','terms')}
    {nav('/support/','Support','support')}
  </nav>
</header>
{body}
<footer class="site">
  <p>Prepkin is not made or endorsed by Instructure or by your school.<br>
  Questions: <a href="mailto:support@prepkin.com">support@prepkin.com</a></p>
  <p>This page loads no fonts, no images and no scripts from anywhere else.
  Same rule as the Canvas skin.</p>
</footer>
</div>
</body></html>
"""


def strip_build_note(md: str) -> tuple[str, str]:
    """Drop the 'this file is the text, not the policy' note and pull the date."""
    # The note runs from its bold opening to the "Last updated" line. Only the
    # first sentence is bold, so anchoring on a closing ** does not work.
    md = re.sub(
        r"\*\*This file is the text\..*?(?=^Last updated:)",
        "", md, flags=re.S | re.M,
    )
    m = re.search(r"^Last updated: (.+)$", md, flags=re.M)
    updated = m.group(1).strip() if m else ""
    md = re.sub(r"^Last updated: .+$", "", md, flags=re.M)
    md = re.sub(r"^#{1,2} .*$", "", md, count=1, flags=re.M)
    return md.strip().lstrip("-").strip(), updated


def write(rel: str, text: str) -> None:
    path = OUT / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")
    print(f"  {rel}")


def main() -> None:
    print("building site/")

    # --- privacy + terms, straight from the source of truth ---
    for slug, src, title, desc in [
        ("privacy", "bridge/PRIVACY.md", "Privacy policy — Prepkin",
         "What Prepkin reads, what leaves your laptop, and how long it is kept."),
        ("terms", "bridge/TERMS.md", "Terms of service — Prepkin",
         "The terms for the Prepkin Chrome extension and iPhone app."),
    ]:
        body_md, updated = strip_build_note((ROOT / src).read_text(encoding="utf-8"))
        head = f'<h1>{title.split(" — ")[0]}</h1>'
        if updated:
            head += f'<p class="updated">Last updated {html.escape(updated)}</p>'
        write(f"{slug}/index.html", page(title, head + md_to_html(body_md), desc, slug))

    # --- home. This exists because manifest.json declares homepage_url. ---
    home = """<h1>Prepkin</h1>
<p class="lede">A Canvas skin for Chrome, and an iPhone app with a fish.</p>
<div class="claim">The Canvas skin reads nothing and sends nothing. It is pure CSS
over Canvas&rsquo;s own markup &mdash; no outside fonts, no outside images, no
analytics, and zero external network requests.</div>
<div class="grid">
  <div class="card"><h3>On your laptop</h3>
  <p>A Chrome extension restyles the Canvas you already log into. Pick a look,
  keep your session, change nothing about how Canvas works. Turn it off and the
  page goes back exactly as it was.</p></div>
  <div class="card"><h3>On your phone</h3>
  <p>Finish schoolwork and earn coins. Coins buy tanks and looks for Sprout, a
  fish who lives on your home screen. Learn holds 57 short lessons on money,
  studying and work.</p></div>
</div>
<h2>The sync is a separate half</h2>
<p>If you want your coursework on your phone, you pair the two halves yourself.
That is the only time anything leaves your laptop, and it sends your coursework
list and course grades &mdash; nothing else, to nobody else. The
<a href="/privacy/">privacy policy</a> lists every field.</p>
<p>You can use the skin and never pair a phone. Schools can allow one half
without the other.</p>
<h2>What Prepkin is not</h2>
<ul>
  <li>Not an SAT app, and not test prep.</li>
  <li>Not a grade booster. We make no claim about grades, GPA or scores.</li>
  <li>Not made or endorsed by Instructure or by your school.</li>
</ul>
"""
    write("index.html", page("Prepkin — a Canvas skin that reads nothing",
                             home,
                             "A pure-CSS Canvas skin for Chrome and an iPhone app. "
                             "The skin reads nothing and sends nothing."))

    # --- support. Both stores require a reachable support URL. ---
    support = """<h1>Support</h1>
<p class="lede">Email <a href="mailto:support@prepkin.com">support@prepkin.com</a>.
A person reads it.</p>
<div class="card"><h3>Delete my coursework</h3>
<p>Tap <strong>Disconnect</strong> in the phone app. The row is deleted straight
away. If you only remove the extension, it expires within 30 days on its own.</p></div>
<div class="card"><h3>Delete my league identity</h3>
<p>Tap <strong>Forget me</strong> in the league. Your identity and every pod row
you appear in go immediately. This cannot be undone, and we cannot do it for you
by email &mdash; there is no name or address on a league identity to look it up by.</p></div>
<div class="card"><h3>Canvas looks wrong</h3>
<p>Turn the Canvas look off in the extension&rsquo;s popup. The page returns to
plain Canvas at once. Then email us the school and the page.</p></div>
<div class="card"><h3>Cancel Prepkin Plus</h3>
<p>Apple handles the billing, so cancel in your Apple subscription settings. When
the plan ends you keep everything you already had.</p></div>
<h2>Also here</h2>
<ul>
  <li><a href="/privacy/">Privacy policy</a> &mdash; every field, and how long it is kept</li>
  <li><a href="/terms/">Terms of service</a></li>
</ul>
"""
    write("support/index.html", page("Support — Prepkin", support,
                                     "How to reach Prepkin, and how to delete your data.",
                                     "support"))

    # --- channel redirects, so installs can be told apart ---
    for ch in CHANNELS:
        body = f"""<h1>Opening the Chrome&nbsp;Web&nbsp;Store</h1>
<p class="lede">If nothing happens,
<a href="{STORE_URL}">tap here</a>.</p>"""
        doc = page(f"Prepkin — {ch}", body, "Redirecting to the Chrome Web Store.")
        doc = doc.replace(
            "<title>",
            f'<meta http-equiv="refresh" content="0;url={STORE_URL}">\n<meta name="robots" content="noindex">\n<title>',
            1,
        )
        write(f"go/{ch}/index.html", doc)

    write("go/index.html", page(
        "Prepkin", '<h1>Nothing here</h1><p><a href="/">Prepkin</a></p>',
        "Redirecting."))

    # Cloudflare Pages: 404 fallback
    write("404.html", page("Not found — Prepkin",
                           '<h1>Not found</h1><p>That page does not exist. '
                           '<a href="/">Start at the front</a>.</p>',
                           "Page not found."))

    print(f"\nSTORE_URL is still a placeholder: {STORE_URL}")
    print("Change it in site/build.py the day the listing goes live, then rerun.")


if __name__ == "__main__":
    main()

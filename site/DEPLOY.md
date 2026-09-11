# Putting prepkin.com live

Both stores block on a hosted privacy policy and a working support address.
This is how those get to exist. Written 2026-09-10.

## What is already true

- **You own prepkin.com.** Registered at GoDaddy on 2024-11-11.
- **Its DNS is already on Cloudflare.** The nameservers are
  `henry.ns.cloudflare.com` and `davina.ns.cloudflare.com`, and the A records
  resolve to Cloudflare addresses. So you already have a Cloudflare account with
  this domain in it. You do not need to sign up or transfer anything.
- **The site is built.** It is the `site/` folder in this repo: a home page, the
  privacy policy, the terms, a support page, a 404, and seven redirect pages.
  It is the `design/handoff-site/` design, turn-2 artboards, with Newsreader and
  Nunito self-hosted in `site/fonts/` and the mark and Sprout in `site/img/`.
- Right now prepkin.com returns **403**, so whatever is answering is not a site.

## Step 1 — deploy the folder

1. Go to **dash.cloudflare.com** and sign in.
2. Left sidebar: **Workers & Pages**, then **Create**, then the **Pages** tab,
   then **Upload assets**.
3. Name the project `prepkin`.
4. Drag the whole **`site`** folder in. Click **Deploy**.
5. You get a URL like `prepkin.pages.dev`. Open it. Click Privacy, Terms and
   Support and check all three load.

## Step 2 — put it on your own domain

1. In the same project: **Custom domains**, then **Set up a custom domain**.
2. Enter `prepkin.com`. Cloudflare adds the DNS record itself, because the domain
   is already on your account.
3. Repeat for `www.prepkin.com`.
4. Wait a couple of minutes, then open `https://prepkin.com/privacy/`. That URL is
   what goes in both store listings.

If prepkin.com already has a Pages project, a Worker, or a redirect rule attached
to it, that is what is returning the 403. Point the custom domain at this new
project and the old one stops answering.

## Step 3 — make support@prepkin.com work

Every page and both policies already tell people to email it, so it has to exist.

1. Cloudflare dashboard, pick **prepkin.com**, then **Email** in the sidebar,
   then **Email Routing**. Click **Get started** and let it add the DNS records.
2. **Create address**: `support@prepkin.com`, forwarding to the Gmail you read.
3. Gmail sends you a verification email. Click the link in it.
4. **Test it for real**: from a different account, email `support@prepkin.com` and
   confirm it lands in your inbox. Do not skip this. Both stores reject a dead
   contact address, and the Chrome developer account needs an address read daily.

## Step 4 — turn on analytics

This is how you measure view-to-install, which the marketing plan calls one of the
three numbers that carry the whole forecast.

1. In the Pages project: **Settings**, then **Web Analytics**, then enable it.
2. Cloudflare Web Analytics is free, needs no cookie banner, and counts page views
   per path. It does not need a script tag when it is enabled this way.
3. Then `/go/tiktok/`, `/go/reels/`, `/go/shorts/`, `/go/reddit/`, `/go/bio/`,
   `/go/paper/` and `/go/creator/` each become a counted page view before the
   viewer bounces to the store. Put a different one in each channel's link, and
   the difference between them is your channel breakdown.

## Still a placeholder

`site/build.py` has `STORE_URL` set to a fake Chrome Web Store address and
`APP_URL` to a fake App Store one, because neither listing exists yet. **On the
day they go live:** change those two lines, run `python3 site/build.py`, and
redeploy. Thirty-six links on the site point at the first one.

## The Canvas shots

The hero and the "On your laptop" card show the seeded student's real dashboard
on the self-hosted Canvas sandbox: plain Canvas on the left, the extension's
dark paper on the right. The light skin is deliberately quiet and reads as
"nothing changed" at that size, so the dark paper is the after-frame, and the
label under the hero says so.

To reshoot after the skin changes: start the sandbox VM in the Google Cloud
console, open the tunnel, then

```bash
node design/site-shots/shoot.js && python3 design/site-shots/compose.py && python3 site/build.py
```

`shoot.js` writes `before.png`, `after.png` and `after-dark.png` into
`design/site-shots/`; `compose.py` crops them into `site/img/`. If either site
image is deleted, the build leaves that block out rather than shipping an empty
frame. Chromium needs a few minutes to start when the Mac is running simulators.

## Rebuilding

The privacy and terms pages are generated from `bridge/PRIVACY.md` and
`bridge/TERMS.md`, which stay the source of truth. Edit the markdown, then:

```bash
python3 site/build.py
```

Then re-upload the folder in Cloudflare, or connect the project to the GitHub repo
so a push redeploys it.

## One rule for this site

**No outside requests.** No Google Fonts, no CDN scripts, no hosted images. The
Canvas skin's whole claim is that it makes zero external network requests, and a
marketing site that pulls a font from Google undercuts the one thing we lead with.
The CSS is inline in `build.py` and the two typefaces are `.woff2` files in
`site/fonts/` for exactly this reason. Keep it that way.

To check it after a change, look for anything that is not a store link:

```bash
grep -oh 'https\?://[^"'"'"' )]*' site/*.html site/*/index.html site/*/*/index.html | sort -u
```

The only answers should be the two store URLs and the `supabase.com` link inside
the privacy policy's own text.

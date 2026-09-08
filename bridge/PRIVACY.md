# Privacy policy — Prepkin for Canvas

**This file is the text. It is not the policy until it lives at a real, public
URL.** The Chrome Web Store listing will not accept a link into a git repo, and
the data-use certification asks you to affirm that the page exists. Put it on a
plain page you control, then paste that URL into both the store listing and the
`homepage_url` of `extension/manifest.json`.

Last updated: 5 September 2026

---

## The short version

Prepkin for Canvas reads only the Canvas you connect. Sends your coursework
list and course grades to your own phone, and makes no other request. It never
asks for your password, and nothing it collects is sold, shared, or used for
advertising.

This page also covers the weekly league in the phone app, because it uses the
same bridge. The league is the one part of Prepkin where another person can see
anything of yours: a nickname the app picked for you, your fish, and how many
coins you earned that week. Never your coursework, never your grades, never
your real name. Joining is your choice and nothing is created until you say
yes.

## What it reads

Only from a Canvas site you connected yourself, using the login session already
in your browser:

- Your courses, their names and course codes
- Your assignments and quizzes: title, due date, points, and the link back to
  Canvas
- Whether you have handed something in, and when
- Your scores and current grade in each course
- The colours you picked for your Canvas dashboard

The page skin and its receipt are worked out entirely on your laptop, from the
page in front of you. Nothing about what was changed, put back, or shown is
sent anywhere.

## What leaves your laptop

Less than what it reads. Sent to the bridge, so your phone can show it:

- Course names and codes, and your current grade in each
- Assignment and quiz titles, due dates, points, and submission times
- The Canvas site the work came from

**Deliberately not sent:** your per-assignment score history and your
assignment-group weights. Those stay on the laptop, for the panel on Canvas
only, because the phone has no use for them and they are the most identifying
thing here.

**Never collected at any point:** your Canvas password, your email address, your
name, your student ID, your browsing on any other site, or anything at all from
a site you did not connect. The league adds nothing to this list: there is no
text box anywhere in it, so there is nothing you could type for us to keep.

## Where your coursework goes, and who can read it

To a database run for this app on [Supabase](https://supabase.com), in one row.
That row is found by a pairing code, and reading or writing it also requires a
long random token that only your phone and your laptop hold. The token is stored
as a one-way hash, so the database cannot hand it back to anyone — including us.

Someone who learned your pairing code after your laptop paired cannot read the
row. The code is only usable for the fifteen minutes it takes to pair.

There is no account, no email, and no name attached to the row. But course names
and grades can identify a person, so we treat the row as your education record,
not as anonymous data.

**Nobody else can read this row.** Not other students, not people in your league
pod, not anyone with the app. It takes your token, and only your phone and your
laptop have it.

## The weekly pod, and what strangers can see

The phone app has a weekly league. If you join a pod, up to nineteen students
you do not know can see four things about you — and you can see the same four
things about each of them:

- **A nickname the app picked**, like "Quiet Otter". You cannot type a name,
  pick one, or change it. The bridge chooses two numbers and your phone looks
  them up in a list of 64 adjectives and 64 nouns that ships inside the app.
  Your real name is never part of this.
- **Your fish**: which one you have and what it is wearing. A picture, nothing
  else.
- **Its stars**: how grown your fish is, one to three. A number that only goes up.
- **The coins you earned that week.** Not your balance, not what you spent, not
  what you did to earn them.

That is the whole list. A pod row holds which week it is, which depth of water
the pod is, two numbers for the nickname, the fish, the points, the highest
points you reached that week, and the time that high point last moved — which is
there only to cap how fast any score can grow. No time is ever shown to anybody
else. The board cannot tell another student when you last opened the app, or
whether you are using it right now.

A pod row does **not** contain your coursework, course names, grades,
assignments, due dates, school, Canvas site, email, real name, student ID,
location, or anything about your device. There is no message box, no profile, no
way to add a person and no way to send a person anything. That is deliberate:
nothing in a pod is text a person chose, so there is nothing in a pod that can
be used to hurt somebody.

**The league and the Canvas sync are kept apart.** They are separate rows in
separate tables with no shared key and no way to get from one to the other.
Nobody in your pod can reach your coursework, and disconnecting Canvas does not
touch your league.

**Joining is your choice.** Until you say yes to a pod, you have no league row
on the bridge at all.

**What we cannot promise.** Your points come from your own phone, and there is
no way for the bridge to check them, so a determined person could put a number
on a board that they did not earn. The bridge caps how fast any score can grow,
and the league is climb-only — nobody's tier ever goes down, and nobody else's
score can move yours. Somebody else's inflated number costs you nothing but the
comparison.

## How long it is kept

The coursework row is deleted 30 days after your laptop last synced. A scheduled
job runs hourly and removes anything past that.

If you tap **Disconnect** in the app, the row is deleted immediately.
If you remove a school in the extension's popup, that school's work stops being
sent and is removed from the next push.

The league is kept on a different clock, because it holds a ladder you climbed
over months and a standing that quietly disappeared would be worse than none at
all:

- **Your league identity** — the nickname numbers, the fish, and your depth —
  has no expiry date and is not touched by disconnecting Canvas. It holds no
  coursework of any kind.
- **A league identity that never joined a pod** is deleted after 7 days.
- **Pod scoreboards** are deleted four weeks after their week is settled. The
  app only ever draws the current week. A pod that nobody in it ever came back
  to cannot be settled, and is deleted after six months instead.
- **Tap Forget me** in the league and your identity and every pod row you appear
  in are deleted immediately. That cannot be undone: there is no account to sign
  back into and no way to prove a new identity was you.

## Who it is for

Prepkin for Canvas is intended for students aged 13 and over. It is not
directed to children under 13, and we do not knowingly collect anything from
them. If you believe a child under 13 has used it, delete the pairing in the app
and email the address below and the row will be removed. A league identity has
to be deleted from the app itself, with **Forget me** — we cannot find one from
an email, because there is no name, address or anything else on it to look it up
by.

The pod is built for teenagers on purpose. Because a nickname comes from a word
list we ship and nothing in a pod is text a person chose, there is no way for
one student to say anything at all to another one through this app.

## Third parties

Supabase hosts the database. No analytics, advertising, tracking, or other
third-party code is included in the extension or the app. Nothing is sold or
shared for advertising, and nothing is used to build a profile.

## Your choices

- **See what is sent:** the extension's popup shows the last sync and its count.
- **Stop sending a school:** remove it in the popup. The permission is revoked.
- **Delete your coursework:** tap Disconnect in the app. The row goes
  immediately.
- **Leave the pod:** tap Leave in the league. Your seat and that week's score go
  straight away. Your nickname, your fish and your depth stay.
- **Delete your league identity:** tap Forget me in the league. Your identity and
  every pod row with you in it are deleted immediately, and cannot be restored.
- **Uninstall:** removing the extension stops all collection. The row expires
  within 30 days.

## Changes

If what is collected changes, this page changes with it and the date at the top
moves. A change that widens what is collected will be called out in the
extension's update notes.

## Contact

Email support@prepkin.com and we will help with deletion requests or anything else on this page.

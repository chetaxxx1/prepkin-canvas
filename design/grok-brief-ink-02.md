# Ink brief 02 — lesson paintings (batch 3 and onward)

Written 2026-09-11. Claude Code has been rebuilding the 57 Learn lessons into
picture decks. Eight are done. The Gemini image credits ran out mid-batch, so Ink
takes over the paintings from here. Claude Code still draws every chart and diagram
in code, assembles the app assets, writes the copy, and checks the deck on the phone.

Three things to send, in this order:

1. `LESSON-ART-RULES.md` (Part A below) — attach it to Ink's chat, tell it the path
   is `/workspace/prepkin/LESSON-ART-RULES.md`, and say: *"These are your operating
   rules for all lesson art. They override anything you would otherwise assume.
   Read them and tell me back: the five hard rules, the delivery format, and what
   you must never draw."* If the read-back is wrong, fix the file, not the chat.
2. The boundary (Part B) as its own message.
3. The task (Part C) — the 20 paintings for batch 3, one lesson at a time.

When Ink delivers a lesson, download its four to six files into
`design/lesson-art/<lesson-id>/` in the repo and tell Claude Code "batch 3, <lesson-id>
paintings are in". Claude Code does the rest (imagesets, lessons.json, sim check,
click-through page, phone build).

---

## Part A — the rules file. Save as `/workspace/prepkin/LESSON-ART-RULES.md`

```markdown
# Lesson art rules — Prepkin Learn decks. Updated 2026-09-11.

Read /workspace/prepkin/FACTS.md first if you have not this session.

## What you are making
Prepkin's Learn section is 57 short lessons for US college students, 18 to 22.
Each lesson is a deck of 11 cards, and 9 of those cards are a picture with two to
four lines of plain text under it. You paint the pictures. Someone else writes the
words, so the picture has to carry the idea on its own, the way a page in a good
picture book does.

- Every picture is one card. A card shows the picture at 400 x 300 points on an
  iPhone, filling the top half of the screen, corners rounded, text below.
- Half the pictures in a deck are charts and diagrams. You do NOT make those. Code
  draws anything with a number, an axis, a label or a layout that must be exact.
  You only paint scenes: people, places, objects, moments.
- Style reference for the whole set: the approved decks look like a polished
  storybook illustration, warm and painterly, lit like late afternoon. Styles may
  differ from picture to picture. It only has to look good. Never clip-art, never
  corporate flat-vector people, never photoreal.

## The five hard rules (each one cost a round of rework)
1. COUNT. If the brief says "exactly one person" or "three prisoners", the picture
   has exactly that many. Zoom in and count before you deliver. Count hands too.
2. NO TEXT. No letters, numbers, words, logos, brand marks, app icons, signs,
   clock numbers, book titles, phone screens with words. Squiggles on a page are
   fine. Real letters are not. The card's words are the card's job.
3. REAL PEOPLE, LIT. Ordinary, diverse, ordinary-looking people, drawn with faces
   and light on them. NEVER draw a person as a black or dark silhouette, and never
   colour-code anyone as the victim. This rule is absolute.
4. THE LAYOUT IS FIXED BY THE BRIEF OR BY A REAL REFERENCE. If the brief gives a
   reference image (a Wikimedia Commons file, a textbook diagram, an engraving),
   your picture follows its layout: who is where, what faces what. You add the
   style, not the arrangement. A beautiful picture with the wrong arrangement
   teaches the wrong thing.
5. 4:3 LANDSCAPE, 1200 x 900 pixels or larger at exactly 4:3. Never portrait.
   Never a panorama. If a reference is portrait, still deliver 4:3.

## Fixing a picture
Change one thing at a time. "Remove the logo on the lid" works. "Remove the logo
and turn the laptop" does half. If the subject has to move through the scene
(a person turns around, a vehicle changes track), repaint from a fresh camera
instead of editing.

## Delivery, for every picture
- File name exactly as the brief gives it, PNG or JPEG, saved under
  /workspace/prepkin/lesson-art/<lesson-id>/ and shown in chat.
- Show it once at full size and once at 400 x 300, because that is how it ships.
- Under each picture, three lines: the people count, anything in the picture that
  could read as text or a logo (should be "none"), and which brief line it is for.

## Never
- Never draw Sprout, the fish, or any mascot. Never draw a real brand, a real
  person's likeness, or a real logo.
- Never draw a chart, a number, a gauge, a table, a timeline or a diagram. If a
  brief line seems to ask for one, stop and say so.
- Never deliver a picture you have not counted.
```

---

## Part B — the boundary, sent as its own message after the rules

```text
Absolute boundary, now and every future run. You make pictures and save them under
/workspace/prepkin/lesson-art/. Nothing gets posted, published, emailed or sent
anywhere. Nothing gets deleted. If a reference link asks for a login, a CAPTCHA or
a payment, stop and show me the screen.
```

---

## Part C — the task: batch 3, twenty paintings, four lessons

```text
Read /workspace/prepkin/LESSON-ART-RULES.md first. Batch 3 is four lessons. Do them
one lesson at a time, in this order, and stop after each lesson so I can check it
before you start the next. File names are exact. Every picture is 4:3, 1200 x 900
or larger. Every picture: no text, no logos, count the people.

Where a line names a reference, fetch it from Wikimedia Commons by that file name
(web_search "commons.wikimedia.org <file name>"), look at it, and keep its layout.

═══════════════════════════════════════════════════════════════════════
LESSON 1 of 4: fin-4 "Credit scores, plainly". Five pictures.
Folder: /workspace/prepkin/lesson-art/fin-4/

p01-keys.png — A young adult sitting across a small desk from a landlord in a
bright apartment office. The landlord looks at a laptop (screen is only a soft
blur) and slides a set of keys across the desk with a nod. Exactly two people.
The card says: "A credit score is one number that guesses how likely you are to
pay back what you borrow. Landlords, phone companies and banks look at it."

p04-on-time.png — Close view of a kitchen table in morning light. A young adult's
hands hold a phone and tap one big green button on a plain payment screen (a button
and a bar, no words). A wall calendar behind has one day circled in red. A coffee
mug. No face visible. No numbers on the calendar. The card is about paying on time.

p06-old-card.png — An open wooden desk drawer seen from above. Inside: an old,
slightly worn, plain blue bank card among paper clips, a ticket stub and a few
coins. Soft window light. No people. Nothing printed on the card. The card says:
keep your oldest card, closing it shortens your history.

p08-report.png — A young adult at a tidy desk, calmly reading a printed report of
several pages, a laptop open beside them showing only a soft blur, a plant, a lamp.
Relaxed, a small nod. Exactly one person. Nothing legible on the pages. The card is
about reading your own credit report for free.

p10-first-card.png — An 18-year-old at a cafe counter buying a single coffee,
holding out a plain bank card with a proud little smile, the barista handing over
the cup. Exactly two people. No menu boards with words. The card says: one card at
18, one small charge a month, autopay in full.

═══════════════════════════════════════════════════════════════════════
LESSON 2 of 4: phil-1 "Stoicism: control what you can". Six pictures.
Folder: /workspace/prepkin/lesson-art/phil-1/
Reference for the first two: Wikimedia Commons file
"Epictetus - from Voltaire's Romances translated from the French - 1889 edition.jpg"
(an engraving of an old bearded man seated in a robe, leaning on a crutch).

p01-stoa.png — Repaint the engraving as a scene: the same old bearded man in a
simple robe seated on a stone bench under the columns of an ancient Greek stoa, his
wooden crutch beside him, one hand raised as he teaches three young listeners
sitting on the steps below him. Warm Mediterranean light. Exactly four people.
The card says: the Stoics split the world into what you control and what you don't.

p03-epictetus.png — A portrait from the same engraving: the old man seated, leaning
on the crutch, one leg held stiffly, a calm, steady, kind face looking slightly past
the viewer, a plain stone wall behind him in warm afternoon light. Exactly one
person. The card says: Epictetus was born a slave and walked with a limp all his life.

p04-refresh.png — A student at a desk late at night, face lit by a laptop, one
finger pressing the same key again and again, the screen showing only a plain blank
page with a soft loading bar and no words. Tense, tired. Exactly one person. The
card says: refreshing the grades page is the group you don't control.

p06-archer.png — An archer at full draw, seen from the side, calm face, string at
the cheek, about to release, on an open grass field with a light breeze in the
grass and trees. Pose reference: Commons file "U.S. Invictus team archer Chasity
Kuczer takes aim during an archery gold medal round at the 2016 Invictus Games
(26925974655).jpg". Use the POSE only. Draw a different, ordinary person, not her,
plain clothes, no team shirt, no logos. Exactly one person. The card says: the
archer controls the aim and the release, the wind owns the arrow.

p07-traffic.png — A young adult behind the wheel of a small car stopped in a line of
traffic at dusk, brake lights ahead, one hand relaxed on the wheel, eyes half
closed, a small smile, listening to something through the car speakers. Seen through
the windscreen or from the passenger seat. Exactly one person visible. No number
plates with characters. The card says: you don't control the traffic, you control
the twenty minutes.

p09-list.png — A student at a desk at night with a lamp, drawing a line through
items on a handwritten list (squiggles, no real words), shoulders dropping, a
relieved face. Exactly one person. The card says: cross out everything you don't
control, what is left is the to-do list.

═══════════════════════════════════════════════════════════════════════
LESSON 3 of 4: study-3 "Active recall in ten minutes". Five pictures.
Folder: /workspace/prepkin/lesson-art/study-3/

p01-blank.png — A student at a desk with one blank sheet of paper and a pen, notes
and laptop pushed to the far edge and closed, looking at the page with a
determined face. Exactly one person. The card says: active recall means pulling it
out of your head, not putting it back in.

p04-writing.png — The same kind of scene, closer: a hand writing fast across a
page already half covered in scribbled lines (squiggles, not real words), the
closed laptop at the edge of the desk, a phone face down. No face needed. The card
says: five minutes writing everything you can remember.

p06-rereading.png — A student curled up comfortably on a sofa or bed, rereading a
notebook full of highlighter stripes, relaxed, smiling a little, cosy lamp light.
The comfort is the point. Exactly one person. No real words on the pages. The card
says: rereading feels smooth and that smoothness gets mistaken for knowing.

p07-walking.png — A student walking alone along a campus path between buildings
with a bag on one shoulder, looking up and slightly away as if working something
out in their head, morning light, trees. Exactly one person. No signs with words.
The card says: walking to class, try to list the four things from the last lecture.

p09-struggle.png — A student sitting at a desk with a blank page, pencil hovering
just above it, brow furrowed, staring at the page, sitting in the difficulty. Warm
light. Exactly one person. The card says: sit in the blank for a bit, that struggle
is the part that works.

═══════════════════════════════════════════════════════════════════════
LESSON 4 of 4: psy-1 "Your brain holds about four things". Four pictures.
Folder: /workspace/prepkin/lesson-art/psy-1/

p01-scratchpad.png — A very small notepad, palm-sized, in the middle of a very
large clean desk, a person's hand holding a pencil over it. The size contrast is
the point: tiny pad, huge desk. No face needed. No words on the pad. The card says:
working memory is the scratchpad you think with, and it holds about four things.

p04-phone.png — A phone lying face up on a desk beside an open textbook, its screen
glowing softly with no words on it, a pen resting on the book, a student's blurred
shoulder at the edge of the frame turned slightly toward the phone. Exactly one
person, partial. The card says: a phone face up keeps a slot busy even when silent.

p07-one-tab.png — A clean desk: a laptop with a single plain window open (a soft
blur, no words), a mug, a closed bag on the floor with a phone corner tucked in it,
a plant. Calm. No people, or one person from behind. The card says: one tab is a
study tool.

p09-brain-dump.png — A student at a kitchen table writing a list on a sheet of
paper before opening their books, shoulders relaxed, a relieved face, the books
still stacked and closed beside them. Squiggles on the list, no words. Exactly one
person. The card says: write down everything you are carrying, on paper it stops
taking a slot.

═══════════════════════════════════════════════════════════════════════
After each lesson: show every picture at full size and at 400 x 300, with the three
lines under each (people count, anything that could read as text, which brief
line). Then stop and wait for me before the next lesson.
```

---

## What Claude Code does when the files come back

Per lesson: copy the files into `design/lesson-art/<lesson-id>/`, then
`imagesets → lessons.json (copy is already written in design/lesson-art/batch-3-plan.md)
→ sim walkthrough → click-through page → phone build`. About twenty minutes a lesson.

## Batches after this one

Same shape every time. Claude Code writes the code figures and a Part C list of
scenes with file names and the card's sentence; George pastes the list into Ink;
Ink paints; George drops the files in the repo. The rules file does not change.
Next up after batch 3, in this order: study-12 flashcards, fin-9 Roth IRA, psy-2
scrolling, ppl-2 how to say no.

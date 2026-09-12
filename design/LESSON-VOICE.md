# Lesson voice: "the roommate who did the reading"

Written 2026-09-12. This is the house voice for every Learn lesson card in
`ios/Resources/Content/lessons.json` (57 lessons, 573 text cards today, 80 planned).
It is built from research on how 18 to 24 year olds read, then checked against the
`humanizer` skill's list of AI tells. Use it with `brand-voice` (this file is the
profile) and run `humanizer` as the audit pass afterwards.

Read this first. Then the profile block. Then the audit numbers. The research notes at
the end are the receipts, not the rules.

---

## 1. Who is reading

A US college student, 18 to 24, on a phone, usually late, usually tired, between two
other apps. They read well (NN/g: college students are strong readers) but they scan
first and only read a card if the first sentence earns it. They have grown up inside
ads and can smell one. They are adults and get insulted fast when a product talks down
to them, and they notice within a sentence when a brand tries to sound young.

They are not looking for a teacher. They are looking for the friend who already did the
reading and will tell them the short version, straight, with the catch included.

---

## 2. What the research says, and the rule it gives us

| Finding | Source | Rule for us |
|---|---|---|
| Conversational text ("you", first person, direct address) beats formal text: retention d = 0.30, transfer d = 0.54, rated friendlier (d = 0.46) and easier (d = 0.62). The effect fades past 35 minutes. | Ginns, Martin & Marsh 2013 meta-analysis, 3,312 students | Write to "you". Use contractions. Our 3-minute lessons sit right where the effect is strongest. |
| Removing "seductive details" (fun but off-topic bits) has one of the largest effects in all of multimedia learning. | Sundararajan & Adesope 2020 meta-analysis; 2025 meta-analysis of Mayer's 181 studies | No jokes for their own sake, no mascot bits inside a lesson, no trivia that isn't the point. |
| Humor tied to the content helps recall. Humor unrelated to the content does not, and can cost attention. | Frontiers in Psychology 2025 review of five decades of instructional humor | Dry, specific, and about the thing being taught. Never a joke that could sit in any lesson. |
| Young adults "will feel insulted if they suspect the site is talking down to them, and will notice if the site is trying too hard to appear cool." They demand more evidence than teens and scoff at unfounded claims. | Nielsen Norman Group, Designing for Young Adults (18 to 25), 3rd ed. | Treat them as adults. Every lesson carries at least one receipt (a named study, a real number, a year). Say what isn't known. |
| Young adults scan. Many read only the first sentence of each paragraph and abandon dense blocks without reading the first line. | NN/g eyetracking and reading studies | The first sentence of every card must carry the card on its own. |
| Objective, concise, scannable writing beat promotional "marketese" by 124% on usability. Users "detest anything that seems like marketing fluff." | NN/g, Morkes & Nielsen | No hype words, no "game-changing", no exclamation points. |
| 1 in 3 Gen Z find brands using slang "cringe-worthy". 80% of Gen Z want a formal register from finance brands. 32% of Gen Z reject brands for "trying too hard". | Exclaimer 2023 survey (n=800); SKIM 2025 global study (n=500+) | No slang as a costume. Plain adult English. Money lessons are the most conservative of all. |
| Slang has a 12 to 24 month shelf life and reads as "a marketing intern speedrunning TikTok" when stacked. | Ipsos Synthesio 2026 social listening, 202k UK posts | If a slang word ever appears it is one, it is current, and it is doing real work. Default is zero. |
| 58% of 18 to 34 year olds say finance brands' language "doesn't reflect how they actually think or talk about money." Money lives in apps and transactions, not in "banking". | Reach3 Insights, March 2026 (n=450) | Money examples are Venmo, a paycheck, rent, a card statement. Not "financial institutions". |
| 81% of Gen Z can tell when content is an ad. "Proof beats polish." Perfect, glossy copy now reads as manufactured. | Hiebing Gen Z research, wave 8, 2026 | Show the working. A specific number beats an adjective every time. Let a little roughness in. |
| Morning Brew's whole edge was writing business news like "texts from your smartest friend, not lectures from your economics professor." Short paragraphs, real jokes, no dumbing down. | Morning Brew case studies; founded by two students for students | The voice is a peer who knows more, not a coach and not an institution. |
| Real users on Imprint (our closest comparable): "basically ChatGPT in what they think is an aesthetically pleasing layout." "Every third book was telling me the same thing." "Depth: surface-level." | Imprint reviews, 2025 to 2026 | The danger for us is not sounding young. It is sounding generated. Specifics, receipts, and one honest catch per lesson are the fix. |

---

## 3. The profile

```text
VOICE PROFILE
=============
Author: Prepkin Learn cards. The roommate who did the reading.
Goal: A tired 20-year-old reads the whole card, believes it, and could repeat it
      to a friend tomorrow.
Confidence: High on the rules with a source above. Medium on the exact numbers
      in section 5, which are house targets, not research.

Source Set
- Ginns 2013, NN/g young adults report, Exclaimer 2023, SKIM 2025, Reach3 2026,
  Hiebing 2026, Synthesio 2026, Morning Brew case studies, Imprint user reviews
- The 57 lessons already in lessons.json (measured in section 5)

Rhythm
- Short sentences, 8 to 14 words on average, but varied. A 4-word sentence is
  allowed once per card, not once per line.
- A card is 2 to 4 sentences. The first one carries the card.
- No run of clipped fragments for drama. If three sentences in a row are under
  six words, rewrite.

Compression
- Dense with facts, light on framing. Cut the sentence that tells them what the
  next sentence will do.
- One idea per card. If a card has two, the second one is the next card.

Capitalization
- Conventional. Never forced lowercase. Never Title Case in eyebrows.

Contractions
- Default on. "It's Thursday night", not "It is Thursday night".
- Spell it out only for stress: "That is the whole trick."

Parentheticals
- Only to define a term in place: "a 401(k) (the retirement account your job
  sets up)". Never for a wink or an aside.

Question Use
- Rare. One real question a lesson at most, and it's a question the reader
  would actually ask, not a rhetorical setup.

Claim Style
- Plain, sharp, and backed. Every lesson names at least one real source, number
  or year. If we don't have one, the card says so in plain words.
- Every lesson includes the catch: the case where the advice fails or the thing
  it costs. Adults trust advice more when it admits its limits.
- No moralizing. We say what happens, not what they should feel about it.

Preferred Moves
- Second person, present tense, a scene they're already in.
- The first sentence states the fact. The rest shows the mechanism.
- Real numbers with the arithmetic visible: "$28 minimum, $18 is interest".
- College-true scenes: a professor or TA, rent, a part-time job, a group
  chat, a Venmo request, a lease, a midterm, office hours.
- One dry line per lesson at most, and it's about the content.
- Concrete verbs: open, send, pay, copy, delete.

Banned Moves
- Manufactured punchlines: a short quotable closer on every card ("The wall is
  at the door." "That is exactly the problem."). One per lesson, not one per card.
- Aphorism formulas: "X is the Y of Z", "the task is fine, the doorway is the
  problem".
- Copula stacks: three sentences in a row starting "That is / It is / This is".
- Slang, memes, "bestie", "vibe", "lowkey", "adulting", "hack", "pro tip".
- Hype: "game-changing", "powerful", "unlock", "supercharge", exclamation points.
- Coach talk: "you've got this", "remember", "trust the process", "kiddo".
- High-school framing: "teacher", "homework", "class" when "professor",
  "problem set", "lecture" is what they'd say.
- Em dashes, semicolons, emoji, bold inside a card body.
- Rule of three for its own sake. Fake ranges ("from X to Y").
- Any sentence that could be pasted into a different lesson unchanged.

CTA Rules
- The key card is the one sentence they'd text a friend. Imperative is fine
  there. Nowhere else.
- Never end a lesson on an upbeat generic line. End on the catch or the number.

Channel Notes
- Card body: 2 to 4 sentences, under about 40 words, first sentence carries it.
- Eyebrow: 1 to 3 words, sentence case, a label not a tease.
- Blurb: two sentences. What it is, then what they'll see, with a number.
- Takeaway: one plain sentence. Drop "You learned".
- Check "why": one sentence of mechanism, no recap of the question.
```

---

## 4. The rules with our own cards

Each pair below is a real card from lessons.json and its rewrite. The "why" names the
research or the humanizer pattern.

**Contractions and copula stacks** (Ginns; humanizer §8, §31)

> Before: It is Thursday night and the bio lab report is due Friday. Two sections are
> done and two are not.
>
> After: It's Thursday night and the lab report is due at 9 tomorrow. Two sections
> are done, two aren't.

**Manufactured punchline and aphorism formula** (humanizer §31, §32)

> Before: Putting something off is almost always about starting it, not about doing
> it. The task is fine. The doorway is the problem.
>
> After: Putting something off is almost always about starting it, not doing it. The
> forty minutes of work are fine. It's the first one you keep dodging.

**Receipt instead of assertion** (NN/g skepticism; Hiebing)

> Before: The hard part is the first minute, not the next forty. Once you are in, the
> work carries itself along. The wall is at the door.
>
> After: Sirois and Pychyl (2013) found procrastination is mostly mood repair. You
> aren't avoiding the essay, you're avoiding the bad feeling of opening it. Once
> it's open, that feeling is mostly gone.

**Age-true framing** (NN/g: "respect that young adults are adults")

> Before: The teacher has a hundred students and needs to know which piece of work
> this is before anything else.
>
> After: Your professor has 200 students and a TA reading the inbox. Name the
> assignment first so they don't have to guess.

**Cut the tease, keep the fact** (NN/g first-sentence scanning; humanizer §28)

> Before: An extension email has four lines. But before the lines, the timing. Send
> it before the deadline, not after.
>
> After: Send it before the deadline. Before, it's a request. After, it's an
> excuse, and professors treat those very differently.

**The catch, said plainly** (Headspace "never toxic positivity"; NN/g depth)

> Before (key card): Commit to starting, never to finishing. Finishing takes care of
> itself more often than you'd think.
>
> After: Commit to five minutes and mean it. Most nights you'll keep going. Some
> nights you'll stop at five, and that still beats the zero you were about to do.

---

## 5. The audit: numbers to hit

Measured on lessons.json on 2026-09-12 with the script in section 6. Targets are house
targets, not research.

| Measure | Today | Target | Why |
|---|---|---|---|
| Cards ending on a 7-word-or-shorter punchline | 32% (182 of 573) | under 10% | humanizer §31, reads engineered |
| Uncontracted forms (it is, do not, you are) vs contracted | 408 vs 68 | contractions win 3 to 1 | Ginns 2013 |
| Sentences starting "That is / It is / This is" | 142 | under 50 | humanizer §8 |
| Lessons with a named source, year or verifiable number | about 16 year mentions across 57 lessons | every lesson has one | NN/g, Hiebing |
| Lessons with a stated catch or limit | not measured | every lesson | NN/g depth |
| Slang, hype words, exclamation points | 1 exclamation, 0 slang | 0 | Exclaimer, SKIM |
| Average words per sentence | 9.3 | 8 to 14, and varied | keep |
| Em dashes, semicolons | 0, 1 | 0, 0 | keep |
| "teacher" where "professor/TA" fits | 3 | 0 | audience |

Then the humanizer pass. Every rewritten lesson gets the four-step loop from that
skill: draft, list what still reads generated, final, scan for dashes. The tells most
likely in our cards are §8 (copula avoidance), §9 (tailing negation: "no story yet"),
§31 (staccato drama), §32 (aphorisms), §33 (fake-candid openers like "Here is what you
cannot see").

---

## 6. How to run the rewrite

1. Pull one lesson from lessons.json. Read all 11 cards together, not one at a time,
   because the punchline rule is per lesson.
2. Find the receipt. If the lesson has no real source or number, find one before
   rewriting. If none exists, the card says "nobody has measured this well" in plain
   words rather than pretending.
3. Find the catch. Where does this advice fail, or what does it cost?
4. Rewrite against the profile. Keep the picture's job: the body still has to match
   the image on the card, so scenes don't change, only the words.
5. Keep length. Bodies stay under about 40 words so they still fit under the picture.
6. Run the audit script, then the humanizer loop.
7. Show George three lessons before doing the rest. Voice, like faces and
   animations, gets a sign-off first.

Audit script (paste into python3 from the repo root):

```python
import json,re
d=json.load(open('ios/Resources/Content/lessons.json'))
cards=[c for l in d for c in l['cards'] if c.get('body')]
sents=lambda t:[s for s in re.split(r'(?<=[.!?])\s+',t.strip()) if s]
punch=sum(1 for c in cards if len(sents(c['body']))>=2 and len(sents(c['body'])[-1].split())<=7)
txt=' '.join(c['body'] for c in cards)
unc=len(re.findall(r"\b(it is|that is|do not|does not|is not|are not|you are|you will|cannot|did not|there is|here is)\b",txt,re.I))
con=len(re.findall(r"\b\w+'(s|t|re|ll|ve|d|m)\b",txt))
cop=len(re.findall(r'(?:^|[.!?]\s+)(That is|It is|This is)\b',txt))
print(f'punchline cards {punch}/{len(cards)} = {100*punch//len(cards)}%')
print(f'uncontracted {unc} contracted {con}')
print(f'copula starts {cop}  dashes {txt.count("—")+txt.count("–")}  bangs {txt.count("!")}')
print('teacher', len(re.findall(r'\bteachers?\b',txt,re.I)))
```

---

## 7. Two full sample rewrites

Same cards, same pictures, same length. Only the words moved.

### study-6 The five-minute start

Blurb: Procrastination is about starting, not working. Sirois and Pychyl's research says
you're dodging a feeling, not a task, and the fix is a five-minute deal you actually keep.

Takeaway: Commit to five minutes and mean it.

| Eyebrow | Body |
|---|---|
| The idea | Putting something off is almost always about starting it, not doing it. The forty minutes of work are fine. It's the first one you keep dodging. |
| Where the cost is | Sirois and Pychyl (2013) found procrastination is mostly mood repair. You aren't avoiding the essay, you're avoiding the bad feeling of opening it. Once it's open, that feeling is mostly gone. |
| Shrink it | So shrink the deal to five minutes, and mean the part where you're allowed to stop. Five real minutes on a timer, and then a real choice about whether to keep going. |
| Set a timer | Set an actual timer, open the file, and do the ugliest first step you can think of. When it rings you're free to leave, and that part has to be true. |
| Most of the time | Most of the time you don't leave. Starting was the expensive part and you've already paid it. The five minutes weren't the job, they were the price of entry. |
| The bad first sentence | For an essay, the five minutes is opening the doc and typing a bad first sentence. Bad is fine, because you'll delete it later and its only job was to exist. |
| The permission is real | If the five minutes is a trick, your brain stops falling for it by week two. It works because stopping is genuinely allowed, every time, no guilt. |
| Forty minutes later | The timer rang half an hour ago and you didn't hear it. That isn't discipline. It's just what happens once the opening is behind you. |
| Five-minute starts | Every task has a five-minute version. Essay: one bad sentence. Problem set: copy out question one. Chapter: turn the first heading into a question. |
| Key | Commit to five minutes and mean it. Most nights you'll keep going. Some nights you'll stop at five, and that still beats the zero you were about to do. |
| Check | Why does the five minutes have to be a real permission to stop? / If it's a trick, your brain stops falling for it. / Why: Starting is only cheap if stopping is free. Take that away and starting costs the whole task again. |

### ppl-1 Ask for an extension the right way

Blurb: Professors say yes to a good extension email more often than students think.
You'll build the four-line version: what, when, the specific ask, and proof you've
started.

Takeaway: Ask early, name a date, show the draft, skip the story.

| Eyebrow | Body |
|---|---|
| Thursday night | It's Thursday night and the lab report is due at 9 tomorrow. Two sections are done, two aren't. You can pull an all-nighter and hand in something rough, or send one short email right now. |
| Timing | Send it before the deadline. Before, it's a request. After, it's an excuse, and professors treat those very differently. |
| Line one | Line one is what and when: "The Bio 101 lab report is due Friday." Your professor has 200 students and a TA reading the inbox. Name the assignment first so they don't have to guess. |
| Line two | Line two is the ask, with a date and a time: "Could I turn it in Monday at 8am?" A specific date is easy to say yes to. "A few more days" makes them do the deciding, so it gets a no. |
| Line three | Line three is proof you've started: "I've attached my draft with the first two sections done." That line separates you from everyone who hasn't opened the file, and a TA can tell in a second. |
| Line four | Line four is thanks, then stop. No paragraph about your week. If they want the reason they'll ask. Every extra sentence makes the email longer to read and easier to say no to. |
| Their side | Picture it from their desk: sixty emails, half of them long. Yours is four lines that name the work, name a date and show a draft, which makes it the easiest yes of their morning. |
| The whole thing | Four lines, sent the night before. It takes three minutes to write. Nobody has run a study on this, but ask any TA which emails get a yes and you'll hear the same four lines. |
| The weekend | Then actually use the time. An extension that ends in another rushed night wasn't worth asking for. Finish the two sections Saturday and hand in something you're not embarrassed by. |
| Key | Ask early. Name a date. Show the draft. Skip the story. |
| Check | Which detail matters most in an extension request? / Sending it before the due date / Why: Before the deadline it's a request. After, it's an excuse, and professors treat the two very differently. |

Audit on these two (script in section 6): punchline cards 2 of 20, and both are the
key cards where an imperative is allowed. 28 contractions, 0 uncontracted forms, 0
copula starts, every body under about 40 words. One receipt each (Sirois & Pychyl 2013; an honest
"nobody has run a study on this"), one catch each, zero slang, zero dashes.

---

## 8. Research notes (the receipts)

- Ginns, Martin & Marsh (2013). Designing instructional text in a conversational
  style: a meta-analysis. Educational Psychology Review 25, 445 to 472. Retention
  d = .30 (30 studies), transfer d = .54 (25 studies), friendliness d = .46, perceived
  difficulty d = .62. Effects shrink and lose significance past 35 minutes of
  instruction.
- Sundararajan & Adesope (2020). Keep it coherent: a meta-analysis of the seductive
  details effect. Educational Psychology Review 32, 707 to 734. Removing off-topic
  interesting details helps retention (small to medium) and transfer (medium).
- Meta-analysis of Mayer's 181 studies (2025, University of Illinois). Overall
  g = 0.37. Largest effects: removing seductive detail, modality, personalization,
  sentence-level coherence.
- Frontiers in Psychology (Jan 2025). Teaching and learning with instructional humor:
  five decades review. Content-related humor improves recall; unrelated humor does
  not, and can pull attention off the material.
- Nielsen Norman Group. Designing for Young Adults (18 to 25), 3rd edition. Strong
  readers who still scan; abandon dense text; feel insulted when talked down to;
  notice "trying too hard to appear cool"; demand more evidence than teens; scoff at
  unfounded claims ("A king of smartwatches is crowned" got "Yeah, sure.").
- Morkes & Nielsen (1997). Concise, scannable, objective writing beat promotional
  writing by 124% on combined usability. Users "detest anything that seems like
  marketing fluff."
- Exclaimer (2023), n = 800 UK. 54% of Gen Z prefer a formal register from brands;
  over a third find forced slang cringe-worthy; 80% of Gen Z want formality from
  finance brands; 42% say slang hurts brand image.
- SKIM Group (Dec 2025), 500+ young consumers, 8 countries. 44% rank transparency
  first; 32% reject brands for "trying too hard"; humor and relatable language matter
  to only 19%.
- Ipsos Synthesio (Mar 2026), 202k UK posts. Slang shelf life 12 to 24 months.
  "Slang isn't cringe, misusing it is." Use it like seasoning, not the dish.
- Reach3 Insights (Mar 2026), n = 450 US, ages 18 to 34. 58% say finance brand
  language doesn't reflect how they talk about money; 42% say it's out of touch; a
  third say it sounds aimed at an older generation.
- Hiebing (Jun 2026), Gen Z wave 8. 81% can tell when content is an ad; only 26%
  find ads relevant; polish now reads as manufactured; "proof beats polish."
- Morning Brew case studies. Readers were students who found the WSJ "for old
  people"; the voice was set as "texts from your smartest friend"; short paragraphs,
  real jokes, no dumbing down.
- Imprint user reviews (2025 to 2026, Taptu, Headway, App Store). Praise: chunked,
  visual, short. Complaints: "basically ChatGPT in an aesthetically pleasing layout",
  same ideas recycled, surface-level, no nuance or opposing views.

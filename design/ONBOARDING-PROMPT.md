Rebuild the first run of the Prepkin iPhone app, in this repo (/Users/georgeshi/Desktop/app/prepkin-canvas), from a B− to an A. Every screen copies a named screen from an app that already onboards millions of students, and every question asked changes what the student sees next. The audit that grades it B− is at the top; the build plan follows. One decision is made for you: the flow asks whether the student is in high school, college or grad school, and that answer reshapes the app.

## The audit, 2026-09-12

What a new student meets today, in order (ios/Sources/FirstRunView.swift, HomeView.swift Day 1 offers, DayEditorView.swift):
1. The app opens straight onto "What do you want to name your kin?" with Shuffle and Next. No welcome, no line about what the app is, no fish to meet first.
2. "Pick three for today": Study ideas and Life care rows, Continue locked until three are picked.
3. Home. The bubble says "Tap one when it's done." The first check pays 20 coins and a toast says "20 coins. Open the shop."
4. Day 1 offer one: "Want Moss to check in tomorrow evening?" with a preview sheet before the system prompt. Good.
5. Day 1 offer two: "Want your Canvas homework here? Takes a laptop." "Show me" opens Your day with an eight-character code and "Get the Chrome extension".
6. Nothing after that. No widget card yet (planned), no "how did you hear about us", no friend code path, no school question.
The extension's own first run is three skippable steps and is already an A: "Dark mode, one list, your grades. Everything else is optional. Free · no account · no AI."

What is right: two screens to a fish with a name; no account, ever; permissions primed before the system asks and never in the first ten seconds; the first coin is a real outcome; nothing scolds; the copy is under 40 characters everywhere.

What holds it at B−, against the research and the comparables:
- No outcome is sold before the first question. Finch opens on the bird and one line ("Your new self-care best friend") and a button; ours opens on a text field.
- Nothing is personalised. The research says only ask what changes the next screen, and we ask nothing. A high-school junior, a college sophomore and a grad student get the same presets ("Read for one class"), the same Canvas wording and the same lesson order.
- The fish is not met. Finch's egg pick and hatch is the moment people screenshot; ours skips to a name field. Four Sprout coats already exist as stills, so a pick-your-coat screen costs no art.
- No result screen. Headspace's "Your style is…" and Duolingo's plan screen show what the answers unlocked; ours drops onto Home with no beat.
- The real value, Canvas, is the second of two cards at the end, worded "Takes a laptop." For a student on the phone that reads as a dead end. There is no send-to-laptop path.
- No invite path. Finch's welcome has "Have an invite?"; friend codes exist in the app and first run never mentions them.
- No attribution question. The marketing plan wants "How did you hear about us" and Finch asks it on day one.

Research used (checked 2026-09-12): 1,460 flows studied, median flows are 16 screens and length only hurts when a screen delivers nothing; Headspace's multi-select goals lifted trial conversion 10%; pre-permission screens beat raw system prompts; "show what the answers unlocked" is the pattern behind Noom, Brilliant and Headspace (daniliants.com, 2026-04). 137 flows: median 16 screens on iOS, only 5 of 137 under five screens (gummble.com, 2026-07). Ask only what changes the next screen; delay every ask until the moment it pays; end at a real outcome, not a last slide (kompassify.com, 2026-08).

## Read first
1. PRODUCT.md house rules: no exclamation marks, no meters, no streaks, no account, no scolding, every string under 40 characters, coins pay for finishing only.
2. ios/Sources/FirstRunView.swift, HomeView.swift (Day 1 offers, `isFirstSession`, `offerCard`), DayEditorView.swift (the pairing code card), Core/GameState.swift (`firstRunDone`, templates, presets), ios/Resources/Content (the preset lists), test/ios-firstrun.sh (the end-to-end first-run test; run it before you touch anything and keep it green, extending it for every new screen).
3. Memory facts: `-unlockAll` skips first run, so build and shoot without it on a fresh simulator; the four coat stills are `sprout-{mint,coral,butter,lilac}-1` in Assets; Sprout only at launch, no other species on screen; never a costume still as a placeholder; any new animation needs a GIF sign-off from George before it ships (the hatch is one).
4. .claude/skills/ios-walkthrough/SKILL.md. Session-named simulator, one at a time, delete it after. Commit your own files only.

## The flow to build, screen by screen, each with the screen it copies

Open every Mobbin link and look before you build. Use the Mobbin connector to find any reference this list lacks (search_screens, platform ios) and cite what you use. Pinterest and the web are for the hatch illustration only, not for layout.

1. Welcome. The fish in the tank, one line, one button. "Your Canvas, a fish, and coins for finishing." Buttons: "Meet your fish" (coral), "Have a friend code?" (quiet, opens the add-friend field after setup), "Already use Prepkin on another phone?" (quiet, explains there are no accounts and the laptop link is how work follows you). Copy Finch's welcome: https://mobbin.com/screens/d57f16e6-eb3b-4562-810c-0c6be6eaf239 and Saturn's one-line pitch "The calendar for students": https://mobbin.com/screens/9efc1ae1-bd4f-4332-b473-082e0f67a929. Legal line as Finch does it.

2. "Where are you in school?" Three cards: High school · College · Grad school. Sprout asks it from a speech bubble with a thin progress bar on top, Duolingo's shape: https://mobbin.com/screens/ce101753-63a5-4c96-bf23-33f584d0a4ba (Duolingo Math: "Grades 2 through 12 / University / I'm an adult learner") and https://mobbin.com/screens/6f28eb68-b3c3-43d1-a4be-fb5f43b8f930 (the bubble and bar). The answer is stored as one of three, never a school name, never a year (Saturn asks for both and it is the anti-reference: https://mobbin.com/screens/bb22cc52-0c7f-4cbd-bd2b-045ad7fdd7a8). What it changes, and this is the whole point of asking: the preset lists on the next screen and in Your day (high school: "Read the chapter", "Study for the quiz", "Ask the teacher"; college: "Read for one class", "Go to office hours", "Email a professor", "Laundry"; grad: "Write for 25 minutes", "Meet my advisor", "Lab notebook", "TA hours"); the Canvas card's wording ("your school's Canvas" vs "your college's Canvas"); the default focus length (25 for high school, 25 for college, 45 for grad); the Learn track that leads (study skills first for high school, personal finance first for college, work track first for grad); and the sample course names anywhere sample data shows.

3. "What's on your plate?" Multi-select, Headspace's shape, at least one required: "Homework I keep putting off" · "Big exams coming" · "Staying focused" · "Getting a routine" · "Studying with friends" · "Something else". https://mobbin.com/screens/6aba84cc-e359-446c-8cf3-b10cae809456 and Duolingo's multi-select with the bubble: https://mobbin.com/screens/1a2c3854-ea7a-41fa-ab1b-95466c2c0228. What it changes: the order of the three suggested picks on screen 6, which Day 1 offer comes first (exams → the Canvas card first; focus → the check-in card first; friends → the friend code path is offered on Day 2), and the first Learn suggestion.

4. Pick your coat. Four Sprout coats on their stills in a ring, the tank behind, "Meet" as the button. Finch's egg pick: https://mobbin.com/screens/9a45c4b2-8ef7-4b6b-af4f-434673afd0c0. Then the reveal: the tank, the fish swims in and waves, the name field rises. This is the one animation; record a GIF for George before it ships. Finch's hatch beat: https://mobbin.com/screens/e35e65d4-5375-4ea1-99f1-b83e54d88140 and https://mobbin.com/screens/597d5b39-b912-43a6-8b6c-8e6045260727. Sprout is the only species; a coat is a colour, so nothing here contradicts "Sprout only at launch".

5. Name. Keep as built: "What do you want to name your kin?", "You can change this later.", Shuffle, Next. Finch's exact screen: https://mobbin.com/screens/0b3973cb-4909-47e5-a90f-aa289957b6d4. Now it sits under the fish that was just picked.

6. "Pick three for today." Keep as built, with the lists from screen 2 and the order from screen 3, and three already suggested (ticked) so Continue is live on arrival; the student can swap. Finch's first-goals screen: https://mobbin.com/screens/75c0006a-8e29-4db7-bbc6-7bcf3d6c7655.

7. "Your day is set." One screen: the fish, the three picks with their coins, and one line: "Finish one and Moss gets paid. That's the whole thing." Then "Let's go". Headspace's "Your style is…" result: https://mobbin.com/screens/71a1f085-c0df-44b4-9675-7cbe8b429094 and its plan screen: https://mobbin.com/screens/3ab1a91f-775e-4f76-9610-f6ca895349e7. No plan length, no dates, no meter.

8. Home. Keep as built: the bubble says "Tap one when it's done." The first check pays and the toast says so. This is the outcome the flow ends at.

9. Day 1 offer, check-in. Keep as built, the preview sheet before the system prompt, Finch's pre-permission: https://mobbin.com/screens/3e88469e-f60a-439d-ac4d-0bd06fd8eae4.

10. Day 1 offer, Canvas, rewritten as the main event. Title "Your Canvas homework can live here." Body: a small laptop drawing, the eight-character code big and monospaced, and two buttons: "I'm at my laptop" (opens Your day with the code and the extension link as today) and "Send the link to my laptop" (the system share sheet with the extension page link and the code, so AirDrop, Messages or Mail carries it). "Not now" stays. Copy the code screen shape from Finch's friend-code sheet: https://mobbin.com/screens/73949f04-5c45-45ab-b427-642c3dee5229. Never "Takes a laptop."

11. Day 2 card: the widget install card from design/WIDGET-NOTIFICATIONS-PROMPT.md, if the widget exists; otherwise skip.

12. Day 3 card: "How did you hear about Prepkin?" One tap: TikTok · A friend · App Store · Reddit · Somewhere else. Stored locally as one of five, shown once, never repeated, the marketing plan's one instrument. Finch asks it; search Mobbin "Finch how did you hear about us" and cite the id.

Rules for the whole flow: a thin progress bar across screens 2–7 (Duolingo's); Back on every screen; every question skippable except the coat and the name; every string under 40 characters; no account, no email, no school name, no year; the fish is on every screen from 4 onward; nothing counts, nothing warns; the flow can be interrupted and resumes where it stopped (persist the step).

## Prove it
- Unit tests: the school answer maps to the right preset list, focus default, Canvas wording and Learn lead for all three answers; the plate answers reorder picks and offers as specified; the flow resumes at the saved step; the attribution answer stores one of five and shows once.
- Extend test/ios-firstrun.sh through every screen: welcome → school → plate → coat → name → picks → result → Home → first coin → both Day 1 cards. Screenshot every step into design/screenshots/firstrun-<date>/ with a README naming the Mobbin screen each copies.
- Run the flow three times on a fresh simulator, once per school answer, and put the three Home screens side by side to prove the answer changed something.
- A GIF of the hatch for George. Do not ship the animation without his yes.
- The copy sweep test covers every new string.

What an A looks like: a student opens the app, sees a fish and one sentence, answers two questions that visibly change what comes next, picks a fish and names it, is handed three things to finish today that fit their kind of school, and gets a coin two minutes in. Canvas is offered as the main event with a way to reach the laptop from the phone. Nothing asks for an account, a school name, or a permission before it has earned it.

Finish with: the screenshots and README, the three side-by-side Homes, the GIF, the test count and result, and the commits, one per screen.

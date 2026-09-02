import Foundation

/// User-controlled switches. Reminders default to off — nothing asks for a
/// notification permission until the user turns it on themselves.
struct AppSettings: Codable, Equatable {
    var remindersEnabled = false
    /// Hour of the local evening nudge, when tasks are still open.
    var nudgeHour = 19
    var dueRemindersEnabled = true
    var comeBackRemindersEnabled = true
}

/// Everything that survives a relaunch. Pure value type with no UI and no I/O, so
/// every rule in it can be tested directly.
struct GameState: Codable, Equatable {
    var ledger = Ledger()
    var owned: [OwnedChibi] = [OwnedChibi(speciesID: "slime", level: 1)]
    var activeChibiID = "slime"
    var sceneID = "dorm"
    var ownedScenes: Set<String> = ["dorm"]
    var completedLessons: Set<String> = []

    /// How far into each deck the student has read, by lesson id. Drives Continue on
    /// Learn, the current node on a track map, and where Resume puts you back.
    /// Cleared on finish, so a finished lesson stops asking to be continued.
    var deckProgress: [String: Int] = [:]
    /// Hearted cards, newest first. Stored as pointers into the catalogue, never as
    /// copies of the prose — rewriting a lesson updates what the student kept.
    var savedCards: [SavedCard] = []
    /// The tap-zone coach is shown once, ever.
    var hasSeenTapCoach = false

    var templates: [TaskTemplate] = TaskTemplate.starterSet()
    var canvasItems: [CanvasItem] = []
    var canvasCourses: [CanvasCourse] = []

    /// The day the list on screen was last built for.
    var currentDay: DayKey = .today()
    /// The furthest day this install has ever seen. Rewards key off this, never off
    /// the raw clock, so winding the device date backwards can't re-open a paid day.
    var maxDayReached: DayKey = .today()

    var settings = AppSettings()
    var lastOpenedAt = Date()

    /// Most miles Kin has driven in a single focus shift. A target to beat, never
    /// spendable — the coins for a shift come out of the ledger like any other pay.
    var bestShift = 0

    /// Lifetime totals for the Kin tab's "together since" strip.
    ///
    /// Stored, not derived from `Ledger.entries`, because the ledger folds lines
    /// older than its window into the opening balance — a derived count would go
    /// DOWN over time, and the one promise this strip makes is that it only goes up.
    var lifetime = LifetimeStats()

    /// Today's five shop picks, as `"kin:ember"` / `"scene:meadow"`.
    var shopPicks: [String] = []
    var shopPickDay: DayKey = DayKey(raw: "")
    /// How many times today's row has been rerolled. Seeds the draw, and caps it at
    /// `rerollsPerDay`. Resets with the row at the day boundary.
    var rerollCount = 0
    /// A slot the student is holding. Survives every reroll and the day boundary.
    var lockedPick: String?

    /// Daily Word record, kept here rather than derived from the ledger because the
    /// ledger compacts lines older than 90 days and these should never go down.
    var wordleSolved = 0
    /// Fewest guesses ever. `nil` until the first solve.
    var wordleBest: Int?
    var wordleStreak = 0
    /// The last day a word was solved, so the streak knows whether today continues it.
    var wordleLastDay: DayKey?
    /// Today's board, so leaving mid-puzzle and coming back finds the same guesses —
    /// and a solved board stays solved instead of dealing the same word again.
    var wordleGuesses: [String] = []
    var wordleGuessDay: DayKey?

    /// Number Line record. Rounds can be played any time; coins come once a day.
    var numberLinePlayed = 0
    /// Best round accuracy, 0–100. `nil` until the first round.
    var numberLineBest: Int?

    /// The code the student types into the Chrome extension. Optional on purpose:
    /// nothing is created until they actually open the connect screen, and the app
    /// works fully without one.
    var pairingCode: String?
    var lastCanvasSyncAt: Date?

    // MARK: - Decoding

    private enum CodingKeys: String, CodingKey {
        case ledger, owned, activeChibiID, sceneID, ownedScenes, completedLessons
        case templates, canvasItems, canvasCourses, currentDay, maxDayReached
        case settings, lastOpenedAt, pairingCode, lastCanvasSyncAt, bestShift
        case deckProgress, savedCards, hasSeenTapCoach
        case lifetime, shopPicks, shopPickDay, rerollCount, lockedPick
        case wordleSolved, wordleBest, wordleStreak, wordleLastDay, wordleGuesses, wordleGuessDay
        case numberLinePlayed, numberLineBest
    }

    init() {}

    /// Every field is read with `decodeIfPresent` and falls back to its default.
    ///
    /// The synthesized decoder would throw on the first key a older save does not
    /// have, and a throw here means the whole file is unreadable — which reads to
    /// the student as every coin gone. Adding a field should never be able to do
    /// that, so adding one is free from here on.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let blank = GameState()
        ledger = try c.decodeIfPresent(Ledger.self, forKey: .ledger) ?? blank.ledger
        owned = try c.decodeIfPresent([OwnedChibi].self, forKey: .owned) ?? blank.owned
        activeChibiID = try c.decodeIfPresent(String.self, forKey: .activeChibiID) ?? blank.activeChibiID
        sceneID = try c.decodeIfPresent(String.self, forKey: .sceneID) ?? blank.sceneID
        ownedScenes = try c.decodeIfPresent(Set<String>.self, forKey: .ownedScenes) ?? blank.ownedScenes
        completedLessons = try c.decodeIfPresent(Set<String>.self, forKey: .completedLessons) ?? blank.completedLessons
        templates = try c.decodeIfPresent([TaskTemplate].self, forKey: .templates) ?? blank.templates
        canvasItems = try c.decodeIfPresent([CanvasItem].self, forKey: .canvasItems) ?? blank.canvasItems
        canvasCourses = try c.decodeIfPresent([CanvasCourse].self, forKey: .canvasCourses) ?? blank.canvasCourses
        currentDay = try c.decodeIfPresent(DayKey.self, forKey: .currentDay) ?? blank.currentDay
        maxDayReached = try c.decodeIfPresent(DayKey.self, forKey: .maxDayReached) ?? blank.maxDayReached
        settings = try c.decodeIfPresent(AppSettings.self, forKey: .settings) ?? blank.settings
        lastOpenedAt = try c.decodeIfPresent(Date.self, forKey: .lastOpenedAt) ?? blank.lastOpenedAt
        pairingCode = try c.decodeIfPresent(String.self, forKey: .pairingCode)
        lastCanvasSyncAt = try c.decodeIfPresent(Date.self, forKey: .lastCanvasSyncAt)
        bestShift = try c.decodeIfPresent(Int.self, forKey: .bestShift) ?? blank.bestShift
        deckProgress = try c.decodeIfPresent([String: Int].self, forKey: .deckProgress) ?? blank.deckProgress
        savedCards = try c.decodeIfPresent([SavedCard].self, forKey: .savedCards) ?? blank.savedCards
        hasSeenTapCoach = try c.decodeIfPresent(Bool.self, forKey: .hasSeenTapCoach) ?? blank.hasSeenTapCoach
        lifetime = try c.decodeIfPresent(LifetimeStats.self, forKey: .lifetime) ?? blank.lifetime
        shopPicks = try c.decodeIfPresent([String].self, forKey: .shopPicks) ?? blank.shopPicks
        shopPickDay = try c.decodeIfPresent(DayKey.self, forKey: .shopPickDay) ?? blank.shopPickDay
        rerollCount = try c.decodeIfPresent(Int.self, forKey: .rerollCount) ?? blank.rerollCount
        lockedPick = try c.decodeIfPresent(String.self, forKey: .lockedPick)
        wordleSolved = try c.decodeIfPresent(Int.self, forKey: .wordleSolved) ?? blank.wordleSolved
        wordleBest = try c.decodeIfPresent(Int.self, forKey: .wordleBest)
        wordleStreak = try c.decodeIfPresent(Int.self, forKey: .wordleStreak) ?? blank.wordleStreak
        wordleLastDay = try c.decodeIfPresent(DayKey.self, forKey: .wordleLastDay)
        wordleGuesses = try c.decodeIfPresent([String].self, forKey: .wordleGuesses) ?? blank.wordleGuesses
        wordleGuessDay = try c.decodeIfPresent(DayKey.self, forKey: .wordleGuessDay)
        numberLinePlayed = try c.decodeIfPresent(Int.self, forKey: .numberLinePlayed) ?? blank.numberLinePlayed
        numberLineBest = try c.decodeIfPresent(Int.self, forKey: .numberLineBest)
    }

    // MARK: - Day

    /// The day rewards are keyed to. Equal to today, except while the device clock
    /// is behind a day this install already reached. Travelling backwards across the
    /// date line pins you to the later day for a day; no coins are ever lost.
    var effectiveDay: DayKey { DayKey.latest(currentDay, maxDayReached) }

    /// Rolls the list over to `day` if it isn't already there. Safe to call on every
    /// foreground, midnight tick, and time-zone change.
    mutating func advance(to day: DayKey = .today()) {
        // While the clock is rolled back, a completion is keyed to this later day,
        // not to `currentDay` — the retirement check below has to look at both.
        let paidDay = effectiveDay
        maxDayReached = DayKey.latest(maxDayReached, day)
        guard day != currentDay else { return }
        // A finished one-off is done with; retire it rather than deleting, so the
        // ledger line it produced still has something to point at.
        for i in templates.indices where templates[i].recurrence == .once {
            if templates[i].retiredOn == nil,
               isDone(templateID: templates[i].id, on: currentDay)
                || isDone(templateID: templates[i].id, on: paidDay) {
                templates[i].retiredOn = currentDay
                templates[i].isActive = false
            }
        }
        currentDay = day
    }

    // MARK: - Today's list

    func taskKey(_ id: String, on day: DayKey) -> String { "task:\(id):\(day.raw)" }

    /// Assignments are one-shot, so their pay is keyed without a day. A submitted
    /// item that stays in the extension's feed across midnight, or a hand-ticked
    /// one still open tomorrow, must not pay a second time.
    func canvasKey(_ id: String) -> String { "task:\(id)" }

    /// Ever paid, under the day-less key or under a day-keyed line written before
    /// day-less keys existed.
    private func isCanvasPaid(_ id: String) -> Bool {
        ledger.entries.contains { $0.key == canvasKey(id) || $0.key.hasPrefix("task:\(id):") }
    }

    func isDone(templateID: String, on day: DayKey) -> Bool {
        ledger.isClaimed(taskKey(templateID, on: day))
    }

    /// Today's list, rebuilt from templates plus the Canvas feed. Never stored.
    var tasks: [DailyTask] {
        let day = effectiveDay
        let canvas = canvasItems
            .sorted { ($0.dueAt ?? .distantFuture) < ($1.dueAt ?? .distantFuture) }
            .map { item in
                DailyTask(id: item.id, title: item.title, kind: .canvas,
                          detail: item.courseName, dueAt: item.dueAt,
                          done: item.isSubmitted || isCanvasPaid(item.id),
                          isLocked: item.isSubmitted)
            }
        let mine = templates
            .filter { $0.isActive && $0.retiredOn == nil }
            .map { t in
                DailyTask(id: t.id, title: t.title, kind: t.kind,
                          done: ledger.isClaimed(taskKey(t.id, on: day)))
            }
        return canvas + mine
    }

    var allDone: Bool { !tasks.isEmpty && tasks.allSatisfy(\.done) }

    var week: WeekStats { ledger.stats() }

    var activeChibi: OwnedChibi {
        owned.first { $0.speciesID == activeChibiID } ?? owned[0]
    }

    // MARK: - Tasks

    /// Pays for a finished task, once. Returns what was paid, or 0 if it was already
    /// checked off — today for a daily task, ever for a Canvas assignment.
    @discardableResult
    mutating func complete(taskID: String, reward: Int, now: Date = Date()) -> Int {
        let day = effectiveDay
        if canvasItems.contains(where: { $0.id == taskID }) {
            guard !isCanvasPaid(taskID) else { return 0 }
            let posted = ledger.post(CoinEntry(key: canvasKey(taskID), amount: reward,
                                               reason: .task, day: day, at: now))
            if posted { lifetime.tasksFinished += 1; lifetime.canvasFinished += 1 }
            return posted ? reward : 0
        }
        let posted = ledger.post(CoinEntry(key: taskKey(taskID, on: day), amount: reward,
                                           reason: .task, day: day, at: now))
        if posted { lifetime.tasksFinished += 1 }
        return posted ? reward : 0
    }

    mutating func addTask(title: String, kind: TaskKind, recurrence: Recurrence, id: String = UUID().uuidString) {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        templates.append(TaskTemplate(id: "u-\(id)", title: clean, kind: kind, recurrence: recurrence))
    }

    mutating func setTemplate(_ id: String, active: Bool) {
        guard let i = templates.firstIndex(where: { $0.id == id }) else { return }
        templates[i].isActive = active
    }

    /// Deletes a task the user made. Presets can only be switched off, never removed.
    mutating func deleteTask(_ id: String) {
        guard let i = templates.firstIndex(where: { $0.id == id }), !templates[i].isPreset else { return }
        templates.remove(at: i)
    }

    // MARK: - Other earnings

    @discardableResult
    mutating func recordFocus(minutes: Int, sessionID: String = UUID().uuidString, now: Date = Date()) -> Int {
        let day = effectiveDay
        let ok = ledger.post(CoinEntry(key: "focus:\(sessionID)", amount: minutes,
                                       reason: .focus, units: minutes, day: day, at: now))
        if ok { lifetime.focusMinutes += minutes }
        return ok ? minutes : 0
    }

    /// Keeps the best single shift. Miles are cosmetic, so this is a plain max with
    /// no ledger entry behind it.
    mutating func recordShift(miles: Int) {
        bestShift = max(bestShift, miles)
    }

    /// Pays for the daily word once per day. Replaces the old `@AppStorage` day
    /// stamp, which a clock change could reset. `day` is the day the puzzle was
    /// dealt — a solve finished just past midnight still settles the word it was.
    @discardableResult
    mutating func recordWordleWin(reward: Int = 30, guesses: Int = 6, day: DayKey? = nil,
                                  now: Date = Date(), calendar: Calendar = .current) -> Int {
        let day = day ?? effectiveDay
        let ok = ledger.post(CoinEntry(key: "wordle:\(day.raw)", amount: reward,
                                       reason: .wordle, day: day, at: now))
        guard ok else { return 0 }
        wordleSolved += 1
        wordleBest = min(wordleBest ?? guesses, guesses)
        // Yesterday continues the streak; anything older starts it over at 1.
        if let last = wordleLastDay, last == Self.dayBefore(day, calendar: calendar) {
            wordleStreak += 1
        } else if wordleLastDay != day {
            wordleStreak = 1
        }
        wordleLastDay = day
        return reward
    }

    /// The streak as it stands right now: a solve yesterday or today keeps it; a
    /// gap of a day or more means it has already lapsed, whatever the counter says.
    func wordleStreak(asOf day: DayKey? = nil, calendar: Calendar = .current) -> Int {
        let day = day ?? effectiveDay
        guard let last = wordleLastDay else { return 0 }
        return (last == day || last == Self.dayBefore(day, calendar: calendar)) ? wordleStreak : 0
    }

    static func dayBefore(_ day: DayKey, calendar: Calendar = .current) -> DayKey? {
        let parts = day.raw.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3,
              let date = calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2])),
              let before = calendar.date(byAdding: .day, value: -1, to: date) else { return nil }
        return DayKey(before, calendar: calendar)
    }

    var wordleClaimedToday: Bool { ledger.isClaimed("wordle:\(effectiveDay.raw)") }

    /// A finished Number Line round. Paid once a day, whatever the accuracy — the
    /// score is a number to beat, never the thing that decides the coins.
    @discardableResult
    mutating func recordNumberLineRound(accuracy: Int, reward: Int = 25, day: DayKey? = nil,
                                        now: Date = Date()) -> Int {
        let day = day ?? effectiveDay
        numberLinePlayed += 1
        numberLineBest = max(numberLineBest ?? 0, accuracy)
        let ok = ledger.post(CoinEntry(key: "numberline:\(day.raw)", amount: reward,
                                       reason: .numberLine, day: day, at: now))
        return ok ? reward : 0
    }

    var numberLineClaimedToday: Bool { ledger.isClaimed("numberline:\(effectiveDay.raw)") }

    /// Pays for a finished deck, once ever. A re-read is free to do and pays nothing,
    /// which is the same rule every other earning path in the app follows.
    @discardableResult
    mutating func completeLesson(id: String, reward: Int, now: Date = Date()) -> Int {
        let day = effectiveDay
        let ok = ledger.post(CoinEntry(key: "lesson:\(id)", amount: reward,
                                       reason: .lesson, day: day, at: now))
        completedLessons.insert(id)
        if ok { lifetime.lessonsRead += 1 }
        // Finished decks don't ask to be continued.
        deckProgress[id] = nil
        return ok ? reward : 0
    }

    // MARK: - Learn

    /// Remembers how far in you got. Only ever moves forward within a session's
    /// reading, so paging back doesn't make Continue offer you an earlier card.
    mutating func setDeckProgress(_ lessonID: String, card index: Int) {
        guard index > 0 else { deckProgress[lessonID] = nil; return }
        deckProgress[lessonID] = max(deckProgress[lessonID] ?? 0, index)
    }

    func deckProgress(_ lessonID: String) -> Int { deckProgress[lessonID] ?? 0 }

    func isSaved(lessonID: String, index: Int) -> Bool {
        savedCards.contains { $0.lessonID == lessonID && $0.index == index }
    }

    /// Hearts or un-hearts a card. Returns the state it ended in, so the view can
    /// bounce the heart only when something was actually saved.
    @discardableResult
    mutating func toggleSaved(lessonID: String, index: Int, now: Date = Date()) -> Bool {
        if let i = savedCards.firstIndex(where: { $0.lessonID == lessonID && $0.index == index }) {
            savedCards.remove(at: i)
            return false
        }
        savedCards.insert(SavedCard(lessonID: lessonID, index: index, savedAt: now), at: 0)
        return true
    }

    /// The only counter Learn shows. Counts up within a month and never resets to a
    /// target you have to hit — there is no streak to break here.
    func lessonsThisMonth(now: Date = Date(), calendar: Calendar = .current) -> Int {
        guard let month = calendar.dateInterval(of: .month, for: now) else { return 0 }
        return ledger.entries.filter { $0.reason == .lesson && month.contains($0.at) }.count
    }

    // MARK: - Spending

    @discardableResult
    mutating func upgradeActiveChibi(now: Date = Date()) -> Bool {
        guard let cost = activeChibi.nextUpgradeCost,
              let i = owned.firstIndex(where: { $0.speciesID == activeChibiID }) else { return false }
        let level = owned[i].level
        guard ledger.post(CoinEntry(key: "upgrade:\(activeChibiID):\(level)", amount: -cost,
                                    reason: .upgrade, day: effectiveDay, at: now)) else { return false }
        owned[i].level += 1
        return true
    }

    @discardableResult
    mutating func buy(_ species: ChibiSpecies, now: Date = Date()) -> Bool {
        guard !owned.contains(where: { $0.speciesID == species.id }) else { return false }
        guard ledger.post(CoinEntry(key: "species:\(species.id)", amount: -species.price,
                                    reason: .species, day: effectiveDay, at: now)) else { return false }
        owned.append(OwnedChibi(speciesID: species.id, level: 1))
        activeChibiID = species.id
        return true
    }

    @discardableResult
    mutating func buyScene(_ scene: Scene0, now: Date = Date()) -> Bool {
        guard !ownedScenes.contains(scene.id) else { return false }
        guard ledger.post(CoinEntry(key: "scene:\(scene.id)", amount: -scene.price,
                                    reason: .scene, day: effectiveDay, at: now)) else { return false }
        ownedScenes.insert(scene.id)
        sceneID = scene.id
        return true
    }

    mutating func equipScene(_ id: String) {
        guard ownedScenes.contains(id) else { return }
        sceneID = id
    }

    mutating func setActive(_ speciesID: String) {
        guard owned.contains(where: { $0.speciesID == speciesID }) else { return }
        activeChibiID = speciesID
    }

    // MARK: - Canvas

    /// Takes a push from the extension. Work Canvas confirms you handed in pays
    /// on the spot: submitting *is* completing, and the ledger key means a student
    /// who also ticked it by hand is never paid twice.
    mutating func applyCanvas(_ snapshot: CanvasSnapshot, now: Date = Date()) {
        canvasItems = snapshot.tasks
        canvasCourses = snapshot.courses
        lastCanvasSyncAt = now
        for item in snapshot.tasks where item.isSubmitted {
            complete(taskID: item.id, reward: TaskKind.canvas.reward, now: now)
        }
    }

    /// Un-checking is for things you told the app about. Canvas already knows.
    /// Undoing a check-off takes its line out of the lifetime totals as well. That is
    /// the one way a "together since" number can fall, and it is the honest one: the
    /// student is saying the thing did not happen.
    mutating func uncomplete(taskID: String) {
        if let item = canvasItems.first(where: { $0.id == taskID }) {
            guard !item.isSubmitted else { return }
            if ledger.revoke(canvasKey(taskID)) {
                lifetime.tasksFinished = max(0, lifetime.tasksFinished - 1)
                lifetime.canvasFinished = max(0, lifetime.canvasFinished - 1)
            }
        } else if ledger.revoke(taskKey(taskID, on: effectiveDay)) {
            lifetime.tasksFinished = max(0, lifetime.tasksFinished - 1)
        }
    }

    /// Makes a code the first time it is needed, then keeps it. Regenerating would
    /// silently orphan a laptop that is already pushing to the old one.
    @discardableResult
    mutating func ensurePairingCode() -> String {
        if let existing = pairingCode { return existing }
        let code = PairingCode.generate()
        pairingCode = code
        return code
    }

    /// Forgets the pairing. The row in the bridge is left to expire on its own.
    mutating func unpair() {
        pairingCode = nil
        canvasItems = []
        canvasCourses = []
        lastCanvasSyncAt = nil
    }
}

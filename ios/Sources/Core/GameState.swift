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

/// A friend, as the Friends tab draws them. Nothing writes one yet — there is no
/// friend bridge — so on a real device the list stays empty.
struct Friend: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let speciesID: String
    /// `OwnedChibi.level`, 1…3, drawn as `StarPips`.
    let level: Int
    let weekCoins: Int
    let lastActivity: String
}

/// Everything that survives a relaunch. Pure value type with no UI and no I/O, so
/// every rule in it can be tested directly.
struct GameState: Codable, Equatable {
    var ledger = Ledger()
    var owned: [OwnedChibi] = [OwnedChibi(speciesID: "slime", level: 1)]
    var activeChibiID = "slime"
    var sceneID = "lagoon"
    var ownedScenes: Set<String> = ["lagoon"]
    var completedLessons: Set<String> = []

    /// How far into each deck the student has read, by lesson id. Drives Continue on
    /// Learn, the current node on a track map, and where Resume puts you back.
    /// Cleared on finish, so a finished lesson stops asking to be continued.
    var deckProgress: [String: Int] = [:]
    /// Hearted cards, newest first. Stored as pointers into the catalogue, never as
    /// copies of the prose — rewriting a lesson updates what the student kept.
    var savedCards: [SavedCard] = []
    /// Cards the student flagged as broken, newest first. Local only — there is
    /// nowhere to send a report yet, so this is a note to self.
    var cardReports: [CardReport] = []
    /// The tap-zone coach is shown once, ever.
    var hasSeenTapCoach = false
    /// The two-screen first run (name the kin, pick three) has been completed.
    /// A save written before the first run existed decodes as `true`: whoever
    /// wrote it has already been using the app, and must not be sent back to
    /// the start.
    var firstRunDone = false
    /// The Day 1 offer cards on Home (notifications, then Canvas) have been
    /// answered or dismissed. Same rule for older saves.
    var firstRunOffersDone = false

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

    /// The weekly league: which water the student is in, and the pennants they have
    /// kept. Sits beside `lifetime` because it makes the same promise — a pennant,
    /// once earned, is never taken back.
    var league = LeagueState()

    /// Lifetime totals for the Kin tab's "together since" strip.
    ///
    /// Stored, not derived from `Ledger.entries`, because the ledger folds lines
    /// older than its window into the opening balance — a derived count would go
    /// DOWN over time, and the one promise this strip makes is that it only goes up.
    var lifetime = LifetimeStats()

    /// Today's shop picks, up to five, as `"kin:ember"` / `"scene:meadow"`.
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
    /// This phone's own bridge token, handed out once when the code was claimed.
    /// The code is only good for the few minutes it takes a laptop to pair; every
    /// read and write after that needs this.
    var pairingToken: String?
    /// Looks bought in the extension's shop. The catalog lives on the laptop; the
    /// phone only records what was paid for, because the ledger is the truth.
    var ownedLooks: Set<String> = ["classic"]
    /// The newest laptop request this phone has paid. Published back so the
    /// extension knows what it can stop re-sending.
    var requestsAppliedAt: Date?
    var lastCanvasSyncAt: Date?

    /// The code a student reads out to a friend. Separate from `pairingCode` on
    /// purpose: that one ties this phone to one laptop and is revoked by
    /// `unpair()`; this one is the person, and disconnecting Canvas must not
    /// change it.
    var friendCode: String?

    /// The friends whose kins show on the tab. Empty until there is a bridge to
    /// fill it: a student must never see a person who does not exist.
    var friends: [Friend] = []

    /// Codes typed into "Add a friend" that nobody has answered. Local only —
    /// there is nowhere to send them yet, so this is a note to self.
    var pendingFriendCodes: [String] = []

    // MARK: - Decoding

    private enum CodingKeys: String, CodingKey {
        case ledger, owned, activeChibiID, sceneID, ownedScenes, completedLessons
        case templates, canvasItems, canvasCourses, currentDay, maxDayReached
        case settings, lastOpenedAt, pairingCode, lastCanvasSyncAt, bestShift, friendCode
        case pairingToken, ownedLooks, requestsAppliedAt
        case friends, pendingFriendCodes
        case deckProgress, savedCards, cardReports, hasSeenTapCoach, firstRunDone, firstRunOffersDone
        case lifetime, shopPicks, shopPickDay, rerollCount, lockedPick
        case wordleSolved, wordleBest, wordleStreak, wordleLastDay, wordleGuesses, wordleGuessDay
        case numberLinePlayed, numberLineBest
        case league
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
        // Land scenes became tanks. Carry over anything already paid for.
        sceneID = Scene0.find(sceneID).id
        ownedScenes = Set(ownedScenes.map { Scene0.find($0).id })
        ownedScenes.insert(Scene0.all[0].id)
        completedLessons = try c.decodeIfPresent(Set<String>.self, forKey: .completedLessons) ?? blank.completedLessons
        templates = try c.decodeIfPresent([TaskTemplate].self, forKey: .templates) ?? blank.templates
        canvasItems = try c.decodeIfPresent([CanvasItem].self, forKey: .canvasItems) ?? blank.canvasItems
        canvasCourses = try c.decodeIfPresent([CanvasCourse].self, forKey: .canvasCourses) ?? blank.canvasCourses
        currentDay = try c.decodeIfPresent(DayKey.self, forKey: .currentDay) ?? blank.currentDay
        maxDayReached = try c.decodeIfPresent(DayKey.self, forKey: .maxDayReached) ?? blank.maxDayReached
        settings = try c.decodeIfPresent(AppSettings.self, forKey: .settings) ?? blank.settings
        lastOpenedAt = try c.decodeIfPresent(Date.self, forKey: .lastOpenedAt) ?? blank.lastOpenedAt
        pairingCode = try c.decodeIfPresent(String.self, forKey: .pairingCode)
        pairingToken = try c.decodeIfPresent(String.self, forKey: .pairingToken)
        ownedLooks = try c.decodeIfPresent(Set<String>.self, forKey: .ownedLooks) ?? blank.ownedLooks
        requestsAppliedAt = try c.decodeIfPresent(Date.self, forKey: .requestsAppliedAt)
        lastCanvasSyncAt = try c.decodeIfPresent(Date.self, forKey: .lastCanvasSyncAt)
        friendCode = try c.decodeIfPresent(String.self, forKey: .friendCode)
        friends = try c.decodeIfPresent([Friend].self, forKey: .friends) ?? blank.friends
        pendingFriendCodes = try c.decodeIfPresent([String].self, forKey: .pendingFriendCodes) ?? blank.pendingFriendCodes
        bestShift = try c.decodeIfPresent(Int.self, forKey: .bestShift) ?? blank.bestShift
        deckProgress = try c.decodeIfPresent([String: Int].self, forKey: .deckProgress) ?? blank.deckProgress
        savedCards = try c.decodeIfPresent([SavedCard].self, forKey: .savedCards) ?? blank.savedCards
        cardReports = try c.decodeIfPresent([CardReport].self, forKey: .cardReports) ?? blank.cardReports
        hasSeenTapCoach = try c.decodeIfPresent(Bool.self, forKey: .hasSeenTapCoach) ?? blank.hasSeenTapCoach
        firstRunDone = try c.decodeIfPresent(Bool.self, forKey: .firstRunDone) ?? true
        firstRunOffersDone = try c.decodeIfPresent(Bool.self, forKey: .firstRunOffersDone) ?? true
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
        // A save written before the league existed opens in Tidepool with no
        // pennants. There is no history to reconstruct and inventing one would be a
        // keepsake nobody earned.
        league = try c.decodeIfPresent(LeagueState.self, forKey: .league) ?? blank.league
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
        settleLeagueWeekIfNeeded()
    }

    // MARK: - The league week

    /// Coins earned so far in the week the league is counting. Earned, never held —
    /// buying a kin does not cost you a place.
    var leaguePoints: Int { ledger.coinsEarned(inWeek: league.weekStart) }

    /// The bar left to clear this week, or `nil` at the top of the ladder.
    var leaguePointsToNextTier: Int? {
        LeagueRules.bar(for: league.tier).map { max(0, $0 - leaguePoints) }
    }

    /// Closes the old week if the calendar has turned over.
    ///
    /// Hung off `advance(to:)` rather than a timer of its own, so it fires on exactly
    /// the four moments the day already rolls: launch, foreground, midnight, and a
    /// time-zone change. A student away for three weeks settles the week they were
    /// last active in and lands in the current one; the empty weeks between earned
    /// nothing, and nothing is what they change.
    @discardableResult
    mutating func settleLeagueWeekIfNeeded() -> LeagueRules.Outcome? {
        let week = WeekKey(effectiveDay)
        guard !week.raw.isEmpty, week > league.weekStart else { return nil }
        return league.settle(into: week, coinsEarned: ledger.coinsEarned(inWeek: league.weekStart))
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
        // Canvas can hand back the same quiz several times under different ids
        // (one per section copy). One row per title, course and due date; a
        // weekly quiz with fresh dates stays a separate row each week.
        var seen: Set<String> = []
        let canvas = canvasItems
            .sorted { ($0.dueAt ?? .distantFuture) < ($1.dueAt ?? .distantFuture) }
            .filter { item in
                let key = "\(item.title)|\(item.courseName)|\(item.dueAt?.timeIntervalSince1970 ?? -1)"
                return seen.insert(key).inserted
            }
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

    /// Pays what the laptop asked for: focus sessions that finished there, and
    /// looks bought in its shop.
    ///
    /// Every request carries its own ledger key, so the extension can keep
    /// re-sending one until this phone confirms it without ever paying twice. A
    /// purchase the balance cannot cover is simply refused — `Ledger.post` will
    /// not overdraw — and the look stays unowned, which is the honest answer.
    ///
    /// Returns the newest request it actually looked at, which is what the
    /// extension needs back to stop re-sending.
    @discardableResult
    mutating func applyBridgeRequests(_ requests: [BridgeRequest], now: Date = Date()) -> Date? {
        let day = effectiveDay
        var newest = requestsAppliedAt
        for request in requests.sorted(by: { $0.at < $1.at }) {
            // Already settled in an earlier sync.
            if let seen = requestsAppliedAt, request.at <= seen { continue }
            switch request.kind {
            case "focus":
                let minutes = request.minutes ?? 0
                guard (1...240).contains(minutes) else { break }
                if ledger.post(CoinEntry(key: request.ledgerKey, amount: minutes,
                                         reason: .focus, units: minutes, day: day, at: now)) {
                    lifetime.focusMinutes += minutes
                }
            case "look":
                guard let lookId = request.lookId, !lookId.isEmpty,
                      let price = request.price, (0...5000).contains(price) else { break }
                if ownedLooks.contains(lookId) { break }
                if price == 0 {
                    ownedLooks.insert(lookId)
                } else if ledger.post(CoinEntry(key: request.ledgerKey, amount: -price,
                                                reason: .upgrade, day: day, at: now)) {
                    ownedLooks.insert(lookId)
                }
            default:
                break
            }
            newest = max(newest ?? request.at, request.at)
        }
        requestsAppliedAt = newest
        return newest
    }

    /// What the extension is told after a sync.
    var bridgeState: BridgeState {
        BridgeState(coins: ledger.balance, owned: Array(ownedLooks).sorted(),
                    requestsAppliedAt: requestsAppliedAt, league: bridgeLeague)
    }

    /// The league flattened for the laptop. The board rides along only when the pod
    /// is this week's, so a stale week's strangers never show up on a Canvas page.
    var bridgeLeague: BridgeLeague {
        let pod = league.lastPod.flatMap { $0.week == league.weekStart ? $0 : nil }
        return BridgeLeague(
            tier: league.tier.rawValue,
            points: leaguePoints,
            bar: LeagueRules.bar(for: league.tier),
            week: league.weekStart.raw,
            pennants: league.pennants.map(\.rawValue).sorted(),
            board: pod.map { $0.members.map {
                BridgeLeagueMember(you: $0.isYou, adjective: $0.adjective, noun: $0.noun,
                                   points: $0.points, level: $0.level,
                                   species: $0.speciesID, look: $0.lookID)
            } })
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

    /// Files a report against a card. Duplicates are kept — flagging the same card
    /// twice is the student saying it again, not a mistake to swallow.
    mutating func reportCard(lessonID: String, index: Int, reason: CardReportReason,
                             now: Date = Date()) {
        cardReports.insert(CardReport(lessonID: lessonID, cardIndex: index,
                                      reason: reason, date: now), at: 0)
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
        // Today's price, not the Collection price. A scene drawn into the picks row
        // is shown at 20% off, and charging the full price after showing the discount
        // is the one thing the shop's honesty panel promises never happens.
        guard ledger.post(CoinEntry(key: "scene:\(scene.id)", amount: -currentPrice("scene:\(scene.id)"),
                                    reason: .scene, day: effectiveDay, at: now)) else { return false }
        ownedScenes.insert(scene.id)
        sceneID = scene.id
        // Same as adopting a kin: release the slot it was held in and backfill the row,
        // so a bought scene does not sit in today's picks pretending to still be for sale.
        if lockedPick == "scene:\(scene.id)" { lockedPick = nil }
        refreshPicksIfNeeded(now: now)
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

    /// Made the first time the Friends tab is opened, then kept. A friend who
    /// wrote the old one down must still be able to use it.
    @discardableResult
    mutating func ensureFriendCode() -> String {
        if let existing = friendCode { return existing }
        let code = PairingCode.generate()
        friendCode = code
        return code
    }

    /// Remembers a code the student typed. Nothing is sent; the row is only so the
    /// tab can say who they are still waiting on. Typing the same code twice is a
    /// no-op rather than a second row.
    mutating func addPendingFriendCode(_ code: String) {
        guard !pendingFriendCodes.contains(code) else { return }
        pendingFriendCodes.append(code)
    }

    mutating func removePendingFriendCode(_ code: String) {
        pendingFriendCodes.removeAll { $0 == code }
    }

    /// Forgets the pairing. The caller deletes the bridge row first — leaving it
    /// to expire meant a student who disconnected because something felt wrong
    /// left their coursework readable for another month.
    mutating func unpair() {
        pairingCode = nil
        pairingToken = nil
        requestsAppliedAt = nil
        canvasItems = []
        canvasCourses = []
        lastCanvasSyncAt = nil
    }
}

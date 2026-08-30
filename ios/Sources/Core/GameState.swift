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
            return posted ? reward : 0
        }
        let posted = ledger.post(CoinEntry(key: taskKey(taskID, on: day), amount: reward,
                                           reason: .task, day: day, at: now))
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
    mutating func recordWordleWin(reward: Int = 30, day: DayKey? = nil, now: Date = Date()) -> Int {
        let day = day ?? effectiveDay
        let ok = ledger.post(CoinEntry(key: "wordle:\(day.raw)", amount: reward,
                                       reason: .wordle, day: day, at: now))
        return ok ? reward : 0
    }

    var wordleClaimedToday: Bool { ledger.isClaimed("wordle:\(effectiveDay.raw)") }

    @discardableResult
    mutating func completeLesson(id: String, reward: Int, now: Date = Date()) -> Int {
        let day = effectiveDay
        let ok = ledger.post(CoinEntry(key: "lesson:\(id)", amount: reward,
                                       reason: .lesson, day: day, at: now))
        if ok { completedLessons.insert(id) }
        return ok ? reward : 0
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
    mutating func uncomplete(taskID: String) {
        if let item = canvasItems.first(where: { $0.id == taskID }) {
            guard !item.isSubmitted else { return }
            ledger.revoke(canvasKey(taskID))
        } else {
            ledger.revoke(taskKey(taskID, on: effectiveDay))
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

import Foundation

/// User-controlled switches. Reminders default to off — nothing asks for a
/// notification permission until the user turns it on themselves.
struct Settings: Codable, Equatable {
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

    /// The day the list on screen was last built for.
    var currentDay: DayKey = .today()
    /// The furthest day this install has ever seen. Rewards key off this, never off
    /// the raw clock, so winding the device date backwards can't re-open a paid day.
    var maxDayReached: DayKey = .today()

    var settings = Settings()
    var lastOpenedAt = Date()

    // MARK: - Day

    /// The day rewards are keyed to. Equal to today, except while the device clock
    /// is behind a day this install already reached. Travelling backwards across the
    /// date line pins you to the later day for a day; no coins are ever lost.
    var effectiveDay: DayKey { DayKey.latest(currentDay, maxDayReached) }

    /// Rolls the list over to `day` if it isn't already there. Safe to call on every
    /// foreground, midnight tick, and time-zone change.
    mutating func advance(to day: DayKey = .today()) {
        maxDayReached = DayKey.latest(maxDayReached, day)
        guard day != currentDay else { return }
        // A finished one-off is done with; retire it rather than deleting, so the
        // ledger line it produced still has something to point at.
        for i in templates.indices where templates[i].recurrence == .once {
            if templates[i].retiredOn == nil, isDone(templateID: templates[i].id, on: currentDay) {
                templates[i].retiredOn = currentDay
                templates[i].isActive = false
            }
        }
        currentDay = day
    }

    // MARK: - Today's list

    private func taskKey(_ id: String, on day: DayKey) -> String { "task:\(id):\(day.raw)" }

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
                          done: ledger.isClaimed(taskKey(item.id, on: day)))
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
    /// checked off today.
    @discardableResult
    mutating func complete(taskID: String, reward: Int, now: Date = Date()) -> Int {
        let day = effectiveDay
        let posted = ledger.post(CoinEntry(key: taskKey(taskID, on: day), amount: reward,
                                           reason: .task, day: day, at: now))
        return posted ? reward : 0
    }

    /// Un-checks a task and takes the coins back. Never a penalty — the balance just
    /// returns to what it was before the tap.
    mutating func uncomplete(taskID: String) {
        ledger.revoke(taskKey(taskID, on: effectiveDay))
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

    /// Pays for the daily word once per day. Replaces the old `@AppStorage` day
    /// stamp, which a clock change could reset.
    @discardableResult
    mutating func recordWordleWin(reward: Int = 30, now: Date = Date()) -> Int {
        let day = effectiveDay
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

    mutating func applyCanvas(_ items: [CanvasItem]) {
        canvasItems = items
    }
}

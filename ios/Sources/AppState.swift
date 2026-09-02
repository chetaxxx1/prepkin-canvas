import Foundation
import SwiftUI

/// The bridge between SwiftUI and `GameState`.
///
/// All the rules live in `GameState`, which is a plain value type with no I/O — this
/// class only publishes it, saves it, and plays the mascot's reaction. Anything you
/// would want to write a test for belongs on the other side of this line.
@MainActor
final class AppState: ObservableObject {
    @Published private(set) var game: GameState {
        didSet { store.save(game) }
    }

    @Published var animation: ChibiAnimation = .wave
    /// Raised by pushed sub-screens (Daily Word, a lesson, the grade calculator)
    /// and by a running focus session, so the floating bar gets out of the way.
    @Published var hideTabBar = false

    /// What the last sync did, for the connect screen. Not persisted — it is only
    /// ever about this run.
    @Published private(set) var canvasStatus: String?

    /// One line of dark glass saying what just happened. A new value replaces the
    /// current one in place; there is never a second toast on screen.
    @Published var toast: String?
    /// The four steps of adopting a kin, as one path. `nil` when nothing is in flight.
    @Published var adoption: Adoption?
    /// Set while the picks row is changing over, so the row can stagger.
    @Published var rerolling = false
    /// "Meet <kin>" was tapped on the adoption card. Root switches to the Kin tab,
    /// and whatever shop or sheet is open gets out of the way. Cleared by Root.
    @Published var meetKinRequest: String?

    private var toastTask: Task<Void, Never>?

    private let store: Store
    private let makeClient: (GameState) -> CanvasSyncClient?

    /// Real bridge once there is a pairing code. Sample data only in a checkout
    /// with no bridge configured at all, so a demo is never an empty page — but a
    /// real install that unpairs gets nothing, not fake homework that pays coins.
    nonisolated static func defaultClient(for state: GameState, config: BridgeConfig = .shared) -> CanvasSyncClient? {
        guard config.isConfigured else { return MockCanvasClient() }
        guard let code = state.pairingCode else { return nil }
        return SupabaseCanvasClient(code: code)
    }

    init(store: Store = .shared,
         makeClient: @escaping (GameState) -> CanvasSyncClient? = { AppState.defaultClient(for: $0) }) {
        self.store = store
        self.makeClient = makeClient
        var loaded = store.load()
        loaded.advance()
        loaded.lastOpenedAt = Date()
        game = loaded
        game.refreshPicksIfNeeded()
        store.save(game)
    }

    // MARK: - Read-through for the views

    var coins: Int { game.ledger.balance }
    var owned: [OwnedChibi] { game.owned }
    var activeChibiID: String { game.activeChibiID }
    var activeChibi: OwnedChibi { game.activeChibi }
    var tasks: [DailyTask] { game.tasks }
    var allDone: Bool { game.allDone }
    var week: WeekStats { game.week }
    var completedLessons: Set<String> { game.completedLessons }
    var savedCards: [SavedCard] { game.savedCards }
    var hasSeenTapCoach: Bool { game.hasSeenTapCoach }
    var lessonsThisMonth: Int { game.lessonsThisMonth() }
    var sceneID: String { game.sceneID }
    var ownedScenes: Set<String> { game.ownedScenes }
    var templates: [TaskTemplate] { game.templates }
    var settings: AppSettings { game.settings }
    var wordleClaimedToday: Bool { game.wordleClaimedToday }
    var coinHistory: [CoinEntry] { game.ledger.entries.reversed() }
    var courses: [CanvasCourse] { game.canvasCourses }
    var bestShift: Int { game.bestShift }
    var lifetime: LifetimeStats { game.lifetime }
    var picks: [ShopPick] { game.picks }
    var lockedPick: String? { game.lockedPick }
    func currentPrice(_ id: String) -> Int { game.currentPrice(id) }
    func workToAfford(_ id: String) -> String? { game.workToAfford(id) }
    func ownedKin(_ speciesID: String) -> OwnedChibi? {
        game.owned.first { $0.speciesID == speciesID }
    }
    func daysTogether(_ kin: OwnedChibi) -> Int { game.daysTogether(kin) }
    var canvasFinished: Int? { game.canvasFinishedOrNil }

    // MARK: - Day

    /// Rebuilds today's list. Called on launch, on foreground, at midnight, and on a
    /// time-zone change — the four moments the old `isDateInToday` check missed.
    func refreshDay() {
        game.advance()
        game.lastOpenedAt = Date()
        rescheduleReminders()
    }

    func flush() { store.flush() }

    // MARK: - Canvas

    func syncCanvas() async {
        guard let client = makeClient(game) else {
            canvasStatus = "Pair with the Chrome extension to see Canvas here."
            return
        }
        // If the user disconnects (or re-pairs) while this fetch is in the air, the
        // response belongs to a pairing that no longer exists. Drop it.
        let codeAtStart = game.pairingCode
        do {
            let snapshot = try await client.fetchTodo()
            guard game.pairingCode == codeAtStart else { return }
            let before = Set(game.tasks.map(\.id))
            game.applyCanvas(snapshot)
            canvasStatus = nil
            rescheduleReminders()
            // New homework just dropped in — a startled "whoa!", but never
            // interrupting an animation that is already playing.
            if animation == .idle, game.tasks.contains(where: { !before.contains($0.id) }) {
                play(.startle)
            }
        } catch BridgeError.notPairedYet {
            guard game.pairingCode == codeAtStart else { return }
            canvasStatus = "Waiting for your laptop to send its first list."
        } catch {
            guard game.pairingCode == codeAtStart else { return }
            // Keep whatever is already on the list. A dropped connection is not a
            // reason to empty somebody's day.
            canvasStatus = "Could not reach the bridge. Showing the last list."
        }
    }

    // MARK: - Pairing

    var pairingCode: String? { game.pairingCode }
    var lastCanvasSyncAt: Date? { game.lastCanvasSyncAt }
    var isBridgeConfigured: Bool { BridgeConfig.shared.isConfigured }

    @discardableResult
    func ensurePairingCode() -> String { game.ensurePairingCode() }

    func unpair() {
        game.unpair()
        canvasStatus = nil
    }

    // MARK: - Tasks

    func complete(_ task: DailyTask) {
        let paid = game.complete(taskID: task.id, reward: task.reward)
        guard paid > 0 else { return }
        play(game.allDone ? .celebrate : .bounce)
        rescheduleReminders()
    }

    /// Undo a check-off. Takes the coins back, plays nothing. Never a penalty.
    func uncomplete(_ task: DailyTask) {
        game.uncomplete(taskID: task.id)
        rescheduleReminders()
    }

    func addTask(title: String, kind: TaskKind, recurrence: Recurrence) {
        game.addTask(title: title, kind: kind, recurrence: recurrence)
        rescheduleReminders()
    }

    func setTemplate(_ id: String, active: Bool) {
        game.setTemplate(id, active: active)
        rescheduleReminders()
    }

    func deleteTask(_ id: String) {
        game.deleteTask(id)
        rescheduleReminders()
    }

    // MARK: - Other earnings

    func recordFocus(minutes: Int) {
        let paid = game.recordFocus(minutes: minutes)
        if paid > 0 { play(minutes >= 25 ? .celebrate : .bounce) }
    }

    /// Miles from a finished shift. Called for a clock-out too — the miles were
    /// still driven.
    func recordShift(miles: Int) {
        game.recordShift(miles: miles)
    }

    /// `dealtDay` is the day the puzzle was dealt, so a solve finished just past
    /// midnight settles the word it actually was.
    func recordWordleWin(guesses: Int, dealtDay: DayKey) {
        if game.recordWordleWin(guesses: guesses, day: dealtDay) > 0 { play(.celebrate) }
    }

    /// The guesses made on the word dealt on `day`. Empty for any other day.
    func wordleGuesses(for day: DayKey) -> [String] {
        game.wordleGuessDay == day ? game.wordleGuesses : []
    }

    func saveWordleGuesses(_ guesses: [String], for day: DayKey) {
        game.wordleGuesses = guesses
        game.wordleGuessDay = day
    }

    var wordleStreak: Int { game.wordleStreak() }

    var numberLineClaimedToday: Bool { game.numberLineClaimedToday }

    /// Returns what was paid: 25 the first round of the day, 0 after.
    @discardableResult
    func finishNumberLineRound(accuracy: Int) -> Int {
        let paid = game.recordNumberLineRound(accuracy: accuracy)
        if paid > 0 { play(.celebrate) }
        return paid
    }

    /// Pays for a finished deck and returns what it paid, so the finish card can show
    /// the coins flying only when coins actually moved. A re-read pays 0 and is silent.
    @discardableResult
    func completeLesson(id: String, reward: Int) -> Int {
        let paid = game.completeLesson(id: id, reward: reward)
        if paid > 0 { play(.celebrate) }
        return paid
    }

    // MARK: - Learn

    func deckProgress(_ lessonID: String) -> Int { game.deckProgress(lessonID) }

    func setDeckProgress(_ lessonID: String, card index: Int) {
        game.setDeckProgress(lessonID, card: index)
    }

    func isSaved(lessonID: String, index: Int) -> Bool {
        game.isSaved(lessonID: lessonID, index: index)
    }

    @discardableResult
    func toggleSaved(lessonID: String, index: Int) -> Bool {
        game.toggleSaved(lessonID: lessonID, index: index)
    }

    func markTapCoachSeen() { game.hasSeenTapCoach = true }

    /// The deck offered under Continue: the one you are furthest into. Finished decks
    /// clear their progress, so this only ever offers something genuinely unfinished.
    var continueLesson: (lesson: Lesson, card: Int)? {
        game.deckProgress
            .compactMap { id, index -> (Lesson, Int)? in
                guard let lesson = Catalog.lesson(id), index < lesson.cards.count else { return nil }
                return (lesson, index)
            }
            .max { $0.1 < $1.1 }
            .map { (lesson: $0.0, card: $0.1) }
    }

    var lessonSuggestions: [Catalog.Suggestion] {
        // A deck already on offer under Continue must not be offered twice on the
        // same screen, so it counts as spoken for here.
        var spokenFor = completedLessons
        if let cont = continueLesson { spokenFor.insert(cont.lesson.id) }
        return Catalog.suggestions(for: tasks, completed: spokenFor)
    }

    // MARK: - Spending

    func upgradeActiveChibi() {
        if game.upgradeActiveChibi() { play(.celebrate) }
    }

    func buy(_ species: ChibiSpecies) {
        if game.buy(species) { play(.celebrate) }
    }

    func buyScene(_ scene: Scene0) {
        if game.buyScene(scene) {
            play(.celebrate)
            game.equipScene(scene.id)
            show("\(scene.name) is your scene")
        }
    }

    func equipScene(_ id: String) {
        game.equipScene(id)
        show("\(Scene0.find(id).name) is your scene")
    }

    func setActive(_ speciesID: String) {
        game.setActive(speciesID)
        play(.wave)
        if let kin = ownedKin(speciesID) { show("\(kin.displayName) is your active kin") }
    }

    // MARK: - Kin

    /// The purchase ceremony, as one path: confirm, arrival, naming, certificate.
    /// Every step after the first can be left, and leaving keeps the kin.
    struct Adoption: Equatable {
        enum Step { case confirm, arrival, naming, certificate }
        var species: ChibiSpecies
        var step: Step = .confirm
        var draftName: String = ""
    }

    func beginAdoption(_ species: ChibiSpecies) {
        adoption = Adoption(species: species, draftName: Self.shuffleName())
    }

    /// Takes the coins and hands back the kin. Returns false only when the balance
    /// moved underneath us; the sheet never opens without the coins being there.
    @discardableResult
    func confirmAdoption() -> Bool {
        guard var flow = adoption, game.adopt(flow.species) else { return false }
        play(.celebrate)
        flow.step = .arrival
        adoption = flow
        return true
    }

    func advanceAdoption(to step: Adoption.Step) {
        guard var flow = adoption else { return }
        flow.step = step
        adoption = flow
    }

    func shuffleDraftName() {
        guard var flow = adoption else { return }
        var next = Self.shuffleName()
        while next == flow.draftName { next = Self.shuffleName() }
        flow.draftName = next
        adoption = flow
    }

    func commitName() {
        guard let flow = adoption else { return }
        game.rename(flow.species.id, to: flow.draftName)
        advanceAdoption(to: .certificate)
    }

    func rename(_ speciesID: String, to name: String) {
        game.rename(speciesID, to: name)
    }

    func endAdoption() { adoption = nil }

    /// One tap from the kin's sheet: pay and go straight to the arrival screen.
    /// The sheet already showed the price and the wallet after, so a second
    /// confirm sheet was the same question asked twice.
    func adoptNow(_ species: ChibiSpecies) {
        beginAdoption(species)
        confirmAdoption()
    }

    /// "Meet <kin>" on the certificate. Ends the flow and asks Root for the Kin tab.
    func meetKin(_ species: ChibiSpecies) {
        if activeChibiID != species.id { setActive(species.id) }
        endAdoption()
        meetKinRequest = species.id
    }

    private static func shuffleName() -> String {
        GameState.shuffleNames.randomElement() ?? "Moss"
    }

    // MARK: - Shop picks

    var rerollsLeft: Int { game.rerollsLeft }

    /// Free, three a day, never confirmed. The 420ms flag is only so the row can
    /// stagger; nothing is disabled while it runs, because there is no cost to
    /// protect against a double tap.
    func rerollPicks() {
        let held = game.lockedPick.flatMap { game.resolvePick($0)?.name }
        guard game.rerollPicks() else {
            show("No rerolls left today. New picks tomorrow.")
            return
        }
        rerolling = true
        show(held.map { "Five new picks · \($0) kept" } ?? "Five new picks")
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(420))
            rerolling = false
        }
    }

    /// Rolls the row over if the day changed, or backfills a slot that was bought.
    func refreshPicks() { game.refreshPicksIfNeeded() }

    func toggleLock(_ id: String) {
        let wasLocked = game.lockedPick == id
        game.toggleLock(id)
        guard !wasLocked, let pick = game.resolvePick(id) else { return }
        show("\(pick.name) held at \(pick.price) · tap to release")
    }

    // MARK: - Care

    /// Free, unlimited, no cooldown, no counter, no coins either way. The kin has no
    /// meter to fill and nothing it needs from the student.
    func care(_ kind: CareKind) {
        play(kind.animation)
    }

    enum CareKind: CaseIterable {
        case pet, highFive, snack

        var animation: ChibiAnimation {
            switch self {
            case .pet: return .bounce
            case .highFive: return .wave
            case .snack: return .celebrate
            }
        }
        var label: String {
            switch self {
            case .pet: return "Pet"
            case .highFive: return "High five"
            case .snack: return "Snack"
            }
        }
        var glyph: KinGlyph {
            switch self {
            case .pet: return .pet
            case .highFive: return .highFive
            case .snack: return .snack
            }
        }
        func bubble(_ name: String) -> String {
            switch self {
            case .pet: return "\(name) leans into it."
            case .highFive: return "Nailed it."
            case .snack: return "Crunch."
            }
        }
    }

    // MARK: - Toast

    func show(_ text: String) {
        toastTask?.cancel()
        toast = text
        toastTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(2400))
            guard !Task.isCancelled else { return }
            toast = nil
        }
    }

    // MARK: - Reminders

    /// Turning reminders on is the only thing that asks iOS for permission. If the
    /// user says no at the system prompt, the switch goes back off rather than
    /// pretending it worked.
    func setRemindersEnabled(_ on: Bool) async {
        if on {
            let granted = await NotificationScheduler.shared.requestAuthorization()
            game.settings.remindersEnabled = granted
        } else {
            game.settings.remindersEnabled = false
        }
        await NotificationScheduler.shared.reschedule(for: game)
    }

    func setNudgeHour(_ hour: Int) {
        game.settings.nudgeHour = min(max(hour, 6), 23)
        rescheduleReminders()
    }

    func setDueReminders(_ on: Bool) {
        game.settings.dueRemindersEnabled = on
        rescheduleReminders()
    }

    func setComeBackReminders(_ on: Bool) {
        game.settings.comeBackRemindersEnabled = on
        rescheduleReminders()
    }

    private func rescheduleReminders() {
        guard game.settings.remindersEnabled else { return }
        let snapshot = game
        Task { await NotificationScheduler.shared.reschedule(for: snapshot) }
    }

    // MARK: - Mascot

    /// Play a one-shot animation, then fall back to idle.
    private var animationToken = UUID()
    func play(_ anim: ChibiAnimation) {
        animation = anim
        let token = UUID()
        animationToken = token
        Task {
            try? await Task.sleep(for: .seconds(anim.duration))
            if animationToken == token { animation = .idle }
        }
    }
}

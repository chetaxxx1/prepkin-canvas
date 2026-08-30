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
    var sceneID: String { game.sceneID }
    var ownedScenes: Set<String> { game.ownedScenes }
    var templates: [TaskTemplate] { game.templates }
    var settings: AppSettings { game.settings }
    var wordleClaimedToday: Bool { game.wordleClaimedToday }
    var coinHistory: [CoinEntry] { game.ledger.entries.reversed() }
    var courses: [CanvasCourse] { game.canvasCourses }
    var bestShift: Int { game.bestShift }

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
        if game.recordWordleWin(day: dealtDay) > 0 { play(.celebrate) }
    }

    func completeLesson(id: String, reward: Int) {
        if game.completeLesson(id: id, reward: reward) > 0 { play(.celebrate) }
    }

    // MARK: - Spending

    func upgradeActiveChibi() {
        if game.upgradeActiveChibi() { play(.celebrate) }
    }

    func buy(_ species: ChibiSpecies) {
        if game.buy(species) { play(.celebrate) }
    }

    func buyScene(_ scene: Scene0) {
        if game.buyScene(scene) { play(.celebrate) }
    }

    func equipScene(_ id: String) { game.equipScene(id) }

    func setActive(_ speciesID: String) {
        game.setActive(speciesID)
        play(.wave)
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

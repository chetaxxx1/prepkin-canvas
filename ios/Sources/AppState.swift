import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var coins: Int
    @Published var owned: [OwnedChibi]
    @Published var activeChibiID: String
    @Published var tasks: [DailyTask]
    @Published var animation: ChibiAnimation = .wave
    @Published var completedLessons: Set<String>
    @Published var week: WeekStats
    @Published var sceneID: String
    @Published var ownedScenes: Set<String>
    /// Raised by pushed sub-screens (Daily Word, a lesson, the grade calculator)
    /// and by a running focus session, so the floating bar gets out of the way.
    @Published var hideTabBar = false

    private let canvas: CanvasSyncClient = MockCanvasClient()

    var activeChibi: OwnedChibi {
        owned.first { $0.speciesID == activeChibiID } ?? owned[0]
    }

    var allDone: Bool { !tasks.isEmpty && tasks.allSatisfy(\.done) }

    // MARK: - Weekly stats

    struct WeekStats: Codable {
        var key: String          // e.g. "2026-W35"
        var tasksDone = 0
        var coinsEarned = 0
        var focusMinutes = 0
        var wordleSolved = 0
        var lessonsDone = 0

        static func currentKey() -> String {
            let c = Calendar.current
            return "\(c.component(.yearForWeekOfYear, from: Date()))-W\(c.component(.weekOfYear, from: Date()))"
        }
    }

    // MARK: - Init / persistence

    private struct Snapshot: Codable {
        var coins: Int
        var owned: [OwnedChibi]
        var activeChibiID: String
        var tasks: [DailyTask]
        var completedLessons: Set<String>
        var week: WeekStats
        var savedOn: Date
        var sceneID: String?
        var ownedScenes: Set<String>?
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: "snapshot2"),
           let snap = try? JSONDecoder().decode(Snapshot.self, from: data) {
            coins = snap.coins
            owned = snap.owned
            activeChibiID = snap.activeChibiID
            tasks = Calendar.current.isDateInToday(snap.savedOn) ? snap.tasks : Self.defaultTasks()
            completedLessons = snap.completedLessons
            week = snap.week.key == WeekStats.currentKey() ? snap.week : WeekStats(key: WeekStats.currentKey())
            sceneID = snap.sceneID ?? "dorm"
            ownedScenes = snap.ownedScenes ?? ["dorm"]
        } else {
            coins = 0
            owned = [OwnedChibi(speciesID: "slime", level: 1)]
            activeChibiID = "slime"
            tasks = Self.defaultTasks()
            completedLessons = []
            week = WeekStats(key: WeekStats.currentKey())
            sceneID = "dorm"
            ownedScenes = ["dorm"]
        }
    }

    private static func defaultTasks() -> [DailyTask] {
        [
            DailyTask(id: "s-1", title: "20 min SAT practice", kind: .study),
            DailyTask(id: "l-1", title: "Drink a glass of water", kind: .life),
            DailyTask(id: "l-2", title: "10 minute walk", kind: .life),
            DailyTask(id: "l-3", title: "In bed by 11", kind: .life),
        ]
    }

    private func save() {
        let snap = Snapshot(coins: coins, owned: owned, activeChibiID: activeChibiID,
                            tasks: tasks, completedLessons: completedLessons,
                            week: week, savedOn: Date(),
                            sceneID: sceneID, ownedScenes: ownedScenes)
        if let data = try? JSONEncoder().encode(snap) {
            UserDefaults.standard.set(data, forKey: "snapshot2")
        }
    }

    // MARK: - Canvas

    func syncCanvas() async {
        guard let items = try? await canvas.fetchTodo() else { return }
        let existing = Dictionary(uniqueKeysWithValues: tasks.filter { $0.kind == .canvas }.map { ($0.id, $0) })
        let canvasTasks = items.map { item in
            var t = DailyTask(id: item.id, title: item.title, kind: .canvas,
                              detail: item.courseName, dueAt: item.dueAt)
            t.done = existing[item.id]?.done ?? false
            return t
        }
        tasks = canvasTasks + tasks.filter { $0.kind != .canvas }
        save()
    }

    // MARK: - Economy

    /// Every coin in the app flows through here. Pays for completion, never for performance.
    func earn(_ amount: Int, celebrate: Bool = false) {
        coins += amount
        week.coinsEarned += amount
        play(celebrate ? .celebrate : .bounce)
        save()
    }

    func complete(_ task: DailyTask) {
        guard let i = tasks.firstIndex(where: { $0.id == task.id }), !tasks[i].done else { return }
        tasks[i].done = true
        week.tasksDone += 1
        earn(task.reward, celebrate: allDone)
    }

    /// Undo a check-off. Takes the coins back, plays nothing. Never a penalty.
    func uncomplete(_ task: DailyTask) {
        guard let i = tasks.firstIndex(where: { $0.id == task.id }), tasks[i].done else { return }
        tasks[i].done = false
        coins = max(0, coins - task.reward)
        week.tasksDone = max(0, week.tasksDone - 1)
        week.coinsEarned = max(0, week.coinsEarned - task.reward)
        save()
    }

    // MARK: - Scenes

    func buyScene(_ scene: Scene0) {
        guard coins >= scene.price, !ownedScenes.contains(scene.id) else { return }
        coins -= scene.price
        ownedScenes.insert(scene.id)
        sceneID = scene.id
        play(.celebrate)
        save()
    }

    func equipScene(_ id: String) {
        guard ownedScenes.contains(id) else { return }
        sceneID = id
        save()
    }

    func recordFocus(minutes: Int) {
        week.focusMinutes += minutes
        earn(minutes, celebrate: minutes >= 25)
    }

    func recordWordleWin(guesses: Int) {
        week.wordleSolved += 1
        earn(30, celebrate: true)
    }

    func completeLesson(id: String, reward: Int) {
        guard !completedLessons.contains(id) else { return }
        completedLessons.insert(id)
        week.lessonsDone += 1
        earn(reward, celebrate: true)
    }

    func upgradeActiveChibi() {
        guard let cost = activeChibi.nextUpgradeCost, coins >= cost,
              let i = owned.firstIndex(where: { $0.speciesID == activeChibiID }) else { return }
        coins -= cost
        owned[i].level += 1
        play(.celebrate)
        save()
    }

    func buy(_ species: ChibiSpecies) {
        guard coins >= species.price,
              !owned.contains(where: { $0.speciesID == species.id }) else { return }
        coins -= species.price
        owned.append(OwnedChibi(speciesID: species.id, level: 1))
        activeChibiID = species.id
        play(.celebrate)
        save()
    }

    func setActive(_ speciesID: String) {
        guard owned.contains(where: { $0.speciesID == speciesID }) else { return }
        activeChibiID = speciesID
        play(.wave)
        save()
    }

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

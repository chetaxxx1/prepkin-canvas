import XCTest
@testable import PrepkinCanvas

final class StoreTests: XCTestCase {
    private var dir: URL!
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUpWithError() throws {
        dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("store-tests-\(UUID().uuidString)", isDirectory: true)
        suiteName = "store-tests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: dir)
        defaults.removePersistentDomain(forName: suiteName)
    }

    private func makeStore() -> Store {
        Store(directory: dir, defaults: defaults, debounce: 0)
    }

    // MARK: - Round trip

    func testAFreshInstallStartsWithTheStarterState() {
        let state = makeStore().load()
        XCTAssertEqual(state.ledger.balance, 0)
        XCTAssertEqual(state.activeChibiID, "slime")
        XCTAssertFalse(state.tasks.isEmpty)
    }

    func testWhatIsSavedIsWhatComesBack() {
        let store = makeStore()
        var state = store.load()
        let task = state.tasks.first!
        state.complete(taskID: task.id, reward: task.reward)
        state.settings.nudgeHour = 21
        store.save(state, immediately: true)

        let back = makeStore().load()
        XCTAssertEqual(back.ledger.balance, task.reward)
        XCTAssertEqual(back.settings.nudgeHour, 21)
        XCTAssertTrue(back.tasks.first { $0.id == task.id }!.done)
    }

    func testAHalfWrittenFileFallsBackToTheBackup() throws {
        let store = makeStore()
        var first = store.load()
        first.recordFocus(minutes: 40, sessionID: "a")
        store.save(first, immediately: true)

        var second = first
        second.recordFocus(minutes: 5, sessionID: "b")
        store.save(second, immediately: true)   // this is what makes the backup

        let main = dir.appendingPathComponent("state.json")
        try Data("{ not json".utf8).write(to: main)

        let recovered = makeStore().load()
        XCTAssertEqual(recovered.ledger.balance, 40, "the last good save should come back")
    }

    func testAnUnreadableFileIsSetAsideRatherThanOverwritten() throws {
        let main = dir.appendingPathComponent("state.json")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try Data("{ not json".utf8).write(to: main)

        _ = makeStore().load()

        let left = try FileManager.default.contentsOfDirectory(atPath: dir.path)
        XCTAssertTrue(left.contains { $0.hasPrefix("state.unreadable-") },
                      "a file we could not read must still be on disk somewhere")
    }

    // MARK: - v1 migration

    private func legacy(coins: Int, savedOn: Date, tasks: [DailyTask]) -> Store.LegacySnapshot {
        Store.LegacySnapshot(
            coins: coins,
            owned: [OwnedChibi(speciesID: "slime", level: 2)],
            activeChibiID: "slime",
            tasks: tasks,
            completedLessons: ["fin-1"],
            week: nil,
            savedOn: savedOn,
            sceneID: "meadow",
            ownedScenes: ["dorm", "meadow"])
    }

    func testTheOldSaveKeepsItsCoinsExactly() {
        let now = Date()
        var done = DailyTask(id: "l-1", title: "Drink a glass of water", kind: .life)
        done.done = true
        let open = DailyTask(id: "s-1", title: "20 min SAT practice", kind: .study)

        let state = Store.fromLegacy(legacy(coins: 340, savedOn: now, tasks: [done, open]), now: now)

        XCTAssertEqual(state.ledger.balance, 340, "the number on screen must not change on upgrade")
        XCTAssertTrue(state.tasks.first { $0.id == "l-1" }!.done, "today's checkmarks carry over")
        XCTAssertFalse(state.tasks.first { $0.id == "s-1" }!.done)
        XCTAssertEqual(state.activeChibi.level, 2)
        // Pin the retirement itself, so a future edit to Scene0.retired trips this test
        // instead of silently moving a scene she already paid for.
        XCTAssertEqual(Scene0.retired["meadow"], "kelp",
                       "this fixture is exercising the meadow-to-kelp retirement")
        XCTAssertEqual(state.sceneID, "kelp", "meadow became the kelp scene in the Sprout rename")
        XCTAssertEqual(state.ownedScenes, ["lagoon", "kelp"],
                       "both land scenes she paid for came across as tanks")
        XCTAssertEqual(state.completedLessons, ["fin-1"])
    }

    func testALegacySaveThatSpentTodaysEarningsDoesNotMintCoins() {
        // Earned 30 today (10 + 20), then spent most of it: 5 coins left.
        let now = Date()
        var life = DailyTask(id: "l-1", title: "Drink a glass of water", kind: .life)
        life.done = true
        var study = DailyTask(id: "s-1", title: "20 min SAT practice", kind: .study)
        study.done = true

        let state = Store.fromLegacy(legacy(coins: 5, savedOn: now, tasks: [life, study]), now: now)

        XCTAssertEqual(state.ledger.balance, 5,
                       "the number on screen must not change on upgrade — up or down")
    }

    func testTheOldSaveDoesNotCarryYesterdaysCheckmarks() {
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        var done = DailyTask(id: "l-1", title: "Drink a glass of water", kind: .life)
        done.done = true

        let state = Store.fromLegacy(legacy(coins: 100, savedOn: yesterday, tasks: [done]), now: now)

        XCTAssertEqual(state.ledger.balance, 100)
        XCTAssertFalse(state.tasks.first { $0.id == "l-1" }!.done)
    }

    func testTheOldTaskListBecomesTemplates() {
        let now = Date()
        let picked = DailyTask(id: "l-2", title: "10 minute walk", kind: .life)
        let custom = DailyTask(id: "mine-1", title: "Feed the cat", kind: .life)
        let canvas = DailyTask(id: "c-9", title: "Essay", kind: .canvas, detail: "English 11")

        let state = Store.fromLegacy(legacy(coins: 0, savedOn: now, tasks: [picked, custom, canvas]), now: now)

        XCTAssertTrue(state.templates.first { $0.id == "l-2" }!.isActive)
        XCTAssertFalse(state.templates.first { $0.id == "l-3" }!.isActive,
                       "a preset the user had removed stays off")
        XCTAssertTrue(state.templates.contains { $0.id == "mine-1" && !$0.isPreset })
        XCTAssertEqual(state.canvasItems.map(\.id), ["c-9"])
        XCTAssertEqual(state.canvasItems.first?.courseName, "English 11")
    }

    func testTheOldUserDefaultsBlobIsPickedUpOnFirstLaunch() throws {
        let now = Date()
        var done = DailyTask(id: "l-1", title: "Drink a glass of water", kind: .life)
        done.done = true
        // Encoded the way the old app wrote it: a bare encoder, so dates are numbers.
        let blob = try JSONEncoder().encode(legacy(coins: 275, savedOn: now, tasks: [done]))
        defaults.set(blob, forKey: Store.legacyDefaultsKey)

        let state = makeStore().load()
        XCTAssertEqual(state.ledger.balance, 275)

        // And it is now a file, so the next launch does not need the old blob.
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: dir.appendingPathComponent("state.json").path))
    }

    func testTheSaveFileCarriesItsSchemaVersion() throws {
        let store = makeStore()
        store.save(store.load(), immediately: true)
        let data = try Data(contentsOf: dir.appendingPathComponent("state.json"))
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(json?["version"] as? Int, Store.currentVersion)
    }
}

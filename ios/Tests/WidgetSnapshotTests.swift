import XCTest
@testable import PrepkinCanvas

/// The widget's copy of the day: written beside every save, never the save itself.
final class WidgetSnapshotTests: XCTestCase {
    private var dir: URL!

    override func setUpWithError() throws {
        dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("widget-snapshot-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: dir)
    }

    func testTheSnapshotCarriesTodaysListAndTheKin() {
        var s = GameState()
        s.owned[0].name = "Moss"
        let first = s.tasks[0]
        s.complete(taskID: first.id, reward: first.reward)
        let snap = WidgetSnapshot.make(from: s, shift: nil)
        XCTAssertEqual(snap.name, "Moss")
        XCTAssertEqual(snap.speciesID, "slime")
        XCTAssertEqual(snap.stage, 1)
        XCTAssertEqual(snap.kinAsset, "sprout-mint-1")
        XCTAssertEqual(snap.plainAsset, "sprout-mint-1")
        XCTAssertEqual(snap.coins, first.reward)
        XCTAssertEqual(snap.tasks.map(\.title), s.tasks.map(\.title))
        XCTAssertEqual(snap.tasks.filter(\.done).map(\.id), [first.id])
        XCTAssertFalse(snap.allDone)
        XCTAssertNil(snap.shiftEndsAt)
        XCTAssertEqual(snap.checkInHour, 19)
        XCTAssertEqual(snap.day, s.effectiveDay.raw)
    }

    func testARunningShiftPutsItsEndInTheSnapshot() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let saved = SavedShift(id: "x", minutes: 25, banked: 0, legStart: now,
                               workingOnID: nil, workingOnCleared: false)
        let snap = WidgetSnapshot.make(from: GameState(), shift: saved, now: now)
        XCTAssertEqual(snap.shiftEndsAt, now.addingTimeInterval(25 * 60))
        let paused = SavedShift(id: "x", minutes: 25, banked: 60, legStart: nil,
                                workingOnID: nil, workingOnCleared: false)
        XCTAssertNil(WidgetSnapshot.make(from: GameState(), shift: paused, now: now).shiftEndsAt)
    }

    func testTheSnapshotRoundTripsThroughItsFile() {
        let snap = WidgetSnapshot.make(from: GameState(), shift: nil)
        snap.write(to: dir)
        let back = WidgetSnapshot.load(from: dir)
        XCTAssertEqual(back?.tasks.count, snap.tasks.count)
        XCTAssertEqual(back?.kinAsset, snap.kinAsset)
        XCTAssertEqual(back?.day, snap.day)
    }

    /// The save writes `widget.json` next to itself, in the same folder the store
    /// was given, so a test never touches the phone's real widget.
    func testSavingWritesTheWidgetFile() {
        let store = Store(directory: dir, defaults: UserDefaults(suiteName: "widget-\(UUID().uuidString)")!,
                          debounce: 0)
        var s = GameState()
        s.owned[0].name = "Pebble"
        store.save(s, immediately: true)
        let snap = WidgetSnapshot.load(from: dir)
        XCTAssertEqual(snap?.name, "Pebble")
        XCTAssertTrue(FileManager.default.fileExists(atPath: dir.appendingPathComponent("state.json").path))
    }
}

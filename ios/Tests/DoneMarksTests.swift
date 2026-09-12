import XCTest
@testable import PrepkinCanvas

/// The Done button's promise: a tap outside the app pays once, on the next open,
/// and never twice.
final class DoneMarksTests: XCTestCase {
    private var dir: URL!

    override func setUpWithError() throws {
        dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("done-marks-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: dir)
    }

    func testAMarkRoundTripsThroughTheFile() {
        XCTAssertEqual(DoneMarks.load(in: dir), [])
        DoneMarks.add("s-5", at: Date(timeIntervalSince1970: 1_000), in: dir)
        XCTAssertEqual(DoneMarks.load(in: dir).map(\.taskID), ["s-5"])
        DoneMarks.clear(in: dir)
        XCTAssertEqual(DoneMarks.load(in: dir), [])
    }

    func testASecondTapOnTheSameTaskIsOneMark() {
        DoneMarks.add("s-5", in: dir)
        DoneMarks.add("s-5", in: dir)
        DoneMarks.add("l-1", in: dir)
        XCTAssertEqual(DoneMarks.load(in: dir).map(\.taskID), ["s-5", "l-1"])
    }

    func testTheAppPaysAMarkOnceAndNeverTwice() {
        var s = GameState()
        let task = s.tasks[0]
        let before = s.ledger.balance
        DoneMarks.add(task.id, in: dir)

        let paid = s.applyDoneMarks(DoneMarks.load(in: dir))
        XCTAssertEqual(paid.map(\.task.id), [task.id])
        XCTAssertEqual(s.ledger.balance, before + task.reward)
        XCTAssertTrue(s.tasks.first { $0.id == task.id }!.done)

        // The file was not cleared in time and the app opened again.
        let again = s.applyDoneMarks(DoneMarks.load(in: dir))
        XCTAssertTrue(again.isEmpty)
        XCTAssertEqual(s.ledger.balance, before + task.reward)
    }

    func testAMarkForATaskNotOnTodaysListIsDropped() {
        var s = GameState()
        let before = s.ledger.balance
        let paid = s.applyDoneMarks([DoneMark(taskID: "gone", at: Date())])
        XCTAssertTrue(paid.isEmpty)
        XCTAssertEqual(s.ledger.balance, before)
    }

    func testOnlyANoteThatNamesOneTaskCarriesDone() {
        let calendar = Calendar(identifier: .gregorian)
        var c = DateComponents(); c.year = 2026; c.month = 8; c.day = 29; c.hour = 10
        let now = calendar.date(from: c)!
        var s = GameState()
        s.currentDay = DayKey(now, calendar: calendar)
        s.maxDayReached = s.currentDay
        s.lastOpenedAt = now
        s.settings.remindersEnabled = true
        var due = c; due.day = 31; due.hour = 20
        s.applyCanvas(CanvasSnapshot(tasks: [CanvasItem(id: "c-1", title: "Bio quiz", courseName: "BIO 101",
                                                        dueAt: calendar.date(from: due)!)]))
        var plan = NotificationPlanner.plan(for: s, now: now, calendar: calendar)
        XCTAssertEqual(plan.first { $0.id == "due:c-1" }?.taskID, "c-1")
        XCTAssertNil(plan.first { $0.id == "nudge:2026-08-29" }?.taskID, "several open: no Done")

        for t in s.tasks.dropFirst() { s.complete(taskID: t.id, reward: t.reward, now: now) }
        plan = NotificationPlanner.plan(for: s, now: now, calendar: calendar)
        XCTAssertEqual(plan.first { $0.id == "nudge:2026-08-29" }?.taskID, s.tasks[0].id)
    }
}

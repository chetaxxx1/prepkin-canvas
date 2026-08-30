import XCTest
@testable import PrepkinCanvas

final class NotificationPlannerTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    /// A fixed 10:00 on a known day, so nothing here depends on when it runs.
    private func at(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        var c = DateComponents()
        c.year = 2026; c.month = 8; c.day = day; c.hour = hour; c.minute = minute
        return calendar.date(from: c)!
    }

    private func state(now: Date) -> GameState {
        var s = GameState()
        s.currentDay = DayKey(now, calendar: calendar)
        s.maxDayReached = s.currentDay
        s.lastOpenedAt = now
        s.settings.remindersEnabled = true
        return s
    }

    func testNothingIsScheduledUntilTheUserTurnsRemindersOn() {
        var s = state(now: at(29, 10))
        s.settings.remindersEnabled = false
        XCTAssertTrue(NotificationPlanner.plan(for: s, now: at(29, 10), calendar: calendar).isEmpty)
    }

    func testTheEveningCheckInIsQueuedWhileTasksAreOpen() {
        let now = at(29, 10)
        let plan = NotificationPlanner.plan(for: state(now: now), now: now, calendar: calendar)
        XCTAssertTrue(plan.contains { $0.id == "nudge:2026-08-29" })
    }

    func testTheEveningCheckInIsDroppedOnceTheListIsClear() {
        let now = at(29, 10)
        var s = state(now: now)
        for t in s.tasks { s.complete(taskID: t.id, reward: t.reward, now: now) }
        let plan = NotificationPlanner.plan(for: s, now: now, calendar: calendar)
        XCTAssertFalse(plan.contains { $0.id == "nudge:2026-08-29" },
                       "finishing everything should not earn you a reminder")
    }

    func testThePastIsNeverScheduled() {
        let now = at(29, 21)   // after the 19:00 check-in
        let plan = NotificationPlanner.plan(for: state(now: now), now: now, calendar: calendar)
        XCTAssertFalse(plan.contains { $0.id == "nudge:2026-08-29" })
        XCTAssertTrue(plan.allSatisfy { $0.fireAt > now })
    }

    func testAnAssignmentGetsAHeadsUpTwelveHoursOut() {
        let now = at(29, 10)
        var s = state(now: now)
        s.applyCanvas(CanvasSnapshot(tasks: [CanvasItem(id: "c-1", title: "Problem set", courseName: "Physics", dueAt: at(31, 23))]))
        let plan = NotificationPlanner.plan(for: s, now: now, calendar: calendar)
        let due = plan.first { $0.id == "due:c-1" }
        XCTAssertEqual(due?.fireAt, at(31, 11))
    }

    func testAHeadsUpNeverLandsInTheMiddleOfTheNight() {
        let now = at(29, 10)
        var s = state(now: now)
        // 12 hours before a 14:00 deadline is 02:00 — pushed to a civilised hour.
        s.applyCanvas(CanvasSnapshot(tasks: [CanvasItem(id: "c-1", title: "Quiz", courseName: "APUSH", dueAt: at(31, 14))]))
        let plan = NotificationPlanner.plan(for: s, now: now, calendar: calendar)
        XCTAssertEqual(plan.first { $0.id == "due:c-1" }?.fireAt, at(31, 8))
    }

    func testAFinishedAssignmentStopsBuzzing() {
        let now = at(29, 10)
        var s = state(now: now)
        s.applyCanvas(CanvasSnapshot(tasks: [CanvasItem(id: "c-1", title: "Problem set", courseName: "Physics", dueAt: at(31, 23))]))
        s.complete(taskID: "c-1", reward: TaskKind.canvas.reward, now: now)
        let plan = NotificationPlanner.plan(for: s, now: now, calendar: calendar)
        XCTAssertFalse(plan.contains { $0.id == "due:c-1" })
    }

    func testAnAssignmentAlreadyPastDueIsLeftAlone() {
        let now = at(29, 10)
        var s = state(now: now)
        s.applyCanvas(CanvasSnapshot(tasks: [CanvasItem(id: "c-1", title: "Late one", courseName: "Math", dueAt: at(28, 23))]))
        let plan = NotificationPlanner.plan(for: s, now: now, calendar: calendar)
        XCTAssertFalse(plan.contains { $0.id == "due:c-1" }, "no nagging about what is already late")
    }

    func testTheComeBackNoteWaitsThreeDays() {
        let now = at(29, 10)
        let plan = NotificationPlanner.plan(for: state(now: now), now: now, calendar: calendar)
        XCTAssertEqual(plan.first { $0.id == "comeback" }?.fireAt, at(1 + 31, 17))
    }

    func testNoRemindersSayAnythingAboutLosingAStreak() {
        let now = at(29, 10)
        var s = state(now: now)
        s.applyCanvas(CanvasSnapshot(tasks: [CanvasItem(id: "c-1", title: "Essay", courseName: "English", dueAt: at(31, 23))]))
        let words = ["streak", "lost", "lose", "don't break", "failed", "behind"]
        for item in NotificationPlanner.plan(for: s, now: now, calendar: calendar) {
            let text = (item.title + " " + item.body).lowercased()
            for bad in words {
                XCTAssertFalse(text.contains(bad), "\(item.id) says '\(bad)'")
            }
        }
    }
}

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

    // MARK: - The board

    private func friend(_ id: String) -> Friend {
        Friend(id: id, adjective: 1, noun: 2, speciesID: "ember", lookID: "classic",
               costumeID: "none", sceneID: "reef", level: 2, tier: .reef,
               friendsSince: Date(timeIntervalSince1970: 1_757_000_000), onShiftUntil: nil)
    }

    /// 2026-08-29 is a Saturday: the week settles on Sunday the 30th at six and is
    /// announced Monday the 31st at nine.
    func testTheBoardSpeaksTwiceAWeekOnlyWithAFriend() {
        let now = at(29, 10)
        var s = state(now: now)
        XCTAssertFalse(NotificationPlanner.plan(for: s, now: now, calendar: calendar)
            .contains { $0.id.hasPrefix("board:") }, "no friend, no board, nothing to say")
        s.addFriend(friend("a"), now: now)
        let plan = NotificationPlanner.plan(for: s, now: now, calendar: calendar)
        XCTAssertEqual(plan.first { $0.id == "board:settles:2026-W35" }?.fireAt, at(30, 18))
        XCTAssertEqual(plan.first { $0.id == "board:settled:2026-W35" }?.fireAt, at(31, 9))
    }

    func testSundaysNoteIsDroppedOnceItIsSundayEvening() {
        let now = at(30, 20)
        var s = state(now: now)
        s.addFriend(friend("a"), now: now)
        let plan = NotificationPlanner.plan(for: s, now: now, calendar: calendar)
        XCTAssertFalse(plan.contains { $0.id == "board:settles:2026-W35" })
        XCTAssertTrue(plan.contains { $0.id == "board:settled:2026-W35" })
    }

    /// The house rule, on every kind the planner can produce at once: a due
    /// reminder, three check-ins, the come-back note and the board's two.
    func testNoPlannedTextScoldsOrShouts() {
        let now = at(29, 10)
        var s = state(now: now)
        s.applyCanvas(CanvasSnapshot(tasks: [CanvasItem(id: "c-1", title: "Essay", courseName: "English", dueAt: at(31, 23))]))
        s.addFriend(friend("a"), now: now)
        let plan = NotificationPlanner.plan(for: s, now: now, calendar: calendar)
        XCTAssertGreaterThanOrEqual(plan.count, 5)
        let words = ["streak", "missed", "lose", "lost", "don't break", "failed", "behind", "!"]
        for item in plan {
            let text = (item.title + " " + (item.subtitle ?? "") + " " + item.body).lowercased()
            for bad in words {
                XCTAssertFalse(text.contains(bad), "\(item.id) says '\(bad)'")
            }
            XCTAssertLessThan(item.title.count, 40, "\(item.id) title runs long: \(item.title)")
        }
    }

    // MARK: - The check-in's words

    func testTheCheckInIsSilentWhenNothingIsOpen() {
        XCTAssertNil(NotificationPlanner.checkIn(openTitles: []))
        XCTAssertNil(NotificationPlanner.checkIn(openTitles: ["  "]))
    }

    func testTheCheckInNamesOneOpenTask() {
        let copy = NotificationPlanner.checkIn(openTitles: ["Essay outline"])
        XCTAssertEqual(copy?.title, "1 left today")
        XCTAssertEqual(copy?.body, "Essay outline. Then you're done.")
    }

    func testTheCheckInNamesTwoOpenTasksThenPromisesDone() {
        let copy = NotificationPlanner.checkIn(openTitles: ["Essay outline", "The walk"])
        XCTAssertEqual(copy?.title, "2 left today")
        XCTAssertEqual(copy?.body, "Essay outline, then the walk. Then you're done.")
    }

    func testTheCheckInCountsTheRestOfFiveInsteadOfPromisingDone() {
        let copy = NotificationPlanner.checkIn(openTitles: ["Essay outline", "Bio quiz", "Walk", "Read", "Water"])
        XCTAssertEqual(copy?.title, "5 left today")
        XCTAssertEqual(copy?.body, "Essay outline, then bio quiz, then 3 more.")
    }

    func testTheCheckInKeepsAnAcronymsCapital() {
        let copy = NotificationPlanner.checkIn(openTitles: ["Walk", "BIO 101 quiz"])
        XCTAssertEqual(copy?.body, "Walk, then BIO 101 quiz. Then you're done.")
    }

    func testTonightsCheckInUsesTheRealList() {
        let now = at(29, 10)
        var s = state(now: now)
        // The starter set is three dailies; finish all but one.
        let open = s.tasks.filter { !$0.done }
        for t in open.dropFirst() { s.complete(taskID: t.id, reward: t.reward, now: now) }
        let plan = NotificationPlanner.plan(for: s, now: now, calendar: calendar)
        let tonight = plan.first { $0.id == "nudge:2026-08-29" }
        XCTAssertEqual(tonight?.title, "1 left today")
        XCTAssertEqual(tonight?.body, "\(open[0].title). Then you're done.")
    }

    func testTomorrowsCheckInBringsTheDailiesBack() {
        let now = at(29, 10)
        var s = state(now: now)
        for t in s.tasks { s.complete(taskID: t.id, reward: t.reward, now: now) }
        let plan = NotificationPlanner.plan(for: s, now: now, calendar: calendar)
        XCTAssertNil(plan.first { $0.id == "nudge:2026-08-29" }, "tonight is clear")
        let tomorrow = plan.first { $0.id == "nudge:2026-08-30" }
        XCTAssertEqual(tomorrow?.title, "\(s.tasks.count) left today")
    }

    // MARK: - The due reminder's words

    func testADueReminderLeadsWithTheTimeAndTheCourse() {
        let now = at(29, 10)
        var s = state(now: now)
        s.applyCanvas(CanvasSnapshot(tasks: [CanvasItem(id: "c-1", title: "Bio quiz", courseName: "BIO 101", dueAt: at(31, 8))]))
        let due = NotificationPlanner.plan(for: s, now: now, calendar: calendar).first { $0.id == "due:c-1" }
        XCTAssertEqual(due?.title, "Due \(at(31, 8).formatted(.dateTime.weekday().hour().minute())) · BIO 101")
        XCTAssertEqual(due?.subtitle, "Bio quiz")
        XCTAssertEqual(due?.body, "Just a heads up. Moss is around if you want to knock it out.")
    }

    func testADueReminderNeverFiresAtElevenOrLater() {
        let now = at(29, 10)
        var s = state(now: now)
        // 12 hours before 11:30 AM is 11:30 PM — pulled back to 10 PM.
        s.applyCanvas(CanvasSnapshot(tasks: [CanvasItem(id: "c-1", title: "Lab", courseName: "CHEM", dueAt: at(31, 11, 30))]))
        let due = NotificationPlanner.plan(for: s, now: now, calendar: calendar).first { $0.id == "due:c-1" }
        XCTAssertEqual(due?.fireAt, at(30, 22))
    }

    // MARK: - One a day

    /// Sunday the 30th has the board note at six; that evening's check-in is dropped
    /// for it. Saturday keeps its check-in.
    func testOnlyOneNonDueNoteADay() {
        let now = at(29, 10)
        var s = state(now: now)
        s.addFriend(friend("a"), now: now)
        let plan = NotificationPlanner.plan(for: s, now: now, calendar: calendar)
        XCTAssertTrue(plan.contains { $0.id == "nudge:2026-08-29" })
        XCTAssertTrue(plan.contains { $0.id == "board:settles:2026-W35" })
        XCTAssertFalse(plan.contains { $0.id == "nudge:2026-08-30" })
        let perDay = Dictionary(grouping: plan.filter { !$0.id.hasPrefix("due:") },
                                by: { DayKey($0.fireAt, calendar: calendar) })
        XCTAssertTrue(perDay.values.allSatisfy { $0.count == 1 })
    }
}

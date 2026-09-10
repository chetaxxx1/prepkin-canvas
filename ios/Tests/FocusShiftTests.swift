import XCTest
@testable import PrepkinCanvas

/// The Focus tab's promise, tested without a phone: a shift that is running has an
/// end booked, a shift that is paused does not, and the report says out loud what the
/// shift paid.
final class FocusShiftTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)
    private let kin = "Moss"

    private func at(_ hour: Int, _ minute: Int = 0, _ second: Int = 0) -> Date {
        var c = DateComponents()
        c.year = 2026; c.month = 9; c.day = 10
        c.hour = hour; c.minute = minute; c.second = second
        return calendar.date(from: c)!
    }

    // MARK: - The shift-end notification

    func testStartBooksTheEndOfTheShift() {
        var shift = FocusShift()
        let start = at(20, 0, 40)
        shift.start(minutes: 25, at: start)

        let item = NotificationPlanner.shiftEnd(for: shift, kinName: kin, now: start)
        XCTAssertNotNil(item)
        // To the second, not to the minute: the coins are earned at 20:25:40.
        XCTAssertEqual(item?.fireAt, at(20, 25, 40))
        XCTAssertEqual(item?.id, NotificationPlanner.shiftEndID)
        XCTAssertEqual(item?.title, "Shift over. 25 coins paid.")
        XCTAssertEqual(item?.body, "Moss swam 16 lengths.")
    }

    func testPausingTakesTheNotificationOffTheQueue() {
        var shift = FocusShift()
        shift.start(minutes: 25, at: at(20, 0))
        shift.pause(at: at(20, 5))
        XCTAssertNil(NotificationPlanner.shiftEnd(for: shift, kinName: kin, now: at(20, 5)),
                     "A paused shift has no end time, so nothing may be waiting to fire")
    }

    func testResumingBooksItAgainForTheTimeThatIsLeft() {
        var shift = FocusShift()
        shift.start(minutes: 25, at: at(20, 0))
        shift.pause(at: at(20, 5))
        shift.resume(at: at(20, 30))

        let item = NotificationPlanner.shiftEnd(for: shift, kinName: kin, now: at(20, 30))
        // Five minutes were banked, so twenty are left: 20:50, not 20:25.
        XCTAssertEqual(item?.fireAt, at(20, 50))
        XCTAssertEqual(item?.title, "Shift over. 25 coins paid.")
    }

    func testClockingOutLeavesNothingBooked() {
        var shift = FocusShift()
        shift.start(minutes: 15, at: at(20, 0))
        shift.clear()
        XCTAssertNil(NotificationPlanner.shiftEnd(for: shift, kinName: kin, now: at(20, 3)))
    }

    func testTheShiftAlarmIsNotAReminderAndIgnoresTheRemindersSwitch() {
        var shift = FocusShift()
        shift.start(minutes: 15, at: at(3, 0))
        // Reminders off, and 3am — both of which silence every other kind.
        var game = GameState()
        game.settings.remindersEnabled = false
        XCTAssertTrue(NotificationPlanner.plan(for: game, now: at(3, 0), calendar: calendar).isEmpty)
        XCTAssertNotNil(NotificationPlanner.shiftEnd(for: shift, kinName: kin, now: at(3, 0)),
                        "The student asked for a timer; that is not a reminder")
    }

    func testOneMinuteAndOneLengthReadAsSingular() {
        var shift = FocusShift()
        shift.start(minutes: 1, at: at(20, 0))
        let item = NotificationPlanner.shiftEnd(for: shift, kinName: kin, now: at(20, 0))
        XCTAssertEqual(item?.title, "Shift over. 1 coin paid.")
        XCTAssertEqual(item?.body, "Moss swam 0 lengths.")
    }

    // MARK: - The clock itself

    func testAPauseFreezesTheClockAndAResumeCarriesOn() {
        var shift = FocusShift()
        shift.start(minutes: 25, at: at(20, 0))
        shift.pause(at: at(20, 5))
        XCTAssertEqual(shift.elapsed(at: at(20, 40)), 300, "A paused shift does not age")
        shift.resume(at: at(20, 40))
        XCTAssertEqual(shift.elapsed(at: at(20, 45)), 600)
        XCTAssertEqual(shift.remaining(at: at(20, 45)), 900)
    }

    func testLengthsTickEveryNinetySeconds() {
        var shift = FocusShift()
        shift.start(minutes: 25, at: at(20, 0))
        XCTAssertEqual(shift.lengths(at: at(20, 1)), 0)
        XCTAssertEqual(shift.lengths(at: at(20, 1, 30)), 1)
        XCTAssertEqual(shift.nextLengthIn(at: at(20, 1)), 30)
    }

    // MARK: - The report's pay line

    private func result(minutes: Int, finished: Bool, lengths: Int = 0) -> ShiftResult {
        ShiftResult(minutes: minutes, paid: finished ? minutes : 0, lengths: lengths,
                    finished: finished, beatBest: false, workingOn: nil)
    }

    func testThePayLineShowsTheArithmeticForEveryLength() {
        XCTAssertEqual(ShiftReportCopy.payLine(result(minutes: 15, finished: true)),
                       "15 minutes. 15 coins.")
        XCTAssertEqual(ShiftReportCopy.payLine(result(minutes: 25, finished: true)),
                       "25 minutes. 25 coins.")
        XCTAssertEqual(ShiftReportCopy.payLine(result(minutes: 45, finished: true)),
                       "45 minutes. 45 coins.")
    }

    func testThePayLineAfterAClockOutSaysZeroWithoutScolding() {
        let line = ShiftReportCopy.payLine(result(minutes: 12, finished: false))
        XCTAssertEqual(line, "You worked 12 minutes. This shift pays nothing.")
        for word in ["lost", "wasted", "failed", "again", "?"] {
            XCTAssertFalse(line.lowercased().contains(word), "The report never scolds: \(word)")
        }
    }

    func testThePayLineAtZeroMinutes() {
        XCTAssertEqual(ShiftReportCopy.payLine(result(minutes: 0, finished: false)),
                       "You worked less than a minute. This shift pays nothing.")
    }

    func testTheBestShiftLineIsSaidOnlyWhenItChanged() {
        var r = result(minutes: 25, finished: true, lengths: 16)
        XCTAssertNil(ShiftReportCopy.bestLine(r))
        r = ShiftResult(minutes: 25, paid: 25, lengths: 16, finished: true,
                        beatBest: true, workingOn: nil)
        XCTAssertEqual(ShiftReportCopy.bestLine(r), "That is the longest swim yet.")
    }

    // MARK: - Working on

    func testWorkingOnDefaultsToTheNextUndoneTask() {
        var game = GameState()
        let tasks = game.tasks
        XCTAssertFalse(tasks.isEmpty)
        XCTAssertEqual(WorkingOn.auto.resolve(in: tasks)?.id, tasks.first { !$0.done }?.id)

        // Finish the first one and the default moves on by itself.
        let first = tasks.first { !$0.done }!
        game.complete(taskID: first.id, reward: first.reward)
        XCTAssertNotEqual(WorkingOn.auto.resolve(in: game.tasks)?.id, first.id)
    }

    func testNothingInParticularIsAChoiceTheScreenKeeps() {
        let game = GameState()
        XCTAssertNil(WorkingOn.nothing.resolve(in: game.tasks),
                     "A student who said 'nothing' is not handed a task anyway")
    }

    func testAPickedTaskWinsUntilItLeavesTheList() {
        let game = GameState()
        let tasks = game.tasks
        let second = tasks.filter { !$0.done }.dropFirst().first!
        XCTAssertEqual(WorkingOn.task(second.id).resolve(in: tasks)?.id, second.id)
        // A task that vanished (a Canvas row that stopped coming) falls back rather
        // than leaving the chip empty.
        XCTAssertNotNil(WorkingOn.task("gone").resolve(in: tasks))
    }

    // MARK: - This week

    func testTheWeekLineCountsOnlyShiftsThatPaid() {
        var game = GameState()
        let now = at(12)
        game.recordFocus(minutes: 25, sessionID: "a", now: now)
        game.recordFocus(minutes: 45, sessionID: "b", now: now)
        // A clock-out pays nothing, so it writes no line and is not a shift here.
        let week = game.ledger.focusWeek(of: now, calendar: calendar)
        XCTAssertEqual(week.shifts, 2)
        XCTAssertEqual(week.minutes, 70)
        XCTAssertEqual(FocusWeek.line(shifts: week.shifts, minutes: week.minutes),
                       "2 shifts · 1h 10m")
    }

    func testTheWeekLineIsAbsentUntilThereIsSomethingToSay() {
        XCTAssertNil(FocusWeek.line(shifts: 0, minutes: 0))
        XCTAssertEqual(FocusWeek.line(shifts: 1, minutes: 45), "1 shift · 45m")
        XCTAssertEqual(FocusWeek.line(shifts: 4, minutes: 120), "4 shifts · 2h")
    }

    // MARK: - The line under the title

    func testTheShiftScreenAsksForNothing() {
        let line = FocusCopy.waitLine(kinName: "Moss")
        XCTAssertEqual(line, "Moss is swimming. The phone can wait.")
        XCTAssertLessThan(line.count, 40)
        // The old line was "Put the phone down and let them work" — an instruction.
        XCTAssertFalse(line.lowercased().hasPrefix("put "))
        // A long name falls back rather than wrapping.
        XCTAssertEqual(FocusCopy.waitLine(kinName: "Bartholomew the Third"),
                       "The phone can wait.")
    }

    // MARK: - Surviving a kill

    func testARestoredShiftCarriesOnFromWhereItWas() {
        let saved = SavedShift(id: "s1", minutes: 25, banked: 300,
                               legStart: at(20, 10), workingOnID: "l-1",
                               workingOnCleared: false)
        let shift = saved.shift()
        XCTAssertEqual(shift.phase, .running)
        // Five minutes banked plus five on this leg.
        XCTAssertEqual(shift.elapsed(at: at(20, 15)), 600)
        XCTAssertEqual(shift.remaining(at: at(20, 15)), 900)
        XCTAssertEqual(saved.workingOn, .task("l-1"))
    }

    func testARestoredShiftThatWasPausedComesBackPaused() {
        let saved = SavedShift(id: "s2", minutes: 15, banked: 120, legStart: nil,
                               workingOnID: nil, workingOnCleared: true)
        XCTAssertEqual(saved.shift().phase, .paused)
        XCTAssertNil(NotificationPlanner.shiftEnd(for: saved.shift(), kinName: kin, now: at(20, 0)))
        XCTAssertEqual(saved.workingOn, .nothing, "'Nothing in particular' is a choice, not an absence")
    }

    func testAShiftThatRanOutWhileTheAppWasGoneIsStillOver() {
        let saved = SavedShift(id: "s3", minutes: 15, banked: 0, legStart: at(20, 0),
                               workingOnID: nil, workingOnCleared: false)
        XCTAssertEqual(saved.shift().remaining(at: at(20, 40)), 0,
                       "The report has to pay it: the notification already said it was paid")
    }

    func testAShiftRestoredTwicePaysOnce() {
        var game = GameState()
        let now = at(20, 30)
        XCTAssertEqual(game.recordFocus(minutes: 15, sessionID: "s4", now: now), 15)
        XCTAssertEqual(game.recordFocus(minutes: 15, sessionID: "s4", now: now), 0,
                       "The session id is the ledger key")
        XCTAssertEqual(game.ledger.focusWeek(of: now, calendar: calendar).shifts, 1)
    }

    func testTheStoreRoundTripsAndClears() {
        let defaults = UserDefaults(suiteName: "focus.tests")!
        defaults.removePersistentDomain(forName: "focus.tests")
        XCTAssertNil(ShiftStore.load(defaults))
        let saved = SavedShift(id: "s5", minutes: 45, banked: 90, legStart: at(21, 0),
                               workingOnID: "s-5", workingOnCleared: false)
        ShiftStore.save(saved, to: defaults)
        XCTAssertEqual(ShiftStore.load(defaults), saved)
        ShiftStore.clear(defaults)
        XCTAssertNil(ShiftStore.load(defaults))
    }
}

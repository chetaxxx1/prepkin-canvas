import XCTest
@testable import PrepkinCanvas

final class GameStateTests: XCTestCase {
    private let day1 = DayKey(raw: "2026-08-29")
    private let day2 = DayKey(raw: "2026-08-30")

    private func fresh(on day: DayKey) -> GameState {
        var s = GameState()
        s.currentDay = day
        s.maxDayReached = day
        return s
    }

    // MARK: - Tasks

    func testCompletingATaskPaysItsRewardOnce() {
        var s = fresh(on: day1)
        let task = s.tasks.first { $0.kind == .life }!
        XCTAssertEqual(s.complete(taskID: task.id, reward: task.reward), task.reward)
        XCTAssertEqual(s.complete(taskID: task.id, reward: task.reward), 0, "a second tap pays nothing")
        XCTAssertEqual(s.ledger.balance, task.reward)
        XCTAssertTrue(s.tasks.first { $0.id == task.id }!.done)
    }

    func testUnCheckingPutsTheBalanceBackExactly() {
        var s = fresh(on: day1)
        let task = s.tasks.first!
        s.complete(taskID: task.id, reward: task.reward)
        s.uncomplete(taskID: task.id)
        XCTAssertEqual(s.ledger.balance, 0)
        XCTAssertFalse(s.tasks.first { $0.id == task.id }!.done)
    }

    func testANewDayClearsEveryCheckmark() {
        var s = fresh(on: day1)
        for t in s.tasks { s.complete(taskID: t.id, reward: t.reward) }
        XCTAssertTrue(s.allDone)
        let earned = s.ledger.balance

        s.advance(to: day2)
        XCTAssertFalse(s.allDone, "yesterday's checkmarks must not carry over")
        XCTAssertTrue(s.tasks.allSatisfy { !$0.done })
        XCTAssertEqual(s.ledger.balance, earned, "and the coins stay earned")
    }

    func testTheSameTaskPaysAgainOnTheNextDay() {
        var s = fresh(on: day1)
        let task = s.tasks.first!
        s.complete(taskID: task.id, reward: task.reward)
        s.advance(to: day2)
        XCTAssertEqual(s.complete(taskID: task.id, reward: task.reward), task.reward)
        XCTAssertEqual(s.ledger.balance, task.reward * 2)
    }

    // MARK: - Clock

    func testWindingTheClockBackCannotReopenAPaidDay() {
        var s = fresh(on: day1)
        s.advance(to: day2)
        let task = s.tasks.first!
        s.complete(taskID: task.id, reward: task.reward)
        let afterHonestPlay = s.ledger.balance

        s.advance(to: day1)   // the user sets the device date back a day
        XCTAssertEqual(s.effectiveDay, day2, "rewards stay keyed to the furthest day reached")
        XCTAssertEqual(s.complete(taskID: task.id, reward: task.reward), 0)
        XCTAssertEqual(s.ledger.balance, afterHonestPlay)
    }

    func testTheDailyWordPaysOncePerDayNoMatterTheClock() {
        var s = fresh(on: day1)
        XCTAssertEqual(s.recordWordleWin(), 30)
        XCTAssertEqual(s.recordWordleWin(), 0)
        s.advance(to: day1)   // no real day change
        XCTAssertEqual(s.recordWordleWin(), 0)
        s.advance(to: day2)
        XCTAssertEqual(s.recordWordleWin(), 30)
    }

    // MARK: - Templates

    func testAOneOffRetiresAfterTheDayItIsFinished() {
        var s = fresh(on: day1)
        s.addTask(title: "Finish lab report", kind: .study, recurrence: .once, id: "lab")
        let id = "u-lab"
        XCTAssertTrue(s.tasks.contains { $0.id == id })
        s.complete(taskID: id, reward: TaskKind.study.reward)

        s.advance(to: day2)
        XCTAssertFalse(s.tasks.contains { $0.id == id }, "a finished one-off should not come back")
    }

    func testAFinishedOneOffRetiresEvenIfTheClockWasRolledBack() {
        var s = fresh(on: day1)
        s.advance(to: day2)
        s.advance(to: day1)   // clock set back; rewards stay keyed to day2
        s.addTask(title: "Finish lab report", kind: .study, recurrence: .once, id: "lab")
        s.complete(taskID: "u-lab", reward: TaskKind.study.reward)

        s.advance(to: DayKey(raw: "2026-08-31"))
        XCTAssertFalse(s.tasks.contains { $0.id == "u-lab" },
                       "a paid one-off must retire no matter which day its pay was keyed to")
    }

    func testAnUnfinishedOneOffStaysOnTheList() {
        var s = fresh(on: day1)
        s.addTask(title: "Call the dentist", kind: .life, recurrence: .once, id: "dentist")
        s.advance(to: day2)
        XCTAssertTrue(s.tasks.contains { $0.id == "u-dentist" })
    }

    func testSwitchingOffAPresetTakesItOffTodaysList() {
        var s = fresh(on: day1)
        let preset = s.templates.first { $0.isPreset && $0.isActive }!
        s.setTemplate(preset.id, active: false)
        XCTAssertFalse(s.tasks.contains { $0.id == preset.id })
        s.setTemplate(preset.id, active: true)
        XCTAssertTrue(s.tasks.contains { $0.id == preset.id })
    }

    func testPresetsCannotBeDeleted() {
        var s = fresh(on: day1)
        let preset = s.templates.first { $0.isPreset }!
        s.deleteTask(preset.id)
        XCTAssertTrue(s.templates.contains { $0.id == preset.id })
    }

    func testBlankTaskTitlesAreIgnored() {
        var s = fresh(on: day1)
        let before = s.templates.count
        s.addTask(title: "   ", kind: .study, recurrence: .daily)
        XCTAssertEqual(s.templates.count, before)
    }

    // MARK: - Spending

    func testYouCannotBuyWhatYouCannotAfford() {
        var s = fresh(on: day1)
        let ember = ChibiSpecies.catalog.first { $0.id == "ember" }!
        XCTAssertFalse(s.buy(ember))
        XCTAssertEqual(s.owned.count, 1)
    }

    func testBuyingTwiceIsNotPossible() {
        var s = fresh(on: day1)
        s.recordFocus(minutes: 400, sessionID: "seed")
        let ember = ChibiSpecies.catalog.first { $0.id == "ember" }!
        XCTAssertTrue(s.buy(ember))
        XCTAssertFalse(s.buy(ember))
        XCTAssertEqual(s.ledger.balance, 100)
    }

    func testUpgradingWalksTheLevelsAndChargesOnce() {
        var s = fresh(on: day1)
        s.recordFocus(minutes: 400, sessionID: "seed")
        XCTAssertTrue(s.upgradeActiveChibi())      // 100
        XCTAssertEqual(s.activeChibi.level, 2)
        XCTAssertTrue(s.upgradeActiveChibi())      // 250
        XCTAssertEqual(s.activeChibi.level, 3)
        XCTAssertFalse(s.upgradeActiveChibi(), "level 3 is the top")
        XCTAssertEqual(s.ledger.balance, 50)
    }

    func testFinishingALessonPaysOnceEver() {
        var s = fresh(on: day1)
        XCTAssertEqual(s.completeLesson(id: "fin-1", reward: 20), 20)
        s.advance(to: day2)
        XCTAssertEqual(s.completeLesson(id: "fin-1", reward: 20), 0)
        XCTAssertTrue(s.completedLessons.contains("fin-1"))
    }

    // MARK: - Canvas

    func testCanvasTasksSortByDueDateAndComeFirst() {
        var s = fresh(on: day1)
        let now = Date()
        s.applyCanvas(CanvasSnapshot(tasks: [
            CanvasItem(id: "c-2", title: "Later", courseName: "Math", dueAt: now.addingTimeInterval(7200)),
            CanvasItem(id: "c-1", title: "Sooner", courseName: "Math", dueAt: now.addingTimeInterval(600)),
        ]))
        XCTAssertEqual(s.tasks.first?.id, "c-1")
        XCTAssertEqual(s.tasks[1].id, "c-2")
    }

    func testResyncingCanvasKeepsWhatWasAlreadyCheckedOff() {
        var s = fresh(on: day1)
        let item = CanvasItem(id: "c-1", title: "Problem set", courseName: "Physics", dueAt: nil)
        s.applyCanvas(CanvasSnapshot(tasks: [item]))
        s.complete(taskID: "c-1", reward: TaskKind.canvas.reward)
        s.applyCanvas(CanvasSnapshot(tasks: [item]))   // a later sync returns the same item
        XCTAssertTrue(s.tasks.first { $0.id == "c-1" }!.done)
        XCTAssertEqual(s.ledger.balance, TaskKind.canvas.reward)
    }

    func testASubmittedItemDoesNotPayAgainAfterADayRollover() {
        var s = fresh(on: day1)
        var item = CanvasItem(id: "c-1", title: "Problem set", courseName: "Physics", dueAt: nil)
        item.submittedAt = Date()
        s.applyCanvas(CanvasSnapshot(tasks: [item]))
        XCTAssertEqual(s.ledger.balance, TaskKind.canvas.reward)

        s.advance(to: day2)
        s.applyCanvas(CanvasSnapshot(tasks: [item]))   // the extension still lists it for a few days
        XCTAssertEqual(s.ledger.balance, TaskKind.canvas.reward,
                       "an assignment is handed in once; it cannot pay again tomorrow")
    }

    func testACheckedOffAssignmentStaysDoneTomorrow() {
        var s = fresh(on: day1)
        let item = CanvasItem(id: "c-1", title: "Problem set", courseName: "Physics", dueAt: nil)
        s.applyCanvas(CanvasSnapshot(tasks: [item]))
        s.complete(taskID: "c-1", reward: TaskKind.canvas.reward)

        s.advance(to: day2)
        s.applyCanvas(CanvasSnapshot(tasks: [item]))   // still unsubmitted, still in the feed
        XCTAssertTrue(s.tasks.first { $0.id == "c-1" }!.done,
                      "an assignment is not a daily habit; done stays done")
        XCTAssertEqual(s.complete(taskID: "c-1", reward: TaskKind.canvas.reward), 0)
        XCTAssertEqual(s.ledger.balance, TaskKind.canvas.reward)
    }

    func testTheDailyWordCanPayForTheDayTheGameStarted() {
        var s = fresh(on: day1)
        s.advance(to: day2)   // midnight passed while the puzzle was open
        XCTAssertEqual(s.recordWordleWin(day: day1), 30, "the solve pays under the day it was dealt")
        XCTAssertFalse(s.wordleClaimedToday, "today's word is still unplayed")
        XCTAssertEqual(s.recordWordleWin(day: day1), 0)
        XCTAssertEqual(s.recordWordleWin(), 30)
    }
}

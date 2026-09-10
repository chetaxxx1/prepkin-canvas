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

    func testCanvasCopiesOfTheSameQuizCollapseToOneRow() {
        var s = fresh(on: day1)
        let now = Date()
        s.applyCanvas(CanvasSnapshot(tasks: [
            CanvasItem(id: "c-1", title: "Safety Quiz", courseName: "Orientation", dueAt: nil),
            CanvasItem(id: "c-2", title: "Safety Quiz", courseName: "Orientation", dueAt: nil),
            CanvasItem(id: "c-3", title: "Safety Quiz", courseName: "Orientation", dueAt: nil),
            // Same title, different week: a real second piece of work.
            CanvasItem(id: "c-4", title: "Weekly Quiz", courseName: "Math", dueAt: now),
            CanvasItem(id: "c-5", title: "Weekly Quiz", courseName: "Math", dueAt: now.addingTimeInterval(604_800)),
        ]))
        XCTAssertEqual(s.tasks.filter { $0.kind == .canvas }.map(\.id), ["c-4", "c-5", "c-1"])
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

// MARK: - Learn v2

/// Deck progress, saved cards, and the rule that finishing pays but reading again
/// does not.
final class LearnStateTests: XCTestCase {
    func testProgressOnlyMovesForward() {
        var s = GameState()
        s.setDeckProgress("fin-1", card: 4)
        s.setDeckProgress("fin-1", card: 2)
        XCTAssertEqual(s.deckProgress("fin-1"), 4)
    }

    /// Being on the first card is not "in progress" — Continue must not offer a deck
    /// the student only glanced at.
    func testCardZeroIsNotProgress() {
        var s = GameState()
        s.setDeckProgress("fin-1", card: 3)
        s.setDeckProgress("fin-1", card: 0)
        XCTAssertEqual(s.deckProgress("fin-1"), 0)
        XCTAssertNil(s.deckProgress["fin-1"])
    }

    func testFinishingClearsProgressSoContinueStopsOfferingIt() {
        var s = GameState()
        s.setDeckProgress("fin-1", card: 5)
        s.completeLesson(id: "fin-1", reward: 20)
        XCTAssertNil(s.deckProgress["fin-1"])
        XCTAssertTrue(s.completedLessons.contains("fin-1"))
    }

    func testALessonPaysOnceEver() {
        var s = GameState()
        XCTAssertEqual(s.completeLesson(id: "fin-1", reward: 20), 20)
        XCTAssertEqual(s.completeLesson(id: "fin-1", reward: 20), 0)
        XCTAssertEqual(s.ledger.balance, 20)
    }

    /// A re-read still counts as done, so the map doesn't un-tick a finished node.
    func testRereadingKeepsTheLessonCompleted() {
        var s = GameState()
        s.completeLesson(id: "fin-1", reward: 20)
        s.completeLesson(id: "fin-1", reward: 20)
        XCTAssertTrue(s.completedLessons.contains("fin-1"))
    }

    func testHeartingIsAToggleAndNewestIsFirst() {
        var s = GameState()
        XCTAssertTrue(s.toggleSaved(lessonID: "fin-1", index: 2))
        XCTAssertTrue(s.toggleSaved(lessonID: "fin-1", index: 6))
        XCTAssertEqual(s.savedCards.first?.index, 6)
        XCTAssertTrue(s.isSaved(lessonID: "fin-1", index: 2))

        XCTAssertFalse(s.toggleSaved(lessonID: "fin-1", index: 2))
        XCTAssertFalse(s.isSaved(lessonID: "fin-1", index: 2))
        XCTAssertEqual(s.savedCards.count, 1)
    }

    func testFlaggingACardKeepsEveryReportNewestFirst() {
        var s = GameState()
        s.reportCard(lessonID: "fin-1", index: 2, reason: .typo)
        s.reportCard(lessonID: "fin-1", index: 2, reason: .wrong)
        XCTAssertEqual(s.cardReports.count, 2)
        XCTAssertEqual(s.cardReports.first?.reason, .wrong)
        XCTAssertEqual(s.cardReports.first?.cardIndex, 2)
    }

    func testLessonsThisMonthCountsOnlyLessons() {
        var s = GameState()
        s.completeLesson(id: "fin-1", reward: 20)
        s.completeLesson(id: "fin-2", reward: 20)
        s.recordFocus(minutes: 20)
        XCTAssertEqual(s.lessonsThisMonth(), 2)
    }

    func testLastMonthsLessonsDoNotCount() {
        var s = GameState()
        let old = Calendar.current.date(byAdding: .day, value: -45, to: Date())!
        s.completeLesson(id: "fin-1", reward: 20, now: old)
        XCTAssertEqual(s.lessonsThisMonth(), 0)
    }

    /// Everything Learn keeps has to survive a relaunch.
    func testLearnStateRoundTripsThroughTheSaveFile() throws {
        var s = GameState()
        s.setDeckProgress("fin-1", card: 3)
        s.toggleSaved(lessonID: "fin-1", index: 6)
        s.reportCard(lessonID: "fin-1", index: 4, reason: .other)
        s.hasSeenTapCoach = true

        let data = try Store.encoder.encode(s)
        let back = try Store.decoder.decode(GameState.self, from: data)
        XCTAssertEqual(back.deckProgress("fin-1"), 3)
        XCTAssertTrue(back.isSaved(lessonID: "fin-1", index: 6))
        XCTAssertEqual(back.cardReports.first?.reason, .other)
        XCTAssertTrue(back.hasSeenTapCoach)
    }

    /// A save written before Learn v2 has none of these keys and must still load.
    func testASaveWithoutLearnKeysStillLoads() throws {
        let json = #"{"activeChibiID": "slime", "sceneID": "dorm"}"#.data(using: .utf8)!
        let s = try Store.decoder.decode(GameState.self, from: json)
        XCTAssertTrue(s.savedCards.isEmpty)
        XCTAssertFalse(s.hasSeenTapCoach)
        XCTAssertEqual(s.deckProgress("fin-1"), 0)
    }

    // MARK: - Friends

    /// The tab must never invent people. A fresh state has no friends and no code
    /// of its own — both arrive from the bridge or not at all.
    func testFriendsStartEmptyAndTheWholeRowRoundTrips() throws {
        var s = GameState()
        XCTAssertTrue(s.friends.isEmpty)
        XCTAssertNil(s.friendCode)

        let now = Date(timeIntervalSince1970: 1_757_000_000)
        s.addFriend(Friend(id: "abc", adjective: 2, noun: 5, speciesID: "ember",
                           lookID: "classic", costumeID: "none", sceneID: "reef",
                           level: 3, tier: .kelp, friendsSince: now,
                           onShiftUntil: now.addingTimeInterval(600)), now: now)
        s.setNickname("Maya", for: "abc")

        let back = try Store.decoder.decode(GameState.self, from: Store.encoder.encode(s))
        let f = try XCTUnwrap(back.friends.first)
        XCTAssertEqual(f.displayName, "Maya")
        XCTAssertEqual(f.speciesID, "ember")
        XCTAssertEqual(f.tier, .kelp)
        XCTAssertEqual(f.seenAt.timeIntervalSince1970, now.timeIntervalSince1970, accuracy: 1)
        XCTAssertNotNil(f.onShiftUntil)

        s.dropFriend("abc")
        XCTAssertTrue(s.friends.isEmpty)
    }

    // MARK: - First run

    /// A fresh install starts at the first run; a save from before the first run
    /// existed belongs to someone already using the app and skips it.
    func testFirstRunIsOnlyForFreshInstalls() throws {
        XCTAssertFalse(GameState().firstRunDone)
        XCTAssertFalse(GameState().firstRunOffersDone)

        let old = #"{"activeChibiID": "slime", "sceneID": "dorm"}"#.data(using: .utf8)!
        let existing = try Store.decoder.decode(GameState.self, from: old)
        XCTAssertTrue(existing.firstRunDone)
        XCTAssertTrue(existing.firstRunOffersDone)

        var fresh = GameState()
        fresh.firstRunDone = true
        let back = try Store.decoder.decode(GameState.self, from: Store.encoder.encode(fresh))
        XCTAssertTrue(back.firstRunDone)
        XCTAssertFalse(back.firstRunOffersDone)
    }
}

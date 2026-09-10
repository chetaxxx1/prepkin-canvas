import XCTest
@testable import PrepkinCanvas

/// Home's header and its Tomorrow line. Everything here is a pure string
/// decision, so none of it needs a view or a simulator.
final class HomeTests: XCTestCase {

    // MARK: - The words beside the star pips
    //
    // There is no bar any more, so these words are the whole answer at every
    // stage. None of them may repeat the count the pips already draw.

    func testStarTextAtOneStar() {
        XCTAssertEqual(HomeCopy.levelLabel(nextUpgradeCost: 150, coins: 110), "40 to the next")
    }

    func testStarTextAtTwoStars() {
        XCTAssertEqual(HomeCopy.levelLabel(nextUpgradeCost: 400, coins: 360), "40 to the next")
    }

    func testStarTextWhenTheNextStarIsAffordable() {
        XCTAssertEqual(HomeCopy.levelLabel(nextUpgradeCost: 150, coins: 150), "Ready for the next star")
        XCTAssertEqual(HomeCopy.levelLabel(nextUpgradeCost: 150, coins: 900), "Ready for the next star")
    }

    func testStarTextAtThreeStars() {
        XCTAssertEqual(HomeCopy.levelLabel(nextUpgradeCost: nil, coins: 0), "Fully grown")
        XCTAssertEqual(HomeCopy.levelLabel(nextUpgradeCost: nil, coins: 99_000), "Fully grown")
    }

    func testStarTextNeverRepeatsTheStarCount() {
        for cost in [nil, 150, 400] as [Int?] {
            let label = HomeCopy.levelLabel(nextUpgradeCost: cost, coins: 0)
            XCTAssertFalse(label.lowercased().contains("star"),
                           "the pips draw the count; \"\(label)\" says it twice")
        }
    }

    // MARK: - The quiet line under the goals row

    func testNothingDueAndNoLaptopSaysNothing() {
        // The goals row already reads "Nothing due today". A second copy of that
        // sentence is worse than the blank space it would fill.
        XCTAssertNil(HomeCopy.underGoals(hasTasks: false, lastList: nil))
    }

    func testNothingDueWithALaptopNamesTheList() {
        let line = HomeCopy.underGoals(hasTasks: false, lastList: Date().addingTimeInterval(-7200))
        XCTAssertEqual(line, "Last list from your laptop 2h ago.")
    }

    func testNothingDueSaysSoEvenWhenTheListIsMinutesOld() {
        let line = HomeCopy.underGoals(hasTasks: false, lastList: Date().addingTimeInterval(-120))
        XCTAssertNotNil(line, "an empty day still owes the student a reason")
        XCTAssertTrue(line!.hasPrefix("Last list from your laptop"))
    }

    func testFreshListUnderAFullDayIsSilent() {
        // Under an hour it is just today's list. Saying so is noise.
        XCTAssertNil(HomeCopy.underGoals(hasTasks: true, lastList: Date().addingTimeInterval(-600)))
    }

    func testStaleListUnderAFullDaySaysItsAge() {
        let line = HomeCopy.underGoals(hasTasks: true, lastList: Date().addingTimeInterval(-7200))
        XCTAssertEqual(line, "From your laptop 2h ago.")
    }

    func testNoLaptopUnderAFullDayIsSilent() {
        XCTAssertNil(HomeCopy.underGoals(hasTasks: true, lastList: nil))
    }

    func testTheQuietLineNeverSaysSync() {
        let lines = [
            HomeCopy.underGoals(hasTasks: false, lastList: Date().addingTimeInterval(-7200)),
            HomeCopy.underGoals(hasTasks: true, lastList: Date().addingTimeInterval(-7200)),
        ].compactMap { $0 }
        XCTAssertEqual(lines.count, 2)
        for line in lines {
            XCTAssertFalse(line.lowercased().contains("sync"))
            XCTAssertFalse(line.contains("!"))
        }
    }

    // MARK: - Tomorrow

    /// `DatedTask` puts its own "d-" on the front of the id it is handed, so the
    /// ids these come back under are "d-0", "d-1", …
    private func state(datedTomorrow titles: [String], done: [String] = []) -> GameState {
        var g = GameState()
        let tomorrow = g.effectiveDay.adding(days: 1)
        for (i, title) in titles.enumerated() {
            g.addDated(DatedTask(id: "\(i)", title: title, kind: .study, day: tomorrow))
        }
        for id in done {
            g.complete(taskID: id, reward: TaskKind.study.reward)
        }
        return g
    }

    func testTomorrowIsAbsentWhenTomorrowIsEmpty() {
        XCTAssertNil(GameState().tomorrowLine(), "\"nothing tomorrow\" is not news")
    }

    func testTomorrowWithOneItem() {
        XCTAssertEqual(state(datedTomorrow: ["Bio quiz"]).tomorrowLine(), "Tomorrow: Bio quiz")
    }

    func testTomorrowWithTwoItemsNamesBoth() {
        XCTAssertEqual(state(datedTomorrow: ["Bio quiz", "Essay outline"]).tomorrowLine(),
                       "Tomorrow: Bio quiz, Essay outline")
    }

    func testTomorrowWithFourItemsNamesTwoThenCountsTheRest() {
        let g = state(datedTomorrow: ["Bio quiz", "Essay outline", "Lab report", "Reading"])
        XCTAssertEqual(g.tomorrowLine(), "Tomorrow: Bio quiz, Essay outline and 2 more")
    }

    func testTomorrowWithThreeItemsSaysAndOneMore() {
        let g = state(datedTomorrow: ["Bio quiz", "Essay outline", "Lab report"])
        XCTAssertEqual(g.tomorrowLine(), "Tomorrow: Bio quiz, Essay outline and 1 more")
    }

    func testTomorrowLeavesOutWhatIsAlreadyFinished() {
        let g = state(datedTomorrow: ["Bio quiz", "Essay outline"], done: ["d-0"])
        XCTAssertEqual(g.tomorrowLine(), "Tomorrow: Essay outline",
                       "a task finished early is not still coming")
    }

    func testTomorrowReadsCanvasWorkDueTomorrow() {
        var g = GameState()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        g.canvasItems = [
            CanvasItem(id: "c-1", title: "Ch. 5 Problem Set", courseName: "Physics 13", dueAt: tomorrow),
        ]
        XCTAssertEqual(g.tomorrowLine(), "Tomorrow: Ch. 5 Problem Set")
    }

    func testTomorrowLeavesOutTheDailyHabits() {
        // Every habit is on every tomorrow there will ever be, so listing them
        // would make the line say the same thing forever.
        var g = GameState()
        g.templates = TaskTemplate.presets
        XCTAssertNil(g.tomorrowLine())
    }
}

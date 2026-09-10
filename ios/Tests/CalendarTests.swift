import XCTest
@testable import PrepkinCanvas

/// Dated tasks, the per-day calendar list, and course events.
/// design/CALENDAR-PLAN.md.
final class CalendarTests: XCTestCase {
    private let day1 = DayKey(raw: "2026-09-09")
    private let day2 = DayKey(raw: "2026-09-10")
    private let day3 = DayKey(raw: "2026-09-11")

    private func fresh(on day: DayKey) -> GameState {
        var s = GameState()
        s.currentDay = day
        s.maxDayReached = day
        return s
    }

    private func quiz(on day: DayKey, id: String = "q1") -> DatedTask {
        DatedTask(id: id, title: "Bio quiz ch 3-4", kind: .study, source: .mine, day: day)
    }

    // MARK: - Dated tasks

    func testADatedTaskShowsOnItsDayAndNotTheDayBefore() {
        var s = fresh(on: day1)
        s.addDated(quiz(on: day2))
        XCTAssertEqual(s.tasks(on: day2).map(\.title), ["Bio quiz ch 3-4"])
        XCTAssertTrue(s.tasks(on: day1).isEmpty)
        XCTAssertTrue(s.tasks(on: day3).isEmpty)
    }

    func testTodaysListPicksUpADatedTaskDueToday() {
        var s = fresh(on: day1)
        s.addDated(quiz(on: day1))
        XCTAssertTrue(s.tasks.contains { $0.id == "d-q1" && $0.isDated })
    }

    func testAnOverdueOpenDatedTaskStaysOnTodayUntilItIsDone() {
        var s = fresh(on: day2)
        s.addDated(quiz(on: day1))
        XCTAssertTrue(s.tasks.contains { $0.id == "d-q1" }, "yesterday's quiz is still owed")
        s.complete(taskID: "d-q1", reward: TaskKind.study.reward)
        XCTAssertFalse(s.tasks.contains { $0.id == "d-q1" }, "finished, it stays on its own day")
        XCTAssertTrue(s.tasks(on: day1).first { $0.id == "d-q1" }!.done)
    }

    func testFinishingADatedTaskPaysOnceEver() {
        var s = fresh(on: day1)
        s.addDated(quiz(on: day1))
        XCTAssertEqual(s.complete(taskID: "d-q1", reward: 20), 20)
        XCTAssertEqual(s.complete(taskID: "d-q1", reward: 20), 0)
        s.advance(to: day2)
        XCTAssertEqual(s.complete(taskID: "d-q1", reward: 20), 0, "a new day does not reopen it")
        XCTAssertEqual(s.ledger.balance, 20)
        XCTAssertEqual(s.lifetime.tasksFinished, 1)
    }

    func testUncheckingADatedTaskTakesTheCoinsBack() {
        var s = fresh(on: day1)
        s.addDated(quiz(on: day1))
        s.complete(taskID: "d-q1", reward: 20)
        s.uncomplete(taskID: "d-q1")
        XCTAssertEqual(s.ledger.balance, 0)
        XCTAssertFalse(s.isDatedDone("d-q1"))
        XCTAssertEqual(s.lifetime.tasksFinished, 0)
    }

    func testEditingMovesTheTaskAndDeletingKeepsTheCoins() {
        var s = fresh(on: day1)
        s.addDated(quiz(on: day1))
        var moved = s.datedTasks[0]
        moved.day = day3
        moved.minute = 14 * 60 + 30
        s.updateDated(moved)
        XCTAssertTrue(s.tasks(on: day1).isEmpty)
        XCTAssertEqual(s.tasks(on: day3).count, 1)
        s.complete(taskID: "d-q1", reward: 20)
        s.deleteDated("d-q1")
        XCTAssertTrue(s.datedTasks.isEmpty)
        XCTAssertEqual(s.ledger.balance, 20, "tidying the list is not a refund")
    }

    func testABlankTitleIsNotATask() {
        var s = fresh(on: day1)
        s.addDated(DatedTask(title: "   ", day: day1))
        XCTAssertTrue(s.datedTasks.isEmpty)
    }

    func testDeletingATemplateLeavesDatedTasksAlone() {
        var s = fresh(on: day1)
        s.addTask(title: "Read", kind: .study, recurrence: .daily, id: "t")
        s.addDated(quiz(on: day1))
        s.deleteTask("u-t")
        XCTAssertEqual(s.datedTasks.count, 1)
    }

    func testDailyTemplatesStayOffTheCalendar() {
        let s = fresh(on: day1)
        XCTAssertFalse(s.templates.isEmpty)
        XCTAssertTrue(s.tasks(on: day1).isEmpty, "habits are Home's, not the calendar's")
    }

    func testDatedTasksSurviveASaveAndLoad() throws {
        var s = fresh(on: day1)
        s.addDated(quiz(on: day2))
        let data = try JSONEncoder().encode(s)
        let back = try JSONDecoder().decode(GameState.self, from: data)
        XCTAssertEqual(back.datedTasks, s.datedTasks)
    }

    func testAnOldSaveWithoutDatedTasksStillLoads() throws {
        let back = try JSONDecoder().decode(GameState.self, from: Data(#"{"currentDay":"2026-09-09"}"#.utf8))
        XCTAssertTrue(back.datedTasks.isEmpty)
        XCTAssertTrue(back.canvasEvents.isEmpty)
    }

    // MARK: - Canvas on the calendar

    func testCanvasWorkSitsOnItsDueDayWithTheCourseColour() {
        var s = fresh(on: day1)
        let due = Calendar.current.date(bySettingHour: 23, minute: 59, second: 0, of: day2.date()!)!
        s.applyCanvas(CanvasSnapshot(
            tasks: [CanvasItem(id: "c-1", title: "Lab", courseName: "Physics", dueAt: due)],
            courses: [CanvasCourse(id: "1", name: "Physics", colorHex: "#FF6F61")]))
        let rows = s.tasks(on: day2)
        XCTAssertEqual(rows.map(\.id), ["c-1"])
        XCTAssertEqual(rows[0].colorHex, "#FF6F61")
        XCTAssertTrue(s.tasks(on: day1).isEmpty)
    }

    func testEventsLandOnTheirDayAndUnpairingClearsThem() {
        var s = fresh(on: day1)
        let start = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: day3.date()!)!
        s.applyCanvas(CanvasSnapshot(events: [
            CanvasEvent(id: "e-1", title: "Midterm", courseName: "Physics", startAt: start),
        ]))
        XCTAssertEqual(s.events(on: day3).map(\.title), ["Midterm"])
        XCTAssertTrue(s.events(on: day2).isEmpty)
        s.unpair()
        XCTAssertTrue(s.canvasEvents.isEmpty)
    }

    func testTheWireCarriesEventsAndAnOldPushWithoutThemIsFine() throws {
        let snap = try SupabaseCanvasClient.decode(Data("""
        {"tasks":[],"events":[
          {"id":"e-1","title":"Midterm 1","courseName":"Physics","startAt":"2026-09-11T13:00:00Z","endAt":"2026-09-11T15:00:00Z","allDay":false,"location":"Moore 202"},
          {"id":"e-2","title":"No start","courseName":"Physics"}
        ]}
        """.utf8))
        XCTAssertEqual(snap.events.count, 1, "an event with no start has no day to sit on")
        XCTAssertEqual(snap.events[0].location, "Moore 202")
        XCTAssertNotNil(snap.events[0].endAt)
        let old = try SupabaseCanvasClient.decode(Data(#"{"tasks":[]}"#.utf8))
        XCTAssertTrue(old.events.isEmpty)
    }

    // MARK: - Scan rows

    func testAScanRowBecomesADatedTaskOnlyWithARealDate() {
        let good = ScanRow(title: "Essay draft", date: "2026-09-22", time: "17:00", course: "Writing 5")
        let task = good.task(source: "From a photo")
        XCTAssertEqual(task?.day.raw, "2026-09-22")
        XCTAssertEqual(task?.minute, 17 * 60)
        XCTAssertEqual(task?.detail, "Writing 5")
        XCTAssertEqual(task?.source, .photo)
        XCTAssertNil(ScanRow(title: "No date", date: "soon").task(source: "From a photo"))
        XCTAssertNil(ScanRow(title: "Bad time", date: "2026-09-22", time: "25:99").minute)
    }

    func testAllDayDatedTasksAreDueAtTheEndOfTheDay() {
        let t = DatedTask(title: "Read", day: day1)
        let c = Calendar.current.dateComponents([.hour, .minute], from: t.dueAt()!)
        XCTAssertEqual(c.hour, 23)
        XCTAssertEqual(c.minute, 59)
        XCTAssertTrue(t.allDay)
    }
}

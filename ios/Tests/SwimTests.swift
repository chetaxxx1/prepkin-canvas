import XCTest
@testable import PrepkinCanvas

/// The swim: finish the list, the fish leaves; back at the check-in hour with a
/// find; paid once. No meter, no streak, no penalty for a day it stays home.
final class SwimTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    private func at(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        var c = DateComponents()
        c.year = 2026; c.month = 9; c.day = day; c.hour = hour; c.minute = minute
        return calendar.date(from: c)!
    }

    private func state(now: Date) -> GameState {
        var s = GameState()
        s.currentDay = DayKey(now, calendar: calendar)
        s.maxDayReached = s.currentDay
        s.lastOpenedAt = now
        s.installedAt = at(1, 9)
        s.settings.remindersEnabled = true
        return s
    }

    private func finishAll(_ s: inout GameState, now: Date) {
        for t in s.tasks where !t.done { s.complete(taskID: t.id, reward: t.reward, now: now) }
    }

    func testTheLastTickSendsTheFishOutUntilTheCheckInHour() {
        let now = at(9, 16, 40)
        var s = state(now: now)
        XCTAssertNil(s.swim)
        let open = s.tasks
        for t in open.dropLast() { s.complete(taskID: t.id, reward: t.reward, now: now) }
        XCTAssertNil(s.swim, "not until the list is clear")
        s.complete(taskID: open.last!.id, reward: open.last!.reward, now: now)
        let swim = try! XCTUnwrap(s.swim)
        XCTAssertEqual(swim.returnsAt, at(9, 19))
        XCTAssertTrue(swim.isAway(at: at(9, 18)))
        XCTAssertTrue(swim.isBack(at: at(9, 19)))
        XCTAssertFalse(swim.collected)
    }

    func testFinishedLateItIsBackInTwoHours() {
        let now = at(9, 21, 15)
        var s = state(now: now)
        finishAll(&s, now: now)
        XCTAssertEqual(s.swim?.returnsAt, at(9, 23, 15))
        // Too close to the hour counts as late too.
        let close = at(9, 18, 45)
        var t = state(now: close)
        finishAll(&t, now: close)
        XCTAssertEqual(t.swim?.returnsAt, at(9, 20, 45))
    }

    func testOnceADayAndNeverRestartedByAnUnTick() {
        let now = at(9, 10)
        var s = state(now: now)
        finishAll(&s, now: now)
        let first = s.swim
        let task = s.tasks[0]
        s.uncomplete(taskID: task.id)
        XCTAssertEqual(s.swim, first, "an un-tick does not call it home")
        s.complete(taskID: task.id, reward: task.reward, now: at(9, 11))
        XCTAssertEqual(s.swim, first, "a re-tick does not send it out again")
        // Tomorrow is a new day and a new swim.
        s.advance(to: DayKey(at(10, 9), calendar: calendar))
        finishAll(&s, now: at(10, 9))
        XCTAssertEqual(s.swim?.day, DayKey(at(10, 9), calendar: calendar))
    }

    func testTheFindPaysOnceAndLandsOnTheCard() {
        let now = at(9, 10)
        var s = state(now: now)
        finishAll(&s, now: now)
        let before = s.ledger.balance
        XCTAssertNil(s.collectSwim(now: at(9, 18)), "not back yet")
        let find = s.collectSwim(now: at(9, 19))
        XCTAssertNotNil(find)
        XCTAssertEqual(s.ledger.balance, before + Swim.coins)
        XCTAssertEqual(s.finds.map(\.findID), [find!.findID])
        XCTAssertNil(s.collectSwim(now: at(9, 20)), "paid once")
        XCTAssertEqual(s.ledger.balance, before + Swim.coins)
        XCTAssertEqual(s.finds.count, 1)
    }

    func testTheFindIsTheSameAllDayAndDrawnFromThePool() {
        let a = Find.draw(day: DayKey(raw: "2026-09-09"), seed: 7)
        let b = Find.draw(day: DayKey(raw: "2026-09-09"), seed: 7)
        let c = Find.draw(day: DayKey(raw: "2026-09-10"), seed: 7)
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
        XCTAssertTrue(Find.pool.contains(a))
    }

    // MARK: - The widget

    private func snap(_ s: GameState, now: Date) -> WidgetSnapshot {
        WidgetSnapshot.make(from: s, shift: nil, now: now)
    }

    func testTheWidgetShowsAnEmptyTankThenTheReturn() {
        let now = at(9, 16, 40)
        var s = state(now: now)
        finishAll(&s, now: now)
        let snap = snap(s, now: now)
        let seven = at(9, 19).formatted(.dateTime.hour().minute())
        let away = WidgetLine.tile(for: snap, now: at(9, 17), calendar: calendar)
        XCTAssertEqual(away.head, "Out swimming")
        XCTAssertEqual(away.sub, "back at \(seven)")
        XCTAssertTrue(snap.swimAway(at: at(9, 17)))
        XCTAssertEqual(WidgetLine.count(for: snap, now: at(9, 17), calendar: calendar), "Out swimming")
        let back = WidgetLine.tile(for: snap, now: at(9, 19, 5), calendar: calendar)
        XCTAssertEqual(back.head, "Moss is back")
        XCTAssertEqual(back.sub, "found \(s.swim!.find.name)")
        XCTAssertFalse(snap.swimAway(at: at(9, 19, 5)))
        XCTAssertTrue(snap.swimBack(at: at(9, 19, 5)))
        // Paid: the tile is the list again.
        s.collectSwim(now: at(9, 19, 5))
        let paid = WidgetLine.tile(for: self.snap(s, now: at(9, 19, 6)), now: at(9, 19, 6), calendar: calendar)
        XCTAssertEqual(paid.head, "All done")
        // The return is a moment on the timeline.
        XCTAssertTrue(WidgetLine.timelineDates(for: snap, now: at(9, 17), calendar: calendar).contains(at(9, 19)))
    }

    func testALongNameSaysBackHome() {
        XCTAssertEqual(WidgetLine.backHead("Moss"), "Moss is back")
        XCTAssertEqual(WidgetLine.backHead("Bartholomew"), "Back home")
        for f in Find.pool {
            XCTAssertLessThan("found \(f.name)".count, WidgetLine.maxLength)
            XCTAssertLessThan("Found \(f.name). \(Swim.coins) coins are waiting.".count, 60)
        }
    }

    // MARK: - The note

    func testTheCheckInBecomesTheReturn() {
        let now = at(9, 16, 40)
        var s = state(now: now)
        finishAll(&s, now: now)
        let plan = NotificationPlanner.plan(for: s, now: now, calendar: calendar)
        let tonight = plan.first { $0.id == "nudge:2026-09-09" }
        XCTAssertEqual(tonight?.title, "Moss is back")
        XCTAssertEqual(tonight?.fireAt, at(9, 19))
        XCTAssertEqual(tonight?.body, "Found \(s.swim!.find.name). \(Swim.coins) coins are waiting.")
        XCTAssertEqual(plan.filter { $0.id.hasPrefix("nudge:2026-09-09") }.count, 1, "one a day")
        XCTAssertTrue(plan.contains { $0.id == "nudge:2026-09-10" }, "tomorrow's check-in still queued")
    }

    func testAReturnAfterTenIsNotANote() {
        let now = at(9, 21, 30)
        var s = state(now: now)
        finishAll(&s, now: now)
        XCTAssertEqual(s.swim?.returnsAt, at(9, 23, 30))
        let plan = NotificationPlanner.plan(for: s, now: now, calendar: calendar)
        XCTAssertFalse(plan.contains { $0.id == "nudge:2026-09-09" })
    }
}

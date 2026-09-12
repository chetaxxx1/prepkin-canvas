import XCTest
@testable import PrepkinCanvas

/// The weekly board, held to the promises the rest of the app makes: a day is
/// capped so one big day cannot buy a week, ties share a place, nothing on the
/// shelf ever goes down, and a win on the board can only ever move a tier up.
final class WeekBoardTests: XCTestCase {

    /// 2026-08-31 is a Monday.
    private let week = WeekKey(DayKey(raw: "2026-08-31"))

    private func member(_ id: String, _ points: Int, you: Bool = false,
                        counts: TodayCounts = TodayCounts()) -> BoardMember {
        BoardMember(id: id, name: id.capitalized, speciesID: "sprout", lookID: "classic",
                    level: 2, points: points, counts: counts, isYou: you, onShiftUntil: nil)
    }

    private func friend(_ id: String) -> Friend {
        Friend(id: id, adjective: 0, noun: 0, speciesID: "sprout", lookID: "classic",
               costumeID: "none", sceneID: "lagoon", level: 2, tier: .tidepool,
               friendsSince: Date(), onShiftUntil: nil)
    }

    // MARK: - The score

    func testAClosedRingIsAHundredAndAHalfRingIsHalf() {
        XCTAssertEqual(WeekPoints.ring(3, goal: 3), 100)
        XCTAssertEqual(WeekPoints.ring(1, goal: 3), 33)
        XCTAssertEqual(WeekPoints.ring(0, goal: 3), 0)
    }

    func testADayIsCappedAtFourHundred() {
        let huge = TodayCounts(tasks: 40, focusMinutes: 600, lessons: 9, games: 6)
        XCTAssertEqual(WeekPoints.day(huge), WeekPoints.dayMax,
                       "a forged or heroic day is worth exactly a full day, no more")
    }

    func testAFullDayIsFourRings() {
        let full = TodayCounts(tasks: 3, focusMinutes: 45, lessons: 1, games: 3)
        XCTAssertEqual(WeekPoints.day(full), 400)
        let light = TodayCounts(tasks: 1, focusMinutes: 25, lessons: 0, games: 1)
        XCTAssertEqual(WeekPoints.day(light), 33 + 55 + 0 + 33)
    }

    func testAWeekIsScoredDayByDayNotAsOneHeap() {
        let sunday = [TodayCounts(tasks: 21)]
        let spread = Array(repeating: TodayCounts(tasks: 3), count: 7)
        XCTAssertEqual(WeekPoints.week(sunday), 100, "twenty-one tasks on Sunday close one ring")
        XCTAssertEqual(WeekPoints.week(spread), 700, "three a day for a week closes seven")
    }

    // MARK: - The week's days

    func testAWeekHasSevenDaysMondayFirst() {
        let days = week.days()
        XCTAssertEqual(days.count, 7)
        XCTAssertEqual(days.first, DayKey(raw: "2026-08-31"))
        XCTAssertEqual(days.last, DayKey(raw: "2026-09-06"))
        XCTAssertTrue(days.allSatisfy { WeekKey($0) == week })
    }

    func testAMalformedWeekHasNoDays() {
        XCTAssertTrue(WeekKey(raw: "").days().isEmpty)
        XCTAssertTrue(WeekKey(raw: "nonsense").days().isEmpty)
    }

    // MARK: - Ranking

    func testTiesShareAPlaceAndTheNextPlaceSkips() {
        let rows = WeekBoard.rank([member("a", 610), member("b", 900), member("c", 610), member("d", 10)])
        XCTAssertEqual(rows.map(\.place), [1, 2, 2, 4])
        XCTAssertEqual(rows.map(\.id), ["b", "a", "c", "d"], "ties sort by name, so the order is stable")
    }

    func testABoardOfOneIsFirstOfOneAndNoMedal() {
        let rows = WeekBoard.rank([member("you", 0, you: true)])
        let p = WeekBoard.placement(of: rows)
        XCTAssertEqual(p, BoardPlacement(place: 1, of: 1))
        XCTAssertNil(p?.medal, "first of one is not a medal")
    }

    // MARK: - Who is on it

    func testOnlyFriendsWithARowInsideTheWeekAreOnTheBoard() {
        let rows = [
            DayRow(playerID: "maya", day: DayKey(raw: "2026-09-02"), counts: TodayCounts(tasks: 3)),
            DayRow(playerID: "maya", day: DayKey(raw: "2026-09-03"), counts: TodayCounts(tasks: 3)),
            // Last week's row does not count for this week.
            DayRow(playerID: "jun", day: DayKey(raw: "2026-08-30"), counts: TodayCounts(tasks: 9)),
        ]
        let split = WeekBoard.members(you: member("you", 150, you: true),
                                      friends: [friend("maya"), friend("jun"), friend("sam")],
                                      rows: rows, week: week)
        XCTAssertEqual(split.on.map(\.id), ["you", "maya"])
        XCTAssertEqual(split.on[1].points, 200, "two days of three tasks is two closed rings")
        XCTAssertEqual(split.off.map(\.id), ["jun", "sam"])
    }

    // MARK: - The shelf and the award

    private func settled(_ tier: LeagueTier = .tidepool, promoted: Bool = false) -> LeagueState {
        var s = LeagueState()
        s.tier = promoted ? (tier.next ?? tier) : tier
        s.history = [LeagueWeekResult(week: week, tier: tier, coinsEarned: 0, promoted: promoted)]
        return s
    }

    func testWinningAgainstThreeMovesYouUpAndCountsAGold() {
        var s = settled()
        XCTAssertTrue(s.award(BoardPlacement(place: 1, of: 3), for: week))
        XCTAssertEqual(s.tier, .shallows)
        XCTAssertTrue(s.pennants.contains(.shallows))
        XCTAssertEqual(s.weeksWon, 1)
        XCTAssertTrue(s.history[0].promoted)
    }

    func testWinningAgainstOneIsARaceNotAPromotion() {
        var s = settled()
        XCTAssertFalse(s.award(BoardPlacement(place: 1, of: 2), for: week))
        XCTAssertEqual(s.tier, .tidepool)
        XCTAssertEqual(s.weeksWon, 1, "the gold still counts")
    }

    func testAWeekTheBarAlreadyClearedGivesNothingMore() {
        var s = settled(promoted: true)
        XCTAssertFalse(s.award(BoardPlacement(place: 1, of: 5), for: week))
        XCTAssertEqual(s.tier, .shallows, "one step up, not two")
    }

    func testAnAwardIsCountedOnce() {
        var s = settled()
        s.award(BoardPlacement(place: 2, of: 4), for: week)
        s.award(BoardPlacement(place: 2, of: 4), for: week)
        s.award(BoardPlacement(place: 1, of: 4), for: week)
        XCTAssertEqual(s.weeksSecond, 1)
        XCTAssertEqual(s.weeksWon, 0, "the second fetch cannot rewrite the receipt")
        XCTAssertEqual(s.tier, .tidepool)
    }

    func testLastPlaceCountsNothingAndLowersNothing() {
        var s = settled(.reef)
        s.award(BoardPlacement(place: 9, of: 9), for: week)
        XCTAssertEqual(s.tier, .reef)
        XCTAssertEqual(s.weeksWon + s.weeksSecond + s.weeksThird, 0)
        XCTAssertEqual(s.history[0].placement?.place, 9)
    }

    func testAQuestIsCreditedOncePerWeek() {
        var s = LeagueState()
        XCTAssertTrue(s.creditQuest(week))
        XCTAssertFalse(s.creditQuest(week))
        XCTAssertEqual(s.questsCleared, 1)
        XCTAssertTrue(s.creditQuest(WeekKey(DayKey(raw: "2026-09-07"))))
        XCTAssertEqual(s.questsCleared, 2)
    }

    func testTheMondayCardShowsOnceForAPlacedWeek() {
        var s = settled()
        XCTAssertNil(s.unseenSettledWeek, "held, unplaced: nothing to say")
        s.award(BoardPlacement(place: 3, of: 4), for: week)
        XCTAssertEqual(s.unseenSettledWeek?.week, week)
        s.boardSeen = week
        XCTAssertNil(s.unseenSettledWeek)
    }

    func testTheMondayCardShowsForABarClearedAlone() {
        let s = settled(promoted: true)
        XCTAssertEqual(s.unseenSettledWeek?.week, week)
    }

    func testAnOldSaveOpensWithAnEmptyShelf() throws {
        let old = #"{"tier":2,"weekStart":"2026-W36","pennants":[1,2],"history":[{"week":"2026-W35","tier":1,"coinsEarned":320,"promoted":true}],"podOptIn":false}"#
        let s = try JSONDecoder().decode(LeagueState.self, from: Data(old.utf8))
        XCTAssertEqual(s.tier, .reef)
        XCTAssertEqual(s.weeksWon, 0)
        XCTAssertNil(s.history[0].placement)
        XCTAssertNil(s.boardSeen)
        XCTAssertEqual(s.unseenSettledWeek?.week, WeekKey(raw: "2026-W35"),
                       "a promotion the old app never announced gets its Monday card")
    }

    // MARK: - The quest

    func testTheQuestNeedsTwoPeopleAndScalesWithHeadcount() {
        XCTAssertNil(GroupQuest.status(week: week, members: [member("you", 0, you: true)]))
        let two = [member("you", 0, you: true, counts: TodayCounts(tasks: 7)),
                   member("maya", 0, counts: TodayCounts(tasks: 4))]
        let q = try! XCTUnwrap(GroupQuest.status(week: week, members: two))
        XCTAssertEqual(q.goal, GroupQuest.kind(for: week).perPerson * 2)
        XCTAssertEqual(q.headcount, 2)
    }

    func testTheKindRotatesWithTheWeekAndTwoPhonesAgree() {
        let a = GroupQuest.kind(for: WeekKey(raw: "2026-W36"))
        let b = GroupQuest.kind(for: WeekKey(raw: "2026-W37"))
        XCTAssertNotEqual(a, b)
        XCTAssertEqual(GroupQuest.kind(for: WeekKey(raw: "2026-W36")), a)
    }

    func testTheNudgeGoesToTheLowestContributorBelowYou() {
        let w = WeekKey(raw: "2026-W36")  // 36 % 4 == 0: tasks
        XCTAssertEqual(GroupQuest.kind(for: w), .tasks)
        let members = [member("you", 0, you: true, counts: TodayCounts(tasks: 8)),
                       member("maya", 0, counts: TodayCounts(tasks: 9)),
                       member("sam", 0, counts: TodayCounts(tasks: 2))]
        let q = try! XCTUnwrap(GroupQuest.status(week: w, members: members))
        XCTAssertEqual(GroupQuest.nudge(q, members: members)?.id, "sam")
        XCTAssertEqual(GroupQuest.line(q), "Finish 30 tasks between the three of you")
        XCTAssertEqual(GroupQuest.progressLine(q), "19 / 30")
    }

    func testNobodyIsNudgedWhenYouAreTheLowest() {
        let w = WeekKey(raw: "2026-W36")
        let members = [member("you", 0, you: true, counts: TodayCounts(tasks: 1)),
                       member("maya", 0, counts: TodayCounts(tasks: 9))]
        let q = try! XCTUnwrap(GroupQuest.status(week: w, members: members))
        XCTAssertNil(GroupQuest.nudge(q, members: members))
    }
}

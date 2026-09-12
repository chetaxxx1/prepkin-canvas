import XCTest
@testable import PrepkinCanvas

/// A race, held to the same promises as the board: one a week, nothing on the
/// bridge decides it, ahead or level keeps a pennant, and nobody loses anything.
final class RaceTests: XCTestCase {
    private let week = WeekKey(raw: "2026-W36")
    private let lastWeek = WeekKey(raw: "2026-W35")

    private func friend(_ id: String) -> Friend {
        Friend(id: id, adjective: 1, noun: 2, speciesID: "ember", lookID: "classic",
               costumeID: "none", sceneID: "reef", level: 2, tier: .reef,
               friendsSince: Date(timeIntervalSince1970: 1_757_000_000), onShiftUntil: nil)
    }

    private func pact(_ id: String, with other: String, week: WeekKey, mine: Bool, accepted: Bool,
                      declined: Bool = false) -> Pact {
        Pact(id: id, week: week, mine: mine, accepted: accepted, declined: declined, other: friend(other))
    }

    private func member(_ id: String, _ points: Int, you: Bool = false) -> BoardMember {
        BoardMember(id: id, name: id, speciesID: "sprout", lookID: "classic", level: 2,
                    points: points, counts: TodayCounts(), isYou: you, onShiftUntil: nil)
    }

    // MARK: - One a week

    func testTheRaceIsTheOneAcceptedPactForTheWeek() {
        let pacts = [pact("a", with: "maya", week: lastWeek, mine: true, accepted: true),
                     pact("b", with: "jun", week: week, mine: false, accepted: false),
                     pact("c", with: "sam", week: week, mine: true, accepted: true)]
        XCTAssertEqual(RaceRules.current(pacts, week: week)?.id, "c")
        XCTAssertEqual(RaceRules.invites(pacts, week: week).map(\.id), ["b"])
        XCTAssertNil(RaceRules.sent(pacts, week: week))
        XCTAssertFalse(RaceRules.canInvite(pacts, week: week), "a race is already on")
    }

    func testAnInviteYouSentBlocksASecondOne() {
        let pacts = [pact("a", with: "maya", week: week, mine: true, accepted: false)]
        XCTAssertEqual(RaceRules.sent(pacts, week: week)?.id, "a")
        XCTAssertFalse(RaceRules.canInvite(pacts, week: week))
        XCTAssertTrue(RaceRules.canInvite([], week: week))
    }

    func testADeclinedInviteIsNeitherPendingNorOn() {
        let p = pact("a", with: "maya", week: week, mine: false, accepted: false, declined: true)
        XCTAssertFalse(p.pendingMine)
        XCTAssertNil(RaceRules.current([p], week: week))
        XCTAssertTrue(RaceRules.invites([p], week: week).isEmpty)
    }

    // MARK: - The standing

    func testTheStandingReadsBothSidesOffTheBoard() {
        let race = pact("a", with: "maya", week: week, mine: true, accepted: true)
        let members = [member("you", 820, you: true), member("maya", 760)]
        let s = try! XCTUnwrap(RaceRules.standing(race, members: members))
        XCTAssertEqual(s.lead, 60)
        XCTAssertEqual(s.line, "You're ahead by 60")
        let behind = RaceRules.standing(race, members: [member("you", 700, you: true), member("maya", 760)])!
        XCTAssertEqual(behind.line, "\(friend("maya").displayName) is ahead by 60")
        XCTAssertEqual(RaceRules.standing(race, members: [member("you", 5, you: true), member("maya", 5)])?.line, "Level")
    }

    func testNoStandingUntilTheyHaveSharedADay() {
        let race = pact("a", with: "maya", week: week, mine: true, accepted: true)
        XCTAssertNil(RaceRules.standing(race, members: [member("you", 820, you: true)]))
    }

    // MARK: - Settling

    private func settled() -> LeagueState {
        var s = LeagueState()
        s.history = [LeagueWeekResult(week: lastWeek, tier: .tidepool, coinsEarned: 0, promoted: false)]
        return s
    }

    func testAheadOrLevelKeepsAPennantAndTheOtherLosesNothing() {
        var s = settled()
        XCTAssertTrue(s.settleRace(RaceResult(otherName: "Maya", mine: 800, theirs: 700), for: lastWeek))
        XCTAssertEqual(s.racesWon, 1)
        XCTAssertEqual(s.tier, .tidepool)

        var t = settled()
        XCTAssertTrue(t.settleRace(RaceResult(otherName: "Maya", mine: 700, theirs: 700), for: lastWeek),
                      "level is a pennant each")
        var u = settled()
        XCTAssertFalse(u.settleRace(RaceResult(otherName: "Maya", mine: 600, theirs: 700), for: lastWeek))
        XCTAssertEqual(u.racesWon, 0)
        XCTAssertEqual(u.history[0].race?.theirs, 700, "the receipt still says what happened")
        XCTAssertEqual(u.unseenSettledWeek?.week, lastWeek, "and Monday says so, once")
    }

    func testARaceIsSettledOnce() {
        var s = settled()
        s.settleRace(RaceResult(otherName: "Maya", mine: 800, theirs: 700), for: lastWeek)
        s.settleRace(RaceResult(otherName: "Maya", mine: 800, theirs: 700), for: lastWeek)
        XCTAssertEqual(s.racesWon, 1)
    }

    // MARK: - The wire

    func testAPactDecodesTheBridgeRow() throws {
        let json = #"{"id":"p1","kind":1,"week":"2026-W36","mine":false,"accepted":true,"declined":false,"other":{"id":"maya","adj":3,"noun":4,"species":"ember","look":"classic","level":2,"costume":"none","scene":"reef","tier":1}}"#
        let p = try JSONDecoder().decode(Pact.self, from: Data(json.utf8))
        XCTAssertEqual(p.id, "p1")
        XCTAssertEqual(p.week, week)
        XCTAssertTrue(p.accepted)
        XCTAssertFalse(p.mine)
        XCTAssertEqual(p.other.id, "maya")
    }

    func testAnOldSaveOpensWithNoRaces() throws {
        let old = #"{"tier":0,"weekStart":"2026-W36","pennants":[],"history":[]}"#
        let s = try JSONDecoder().decode(LeagueState.self, from: Data(old.utf8))
        XCTAssertTrue(s.races.isEmpty)
        XCTAssertEqual(s.racesWon, 0)
    }
}

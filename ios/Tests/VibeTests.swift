import XCTest
@testable import PrepkinCanvas

/// One wave, and the rules around it.
///
/// The six drawn cards do not exist yet, so exactly one card ships and the other
/// five indices stay reserved on the wire. Everything that can actually go wrong is
/// here anyway: the once-a-day rule, an index this build has no picture for, and the
/// day window that stops a friend in another time zone waving into a void.
final class VibeTests: XCTestCase {
    private let today = DayKey(raw: "2026-09-10")

    private func friend(_ id: String) -> Friend {
        Friend(id: id, adjective: 1, noun: 2, speciesID: "ember", lookID: "classic",
               costumeID: "none", sceneID: "reef", level: 2, tier: .reef,
               friendsSince: Date(timeIntervalSince1970: 1_757_000_000), onShiftUntil: nil)
    }

    // MARK: - The cards that exist

    func testOneCardShipsAndTheRestOfTheRangeIsReserved() {
        XCTAssertEqual(Vibes.all.count, 1, "the six faces are not drawn yet")
        XCTAssertEqual(Vibes.all.first?.kind, 0)
        // The bridge takes 0...15. Reserving the range now means the other five
        // land as data later, with no change to the wire and no migration.
        XCTAssertTrue(Vibes.reserved.contains(5))
        XCTAssertFalse(Vibes.reserved.contains(16))
    }

    /// A phone on an older build will one day be waved at with a card it has never
    /// heard of. It draws the one it has rather than a hole.
    func testAnUnknownCardFallsBackRatherThanBlank() {
        XCTAssertEqual(Vibes.card(kind: 0).kind, 0)
        XCTAssertEqual(Vibes.card(kind: 4).kind, 0, "reserved but not drawn yet")
        XCTAssertEqual(Vibes.card(kind: 99).kind, 0)
        XCTAssertEqual(Vibes.card(kind: -1).kind, 0)
        XCTAssertFalse(Vibes.card(kind: 99).label.isEmpty)
    }

    func testTheLabelNeverShouts() {
        for card in Vibes.all {
            XCTAssertFalse(card.label.contains("!"))
            XCTAssertFalse(card.label.isEmpty)
        }
    }

    // MARK: - Once a day

    func testWavingTwiceInADayIsSettledNotRefused() {
        var state = GameState()
        state.addFriend(friend("a"))
        XCTAssertFalse(state.hasWaved(at: "a", on: today))
        state.markWaved(at: "a", on: today)
        XCTAssertTrue(state.hasWaved(at: "a", on: today))
        // Tomorrow is a fresh one.
        XCTAssertFalse(state.hasWaved(at: "a", on: DayKey(raw: "2026-09-11")))
    }

    func testWhoYouHaveWavedAtComesBackFromTheBridgeToo() {
        var state = GameState()
        state.addFriend(friend("a"))
        state.addFriend(friend("b"))
        // fetch_sent is the truth after a reinstall, when this phone has no memory
        // of today at all.
        state.applyWavesSent(["b"], on: today)
        XCTAssertFalse(state.hasWaved(at: "a", on: today))
        XCTAssertTrue(state.hasWaved(at: "b", on: today))
    }

    // MARK: - Being waved at

    func testTheNewestWaveFromEachPersonWins() {
        // fetch_visits returns yesterday and today, oldest first, so somebody who
        // waved on both days is in the list twice.
        let visits = [VibeVisit(sender: friend("a"), kind: 0),
                      VibeVisit(sender: friend("b"), kind: 0),
                      VibeVisit(sender: friend("a"), kind: 3)]
        let newest = Vibes.newest(visits)
        XCTAssertEqual(newest.count, 2, "nobody is drawn twice")
        XCTAssertEqual(newest.first(where: { $0.sender.id == "a" })?.kind, 3)
    }

    func testAWaveIsNewsUntilYouHaveLookedAtIt() {
        var state = GameState()
        state.addFriend(friend("a"))
        state.applyWavesReceived(["a"], on: today)
        XCTAssertEqual(state.unseenWaves(on: today), ["a"])
        state.markWaveSeen("a", on: today)
        XCTAssertTrue(state.unseenWaves(on: today).isEmpty)
        // A second fetch on the same day must not put the card back.
        state.applyWavesReceived(["a"], on: today)
        XCTAssertTrue(state.unseenWaves(on: today).isEmpty)
    }

    func testYesterdaysWaveIsNotTodaysNews() {
        var state = GameState()
        state.addFriend(friend("a"))
        state.applyWavesReceived(["a"], on: DayKey(raw: "2026-09-09"))
        XCTAssertTrue(state.unseenWaves(on: today).isEmpty)
    }

    // MARK: - The wire

    func testAVisitDecodesFromTheRowTheBridgeSends() throws {
        let json = """
        [{"id":"11111111-2222-3333-4444-555555555555","adj":7,"noun":9,
          "species":"droplet","look":"classic","level":2,"costume":"none",
          "scene":"kelp","tier":1,"kind":0}]
        """
        let rows = try JSONDecoder().decode([VibeVisit].self, from: Data(json.utf8))
        let v = try XCTUnwrap(rows.first)
        XCTAssertEqual(v.kind, 0)
        XCTAssertEqual(v.sender.speciesID, "droplet")
        XCTAssertEqual(v.sender.displayName, PodName.name(adjective: 7, noun: 9))
        XCTAssertNil(v.sender.nickname, "nothing a student typed comes back")
    }

    func testTheMockNeverWavesAtYouOnItsOwn() async throws {
        let mock = MockFriendClient()
        let identity = LeagueIdentity(id: "x", token: "y", adjective: 0, noun: 0)
        let visits = try await mock.fetchVisits(identity: identity, day: today)
        XCTAssertTrue(visits.isEmpty)
        let sent = try await mock.fetchSent(identity: identity, day: today)
        XCTAssertTrue(sent.isEmpty)
    }
}

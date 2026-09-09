import XCTest
@testable import PrepkinCanvas

/// Sitting down to work at the same time as a friend. The rules that make the cheap
/// version safe are all in here, because none of them are visible in the UI.
final class StudyTogetherTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_757_000_000)

    private func presence(minutesLeft: Int, name: Int = 0) -> FocusPresence {
        FocusPresence(playerID: "p\(name)", adjective: name, noun: name,
                      speciesID: "slime", lookID: "classic", level: 2,
                      endsAt: now.addingTimeInterval(TimeInterval(minutesLeft * 60)))
    }

    // MARK: - Joining

    func testJoinPicksTheNearestOfferedLength() {
        XCTAssertEqual(StudyTogether.joinLength(minutesLeft: 24), 25)
        XCTAssertEqual(StudyTogether.joinLength(minutesLeft: 40), 45)
        XCTAssertEqual(StudyTogether.joinLength(minutesLeft: 5), 15)
        XCTAssertEqual(StudyTogether.joinLength(minutesLeft: 90), 45, "never longer than we offer")
    }

    func testATieRoundsDownSoJoiningNeverSignsYouUpForLonger() {
        // Exactly between 15 and 25.
        XCTAssertEqual(StudyTogether.joinLength(minutesLeft: 20), 15)
        // Exactly between 25 and 45.
        XCTAssertEqual(StudyTogether.joinLength(minutesLeft: 35), 25)
    }

    func testASessionAboutToEndCannotBeJoined() {
        XCTAssertNil(StudyTogether.joinLength(minutesLeft: 1))
        XCTAssertNil(StudyTogether.joinLength(minutesLeft: 0))
        XCTAssertNotNil(StudyTogether.joinLength(minutesLeft: StudyTogether.joinFloor))
    }

    // MARK: - Liveness

    func testAFinishedSessionIsNotLive() {
        XCTAssertTrue(presence(minutesLeft: 1).isLive(at: now))
        XCTAssertFalse(presence(minutesLeft: 0).isLive(at: now))
        XCTAssertFalse(presence(minutesLeft: -30).isLive(at: now))
    }

    func testMinutesLeftRoundsUpSoNothingReadsAsZeroWhileItIsStillRunning() {
        let p = FocusPresence(playerID: "p", adjective: 0, noun: 0, speciesID: "slime",
                              lookID: "classic", level: 1, endsAt: now.addingTimeInterval(30))
        XCTAssertEqual(p.minutesLeft(at: now), 1)
        XCTAssertTrue(p.isLive(at: now))
    }

    func testTheLineNeverNudges() {
        XCTAssertEqual(StudyTogether.line(for: presence(minutesLeft: 12), at: now),
                       "focusing, 12 min left")
        XCTAssertEqual(StudyTogether.line(for: presence(minutesLeft: 1), at: now),
                       "focusing, 1 min left")
        XCTAssertEqual(StudyTogether.line(for: presence(minutesLeft: 0), at: now),
                       "just finished")
        for left in [0, 1, 12, 44] {
            let line = StudyTogether.line(for: presence(minutesLeft: left), at: now)
            XCTAssertFalse(line.contains("!"), "no urgency in a line about somebody else's work")
            XCTAssertFalse(line.lowercased().contains("behind"))
            XCTAssertFalse(line.lowercased().contains("join"), "the button asks, the line reports")
        }
    }

    // MARK: - The level is clamped, like every other kin on the wire

    func testAnImpossibleLevelIsClampedRatherThanTrusted() {
        let high = FocusPresence(playerID: "p", adjective: 0, noun: 0, speciesID: "slime",
                                 lookID: "classic", level: 9, endsAt: now)
        XCTAssertEqual(high.level, 3)
    }

    // MARK: - The wire

    func testAPresenceSurvivesARoundTrip() throws {
        let sent = presence(minutesLeft: 20, name: 3)
        let data = try JSONEncoder().encode(sent)
        let back = try JSONDecoder().decode(FocusPresence.self, from: data)
        XCTAssertEqual(back.playerID, sent.playerID)
        XCTAssertEqual(back.displayName, sent.displayName)
        // The wire carries whole milliseconds, so compare at that resolution.
        XCTAssertEqual(back.endsAt.timeIntervalSince1970,
                       sent.endsAt.timeIntervalSince1970, accuracy: 0.01)
    }

    func testAnUnreadableEndTimeReadsAsFinishedRatherThanAsForever() throws {
        let json = Data(#"{"id":"p","adj":1,"noun":2,"species":"slime","look":"classic","level":1,"ends":"not a date"}"#.utf8)
        let back = try JSONDecoder().decode(FocusPresence.self, from: json)
        XCTAssertFalse(back.isLive(at: now), "a broken row shows nobody, never a ghost")
    }

    func testAnEmptyPayloadDoesNotThrow() throws {
        let back = try JSONDecoder().decode(FocusPresence.self, from: Data("{}".utf8))
        XCTAssertEqual(back.level, 1)
        XCTAssertFalse(back.isLive(at: now))
    }

    // MARK: - The mock seats nobody

    func testTheMockNeverInventsCompany() async throws {
        let client = MockStudyClient()
        let identity = LeagueIdentity(id: "m", token: "t", adjective: 0, noun: 0)
        let rows = try await client.friendsFocusing(identity: identity)
        XCTAssertTrue(rows.isEmpty, "a demo must never invite a student to sit with nobody")
    }
}

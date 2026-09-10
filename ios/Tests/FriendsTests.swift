import XCTest
@testable import PrepkinCanvas

/// The Friends tab's rules, none of which are visible in the UI.
///
/// Four things are pinned here because getting any of them wrong shows a student
/// something that is not true: whose name a row prints, who counts as new, what a
/// shift line says, and what happens to the four fake friends an old save is
/// carrying.
final class FriendsTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_757_000_000)

    private func friend(_ id: String, adjective: Int = 0, noun: Int = 0,
                        nickname: String? = nil, seenAt: Date = .distantPast,
                        shiftMinutes: Int? = nil) -> Friend {
        Friend(id: id, adjective: adjective, noun: noun,
               speciesID: "sprout", lookID: "classic", costumeID: "none",
               sceneID: "lagoon", level: 2, tier: .reef,
               friendsSince: now.addingTimeInterval(-86_400),
               onShiftUntil: shiftMinutes.map { now.addingTimeInterval(TimeInterval($0 * 60)) },
               nickname: nickname, seenAt: seenAt)
    }

    // MARK: - The name on the row

    func testANicknameWinsAndTheWordListNameIsTheFallback() {
        let named = friend("a", adjective: 1, noun: 1, nickname: "Maya")
        XCTAssertEqual(named.displayName, "Maya")

        let plain = friend("b", adjective: 1, noun: 1)
        XCTAssertEqual(plain.displayName, PodName.name(adjective: 1, noun: 1))
        XCTAssertFalse(plain.displayName.isEmpty, "a row always prints something")
    }

    func testABlankNicknameIsNotAName() {
        XCTAssertEqual(friend("a", nickname: "   ").displayName,
                       PodName.name(adjective: 0, noun: 0))
    }

    /// Same rule as naming a kin: trimmed, fourteen characters, empty means none.
    func testANicknameIsCleanedTheWayAKinNameIs() {
        XCTAssertEqual(Friend.cleanNickname("  Maya  "), "Maya")
        XCTAssertEqual(Friend.cleanNickname("Bartholomew Ashworth")?.count, 14)
        XCTAssertNil(Friend.cleanNickname("   "))
        XCTAssertNil(Friend.cleanNickname(""))
    }

    // MARK: - "Maya added you"

    func testAFriendThisPhoneHasNeverSeenIsNew() {
        let fetched = [friend("a"), friend("b")]
        let merged = FriendList.merge(fetched: fetched, cached: [])
        XCTAssertEqual(FriendList.added(in: merged).map(\.id), ["a", "b"])
    }

    func testMergeCarriesTheNicknameAndTheSeenStampForward() {
        let cached = [friend("a", nickname: "Maya", seenAt: now)]
        let fetched = [friend("a", shiftMinutes: 20)]
        let merged = FriendList.merge(fetched: fetched, cached: cached)

        XCTAssertEqual(merged.first?.nickname, "Maya", "a nickname never comes off the wire")
        XCTAssertEqual(merged.first?.seenAt, now)
        XCTAssertTrue(FriendList.added(in: merged).isEmpty, "an old friend is not news")
        XCTAssertNotNil(merged.first?.onShiftUntil, "the wire still wins on everything else")
    }

    func testAFriendTheBridgeNoLongerReturnsDropsOut() {
        let merged = FriendList.merge(fetched: [friend("a")],
                                      cached: [friend("a"), friend("gone")])
        XCTAssertEqual(merged.map(\.id), ["a"])
    }

    func testSomebodyYouAddedYourselfIsNeverNewsToYou() {
        var state = GameState()
        state.applyFriends([friend("a")], now: now)
        XCTAssertTrue(state.friends.first?.isNew == true)

        var other = GameState()
        other.addFriend(friend("a"), now: now)
        XCTAssertFalse(other.friends.first?.isNew == true)
        XCTAssertEqual(other.friends.first?.seenAt, now)
    }

    func testSeeingACardMarksItSeenOnce() {
        var state = GameState()
        state.applyFriends([friend("a")], now: now)
        state.markFriendSeen("a", at: now)
        XCTAssertTrue(FriendList.added(in: state.friends).isEmpty)

        // A later fetch must not put the card back.
        state.applyFriends([friend("a", shiftMinutes: 5)], now: now.addingTimeInterval(600))
        XCTAssertTrue(FriendList.added(in: state.friends).isEmpty)
    }

    // MARK: - On shift

    func testTheShiftLineOnlyShowsWhileTheClockIsStillRunning() {
        XCTAssertEqual(friend("a", shiftMinutes: 12).shiftLine(at: now), "on shift · 12 min left")
        XCTAssertEqual(friend("a", shiftMinutes: 1).shiftLine(at: now), "on shift · 1 min left")
        XCTAssertNil(friend("a", shiftMinutes: 0).shiftLine(at: now))
        XCTAssertNil(friend("a", shiftMinutes: -10).shiftLine(at: now))
        XCTAssertNil(friend("a").shiftLine(at: now), "nobody who is not working gets a line")
    }

    func testAShiftLineNeverNudges() {
        for minutes in [1, 12, 44] {
            let line = friend("a", shiftMinutes: minutes).shiftLine(at: now) ?? ""
            XCTAssertFalse(line.contains("!"))
            XCTAssertFalse(line.lowercased().contains("join"))
        }
    }

    // MARK: - Nicknames live here and nowhere else

    func testANicknameIsWrittenToThisPhoneAndNeverReadBackOffTheWire() throws {
        let f = friend("a", nickname: "Maya", seenAt: now)
        let saved = try JSONEncoder().encode(f)
        XCTAssertTrue(String(decoding: saved, as: UTF8.self).contains("Maya"),
                      "the save file on this phone keeps it")
        XCTAssertEqual(try JSONDecoder().decode(Friend.self, from: saved).nickname, "Maya")

        // The same shape read from the bridge has no nickname key at all, so a
        // fetch can never hand one phone a string another phone typed.
        let row = #"{"id":"a","adj":0,"noun":0}"#
        XCTAssertNil(try JSONDecoder().decode(Friend.self, from: Data(row.utf8)).nickname)
    }

    func testSettingANicknameCleansItAndClearingItFallsBack() {
        var state = GameState()
        state.addFriend(friend("a", adjective: 3, noun: 4), now: now)
        state.setNickname("  Maya  ", for: "a")
        XCTAssertEqual(state.friends.first?.displayName, "Maya")
        state.setNickname("", for: "a")
        XCTAssertNil(state.friends.first?.nickname)
        XCTAssertEqual(state.friends.first?.displayName, PodName.name(adjective: 3, noun: 4))
    }

    // MARK: - The wire

    /// One row of `fetch_friends`, read the way the bridge writes it.
    func testAFriendDecodesFromTheRowTheBridgeSends() throws {
        let json = """
        [{"id":"11111111-2222-3333-4444-555555555555","adj":7,"noun":9,
          "species":"ember","look":"classic","level":3,"costume":"ninja",
          "scene":"reef","tier":2,
          "since":"2026-09-01T10:00:00.000Z",
          "shift":"2126-09-01T10:25:00.000Z"}]
        """
        let rows = try JSONDecoder().decode([Friend].self, from: Data(json.utf8))
        let f = try XCTUnwrap(rows.first)
        XCTAssertEqual(f.adjective, 7)
        XCTAssertEqual(f.noun, 9)
        XCTAssertEqual(f.speciesID, "ember")
        XCTAssertEqual(f.level, 3)
        XCTAssertEqual(f.costumeID, "ninja")
        XCTAssertEqual(f.sceneID, "reef")
        XCTAssertEqual(f.tier, .reef)
        XCTAssertNotNil(f.onShiftUntil)
        XCTAssertNil(f.nickname, "nothing a student typed comes back")
        XCTAssertTrue(f.isNew)
    }

    /// `add_friend` answers with a public row and no friendship date.
    func testARowWithHalfItsKeysMissingStillDraws() throws {
        let json = #"{"id":"abc","adj":1,"noun":2}"#
        let f = try JSONDecoder().decode(Friend.self, from: Data(json.utf8))
        XCTAssertEqual(f.id, "abc")
        XCTAssertEqual(f.level, 1, "clamped into the range the art has")
        XCTAssertEqual(f.tier, .tidepool)
        XCTAssertNil(f.onShiftUntil)
        XCTAssertFalse(f.speciesID.isEmpty)
    }

    func testALevelOutsideTheArtIsClamped() throws {
        let json = #"{"id":"abc","level":99}"#
        let f = try JSONDecoder().decode(Friend.self, from: Data(json.utf8))
        XCTAssertEqual(f.level, 3)
    }

    // MARK: - What an old save is carrying

    /// A v4 file holds four invented friends, a list of codes nobody ever sent, and
    /// a code this phone made up. All three are lies the moment the tab is real, so
    /// the migration drops them rather than trying to read them forward.
    func testUpgradingDropsTheFakeFriendsTheCodesAndTheMadeUpCode() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("friends-migration-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let old = """
        {"version":4,"state":{
          "activeChibiID":"slime",
          "friendCode":"ABCD-EFGH",
          "pendingFriendCodes":["JKLM-NPQR"],
          "friends":[{"id":"maya","name":"Maya","speciesID":"ember","level":3,
                      "weekCoins":320,"lastActivity":"Focused 45 min"}]
        }}
        """
        try Data(old.utf8).write(to: dir.appendingPathComponent("state.json"))

        let suite = "friends-migration-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let state = Store(directory: dir, defaults: defaults, debounce: 0).load()

        XCTAssertTrue(state.friends.isEmpty, "a made-up friend must never survive into a real list")
        XCTAssertNil(state.friendCode, "the code is the server's to hand out now")
        XCTAssertEqual(state.activeChibiID, "slime", "the rest of the save is untouched")
        XCTAssertGreaterThan(Store.currentVersion, 4)
    }

    // MARK: - The mock

    func testTheMockNeverInventsAPerson() async throws {
        let mock = MockFriendClient()
        let identity = LeagueIdentity(id: "x", token: "y", adjective: 0, noun: 0)
        let list = try await mock.fetchFriends(identity: identity)
        XCTAssertTrue(list.isEmpty)
        let added = try await mock.addFriend(identity: identity, code: "ABCD-EFGH")
        XCTAssertNil(added, "a code opens nothing when there is nobody to open")
    }
}

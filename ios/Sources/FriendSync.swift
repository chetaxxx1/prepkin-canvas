import Foundation

// Friends: the people a student chose, one code at a time.
//
// Built on the same shape as `LeagueSync.swift` and `StudySync.swift` — a protocol, a
// Supabase client that POSTs to one database function per call, a mock, and the rule
// that a configured install never falls back to sample data. Read `LeagueSync.swift`
// first; this file only says what is different.
//
// Three decisions from `design/FRIENDS-BUILD-PLAN.md` §2 are load-bearing here:
//
//   1. **No accept step.** Handing somebody your code is the consent. `add_friend`
//      makes the pair on the spot, both ways, and there is no pending anything. What
//      protects a student instead is that a code is replaceable — `rotateCode` makes
//      the old one stop working — and that Block ends one person for good.
//   2. **Nicknames live on the phone that typed them.** The wire carries two indices
//      into shipped word lists, so there is no string here a student wrote and
//      nothing anybody has to moderate. `Friend.nickname` is a save-file field with
//      no call that could ever send it.
//   3. **A wrong code and a code that is not yours to open give the same answer:**
//      nothing. Blocked, rotated, mistyped, never existed — all null. A stranger
//      cannot use this to find out whether a code is live.
//
// And one that is not a decision so much as a line nobody crosses: no coins, in any
// direction, in any friend payload (`SOCIAL-PLAN.md` F5).

// MARK: - The list, as a rule

/// The pure half of the tab: what a fetched list does to the list already on the
/// phone. Separate from everything else so it can be walked by a test with no view
/// and no network in it.
enum FriendList {
    /// Folds what the bridge just sent into what this phone already knew.
    ///
    /// The bridge wins on everything it sends, because it is the only thing that
    /// knows a level went up or a shift started. This phone wins on the two fields
    /// the bridge has never heard of: the nickname, and whether you have been told
    /// about this person yet.
    ///
    /// Anybody missing from `fetched` is gone — removed, or blocked, from either
    /// side. There is no tombstone and nothing is told about it.
    static func merge(fetched: [Friend], cached: [Friend]) -> [Friend] {
        var mine: [String: Friend] = [:]
        for f in cached { mine[f.id] = f }
        return fetched.map { row in
            guard let old = mine[row.id] else { return row }
            var next = row
            next.nickname = old.nickname
            next.seenAt = old.seenAt
            return next
        }
    }

    /// The people to put a card at the top of the tab for: in the list, never shown.
    ///
    /// This is the whole of "Maya added you". There is no inbox table on the bridge
    /// and no unread flag — a friendship this phone has not drawn yet *is* the news,
    /// and looking at it is what makes it stop being news.
    static func added(in list: [Friend]) -> [Friend] { list.filter(\.isNew) }
}

// MARK: - The client

enum FriendError: Error, Equatable {
    case notConfigured
    case server(status: Int)
    case badResponse
}

/// The bridge to the people a student added.
///
/// Every call takes the identity because every call proves who is asking; there is
/// no call here that reads anything about a person you are not already friends with,
/// except `addFriend`, which is the one that makes you friends.
protocol FriendClient {
    /// This player's code, minted on the first ask and the same one forever after.
    func myCode(identity: LeagueIdentity) async throws -> String
    /// A new code. The old one stops opening anything the moment this returns.
    func rotateCode(identity: LeagueIdentity) async throws -> String
    /// `nil` when the code opens nothing. See the header: that answer covers a typo,
    /// a rotated code, a blocked person and your own code alike, on purpose.
    func addFriend(identity: LeagueIdentity, code: String) async throws -> Friend?
    func removeFriend(identity: LeagueIdentity, friendID: String) async throws
    /// Ends the friendship and stops it being remade, in both directions.
    func blockPlayer(identity: LeagueIdentity, playerID: String) async throws
    /// Two ids and a time, read by hand. There is no free text to attach because
    /// there is no free text anywhere.
    func reportPlayer(identity: LeagueIdentity, playerID: String) async throws
    /// Everybody, with when the pair was made and whether they are on shift now.
    /// One call draws the tab. Empty is a real and common answer.
    func fetchFriends(identity: LeagueIdentity) async throws -> [Friend]
    /// The two cosmetic ids a visitor's screen needs. Cosmetic only — neither
    /// decides anything.
    func setTank(identity: LeagueIdentity, costume: String, scene: String) async throws

    /// Today's four counts, replacing whatever this day already held. The phone
    /// sends whole-day totals, so a retry cannot double anything.
    func pushToday(identity: LeagueIdentity, day: DayKey, counts: TodayCounts) async throws
    /// Friends' rows across a window of days, for the ones who share. A friend who
    /// has sharing off is simply not in the answer, which looks exactly like a
    /// friend who did nothing — on purpose.
    func fetchToday(identity: LeagueIdentity, from: DayKey, to: DayKey) async throws -> [DayRow]

    /// Waves at somebody. `false` means today's was already sent, which is not an
    /// error and is not said out loud.
    @discardableResult
    func sendVibe(identity: LeagueIdentity, friendID: String, kind: Int, day: DayKey) async throws -> Bool
    /// Who waved at you. Covers yesterday too — see the window in the schema.
    func fetchVisits(identity: LeagueIdentity, day: DayKey) async throws -> [VibeVisit]
    /// Who you have already waved at today.
    func fetchSent(identity: LeagueIdentity, day: DayKey) async throws -> [String]

    /// The two privacy flags. Neither is about the fish: a friend can always see
    /// the kin they were given a code for.
    func setSharing(identity: LeagueIdentity, today: Bool, board: Bool) async throws

    /// Invites a friend to race this week. The row that already exists comes back
    /// if one does, so inviting twice is one invite.
    func proposeRace(identity: LeagueIdentity, friendID: String, week: WeekKey) async throws -> Pact
    /// Accepts or declines an invite addressed to you.
    func answerRace(identity: LeagueIdentity, pactID: String, accept: Bool) async throws -> Pact
    /// Every pact you are in from `from` week onward, declined ones left out.
    func fetchRaces(identity: LeagueIdentity, from: WeekKey) async throws -> [Pact]
}

struct SupabaseFriendClient: FriendClient {
    var config: BridgeConfig = .shared
    var session: URLSession = .shared

    private func call(_ function: String, _ body: [String: Any]) async throws -> Data {
        guard config.isConfigured, let endpoint = config.endpoint(function) else {
            throw FriendError.notConfigured
        }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(config.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(config.publishableKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 15

        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else { throw FriendError.server(status: status) }
        return data
    }

    private func who(_ identity: LeagueIdentity) -> [String: Any] {
        ["p_player": identity.id, "p_token": identity.token]
    }

    func myCode(identity: LeagueIdentity) async throws -> String {
        try Self.text(try await call("my_code", who(identity)))
    }

    func rotateCode(identity: LeagueIdentity) async throws -> String {
        try Self.text(try await call("rotate_code", who(identity)))
    }

    func addFriend(identity: LeagueIdentity, code: String) async throws -> Friend? {
        var body = who(identity)
        body["p_code"] = code
        let data = try await call("add_friend", body)
        // `null` is the answer to a code that opens nothing, and it is not an error.
        guard !Self.isNull(data) else { return nil }
        guard let friend = try? JSONDecoder().decode(Friend.self, from: data),
              !friend.id.isEmpty else {
            throw FriendError.badResponse
        }
        return friend
    }

    func removeFriend(identity: LeagueIdentity, friendID: String) async throws {
        var body = who(identity)
        body["p_friend"] = friendID
        _ = try await call("remove_friend", body)
    }

    func blockPlayer(identity: LeagueIdentity, playerID: String) async throws {
        var body = who(identity)
        body["p_other"] = playerID
        _ = try await call("block_player", body)
    }

    func reportPlayer(identity: LeagueIdentity, playerID: String) async throws {
        var body = who(identity)
        body["p_other"] = playerID
        _ = try await call("report_player", body)
    }

    func fetchFriends(identity: LeagueIdentity) async throws -> [Friend] {
        let data = try await call("fetch_friends", who(identity))
        guard !Self.isNull(data) else { return [] }
        guard let rows = try? JSONDecoder().decode([Friend].self, from: data) else {
            throw FriendError.badResponse
        }
        // A row with no id cannot be tapped, removed or drawn. Dropping it here is
        // better than a ghost on the tab that nothing can act on.
        return rows.filter { !$0.id.isEmpty }
    }

    func setTank(identity: LeagueIdentity, costume: String, scene: String) async throws {
        var body = who(identity)
        body["p_costume"] = costume
        body["p_scene"] = scene
        _ = try await call("set_tank", body)
    }

    func pushToday(identity: LeagueIdentity, day: DayKey, counts: TodayCounts) async throws {
        var body = who(identity)
        body["p_day"] = day.raw
        body["p_tasks"] = counts.tasks
        body["p_focus"] = counts.focusMinutes
        body["p_lessons"] = counts.lessons
        body["p_games"] = counts.games
        _ = try await call("push_today", body)
    }

    func fetchToday(identity: LeagueIdentity, from: DayKey, to: DayKey) async throws -> [DayRow] {
        var body = who(identity)
        body["p_from"] = from.raw
        body["p_to"] = to.raw
        let data = try await call("fetch_today", body)
        guard !Self.isNull(data) else { return [] }
        guard let rows = try? JSONDecoder().decode([DayRow].self, from: data) else {
            throw FriendError.badResponse
        }
        return rows.filter { !$0.playerID.isEmpty }
    }

    @discardableResult
    func sendVibe(identity: LeagueIdentity, friendID: String, kind: Int, day: DayKey) async throws -> Bool {
        var body = who(identity)
        body["p_friend"] = friendID
        body["p_kind"] = kind
        body["p_day"] = day.raw
        let data = try await call("send_vibe", body)
        return String(decoding: data, as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines) == "true"
    }

    func fetchVisits(identity: LeagueIdentity, day: DayKey) async throws -> [VibeVisit] {
        var body = who(identity)
        body["p_day"] = day.raw
        let data = try await call("fetch_visits", body)
        guard !Self.isNull(data) else { return [] }
        guard let rows = try? JSONDecoder().decode([VibeVisit].self, from: data) else {
            throw FriendError.badResponse
        }
        return Vibes.newest(rows.filter { !$0.sender.id.isEmpty })
    }

    func fetchSent(identity: LeagueIdentity, day: DayKey) async throws -> [String] {
        var body = who(identity)
        body["p_day"] = day.raw
        let data = try await call("fetch_sent", body)
        guard !Self.isNull(data) else { return [] }
        guard let ids = try? JSONDecoder().decode([String].self, from: data) else {
            throw FriendError.badResponse
        }
        return ids
    }

    func setSharing(identity: LeagueIdentity, today: Bool, board: Bool) async throws {
        var body = who(identity)
        body["p_today"] = today
        body["p_board"] = board
        _ = try await call("set_sharing", body)
    }

    func proposeRace(identity: LeagueIdentity, friendID: String, week: WeekKey) async throws -> Pact {
        var body = who(identity)
        body["p_other"] = friendID
        body["p_week"] = week.raw
        return try Self.pact(try await call("propose_pact", body))
    }

    func answerRace(identity: LeagueIdentity, pactID: String, accept: Bool) async throws -> Pact {
        var body = who(identity)
        body["p_id"] = pactID
        body["p_accept"] = accept
        return try Self.pact(try await call("answer_pact", body))
    }

    func fetchRaces(identity: LeagueIdentity, from: WeekKey) async throws -> [Pact] {
        var body = who(identity)
        body["p_from"] = from.raw
        let data = try await call("fetch_pacts", body)
        guard !Self.isNull(data) else { return [] }
        guard let rows = try? JSONDecoder().decode([Pact].self, from: data) else {
            throw FriendError.badResponse
        }
        return rows.filter { !$0.id.isEmpty && !$0.other.id.isEmpty }
    }

    private static func pact(_ data: Data) throws -> Pact {
        guard !isNull(data), let row = try? JSONDecoder().decode(Pact.self, from: data),
              !row.id.isEmpty else { throw FriendError.badResponse }
        return row
    }

    /// A function that answers with a bare string: Postgres sends it quoted.
    private static func text(_ data: Data) throws -> String {
        let raw = String(decoding: data, as: UTF8.self)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"\n\r "))
        guard !raw.isEmpty, raw != "null" else { throw FriendError.badResponse }
        return raw
    }

    private static func isNull(_ data: Data) -> Bool {
        let text = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty || text == "null"
    }
}

/// Sample data for a checkout with no bridge configured.
///
/// **Nobody is here.** The list is empty and a code opens nothing, because inventing
/// a friend is the same lie as the four hard-coded friends that were cut from this
/// app already — and a worse one on this tab, where every row is a person a student
/// is meant to have chosen. An empty tab with a working Add button is also the state
/// every real student meets first, so it is the state most worth building against.
struct MockFriendClient: FriendClient {
    /// A code that is stable across a run, so Copy has something to copy.
    var code = "DEMO-CODE"
    /// Seeds a friend, for looking at the row. See `seededForTesting`.
    var seeded: [Friend] = []
    /// Seeded day rows, so the today lines and the weekly card have something to
    /// draw under `-fakeFriend`.
    var days: [DayRow] = []

    func myCode(identity: LeagueIdentity) async throws -> String { code }
    func rotateCode(identity: LeagueIdentity) async throws -> String { code }
    func addFriend(identity: LeagueIdentity, code: String) async throws -> Friend? { seeded.first }
    func removeFriend(identity: LeagueIdentity, friendID: String) async throws {}
    func blockPlayer(identity: LeagueIdentity, playerID: String) async throws {}
    func reportPlayer(identity: LeagueIdentity, playerID: String) async throws {}
    func fetchFriends(identity: LeagueIdentity) async throws -> [Friend] { seeded }
    func setTank(identity: LeagueIdentity, costume: String, scene: String) async throws {}
    func pushToday(identity: LeagueIdentity, day: DayKey, counts: TodayCounts) async throws {}
    func fetchToday(identity: LeagueIdentity, from: DayKey, to: DayKey) async throws -> [DayRow] { days }
    @discardableResult
    func sendVibe(identity: LeagueIdentity, friendID: String, kind: Int, day: DayKey) async throws -> Bool { true }
    /// **Nobody waves at you.** Inventing a hello from a person who does not exist
    /// is the same lie as the four hard-coded friends this app already cut.
    func fetchVisits(identity: LeagueIdentity, day: DayKey) async throws -> [VibeVisit] { [] }
    func fetchSent(identity: LeagueIdentity, day: DayKey) async throws -> [String] { [] }
    func setSharing(identity: LeagueIdentity, today: Bool, board: Bool) async throws {}

    /// Seeded races, for looking at the cards. See `seededForTesting`.
    var races: [Pact] = []

    func proposeRace(identity: LeagueIdentity, friendID: String, week: WeekKey) async throws -> Pact {
        let other = seeded.first { $0.id == friendID }
            ?? Friend(id: friendID, adjective: 0, noun: 0, speciesID: "sprout", lookID: "classic",
                      costumeID: "none", sceneID: "lagoon", level: 1, tier: .tidepool,
                      friendsSince: Date(), onShiftUntil: nil)
        return Pact(id: "mock-\(friendID)-\(week.raw)", week: week, mine: true, accepted: false, other: other)
    }
    func answerRace(identity: LeagueIdentity, pactID: String, accept: Bool) async throws -> Pact {
        guard let p = races.first(where: { $0.id == pactID }) else { throw FriendError.badResponse }
        return Pact(id: p.id, week: p.week, mine: p.mine, accepted: accept, declined: !accept, other: p.other)
    }
    func fetchRaces(identity: LeagueIdentity, from: WeekKey) async throws -> [Pact] { races }
}

#if DEBUG
extension MockFriendClient {
    /// Launch with `-fakeFriend` to put one friend on the tab.
    ///
    /// Same two guards as `-unlockAll` and `-fakeTable` — `#if DEBUG` and a launch
    /// argument — so a seeded row can never be mistaken for a real one, and an
    /// ordinary run still shows an empty tab.
    static let fakeFriendArgument = "-fakeFriend"

    /// Five: one on shift, one that arrives already made (so the "added you" card
    /// has something to be about), and a spread of weeks so the podium, the rows
    /// under it and the quest all have something to draw. The fifth shares no day,
    /// so the "not on the board" list has a row too.
    static func seededForTesting(now: Date = Date()) -> MockFriendClient {
        let today = DayKey(now)
        let week = WeekKey(today).days()
        func day(_ i: Int) -> DayKey { i < week.count ? week[i] : today }
        func friend(_ n: Int, _ adj: Int, _ noun: Int, _ species: String, _ scene: String,
                    level: Int, tier: LeagueTier, since: TimeInterval, shift: TimeInterval? = nil) -> Friend {
            Friend(id: "debug-friend-\(n)", adjective: adj, noun: noun,
                   speciesID: species, lookID: "classic", costumeID: "none",
                   sceneID: scene, level: level, tier: tier,
                   friendsSince: now.addingTimeInterval(since),
                   onShiftUntil: shift.map { now.addingTimeInterval($0) })
        }
        return MockFriendClient(code: "TEST-CODE", seeded: [
            friend(1, 12, 30, "ember", "reef", level: 3, tier: .reef, since: -3 * 86_400, shift: 23 * 60),
            friend(2, 41, 7, "droplet", "kelp", level: 2, tier: .tidepool, since: -120),
            friend(3, 5, 19, "wisp", "lagoon", level: 2, tier: .shallows, since: -9 * 86_400),
            friend(4, 27, 44, "comet", "dusk", level: 3, tier: .kelp, since: -30 * 86_400),
            friend(5, 33, 2, "mochi", "deep", level: 1, tier: .tidepool, since: -2 * 86_400),
        ], days: [
            DayRow(playerID: "debug-friend-1", day: today,
                   counts: TodayCounts(tasks: 4, focusMinutes: 75, lessons: 2, games: 3)),
            DayRow(playerID: "debug-friend-1", day: day(0),
                   counts: TodayCounts(tasks: 3, focusMinutes: 45, lessons: 1, games: 3)),
            DayRow(playerID: "debug-friend-1", day: day(1),
                   counts: TodayCounts(tasks: 3, focusMinutes: 50, lessons: 1, games: 2)),
            DayRow(playerID: "debug-friend-2", day: today,
                   counts: TodayCounts(tasks: 1, focusMinutes: 20)),
            DayRow(playerID: "debug-friend-3", day: day(0),
                   counts: TodayCounts(tasks: 2, focusMinutes: 25, lessons: 0, games: 1)),
            DayRow(playerID: "debug-friend-3", day: day(1),
                   counts: TodayCounts(tasks: 3, focusMinutes: 45, lessons: 1, games: 3)),
            DayRow(playerID: "debug-friend-3", day: day(2),
                   counts: TodayCounts(tasks: 3, focusMinutes: 30, lessons: 1, games: 3)),
            DayRow(playerID: "debug-friend-4", day: day(0),
                   counts: TodayCounts(tasks: 1, focusMinutes: 0, lessons: 0, games: 2)),
        ], races: [
            // A race that is on, and an invite waiting on you, so both cards draw.
            Pact(id: "mock-race", week: WeekKey(today), mine: true, accepted: true,
                 other: friend(3, 5, 19, "wisp", "lagoon", level: 2, tier: .shallows, since: -9 * 86_400)),
            Pact(id: "mock-invite", week: WeekKey(today), mine: false, accepted: false,
                 other: friend(1, 12, 30, "ember", "reef", level: 3, tier: .reef, since: -3 * 86_400)),
        ])
    }
}
#endif

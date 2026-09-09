import Foundation

// Study Together: sitting down to work at the same time as a friend.
//
// `design/FRIENDS-PLAN.md` §3 calls this the reason to open the Friends tab daily, and
// it is right — a board is something you glance at, a shared timer is something you
// show up for. It copies Forest's Plant Together and Focusmate, and this is the cheap
// version both plans point at: **two independent timers, no presence server, no
// websockets.** A friend's row says "focusing until 4:15" and Join starts YOUR clock.
//
// Three rules that make the cheap version safe as well as cheap:
//
//   1. **Joining links nothing.** Your session is your session. Quitting early costs
//      you nothing extra and the other person is never told. Nobody's tree dies —
//      Forest's shared punishment is the one part of Plant Together we refuse.
//   2. **Both sides are paid exactly as a solo session.** Coins pay for finishing, and
//      finishing next to somebody is the same amount of finishing.
//   3. **Nothing about the work travels.** The wire carries a kin and an end time. Not
//      the paired task, not a course, not a title.
//
// Built on the same shape as `LeagueSync.swift`: a protocol, a Supabase client that
// POSTs one database function per call, a mock, and a rule that a configured install
// never falls back to sample data. Read that file first; this one only says what is
// different.

// MARK: - Who is at the table

/// A friend who is working right now.
///
/// The same name-and-kin shape the pod board uses, plus the moment their clock runs
/// out. There is no id for what they are doing and no field for how it is going.
struct FocusPresence: Codable, Equatable, Identifiable {
    /// The friend, so a tap can open their tank. Unlike a pod member — who is
    /// deliberately anonymous week to week — a friend is somebody you already chose.
    let playerID: String
    let adjective: Int
    let noun: Int
    let speciesID: String
    let lookID: String
    let level: Int
    /// **The server set this**, from a capped number of minutes. A phone that could
    /// name its own end time could sit in the Friends tab all day looking busy.
    let endsAt: Date

    var id: String { playerID }
    var displayName: String { PodName.name(adjective: adjective, noun: noun) }

    /// Still going, as of `date`. A presence is never deleted on a schedule; it simply
    /// stops being true, which is why there is no cleanup job for this table.
    func isLive(at date: Date = Date()) -> Bool { endsAt > date }

    /// Whole minutes left, rounded up so "1 min left" is not shown as none.
    func minutesLeft(at date: Date = Date()) -> Int {
        max(0, Int(ceil(endsAt.timeIntervalSince(date) / 60)))
    }

    private enum CodingKeys: String, CodingKey { case id, adj, noun, species, look, level, ends }

    init(playerID: String, adjective: Int, noun: Int, speciesID: String,
         lookID: String, level: Int, endsAt: Date) {
        self.playerID = playerID
        self.adjective = adjective
        self.noun = noun
        self.speciesID = speciesID
        self.lookID = lookID
        self.level = min(max(level, 1), 3)
        self.endsAt = endsAt
    }

    /// Tolerant in the same way `PodMember` is: one odd key must never take the row
    /// down. An unreadable end time reads as already finished, so the worst a broken
    /// payload can do is show nobody rather than show somebody who is not there.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let raw = try c.decodeIfPresent(String.self, forKey: .ends) ?? ""
        self.init(playerID: try c.decodeIfPresent(String.self, forKey: .id) ?? "",
                  adjective: try c.decodeIfPresent(Int.self, forKey: .adj) ?? 0,
                  noun: try c.decodeIfPresent(Int.self, forKey: .noun) ?? 0,
                  speciesID: try c.decodeIfPresent(String.self, forKey: .species) ?? "slime",
                  lookID: try c.decodeIfPresent(String.self, forKey: .look) ?? "classic",
                  level: try c.decodeIfPresent(Int.self, forKey: .level) ?? 1,
                  endsAt: FocusPresence.wireDate.date(from: raw) ?? .distantPast)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(playerID, forKey: .id)
        try c.encode(adjective, forKey: .adj)
        try c.encode(noun, forKey: .noun)
        try c.encode(speciesID, forKey: .species)
        try c.encode(lookID, forKey: .look)
        try c.encode(level, forKey: .level)
        try c.encode(FocusPresence.wireDate.string(from: endsAt), forKey: .ends)
    }

    /// Postgres hands back ISO 8601 with fractional seconds. Both spellings are
    /// accepted because a server upgrade must not empty the table.
    static let wireDate: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
}

// MARK: - Joining

/// The pure part: what happens when you tap Join.
enum StudyTogether {
    /// The lengths the Focus screen offers. Repeated from `FocusView` rather than
    /// reached into, so this rule can be walked by a test with no view in it.
    static let lengths = [15, 25, 45]

    /// A session no longer worth joining. Under this, Join is hidden rather than
    /// starting a timer that ends before the student has put the phone down.
    static let joinFloor = 2

    /// The length to start when you join somebody with `minutesLeft` to go.
    ///
    /// **The nearest offered length, not the exact remainder.** Two clocks that end on
    /// the same second would be a promise this design does not make — the sessions are
    /// independent, and a student who joins with eleven minutes left and picks 15 has
    /// done nothing wrong. Ties round down, so joining never quietly signs you up for
    /// longer than the person you joined.
    static func joinLength(minutesLeft: Int, lengths: [Int] = lengths) -> Int? {
        guard minutesLeft >= joinFloor, let first = lengths.first else { return nil }
        return lengths.dropFirst().reduce(first) { best, m in
            abs(m - minutesLeft) < abs(best - minutesLeft) ? m : best
        }
    }

    /// What the row says. Plain, and never a nudge: it reports where somebody is, it
    /// does not ask the reader to do anything.
    static func line(for presence: FocusPresence, at date: Date = Date()) -> String {
        let left = presence.minutesLeft(at: date)
        if left <= 0 { return "just finished" }
        if left == 1 { return "focusing, 1 min left" }
        return "focusing, \(left) min left"
    }
}

// MARK: - The client

enum StudyError: Error, Equatable {
    case notConfigured
    case server(status: Int)
    case badResponse
}

protocol StudyClient {
    /// Says you have started. The bridge decides the end time from `minutes`; this
    /// returns whatever it decided, so the phone and the server never disagree about
    /// when you are finished.
    func startFocus(identity: LeagueIdentity, minutes: Int) async throws -> Date
    /// Says you have stopped, early or otherwise. Best-effort: a failure here leaves
    /// a row that expires on its own within the hour, which is why nothing waits on it.
    func endFocus(identity: LeagueIdentity) async throws
    /// Friends who are working right now. Empty is a real and common answer.
    func friendsFocusing(identity: LeagueIdentity) async throws -> [FocusPresence]
}

struct SupabaseStudyClient: StudyClient {
    var config: BridgeConfig = .shared
    var session: URLSession = .shared

    private func call(_ function: String, _ body: [String: Any]) async throws -> Data {
        guard config.isConfigured, let endpoint = config.endpoint(function) else {
            throw StudyError.notConfigured
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
        guard (200..<300).contains(status) else { throw StudyError.server(status: status) }
        return data
    }

    func startFocus(identity: LeagueIdentity, minutes: Int) async throws -> Date {
        let data = try await call("start_focus", [
            "p_player": identity.id, "p_token": identity.token, "p_minutes": minutes,
        ])
        let raw = String(decoding: data, as: UTF8.self)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"\n\r "))
        guard let ends = FocusPresence.wireDate.date(from: raw) else { throw StudyError.badResponse }
        return ends
    }

    func endFocus(identity: LeagueIdentity) async throws {
        _ = try await call("end_focus", ["p_player": identity.id, "p_token": identity.token])
    }

    func friendsFocusing(identity: LeagueIdentity) async throws -> [FocusPresence] {
        let data = try await call("friends_focusing", ["p_player": identity.id, "p_token": identity.token])
        guard let rows = try? JSONDecoder().decode([FocusPresence].self, from: data) else {
            throw StudyError.badResponse
        }
        // A row whose clock has already run out is dropped here rather than drawn as a
        // person who is still working. Clock skew between a phone and the bridge is
        // measured in seconds and this costs nothing.
        return rows.filter { $0.isLive() }
    }
}

/// Sample data for a checkout with no bridge configured.
///
/// **Nobody is focusing.** Inventing a friend at a desk is the same lie as the four
/// hard-coded friends that were cut from this app, and it is a worse one: it would
/// invite a student to sit down beside somebody who does not exist.
struct MockStudyClient: StudyClient {
    /// Seats two made-up friends, for looking at the row. See `seated`.
    var seated: [FocusPresence] = []

    func startFocus(identity: LeagueIdentity, minutes: Int) async throws -> Date {
        Date().addingTimeInterval(TimeInterval(minutes * 60))
    }
    func endFocus(identity: LeagueIdentity) async throws {}
    func friendsFocusing(identity: LeagueIdentity) async throws -> [FocusPresence] { seated }
}

#if DEBUG
extension MockStudyClient {
    /// Launch with `-fakeTable` to put two friends at the table.
    ///
    /// The row is otherwise impossible to look at: it needs two real people on a
    /// bridge that has not been created, and there is no Apple Developer account, so
    /// there cannot be a second person yet. Same two guards as `-unlockAll` — `#if
    /// DEBUG` and a launch argument — so a seated table can never be mistaken for a
    /// real one, and an ordinary run still shows an empty table.
    static let fakeTableArgument = "-fakeTable"

    static func seatedForTesting(now: Date = Date()) -> MockStudyClient {
        MockStudyClient(seated: [
            FocusPresence(playerID: "debug-1", adjective: 0, noun: 0,
                          speciesID: "slime", lookID: "classic", level: 3,
                          endsAt: now.addingTimeInterval(22 * 60)),
            FocusPresence(playerID: "debug-2", adjective: 5, noun: 3,
                          speciesID: "ember", lookID: "classic", level: 2,
                          endsAt: now.addingTimeInterval(38 * 60)),
        ])
    }
}
#endif

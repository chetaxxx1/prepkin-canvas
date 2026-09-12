import Foundation

/// One piece of work from Canvas. Everything past the first four fields is
/// optional, because the cheap cross-course sweep in the extension finds work it
/// has no grade or submission detail for.
struct CanvasItem: Codable, Equatable {
    let id: String
    let title: String
    let courseName: String
    let dueAt: Date?
    var courseId: String?
    var colorHex: String?
    /// When Canvas says you handed it in. The app treats this as done, rather
    /// than trusting a check-off.
    var submittedAt: Date?
    var score: Double?
    var pointsPossible: Double?

    var isSubmitted: Bool { submittedAt != nil }
}

/// A course you are enrolled in, with the grade Canvas currently computes.
struct CanvasCourse: Codable, Equatable, Identifiable {
    let id: String
    let name: String
    var code: String = ""
    /// 0-100, or nil before anything is graded. Nil is a real answer: no grade
    /// yet is not the same as a zero.
    var score: Double?
    var grade: String?
    var colorHex: String?

    init(id: String, name: String, code: String = "", score: Double? = nil,
         grade: String? = nil, colorHex: String? = nil) {
        self.id = id
        self.name = name
        self.code = code
        self.score = score
        self.grade = grade
        self.colorHex = colorHex
    }

    /// `code` has a default, but the synthesized decoder would still demand the
    /// key and throw without it — the same trap `GameState` has a hand-written
    /// decoder to avoid. Only `id` and `name` are genuinely required.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        code = try c.decodeIfPresent(String.self, forKey: .code) ?? ""
        score = try c.decodeIfPresent(Double.self, forKey: .score)
        grade = try c.decodeIfPresent(String.self, forKey: .grade)
        colorHex = try c.decodeIfPresent(String.self, forKey: .colorHex)
    }
}

/// Something the extension did on the laptop and wants paying for: a focus
/// session that finished, or a look bought in its shop. The app's ledger decides
/// whether it happens — this is only the request.
///
/// `at` is what makes it idempotent. The extension keeps re-sending a request
/// until the phone says it applied it, so the same one can arrive many times and
/// must only ever be paid once.
struct BridgeRequest: Codable, Equatable {
    let kind: String
    var taskId: String?
    var minutes: Int?
    var lookId: String?
    var price: Int?
    let at: Date

    /// The ledger key. Same request, same key, one payment ever.
    var ledgerKey: String {
        let stamp = ISO8601DateFormatter().string(from: at)
        switch kind {
        case "focus": return "bridge:focus:\(taskId ?? "-"):\(stamp)"
        case "look":  return "bridge:look:\(lookId ?? "-"):\(stamp)"
        default:      return "bridge:\(kind):\(stamp)"
        }
    }
}

/// One push from the extension.
struct CanvasSnapshot: Equatable {
    var tasks: [CanvasItem] = []
    var courses: [CanvasCourse] = []
    var requests: [BridgeRequest] = []
    var extensionVersion: String? = nil
    var events: [CanvasEvent] = []

    static let minimumExtensionVersion = "0.6.0"

    static func isOlder(_ a: String, than b: String) -> Bool {
        let left = a.split(separator: ".", omittingEmptySubsequences: false).map { Int($0) ?? 0 }
        let right = b.split(separator: ".", omittingEmptySubsequences: false).map { Int($0) ?? 0 }
        for index in 0..<max(left.count, right.count) {
            let l = index < left.count ? left[index] : 0
            let r = index < right.count ? right[index] : 0
            if l != r { return l < r }
        }
        return false
    }
}

/// What the phone publishes back, so the extension's shop can show a real
/// balance instead of a guess.
struct BridgeState: Codable, Equatable {
    var coins: Int
    var owned: [String]
    /// The newest request the phone has actually paid. The extension drops
    /// everything up to here and keeps re-sending the rest — which is why a
    /// finished focus session can no longer fall down the gap between a push the
    /// bridge accepted and a phone that never read it.
    var requestsAppliedAt: Date?
    /// Where the student stands this week, so the laptop can draw the same league
    /// the phone does. Numbers and word-list indexes only, never a typed name.
    var league: BridgeLeague?
    /// The kin on the phone's Home, so the Canvas page shows the same one: a
    /// species id, a star level and a look id. Nothing the student typed.
    var kin: BridgeKin?
}

struct BridgeKin: Codable, Equatable {
    var species: String
    var level: Int
    var skin: String
    /// The tank on Home (`Scene0.id`), so the laptop paints the same water.
    /// Optional on the wire: an older extension ignores it, an older phone omits it.
    var scene: String?
}

/// The league as the laptop sees it. Mirrors `LeagueState` + the last pod board,
/// flattened to plain numbers: the extension has no `LeagueTier`, only an int.
struct BridgeLeague: Codable, Equatable {
    var tier: Int
    var points: Int
    /// Coins needed to leave this tier, `nil` at Deep.
    var bar: Int?
    var week: String
    var pennants: [Int]
    /// The pod board, best first, or `nil` when the student has no pod this week.
    var board: [BridgeLeagueMember]?
}

struct BridgeLeagueMember: Codable, Equatable {
    var you: Bool
    var adjective: Int
    var noun: Int
    var points: Int
    var level: Int
    /// The kin to draw beside the name: a `ChibiSpecies.id` and a look id, the
    /// same two the pod board already carries. Nothing else about anyone.
    var species: String
    var look: String
}

/// The bridge to Canvas data.
protocol CanvasSyncClient {
    func fetchTodo() async throws -> CanvasSnapshot
    /// Publishes the coin balance and owned looks. Silent no-op for clients that
    /// have no bridge behind them.
    func pushState(_ state: BridgeState) async throws
}

extension CanvasSyncClient {
    func pushState(_ state: BridgeState) async throws {}
}

enum BridgeError: Error, Equatable {
    /// No row for this code yet — the extension has not pushed anything. Different
    /// from an empty list, which means "pushed, and there is nothing due".
    case notPairedYet
    case notConfigured
    case server(status: Int)
}

/// Pulls the list the Chrome extension pushed into Supabase.
///
/// Reads through one database function that demands the exact pairing code, so
/// the key shipped in the app cannot list the table or see anyone else's row.
struct SupabaseCanvasClient: CanvasSyncClient {
    let code: String
    /// This phone's own token, handed out once by `claim_code` when the code was
    /// made. The code alone opens nothing: it is only good for the few minutes it
    /// takes a laptop to pair, and reads need this.
    let token: String
    var config: BridgeConfig = .shared
    var session: URLSession = .shared

    private func call(_ function: String, _ body: [String: Any]) async throws -> Data {
        guard config.isConfigured, let endpoint = config.endpoint(function) else {
            throw BridgeError.notConfigured
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
        guard (200..<300).contains(status) else { throw BridgeError.server(status: status) }
        return data
    }

    func fetchTodo() async throws -> CanvasSnapshot {
        try Self.decode(try await call("fetch_todo", ["p_code": code, "p_token": token]))
    }

    func pushState(_ state: BridgeState) async throws {
        var payload: [String: Any] = ["coins": state.coins, "owned": state.owned]
        if let kin = state.kin {
            payload["kin"] = ["species": kin.species, "level": kin.level, "skin": kin.skin]
        }
        if let at = state.requestsAppliedAt {
            payload["requestsAppliedAt"] = Self.stamp(at)
        }
        if let league = state.league,
           let data = try? JSONEncoder().encode(league),
           let json = try? JSONSerialization.jsonObject(with: data) {
            payload["league"] = json
        }
        _ = try await call("push_state", ["p_code": code, "p_token": token, "p_state": payload])
    }

    /// The "paid up to" watermark, with milliseconds. The extension stamps each
    /// request to the millisecond and retires the ones at or before this; a
    /// whole-second stamp here sat just before the request it was answering,
    /// so nothing was ever retired and every push carried the whole queue again.
    static func stamp(_ date: Date) -> String {
        fractionalISO.string(from: date)
    }

    /// Called once, when the app first shows a code. Returns this phone's token,
    /// or nil if somebody already holds that code and a new one should be rolled.
    static func claimCode(_ code: String, config: BridgeConfig = .shared,
                          session: URLSession = .shared) async throws -> String? {
        let client = SupabaseCanvasClient(code: code, token: "", config: config, session: session)
        let data = try await client.call("claim_code", ["p_code": code])
        let text = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        guard text != "null", !text.isEmpty else { return nil }
        return (try? JSONDecoder().decode(String.self, from: data)) ?? text.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
    }

    /// Unpairing takes the row with it, rather than leaving a student's
    /// coursework readable for another month.
    func deletePairing() async throws {
        _ = try await call("delete_pairing", ["p_code": code, "p_token": token])
    }

    /// `null` means no row: stay quiet and leave whatever the app already has.
    /// `[]` means the extension pushed an empty list, which really should clear it.
    ///
    /// Accepts both shapes the bridge has held: a bare array of tasks, which is
    /// what older extensions pushed, and the object with courses alongside.
    static func decode(_ data: Data) throws -> CanvasSnapshot {
        let trimmed = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed != "null", !trimmed.isEmpty else { throw BridgeError.notPairedYet }
        if trimmed.hasPrefix("[") {
            return CanvasSnapshot(tasks: try decoder.decode([WireItem].self, from: data).map(\.item))
        }
        struct WireRequest: Decodable {
            let kind: String
            var taskId: String?
            var minutes: Int?
            var lookId: String?
            var price: Int?
            var at: String?
        }
        struct Payload: Decodable {
            var version: String?
            var tasks: [WireItem]?
            var courses: [CanvasCourse]?
            var requests: [WireRequest]?
            var events: [WireEvent]?
        }
        let payload = try decoder.decode(Payload.self, from: data)
        // A request with an unreadable timestamp has no idempotency key worth
        // trusting, so it is dropped rather than risking paying it twice.
        let requests: [BridgeRequest] = (payload.requests ?? []).compactMap { r in
            guard let at = date(from: r.at) else { return nil }
            return BridgeRequest(kind: r.kind, taskId: r.taskId, minutes: r.minutes,
                                 lookId: r.lookId, price: r.price, at: at)
        }
        return CanvasSnapshot(tasks: (payload.tasks ?? []).map(\.item),
                              courses: payload.courses ?? [], requests: requests,
                              extensionVersion: payload.version,
                              events: (payload.events ?? []).compactMap(\.event))
    }

    /// A course-calendar event. One without a readable start is dropped: there
    /// is no day to put it on.
    private struct WireEvent: Decodable {
        let id: String
        let title: String
        var courseName: String?
        var courseId: String?
        var colorHex: String?
        var startAt: String?
        var endAt: String?
        var allDay: Bool?
        var location: String?
        var url: String?

        var event: CanvasEvent? {
            guard let start = SupabaseCanvasClient.date(from: startAt) else { return nil }
            return CanvasEvent(id: id, title: title, courseName: courseName ?? "",
                               courseId: courseId, colorHex: colorHex, startAt: start,
                               endAt: SupabaseCanvasClient.date(from: endAt),
                               allDay: allDay ?? false, location: location, url: url)
        }
    }

    /// One task as the wire carries it. The extension deliberately keeps an
    /// assignment whose due date it could not read, so dates arrive as raw strings
    /// and are parsed one field at a time — a bad date costs that date, never the
    /// other nine assignments in the push.
    private struct WireItem: Decodable {
        let id: String
        let title: String
        let courseName: String
        var dueAt: String?
        var courseId: String?
        var colorHex: String?
        var submittedAt: String?
        var score: Double?
        var pointsPossible: Double?

        var item: CanvasItem {
            CanvasItem(id: id, title: title, courseName: courseName,
                       dueAt: SupabaseCanvasClient.date(from: dueAt),
                       courseId: courseId, colorHex: colorHex,
                       submittedAt: SupabaseCanvasClient.date(from: submittedAt),
                       score: score, pointsPossible: pointsPossible)
        }
    }

    private static let decoder = JSONDecoder()

    /// Canvas writes dates with and without fractional seconds depending on the
    /// install, so accept both.
    private static let plainISO = ISO8601DateFormatter()
    private static let fractionalISO: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static func date(from text: String?) -> Date? {
        guard let text else { return nil }
        return plainISO.date(from: text) ?? fractionalISO.date(from: text)
    }
}

/// Sample data, used until a pairing code exists so the app is never a blank page.
struct MockCanvasClient: CanvasSyncClient {
    func fetchTodo() async throws -> CanvasSnapshot {
        let cal = Calendar.current
        // 23:59 is Canvas's own end-of-day default and the app reads it as "all
        // day". Every other hour is on the hour, or the screen reads "due 8:59".
        func due(_ days: Int, hour: Int) -> Date {
            cal.date(bySettingHour: hour, minute: hour == 23 ? 59 : 0, second: 0,
                     of: cal.date(byAdding: .day, value: days, to: Date())!)!
        }
        return CanvasSnapshot(
            tasks: [
                CanvasItem(id: "c-101", title: "Ch. 5 Problem Set", courseName: "Physics 13", dueAt: due(0, hour: 23)),
                CanvasItem(id: "c-102", title: "Essay outline", courseName: "Writing 5", dueAt: due(1, hour: 8)),
                CanvasItem(id: "c-103", title: "Week 3 quiz", courseName: "Intro Psych", dueAt: due(2, hour: 15)),
            ],
            courses: [
                CanvasCourse(id: "1", name: "Physics 13", code: "PHYS 13", score: 88.5, grade: "B+", colorHex: "#FF6F61"),
                CanvasCourse(id: "2", name: "Writing 5", code: "WRIT 5", score: 92.0, grade: "A-", colorHex: "#57C79B"),
                CanvasCourse(id: "3", name: "Intro Psych", code: "PSYC 1", score: nil, grade: nil, colorHex: "#9BC8F2"),
            ],
            events: [
                CanvasEvent(id: "e-201", title: "Midterm 1", courseName: "Physics 13", colorHex: "#FF6F61",
                            startAt: due(4, hour: 9), endAt: due(4, hour: 11)),
                CanvasEvent(id: "e-202", title: "Office hours", courseName: "Intro Psych", colorHex: "#9BC8F2",
                            startAt: due(1, hour: 14), endAt: due(1, hour: 15), location: "Moore 202"),
            ])
    }
}

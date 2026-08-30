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

/// One push from the extension.
struct CanvasSnapshot: Equatable {
    var tasks: [CanvasItem] = []
    var courses: [CanvasCourse] = []
}

/// The bridge to Canvas data.
protocol CanvasSyncClient {
    func fetchTodo() async throws -> CanvasSnapshot
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
    var config: BridgeConfig = .shared
    var session: URLSession = .shared

    func fetchTodo() async throws -> CanvasSnapshot {
        guard config.isConfigured, let endpoint = config.endpoint("fetch_todo") else {
            throw BridgeError.notConfigured
        }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(config.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(config.publishableKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["p_code": code])
        request.timeoutInterval = 15

        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else { throw BridgeError.server(status: status) }

        return try Self.decode(data)
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
            return CanvasSnapshot(tasks: try decoder.decode([CanvasItem].self, from: data))
        }
        struct Payload: Decodable {
            var tasks: [CanvasItem]?
            var courses: [CanvasCourse]?
        }
        let payload = try decoder.decode(Payload.self, from: data)
        return CanvasSnapshot(tasks: payload.tasks ?? [], courses: payload.courses ?? [])
    }

    /// Canvas writes due dates with and without fractional seconds depending on
    /// the install, so accept both rather than losing a whole sync to a decimal.
    private static let decoder: JSONDecoder = {
        let plain = ISO8601DateFormatter()
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let text = try decoder.singleValueContainer().decode(String.self)
            if let date = plain.date(from: text) ?? fractional.date(from: text) { return date }
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath,
                                                    debugDescription: "not an ISO 8601 date: \(text)"))
        }
        return d
    }()
}

/// Sample data, used until a pairing code exists so the app is never a blank page.
struct MockCanvasClient: CanvasSyncClient {
    func fetchTodo() async throws -> CanvasSnapshot {
        let cal = Calendar.current
        func due(_ days: Int, hour: Int) -> Date {
            cal.date(bySettingHour: hour, minute: 59, second: 0,
                     of: cal.date(byAdding: .day, value: days, to: Date())!)!
        }
        return CanvasSnapshot(
            tasks: [
                CanvasItem(id: "c-101", title: "Ch. 5 Problem Set", courseName: "AP Physics", dueAt: due(0, hour: 23)),
                CanvasItem(id: "c-102", title: "Essay outline", courseName: "English 11", dueAt: due(1, hour: 8)),
                CanvasItem(id: "c-103", title: "Unit 3 quiz", courseName: "APUSH", dueAt: due(2, hour: 15)),
            ],
            courses: [
                CanvasCourse(id: "1", name: "AP Physics", code: "PHYS-11", score: 88.5, grade: "B+", colorHex: "#FF6F61"),
                CanvasCourse(id: "2", name: "English 11", code: "ENG-11", score: 92.0, grade: "A-", colorHex: "#57C79B"),
                CanvasCourse(id: "3", name: "APUSH", code: "HIST-21", score: nil, grade: nil, colorHex: "#9BC8F2"),
            ])
    }
}

import Foundation

struct Lesson: Identifiable, Decodable, Equatable {
    let id: String
    let emoji: String
    let title: String
    let track: String
    let pages: [String]
    var reward: Int = 20

    private enum CodingKeys: String, CodingKey { case id, emoji, title, track, pages, reward }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        emoji = try c.decode(String.self, forKey: .emoji)
        title = try c.decode(String.self, forKey: .title)
        track = try c.decode(String.self, forKey: .track)
        pages = try c.decode([String].self, forKey: .pages)
        reward = try c.decodeIfPresent(Int.self, forKey: .reward) ?? 20
    }
}

/// Text content lives in JSON in the bundle, not in Swift arrays, so writing a
/// lesson or adding a word is an edit to a data file instead of a code change.
///
/// A missing or malformed file never crashes the app — it falls back to a small
/// built-in set and logs, because bad content should degrade, not take the app down.
enum Content {
    static let lessons: [Lesson] = load("lessons", fallback: fallbackLessons)
    static let wordleAnswers: [String] = load("words", fallback: fallbackWords)
        .map { $0.uppercased() }
        .filter { $0.count == 5 }

    private static func load<T: Decodable>(_ name: String, fallback: T, bundle: Bundle = .main) -> T {
        guard let url = bundle.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            NSLog("Prepkin: \(name).json missing, using the built-in fallback")
            return fallback
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            NSLog("Prepkin: \(name).json is malformed (\(error)), using the built-in fallback")
            return fallback
        }
    }

    private static let fallbackWords = ["SLIME", "STUDY", "FOCUS", "LEARN", "BRAVE"]

    private static let fallbackLessons: [Lesson] = []
}

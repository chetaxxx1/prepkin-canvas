import Foundation

/// What the home-screen widget knows. Written by the app beside every save,
/// read by the widget and by nothing else.
///
/// Small on purpose, and its own shape rather than the save file's: the widget
/// never opens `state.json`, so a schema change in the app cannot break it. Every
/// field is what a line on the widget needs and no more.
struct WidgetSnapshot: Codable, Equatable {
    struct Task: Codable, Equatable, Identifiable {
        let id: String
        let title: String
        let dueAt: Date?
        var done: Bool
        /// Comes back every morning. On a day after the snapshot's own, these are
        /// open again and the rest of the list is unknowable.
        let isDaily: Bool
    }

    static let fileName = "widget.json"

    var speciesID: String
    var stage: Int
    var costumeID: String
    var name: String
    /// The still to draw, e.g. `sprout-ninja-coral-3`.
    var kinAsset: String
    /// The bare coat at the same stage, for a costume the widget has no still of.
    var plainAsset: String
    var coins: Int
    var tasks: [Task]
    var allDone: Bool
    var lastOpenedAt: Date
    /// When the running shift ends. `nil` when none is running or it is paused.
    var shiftEndsAt: Date?
    var checkInHour: Int
    /// Offsets the day-flavour bank so two phones do not read the same line.
    var dayBankSeed: Int
    /// The day the list belongs to, as `yyyy-MM-dd`.
    var day: String
    var writtenAt: Date

    /// The snapshot with the boxes already tapped drawn as done. The app has not
    /// paid them yet — the coin count stays as it was — but the row is ticked and
    /// the line counts it, so a tap is answered on the spot.
    func applying(_ marks: [DoneMark]) -> WidgetSnapshot {
        let ids = Set(marks.map(\.taskID))
        guard !ids.isEmpty else { return self }
        var out = self
        for i in out.tasks.indices where ids.contains(out.tasks[i].id) { out.tasks[i].done = true }
        out.allDone = !out.tasks.isEmpty && out.tasks.allSatisfy(\.done)
        return out
    }

    // MARK: - The file

    static func url(in directory: URL = AppGroup.container) -> URL {
        directory.appendingPathComponent(fileName)
    }

    static func load(from directory: URL = AppGroup.container) -> WidgetSnapshot? {
        guard let data = try? Data(contentsOf: url(in: directory)) else { return nil }
        return try? decoder.decode(WidgetSnapshot.self, from: data)
    }

    func write(to directory: URL = AppGroup.container) {
        guard let data = try? Self.encoder.encode(self) else { return }
        try? data.write(to: Self.url(in: directory), options: .atomic)
    }

    static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}

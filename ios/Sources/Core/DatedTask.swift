import Foundation

/// Where a dated task came from. Canvas work is never a `DatedTask` — it stays a
/// `CanvasItem` and is rebuilt from the feed every sync.
enum TaskSource: String, Codable {
    case mine       // typed in
    case photo      // read off a syllabus or planner page by the scanner
}

/// A task the student put on a day: "Bio quiz on Friday", "essay due 9/22". One
/// row, one date, paid once ever — like Canvas work, and unlike the daily
/// templates that come back every morning.
///
/// The day is stored as a `DayKey`, not a `Date`, so a task typed for the 12th is
/// still on the 12th after a time-zone change. The time is minutes past midnight
/// and is optional; most syllabus rows have none.
struct DatedTask: Identifiable, Codable, Equatable {
    let id: String
    var title: String
    var kind: TaskKind              // .study or .life
    var source: TaskSource
    /// Course name or a short "from photo" note. Shown under the title.
    var detail: String?
    var day: DayKey
    var minute: Int?
    var notes: String?
    var createdAt: Date

    init(id: String = UUID().uuidString, title: String, kind: TaskKind = .study,
         source: TaskSource = .mine, detail: String? = nil, day: DayKey,
         minute: Int? = nil, notes: String? = nil, createdAt: Date = Date()) {
        self.id = "d-\(id)"
        self.title = title
        self.kind = kind
        self.source = source
        self.detail = detail
        self.day = day
        self.minute = minute
        self.notes = notes
        self.createdAt = createdAt
    }

    var allDay: Bool { minute == nil }

    /// The moment it is due, in the given calendar. All-day tasks land on 23:59 so
    /// reminders and "due" sorting treat them as end-of-day, the way Canvas does.
    func dueAt(calendar: Calendar = .current) -> Date? {
        guard let date = day.date(calendar: calendar) else { return nil }
        let m = minute ?? (23 * 60 + 59)
        return calendar.date(bySettingHour: m / 60, minute: m % 60, second: 0, of: date)
    }
}

extension DayKey {
    /// Midnight of this day in the given calendar, or nil for a corrupt key.
    func date(calendar: Calendar = .current) -> Date? {
        let parts = raw.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var c = DateComponents()
        c.year = parts[0]; c.month = parts[1]; c.day = parts[2]
        return calendar.date(from: c)
    }

    func adding(days: Int, calendar: Calendar = .current) -> DayKey {
        guard let base = date(calendar: calendar),
              let moved = calendar.date(byAdding: .day, value: days, to: base) else { return self }
        return DayKey(moved, calendar: calendar)
    }
}

/// Something on a course calendar that happens rather than gets handed in: an
/// exam sitting, a class meeting a teacher added by hand, office hours. Read
/// from Canvas, shown on the calendar, never checked off and never paid.
struct CanvasEvent: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    var courseName: String
    var courseId: String?
    var colorHex: String?
    let startAt: Date
    var endAt: Date?
    var allDay: Bool = false
    var location: String?
    var url: String?

    init(id: String, title: String, courseName: String, courseId: String? = nil,
         colorHex: String? = nil, startAt: Date, endAt: Date? = nil, allDay: Bool = false,
         location: String? = nil, url: String? = nil) {
        self.id = id
        self.title = title
        self.courseName = courseName
        self.courseId = courseId
        self.colorHex = colorHex
        self.startAt = startAt
        self.endAt = endAt
        self.allDay = allDay
        self.location = location
        self.url = url
    }

    /// Every field past the first four is optional on the wire; the synthesized
    /// decoder would demand `allDay` and throw without it.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        courseName = try c.decodeIfPresent(String.self, forKey: .courseName) ?? ""
        courseId = try c.decodeIfPresent(String.self, forKey: .courseId)
        colorHex = try c.decodeIfPresent(String.self, forKey: .colorHex)
        startAt = try c.decode(Date.self, forKey: .startAt)
        endAt = try c.decodeIfPresent(Date.self, forKey: .endAt)
        allDay = try c.decodeIfPresent(Bool.self, forKey: .allDay) ?? false
        location = try c.decodeIfPresent(String.self, forKey: .location)
        url = try c.decodeIfPresent(String.self, forKey: .url)
    }
}

import Foundation

// What a friend did today, and the sentence under the whole group.
//
// Four small integers cross the wire and nothing else — `daily_stats` in
// bridge/schema-friends.sql holds tasks, focus minutes, lessons and games, capped,
// and there is no column for what a lesson was called or what a task said. That is
// the whole privacy story of this feature: a friend learns how much you worked,
// never what you worked on.
//
// Everything in this file is pure. It reads a ledger and returns strings, so every
// rule about what is and is not said out loud can be walked by a test.

/// One day's work, as four counts.
struct TodayCounts: Equatable, Codable {
    var tasks: Int
    var focusMinutes: Int
    var lessons: Int
    var games: Int

    /// The six daily boards. `numberLine` is deliberately not among them: it is not
    /// keyed on `PlayDeal.number`, so it is not one of the six a day contains, and
    /// counting it would push this past the six the bridge will accept.
    static let gameReasons: Set<CoinReason> = [.wordle, .balance, .pearls, .trace, .sort, .weave]

    init(tasks: Int = 0, focusMinutes: Int = 0, lessons: Int = 0, games: Int = 0) {
        self.tasks = max(0, tasks)
        self.focusMinutes = max(0, focusMinutes)
        self.lessons = max(0, lessons)
        self.games = max(0, games)
    }

    /// Read straight off the ledger, which already holds every one of these with a
    /// day on it. Nothing here keeps its own counter, for the same reason
    /// `WeekStats` does not: a second counter is a second thing that can drift.
    init(ledger: Ledger, day: DayKey) {
        var tasks = 0, focus = 0, lessons = 0
        var games: Set<CoinReason> = []
        for e in ledger.entries where e.day == day {
            switch e.reason {
            case .task: tasks += e.units
            case .focus: focus += e.units
            case .lesson: lessons += e.units
            default:
                if TodayCounts.gameReasons.contains(e.reason) { games.insert(e.reason) }
            }
        }
        // Distinct boards, not lines: one puzzle a day means the two agree today,
        // and if that ever stops being true this is the number that stays inside
        // the range the bridge allows.
        self.init(tasks: tasks, focusMinutes: focus, lessons: lessons, games: games.count)
    }

    /// Nothing happened. **A row of four zeros means the same as no row at all** —
    /// the push skips an empty day, but a phone that saved a minute after midnight
    /// may already have written one, and a zero must never reach a screen.
    var isEmpty: Bool { tasks == 0 && focusMinutes == 0 && lessons == 0 && games == 0 }

    /// A run of days, folded in one pass over the ledger.
    ///
    /// **Grouped by day, not summed flat.** Games are counted as distinct boards
    /// within a day, so folding the whole week at once would count somebody who
    /// played the word every morning as having solved one game, not seven.
    ///
    /// One pass matters: this is read from a SwiftUI body, and a day at a time
    /// would walk the whole ledger once per day on every redraw.
    static func week(ledger: Ledger, days: Set<DayKey>) -> TodayCounts {
        var tasks = 0, focus = 0, lessons = 0
        var gamesByDay: [DayKey: Set<CoinReason>] = [:]
        for e in ledger.entries where days.contains(e.day) {
            switch e.reason {
            case .task: tasks += e.units
            case .focus: focus += e.units
            case .lesson: lessons += e.units
            default:
                if gameReasons.contains(e.reason) { gamesByDay[e.day, default: []].insert(e.reason) }
            }
        }
        return TodayCounts(tasks: tasks, focusMinutes: focus, lessons: lessons,
                           games: gamesByDay.values.reduce(0) { $0 + $1.count })
    }

    static func + (a: TodayCounts, b: TodayCounts) -> TodayCounts {
        TodayCounts(tasks: a.tasks + b.tasks, focusMinutes: a.focusMinutes + b.focusMinutes,
                    lessons: a.lessons + b.lessons, games: a.games + b.games)
    }

    /// The wire keys `push_today` and `fetch_today` use.
    private enum CodingKeys: String, CodingKey { case tasks, focus, lessons, games }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(tasks: try c.decodeIfPresent(Int.self, forKey: .tasks) ?? 0,
                  focusMinutes: try c.decodeIfPresent(Int.self, forKey: .focus) ?? 0,
                  lessons: try c.decodeIfPresent(Int.self, forKey: .lessons) ?? 0,
                  games: try c.decodeIfPresent(Int.self, forKey: .games) ?? 0)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(tasks, forKey: .tasks)
        try c.encode(focusMinutes, forKey: .focus)
        try c.encode(lessons, forKey: .lessons)
        try c.encode(games, forKey: .games)
    }
}

/// One row of `fetch_today`: whose day it is, which day, and the four counts.
struct DayRow: Equatable, Decodable {
    let playerID: String
    let day: DayKey
    let counts: TodayCounts

    private enum CodingKeys: String, CodingKey { case id, day }

    init(playerID: String, day: DayKey, counts: TodayCounts) {
        self.playerID = playerID
        self.day = day
        self.counts = counts
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        playerID = try c.decodeIfPresent(String.self, forKey: .id) ?? ""
        day = try c.decodeIfPresent(DayKey.self, forKey: .day) ?? DayKey(raw: "")
        counts = try TodayCounts(from: decoder)
    }
}

/// Four numbers in, English out.
enum TodayLines {
    /// How many lines a friend row is allowed. Three is the design brief's number,
    /// and it is also the point where a list of things somebody did stops reading
    /// as news and starts reading as a report card.
    static let maximum = 3

    /// What a friend did today, longest-standing habit first.
    ///
    /// **A zero is never a line.** A field at nothing is skipped, not written as
    /// "0 tasks", and a day with nothing in it has no lines at all rather than an
    /// empty state — "no session" and "hasn't studied" are the same sentence, and
    /// this app does not write the second one.
    ///
    /// The order is fixed and is not sorted by size. Sorting would turn a list of
    /// things somebody did into a ranking of how much they did.
    static func lines(_ c: TodayCounts) -> [String] {
        var out: [String] = []
        if c.focusMinutes > 0 { out.append("Focused \(clock(c.focusMinutes))") }
        if c.tasks > 0 { out.append("Finished \(c.tasks) \(c.tasks == 1 ? "task" : "tasks")") }
        if c.lessons > 0 { out.append("Read \(c.lessons) \(c.lessons == 1 ? "lesson" : "lessons")") }
        if c.games > 0 {
            out.append(c.games >= 6 ? "Solved all six"
                                    : "Solved \(c.games) \(c.games == 1 ? "game" : "games")")
        }
        return Array(out.prefix(maximum))
    }

    /// "45 min", "1h", "1h 20m". Exact, because a friend row is about one person.
    static func clock(_ minutes: Int) -> String {
        guard minutes >= 60 else { return "\(minutes) min" }
        let h = minutes / 60, m = minutes % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }

    /// The one sentence under the whole tab: "You and 2 friends: 41 tasks, 6h focus,
    /// 6 games."
    ///
    /// **The headcount is who is in the number, not the size of the friend list.**
    /// Pass only friends who actually have a row for the week — somebody who never
    /// turned sharing on contributes nothing, and counting them would make the
    /// sentence a claim about people who are not in it.
    ///
    /// `nil` when there is nobody to be together with, or when the week is all
    /// zeros. The card is absent then, never an empty one.
    ///
    /// Three parts, matching the design brief. Lessons are left to the per-friend
    /// lines: three numbers is a sentence and four is a dashboard, which PRODUCT.md
    /// bans by name. No coins on it, ever — `design/SOCIAL-PLAN.md` F5.
    static func weekly(mine: TodayCounts, friends: [TodayCounts]) -> String? {
        guard !friends.isEmpty else { return nil }
        let total = friends.reduce(mine, +)
        guard !total.isEmpty else { return nil }

        var parts: [String] = []
        if total.tasks > 0 { parts.append("\(total.tasks) \(total.tasks == 1 ? "task" : "tasks")") }
        if total.focusMinutes > 0 { parts.append("\(roundHours(total.focusMinutes)) focus") }
        if total.games > 0 { parts.append("\(total.games) \(total.games == 1 ? "game" : "games")") }
        guard !parts.isEmpty else { return nil }

        let who = friends.count == 1 ? "1 friend" : "\(friends.count) friends"
        return "You and \(who): \(parts.joined(separator: ", "))"
    }

    /// Whole hours for the group sentence, rounded down so the total is never more
    /// than the week actually held. Under an hour it stays in minutes.
    static func roundHours(_ minutes: Int) -> String {
        minutes >= 60 ? "\(minutes / 60)h" : "\(minutes) min"
    }

    /// One friend's today out of a fetched window.
    ///
    /// **The newest row wins, not the row whose date matches yours.** `day` is each
    /// sender's own local day, so a friend twelve hours ahead is already writing
    /// tomorrow's date: matching on your date would leave their lines empty all day
    /// and then show them a day late. Same disease as `SOCIAL-PLAN.md` F2, which the
    /// board avoids by keying on the puzzle number; a day row has no puzzle number,
    /// so it takes the latest instead.
    static func newest(_ rows: [DayRow], for playerID: String) -> TodayCounts? {
        rows.filter { $0.playerID == playerID }
            .max { $0.day < $1.day }
            .map(\.counts)
    }
}

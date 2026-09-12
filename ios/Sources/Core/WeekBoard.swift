import Foundation

// The weekly board: you and your friends, one list, one week.
//
// Scored the way an Apple Watch competition is scored, ranked the way any board is,
// and settled on Monday with a pennant for the top three. Everything in this file
// is pure — it reads counts and returns rows — so every rule can be walked by a test
// with no view and no network in it.
//
// **Why the score is capped per day.** Apple gives at most 600 points a day in a
// competition, so one enormous Saturday cannot buy the week; you win a week by
// turning up. Here the cap is 400: four counts, each worth up to 100 for a day in
// which it was "closed". That is also the honour-system answer the last council
// wanted: every count is a check-off nobody verifies, and a forged day is worth
// exactly what a real one is — a hundred a ring, and no more.
//
// **What crosses the wire.** Nothing new. The four counts in `daily_stats` are what
// friends already share (`design/FRIENDS-BUILD-PLAN.md`), and the board is built on
// the phone from the rows `fetch_today` already sends. No coins, no free text, and
// no row for anybody who has not turned sharing on.

// MARK: - The score

/// How a day turns into points. Four rings, a hundred each, capped.
enum WeekPoints {
    static let perRing = 100
    /// Four rings closed. The most any day can be worth.
    static let dayMax = 4 * perRing

    /// What closes a ring, sized against the real day: three study tasks is the
    /// Home list's own default, 45 minutes is the longest shift, a lesson is a
    /// lesson, and three games is half the daily six.
    static let taskGoal = 3
    static let focusGoal = 45
    static let lessonGoal = 1
    static let gameGoal = 3

    static func ring(_ n: Int, goal: Int) -> Int {
        guard goal > 0, n > 0 else { return 0 }
        return min(perRing, n * perRing / goal)
    }

    static func day(_ c: TodayCounts) -> Int {
        ring(c.tasks, goal: taskGoal)
            + ring(c.focusMinutes, goal: focusGoal)
            + ring(c.lessons, goal: lessonGoal)
            + ring(c.games, goal: gameGoal)
    }

    /// A week is its days added up, each already capped. Folding the week's counts
    /// first and scoring once would let a seven-task Sunday close Monday's ring.
    static func week(_ days: [TodayCounts]) -> Int {
        days.reduce(0) { $0 + day($1) }
    }
}

// MARK: - The week's days

extension WeekKey {
    /// The seven days of this week, Monday first. Empty when the key is malformed.
    ///
    /// Same ISO calendar the key was built with, so a phone that changed region
    /// mid-week still puts Monday where the key says it is.
    func days(calendar: Calendar = WeekKey.calendar) -> [DayKey] {
        let parts = raw.components(separatedBy: "-W").compactMap { Int($0) }
        guard parts.count == 2,
              let monday = calendar.date(from: DateComponents(
                weekday: 2, weekOfYear: parts[1], yearForWeekOfYear: parts[0]))
        else { return [] }
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: monday).map { DayKey($0, calendar: calendar) }
        }
    }
}

extension TodayCounts {
    /// A run of days, one entry per day that had anything in it. One pass over the
    /// ledger, for the same reason `week(ledger:days:)` is one pass.
    static func byDay(ledger: Ledger, days: Set<DayKey>) -> [DayKey: TodayCounts] {
        var tasks: [DayKey: Int] = [:], focus: [DayKey: Int] = [:], lessons: [DayKey: Int] = [:]
        var games: [DayKey: Set<CoinReason>] = [:]
        for e in ledger.entries where days.contains(e.day) {
            switch e.reason {
            case .task: tasks[e.day, default: 0] += e.units
            case .focus: focus[e.day, default: 0] += e.units
            case .lesson: lessons[e.day, default: 0] += e.units
            default:
                if gameReasons.contains(e.reason) { games[e.day, default: []].insert(e.reason) }
            }
        }
        var out: [DayKey: TodayCounts] = [:]
        for d in Set(tasks.keys).union(focus.keys).union(lessons.keys).union(games.keys) {
            out[d] = TodayCounts(tasks: tasks[d] ?? 0, focusMinutes: focus[d] ?? 0,
                                 lessons: lessons[d] ?? 0, games: games[d]?.count ?? 0)
        }
        return out
    }
}

// MARK: - Who is on it

/// One person on the board for one week. Built, never fetched: the wire carries
/// days, and this is what a week of them adds up to.
struct BoardMember: Identifiable, Equatable {
    /// A friend's id on the bridge, or `BoardMember.youID` for this phone.
    let id: String
    let name: String
    let speciesID: String
    let lookID: String
    let level: Int
    /// The week's points, each day capped.
    let points: Int
    /// The week's four counts added up, for the quest.
    let counts: TodayCounts
    let isYou: Bool
    let onShiftUntil: Date?

    static let youID = "you"
}

/// A member with the place the ranking gave it.
struct BoardRow: Identifiable, Equatable {
    let member: BoardMember
    /// 1 is the top. Ties share a place, so two people on 610 are both 2nd and the
    /// next person is 4th — standard competition ranking, the only kind where
    /// somebody on the same score as you is never drawn above you.
    let place: Int

    var id: String { member.id }
}

/// Where a finished week left you, kept on the week's receipt.
struct BoardPlacement: Codable, Equatable {
    let place: Int
    /// How many were on the board, you included. A board of one is not a contest,
    /// and nothing below counts it as one.
    let of: Int

    /// Gold, silver or bronze, when there was somebody to place against.
    var medal: Int? { of >= 2 && (1...3).contains(place) ? place : nil }
}

enum WeekBoard {
    /// The rows, best first. Deterministic on ties: same points sort by name, then
    /// id, so a board never shuffles under a reader's thumb between two fetches.
    static func rank(_ members: [BoardMember]) -> [BoardRow] {
        let sorted = members.sorted {
            if $0.points != $1.points { return $0.points > $1.points }
            if $0.name != $1.name { return $0.name < $1.name }
            return $0.id < $1.id
        }
        var rows: [BoardRow] = []
        var place = 0
        for (i, m) in sorted.enumerated() {
            if i == 0 || m.points != sorted[i - 1].points { place = i + 1 }
            rows.append(BoardRow(member: m, place: place))
        }
        return rows
    }

    /// Who this week's board holds, out of the rows the bridge sent.
    ///
    /// **A friend is on the board only with at least one row inside the week.** A
    /// friend who has sharing off sends no rows, and so does a friend who has not
    /// started yet; the two look the same and are handled the same — listed
    /// separately, never drawn as a zero somebody has to explain. You are always
    /// on your own board, sharing or not: nobody else can see you until you share,
    /// but your own week is your own.
    static func members(you: BoardMember, friends: [Friend], rows: [DayRow], week: WeekKey)
        -> (on: [BoardMember], off: [Friend]) {
        let days = Set(week.days())
        var byFriend: [String: [TodayCounts]] = [:]
        for r in rows where days.contains(r.day) {
            byFriend[r.playerID, default: []].append(r.counts)
        }
        var on: [BoardMember] = [you]
        var off: [Friend] = []
        for f in friends {
            guard let theirs = byFriend[f.id], !theirs.isEmpty else { off.append(f); continue }
            on.append(BoardMember(id: f.id, name: f.displayName, speciesID: f.speciesID,
                                  lookID: f.lookID, level: f.level,
                                  points: WeekPoints.week(theirs),
                                  counts: theirs.reduce(TodayCounts(), +),
                                  isYou: false, onShiftUntil: f.onShiftUntil))
        }
        return (on, off)
    }

    /// Your placement on a finished board, or `nil` when you were not on it.
    static func placement(of rows: [BoardRow]) -> BoardPlacement? {
        guard let mine = rows.first(where: { $0.member.isYou }) else { return nil }
        return BoardPlacement(place: mine.place, of: rows.count)
    }
}

// MARK: - The group quest

/// One goal a week for everybody on the board, Duolingo's Friends Quest for the
/// whole group instead of a pair. Everyone contributes, everyone keeps the pennant.
///
/// Sized by headcount rather than fixed, because a group of two and a group of
/// nine are not the same week: ten tasks a head is three light days each, and the
/// bar grows when a friend joins the board and shrinks when one is not on it.
enum GroupQuest {
    enum Kind: Int, CaseIterable, Codable {
        case tasks, focus, lessons, games

        /// Per person. Sized against the same day the ring goals are.
        var perPerson: Int {
            switch self {
            case .tasks: return 10
            case .focus: return 150
            case .lessons: return 3
            case .games: return 6
            }
        }

        func count(in c: TodayCounts) -> Int {
            switch self {
            case .tasks: return c.tasks
            case .focus: return c.focusMinutes
            case .lessons: return c.lessons
            case .games: return c.games
            }
        }
    }

    /// The kind rotates with the ISO week number, so two phones on the same week
    /// agree without a server telling them.
    static func kind(for week: WeekKey) -> Kind {
        let n = Int(week.raw.components(separatedBy: "-W").last ?? "") ?? 0
        return Kind.allCases[n % Kind.allCases.count]
    }

    struct Status: Equatable {
        let week: WeekKey
        let kind: Kind
        let goal: Int
        let progress: Int
        let headcount: Int
        var cleared: Bool { progress >= goal }
    }

    /// `nil` with nobody to quest with: a goal for one is a to-do, not a quest.
    static func status(week: WeekKey, members: [BoardMember]) -> Status? {
        guard members.count >= 2 else { return nil }
        let kind = kind(for: week)
        let progress = members.reduce(0) { $0 + kind.count(in: $1.counts) }
        return Status(week: week, kind: kind, goal: kind.perPerson * members.count,
                      progress: progress, headcount: members.count)
    }

    /// "Finish 60 tasks between the six of you."
    static func line(_ s: Status) -> String {
        let who = "between the \(spelled(s.headcount)) of you"
        switch s.kind {
        case .tasks: return "Finish \(s.goal) tasks \(who)"
        case .focus: return "Focus \(TodayLines.roundHours(s.goal)) \(who)"
        case .lessons: return "Read \(s.goal) lessons \(who)"
        case .games: return "Solve \(s.goal) games \(who)"
        }
    }

    /// "37 / 60", or "2h 10m / 15h" for focus.
    static func progressLine(_ s: Status) -> String {
        switch s.kind {
        case .focus: return "\(TodayLines.clock(s.progress)) / \(TodayLines.roundHours(s.goal))"
        default: return "\(s.progress) / \(s.goal)"
        }
    }

    /// The person to nudge: the lowest contributor who is not you. `nil` when
    /// everybody but you is ahead of you, which is not a moment to nudge anyone.
    static func nudge(_ s: Status, members: [BoardMember]) -> BoardMember? {
        let others = members.filter { !$0.isYou }
        guard let mine = members.first(where: \.isYou),
              let least = others.min(by: { s.kind.count(in: $0.counts) < s.kind.count(in: $1.counts) }),
              s.kind.count(in: least.counts) < s.kind.count(in: mine.counts)
        else { return nil }
        return least
    }

    private static func spelled(_ n: Int) -> String {
        let words = ["", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]
        return n < words.count ? words[n] : "\(n)"
    }
}

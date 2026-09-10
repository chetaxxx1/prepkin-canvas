import Foundation

/// How the Calendar list is grouped — Things 3's "Upcoming", as rules rather
/// than as layout, so they can be tested without a screen.
///
/// Three of them:
///
/// 1. **Only days with something on them exist.** A run of empty days is one
///    folded line; today never folds, because it is where the student is.
/// 2. **Near days say their weekday, far days say their month.** Today and
///    tomorrow say so in words. Past a fortnight a weekday stops helping and the
///    month takes over.
/// 3. **In the week that holds today, days already gone are dropped.** Anything
///    still open from them is in the Still counts group at the top; anything
///    finished is not what is coming. A week entirely in the past keeps them.
enum Upcoming {

    /// The two strings a day header draws.
    struct Heading: Equatable {
        let lead: String
        let date: String
        let isToday: Bool
    }

    enum Block: Identifiable, Equatable {
        case day(DayKey)
        case folded([DayKey])

        var id: String {
            switch self {
            case .day(let d): return d.raw
            case .folded(let run): return "fold-\(run.first?.raw ?? "")"
            }
        }
    }

    /// Past this many days a weekday name stops telling a student anything.
    static let farOut = 14

    static func heading(for day: DayKey, today: DayKey = .today(),
                        calendar: Calendar = .current) -> Heading {
        let date = day.date(calendar: calendar) ?? Date()
        let short = date.formatted(.dateTime.month(.abbreviated).day())
        if day == today { return Heading(lead: "Today", date: short, isToday: true) }
        if day == today.adding(days: 1, calendar: calendar) {
            return Heading(lead: "Tomorrow", date: short, isToday: false)
        }
        if day < today.adding(days: farOut, calendar: calendar) {
            return Heading(lead: date.formatted(.dateTime.weekday(.wide)), date: short, isToday: false)
        }
        return Heading(lead: date.formatted(.dateTime.month(.wide)), date: short, isToday: false)
    }

    static func blocks(_ days: [DayKey], today: DayKey = .today(),
                       dropPast: Bool, isEmpty: (DayKey) -> Bool) -> [Block] {
        var out: [Block] = []
        var run: [DayKey] = []
        func flush() {
            if !run.isEmpty { out.append(.folded(run)); run = [] }
        }
        for d in days {
            if d < today && dropPast { flush(); continue }
            if d != today && isEmpty(d) { run.append(d); continue }
            flush()
            out.append(.day(d))
        }
        flush()
        return out
    }

    /// Everything from the last fortnight that is open and was due, oldest
    /// first. Todoist and ClickUp both group overdue at the top; ours is one
    /// group called "Still counts", and a Canvas row and a typed row land in it
    /// the same way because both come off the same day list.
    static func stillCounts(today: DayKey = .today(), lookBack: Int = farOut,
                            calendar: Calendar = .current,
                            tasks: (DayKey) -> [DailyTask]) -> [DailyTask] {
        (1...lookBack).reversed()
            .flatMap { tasks(today.adding(days: -$0, calendar: calendar)) }
            .filter { !$0.done && !$0.isLocked }
    }

    /// "Thu – Sun · free", or "Thu · free" for one day.
    static func foldLabel(_ days: [DayKey], calendar: Calendar = .current) -> String {
        let names = days.compactMap {
            $0.date(calendar: calendar)?.formatted(.dateTime.weekday(.abbreviated))
        }
        guard let first = names.first else { return "free" }
        if names.count == 1 { return "\(first) · free" }
        return "\(first) – \(names[names.count - 1]) · free"
    }
}

import Foundation

/// Why coins moved. Positive amounts are earnings, negative are purchases.
enum CoinReason: String, Codable {
    case task, focus, wordle, lesson, numberLine   // earn
    case balance, pearls, trace, sort, weave    // earn, the Play pool
    case ladder, thread                     // retired 2026-09-10; kept so old ledgers decode
    case upgrade, species, scene            // spend
    case legacy                             // opening balance carried in from an old save
}

/// One line in the coin history.
struct CoinEntry: Codable, Equatable, Identifiable {
    /// Idempotency key, e.g. `task:l-1:2026-08-29`. Posting a key the ledger already
    /// holds is a no-op, so no path in the app can pay for the same thing twice —
    /// not a double tap, not a retried sync, not a re-entered screen.
    let key: String
    let amount: Int
    let reason: CoinReason
    /// How many of the thing: minutes for a focus session, 1 for a task. Weekly
    /// stats add these up instead of keeping their own counters that can drift.
    let units: Int
    let day: DayKey
    let at: Date

    var id: String { key }

    init(key: String, amount: Int, reason: CoinReason, units: Int = 1, day: DayKey, at: Date = Date()) {
        self.key = key
        self.amount = amount
        self.reason = reason
        self.units = units
        self.day = day
        self.at = at
    }
}

/// Rolled-up counts for one week, computed from the ledger rather than stored.
struct WeekStats: Equatable {
    var tasksDone = 0
    var coinsEarned = 0
    var focusMinutes = 0
    var wordleSolved = 0
    var lessonsDone = 0
}

/// The coin history. `balance` is the sum of every line, so the number on screen
/// can always be explained by the rows behind it.
///
/// Append-only, with one deliberate exception: `revoke` deletes a line when the user
/// un-checks a task. That is a correction of a mistake, not a transaction, and it has
/// to release the idempotency key so the task can be checked again.
struct Ledger: Codable, Equatable {
    /// Balance folded in from lines old enough to have been compacted away.
    private(set) var openingBalance: Int
    private(set) var entries: [CoinEntry]
    /// Kept in sync on every mutation and recomputed after decoding, so reading it
    /// in a SwiftUI body doesn't walk the whole history.
    private(set) var balance: Int

    /// Lines older than this are folded into `openingBalance`. Well past any window
    /// in which a day-scoped key could still be claimed again.
    static let compactAfterDays = 90
    /// Fold only when there is a real amount of history to fold.
    static let compactThreshold = 400

    init(openingBalance: Int = 0, entries: [CoinEntry] = []) {
        self.openingBalance = openingBalance
        self.entries = entries
        balance = openingBalance + entries.reduce(0) { $0 + $1.amount }
    }

    // MARK: - Reading

    func isClaimed(_ key: String) -> Bool { entries.contains { $0.key == key } }

    func stats(inWeekOf date: Date = Date(), calendar: Calendar = .current) -> WeekStats {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: date) else { return WeekStats() }
        var s = WeekStats()
        for e in entries where week.contains(e.at) {
            if e.amount > 0 { s.coinsEarned += e.amount }
            switch e.reason {
            case .task: s.tasksDone += e.units
            case .focus: s.focusMinutes += e.units
            case .wordle: s.wordleSolved += e.units
            case .lesson: s.lessonsDone += e.units
            default: break
            }
        }
        return s
    }

    /// Coins earned inside one week, keyed off each line's protected `day` rather
    /// than its wall-clock `at`.
    ///
    /// `stats(inWeekOf:)` above uses `at` and the device calendar, which is right for
    /// a soft display on Home. League points decide a promotion, so they key off the
    /// same day the clock-rollback guard already wrote — otherwise winding the date
    /// back would move earnings into a week that has not happened yet. Spending is
    /// skipped, as it is there: points are earned, never held.
    func coinsEarned(inWeek week: WeekKey) -> Int {
        entries.reduce(0) { sum, e in
            guard e.amount > 0, WeekKey(e.day) == week else { return sum }
            return sum + e.amount
        }
    }

    // MARK: - Writing

    /// Adds a line. Returns false and changes nothing if the key was already used,
    /// or if a purchase would overdraw the balance.
    @discardableResult
    mutating func post(_ entry: CoinEntry) -> Bool {
        guard !isClaimed(entry.key) else { return false }
        guard balance + entry.amount >= 0 else { return false }
        entries.append(entry)
        balance += entry.amount
        compactIfNeeded()
        return true
    }

    /// Removes the line with this key and gives back its amount. Used only for undo.
    /// Refused when the coins are already spent — taking back an earning may never
    /// push the balance below zero, so in that case the line simply stands.
    @discardableResult
    mutating func revoke(_ key: String) -> Bool {
        guard let i = entries.firstIndex(where: { $0.key == key }),
              balance - entries[i].amount >= 0 else { return false }
        balance -= entries[i].amount
        entries.remove(at: i)
        return true
    }

    /// Folds old lines into the opening balance so the save file can't grow forever.
    private mutating func compactIfNeeded(now: Date = Date()) {
        guard entries.count > Self.compactThreshold,
              let cutoff = Calendar.current.date(byAdding: .day, value: -Self.compactAfterDays, to: now)
        else { return }
        let old = entries.filter { $0.at < cutoff }
        guard !old.isEmpty else { return }
        openingBalance += old.reduce(0) { $0 + $1.amount }
        entries.removeAll { $0.at < cutoff }
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey { case openingBalance, entries }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        openingBalance = try c.decodeIfPresent(Int.self, forKey: .openingBalance) ?? 0
        entries = try c.decodeIfPresent([CoinEntry].self, forKey: .entries) ?? []
        balance = openingBalance + entries.reduce(0) { $0 + $1.amount }
    }
}

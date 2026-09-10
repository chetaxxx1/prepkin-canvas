import Foundation

/// The two strings Home's header decides for itself: the words beside the star
/// pips, and the quiet line under the goals row.
///
/// They live here rather than inside `HomeView` so a test can read them without
/// building a view. Both are pure — a level and a balance in, a sentence out.
enum HomeCopy {

    /// The words next to the star pips.
    ///
    /// The pips already draw the count, so these never repeat it. At the top of
    /// the ladder there is nothing left to say but that.
    static func levelLabel(nextUpgradeCost: Int?, coins: Int) -> String {
        guard let cost = nextUpgradeCost else { return "Fully grown" }
        let left = max(0, cost - coins)
        if left == 0 { return "Ready for the next star" }
        return "\(left) to the next"
    }

    /// How stale a list has to be before Home mentions its age. Under an hour it
    /// is just today's list, and saying so is noise.
    static let staleAfter: TimeInterval = 3600

    /// The line under the goals row, or `nil` when there is nothing true to add.
    ///
    /// Empty list: say where the emptiness came from, because the goals row
    /// already says "Nothing due today" and a second copy of that is worse than
    /// the blank space it would fill. Full list: only worth a line once the
    /// laptop's list is old enough to wonder about.
    static func underGoals(hasTasks: Bool, lastList: Date?, now: Date = Date()) -> String? {
        func age(olderThan minimum: TimeInterval) -> String? {
            guard let at = lastList, now.timeIntervalSince(at) >= minimum else { return nil }
            return at.formatted(.relative(presentation: .numeric, unitsStyle: .narrow))
        }
        if !hasTasks { return age(olderThan: 0).map { "Last list from your laptop \($0)." } }
        return age(olderThan: staleAfter).map { "From your laptop \($0)." }
    }
}

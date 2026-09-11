import Foundation

/// Things that happened once and stay. Finch's quests list without the hints and
/// without the counts: a done row shows the day it happened, an undone row shows
/// the words. Never a "?", never "3/5", never a reward for finishing the list.
///
/// A save written before this list existed cannot know the dates, so a first that
/// evidently already happened is kept as done with no date rather than stamped
/// with the day the app was updated — a date the student would know was wrong.
struct Firsts: Codable, Equatable {
    /// Id to the moment it happened.
    var dated: [String: Date] = [:]
    /// Ids that happened before the list existed. Done, date unknown.
    var undated: Set<String> = []

    static let costume = "costume"
    static let scene = "scene"
    static let friend = "friend"
    static let shift = "shift"
    /// Three stars is a first per kin: this one grew all the way.
    static func threeStars(_ speciesID: String) -> String { "stars:\(speciesID)" }

    func isDone(_ id: String) -> Bool { dated[id] != nil || undated.contains(id) }
    func date(_ id: String) -> Date? { dated[id] }

    /// Marks a first, once. A second call changes nothing: a first is a first.
    @discardableResult
    mutating func mark(_ id: String, at now: Date = Date()) -> Bool {
        guard !isDone(id) else { return false }
        dated[id] = now
        return true
    }

    /// For a save older than the list: done, date unknown.
    mutating func markUndated(_ id: String) {
        guard !isDone(id) else { return }
        undated.insert(id)
    }

    /// What an older save already did, read off the save itself. Only things the
    /// save can prove: a costume on a kin, a bought tank, a friend in the list,
    /// focus minutes on the record, a kin at three stars.
    static func inferred(from state: GameState) -> Firsts {
        var f = Firsts()
        if state.owned.contains(where: { Costume.ids.contains($0.skinID) }) { f.markUndated(costume) }
        if state.ownedScenes.contains(where: { $0 != Scene0.all[0].id }) { f.markUndated(scene) }
        if !state.friends.isEmpty { f.markUndated(friend) }
        if state.lifetime.focusMinutes > 0 { f.markUndated(shift) }
        for kin in state.owned where kin.level >= 3 { f.markUndated(threeStars(kin.speciesID)) }
        return f
    }

    // MARK: - The card

    struct Row: Identifiable, Equatable {
        let id: String
        let title: String
        let done: Bool
        let date: Date?
    }

    /// The five rows on a kin's card, in the brief's order. Four are shared across
    /// the account; the last is this kin's own.
    func rows(for speciesID: String) -> [Row] {
        let shared: [(String, String)] = [
            (Self.costume, "First costume"),
            (Self.scene, "First scene"),
            (Self.friend, "First friend"),
            (Self.shift, "First shift"),
        ]
        var out = shared.map { Row(id: $0.0, title: $0.1, done: isDone($0.0), date: date($0.0)) }
        let stars = Self.threeStars(speciesID)
        out.append(Row(id: stars, title: "Three stars", done: isDone(stars), date: date(stars)))
        return out
    }
}

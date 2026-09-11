import Foundation

/// How long you and a kin have been at it, as a word. Finch's friendship level
/// (Pals, Buddies, Best Budz…) without the points: five words that only go up,
/// earned by days together and care taps, never lost, never a bar.
///
/// The rule is one line. Days since the kin arrived, plus one day for every four
/// care taps, capped at thirty days of care in all — so care moves the early
/// stages and time moves the late ones. Nothing moves a stage down: the pure rule
/// only climbs as either input climbs, and `OwnedChibi.stageReached` keeps the
/// high-water mark in case the clock is wound back.
enum FriendshipStage: Int, Codable, CaseIterable, Comparable {
    case justMet = 0, tankmates, buddies, besties, oldFriends

    var name: String {
        switch self {
        case .justMet: return "Just met"
        case .tankmates: return "Tankmates"
        case .buddies: return "Buddies"
        case .besties: return "Besties"
        case .oldFriends: return "Old friends"
        }
    }

    /// Elapsed days at which each stage arrives with no care at all.
    var arrivesOnDay: Int {
        switch self {
        case .justMet: return 0
        case .tankmates: return 3
        case .buddies: return 14
        case .besties: return 60
        case .oldFriends: return 180
        }
    }

    /// Care taps that count as one day together.
    static let tapsPerDay = 4
    /// The most days care can add. Old friends still takes 150 real days.
    static let careDaysCap = 30

    /// `days` is elapsed days since adoption: 0 on the day the kin arrived.
    static func stage(days: Int, careTaps: Int) -> FriendshipStage {
        let score = max(0, days) + min(max(0, careTaps) / tapsPerDay, careDaysCap)
        return allCases.last { score >= $0.arrivesOnDay } ?? .justMet
    }

    static func < (a: FriendshipStage, b: FriendshipStage) -> Bool { a.rawValue < b.rawValue }
}

extension GameState {

    /// The stage this kin is at: the rule's answer today, or the highest stage it
    /// has ever been shown, whichever is higher.
    func friendshipStage(_ kin: OwnedChibi, now: Date = Date()) -> FriendshipStage {
        let computed = FriendshipStage.stage(days: daysTogether(kin, now: now) - 1,
                                             careTaps: kin.careTaps)
        let kept = FriendshipStage(rawValue: kin.stageReached) ?? .justMet
        return max(computed, kept)
    }

    /// One care tap on the active kin. Free, unlimited, no coins either way; the
    /// tap counts toward the friendship word and nothing else. Returns the new
    /// stage only on the tap that crossed a line, so the caller can say so once.
    @discardableResult
    mutating func recordCare(now: Date = Date()) -> FriendshipStage? {
        guard let i = owned.firstIndex(where: { $0.speciesID == activeChibiID }) else { return nil }
        owned[i].careTaps += 1
        return settleFriendship(at: i, now: now)
    }

    /// Writes the active kin's high-water mark. Returns the stage only when it just
    /// rose — a day passing can move it as well as a tap, so the tab settles on open.
    @discardableResult
    mutating func settleFriendship(now: Date = Date()) -> FriendshipStage? {
        guard let i = owned.firstIndex(where: { $0.speciesID == activeChibiID }) else { return nil }
        return settleFriendship(at: i, now: now)
    }

    private mutating func settleFriendship(at i: Int, now: Date) -> FriendshipStage? {
        let stage = friendshipStage(owned[i], now: now)
        guard stage.rawValue > owned[i].stageReached else { return nil }
        owned[i].stageReached = stage.rawValue
        return stage
    }
}

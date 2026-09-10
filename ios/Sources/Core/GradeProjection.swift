import Foundation

/// Your GPA for the term, and a target you set per course.
///
/// The per-course what-if on `GradeCalcView` stays free and is not in this file at
/// all. What Plus adds is the row underneath it: every course at once, on a 4.0
/// scale, and a grade you are aiming at.
///
/// This is a tool, not a grade. Nothing here changes a mark, submits anything, or
/// talks to Canvas — it reads the percentages already on the phone and does
/// arithmetic on them. That is the sentence that keeps a grade feature on the right
/// side of "coins pay for finishing, never for grades".
enum GradeProjection {

    /// The standard US letter bands. Deliberately not configurable: a scale a
    /// student can bend is a scale that tells them whatever they want to hear, and
    /// the number stops meaning anything.
    static func points(forPercent percent: Double) -> Double {
        switch percent {
        case 93...:      return 4.0
        case 90..<93:    return 3.7
        case 87..<90:    return 3.3
        case 83..<87:    return 3.0
        case 80..<83:    return 2.7
        case 77..<80:    return 2.3
        case 73..<77:    return 2.0
        case 70..<73:    return 1.7
        case 67..<70:    return 1.3
        case 63..<67:    return 1.0
        case 60..<63:    return 0.7
        default:         return 0.0
        }
    }

    static func letter(forPercent percent: Double) -> String {
        switch percent {
        case 97...:   return "A+"
        case 93..<97: return "A"
        case 90..<93: return "A-"
        case 87..<90: return "B+"
        case 83..<87: return "B"
        case 80..<83: return "B-"
        case 77..<80: return "C+"
        case 73..<77: return "C"
        case 70..<73: return "C-"
        case 67..<70: return "D+"
        case 63..<67: return "D"
        case 60..<63: return "D-"
        default:      return "F"
        }
    }

    /// The term's GPA, from every course that has a score.
    ///
    /// Unweighted, and every course counts once. Credit hours are not on the phone —
    /// Canvas does not send them — so weighting by them would mean asking a student
    /// to type twelve numbers to get one. `nil` when no course has a score yet,
    /// because a GPA of 0.00 from no data is worse than no number at all.
    static func termGPA(_ scores: [Double]) -> Double? {
        guard !scores.isEmpty else { return nil }
        let total = scores.reduce(0.0) { $0 + points(forPercent: $1) }
        return (total / Double(scores.count) * 100).rounded() / 100
    }

    static func format(_ gpa: Double) -> String { String(format: "%.2f", gpa) }

    // MARK: - A goal per course

    /// What is still needed to land a target, given where a course sits now and how
    /// much of it is left.
    ///
    /// `remainingWeight` is the share of the grade not yet marked, 0 to 1. The
    /// answer is the average percent the rest of the work has to score.
    ///
    /// Three honest outcomes and no fourth: it is already done, it is reachable at
    /// some average, or it cannot be reached and we say so plainly rather than
    /// printing 143%.
    enum Need: Equatable {
        case alreadyThere
        case need(percent: Double)
        /// Even a perfect score on everything left falls short.
        case outOfReach(best: Double)
        /// Nothing is left to be marked, and the target was not met.
        case nothingLeft
    }

    static func need(current: Double, target: Double, remainingWeight: Double) -> Need {
        if current >= target { return .alreadyThere }
        guard remainingWeight > 0 else { return .nothingLeft }
        let done = 1 - remainingWeight
        // current already covers the marked share, so the rest has to carry the gap.
        let needed = (target - current * done) / remainingWeight
        if needed > 100 {
            return .outOfReach(best: ((current * done + 100 * remainingWeight) * 100).rounded() / 100)
        }
        return .need(percent: (needed * 100).rounded() / 100)
    }

    /// The one line the row shows. Plain words, no scolding, and never a percentage
    /// above 100.
    static func line(_ need: Need, target: Double) -> String {
        let goal = Self.letter(forPercent: target)
        switch need {
        case .alreadyThere:
            return "You're at \(goal) or better already."
        case .need(let percent):
            return "Average \(Int(percent.rounded()))% on what's left for \(goal)."
        case .outOfReach(let best):
            return "\(goal) is out of reach now. Everything left at 100% lands \(Int(best.rounded()))%."
        case .nothingLeft:
            return "Nothing left to be marked in this one."
        }
    }
}

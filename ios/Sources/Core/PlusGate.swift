import Foundation

/// Every gate money touches, named once, in one place.
///
/// The point of this file is that a reviewer can read forty lines and see the whole
/// surface of what Plus changes. Nothing else in the app reads `PlusEntitlement`
/// directly: a view asks `PlusGate.value(_:isPlus:)` or `PlusGate.isOn(_:isPlus:)`
/// and gets a number back.
///
/// The design rule behind the shape: **the free side is a value in the same table,
/// not an `if` somewhere else.** A gate that cannot state what a student without an
/// entitlement gets is a gate that took something away, and `PlusGateTests` fails
/// the build on it.
///
/// The list is `design/PLUS-SPEC.md` section 2. Adding a case here means adding a
/// row there first, with its rule check.
enum PlusGate: String, CaseIterable {

    // MARK: Calendar

    /// Photos read into dated tasks, per month. Free is 0: the reader has never
    /// been free, so gating it takes nothing from anyone.
    case scanPhoto
    /// Dated tasks written out to Apple Calendar, or to an `.ics` file.
    case calendarExport

    // MARK: Shop

    /// Slots in today's picks row.
    case shopSlots
    /// Slots that can be held through a reroll and overnight.
    case shopHolds
    /// Percent off a pick's Collection price. Every item stays reachable at full
    /// coin price forever, which is the sentence that keeps this on the right side
    /// of "coins are never sold".
    case shopDiscount
    /// Free rerolls of today's row, per day.
    case shopRerolls

    // MARK: Focus

    /// How many shift lengths the chip row offers. Free keeps 15, 25 and 45.
    case focusLengths
    /// The last seven days of shift minutes, as a bar per day. A count of work
    /// done, never a target, so it is not a meter that falls.
    case focusHistory

    // MARK: Grades

    /// Term GPA projected from the course grades already on the phone. The
    /// per-course what-if stays free and is not in this table at all.
    case gpaProjection
    /// A target grade the student sets per course.
    case courseGoal

    // MARK: Friends and kin

    /// Cards that can be sent to a friend. Free gets three of six. This ships with
    /// Friends phase 2 at three, or it can never be three.
    case vibeCards
    /// Saved coat-plus-costume-plus-scene combinations. Every combination already
    /// saved stays applicable forever, including any above the free number.
    case savedLooks
    /// Looks coins cannot buy, wearable on any kin at any star.
    case plusLooks
    /// Scenes coins cannot buy: Observatory, Lantern Street, Snow Cabin.
    case plusScenes

    // MARK: - The table

    /// What a student with no entitlement gets. These are the numbers the app
    /// ships with today, and `PlusGateTests` holds its own copy of them so a diff
    /// that lowers one has to change a test on purpose.
    var free: Int {
        switch self {
        case .scanPhoto:      return 0
        case .calendarExport: return 0
        case .shopSlots:      return 5
        case .shopHolds:      return 1
        case .shopDiscount:   return 20
        case .shopRerolls:    return 3
        case .focusLengths:   return 3      // 15, 25, 45
        case .focusHistory:   return 0
        case .gpaProjection:  return 0
        case .courseGoal:     return 0
        case .vibeCards:      return 3
        case .savedLooks:     return 3
        case .plusLooks:      return 0
        case .plusScenes:     return 0
        }
    }

    /// What Plus gets. Never smaller than `free` — Plus is more of a thing, never a
    /// different thing.
    var plus: Int {
        switch self {
        case .scanPhoto:      return 50
        case .calendarExport: return .max
        case .shopSlots:      return 7
        case .shopHolds:      return 3
        case .shopDiscount:   return 30
        case .shopRerolls:    return 6
        case .focusLengths:   return .max   // 15, 25, 45, 60, 90, and any length typed
        case .focusHistory:   return 7
        case .gpaProjection:  return 1
        case .courseGoal:     return .max
        case .vibeCards:      return 6
        case .savedLooks:     return .max
        case .plusLooks:      return .max
        case .plusScenes:     return 3
        }
    }

    /// Filled in only by a release that lowers a gate's `free` number.
    ///
    /// Empty on 2026-09-10, and that is the point: nothing in `PLUS-SPEC.md` takes
    /// anything away, so nothing needs grandfathering yet. It exists so the promise
    /// is enforceable in code the day George signs one of the section-10 items, and
    /// not only written down in a plan.
    var restriction: Restriction? { nil }

    struct Restriction: Equatable {
        /// Installs from before this date keep `was` forever.
        var since: Date
        /// The number the gate offered before the release that lowered it.
        var was: Int
    }

    // MARK: - Reading a gate

    /// The only entitlement read in the app.
    static func value(_ gate: PlusGate, isPlus: Bool, installedAt: Date? = nil) -> Int {
        if isPlus { return gate.plus }
        guard let r = gate.restriction, let installed = installedAt, installed < r.since else {
            return gate.free
        }
        return r.was
    }

    static func isOn(_ gate: PlusGate, isPlus: Bool, installedAt: Date? = nil) -> Bool {
        value(gate, isPlus: isPlus, installedAt: installedAt) > 0
    }
}

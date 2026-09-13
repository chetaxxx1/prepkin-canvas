import Foundation

/// Free and Plus, side by side.
///
/// Structured's and Forest's compare table, which is the clearest perk list in the
/// category, and the second screen of the sheet rather than the first — a table is
/// what you read once you have decided to look closely.
///
/// The rule this table has to obey is `PLUS-SPEC.md` R1: **nothing in the Free
/// column ever moves to the Plus column.** The top rows are there for exactly that
/// reason. A compare table that only lists what you do not have is a padlock with a
/// header on it; this one starts with what a student already owns, ticked in both columns.
///
/// The numbers are read from `PlusGate` rather than typed here, so a row cannot
/// promise something the gate does not hand over.
enum PlusCompare {

    /// A cell is a tick or a number. There is no cross: a row that reads
    /// "nothing / yes" is a padlock with better manners, so a good that Free has
    /// none of is not in this table at all — it is on the offer screen as a
    /// picture, where a student can judge it.
    enum Mark: Equatable {
        case yes
        case text(String)
    }

    struct Row: Equatable {
        var name: String
        var free: Mark
        var plus: Mark
    }

    private static func both(_ name: String) -> Row {
        Row(name: name, free: .yes, plus: .yes)
    }

    private static func counts(_ name: String, _ gate: PlusGate, suffix: String = "") -> Row {
        Row(
            name: name,
            free: .text("\(gate.free)\(suffix)"),
            plus: .text(gate.plus == .max ? "any" : "\(gate.plus)\(suffix)")
        )
    }

    /// Only rows with a value in both columns: three ticked in both, then numbers
    /// against numbers. The four Plus-only goods (the look, the three scenes, the
    /// reader, the GPA) are on the offer screen, not here.
    static let rows: [Row] = [
        // Everything that is free, first. This half of the table is the promise.
        both("Canvas work, the Receipt, coins"),
        both("All 57 lessons, Friends, leagues, Games"),
        both("Dark, contrast, reduced motion"),

        // The paid half: the same thing, more of it.
        counts("Picks a day", .shopSlots),
        counts("Slots you can hold", .shopHolds),
        counts("Off every pick", .shopDiscount, suffix: "%"),
        counts("Free rerolls a day", .shopRerolls),
        counts("Shift lengths", .focusLengths),
        counts("Cards to send a friend", .vibeCards),
        counts("Saved looks", .savedLooks),
    ]
}

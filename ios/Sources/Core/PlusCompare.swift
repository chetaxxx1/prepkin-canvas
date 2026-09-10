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
/// header on it; this one starts with eleven ticks a student already owns.
///
/// The numbers are read from `PlusGate` rather than typed here, so a row cannot
/// promise something the gate does not hand over.
enum PlusCompare {

    enum Mark: Equatable {
        case yes
        case no
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

    static let rows: [Row] = [
        // Everything that is free, first and at length. This half of the table is
        // the promise, and it is longer than the other half on purpose.
        both("Canvas work and the Receipt"),
        both("Coins, and every kin, costume and scene coins buy"),
        both("The timer, and 15, 25 and 45 minute shifts"),
        both("All 57 lessons"),
        both("Friends, leagues and Games"),
        both("Dark, contrast and reduced motion"),

        // The paid half.
        counts("Picks in the Shop each day", .shopSlots),
        counts("Slots you can hold", .shopHolds),
        counts("Off every pick", .shopDiscount, suffix: "%"),
        counts("Free rerolls a day", .shopRerolls),
        Row(name: "60 and 90 minute shifts, or any length", free: .no, plus: .yes),
        Row(name: "A week of your own hours", free: .no, plus: .yes),
        Row(name: "Photos read into your calendar", free: .no, plus: .yes),
        Row(name: "Work sent out to Apple Calendar", free: .no, plus: .yes),
        Row(name: "Your GPA for the term, and a goal per course", free: .no, plus: .yes),
        counts("Cards to send a friend", .vibeCards),
        counts("Saved looks", .savedLooks),
        Row(name: "A look and three scenes coins cannot buy", free: .no, plus: .yes),
    ]
}

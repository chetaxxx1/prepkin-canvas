import Foundation
import CoreGraphics

/// Two prop slots per tank, left and right, inside the window every tank plate
/// keeps clear. Tolan's planet: tap a slot, a ring shows where the thing will
/// stand, pick from a tray. Replika's room: a grid of props, owned ones marked.
///
/// The numbers are `design/tanks/compose_tank.py`'s, which is the script that
/// composes every new plate: a prop's centre at x 0.212 / 0.788 of the plate, its
/// feet at y 0.765, at most 0.34 of the plate tall and 0.155 wide. Code owns the
/// geometry; a prop is a keyed cut-out placed at a slot, never a new painting.
enum PropSlot: String, Codable, CaseIterable, Identifiable {
    case left, right

    var id: String { rawValue }

    /// The prop's centre, as a fraction of the plate's width.
    var x: CGFloat { self == .left ? 0.212 : 0.788 }
    /// Where the prop's feet sit, as a fraction of the plate's height.
    static let base: CGFloat = 0.765
    /// Tallest a prop may stand, as a fraction of the plate's height.
    static let maxHeight: CGFloat = 0.34
    /// Widest a prop may be, as a fraction of the plate's width.
    static let maxWidth: CGFloat = 0.155

    var name: String { self == .left ? "Left slot" : "Right slot" }

    /// The window all eleven surfaces keep in frame (`check_tank.py`): x 0.123–0.877,
    /// y 0.367–0.782 of the plate. Anything placed outside it is cut on some card.
    static let window = CGRect(x: 0.123, y: 0.367, width: 0.754, height: 0.415)

    /// The box a prop of this height (plate fraction) and width-to-height aspect
    /// occupies standing in this slot, in plate fractions. Plates are 4:3.
    func box(height: CGFloat, aspect: CGFloat) -> CGRect {
        let h = min(height, Self.maxHeight)
        // Width in plate-width fractions: height fraction × (3/4) × aspect.
        let w = min(h * 0.75 * aspect, Self.maxWidth)
        return CGRect(x: x - w / 2, y: Self.base - h, width: w, height: h)
    }

    /// True when the box is inside the window every surface keeps.
    static func fits(_ box: CGRect) -> Bool { window.contains(box) }
}

/// A cut-out that can stand in a slot. The tray draws None and whatever is here.
///
/// Empty until art lands: the five shipped tanks have their props painted in, and
/// the keyed cut-outs the compositor makes (`--layers`) exist only for the trial
/// tanks. Nothing here is shown to a student until `KinFlags.decorate` is on.
struct TankProp: Identifiable, Equatable {
    let id: String
    let name: String
    let price: Int
    /// Asset name of the keyed cut-out, feet on its bottom edge.
    let asset: String
    /// Width over height of the cut-out, so the slot can size it.
    let aspect: CGFloat

    static let catalog: [TankProp] = []

    static func find(_ id: String) -> TankProp? { catalog.first { $0.id == id } }
}

/// What stands in which slot, per tank. An empty slot is simply absent.
struct TankDecor: Codable, Equatable {
    /// tank id → slot → prop id
    var placed: [String: [String: String]] = [:]

    func prop(in slot: PropSlot, tank: String) -> String? { placed[tank]?[slot.rawValue] }

    /// Puts a prop in a slot, or clears it with `nil` — the tray's None tile.
    mutating func place(_ propID: String?, in slot: PropSlot, tank: String) {
        var slots = placed[tank] ?? [:]
        if let propID { slots[slot.rawValue] = propID } else { slots.removeValue(forKey: slot.rawValue) }
        if slots.isEmpty { placed.removeValue(forKey: tank) } else { placed[tank] = slots }
    }
}

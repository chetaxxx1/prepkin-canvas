import Foundation
import CoreGraphics

/// Five piece slots per tank: two stands on the floor, two corners hanging from the
/// top edge, and a light on a cord from the top centre. Tolan's planet: tap a slot,
/// a ring shows where the thing will go, pick from a tray. Replika's room: a grid
/// of pieces, the tank's own first.
///
/// The numbers are `design/tanks/compose_tank.py`'s, which is the script that
/// composes every new plate. Code owns the geometry; a piece is a keyed cut-out
/// placed at a slot, never a new painting. A cut-out is already scaled to its
/// slot's maximum at plate scale (1440x1080), so its own pixel size is its box.
enum PropSlot: String, Codable, CaseIterable, Identifiable {
    case left, right, tl, tr, light

    var id: String { rawValue }

    var kind: PropKind {
        switch self {
        case .left, .right: return .stand
        case .tl, .tr: return .corner
        case .light: return .light
        }
    }

    /// The piece's centre, as a fraction of the plate's width.
    var x: CGFloat {
        switch self {
        case .left: return 0.212
        case .right: return 0.788
        case .tl: return 0.15
        case .tr: return 0.85
        case .light: return 0.5
        }
    }

    /// Where a hanging piece's top edge sits. The lamp starts 8% down so its
    /// fixture hangs out from under the Dynamic Island; the cord is drawn above it.
    var top: CGFloat { self == .light ? 0.08 : 0 }

    var name: String {
        switch self {
        case .left: return "Left stand"
        case .right: return "Right stand"
        case .tl: return "Left corner"
        case .tr: return "Right corner"
        case .light: return "Light"
        }
    }

    /// The box a piece of this pixel size occupies in this slot, in plate
    /// fractions. Stands put their feet on the tank's floor line.
    func box(size: CGSize, feet: CGFloat) -> CGRect {
        let w = size.width / 1440, h = size.height / 1080
        let y = kind == .stand ? feet - h : top
        return CGRect(x: x - w / 2, y: y, width: w, height: h)
    }
}

enum PropKind: String, Codable {
    case stand, corner, light

    /// Tallest a piece may be, as a fraction of the plate's height (compose_tank SLOTS).
    var maxHeight: CGFloat {
        switch self {
        case .stand: return 0.34
        case .corner: return 0.19
        case .light: return 0.24
        }
    }
    /// Widest, as a fraction of the plate's width.
    var maxWidth: CGFloat {
        switch self {
        case .stand: return 0.155
        case .corner: return 0.24
        case .light: return 0.20
        }
    }
}

/// A cut-out that can go in a slot. The tray draws None and whatever fits.
struct TankProp: Identifiable, Equatable {
    let id: String
    let name: String
    let kind: PropKind
    /// 0 for an earned piece, which is never sold.
    let price: Int
    /// Asset name of the keyed cut-out, feet on its bottom edge.
    let asset: String
    /// The same cut-out under `SproutWeb/tanks/ios/`, for the live tank.
    let file: String
    /// Pixel size at plate scale; divided by 1440x1080 it is the box.
    let size: CGSize
    /// The tank this piece came with, if any. Loose and earned pieces have none.
    var theme: String? = nil
    /// How an earned piece is earned, shown under it in the tray.
    var rule: String? = nil
    /// A lamp's colour: the live tank's rays take it.
    var light: String? = nil

    static let catalog: [TankProp] = TankCatalog.pieces

    static func find(_ id: String) -> TankProp? { catalog.first { $0.id == id } }

    var isEarned: Bool { rule != nil }
}

/// What is in which slot, per tank. A slot the student has never touched shows the
/// tank's own piece; one cleared with the tray's None tile is stored as "".
struct TankDecor: Codable, Equatable {
    /// tank id → slot → piece id ("" for emptied on purpose)
    var placed: [String: [String: String]] = [:]

    /// The piece to draw in a slot: the student's choice, else the tank's default.
    func prop(in slot: PropSlot, tank: String) -> String? {
        if let chosen = placed[tank]?[slot.rawValue] { return chosen.isEmpty ? nil : chosen }
        return TankCatalog.defaults[tank]?[slot]
    }

    /// True when the slot shows what the tank came with.
    func isDefault(_ slot: PropSlot, tank: String) -> Bool { placed[tank]?[slot.rawValue] == nil }

    /// Puts a piece in a slot, or clears it with `nil` — the tray's None tile.
    mutating func place(_ propID: String?, in slot: PropSlot, tank: String) {
        var slots = placed[tank] ?? [:]
        if propID == TankCatalog.defaults[tank]?[slot] {
            slots.removeValue(forKey: slot.rawValue)
        } else {
            slots[slot.rawValue] = propID ?? ""
        }
        if slots.isEmpty { placed.removeValue(forKey: tank) } else { placed[tank] = slots }
    }
}

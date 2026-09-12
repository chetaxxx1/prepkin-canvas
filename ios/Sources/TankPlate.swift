import SwiftUI

/// A tank still, 4:3, with the student's pieces in its slots. A painted tank (no
/// `emptyAsset`) is just its picture; a themed tank is its empty plate plus a
/// cut-out per slot, placed by the same numbers the live page uses.
struct TankPlate: View {
    let scene: Scene0
    let decor: TankDecor
    var width: CGFloat

    private var height: CGFloat { width * 0.75 }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Image(scene.emptyAsset ?? scene.asset)
                .resizable()
                .scaledToFit()
                .frame(width: width, height: height)

            if scene.emptyAsset != nil {
                ForEach(PropSlot.allCases) { slot in
                    if let prop = decor.prop(in: slot, tank: scene.id).flatMap(TankProp.find) {
                        let box = slot.box(size: prop.size, feet: scene.feet)
                        if slot.kind != .stand, box.minY > 0 {
                            // the cord from the top edge to a lamp, in a colour that reads on any wall
                            Rectangle()
                                .fill(Theme.ink.opacity(0.55))
                                .frame(width: 2, height: box.minY * height + 2)
                                .position(x: box.midX * width, y: (box.minY * height + 2) / 2)
                        }
                        Image(prop.asset)
                            .resizable()
                            .frame(width: box.width * width, height: box.height * height)
                            .position(x: box.midX * width, y: box.midY * height)
                    }
                }
            }
        }
        .frame(width: width, height: height)
        .clipped()
    }
}

extension TankDecor {
    /// The live page's view of a tank's slots: `slot=file` for each slot the student
    /// changed, `slot=none` for one they emptied. Untouched slots are left to the
    /// page, which draws the tank's own piece.
    func queryItems(tank: String) -> [URLQueryItem] {
        PropSlot.allCases.compactMap { slot in
            guard let chosen = placed[tank]?[slot.rawValue] else { return nil }
            let prop = TankProp.find(chosen)
            var value = prop?.file ?? "none"
            if let light = prop?.light { value += "|" + light }
            return URLQueryItem(name: slot.rawValue, value: value)
        }
    }
}

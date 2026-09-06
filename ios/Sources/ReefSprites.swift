import SwiftUI

/// The reef's traced sprites, shipped as SVG assets (`reef-<name>` in Assets.xcassets).
/// Generated from design/reef-route/reef-route.html; width ÷ height so a sprite can be
/// placed by height and keep its shape.
enum ReefSprites {
    static let aspect: [String: CGFloat] = [
        "plant-1": 0.4392,
        "plant-2": 0.5699,
        "plant-3": 0.8567,
        "plant-4": 0.3007,
        "plant-5": 1.5507,
        "coral-1": 1.1148,
        "coral-2": 1.5786,
        "coral-3": 0.9976,
        "coral-4": 0.9536,
        "coral-5": 1.2689,
        "coral-6": 1.2409,
        "coral-7": 1.5109,
        "crab-1": 1.0114,
        "crab-2": 1.3412,
        "clam-1": 1.1588,
        "clam-2": 0.9245,
        "star": 1.2747,
        "arch": 1.1990,
        "far": 6.3158,
        "puffer": 1.3947,
        "darter": 2.8641,
        "angel": 1.0693,
        "dolphin": 1.9537,
        "orca": 1.7550,
        "whale": 2.1116,
        "sub": 1.2333,
        "chest-1": 1.3885
    ]
    static func width(_ name: String, height: CGFloat) -> CGFloat { (aspect[name] ?? 1) * height }
}

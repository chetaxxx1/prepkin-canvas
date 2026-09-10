import SwiftUI

/// Sprout as a still, for every place that is not the Home tank.
///
/// The character is web art (see `SproutView`), and a WKWebView per tile is out of
/// the question — so the six coats × three stars are rendered once from the same
/// build (`scratchpad/capture_sprout.py`) into `Assets.xcassets/sprout-<coat>-<evo>`.
/// Each PNG is a square box, bottom-anchored, with the three-star drawing filling
/// the width; smaller stars are smaller inside the same box, so the size ladder the
/// web build uses survives.
///
/// `size` is the width of that box, the same meaning `KinArtView.size` has always
/// had: the footprint a three-star kin fills.
struct SproutImage: View {
    let speciesID: String
    var level: Int = 3
    /// Which Sprout look the kin is wearing: `classic` or `ninja`.
    var skin: String = "classic"
    var animation: ChibiAnimation = .idle
    /// Bump this to play the current animation again. `animation` alone only fires on
    /// a change, so a screen that wants the same emote twice — a celebration that keeps
    /// going while you sit on it — has no other way to ask.
    var replay: Int = 0
    var size: CGFloat

    /// Drawn height of the three-star art as a fraction of the box width, over
    /// every kin in the catalogue. `capture_sprout.py` prints this value; it must be
    /// updated whenever the stills are recaptured or every card reserves the wrong height.
    ///
    /// 2026-09-09: 0.999 -> 0.660. The stills were recaptured from the current rig, where a
    /// stage-III kin spreads its fins 1293px wide against 853px of height. The old set was
    /// nearly square because its tallest art was headphones reaching above the crown.
    ///
    /// 2026-09-10: 0.660 -> 0.700. The whole costume rack was captured into the same box,
    /// and the sorcerer hat reaches 905px of it.
    static let heightRatio: CGFloat = 0.700

    @State private var trigger = 0

    /// Costumes that have their own six stills in the catalogue — the whole rack, one
    /// per coat, captured by `design/capture_costumes.py`. Anything not here draws the
    /// plain set rather than a blank frame.
    static let looksWithStills: Set<String> = Costume.ids

    static func asset(speciesID: String, level: Int, skin: String) -> String {
        let type = SproutView.type(speciesID)
        // Costumes exist for Sprout only, and only at stage III — the rig has no costume
        // slot before that, so a younger kin in a costume draws the plain art.
        let look = type == "sprout" && level >= 3 && looksWithStills.contains(skin) ? "\(skin)-" : ""
        return "\(type)-\(look)\(SproutView.coat(speciesID))-\(SproutView.evo(level))"
    }

    var body: some View {
        Image(Self.asset(speciesID: speciesID, level: level, skin: skin))
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: size, height: size)
            .frame(width: size, height: size * Self.heightRatio, alignment: .bottom)
            .keyframeAnimator(initialValue: Pose(), trigger: trigger) { view, pose in
                view
                    .scaleEffect(x: pose.sx, y: pose.sy, anchor: .bottom)
                    .rotationEffect(.degrees(pose.tilt), anchor: .bottom)
                    .offset(y: pose.lift)
            } keyframes: { _ in
                KeyframeTrack(\.lift) { lifts(for: animation) }
                KeyframeTrack(\.sy) { squashes(for: animation) }
                KeyframeTrack(\.sx) { stretches(for: animation) }
                KeyframeTrack(\.tilt) { tilts(for: animation) }
            }
            .onChange(of: animation) { _, new in
                if new != .idle { trigger += 1 }
            }
            .onChange(of: replay) { _, _ in
                if animation != .idle { trigger += 1 }
            }
            .accessibilityHidden(true)
    }

    // MARK: - Motion
    //
    // Small transforms on the still — a stand-in for the web emotes until a GIF of
    // each has George's sign-off, like the faces. Idle is nothing at all.

    struct Pose {
        var lift: CGFloat = 0
        var sx: CGFloat = 1
        var sy: CGFloat = 1
        var tilt: Double = 0
    }

    @KeyframeTrackContentBuilder<CGFloat>
    private func lifts(for a: ChibiAnimation) -> some KeyframeTrackContent<CGFloat> {
        switch a {
        case .bounce:
            SpringKeyframe(-14, duration: 0.18, spring: .bouncy)
            SpringKeyframe(0, duration: 0.32, spring: .bouncy)
        case .celebrate:
            SpringKeyframe(-22, duration: 0.2, spring: .bouncy)
            SpringKeyframe(0, duration: 0.3, spring: .bouncy)
            SpringKeyframe(-16, duration: 0.18, spring: .bouncy)
            SpringKeyframe(0, duration: 0.3, spring: .bouncy)
        case .slump:
            CubicKeyframe(4, duration: 0.3)
            CubicKeyframe(0, duration: 0.6)
        default:
            CubicKeyframe(0, duration: 0.01)
        }
    }

    @KeyframeTrackContentBuilder<CGFloat>
    private func squashes(for a: ChibiAnimation) -> some KeyframeTrackContent<CGFloat> {
        switch a {
        case .bounce, .celebrate:
            CubicKeyframe(0.92, duration: 0.08)
            CubicKeyframe(1.06, duration: 0.14)
            SpringKeyframe(1, duration: 0.4, spring: .bouncy)
        case .startle:
            CubicKeyframe(1.1, duration: 0.08)
            SpringKeyframe(1, duration: 0.4, spring: .bouncy)
        case .slump:
            CubicKeyframe(0.94, duration: 0.3)
            CubicKeyframe(1, duration: 0.6)
        default:
            CubicKeyframe(1, duration: 0.01)
        }
    }

    @KeyframeTrackContentBuilder<CGFloat>
    private func stretches(for a: ChibiAnimation) -> some KeyframeTrackContent<CGFloat> {
        switch a {
        case .bounce, .celebrate:
            CubicKeyframe(1.06, duration: 0.08)
            CubicKeyframe(0.96, duration: 0.14)
            SpringKeyframe(1, duration: 0.4, spring: .bouncy)
        case .startle:
            CubicKeyframe(0.94, duration: 0.08)
            SpringKeyframe(1, duration: 0.4, spring: .bouncy)
        default:
            CubicKeyframe(1, duration: 0.01)
        }
    }

    @KeyframeTrackContentBuilder<Double>
    private func tilts(for a: ChibiAnimation) -> some KeyframeTrackContent<Double> {
        switch a {
        case .wave, .dance:
            CubicKeyframe(-7, duration: 0.16)
            CubicKeyframe(7, duration: 0.24)
            CubicKeyframe(-6, duration: 0.24)
            CubicKeyframe(5, duration: 0.24)
            SpringKeyframe(0, duration: 0.3, spring: .smooth)
        case .peek:
            CubicKeyframe(9, duration: 0.2)
            CubicKeyframe(9, duration: 0.5)
            SpringKeyframe(0, duration: 0.3, spring: .smooth)
        default:
            CubicKeyframe(0, duration: 0.01)
        }
    }
}

/// Sprout's face in a circle — the tab chip, the Ask Kin button, any small avatar.
/// A dark plate, like the old chip: on a pale ground the face sits at its own
/// lightness and the crop reads as a colour swatch.
struct SproutFace: View {
    var speciesID: String
    var size: CGFloat = 28
    var plate: Color = Theme.kinChip

    /// A portrait, not a thumbnail. The three-star stills are wide and short (fins
    /// spread, 0.66 tall), so the old crop showed a plate with a face sunk at the
    /// bottom of it. Measured on the mint still at @3x: the head runs 617–900 of
    /// 1293 and is 560 wide, so drawing the still at 2.15× the circle and lifting
    /// it so the point 60% down sits on the centre fills the circle with the face,
    /// tuft just in, collar just showing. Checked on every rig 2026-09-10.
    ///
    /// Each still is centred on its own eyes (`Catalog.portraits`, written by
    /// design/portraits.py), because a headband tail or a costume shifts the face
    /// off the image's centre and the tab-bar kin drifted sideways by rig.
    var body: some View {
        let asset = SproutImage.asset(speciesID: speciesID, level: 3, skin: "classic")
        let face = Catalog.portraits[asset] ?? [0.5, 0.60, 2.15]
        // Third value: how many circle-widths wide the still is drawn, per still,
        // in case a rig ever needs a looser crop than the Sprout portrait.
        let drawn = size * (face.count > 2 ? face[2] : 2.15)
        return Circle()
            .fill(plate)
            .frame(width: size, height: size)
            .overlay {
                Image(asset)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: drawn, height: drawn)
                    .offset(x: (0.5 - face[0]) * drawn, y: (0.5 - face[1]) * drawn)
            }
            .clipShape(Circle())
            .accessibilityHidden(true)
    }
}

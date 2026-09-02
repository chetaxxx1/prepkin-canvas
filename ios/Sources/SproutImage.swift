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
    var animation: ChibiAnimation = .idle
    var size: CGFloat

    /// Drawn height of the three-star art as a fraction of the box width.
    static let heightRatio: CGFloat = 0.738

    @State private var trigger = 0

    var body: some View {
        Image("sprout-\(SproutView.coat(speciesID))-\(SproutView.evo(level))")
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

    var body: some View {
        Circle()
            .fill(plate)
            .frame(width: size, height: size)
            .overlay {
                SproutImage(speciesID: speciesID, level: 3, size: size * 1.9)
                    // Feet out of frame; eyes and tuft in it.
                    .offset(y: size * 0.34)
            }
            .clipShape(Circle())
            .accessibilityHidden(true)
    }
}

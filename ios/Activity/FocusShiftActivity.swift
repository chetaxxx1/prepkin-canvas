import ActivityKit
import SwiftUI
import WidgetKit

/// The lock screen and Dynamic Island for a running shift.
///
/// This target exists for exactly this. The home-screen widgets from the 2026-09-09
/// review are a separate job and are deliberately not here — a widget that shows
/// today's tasks needs the save file, an app group and a decision about what it is
/// allowed to say; the Live Activity needs none of that.
///
/// It draws with `Theme`, the same file the app draws with, so the paper and the coin
/// gold cannot drift. It does not scale with the type size on purpose: the lock
/// screen gives it one fixed strip, and a shift that grows past it just clips.
@main
struct PrepkinActivityBundle: WidgetBundle {
    var body: some Widget { FocusShiftLiveActivity() }
}

struct FocusShiftLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusShiftAttributes.self) { context in
            LockScreenShift(attributes: context.attributes, state: context.state)
                .activityBackgroundTint(Theme.paper)
                .activitySystemActionForegroundColor(Theme.ink)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    KinStill(asset: context.attributes.kinAsset, size: 38)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Clock(state: context.state, size: 22, width: 82, tint: Theme.onDarkWarm)
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(context.attributes.kinName) is on shift")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                        Text(subtitle(context.state, context.attributes))
                            .font(.system(size: 12.5, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } compactLeading: {
                KinStill(asset: context.attributes.kinAsset, size: 18)
            } compactTrailing: {
                Clock(state: context.state, size: 13, width: 48, tint: Theme.onDarkWarm)
            } minimal: {
                KinStill(asset: context.attributes.kinAsset, size: 18)
            }
            .keylineTint(Theme.coral)
        }
    }
}

/// "10 lengths · 25 coins at the end."
///
/// Two things it deliberately does not say. Not "25 coins so far": nothing is earned
/// until the shift finishes, and the lock screen is the last place to blur that. And
/// not "4 lengths **swum**", which is what this said first — a progress count on a
/// locked phone is frozen at whatever it was when the app last ran, so a 45 spent in
/// a pocket sat on "1 length swum" for three quarters of an hour. The lock screen
/// states the shift's shape, which cannot go stale; the running count lives in the
/// app, and the real total is in the notification at the end.
private func subtitle(_ state: FocusShiftAttributes.ContentState,
                      _ attributes: FocusShiftAttributes) -> String {
    let n = attributes.lengths
    let swim = "\(n) length\(n == 1 ? "" : "s")"
    return state.paused ? "\(swim) · paused" : "\(swim) · \(attributes.coins) coins at the end"
}

// MARK: - Lock screen

private struct LockScreenShift: View {
    let attributes: FocusShiftAttributes
    let state: FocusShiftAttributes.ContentState

    var body: some View {
        HStack(spacing: 11) {
            KinStill(asset: attributes.kinAsset, size: 40)
            VStack(alignment: .leading, spacing: 3) {
                // One line, always. A kin with a long name shrinks its own title
                // rather than wrapping "Moss is / on shift" around the clock.
                Text("\(attributes.kinName) is on shift")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(subtitle(state, attributes))
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.tabInk)
                    .lineLimit(2)
            }
            Spacer(minLength: 6)
            Clock(state: state, size: 24, width: 118)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Pieces

/// The countdown. Running, it is a `Text(timerInterval:)`, which the system ticks by
/// itself — the app can be asleep in a pocket for 45 minutes and the number is still
/// right. Paused, there is nothing to count down to, so the frozen figure stands.
///
/// Minutes, not m:ss, and that is the platform's call rather than ours. **The lock
/// screen refreshes a Live Activity about once a minute**, so a ticking seconds digit
/// is not on offer there: `Text(timerInterval:)` renders "21:--" and this style
/// renders "20 min". A tired student reads "20 min"; "21:--" reads as broken. Inside
/// the Dynamic Island, which does refresh fast, the same text ticks as "20:34".
///
/// The width is given, not asked for. Too little and the text truncates ("20 m…");
/// `fixedSize` and it claims room for the largest value it can imagine, squeezing the
/// title and the kin to nothing. Both of those shipped to this lock screen first.
private struct Clock: View {
    let state: FocusShiftAttributes.ContentState
    let size: CGFloat
    var width: CGFloat?
    /// The Dynamic Island is always black, whatever the app's own light-only paper
    /// says, so ink-on-black is unreadable there. The lock screen keeps the ink.
    var tint: Color = Theme.ink

    var body: some View {
        Group {
            if state.paused {
                Text(clockText(Int(state.remaining)))
            } else {
                Text(state.endsAt, style: .timer)
                    .multilineTextAlignment(.trailing)
            }
        }
        .font(.system(size: size, weight: .black, design: .rounded))
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.45)
        .foregroundStyle(tint)
        .frame(width: width, alignment: .trailing)
    }

    private func clockText(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

/// The kin, from this target's own slim catalogue. `SproutImage` is not reused: it
/// carries the keyframe emotes, which need a live view, and a lock screen never plays one.
private struct KinStill: View {
    let asset: String
    let size: CGFloat

    var body: some View {
        Image(asset)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

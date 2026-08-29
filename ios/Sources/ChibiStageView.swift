import SwiftUI

/// Placeholder chibi: a rounded box driven by the real animation state machine.
/// Real slime art (sprite sheet / Rive) replaces the box, keeps the states.
struct ChibiStageView: View {
    let chibi: OwnedChibi
    let animation: ChibiAnimation

    @State private var squish = false
    @State private var hop = false

    // Level = size for now, so upgrades are visible even with placeholder art.
    private var size: CGFloat { [1: 90, 2: 115, 3: 140][chibi.level] ?? 90 }

    var body: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: size * 0.35)
                .fill(Color(.systemGray4))
                .frame(width: size, height: size)
                .scaleEffect(x: squish ? 1.06 : 1.0, y: squish ? 0.92 : 1.0, anchor: .bottom)
                .offset(y: hop ? -26 : 0)
                .opacity(animation == .sleep ? 0.5 : 1)
                .overlay(
                    Text(animation == .sleep ? "zzz" : "·  ·")
                        .font(.system(size: size * 0.2, weight: .bold))
                        .foregroundStyle(.secondary)
                        .offset(y: hop ? -26 : 0)
                )

            Text("\(chibi.species.name) · Lv \(chibi.level) · \(animation.rawValue)")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .onAppear { startIdle() }
        .onChange(of: animation) { _, newValue in
            switch newValue {
            case .bounce, .celebrate, .wave:
                withAnimation(.interpolatingSpring(stiffness: 220, damping: 9)) { hop = true }
                Task {
                    try? await Task.sleep(for: .seconds(0.35))
                    withAnimation(.interpolatingSpring(stiffness: 220, damping: 9)) { hop = false }
                }
            default:
                hop = false
            }
        }
    }

    private func startIdle() {
        withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
            squish = true
        }
    }
}

import SwiftUI

/// RogerHub-style final grade calculator.
/// needed = (target − current × (1 − weight)) / weight
struct GradeCalcView: View {
    @State private var current = 88.0
    @State private var target = 90.0
    @State private var weight = 20.0   // percent

    private var needed: Double {
        let w = weight / 100
        guard w > 0 else { return 0 }
        return (target - current * (1 - w)) / w
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 20) {
                    slider("Current grade", value: $current, range: 0...100, suffix: "%")
                    slider("Grade I want", value: $target, range: 0...100, suffix: "%")
                    slider("Final is worth", value: $weight, range: 5...100, suffix: "% of grade")
                }
                .card()

                VStack(spacing: 8) {
                    Text("You need")
                        .font(.subheadline)
                        .foregroundStyle(Theme.muted)
                    Text("\(needed, specifier: "%.1f")%")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(needed > 100 ? Theme.coral : (needed <= 0 ? Theme.mint : Theme.ink))
                    Text(verdict)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .card()
            }
            .padding(16)
        }
        .background(Theme.paper)
        .navigationTitle("Grade calculator")
        .navigationBarTitleDisplayMode(.inline)
        .hidesTabBar()
    }

    private var verdict: String {
        switch needed {
        case ..<0: "You already have it. The final can't drop you below your target."
        case ..<70: "Very doable."
        case ..<90: "Doable — study up."
        case ..<100: "Tough but possible."
        case 100: "You need a perfect score."
        default: "Not possible on the final alone. Talk to your teacher about extra credit."
        }
    }

    private func slider(_ label: String, value: Binding<Double>, range: ClosedRange<Double>, suffix: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.ink)
                Spacer()
                Text("\(value.wrappedValue, specifier: "%.0f")\(suffix)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.coral)
            }
            Slider(value: value, in: range, step: 1)
                .tint(Theme.coral)
        }
    }
}

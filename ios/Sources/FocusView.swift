import SwiftUI

/// Focus Friend-style: set a timer, your chibi naps while you work.
/// Finish → 1 coin per minute. Give up → nothing (no punishment, just no pay).
struct FocusView: View {
    @EnvironmentObject var state: AppState
    @State private var minutes = 25
    @State private var endDate: Date?
    @State private var now = Date()

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var running: Bool { endDate != nil }
    private var remaining: Int { max(0, Int(endDate?.timeIntervalSince(now) ?? 0)) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                SlimeView(color: Theme.species(state.activeChibiID),
                          level: state.activeChibi.level,
                          animation: running ? .sleep : state.animation,
                          size: 160)

                if running {
                    Text(String(format: "%d:%02d", remaining / 60, remaining % 60))
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                        .monospacedDigit()
                    Text("\(state.activeChibi.species.name) is napping. Stay off your phone.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.muted)
                } else {
                    Text("\(minutes) min")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Stepper("Session length", value: $minutes, in: 5...120, step: 5)
                        .labelsHidden()
                    Text("Finish and earn \(minutes) coins.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.muted)
                }

                Spacer()

                if running {
                    Button(role: .destructive) { giveUp() } label: {
                        Text("Give up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.bordered)
                    .tint(Theme.muted)
                } else {
                    Button { start() } label: {
                        Text("Start focus")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Theme.coral))
                    }
                }
            }
            .padding(24)
            .padding(.bottom, 104)
            .background(Theme.paper)
            .navigationTitle("Focus")
            .onReceive(ticker) { t in
                now = t
                if running && remaining == 0 { finish() }
            }
            .onChange(of: running) { _, isRunning in state.hideTabBar = isRunning }
            .onDisappear { state.hideTabBar = false }
        }
    }

    private func start() {
        endDate = Date().addingTimeInterval(TimeInterval(minutes * 60))
    }

    private func finish() {
        endDate = nil
        state.recordFocus(minutes: minutes)
    }

    private func giveUp() {
        endDate = nil
        state.play(.wave)
    }
}

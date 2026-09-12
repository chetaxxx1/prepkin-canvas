import SwiftUI

/// The half sheet before the system prompt.
///
/// Finch's "Get reminders from Lee": the student sees exactly what a Prepkin
/// notification looks like — our own evening check-in, drawn as the iOS banner it
/// will be, in their own task names — and picks the hour before iOS asks anything.
/// "Turn on" is the one thing that triggers the system prompt. A refusal there
/// leaves the switch off, and the Reminders card in Your day shows its
/// "Open Settings" line as it does today.
struct ReminderPreviewSheet: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var hour = 19
    @State private var asking = false

    private var name: String { state.activeChibi.displayName }

    var body: some View {
        VStack(spacing: 0) {
            Text("Check-ins from \(name)")
                .font(Theme.font(22, .black))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .padding(.top, 28)

            Text("One note in the evening, in your own words. Never before 8 or after 10.")
                .font(Theme.font(14.5, .bold))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.top, 6)
                .padding(.horizontal, 24)

            banner
                .padding(.top, 20)
                .padding(.horizontal, 20)

            SproutImage(speciesID: state.activeChibiID,
                        level: state.activeChibi.level,
                        skin: state.activeChibi.skinID,
                        size: 118)
                .padding(.top, 14)

            Spacer(minLength: 12)

            timeRow
                .padding(.horizontal, 20)

            Button {
                guard !asking else { return }
                asking = true
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                Task { @MainActor in
                    state.setNudgeHour(hour)
                    await state.setRemindersEnabled(true)
                    dismiss()
                }
            } label: {
                Text("Turn on")
                    .font(Theme.font(16, .black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Theme.coral))
            }
            .buttonStyle(PressStyle())
            .padding(.horizontal, 20)
            .padding(.top, 14)

            Button { dismiss() } label: {
                Text("Not now")
                    .font(Theme.font(14.5, .heavy))
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 8)
        }
        .background(Theme.paper.ignoresSafeArea())
        .onAppear { hour = state.settings.nudgeHour }
        .presentationDetents([.height(560)])
        .presentationCornerRadius(26)
        .presentationDragIndicator(.visible)
    }

    // MARK: - The banner

    /// The check-in as iOS will draw it: icon, app name, "2 left today", the names.
    /// Built from tonight's real list; a clear list shows a sample so the shape is
    /// still visible.
    private var banner: some View {
        let open = state.tasks.filter { !$0.done }.map(\.title)
        let copy = NotificationPlanner.checkIn(openTitles: open)
            ?? NotificationPlanner.checkIn(openTitles: ["Bio quiz", "The walk"])!
        return HStack(alignment: .top, spacing: 12) {
            appIcon
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Prepkin")
                        .font(Theme.font(13, .bold))
                        .foregroundStyle(Theme.muted)
                    Spacer(minLength: 8)
                    Text(hourLabel(hour))
                        .font(Theme.font(12.5, .semibold))
                        .foregroundStyle(Theme.dim)
                }
                Text(copy.title)
                    .font(Theme.font(15, .black))
                    .foregroundStyle(Theme.ink)
                Text(copy.body)
                    .font(Theme.font(14, .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Theme.card)
            .shadow(color: Theme.hex(0x281412).opacity(0.10), radius: 10, y: 4))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("A preview. \(copy.title). \(copy.body)")
    }

    private var appIcon: some View {
        Group {
            if let icon = UIImage(named: "AppIcon") {
                Image(uiImage: icon).resizable()
            } else {
                RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.coral)
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityHidden(true)
    }

    // MARK: - The hour

    private var timeRow: some View {
        HStack {
            Text("Check in at")
                .font(Theme.font(16, .bold))
                .foregroundStyle(Theme.ink)
            Spacer(minLength: 0)
            Picker("Check in at", selection: $hour) {
                ForEach(Array(16...22), id: \.self) { Text(hourLabel($0)).tag($0) }
            }
            .tint(Theme.coral)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 52)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Theme.card))
    }

    private func hourLabel(_ hour: Int) -> String {
        var c = DateComponents()
        c.hour = hour
        let date = Calendar.current.date(from: c) ?? Date()
        return date.formatted(.dateTime.hour())
    }
}

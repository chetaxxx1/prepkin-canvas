import SwiftUI

/// Three steps to put the widget on the home screen, with pictures.
///
/// Finch's "Add Lee to your home screen" walk: one step per page, a drawing of
/// the phone doing that step, Next and Back, Done at the end. The drawings are
/// SwiftUI, not screenshots, so they never go stale against an iOS release and
/// weigh nothing. Reached from the Home card "Want Moss on your home screen?",
/// which shows once.
struct WidgetHowToSheet: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0

    private static let steps: [(title: String, note: String)] = [
        ("Hold the home screen", "Touch and hold an empty spot until the icons wiggle."),
        ("Tap Edit, then Add Widget", "Top left corner. On older iPhones it is a plus."),
        ("Search Prepkin", "Pick a size and tap Add Widget. That's it."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(Theme.muted)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Theme.paperSunk))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
                ForEach(0..<3, id: \.self) { i in
                    Capsule()
                        .fill(i <= step ? Theme.coral : Theme.cardEdge)
                        .frame(height: 5)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)

            Text(Self.steps[step].title)
                .font(Theme.font(22, .black))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .padding(.top, 22)
                .padding(.horizontal, 24)
                .id("title-\(step)")

            Text(Self.steps[step].note)
                .font(Theme.font(14.5, .bold))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.top, 6)
                .padding(.horizontal, 28)

            picture
                .frame(maxWidth: .infinity)
                .frame(height: 250)
                .background(RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Theme.paperSunk))
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .animation(.easeOut(duration: 0.25), value: step)

            Spacer(minLength: 12)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                if step < 2 { step += 1 } else { dismiss() }
            } label: {
                Text(step < 2 ? "Next" : "Done")
                    .font(Theme.font(16, .black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Theme.coral))
            }
            .buttonStyle(PressStyle())
            .padding(.horizontal, 20)

            Button {
                if step > 0 { step -= 1 } else { dismiss() }
            } label: {
                Text(step > 0 ? "Back" : "Not now")
                    .font(Theme.font(14.5, .heavy))
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 8)
        }
        .background(Theme.paper.ignoresSafeArea())
        .presentationDetents([.height(620)])
        .presentationCornerRadius(26)
    }

    @ViewBuilder private var picture: some View {
        switch step {
        case 0: HoldPicture()
        case 1: EditPicture()
        default: SearchPicture(name: state.activeChibi.displayName,
                               speciesID: state.activeChibiID,
                               level: state.activeChibi.level,
                               skin: state.activeChibi.skinID)
        }
    }

    // MARK: - The card's own picture

    /// The widget on a phone, for the Home card. Finch's "Lee widget" card shows
    /// exactly this: the pet in a widget among blank icons.
    static func miniWidget(name: String, speciesID: String, level: Int, skin: String) -> some View {
        PhoneFrame(width: 176) {
            VStack(spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    ZStack(alignment: .bottomTrailing) {
                        RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.card)
                        SproutImage(speciesID: speciesID, level: level, skin: skin, size: 46)
                            .padding(.trailing, 2)
                        Text("3 things today.")
                            .font(Theme.font(9.5, .black))
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .padding(8)
                    }
                    .frame(width: 84, height: 84)
                    iconGrid(columns: 2, rows: 2)
                }
                iconGrid(columns: 4, rows: 2)
            }
            .padding(12)
        }
        .frame(height: 176, alignment: .top)
        .clipped()
    }

    fileprivate static func iconGrid(columns: Int, rows: Int, jiggle: Bool = false) -> some View {
        VStack(spacing: 8) {
            ForEach(0..<rows, id: \.self) { r in
                HStack(spacing: 8) {
                    ForEach(0..<columns, id: \.self) { c in
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.white.opacity(0.55))
                            .frame(width: 32, height: 32)
                            .rotationEffect(.degrees(jiggle ? ((r + c) % 2 == 0 ? -4 : 4) : 0))
                    }
                }
            }
        }
    }
}

// MARK: - Pieces

/// A phone, drawn: a dark bezel around a soft sky. Taller than it is wide, and
/// the pictures cut it off at the bottom, the way Finch's do.
private struct PhoneFrame<Content: View>: View {
    var width: CGFloat = 210
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(LinearGradient(colors: [Theme.hex(0xC9E6DA), Theme.hex(0xEAF3EC), Theme.hex(0xF5EBD8)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Theme.hex(0x1B1F24), lineWidth: 7))
            Capsule().fill(Theme.hex(0x1B1F24)).frame(width: 54, height: 12).padding(.top, 8)
            content().padding(.top, 22)
        }
        .frame(width: width)
        .frame(minHeight: 300, alignment: .top)
        .accessibilityHidden(true)
    }
}

/// A fingertip on the screen.
private struct Finger: View {
    var body: some View {
        Circle()
            .fill(Theme.coral.opacity(0.35))
            .overlay(Circle().stroke(Theme.coral, lineWidth: 3))
            .frame(width: 34, height: 34)
    }
}

/// Step 1: icons wiggling, a finger held on an empty spot.
private struct HoldPicture: View {
    var body: some View {
        PhoneFrame {
            VStack(spacing: 10) {
                WidgetHowToSheet.iconGrid(columns: 4, rows: 2, jiggle: true)
                Spacer(minLength: 0)
            }
            .padding(12)
        }
        .frame(height: 230, alignment: .top)
        .clipped()
        .overlay(alignment: .topTrailing) {
            Finger().padding(.trailing, 88).padding(.top, 150)
        }
    }
}

/// Step 2: the Edit pill and its menu, with Add Widget under the finger.
private struct EditPicture: View {
    var body: some View {
        PhoneFrame {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Edit")
                        .font(Theme.font(11, .heavy))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 12).frame(height: 24)
                        .background(Capsule().fill(Color.white.opacity(0.8)))
                    Spacer()
                    Text("Done")
                        .font(Theme.font(11, .heavy))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 12).frame(height: 24)
                        .background(Capsule().fill(Color.white.opacity(0.8)))
                }
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(["Add Widget", "Customize", "Edit Pages"], id: \.self) { row in
                        Text(row)
                            .font(Theme.font(11.5, row == "Add Widget" ? .black : .semibold))
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .frame(height: 30)
                            .background(row == "Add Widget" ? Theme.coralSoft : .clear)
                    }
                }
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.card))
                .frame(width: 130)
                Spacer(minLength: 0)
            }
            .padding(12)
        }
        .frame(height: 230, alignment: .top)
        .clipped()
        .overlay(alignment: .topLeading) {
            Finger().padding(.leading, 118).padding(.top, 76)
        }
    }
}

/// Step 3: the search field, the Prepkin row, Add Widget.
private struct SearchPicture: View {
    let name: String
    let speciesID: String
    let level: Int
    let skin: String

    var body: some View {
        PhoneFrame {
            VStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.muted)
                    Text("Prepkin")
                        .font(Theme.font(12, .bold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                }
                .padding(.horizontal, 10).frame(height: 30)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.card))
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(DayEditorView.D.mintTint)
                        .frame(width: 32, height: 32)
                        .overlay(SproutImage(speciesID: speciesID, level: level, skin: skin, size: 26)
                            .padding(.bottom, 2))
                    Text("Prepkin for Canvas")
                        .font(Theme.font(11.5, .black))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                }
                Text("Add Widget")
                    .font(Theme.font(11.5, .black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 30)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.coral))
                Spacer(minLength: 0)
            }
            .padding(12)
        }
        .frame(height: 230, alignment: .top)
        .clipped()
        .overlay(alignment: .topTrailing) {
            Finger().padding(.trailing, 56).padding(.top, 132)
        }
    }
}

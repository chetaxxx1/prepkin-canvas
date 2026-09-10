import SwiftUI
import PhotosUI

/// Photo to tasks. Four steps on one sheet: the consent line (once), pick a
/// photo, wait while it is read, then review the rows and add them. Nothing is
/// saved until the coral button.
struct ScanSheet: View {
    /// "Type them instead" — closes the reader and opens quick add. Both of the
    /// buttons that say it used to only close the sheet, which left the student
    /// nowhere.
    var onType: () -> Void

    /// Spelled out because every other stored property here is private, which
    /// would otherwise make the memberwise initialiser private too.
    init(onType: @escaping () -> Void = {}) { self.onType = onType }

    @EnvironmentObject var state: AppState
    @EnvironmentObject var plus: PlusStore
    @Environment(\.dismiss) private var dismiss

    private enum Step: Equatable {
        case consent
        case pick
        case reading
        case review
        case failed(ScanError)
    }

    @State private var step: Step = .pick
    @State private var image: UIImage?
    @State private var rows: [ScanRow] = []
    @State private var dropped: Set<String> = []
    @State private var remaining: Int?
    @State private var note: String?
    @State private var showCamera = false
    @State private var libraryPick: PhotosPickerItem?
    @State private var editingRow: ScanRow?
    /// Short steps sit at half height; the review list gets the full sheet.
    @State private var detent: PresentationDetent = .medium

    private enum D {
        static let grabber = Theme.hex(0xE2D8C6)
        static let shadow = Theme.hex(0x2E2622).opacity(0.05)
        static let field = Theme.hex(0xF4EDE1)
    }

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(D.grabber)
                .frame(width: 38, height: 5)
                .frame(height: 24)
            header
            ScrollView {
                Group {
                    switch step {
                    case .consent: consent
                    case .pick: pick
                    case .reading: reading
                    case .review: review
                    case .failed(let e): failed(e)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 40)
                .transition(.opacity)
            }
            .scrollIndicators(.hidden)
        }
        .animation(.easeInOut(duration: 0.25), value: step)
        .background(Theme.paper)
        .presentationDragIndicator(.hidden)
        .presentationBackground(Theme.paper)
        .presentationDetents([.medium, .large], selection: $detent)
        .onAppear { if !state.settings.scanConsentGiven { step = .consent } }
        .onChange(of: step) { _, new in
            if new == .reading || new == .review { detent = .large }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { picked in
                showCamera = false
                if let picked { start(picked) }
            }
            .ignoresSafeArea()
        }
        .onChange(of: libraryPick) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    start(img)
                }
                libraryPick = nil
            }
        }
        .sheet(item: $editingRow) { row in
            RowFixSheet(row: row) { fixed in
                if let i = rows.firstIndex(where: { $0.id == fixed.id }) { rows[i] = fixed }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(Theme.font(26, .black))
                .foregroundStyle(Theme.ink)
            Spacer()
            Text(quota)
                .font(Theme.font(12.5, .heavy))
                .foregroundStyle(Theme.muted)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 14)
    }

    private var title: String {
        switch step {
        case .consent: return "Scan a page"
        case .pick: return "Scan a page"
        case .reading: return "Reading it"
        case .review: return rows.isEmpty ? "Nothing found" : "Found \(kept.count)"
        case .failed: return "Hmm"
        }
    }

    private var quota: String {
        if let remaining { return "\(remaining) of \(ScanClient.monthlyLimit) left this month" }
        return "\(ScanClient.monthlyLimit) a month"
    }

    // MARK: - Consent

    private var consent: some View {
        VStack(alignment: .leading, spacing: 18) {
            card {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(Theme.mintDark)
                        Text("Before the first one")
                            .font(Theme.font(16, .black))
                            .foregroundStyle(Theme.ink)
                    }
                    Text("This sends the photo to Prepkin's server to read it. We keep nothing: not the photo, not the text. Skip this and type the tasks instead.")
                        .font(Theme.font(15, .bold))
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            primary("Okay, go on") {
                state.setScanConsent()
                step = .pick
            }
            Button("Type them instead") { typeInstead() }
                .font(Theme.font(14, .heavy))
                .foregroundStyle(Theme.muted)
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Pick

    private var pick: some View {
        VStack(spacing: 16) {
            card {
                VStack(spacing: 12) {
                    SproutImage(speciesID: state.activeChibiID, level: state.activeChibi.level,
                                skin: state.activeChibi.skinID, size: 88)
                    Text("A syllabus, a whiteboard, a planner page.")
                        .font(Theme.font(16, .black))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)
                    Text("Printed or handwritten. Get the whole page in, with the dates.")
                        .font(Theme.font(13.5, .bold))
                        .foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
            primary("Take a photo", glyph: "camera.fill") { showCamera = true }
            PhotosPicker(selection: $libraryPick, matching: .images) {
                HStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle").font(.system(size: 14, weight: .black))
                    Text("Choose from library").font(Theme.font(15.5, .black))
                }
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(RoundedRectangle(cornerRadius: 25, style: .continuous).fill(D.field))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Reading

    private var reading: some View {
        VStack(spacing: 18) {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(ScanBeam().clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous)))
            }
            HStack(spacing: 10) {
                ProgressView().tint(Theme.coral)
                Text("Reading the dates…")
                    .font(Theme.font(15, .black))
                    .foregroundStyle(Theme.ink)
            }
            Text("About ten seconds.")
                .font(Theme.font(13, .bold))
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Review

    private var kept: [ScanRow] { rows.filter { !dropped.contains($0.id) && $0.day != nil } }

    private var review: some View {
        VStack(spacing: 14) {
            if rows.isEmpty {
                card {
                    VStack(spacing: 8) {
                        Text(note ?? "No dates on that page.")
                            .font(Theme.font(15.5, .black))
                            .foregroundStyle(Theme.ink)
                            .multilineTextAlignment(.center)
                        Text("Try a page with due dates on it, or type them in.")
                            .font(Theme.font(13.5, .bold))
                            .foregroundStyle(Theme.muted)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
                primary("Try another photo", glyph: "camera.fill") { step = .pick }
            } else {
                Text("Tap a row to fix it. Swipe left to drop it. Dashed rows are guesses.")
                    .font(Theme.font(13, .bold))
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                VStack(spacing: 8) {
                    ForEach(rows.filter { !dropped.contains($0.id) }) { row in
                        reviewRow(row)
                            .transition(.opacity.combined(with: .move(edge: .leading)))
                    }
                }
                .animation(.snappy(duration: 0.25), value: dropped)
                primary(kept.count == 1 ? "Add 1 task" : "Add \(kept.count) tasks", glyph: "checkmark") { add() }
                    .disabled(kept.isEmpty)
                    .opacity(kept.isEmpty ? 0.5 : 1)
                Button("Scan another page") { step = .pick }
                    .font(Theme.font(14, .heavy))
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func reviewRow(_ row: ScanRow) -> some View {
        let day = row.day
        let dateLabel = day?.date().map { $0.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()) } ?? "No date"
        return Button { editingRow = row } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(row.title)
                        .font(Theme.font(15, .black))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    HStack(spacing: 6) {
                        chip(dateLabel, tint: day == nil ? Theme.coralSoft : Theme.mintSoft,
                             ink: day == nil ? Theme.coralShade : Theme.mintDark)
                        if let m = row.minute {
                            chip(String(format: "%d:%02d", m > 12 * 60 ? (m / 60 - 12) : max(m / 60, 1), m % 60) + (m >= 12 * 60 ? " PM" : " AM"),
                                 tint: D.field, ink: Theme.ink.opacity(0.7))
                        }
                        if let c = row.course, !c.isEmpty {
                            chip(c, tint: D.field, ink: Theme.ink.opacity(0.7))
                        }
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "pencil")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(Theme.dim)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.card)
                .shadow(color: D.shadow, radius: 8, y: 5))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(row.isShaky || day == nil ? Theme.coral.opacity(0.7) : .clear,
                              style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) { dropped.insert(row.id) } label: { Label("Drop this row", systemImage: "xmark") }
        }
        .gesture(
            DragGesture(minimumDistance: 30).onEnded { v in
                if v.translation.width < -60 && abs(v.translation.height) < 30 {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    dropped.insert(row.id)
                }
            }
        )
    }

    private func chip(_ text: String, tint: Color, ink: Color) -> some View {
        Text(text)
            .font(Theme.font(12, .black))
            .foregroundStyle(ink)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Capsule().fill(tint))
            .lineLimit(1)
    }

    // MARK: - Failed

    private func failed(_ e: ScanError) -> some View {
        VStack(spacing: 16) {
            card {
                VStack(spacing: 8) {
                    Text(e.errorDescription ?? "Something went wrong.")
                        .font(Theme.font(15.5, .black))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)
                    if case .notPlus = e {
                        Text("Your Plus didn't check out on the server. Restore the purchase and try again.")
                            .font(Theme.font(13.5, .bold))
                            .foregroundStyle(Theme.muted)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            if case .limitReached = e {
                primary("Type them instead") { typeInstead() }
            } else if case .notPlus = e {
                primary("Restore purchase") { Task { await plus.restore(); step = .pick } }
            } else {
                primary("Try again") { if let image { start(image) } else { step = .pick } }
            }
        }
    }

    // MARK: - Pieces

    private func card<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        content()
            .padding(18)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Theme.card)
                .shadow(color: D.shadow, radius: 11, y: 8))
    }

    private func primary(_ label: String, glyph: String? = nil, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let glyph { Image(systemName: glyph).font(.system(size: 14, weight: .black)) }
                Text(label).font(Theme.font(17, .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Theme.coral))
            .shadow(color: Theme.coral.opacity(0.3), radius: 10, y: 8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Behaviour

    private func typeInstead() {
        dismiss()
        onType()
    }

    private func start(_ img: UIImage) {
        image = img
        rows = []
        dropped = []
        note = nil
        step = .reading
        Task {
            guard let client = ScanClient() else {
                step = .failed(.server("The reader isn't set up yet."))
                return
            }
            do {
                let result = try await client.scan(img)
                rows = result.rows
                remaining = result.remaining
                note = result.note
                UINotificationFeedbackGenerator().notificationOccurred(rows.isEmpty ? .warning : .success)
                step = .review
            } catch let e as ScanError {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                step = .failed(e)
            } catch {
                step = .failed(.server("Something went wrong."))
            }
        }
    }

    private func add() {
        let tasks = kept.compactMap { $0.task(source: "From a photo") }
        state.addDated(tasks)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}

/// A soft band that sweeps down the photo while the server reads it.
private struct ScanBeam: View {
    @State private var y: CGFloat = -0.2
    var body: some View {
        GeometryReader { geo in
            LinearGradient(colors: [.clear, Theme.mint.opacity(0.55), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 60)
                .offset(y: y * geo.size.height)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { y = 1.0 }
                }
        }
        .allowsHitTesting(false)
    }
}

/// Fix one row: title, day, time.
private struct RowFixSheet: View {
    @State var row: ScanRow
    let onSave: (ScanRow) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var date: Date = Date()
    @State private var hasTime = false
    @State private var time = Date()

    var body: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Theme.hex(0xE2D8C6))
                .frame(width: 38, height: 5)
                .frame(height: 24)
            Text("Fix this row")
                .font(Theme.font(22, .black))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            TextField("Title", text: $row.title)
                .font(Theme.font(17, .bold))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.card))
            DatePicker("Day", selection: $date, displayedComponents: .date)
                .font(Theme.font(15, .bold))
                .tint(Theme.coral)
            Toggle("At a time", isOn: $hasTime.animation())
                .font(Theme.font(15, .bold))
                .tint(Theme.mint)
            if hasTime {
                DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                    .font(Theme.font(15, .bold))
                    .tint(Theme.coral)
            }
            Spacer()
            Button {
                var fixed = row
                fixed.date = DayKey(date).raw
                if hasTime {
                    let c = Calendar.current.dateComponents([.hour, .minute], from: time)
                    fixed.time = String(format: "%02d:%02d", c.hour ?? 0, c.minute ?? 0)
                } else {
                    fixed.time = nil
                }
                fixed.confidence = 1
                onSave(fixed)
                dismiss()
            } label: {
                Text("Save")
                    .font(Theme.font(17, .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Theme.coral))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 24)
        .background(Theme.paper)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Theme.paper)
        .onAppear {
            date = row.day?.date() ?? Date()
            if let m = row.minute {
                hasTime = true
                time = Calendar.current.date(bySettingHour: m / 60, minute: m % 60, second: 0, of: Date()) ?? Date()
            }
        }
    }
}

/// The system camera. Returns nil when the student backs out.
struct CameraPicker: UIViewControllerRepresentable {
    let done: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let p = UIImagePickerController()
        p.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        p.delegate = context.coordinator
        return p
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(done: done) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let done: (UIImage?) -> Void
        init(done: @escaping (UIImage?) -> Void) { self.done = done }
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            done(info[.originalImage] as? UIImage)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { done(nil) }
    }
}

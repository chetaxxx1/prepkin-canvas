import SwiftUI
import Combine

@main
struct PrepkinCanvasApp: App {
    @StateObject private var state = AppState()
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(state)
                // The four moments the day can turn over: coming back to the app,
                // crossing midnight with it open, changing time zone, and a hand-set
                // clock. Each one rebuilds today's list from the templates.
                .onChange(of: phase) { _, new in
                    switch new {
                    case .active:
                        state.refreshDay()
                        Task { await state.syncCanvas() }
                    case .background, .inactive: state.flush()
                    @unknown default: break
                    }
                }
                // A cold launch can land with the scene already `.active`, in which
                // case `onChange` has nothing to diff and never fires. Idempotent,
                // so running alongside `onChange` on ordinary launches is fine.
                .task {
                    state.refreshDay()
                    await state.syncCanvas()
                }
                .onReceive(dayChanged) { _ in state.refreshDay() }
                .onReceive(timeZoneChanged) { _ in state.refreshDay() }
        }
    }

    private var dayChanged: some Publisher<Notification, Never> {
        NotificationCenter.default.publisher(for: .NSCalendarDayChanged)
            .receive(on: DispatchQueue.main)
    }

    private var timeZoneChanged: some Publisher<Notification, Never> {
        NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)
            .receive(on: DispatchQueue.main)
    }
}

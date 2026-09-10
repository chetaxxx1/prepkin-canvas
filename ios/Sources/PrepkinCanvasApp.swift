import SwiftUI
import Combine

@main
struct PrepkinCanvasApp: App {
    @StateObject private var state = AppState()
    /// One store for the whole app: the Plus sheet and the scanner both read it.
    @StateObject private var plus = PlusStore()
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(state)
                .environmentObject(plus)
                .task {
                    await plus.load()
                    state.syncPlus(paid: plus.entitlement.isActive)
                }
                // A subscription can start, lapse, be restored on another phone or
                // be refunded while the app is open. `PlusStore` watches
                // `Transaction.updates` for all four; this is the one line that
                // carries the answer into the gates.
                .onReceive(plus.$entitlement) { state.syncPlus(paid: $0.isActive) }
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

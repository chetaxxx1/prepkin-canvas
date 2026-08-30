import XCTest
@testable import PrepkinCanvas

/// The client-picking and sync rules in `AppState` — the seam where fake demo
/// data could leak into a real install if we get it wrong.
@MainActor
final class AppStateTests: XCTestCase {
    private var dir: URL!

    override func setUpWithError() throws {
        dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("appstate-tests-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: dir)
    }

    private func makeStore() -> Store {
        Store(directory: dir, defaults: UserDefaults(suiteName: "appstate-\(UUID().uuidString)")!,
              debounce: 0)
    }

    // MARK: - Which client

    private let configured = BridgeConfig(url: "https://x.supabase.co", publishableKey: "k")
    private let unconfigured = BridgeConfig(url: "", publishableKey: "")

    func testAnUnconfiguredCheckoutRunsOnSampleData() {
        let client = AppState.defaultClient(for: GameState(), config: unconfigured)
        XCTAssertTrue(client is MockCanvasClient)
    }

    func testAConfiguredBuildWithoutACodeGetsNoClientAtAll() {
        let client = AppState.defaultClient(for: GameState(), config: configured)
        XCTAssertNil(client, "an unpaired install must not fall back to fake homework")
    }

    func testAConfiguredBuildWithACodeTalksToTheBridge() {
        var state = GameState()
        state.ensurePairingCode()
        let client = AppState.defaultClient(for: state, config: configured)
        XCTAssertTrue(client is SupabaseCanvasClient)
    }

    // MARK: - Sync

    func testSyncWithNoClientLeavesTheListAloneAndSaysWhy() async {
        let state = AppState(store: makeStore(), makeClient: { _ in nil })
        await state.syncCanvas()
        XCTAssertTrue(state.game.canvasItems.isEmpty)
        XCTAssertNotNil(state.canvasStatus)
    }

    func testAResponseFromBeforeADisconnectIsDropped() async {
        // A client slow enough that the user can disconnect mid-fetch.
        struct SlowClient: CanvasSyncClient {
            func fetchTodo() async throws -> CanvasSnapshot {
                try? await Task.sleep(for: .milliseconds(50))
                return CanvasSnapshot(tasks: [
                    CanvasItem(id: "c-stale", title: "Old quiz", courseName: "History", dueAt: nil),
                ])
            }
        }
        let state = AppState(store: makeStore(),
                             makeClient: { $0.pairingCode != nil ? SlowClient() : nil })
        state.ensurePairingCode()

        let inFlight = Task { await state.syncCanvas() }
        try? await Task.sleep(for: .milliseconds(10))
        state.unpair()
        await inFlight.value

        XCTAssertTrue(state.game.canvasItems.isEmpty,
                      "a fetch started under the old pairing must not resurrect its data")
    }
}

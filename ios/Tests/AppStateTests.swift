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

    func testAConfiguredBuildWithACodeAndTokenTalksToTheBridge() {
        var state = GameState()
        state.ensurePairingCode()
        state.pairingToken = "a-token-the-bridge-handed-out"
        let client = AppState.defaultClient(for: state, config: configured)
        XCTAssertTrue(client is SupabaseCanvasClient)
    }

    func testACodeWithNoTokenIsNotYetAPairing() {
        // The code alone opens nothing now. Until claim_code answers, there is
        // nothing to talk to — and inventing a client would only produce 404s.
        var state = GameState()
        state.ensurePairingCode()
        XCTAssertNil(AppState.defaultClient(for: state, config: configured))
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

    // MARK: - The Canvas card's one truth

    private struct WaitingClient: CanvasSyncClient {
        func fetchTodo() async throws -> CanvasSnapshot { throw BridgeError.notPairedYet }
    }
    private struct OfflineClient: CanvasSyncClient {
        func fetchTodo() async throws -> CanvasSnapshot { throw BridgeError.server(status: 503) }
    }
    private struct ListClient: CanvasSyncClient {
        func fetchTodo() async throws -> CanvasSnapshot {
            CanvasSnapshot(tasks: [CanvasItem(id: "c-1", title: "Lab 3", courseName: "Physics", dueAt: nil)])
        }
    }

    func testNoClientIsNotSetUp() async {
        let state = AppState(store: makeStore(), makeClient: { _ in nil })
        await state.syncCanvas()
        XCTAssertEqual(state.canvasLink, .notSetUp)
    }

    func testAPairingWithNoListYetIsWaiting() async {
        let state = AppState(store: makeStore(), makeClient: { $0.pairingCode != nil ? WaitingClient() : nil })
        _ = state.ensurePairingCode()
        await state.syncCanvas()
        XCTAssertEqual(state.canvasLink, .waitingForLaptop)
    }

    func testAListMakesItConnected() async {
        let state = AppState(store: makeStore(), makeClient: { $0.pairingCode != nil ? ListClient() : nil })
        _ = state.ensurePairingCode()
        await state.syncCanvas()
        XCTAssertEqual(state.canvasLink, .connected)
        XCTAssertNil(state.canvasStatus)
    }

    func testAFailedCheckIsOfflineAndKeepsTheLastList() async {
        // Reach the laptop once, then lose it: the card must say so and keep the list.
        var reachable = true
        let state = AppState(store: makeStore(), makeClient: { game in
            guard game.pairingCode != nil else { return nil }
            return reachable ? ListClient() : OfflineClient()
        })
        _ = state.ensurePairingCode()
        await state.syncCanvas()
        reachable = false
        await state.syncCanvas()
        XCTAssertEqual(state.canvasLink, .offline)
        XCTAssertEqual(state.game.canvasItems.count, 1, "a dropped connection is not a reason to empty somebody's day")
        XCTAssertFalse((state.canvasStatus ?? "").lowercased().contains("bridge"))
    }
}

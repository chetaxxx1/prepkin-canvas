import XCTest
@testable import PrepkinCanvas

final class PairingCodeTests: XCTestCase {
    func testACodeIsEightCharactersWithADash() {
        for _ in 0..<200 {
            let code = PairingCode.generate()
            XCTAssertEqual(code.count, 9)
            XCTAssertEqual(code[code.index(code.startIndex, offsetBy: 4)], "-")
            XCTAssertTrue(PairingCode.isValid(code))
        }
    }

    func testTheAlphabetHasNoCharactersPeopleConfuse() {
        for bad: Character in ["O", "0", "I", "1"] {
            XCTAssertFalse(PairingCode.alphabet.contains(bad), "\(bad) is too easy to mistype")
        }
    }

    func testItAcceptsWhatSomebodyActuallyTypes() {
        XCTAssertEqual(PairingCode.normalize("abcd-efgh"), "ABCD-EFGH")
        XCTAssertEqual(PairingCode.normalize("abcdefgh"), "ABCD-EFGH")
        XCTAssertEqual(PairingCode.normalize(" ABCD EFGH "), "ABCD-EFGH")
        XCTAssertEqual(PairingCode.normalize("ABCD--EFGH"), "ABCD-EFGH")
    }

    func testItRejectsTheWrongLength() {
        XCTAssertNil(PairingCode.normalize("ABC-EFGH"))
        XCTAssertNil(PairingCode.normalize("ABCD-EFGHJ"))
        XCTAssertNil(PairingCode.normalize(""))
    }

    func testCodesAreNotAllTheSame() {
        XCTAssertGreaterThan(Set((0..<50).map { _ in PairingCode.generate() }).count, 45)
    }
}

final class BridgeDecodingTests: XCTestCase {
    private func decode(_ json: String) throws -> [CanvasItem] {
        try SupabaseCanvasClient.decode(Data(json.utf8)).tasks
    }

    func testNoRowYetIsNotAnEmptyList() {
        // `null` means the laptop has never pushed. Treating it as an empty list
        // would wipe assignments the app already had.
        XCTAssertThrowsError(try decode("null")) { error in
            XCTAssertEqual(error as? BridgeError, .notPairedYet)
        }
    }

    func testAnEmptyPushReallyIsEmpty() throws {
        XCTAssertEqual(try decode("[]"), [])
    }

    func testItReadsWhatTheExtensionSends() throws {
        let items = try decode("""
        [{"id":"c-77","title":"Ch. 5 Problem Set","courseName":"AP Physics","dueAt":"2026-09-01T23:59:00Z"},
         {"id":"c-78","title":"Reading","courseName":"English 11","dueAt":null}]
        """)
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].id, "c-77")
        XCTAssertEqual(items[0].courseName, "AP Physics")
        XCTAssertNotNil(items[0].dueAt)
        XCTAssertNil(items[1].dueAt, "an assignment with no due date is normal")
    }

    func testFractionalSecondsDoNotLoseTheWholeSync() throws {
        let items = try decode("""
        [{"id":"c-1","title":"Quiz","courseName":"APUSH","dueAt":"2026-09-01T23:59:00.000Z"}]
        """)
        XCTAssertNotNil(items[0].dueAt)
    }
}

final class PairingStateTests: XCTestCase {
    func testTheCodeIsMadeOnceAndKept() {
        var s = GameState()
        XCTAssertNil(s.pairingCode)
        let first = s.ensurePairingCode()
        XCTAssertEqual(s.ensurePairingCode(), first, "regenerating would orphan a paired laptop")
    }

    func testDisconnectingClearsTheCanvasSide() {
        var s = GameState()
        s.ensurePairingCode()
        s.applyCanvas(CanvasSnapshot(tasks: [CanvasItem(id: "c-1", title: "Essay", courseName: "English", dueAt: nil)]))
        s.unpair()
        XCTAssertNil(s.pairingCode)
        XCTAssertTrue(s.canvasItems.isEmpty)
        XCTAssertNil(s.lastCanvasSyncAt)
    }

    func testAnOlderSaveWithNoPairingStillLoads() throws {
        // Files written before the bridge existed have no `pairingCode` key at all.
        let json = #"{"version":2,"state":{"ledger":{"openingBalance":42,"entries":[]},"owned":[{"speciesID":"slime","level":1}],"activeChibiID":"slime","sceneID":"dorm","ownedScenes":["dorm"],"completedLessons":[],"templates":[],"canvasItems":[],"currentDay":"2026-08-29","maxDayReached":"2026-08-29","settings":{"remindersEnabled":false,"nudgeHour":19,"dueRemindersEnabled":true,"comeBackRemindersEnabled":true},"lastOpenedAt":"2026-08-29T10:00:00Z"}}"#
        struct Envelope: Decodable { let state: GameState }
        let back = try Store.decoder.decode(Envelope.self, from: Data(json.utf8))
        XCTAssertEqual(back.state.ledger.balance, 42)
        XCTAssertNil(back.state.pairingCode)
    }
}

final class CanvasSnapshotTests: XCTestCase {
    private func decode(_ json: String) throws -> CanvasSnapshot {
        try SupabaseCanvasClient.decode(Data(json.utf8))
    }

    func testItReadsCoursesAndGradesAlongsideTheTasks() throws {
        let snap = try decode("""
        {"tasks":[{"id":"c-a1","title":"Lab writeup","courseName":"AP Physics","dueAt":null,
                   "courseId":"1","colorHex":"#FF6F61","submittedAt":"2026-08-30T10:00:00Z",
                   "score":47,"pointsPossible":50}],
         "courses":[{"id":"1","name":"AP Physics","code":"PHYS-11","score":88.5,"grade":"B+","colorHex":"#FF6F61"}]}
        """)
        XCTAssertEqual(snap.courses.first?.score, 88.5)
        XCTAssertEqual(snap.courses.first?.grade, "B+")
        XCTAssertEqual(snap.tasks.first?.score, 47)
        XCTAssertTrue(snap.tasks.first!.isSubmitted)
    }

    func testAnUngradedCourseIsNilNotZero() throws {
        let snap = try decode(#"{"courses":[{"id":"3","name":"Seminar","score":null,"grade":null}]}"#)
        XCTAssertNil(snap.courses.first?.score, "no grade yet is not a failing grade")
    }

    func testTheOlderBareArrayPushStillWorks() throws {
        // Whatever an out-of-date extension is still sending has to keep working.
        let snap = try decode(#"[{"id":"c-1","title":"Essay","courseName":"English 11","dueAt":null}]"#)
        XCTAssertEqual(snap.tasks.count, 1)
        XCTAssertTrue(snap.courses.isEmpty)
    }

    func testAPushWithNoCoursesKeyIsFine() throws {
        let snap = try decode(#"{"tasks":[]}"#)
        XCTAssertTrue(snap.tasks.isEmpty)
        XCTAssertTrue(snap.courses.isEmpty)
    }

    func testAJunkDueDateLosesTheDateNotTheWholeList() throws {
        // The extension deliberately keeps an assignment whose due date it could
        // not parse. One bad date must not sink the other nine assignments.
        let snap = try decode("""
        {"tasks":[{"id":"c-1","title":"Essay","courseName":"English 11","dueAt":"2026-09-01T23:59:00Z"},
                  {"id":"c-2","title":"Quiz","courseName":"APUSH","dueAt":"whenever the sub says"},
                  {"id":"c-3","title":"Reading","courseName":"English 11","dueAt":null,
                   "submittedAt":"also junk"}]}
        """)
        XCTAssertEqual(snap.tasks.map(\.id), ["c-1", "c-2", "c-3"])
        XCTAssertNotNil(snap.tasks[0].dueAt)
        XCTAssertNil(snap.tasks[1].dueAt, "an unreadable date reads as no date")
        XCTAssertNil(snap.tasks[2].submittedAt, "junk must not count as handed in")
        XCTAssertFalse(snap.tasks[2].isSubmitted)
    }
}

final class SubmissionTests: XCTestCase {
    private func submitted(_ id: String) -> CanvasItem {
        var item = CanvasItem(id: id, title: "Lab writeup", courseName: "AP Physics", dueAt: nil)
        item.submittedAt = Date()
        return item
    }

    func testHandingSomethingInPaysWithoutATap() {
        var s = GameState()
        s.applyCanvas(CanvasSnapshot(tasks: [submitted("c-1")]))
        XCTAssertEqual(s.ledger.balance, TaskKind.canvas.reward)
        XCTAssertTrue(s.tasks.first { $0.id == "c-1" }!.done)
    }

    func testResyncingDoesNotPayTwice() {
        var s = GameState()
        s.applyCanvas(CanvasSnapshot(tasks: [submitted("c-1")]))
        s.applyCanvas(CanvasSnapshot(tasks: [submitted("c-1")]))
        s.applyCanvas(CanvasSnapshot(tasks: [submitted("c-1")]))
        XCTAssertEqual(s.ledger.balance, TaskKind.canvas.reward)
    }

    func testTickingItYourselfFirstDoesNotDoublePay() {
        var s = GameState()
        var item = CanvasItem(id: "c-1", title: "Lab writeup", courseName: "AP Physics", dueAt: nil)
        s.applyCanvas(CanvasSnapshot(tasks: [item]))
        s.complete(taskID: "c-1", reward: TaskKind.canvas.reward)
        item.submittedAt = Date()
        s.applyCanvas(CanvasSnapshot(tasks: [item]))   // Canvas catches up later
        XCTAssertEqual(s.ledger.balance, TaskKind.canvas.reward)
    }

    func testYouCannotUntickSomethingCanvasSaysYouHandedIn() {
        var s = GameState()
        s.applyCanvas(CanvasSnapshot(tasks: [submitted("c-1")]))
        s.uncomplete(taskID: "c-1")
        XCTAssertTrue(s.tasks.first { $0.id == "c-1" }!.done)
        XCTAssertTrue(s.tasks.first { $0.id == "c-1" }!.isLocked)
        XCTAssertEqual(s.ledger.balance, TaskKind.canvas.reward, "and the coins stay")
    }

    func testYourOwnTasksAreStillYoursToUntick() {
        var s = GameState()
        let task = s.tasks.first { $0.kind == .life }!
        s.complete(taskID: task.id, reward: task.reward)
        s.uncomplete(taskID: task.id)
        XCTAssertEqual(s.ledger.balance, 0)
    }
}

final class SchemaGrowthTests: XCTestCase {
    /// The whole point of the hand-written decoder: a save written before a field
    /// existed still loads, with the new field at its default.
    func testAV2SaveWithNoCoursesKeyStillLoads() throws {
        let json = #"{"ledger":{"openingBalance":1130,"entries":[]},"owned":[{"speciesID":"slime","level":3}],"activeChibiID":"slime","sceneID":"night","ownedScenes":["night"],"completedLessons":[],"templates":[],"canvasItems":[],"currentDay":"2026-08-29","maxDayReached":"2026-08-29","settings":{"remindersEnabled":false,"nudgeHour":19,"dueRemindersEnabled":true,"comeBackRemindersEnabled":true},"lastOpenedAt":"2026-08-29T10:00:00Z"}"#
        let state = try Store.decoder.decode(GameState.self, from: Data(json.utf8))
        XCTAssertEqual(state.ledger.balance, 1130, "coins survive a schema change")
        XCTAssertEqual(state.activeChibi.level, 3)
        // The old room names became the Sprout tank scenes (Theme.swift): night is deep.
        // Pinning the mapping here means a future edit to Scene0.retired trips this test
        // instead of silently moving somebody's tank.
        XCTAssertEqual(Scene0.retired["night"], "deep",
                       "this save is exercising the night-to-deep retirement")
        XCTAssertEqual(state.sceneID, "deep")
        XCTAssertEqual(state.ownedScenes, ["lagoon", "deep"],
                       "the scene she paid for came across as its tank")
        XCTAssertTrue(state.canvasCourses.isEmpty)
    }

    func testAnAlmostEmptySaveDoesNotThrow() throws {
        let state = try Store.decoder.decode(GameState.self, from: Data("{}".utf8))
        XCTAssertEqual(state.ledger.balance, 0)
        XCTAssertEqual(state.activeChibiID, "slime")
        XCTAssertFalse(state.templates.isEmpty, "a save with nothing in it still gets the starter tasks")
    }
}

/// The half of the bridge that runs the other way: what the laptop asks for, and
/// what the phone pays. Before this existed the extension queued finished focus
/// sessions and look purchases, pushed them, cleared them, and the phone never
/// looked — so the coins it promised never arrived.
final class BridgeRequestTests: XCTestCase {
    private func request(_ kind: String, at seconds: TimeInterval,
                         minutes: Int? = nil, lookId: String? = nil,
                         price: Int? = nil) -> BridgeRequest {
        BridgeRequest(kind: kind, taskId: kind == "focus" ? "c-a1" : nil,
                      minutes: minutes, lookId: lookId, price: price,
                      at: Date(timeIntervalSince1970: seconds))
    }

    /// Funds the ledger the way the app really would — several finished focus
    /// sessions. One 400-minute session would be refused, and rightly so.
    private func stateWithCoins(_ coins: Int) -> GameState {
        var game = GameState()
        var paid = 0, at = 1.0
        while paid < coins {
            let minutes = min(240, coins - paid)
            game.applyBridgeRequests([request("focus", at: at, minutes: minutes)])
            paid += minutes
            at += 1
        }
        XCTAssertEqual(game.ledger.balance, coins)
        // Reset the watermark so the test's own requests still count as new.
        game.requestsAppliedAt = nil
        return game
    }

    func testAFinishedFocusSessionIsPaid() {
        var game = GameState()
        game.applyBridgeRequests([request("focus", at: 100, minutes: 25)])
        XCTAssertEqual(game.ledger.balance, 25, "a minute of focus is a coin")
        XCTAssertEqual(game.lifetime.focusMinutes, 25)
    }

    func testTheSameRequestArrivingTwiceIsPaidOnce() {
        // The extension re-sends until the phone confirms, so this is the normal
        // case, not an edge case.
        var game = GameState()
        let session = request("focus", at: 100, minutes: 25)
        game.applyBridgeRequests([session])
        game.requestsAppliedAt = nil          // as if the confirmation was lost
        game.applyBridgeRequests([session])
        XCTAssertEqual(game.ledger.balance, 25, "the ledger key stops the second payment")
    }

    func testRequestsAlreadySettledAreSkipped() {
        var game = GameState()
        game.applyBridgeRequests([request("focus", at: 100, minutes: 25)])
        game.applyBridgeRequests([request("focus", at: 100, minutes: 25),
                                  request("focus", at: 200, minutes: 15)])
        XCTAssertEqual(game.ledger.balance, 40, "only the newer session is paid")
    }

    func testBuyingALookSpendsTheCoinsAndRecordsIt() {
        var game = stateWithCoins(400)
        game.applyBridgeRequests([request("look", at: 500, lookId: "woodland", price: 300)])
        XCTAssertEqual(game.ledger.balance, 100)
        XCTAssertTrue(game.ownedLooks.contains("woodland"))
    }

    func testALookYouCannotAffordIsRefusedRatherThanOwed() {
        var game = stateWithCoins(50)
        game.applyBridgeRequests([request("look", at: 500, lookId: "tidepool", price: 450)])
        XCTAssertEqual(game.ledger.balance, 50, "the ledger never overdraws")
        XCTAssertFalse(game.ownedLooks.contains("tidepool"), "and it is not quietly handed over")
    }

    func testTheBridgeStateCarriesTheLeagueAsPlainNumbers() {
        let game = stateWithCoins(50)
        let league = game.bridgeState.league
        XCTAssertEqual(league?.tier, game.league.tier.rawValue)
        XCTAssertEqual(league?.points, game.leaguePoints)
        XCTAssertEqual(league?.bar, LeagueRules.bar(for: game.league.tier))
        XCTAssertEqual(league?.week, game.league.weekStart.raw)
        XCTAssertNil(league?.board, "no pod this week, so no strangers on the laptop")
    }

    func testALookIsNotPaidForTwice() {
        var game = stateWithCoins(700)
        game.applyBridgeRequests([request("look", at: 500, lookId: "beanie", price: 300)])
        game.applyBridgeRequests([request("look", at: 600, lookId: "beanie", price: 300)])
        XCTAssertEqual(game.ledger.balance, 400, "already owned, so nothing more is charged")
    }

    func testNonsenseFromTheBridgeIsIgnoredRatherThanPaid() {
        var game = stateWithCoins(1000)
        let before = game.ledger.balance
        game.applyBridgeRequests([
            request("focus", at: 10, minutes: 100_000),        // a week of "focus"
            request("focus", at: 11, minutes: -5),
            request("look", at: 12, lookId: "", price: 10),
            request("look", at: 13, lookId: "x", price: -900), // a purchase that pays you
            request("wat", at: 14),
        ])
        XCTAssertEqual(game.ledger.balance, before, "none of that is a real request")
        XCTAssertEqual(game.ownedLooks, ["classic"])
    }

    func testThePhoneReportsHowFarItHasPaid() {
        // This is what lets the extension stop re-sending, and what stops a
        // finished session falling down the gap between two pushes.
        var game = GameState()
        let newest = game.applyBridgeRequests([request("focus", at: 100, minutes: 25),
                                               request("focus", at: 300, minutes: 15)])
        XCTAssertEqual(newest, Date(timeIntervalSince1970: 300))
        XCTAssertEqual(game.bridgeState.requestsAppliedAt, Date(timeIntervalSince1970: 300))
        XCTAssertEqual(game.bridgeState.coins, 40)
    }

    func testTheWatermarkKeepsItsMilliseconds() {
        // Found on the simulator: 12:06:26Z never retires a request stamped
        // 12:06:26.126Z, so the laptop re-sent it on every push.
        XCTAssertEqual(SupabaseCanvasClient.stamp(Date(timeIntervalSince1970: 26.126)),
                       "1970-01-01T00:00:26.126Z")
    }

    func testTheExtensionsRequestsSurviveTheWire() throws {
        let json = """
        {"tasks":[],"courses":[],"requests":[
          {"kind":"focus","taskId":"c-a1","minutes":25,"at":"2026-09-04T10:00:00Z"},
          {"kind":"look","lookId":"woodland","price":300,"at":"2026-09-04T10:05:00Z"},
          {"kind":"focus","minutes":15,"at":"not a date"}
        ]}
        """
        let snapshot = try SupabaseCanvasClient.decode(Data(json.utf8))
        XCTAssertEqual(snapshot.requests.count, 2, "a request with no readable time has no safe key")
        XCTAssertEqual(snapshot.requests.first?.minutes, 25)
        XCTAssertEqual(snapshot.requests.last?.lookId, "woodland")
    }

    func testUnpairingForgetsTheTokenAndTheWatermark() {
        var game = GameState()
        game.pairingCode = "ABCD-EFGH"
        game.pairingToken = "secret"
        game.applyBridgeRequests([request("focus", at: 100, minutes: 25)])
        game.unpair()
        XCTAssertNil(game.pairingToken, "the token must not outlive the pairing")
        XCTAssertNil(game.requestsAppliedAt)
        XCTAssertEqual(game.ledger.balance, 25, "coins already earned are kept")
    }
}

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
        XCTAssertEqual(state.sceneID, "night")
        XCTAssertTrue(state.canvasCourses.isEmpty)
    }

    func testAnAlmostEmptySaveDoesNotThrow() throws {
        let state = try Store.decoder.decode(GameState.self, from: Data("{}".utf8))
        XCTAssertEqual(state.ledger.balance, 0)
        XCTAssertEqual(state.activeChibiID, "slime")
        XCTAssertFalse(state.templates.isEmpty, "a save with nothing in it still gets the starter tasks")
    }
}

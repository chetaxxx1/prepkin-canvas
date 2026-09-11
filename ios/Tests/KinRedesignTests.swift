import XCTest
@testable import PrepkinCanvas

/// The Kin tab's rules from the 2026-09-11 redesign: the friendship ladder, the
/// Firsts list, the card's three numbers, and the Wardrobe editor's None tile.
final class KinRedesignTests: XCTestCase {
    private let day1 = DayKey(raw: "2026-09-01")

    private func fresh() -> GameState {
        var s = GameState()
        s.currentDay = day1
        s.maxDayReached = day1
        return s
    }

    private func date(_ iso: String) -> Date {
        let f = ISO8601DateFormatter()
        return f.date(from: iso)!
    }

    // MARK: - Friendship ladder

    func testStagesArriveByDaysWithoutCare() {
        XCTAssertEqual(FriendshipStage.stage(days: 0, careTaps: 0), .justMet)
        XCTAssertEqual(FriendshipStage.stage(days: 2, careTaps: 0), .justMet)
        XCTAssertEqual(FriendshipStage.stage(days: 3, careTaps: 0), .tankmates)
        XCTAssertEqual(FriendshipStage.stage(days: 13, careTaps: 0), .tankmates)
        XCTAssertEqual(FriendshipStage.stage(days: 14, careTaps: 0), .buddies)
        XCTAssertEqual(FriendshipStage.stage(days: 59, careTaps: 0), .buddies)
        XCTAssertEqual(FriendshipStage.stage(days: 60, careTaps: 0), .besties)
        XCTAssertEqual(FriendshipStage.stage(days: 179, careTaps: 0), .besties)
        XCTAssertEqual(FriendshipStage.stage(days: 180, careTaps: 0), .oldFriends)
        XCTAssertEqual(FriendshipStage.stage(days: 1000, careTaps: 0), .oldFriends)
    }

    func testCareMovesTheEarlyStagesAndNotTheLateOnes() {
        // Four taps are a day. Twelve taps on the first day makes Tankmates.
        XCTAssertEqual(FriendshipStage.stage(days: 0, careTaps: 11), .justMet)
        XCTAssertEqual(FriendshipStage.stage(days: 0, careTaps: 12), .tankmates)
        // Care is capped at thirty days, so no amount of tapping makes Besties on day one.
        XCTAssertEqual(FriendshipStage.stage(days: 0, careTaps: 10_000), .buddies)
        XCTAssertEqual(FriendshipStage.stage(days: 3, careTaps: 10_000), .buddies)
        XCTAssertEqual(FriendshipStage.stage(days: 14, careTaps: 10_000), .buddies)
        XCTAssertEqual(FriendshipStage.stage(days: 30, careTaps: 10_000), .besties)
        XCTAssertEqual(FriendshipStage.stage(days: 60, careTaps: 10_000), .besties)
        XCTAssertEqual(FriendshipStage.stage(days: 149, careTaps: 10_000), .besties)
        XCTAssertEqual(FriendshipStage.stage(days: 150, careTaps: 10_000), .oldFriends)
        XCTAssertEqual(FriendshipStage.stage(days: 180, careTaps: 10_000), .oldFriends)
    }

    func testAStageNeverGoesDown() {
        // The pure rule only climbs as either input climbs.
        var last = FriendshipStage.justMet
        for days in 0...400 {
            for taps in [0, 4, 40, 400] {
                let s = FriendshipStage.stage(days: days, careTaps: taps)
                XCTAssertGreaterThanOrEqual(s, FriendshipStage.stage(days: days, careTaps: 0))
                if taps == 0 {
                    XCTAssertGreaterThanOrEqual(s, last)
                    last = s
                }
            }
        }
        // And the stored kin keeps its high-water mark even if the clock runs backwards.
        var s = fresh()
        s.owned[0].adoptedAt = date("2026-06-01T09:00:00Z")
        let later = date("2026-08-15T09:00:00Z")           // 75 days: Besties
        XCTAssertEqual(s.settleFriendship(now: later), .besties)
        XCTAssertEqual(s.friendshipStage(s.activeChibi, now: later), .besties)
        let earlier = date("2026-06-02T09:00:00Z")         // clock wound back to day 2
        XCTAssertEqual(s.friendshipStage(s.activeChibi, now: earlier), .besties,
                       "a stage reached is a stage kept")
        XCTAssertNil(s.settleFriendship(now: earlier), "and settling again reports nothing")
    }

    func testCareTapsAreCountedOnTheActiveKinAndSettleTheStage() {
        var s = fresh()
        s.owned[0].adoptedAt = date("2026-09-01T09:00:00Z")
        let now = date("2026-09-01T12:00:00Z")
        XCTAssertEqual(s.friendshipStage(s.activeChibi, now: now), .justMet)
        var rose: [FriendshipStage] = []
        for _ in 0..<12 {
            if let stage = s.recordCare(now: now) { rose.append(stage) }
        }
        XCTAssertEqual(s.activeChibi.careTaps, 12)
        XCTAssertEqual(rose, [.tankmates], "exactly one toast, on the tap that crossed the line")
        XCTAssertEqual(s.friendshipStage(s.activeChibi, now: now), .tankmates)
    }

    func testTheWordsAreTheFiveOnTheBrief() {
        XCTAssertEqual(FriendshipStage.allCases.map(\.name),
                       ["Just met", "Tankmates", "Buddies", "Besties", "Old friends"])
        for stage in FriendshipStage.allCases {
            XCTAssertLessThan(stage.name.count, 40)
            XCTAssertFalse(stage.name.contains("!"))
        }
    }

    func testFriendshipSurvivesASaveAndLoad() throws {
        var s = fresh()
        s.owned[0].adoptedAt = date("2026-09-01T09:00:00Z")
        for _ in 0..<5 { s.recordCare(now: date("2026-09-01T12:00:00Z")) }
        s.owned[0].stageReached = FriendshipStage.buddies.rawValue
        let data = try JSONEncoder().encode(s)
        let back = try JSONDecoder().decode(GameState.self, from: data)
        XCTAssertEqual(back.activeChibi.careTaps, 5)
        XCTAssertEqual(back.activeChibi.stageReached, FriendshipStage.buddies.rawValue)
        XCTAssertEqual(back.activeChibi.statsAtAdoption, s.activeChibi.statsAtAdoption)
    }

    // MARK: - Firsts

    func testAFirstIsMarkedOnceWithItsDate() {
        var f = Firsts()
        let first = date("2026-09-02T10:00:00Z")
        let again = date("2026-09-09T10:00:00Z")
        XCTAssertFalse(f.isDone("costume"))
        XCTAssertTrue(f.mark("costume", at: first))
        XCTAssertFalse(f.mark("costume", at: again), "a first is a first")
        XCTAssertEqual(f.date("costume"), first)
        XCTAssertTrue(f.isDone("costume"))
    }

    func testAnOlderSaveShowsDoneWithoutADate() {
        var f = Firsts()
        f.markUndated("scene")
        XCTAssertTrue(f.isDone("scene"))
        XCTAssertNil(f.date("scene"))
        XCTAssertFalse(f.mark("scene", at: date("2026-09-09T10:00:00Z")),
                       "a first that already happened cannot be given today's date")
    }

    func testTheCardRowsAreTheFiveOnTheBriefInOrder() {
        let rows = Firsts().rows(for: "slime")
        XCTAssertEqual(rows.map(\.title),
                       ["First costume", "First scene", "First friend", "First shift", "Three stars"])
        XCTAssertTrue(rows.allSatisfy { !$0.done && $0.date == nil })
        for row in rows {
            XCTAssertLessThan(row.title.count, 40)
            XCTAssertFalse(row.title.contains("?"))
        }
    }

    func testFirstsAreStampedWhereTheThingHappens() {
        var s = fresh()
        let when = date("2026-09-03T15:00:00Z")

        s.ownedLooks.insert("hoodie")
        s.wear("hoodie", now: when)
        XCTAssertEqual(s.firsts.date("costume"), when)

        s.ownedScenes.insert("reef")
        s.equipScene("reef", now: when)
        XCTAssertEqual(s.firsts.date("scene"), when)

        s.recordFocus(minutes: 25, sessionID: "one", now: when)
        XCTAssertEqual(s.firsts.date("shift"), when)

        s.owned[0].level = 2
        s.ledger.post(CoinEntry(key: "seed", amount: 1000, reason: .legacy, day: day1))
        XCTAssertTrue(s.upgradeActiveChibi(now: when))
        XCTAssertEqual(s.activeChibi.level, 3)
        XCTAssertEqual(s.firsts.date(Firsts.threeStars("slime")), when)

        // A later costume changes nothing on the first.
        s.ownedLooks.insert("flannel")
        s.wear("flannel", now: date("2026-09-08T15:00:00Z"))
        XCTAssertEqual(s.firsts.date("costume"), when)
        // And wearing nothing is not a costume.
        var t = fresh()
        t.wear("classic", now: when)
        XCTAssertFalse(t.firsts.isDone("costume"))
    }

    func testTheFreeTankIsNotAFirstScene() {
        var s = fresh()
        s.equipScene(Scene0.all[0].id, now: date("2026-09-03T15:00:00Z"))
        XCTAssertFalse(s.firsts.isDone("scene"))
    }

    func testAnOlderSaveInfersWhatAlreadyHappened() throws {
        var s = fresh()
        s.owned[0].level = 3
        s.owned[0].skinID = "ninja"
        s.ownedScenes.insert("kelp")
        s.sceneID = "kelp"
        s.lifetime.focusMinutes = 45
        // Encode without a `firsts` key, the way a save from before the list looks.
        var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(s)) as! [String: Any]
        json.removeValue(forKey: "firsts")
        let back = try JSONDecoder().decode(GameState.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertTrue(back.firsts.isDone("costume"))
        XCTAssertTrue(back.firsts.isDone("scene"))
        XCTAssertTrue(back.firsts.isDone("shift"))
        XCTAssertTrue(back.firsts.isDone(Firsts.threeStars("slime")))
        XCTAssertFalse(back.firsts.isDone("friend"))
        XCTAssertNil(back.firsts.date("costume"), "inferred means done, date unknown")
    }

    // MARK: - The card's three numbers

    func testTheCardNumbersOnlyGoUpAsWorkHappens() {
        var s = fresh()
        let kin = s.activeChibi
        var last = KinCardStats(since: kin, in: s)
        XCTAssertEqual(last, KinCardStats(finished: 0, lengths: 0, lessons: 0))

        let task = s.tasks.first!
        s.complete(taskID: task.id, reward: task.reward)
        var next = KinCardStats(since: kin, in: s)
        XCTAssertEqual(next.finished, 1)
        XCTAssertTrue(next.onlyUp(from: last)); last = next

        s.recordFocus(minutes: 25, sessionID: "a")
        next = KinCardStats(since: kin, in: s)
        XCTAssertEqual(next.lengths, 16, "a length every 90 seconds: 25 minutes is 16")
        XCTAssertTrue(next.onlyUp(from: last)); last = next

        s.recordFocus(minutes: 15, sessionID: "b")
        next = KinCardStats(since: kin, in: s)
        XCTAssertEqual(next.lengths, 26, "40 minutes is 26, not 16 plus 10")
        XCTAssertTrue(next.onlyUp(from: last)); last = next

        s.lifetime.lessonsRead += 1
        next = KinCardStats(since: kin, in: s)
        XCTAssertEqual(next.lessons, 1)
        XCTAssertTrue(next.onlyUp(from: last))
    }

    func testAKinAdoptedLaterCountsFromItsOwnDay() {
        var s = fresh()
        s.lifetime = LifetimeStats(tasksFinished: 40, canvasFinished: 10, focusMinutes: 90, lessonsRead: 9)
        s.ledger.post(CoinEntry(key: "seed", amount: 1000, reason: .legacy, day: day1))
        XCTAssertTrue(s.adopt(ChibiSpecies.find("ember")))
        let ember = s.owned.first { $0.speciesID == "ember" }!
        XCTAssertEqual(KinCardStats(since: ember, in: s), KinCardStats(finished: 0, lengths: 0, lessons: 0))
        XCTAssertEqual(KinCardStats(since: s.owned[0], in: s), KinCardStats(finished: 40, lengths: 60, lessons: 9))
    }

    // MARK: - The Wardrobe editor

    func testTheNoneTileWritesAnEmptyCostume() {
        var s = fresh()
        s.owned[0].level = 3
        s.ownedLooks.insert("ninja")
        s.wear("ninja")
        XCTAssertEqual(s.activeChibi.skinID, "ninja")
        XCTAssertEqual(SproutView.costume(s.activeChibi.skinID, level: 3), "ninja")

        s.wear(Costume.none)
        XCTAssertEqual(s.activeChibi.skinID, "classic")
        XCTAssertEqual(SproutView.costume(s.activeChibi.skinID, level: 3), "",
                       "the page is asked for nothing, and dresses the kin in its coat's default")
        let look = SproutView.Look(type: "sprout", coat: "mint", evo: "3", skin: "classic",
                                   costume: SproutView.costume("classic", level: 3), radius: 47, tank: "lagoon")
        XCTAssertFalse(look.url.absoluteString.contains("costume="))
    }

    func testBuyingACostumeCostsItsPriceOnceAndNeverOverdraws() {
        var s = fresh()
        let hoodie = Costume.find("hoodie")!
        XCTAssertFalse(s.buyCostume(hoodie), "no coins, no costume — and no debt")
        XCTAssertFalse(s.ownedLooks.contains("hoodie"))

        s.ledger.post(CoinEntry(key: "seed", amount: 200, reason: .legacy, day: day1))
        XCTAssertTrue(s.buyCostume(hoodie))
        XCTAssertTrue(s.ownedLooks.contains("hoodie"))
        XCTAssertEqual(s.ledger.balance, 50)
        XCTAssertFalse(s.buyCostume(hoodie), "already yours")
        XCTAssertEqual(s.ledger.balance, 50)
    }

    func testTheGridOrderIsCheapestFirstWithNoneInFront() {
        let prices = Costume.catalog.map(\.price)
        XCTAssertEqual(prices, prices.sorted())
        XCTAssertEqual(WardrobeEditor.costumeTiles.first?.id, Costume.none.id)
        XCTAssertEqual(WardrobeEditor.costumeTiles.count, Costume.catalog.count + 1)
    }
}

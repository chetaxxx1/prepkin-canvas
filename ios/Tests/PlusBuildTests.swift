import Foundation
import XCTest
@testable import PrepkinCanvas

/// The rules Plus added, each as a test that fails before the code exists.
///
/// `PlusGateTests` already holds the one rule that matters most — with the
/// entitlement off, every gate hands back the free number. This file covers the
/// things that rule cannot see: the gift week's shape, the season's claim rule, the
/// price fallbacks, and the calendar mapping.
final class PlusBuildTests: XCTestCase {

    private let cal = Calendar(identifier: .gregorian)

    private func day(_ s: String) -> DayKey { DayKey(raw: s) }

    private func date(_ s: String) -> Date {
        let f = DateFormatter()
        f.calendar = cal
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.date(from: s)!
    }

    // MARK: - PlusAccess: the one entitlement read

    func testAccessIsOffByDefault() {
        XCTAssertFalse(PlusAccess.none.isOn())
    }

    func testAPaidSubscriptionTurnsEveryGateOn() {
        let access = PlusAccess(paid: true)
        XCTAssertTrue(access.isOn())
        XCTAssertEqual(access.value(.shopSlots), 7)
        XCTAssertEqual(access.value(.shopDiscount), 30)
        XCTAssertEqual(access.value(.shopHolds), 3)
        XCTAssertEqual(access.value(.shopRerolls), 6)
    }

    /// The gift week is Plus, and it is *not* a purchase. The sheet reads this to
    /// keep a price off a screen nobody has been asked to pay for.
    func testTheGiftWeekIsPlusButNotPaid() {
        let now = date("2026-09-22 10:00")
        let access = PlusAccess(giftEndsAt: now.addingTimeInterval(3600))
        XCTAssertTrue(access.isOn(at: now))
        XCTAssertTrue(access.isGift(at: now))

        let paid = PlusAccess(paid: true, giftEndsAt: now.addingTimeInterval(3600))
        XCTAssertFalse(paid.isGift(at: now), "a paying student is not on a gift")
    }

    func testAnExpiredGiftIsOff() {
        let now = date("2026-09-22 10:00")
        let access = PlusAccess(giftEndsAt: now.addingTimeInterval(-1))
        XCTAssertFalse(access.isOn(at: now))
    }

    // MARK: - The gift week

    func testTheGiftArrivesOnTheThirdCanvasTaskAndNotBefore() {
        var plus = PlusLocal()
        XCTAssertFalse(plus.startGiftIfEarned(canvasFinished: 1))
        XCTAssertFalse(plus.startGiftIfEarned(canvasFinished: 2))
        XCTAssertNil(plus.giftEndsAt)
        XCTAssertTrue(plus.startGiftIfEarned(canvasFinished: 3))
        XCTAssertNotNil(plus.giftEndsAt)
    }

    /// The gift is given once. A student who finishes three hundred tasks does not
    /// get a second week, and a week that has run out does not re-arm.
    func testTheGiftIsNeverGivenTwice() {
        var plus = PlusLocal()
        let start = date("2026-09-01 09:00")
        XCTAssertTrue(plus.startGiftIfEarned(canvasFinished: 3, now: start))
        let end = plus.giftEndsAt

        XCTAssertFalse(plus.startGiftIfEarned(canvasFinished: 4, now: start))
        // Long after it has run out.
        XCTAssertFalse(plus.startGiftIfEarned(canvasFinished: 99, now: date("2026-12-01 09:00")))
        XCTAssertEqual(plus.giftEndsAt, end)
    }

    func testTheGiftLastsSevenDays() {
        let start = date("2026-09-01 09:00")
        let end = PlusGift.endDate(from: start, calendar: cal)
        XCTAssertEqual(cal.dateComponents([.day], from: start, to: end).day, 7)
    }

    /// Three rows, dated, and not one number that counts down. "your trial is
    /// ending" appears nowhere, which `CopySweepTests` also checks across every
    /// source file.
    func testTheTimelineIsThreeDatedRowsWithNoCountdown() {
        let rows = PlusGift.timeline(start: date("2026-09-01 09:00"), calendar: cal)
        XCTAssertEqual(rows.count, 3)
        XCTAssertEqual(rows[0].when, "Today")
        for row in rows {
            let text = (row.when + " " + row.what).lowercased()
            XCTAssertFalse(text.contains("trial"), "the timeline may never say trial: \(text)")
            XCTAssertFalse(text.contains("days left"), "no countdown: \(text)")
            XCTAssertFalse(text.contains("expires"), "no countdown: \(text)")
        }
        XCTAssertTrue(rows[2].what.contains("Nothing is charged"))
    }

    /// The sheet is owed exactly once, on the day the week runs out.
    func testTheSheetIsOwedOnceWhenTheGiftEnds() {
        var plus = PlusLocal()
        let start = date("2026-09-01 09:00")
        plus.startGiftIfEarned(canvasFinished: 3, now: start)

        XCTAssertFalse(plus.giftJustEnded(at: date("2026-09-04 09:00")), "not while it is on")
        XCTAssertTrue(plus.giftJustEnded(at: date("2026-09-09 09:00")))

        plus.giftSheetShown = true
        XCTAssertFalse(plus.giftJustEnded(at: date("2026-09-30 09:00")), "never twice")
    }

    // MARK: - The season

    func testAClaimNeedsSomethingRealFinishedThatDay() {
        let verdict = SeasonClaim.check(
            season: .midterms, progress: SeasonProgress(),
            day: day("2026-09-23"), finishedToday: 0
        )
        XCTAssertEqual(verdict, .nothingFinishedToday)
    }

    func testADayCanOnlyBeClaimedOnce() {
        var progress = SeasonProgress()
        progress.claimedDays.insert("2026-09-23")
        let verdict = SeasonClaim.check(
            season: .midterms, progress: progress,
            day: day("2026-09-23"), finishedToday: 4
        )
        XCTAssertEqual(verdict, .alreadyClaimedToday)
    }

    func testNothingCanBeClaimedOutsideTheSeason() {
        XCTAssertEqual(
            SeasonClaim.check(season: .midterms, progress: SeasonProgress(),
                              day: day("2026-09-21"), finishedToday: 1),
            .outOfSeason
        )
        XCTAssertEqual(
            SeasonClaim.check(season: .midterms, progress: SeasonProgress(),
                              day: day("2026-10-13"), finishedToday: 1),
            .outOfSeason
        )
    }

    /// **The rule that keeps this off the wrong side of "nothing that resets".**
    ///
    /// A rung is claimed by count, never by calendar position. Miss ten days of a
    /// twenty-one day season, claim on seven, and the ladder is finished.
    func testAGapCostsNothing() {
        var plus = PlusLocal()
        let season = Season.midterms
        // Seven claims, scattered, with long gaps between them.
        let days = ["2026-09-22", "2026-09-26", "2026-09-30",
                    "2026-10-04", "2026-10-08", "2026-10-11", "2026-10-12"]
        for (i, d) in days.enumerated() {
            let got = plus.claim(season, day: day(d), finishedToday: 1, isPlus: true)
            XCTAssertNotNil(got, "claim \(i + 1) on \(d) should be allowed after a gap")
            XCTAssertEqual(got?.rung, i, "a gap must not cost a rung")
        }
        XCTAssertEqual(plus.progress(season).rungsClaimed, season.rungs.count)
        XCTAssertEqual(
            SeasonClaim.check(season: season, progress: plus.progress(season),
                              day: day("2026-10-12"), finishedToday: 1),
            .alreadyClaimedToday
        )
    }

    func testTheLadderStopsWhenItIsFinished() {
        var progress = SeasonProgress()
        for i in 0..<Season.midterms.rungs.count {
            progress.claimedDays.insert("2026-09-\(22 + i)")
        }
        XCTAssertEqual(
            SeasonClaim.check(season: .midterms, progress: progress,
                              day: day("2026-10-05"), finishedToday: 3),
            .ladderFinished
        )
    }

    /// The free column never hands over a costume and the Plus column never hands
    /// over coins. A coin that arrives because a card was charged is a coin that was
    /// sold (`PLUS-SPEC.md` signature 9, which is on the "do not sign" list).
    func testThePlusTrackNeverPaysCoins() {
        for season in Season.all {
            for (i, rung) in season.rungs.enumerated() {
                if case .coins = rung.plus {
                    XCTFail("\(season.id) rung \(i): the Plus track may not pay coins")
                }
                if case .costume = rung.free {
                    XCTFail("\(season.id) rung \(i): the free track hands out coins, not costumes")
                }
            }
        }
    }

    /// Nothing on the Plus track may be art that only money can reach. Every
    /// costume in a season is also on the shelf at its coin price, forever.
    func testEverySeasonCostumeIsAlsoBuyableWithCoins() {
        for season in Season.all {
            for rung in season.rungs {
                guard let id = rung.plus.costumeID else { continue }
                XCTAssertNotNil(
                    Costume.find(id),
                    "\(id) is on a season track but not in the coin catalogue"
                )
            }
        }
    }

    func testAFreeStudentClimbsTheFreeColumnWithNoPlusItem() {
        var plus = PlusLocal()
        let got = plus.claim(.midterms, day: day("2026-09-23"), finishedToday: 1, isPlus: false)
        XCTAssertNotNil(got)
        XCTAssertNil(got?.plus, "a free student gets the free column and no Plus item")
        if case .coins(let n) = got?.free { XCTAssertGreaterThan(n, 0) } else { XCTFail("free rung pays coins") }
    }

    // MARK: - Saved looks

    func testFreeSavesThreeAndPlusSavesMore() {
        var plus = PlusLocal()
        for i in 0..<3 {
            XCTAssertTrue(plus.save(look("\(i)"), limit: 3))
        }
        XCTAssertFalse(plus.save(look("4"), limit: 3), "the fourth save needs Plus")
        XCTAssertTrue(plus.save(look("4"), limit: .max))
    }

    /// The load-bearing promise: a lapse stops new saves and never deletes one.
    func testALapseKeepsEverySavedLookIncludingTheOnesAboveThree() {
        var plus = PlusLocal()
        for i in 0..<9 { plus.save(look("\(i)"), limit: .max) }
        XCTAssertEqual(plus.savedLooks.count, 9)

        // The subscription ends. Nothing is removed.
        XCTAssertFalse(plus.canSave(3))
        XCTAssertEqual(plus.savedLooks.count, 9, "a lapse may never delete a saved look")
    }

    func testRemovingALookIsAlwaysAllowed() {
        var plus = PlusLocal()
        plus.save(look("a"), limit: 3)
        plus.removeLook(plus.savedLooks[0].id)
        XCTAssertTrue(plus.savedLooks.isEmpty)
    }

    private func look(_ name: String) -> SavedLook {
        SavedLook(name: name, speciesID: "slime", costumeID: "classic", sceneID: "lagoon")
    }

    // MARK: - The calendar

    func testATaskWithATimeBecomesAnHourLongEvent() {
        let task = DatedTask(id: "1", title: "Lab report", kind: .study,
                             source: .mine, detail: "Bio 101",
                             day: day("2026-09-23"), minute: 9 * 60 + 30)
        let plan = CalendarExport.plan(task, calendar: cal)
        XCTAssertNotNil(plan)
        XCTAssertFalse(plan!.isAllDay)
        XCTAssertEqual(plan!.end.timeIntervalSince(plan!.start), CalendarExport.defaultDuration)
        XCTAssertEqual(plan!.title, "Lab report")
        XCTAssertEqual(plan!.notes, "Bio 101")
    }

    /// A task with no time is an all-day event, not an event at midnight. Midnight
    /// is a lie about when the work happens.
    func testATaskWithNoTimeIsAllDay() {
        let task = DatedTask(id: "2", title: "Read chapter 4", kind: .study,
                             source: .mine, day: day("2026-09-23"), minute: nil)
        let plan = CalendarExport.plan(task, calendar: cal)
        XCTAssertEqual(plan?.isAllDay, true)
    }

    /// A course called "Bio 101; Lab" breaks the file format without escaping.
    func testCalendarFileEscapesTheCharactersThatWouldBreakIt() {
        XCTAssertEqual(CalendarExport.escape("Bio 101; Lab, week 2"), #"Bio 101\; Lab\, week 2"#)
        XCTAssertEqual(CalendarExport.escape("one\ntwo"), #"one\ntwo"#)
    }

    func testCalendarFileIsWellFormed() {
        let task = DatedTask(id: "3", title: "Essay", kind: .study,
                             source: .mine, day: day("2026-09-23"), minute: 600)
        let text = CalendarExport.file([task], now: date("2026-09-20 12:00"))
        XCTAssertTrue(text.hasPrefix("BEGIN:VCALENDAR"))
        XCTAssertTrue(text.contains("BEGIN:VEVENT"))
        XCTAssertTrue(text.contains("SUMMARY:Essay"))
        XCTAssertTrue(text.contains("UID:prepkin-\(task.id)@prepkin.com"))
        XCTAssertTrue(text.hasSuffix("END:VCALENDAR\r\n"), "tail was: \(String(text.suffix(40)).debugDescription)")
        // RFC 5545 wants CRLF, and Outlook is the one that minds.
        XCTAssertFalse(text.contains("\n\n"))
    }

    // MARK: - Grades

    func testTermGPAIsNilWithNothingToAverage() {
        XCTAssertNil(GradeProjection.termGPA([]))
    }

    func testTermGPAAveragesTheLetterPoints() {
        // 95 → 4.0, 85 → 3.0, 75 → 2.0
        XCTAssertEqual(GradeProjection.termGPA([95, 85, 75]) ?? 0, 3.0, accuracy: 0.001)
    }

    /// Never a percentage above 100 on a screen. "Average 143%" is a number nobody
    /// can act on.
    func testAnUnreachableGoalSaysSoRatherThanPrintingOver100() {
        let need = GradeProjection.need(current: 40, target: 90, remainingWeight: 0.2)
        guard case .outOfReach = need else {
            return XCTFail("an unreachable target must say so, got \(need)")
        }
        XCTAssertFalse(GradeProjection.line(need, target: 90).contains("143"))
    }

    func testAGoalAlreadyMetSaysSo() {
        XCTAssertEqual(GradeProjection.need(current: 95, target: 90, remainingWeight: 0.3),
                       .alreadyThere)
    }

    func testWhatIsNeededToLandAGoal() {
        // Half marked at 80, aiming at 90: the rest has to average 100.
        guard case .need(let percent) = GradeProjection.need(
            current: 80, target: 90, remainingWeight: 0.5
        ) else { return XCTFail("should be reachable") }
        XCTAssertEqual(percent, 100, accuracy: 0.01)
    }

    // MARK: - The compare table

    /// A compare table that only lists what you do not have is a padlock with a
    /// header on it. This one starts with what is free.
    func testTheCompareTableLeadsWithWhatStaysFree() {
        let firstSix = PlusCompare.rows.prefix(6)
        for row in firstSix {
            XCTAssertEqual(row.free, .yes, "\(row.name) should be free in both columns")
            XCTAssertEqual(row.plus, .yes)
        }
    }

    /// The table reads its numbers off `PlusGate`, so a row cannot promise
    /// something the gate does not hand over.
    func testCompareNumbersMatchTheGateTable() {
        let slots = PlusCompare.rows.first { $0.name.contains("Picks in the Shop") }
        XCTAssertEqual(slots?.free, .text("5"))
        XCTAssertEqual(slots?.plus, .text("7"))
        let discount = PlusCompare.rows.first { $0.name.contains("Off every pick") }
        XCTAssertEqual(discount?.free, .text("20%"))
        XCTAssertEqual(discount?.plus, .text("30%"))
    }

    // MARK: - Price fallbacks

    /// StoreKit can hand back nothing — no network, a sandbox hiccup, a product
    /// that has not propagated. The sheet still has to show a price, and it has to
    /// be the price in `PLUS-SPEC.md` section 5.
    func testThePriceFallbacksAreTheOnesInTheSpec() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/PlusSheet.swift")
        let text = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(text.contains(#""$69.99""#), "yearly fallback must be $69.99")
        XCTAssertTrue(text.contains(#""$9.99""#), "monthly fallback must be $9.99")
        XCTAssertFalse(text.contains("79.99"), "$79.99 was replaced by $69.99, signature 7")
    }

    /// Signature 6: the gift week is the only free. An App Store introductory offer
    /// on top of it is fourteen free days and two kinds of free.
    func testTheStoreKitConfigHasNoIntroductoryOffer() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("PrepkinCanvas.storekit")
        let text = try String(contentsOf: url, encoding: .utf8)
        XCTAssertFalse(text.contains("introductoryOffer"),
                       "the gift week is the trial — no App Store intro offer")
        XCTAssertTrue(text.contains(#""displayPrice" : "69.99""#)
                      || text.contains(#""displayPrice": "69.99""#),
                      "yearly is $69.99")
    }
}

/// The gates, read through the shop and the save file rather than through
/// `PlusGate` on its own.
///
/// `PlusGateTests` proves the *table* is right. This proves the app is wired to it:
/// a free student's shop is the shop that shipped before Plus existed, and turning
/// the entitlement on changes exactly four numbers and nothing else.
final class PlusWiringTests: XCTestCase {

    private func fresh(plus: Bool) -> GameState {
        var game = GameState()
        game.plusIsOn = plus
        game.refreshPicksIfNeeded(now: Date())
        return game
    }

    // MARK: - The free path is untouched

    func testAFreeShopIsTheShopThatShippedBeforePlus() {
        let game = fresh(plus: false)
        XCTAssertEqual(game.pickSlots, 5)
        XCTAssertEqual(game.holdLimit, 1)
        XCTAssertEqual(game.discountPercent, 20)
        XCTAssertEqual(game.rerollsPerDay, 3)
        XCTAssertEqual(game.rerollsLeft, 3)
    }

    func testPlusChangesExactlyFourNumbers() {
        let game = fresh(plus: true)
        XCTAssertEqual(game.pickSlots, 7)
        XCTAssertEqual(game.holdLimit, 3)
        XCTAssertEqual(game.discountPercent, 30)
        XCTAssertEqual(game.rerollsPerDay, 6)
    }

    /// The row is five slots long on free and seven on Plus, and it is drawn to the
    /// slot count rather than to a constant.
    func testTheRowIsDrawnToTheSlotCount() {
        XCTAssertEqual(fresh(plus: false).picks.count, 5)
        XCTAssertEqual(fresh(plus: true).picks.count, 7)
    }

    /// **The sentence that keeps this off the wrong side of "coins are never sold".**
    /// A pick is a discount on something that is also on the shelf at full price.
    func testEveryPickIsStillReachableAtFullCoinPrice() {
        for plus in [false, true] {
            let game = fresh(plus: plus)
            for pick in game.picks {
                XCTAssertEqual(game.currentPrice(pick.id), pick.price)
                XCTAssertLessThan(pick.price, pick.fullPrice)
                // The Collection price is what an item costs when it is not in the
                // row, and it never moves.
                XCTAssertGreaterThan(pick.fullPrice, 0)
            }
        }
    }

    func testTheDiscountIsTwentyFreeAndThirtyOnPlus() {
        let free = fresh(plus: false)
        let paid = fresh(plus: true)
        guard let a = free.picks.first, let b = paid.picks.first else {
            return XCTFail("a fresh save has picks")
        }
        XCTAssertEqual(a.discountPercent, 20)
        XCTAssertEqual(b.discountPercent, 30)
        XCTAssertEqual(a.price, Int((Double(a.fullPrice) * 0.8).rounded()))
        XCTAssertEqual(b.price, Int((Double(b.fullPrice) * 0.7).rounded()))
    }

    // MARK: - Holds

    func testFreeHoldsOneSlotAndPlusHoldsThree() {
        var game = fresh(plus: false)
        let ids = game.picks.map(\.id)
        game.toggleLock(ids[0])
        game.toggleLock(ids[1])
        XCTAssertEqual(game.lockedPicks.count, 1, "free holds one")

        game.plusIsOn = true
        game.toggleLock(ids[1])
        game.toggleLock(ids[2])
        game.toggleLock(ids[3])
        XCTAssertEqual(game.lockedPicks.count, 3, "Plus holds three")
    }

    /// A hold that cannot be taken must not silently drop somebody else's.
    func testAFullShelfOfHoldsDropsNothing() {
        var game = fresh(plus: false)
        let ids = game.picks.map(\.id)
        game.toggleLock(ids[0])
        XCTAssertFalse(game.canHoldMore(ids[1]))
        game.toggleLock(ids[1])
        XCTAssertEqual(game.lockedPicks, [ids[0]])
    }

    /// Every held slot survives a reroll, which is the only thing a hold does.
    func testHeldSlotsSurviveAReroll() {
        var game = fresh(plus: true)
        let ids = Array(game.picks.map(\.id).prefix(3))
        for id in ids { game.toggleLock(id) }
        game.rerollPicks()
        for id in ids {
            XCTAssertTrue(game.picks.map(\.id).contains(id), "\(id) was held and should still be in the row")
        }
    }

    // MARK: - The entitlement never lands in the save file

    /// An entitlement written into the save file is an entitlement that outlives the
    /// subscription. `plusIsOn` is deliberately not in `CodingKeys`.
    func testPlusIsNotPersisted() throws {
        var game = GameState()
        game.plusIsOn = true
        let data = try JSONEncoder().encode(game)
        let text = String(data: data, encoding: .utf8) ?? ""
        XCTAssertFalse(text.contains("plusIsOn"), "the entitlement may not be saved to disk")

        let back = try JSONDecoder().decode(GameState.self, from: data)
        XCTAssertFalse(back.plusIsOn, "a decoded save starts free and the first refresh corrects it")
    }

    /// The gift week and the saved looks *are* saved, because both have to survive a
    /// lapse untouched.
    func testTheGiftWeekAndSavedLooksSurviveARoundTrip() throws {
        var game = GameState()
        game.plus.startGiftIfEarned(canvasFinished: 3)
        game.plus.save(SavedLook(name: "Rooftop", speciesID: "slime",
                                 costumeID: "grad", sceneID: "deep"), limit: .max)
        let back = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(game))
        XCTAssertNotNil(back.plus.giftEndsAt)
        XCTAssertEqual(back.plus.savedLooks.count, 1)
        XCTAssertEqual(back.plus.savedLooks[0].name, "Rooftop")
    }

    /// A save written before three holds shipped carries one id in `lockedPick`. It
    /// has to come across, not be dropped on the student's first open.
    func testAnOldSingleHoldIsCarriedOver() throws {
        var game = GameState()
        game.lockedPick = "kin:ember"
        let data = try JSONEncoder().encode(game)

        // A real pre-upgrade file has no `lockedPicks` key at all. Encoding an empty
        // set writes `"lockedPicks":[]`, which decodes as "present and empty" and
        // never reaches the fallback — so the key is removed to get an honest one.
        var json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        json.removeValue(forKey: "lockedPicks")
        let old = try JSONSerialization.data(withJSONObject: json)

        let back = try JSONDecoder().decode(GameState.self, from: old)
        XCTAssertEqual(back.lockedPicks, ["kin:ember"],
                       "a hold from before three holds shipped must survive the upgrade")
        XCTAssertNil(back.lockedPick, "and the old field is cleared once it is carried over")
    }

    /// A save written after the upgrade keeps its own set, empty or not.
    func testANewSaveKeepsItsOwnHolds() throws {
        var game = GameState()
        game.lockedPicks = ["scene:reef"]
        let back = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(game))
        XCTAssertEqual(back.lockedPicks, ["scene:reef"])
    }

    // MARK: - The season pays out

    func testClaimingARungPaysCoinsOnceAndOnlyOnce() {
        var game = GameState()
        let day = DayKey(raw: "2026-09-23")
        // Something real finished today.
        _ = game.ledger.post(CoinEntry(key: "task:x:\(day.raw)", amount: 10,
                                       reason: .task, day: day))
        let before = game.ledger.balance

        let payout = game.claimSeasonRung(.midterms, isPlus: false, day: day)
        XCTAssertEqual(payout?.rung, 0)
        XCTAssertGreaterThan(game.ledger.balance, before)

        // The same day again is refused by the claim rule.
        XCTAssertNil(game.claimSeasonRung(.midterms, isPlus: false, day: day))
    }

    func testAPlusClaimHandsOverTheCostume() {
        var game = GameState()
        let day = DayKey(raw: "2026-09-23")
        _ = game.ledger.post(CoinEntry(key: "focus:x", amount: 25, reason: .focus,
                                       units: 25, day: day))
        let payout = game.claimSeasonRung(.midterms, isPlus: true, day: day)
        XCTAssertNotNil(payout?.costume)
        XCTAssertTrue(game.ownedLooks.contains(payout!.costume!.id))
    }

    /// A costume already on the rack pays its coin price instead, so nobody is
    /// handed a duplicate.
    func testAnAlreadyOwnedCostumePaysCoinsInstead() {
        var game = GameState()
        let day = DayKey(raw: "2026-09-23")
        _ = game.ledger.post(CoinEntry(key: "task:y:\(day.raw)", amount: 10,
                                       reason: .task, day: day))
        let first = Season.midterms.rungs[0].plus.costumeID!
        game.ownedLooks.insert(first)

        let payout = game.claimSeasonRung(.midterms, isPlus: true, day: day)
        XCTAssertNil(payout?.costume)
        XCTAssertGreaterThan(payout?.coins ?? 0, Costume.find(first)?.price ?? 0)
    }

    /// Opening the app is not work. The ladder pays for finishing something.
    func testOpeningTheAppDoesNotClaimADay() {
        var game = GameState()
        XCTAssertEqual(game.finishedToday(DayKey(raw: "2026-09-23")), 0)
        XCTAssertNil(game.claimSeasonRung(.midterms, isPlus: true, day: DayKey(raw: "2026-09-23")))
    }

    /// A round of Sort is play. Real work is a task, a shift or a lesson.
    func testAGameDoesNotCountAsRealWork() {
        var game = GameState()
        let day = DayKey(raw: "2026-09-23")
        _ = game.ledger.post(CoinEntry(key: "sort:x", amount: 5, reason: .sort, day: day))
        XCTAssertEqual(game.finishedToday(day), 0)
        _ = game.ledger.post(CoinEntry(key: "lesson:x", amount: 5, reason: .lesson, day: day))
        XCTAssertEqual(game.finishedToday(day), 1)
    }
}

/// Copy that names a Plus number has to read it from the gate.
///
/// This exists because of a real bug: the Shop's cost badge said "−20%" while the
/// price under it was already 30% off, because the badge was a literal and the price
/// was not. A student on Plus saw two different discounts on the same card.
///
/// Only **string literals** are scanned. A comment is free to name both numbers —
/// several of them have to, to explain why the literal is banned.
final class PlusCopyTests: XCTestCase {

    private func sources() throws -> [(name: String, text: String)] {
        let dir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources")
        let files = FileManager.default.enumerator(at: dir, includingPropertiesForKeys: nil)?
            .compactMap { $0 as? URL }
            .filter { $0.pathExtension == "swift" } ?? []
        return try files.map { ($0.lastPathComponent, try String(contentsOf: $0, encoding: .utf8)) }
    }

    /// Every double-quoted run in a file, with `///` and `//` lines dropped first.
    private func literals(in text: String) -> [String] {
        let code = text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { line -> String in
                let s = String(line)
                guard let slashes = s.range(of: "//") else { return s }
                // A `//` inside a literal is not a comment. Count quotes before it.
                let before = s[s.startIndex..<slashes.lowerBound]
                return before.filter { $0 == "\"" }.count % 2 == 0 ? String(before) : s
            }
            .joined(separator: "\n")

        var out: [String] = []
        var current: String?
        var escaped = false
        for ch in code {
            if var value = current {
                if escaped { escaped = false; value.append(ch); current = value; continue }
                if ch == "\\" { escaped = true; value.append(ch); current = value; continue }
                if ch == "\"" { out.append(value); current = nil; continue }
                value.append(ch)
                current = value
            } else if ch == "\"" {
                current = ""
            }
        }
        return out
    }

    /// No shipped string may hard-code a number the entitlement moves.
    func testNoStringHardCodesTheDiscount() throws {
        var bad: [String] = []
        for file in try sources() {
            for literal in literals(in: file.text) {
                if literal.contains("20% off") || literal.contains("−20%") || literal.contains("-20%") {
                    bad.append("\(file.name): \"\(literal.prefix(70))\"")
                }
            }
        }
        XCTAssertTrue(bad.isEmpty, """
            These name the free discount as a literal. On Plus the price is 30% off and \
            the words would disagree with it. Read `state.pickDiscountPercent` instead.
            \(bad.joined(separator: "\n"))
            """)
    }

    /// The paid screens may never say any of these, in any casing.
    func testTheSheetNeverSaysTheBannedWords() throws {
        let banned = ["unlock", "trial is ending", "limited time", "most popular",
                      "don't lose", "are you sure"]
        for file in try sources()
        where file.name.hasPrefix("Plus") || file.name == "SeasonCard.swift" {
            for literal in literals(in: file.text) {
                let lower = literal.lowercased()
                for word in banned {
                    XCTAssertFalse(lower.contains(word),
                                   "\(file.name) ships the string \"\(literal.prefix(60))\"")
                }
            }
        }
    }
}

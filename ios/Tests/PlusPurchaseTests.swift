import Foundation
import StoreKit
import StoreKitTest
import XCTest
@testable import PrepkinCanvas

/// The purchase itself, against the real StoreKit machinery.
///
/// `SKTestSession` runs Apple's own store locally off `PrepkinCanvas.storekit` — the
/// same file the scheme runs the app against — so these are real transactions
/// through `Product.purchase()`, not a mock of it. Buying, restoring, refunding and
/// expiring all go through the code that ships.
///
/// What this catches that a unit test on `PlusEntitlement.resolve` cannot: the
/// products actually existing under the ids in `PlusProduct`, the prices matching
/// the spec, and `PlusStore` turning a finished transaction into an entitlement.
@MainActor
final class PlusPurchaseTests: XCTestCase {

    private var session: SKTestSession!

    /// Whether this run can actually drive a purchase.
    ///
    /// `SKTestSession` needs the StoreKit configuration attached to the *scheme*,
    /// which `xcodebuild test` does not do — only Xcode's Run and Test actions with
    /// the configuration selected. Under `xcodebuild` the session loads but
    /// `Product.products` comes back empty and every buy fails with
    /// `SKInternalErrorDomain 3`.
    ///
    /// So these skip rather than fail there. **Run this file from Xcode** (Product
    /// then Test, with `PrepkinCanvas.storekit` selected in the scheme) to exercise
    /// buying, restoring and refunding for real. Everything about the *entitlement*
    /// — resolution, grace, expiry, the lapse promise — is covered without a store
    /// in `PlusTests` and `PlusBuildTests`, and those run everywhere.
    private var canDrivePurchases = false

    override func setUp() async throws {
        try await super.setUp()
        // By URL, not by name. The test bundle is hosted inside the app, so
        // `Bundle.main` is the app and `configurationFileNamed:` cannot see a
        // resource that lives in the test bundle beside this file.
        let url = try XCTUnwrap(
            Bundle(for: type(of: self)).url(forResource: "PrepkinCanvas", withExtension: "storekit"),
            "PrepkinCanvas.storekit is not in the test bundle — check project.yml"
        )
        session = try SKTestSession(contentsOf: url)
        session.resetToDefaultState()
        session.clearTransactions()
        session.storefront = "USA"
        // Nothing may stand between a tap and the purchase in these tests: the point
        // is the app's own path, not Apple's confirmation sheet.
        session.askToBuyEnabled = false
        session.disableDialogs = true

        let probe = try? await Product.products(for: [PlusProduct.yearly.rawValue])
        canDrivePurchases = !(probe ?? []).isEmpty
    }

    /// Every test here needs a live store. Called first, so a run without one is
    /// a single skip rather than a wall of assertion failures.
    private func requireStore() throws {
        try XCTSkipUnless(
            canDrivePurchases,
            "StoreKit returned no products. xcodebuild does not attach the scheme's "
            + "StoreKit configuration — run this file from Xcode to exercise buying, "
            + "restoring and refunding."
        )
    }

    override func tearDown() async throws {
        session.clearTransactions()
        session = nil
        try await super.tearDown()
    }

    // MARK: - The products exist and cost what the spec says

    func testBothProductsLoadUnderTheIdsTheAppAsksFor() async throws {
        try requireStore()
        let store = PlusStore()
        await store.load()
        XCTAssertEqual(store.products.count, 2, "both plans must load, or the sheet shows fallbacks")
        let ids = Set(store.products.map(\.id))
        XCTAssertEqual(ids, Set(PlusProduct.allCases.map(\.rawValue)))
    }

    /// `PLUS-SPEC.md` section 5 is the only price table in the repo, and these are
    /// its numbers. A diff that moves one fails here as well as in the file.
    func testThePricesAreTheOnesInTheSpec() async throws {
        try requireStore()
        let store = PlusStore()
        await store.load()
        let yearly = try XCTUnwrap(store.products.first { $0.id == PlusProduct.yearly.rawValue })
        let monthly = try XCTUnwrap(store.products.first { $0.id == PlusProduct.monthly.rawValue })
        XCTAssertEqual(yearly.price, 69.99)
        XCTAssertEqual(monthly.price, 9.99)
    }

    /// Signature 6: the gift week is the only free. An introductory offer here would
    /// be a second, auto-charging free week on top of it.
    func testNeitherPlanCarriesAnIntroductoryOffer() async throws {
        try requireStore()
        let store = PlusStore()
        await store.load()
        for product in store.products {
            XCTAssertNil(
                product.subscription?.introductoryOffer,
                "\(product.id) has an intro offer; the gift week is the trial"
            )
        }
    }

    // MARK: - Buying

    func testBuyingMonthlyTurnsTheEntitlementOn() async throws {
        try requireStore()
        let store = PlusStore()
        await store.load()
        XCTAssertFalse(store.entitlement.isActive, "nobody starts subscribed")

        let bought = try await store.purchase(.monthly)
        XCTAssertTrue(bought)
        XCTAssertTrue(store.entitlement.isActive)
        XCTAssertEqual(store.entitlement.product, .monthly)
    }

    func testBuyingYearlyTurnsTheEntitlementOn() async throws {
        try requireStore()
        let store = PlusStore()
        await store.load()
        let bought = try await store.purchase(.yearly)
        XCTAssertTrue(bought)
        XCTAssertTrue(store.entitlement.isActive)
        XCTAssertEqual(store.entitlement.product, .yearly)
    }

    /// Yearly wins when both are somehow live, which is what `resolve` prefers.
    func testYearlyWinsOverMonthly() async throws {
        try requireStore()
        let store = PlusStore()
        await store.load()
        _ = try await store.purchase(.monthly)
        _ = try await store.purchase(.yearly)
        XCTAssertEqual(store.entitlement.product, .yearly)
    }

    // MARK: - Restoring

    /// A student who reinstalls, or picks up a second phone, gets Plus back without
    /// paying again.
    func testRestoreBringsBackAPurchaseOnAFreshStore() async throws {
        try requireStore()
        let first = PlusStore()
        await first.load()
        _ = try await first.purchase(.yearly)
        XCTAssertTrue(first.entitlement.isActive)

        // A second store is a second launch: it reads the same transactions.
        let second = PlusStore()
        await second.load()
        XCTAssertTrue(second.entitlement.isActive, "a relaunch keeps Plus")

        await second.restore()
        XCTAssertTrue(second.entitlement.isActive)
    }

    // MARK: - Refunds and expiry

    /// A refund revokes the transaction, and Plus goes off. Everything the student
    /// wore, made or saved stays — that is `PlusLocal`, in the save file, and no
    /// refund touches it.
    func testARefundTurnsPlusOff() async throws {
        try requireStore()
        let store = PlusStore()
        await store.load()
        _ = try await store.purchase(.monthly)
        XCTAssertTrue(store.entitlement.isActive)

        let found = await currentTransaction()
        let transaction = try XCTUnwrap(found)
        try await session.refundTransaction(identifier: UInt(transaction.id))

        let after = PlusStore()
        await after.load()
        XCTAssertFalse(after.entitlement.isActive, "a refunded subscription is not Plus")
    }

    /// The subscription runs out. Nothing is deleted, and the free numbers come back.
    func testAnExpiredSubscriptionIsNotPlus() async throws {
        try requireStore()
        let store = PlusStore()
        await store.load()
        _ = try await store.purchase(.monthly)

        let found = await currentTransaction()
        let transaction = try XCTUnwrap(found)
        try await session.expireSubscription(productIdentifier: transaction.productID)

        let after = PlusStore()
        await after.load()
        XCTAssertFalse(after.entitlement.isActive)
    }

    /// **The lapse promise, end to end.** A subscription that ends leaves the fish,
    /// the coins, every look worn and every combination saved exactly where they
    /// were. Only the four shop numbers and the shift lengths go back.
    func testALapseTakesNothingAway() async throws {
        var game = GameState()
        game.ownedLooks.insert("grad")
        game.plus.save(SavedLook(name: "Rooftop", speciesID: "slime",
                                 costumeID: "grad", sceneID: "lagoon"), limit: .max)
        game.plus.save(SavedLook(name: "Lab", speciesID: "slime",
                                 costumeID: "scholar", sceneID: "reef"), limit: .max)
        game.plus.save(SavedLook(name: "Late", speciesID: "slime",
                                 costumeID: "pajamas", sceneID: "deep"), limit: .max)
        game.plus.save(SavedLook(name: "Fourth", speciesID: "slime",
                                 costumeID: "ninja", sceneID: "kelp"), limit: .max)
        game.plusIsOn = true
        let coinsWhilePaid = game.ledger.balance

        // The card lapses.
        game.plusIsOn = false

        XCTAssertTrue(game.ownedLooks.contains("grad"), "a look worn stays worn")
        XCTAssertEqual(game.plus.savedLooks.count, 4, "including the one above the free three")
        XCTAssertEqual(game.ledger.balance, coinsWhilePaid, "coins are untouched")
        XCTAssertEqual(game.pickSlots, 5)
        XCTAssertEqual(game.discountPercent, 20)
        XCTAssertEqual(game.holdLimit, 1)
        XCTAssertEqual(game.rerollsPerDay, 3)
    }

    private func currentTransaction() async -> StoreKit.Transaction? {
        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let t) = result { return t }
        }
        return nil
    }
}

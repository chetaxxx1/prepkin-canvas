import Foundation
import XCTest
@testable import PrepkinCanvas

final class PlusTests: XCTestCase {
    func testEntitlementResolution() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let earlier = now.addingTimeInterval(-1)
        let later = now.addingTimeInterval(1)

        let cases: [(name: String, records: [PlusRecord], expected: PlusEntitlement)] = [
            (
                "nothing",
                [],
                PlusEntitlement(product: nil, expiresAt: nil, isActive: false)
            ),
            (
                "active monthly",
                [PlusRecord(productID: PlusProduct.monthly.rawValue, expiresAt: later, revokedAt: nil)],
                PlusEntitlement(product: .monthly, expiresAt: later, isActive: true)
            ),
            (
                "expired monthly",
                [PlusRecord(productID: PlusProduct.monthly.rawValue, expiresAt: earlier, revokedAt: nil)],
                PlusEntitlement(product: nil, expiresAt: nil, isActive: false)
            ),
            (
                "revoked yearly",
                [PlusRecord(productID: PlusProduct.yearly.rawValue, expiresAt: later, revokedAt: now)],
                PlusEntitlement(product: nil, expiresAt: nil, isActive: false)
            ),
            (
                "both active picks yearly",
                [
                    PlusRecord(productID: PlusProduct.monthly.rawValue, expiresAt: later, revokedAt: nil),
                    PlusRecord(productID: PlusProduct.yearly.rawValue, expiresAt: later, revokedAt: nil),
                ],
                PlusEntitlement(product: .yearly, expiresAt: later, isActive: true)
            ),
            (
                "unknown product is ignored",
                [PlusRecord(productID: "com.prepkin.canvas.plus.other", expiresAt: later, revokedAt: nil)],
                PlusEntitlement(product: nil, expiresAt: nil, isActive: false)
            ),
            (
                "expiry exactly at now",
                [PlusRecord(productID: PlusProduct.monthly.rawValue, expiresAt: now, revokedAt: nil)],
                PlusEntitlement(product: nil, expiresAt: nil, isActive: false)
            ),
        ]

        for testCase in cases {
            XCTAssertEqual(
                PlusEntitlement.resolve(testCase.records, now: now),
                testCase.expected,
                testCase.name
            )
        }
    }
}

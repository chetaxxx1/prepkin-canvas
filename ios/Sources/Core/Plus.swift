import Combine
import Foundation
import StoreKit

enum PlusProduct: String, CaseIterable {
    case monthly = "com.prepkin.canvas.plus.monthly"
    case yearly = "com.prepkin.canvas.plus.yearly"

    static let defaultProduct: PlusProduct = .yearly
}

struct PlusRecord {
    var productID: String
    var expiresAt: Date?
    var revokedAt: Date?
    /// Apple's billing grace period: the card bounced, Apple is retrying, and the
    /// student still has the subscription.
    ///
    /// This has to be carried separately because a transaction in grace has an
    /// `expirationDate` **in the past** — so the plain date check below would drop
    /// it, and a student whose card expired would lose their shop row and their
    /// 90-minute chip for a fortnight through no fault of their own.
    var inGracePeriod = false
}

struct PlusEntitlement: Equatable {
    var product: PlusProduct?
    var expiresAt: Date?
    var isActive: Bool

    static func resolve(_ records: [PlusRecord], now: Date) -> PlusEntitlement {
        let active = records.filter { record in
            guard let _ = PlusProduct(rawValue: record.productID),
                  record.revokedAt == nil else {
                return false
            }
            // In grace, the date is already past and the entitlement is still live.
            if record.inGracePeriod { return true }
            return record.expiresAt.map { $0 > now } ?? true
        }

        for product in [PlusProduct.yearly, .monthly] {
            let matching = active.filter { $0.productID == product.rawValue }
            guard let record = matching.max(by: { left, right in
                (left.expiresAt ?? .distantFuture) < (right.expiresAt ?? .distantFuture)
            }) else {
                continue
            }
            return PlusEntitlement(product: product, expiresAt: record.expiresAt, isActive: true)
        }

        return PlusEntitlement(product: nil, expiresAt: nil, isActive: false)
    }
}

@MainActor
final class PlusStore: ObservableObject {
    @Published private(set) var entitlement = PlusEntitlement(
        product: nil,
        expiresAt: nil,
        isActive: false
    )
    @Published private(set) var products: [Product] = []

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                if Task.isCancelled {
                    return
                }
                guard let self else {
                    return
                }
                guard let transaction = try? self.checkVerified(result) else {
                    continue
                }
                await transaction.finish()
                await self.refreshEntitlement()
            }
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func load() async {
        do {
            products = try await Product.products(for: PlusProduct.allCases.map(\.rawValue))
        } catch {}
        await refreshEntitlement()
    }

    func purchase(_ p: PlusProduct) async throws -> Bool {
        guard let product = products.first(where: { $0.id == p.rawValue }) else {
            return false
        }

        switch try await product.purchase() {
        case .success(let result):
            let transaction = try checkVerified(result)
            await transaction.finish()
            await refreshEntitlement()
            return true
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
        } catch {
            return
        }
        await refreshEntitlement()
    }

    private func refreshEntitlement() async {
        guard let currentEntitlement = await readEntitlement() else {
            return
        }
        entitlement = currentEntitlement
    }

    private func readEntitlement() async -> PlusEntitlement? {
        var records: [PlusRecord] = []
        let grace = await gracePeriodProductIDs()

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else {
                return nil
            }
            records.append(PlusRecord(
                productID: transaction.productID,
                expiresAt: transaction.expirationDate,
                revokedAt: transaction.revocationDate,
                inGracePeriod: grace.contains(transaction.productID)
            ))
        }

        return PlusEntitlement.resolve(records, now: Date())
    }

    /// Products whose subscription is in Apple's billing grace period right now.
    ///
    /// Read from the subscription status rather than from the transaction, because
    /// the transaction only carries a date and the date is what grace makes a liar.
    private func gracePeriodProductIDs() async -> Set<String> {
        var out: Set<String> = []
        for product in products {
            guard let statuses = try? await product.subscription?.status else { continue }
            for status in statuses ?? [] where status.state == .inGracePeriod {
                guard let transaction = try? checkVerified(status.transaction) else { continue }
                out.insert(transaction.productID)
            }
        }
        return out
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified:
            throw PlusStoreError.failedVerification
        }
    }
}

private enum PlusStoreError: Error {
    case failedVerification
}

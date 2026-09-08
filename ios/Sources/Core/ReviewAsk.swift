import Foundation
import StoreKit
import UIKit

/// Pure rules for when the App Store review prompt has been earned.
///
/// Apple caps how often the sheet can appear; we add our own floor so a brand-new
/// install and a fresh ask never collide, and so we only ask after real Canvas use.
struct ReviewAsk {
    static func shouldAsk(
        finishedCanvasItems: Int,
        lastAskedAt: Date?,
        installedAt: Date,
        now: Date
    ) -> Bool {
        guard finishedCanvasItems >= 5 else { return false }
        let day: TimeInterval = 24 * 60 * 60
        guard now.timeIntervalSince(installedAt) >= 3 * day else { return false }
        if let lastAskedAt {
            guard now.timeIntervalSince(lastAskedAt) > 120 * day else { return false }
        }
        return true
    }
}

/// Thin side-effect wrapper: UserDefaults + the system review sheet.
@MainActor
enum ReviewPrompt {
    private static let installedKey = "reviewAsk.installedAt"
    private static let lastAskedKey = "reviewAsk.lastAskedAt"

    static func askIfEarned(finishedCanvasItems: Int, now: Date = Date()) {
        let defaults = UserDefaults.standard
        let installedAt: Date
        if let stored = defaults.object(forKey: installedKey) as? Date {
            installedAt = stored
        } else {
            defaults.set(now, forKey: installedKey)
            installedAt = now
        }
        let lastAskedAt = defaults.object(forKey: lastAskedKey) as? Date
        guard ReviewAsk.shouldAsk(
            finishedCanvasItems: finishedCanvasItems,
            lastAskedAt: lastAskedAt,
            installedAt: installedAt,
            now: now
        ) else { return }

        defaults.set(now, forKey: lastAskedKey)
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first
        else { return }
        AppStore.requestReview(in: scene)
    }
}

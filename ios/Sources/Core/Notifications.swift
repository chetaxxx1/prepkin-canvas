import Foundation
import UserNotifications

/// One reminder we intend to post. Planning is kept separate from posting so the
/// rules — and especially the "don't nag" rules — can be tested without a device.
struct PlannedNotification: Equatable, Identifiable {
    let id: String
    let title: String
    let body: String
    let fireAt: Date
}

/// Decides what to remind about, and when.
///
/// House rule, carried from the economy: reminders are never a punishment. Nothing
/// here counts a streak, warns about losing anything, or scolds. The worst case is
/// a note saying the mascot is around.
enum NotificationPlanner {
    /// How far ahead of a due date to speak up.
    static let dueLead: TimeInterval = 12 * 3600
    /// Never fire a reminder in the small hours.
    static let earliestHour = 8
    /// Days of evening nudges to queue up, so a closed app still gets a couple.
    static let nudgeHorizon = 3
    /// Silence after this many days away, then one gentle note.
    static let comeBackAfterDays = 3

    static func plan(for state: GameState, now: Date = Date(), calendar: Calendar = .current) -> [PlannedNotification] {
        guard state.settings.remindersEnabled else { return [] }
        let name = state.activeChibi.species.name
        var out: [PlannedNotification] = []

        if state.settings.dueRemindersEnabled {
            out += dueReminders(for: state, now: now, calendar: calendar)
        }
        out += nudges(for: state, name: name, now: now, calendar: calendar)
        if state.settings.comeBackRemindersEnabled {
            out += comeBack(for: state, name: name, now: now, calendar: calendar)
        }
        return out.sorted { $0.fireAt < $1.fireAt }
    }

    // MARK: - Pieces

    private static func dueReminders(for state: GameState, now: Date, calendar: Calendar) -> [PlannedNotification] {
        let doneIDs = Set(state.tasks.filter(\.done).map(\.id))
        return state.canvasItems.compactMap { item -> PlannedNotification? in
            guard let due = item.dueAt, due > now, !doneIDs.contains(item.id) else { return nil }
            var fire = due.addingTimeInterval(-dueLead)
            // Too late for the full lead — settle for a couple of hours' warning.
            if fire <= now { fire = due.addingTimeInterval(-2 * 3600) }
            guard fire > now else { return nil }
            fire = pushPastQuietHours(fire, calendar: calendar)
            guard fire < due else { return nil }
            return PlannedNotification(
                id: "due:\(item.id)",
                title: item.title,
                body: "Due \(due.formatted(.dateTime.weekday().hour().minute())) · \(item.courseName). Just a heads up.",
                fireAt: fire)
        }
    }

    private static func nudges(for state: GameState, name: String, now: Date, calendar: Calendar) -> [PlannedNotification] {
        guard !state.templates.filter({ $0.isActive && $0.retiredOn == nil }).isEmpty else { return [] }
        let openToday = state.tasks.contains { !$0.done }
        return (0..<nudgeHorizon).compactMap { offset -> PlannedNotification? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: now),
                  let fire = calendar.date(bySettingHour: state.settings.nudgeHour, minute: 0, second: 0, of: day),
                  fire > now else { return nil }
            // Today's nudge is dropped once the list is clear. Later days we can't
            // know yet, so they stay queued and get replaced on the next open.
            if offset == 0 && !openToday { return nil }
            return PlannedNotification(
                id: "nudge:\(DayKey(day, calendar: calendar).raw)",
                title: "Anything left for today?",
                body: "\(name) is around whenever you want to knock something out.",
                fireAt: fire)
        }
    }

    private static func comeBack(for state: GameState, name: String, now: Date, calendar: Calendar) -> [PlannedNotification] {
        guard let day = calendar.date(byAdding: .day, value: comeBackAfterDays, to: state.lastOpenedAt),
              let fire = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: day),
              fire > now else { return [] }
        return [PlannedNotification(
            id: "comeback",
            title: "\(name) is still here",
            body: "Nothing to catch up on. Come back whenever you like.",
            fireAt: fire)]
    }

    private static func pushPastQuietHours(_ date: Date, calendar: Calendar) -> Date {
        guard calendar.component(.hour, from: date) < earliestHour else { return date }
        return calendar.date(bySettingHour: earliestHour, minute: 0, second: 0, of: date) ?? date
    }
}

/// Posts the plan to iOS. Local notifications only — no server, no push
/// certificate, and nothing here needs a paid developer account.
@MainActor
final class NotificationScheduler {
    static let shared = NotificationScheduler()
    private let center = UNUserNotificationCenter.current()

    /// Asked for only when the user turns reminders on themselves.
    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func isAuthorized() async -> Bool {
        let status = await center.notificationSettings().authorizationStatus
        return status == .authorized || status == .provisional
    }

    /// A refusal, not merely "not on". `.notDetermined` — a fresh install nobody has
    /// asked yet — is deliberately not denial, so a student who has never seen the
    /// prompt is never shown a line about Settings.
    func isDenied() async -> Bool {
        await center.notificationSettings().authorizationStatus == .denied
    }

    /// Replaces every pending reminder with the current plan. Cheap enough to call
    /// on each change, which is what keeps a finished task from still buzzing.
    func reschedule(for state: GameState) async {
        center.removeAllPendingNotificationRequests()
        let plan = NotificationPlanner.plan(for: state)
        guard !plan.isEmpty, await isAuthorized() else { return }
        for item in plan {
            let content = UNMutableNotificationContent()
            content.title = item.title
            content.body = item.body
            content.sound = .default
            let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: item.fireAt)
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: item.id, content: content, trigger: trigger))
        }
    }
}

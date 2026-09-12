import Foundation
import UserNotifications

/// One reminder we intend to post. Planning is kept separate from posting so the
/// rules — and especially the "don't nag" rules — can be tested without a device.
struct PlannedNotification: Equatable, Identifiable {
    let id: String
    let title: String
    /// The second line iOS draws under the title, in the same weight. Only a due
    /// reminder uses it, for the assignment's own name.
    var subtitle: String? = nil
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
    /// The last hour a check-in may be set for. Quiet from 10 PM to 8 AM for
    /// everything that is not a due date.
    static let latestNudgeHour = 22
    /// Days of evening nudges to queue up, so a closed app still gets a couple.
    static let nudgeHorizon = 3
    /// Silence after this many days away, then one gentle note.
    static let comeBackAfterDays = 3

    static func plan(for state: GameState, now: Date = Date(), calendar: Calendar = .current) -> [PlannedNotification] {
        guard state.settings.remindersEnabled else { return [] }
        let name = state.activeChibi.displayName
        var out: [PlannedNotification] = []

        if state.settings.dueRemindersEnabled {
            out += dueReminders(for: state, name: name, now: now, calendar: calendar)
        }
        // One non-due note a day, at most. The board's two are weekly and rarer, so
        // on a Sunday or Monday they win and that evening's check-in is dropped.
        let weekly = board(for: state, now: now, calendar: calendar)
            + (state.settings.comeBackRemindersEnabled
               ? comeBack(for: state, name: name, now: now, calendar: calendar) : [])
        let taken = Set(weekly.map { DayKey($0.fireAt, calendar: calendar) })
        out += weekly
        out += nudges(for: state, name: name, now: now, calendar: calendar)
            .filter { !taken.contains(DayKey($0.fireAt, calendar: calendar)) }
        return out.sorted { $0.fireAt < $1.fireAt }
    }

    // MARK: - The evening check-in's words

    /// "2 left today" over "Essay outline, then the walk. Then you're done."
    ///
    /// Built from the real list, in the student's own task names. Two names at
    /// most; a longer list says how many more rather than promising "done" after
    /// two of five. `nil` when nothing is open — a clear list earns silence, not
    /// a note. The second name loses its capital so the sentence reads as one,
    /// unless it starts with an acronym like "BIO 101".
    static func checkIn(openTitles: [String]) -> (title: String, body: String)? {
        let titles = openTitles.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        guard !titles.isEmpty else { return nil }
        let n = titles.count
        let title = "\(n) left today"
        switch n {
        case 1:
            return (title, "\(titles[0]). Then you're done.")
        case 2:
            return (title, "\(titles[0]), then \(lowerFirst(titles[1])). Then you're done.")
        default:
            return (title, "\(titles[0]), then \(lowerFirst(titles[1])), then \(n - 2) more.")
        }
    }

    private static func lowerFirst(_ s: String) -> String {
        guard let first = s.first, first.isUppercase else { return s }
        let second = s.dropFirst().first
        // "BIO 101 quiz" keeps its capital; "The walk" becomes "the walk".
        guard second == nil || second!.isLowercase else { return s }
        return first.lowercased() + s.dropFirst()
    }

    // MARK: - The board's two

    /// Duolingo's two league notes, minus the countdown: one on Sunday evening
    /// saying the board settles tonight, one on Monday morning saying it has.
    /// Only with a friend to be on a board with, and never a place or a number —
    /// the planner reads the save file, and the board is not in it. Sunday's is
    /// dropped once it is already evening.
    static let settleHour = 18
    static let settledHour = 9

    private static func board(for state: GameState, now: Date, calendar: Calendar) -> [PlannedNotification] {
        guard !state.friends.isEmpty else { return [] }
        var out: [PlannedNotification] = []
        let week = WeekKey(DayKey(now, calendar: calendar))
        let days = week.days()
        guard days.count == 7 else { return out }
        func date(_ key: DayKey, hour: Int) -> Date? {
            let parts = key.raw.split(separator: "-").compactMap { Int($0) }
            guard parts.count == 3 else { return nil }
            return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: hour))
        }
        if let sunday = date(days[6], hour: settleHour), sunday > now {
            out.append(PlannedNotification(
                id: "board:settles:\(week.raw)",
                title: "The board settles tonight",
                body: "Anything you finish today still counts. Everyone starts over tomorrow.",
                fireAt: sunday))
        }
        if let nextMonday = calendar.date(byAdding: .day, value: 1, to: date(days[6], hour: settledHour) ?? now),
           nextMonday > now {
            out.append(PlannedNotification(
                id: "board:settled:\(week.raw)",
                title: "Last week's board is in",
                body: "See where you finished, and who is on the sand this morning.",
                fireAt: nextMonday))
        }
        return out
    }

    // MARK: - Pieces

    /// Due reminders are the one kind allowed past 10 PM, and even they stop here.
    static let latestDueHour = 23

    private static func dueReminders(for state: GameState, name: String, now: Date, calendar: Calendar) -> [PlannedNotification] {
        let doneIDs = Set(state.tasks.filter(\.done).map(\.id))
        return state.canvasItems.compactMap { item -> PlannedNotification? in
            guard let due = item.dueAt, due > now, !doneIDs.contains(item.id) else { return nil }
            var fire = due.addingTimeInterval(-dueLead)
            // Too late for the full lead — settle for a couple of hours' warning.
            if fire <= now { fire = due.addingTimeInterval(-2 * 3600) }
            guard fire > now else { return nil }
            fire = pushPastQuietHours(fire, calendar: calendar)
            fire = pullBeforeMidnight(fire, calendar: calendar)
            guard fire > now, fire < due else { return nil }
            let when = due.formatted(.dateTime.weekday().hour().minute())
            return PlannedNotification(
                id: "due:\(item.id)",
                title: "Due \(when) · \(item.courseName)",
                subtitle: item.title,
                body: "Just a heads up. \(name) is around if you want to knock it out.",
                fireAt: fire)
        }
    }

    private static func nudges(for state: GameState, name: String, now: Date, calendar: Calendar) -> [PlannedNotification] {
        return (0..<nudgeHorizon).compactMap { offset -> PlannedNotification? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: now),
                  let fire = calendar.date(bySettingHour: state.settings.nudgeHour, minute: 0, second: 0, of: day),
                  fire > now else { return nil }
            // Today's names are the real list. A later day's are what will be on it
            // when it comes: the dailies come back, open Canvas work stays, and
            // anything dated for that day joins. Replaced on the next open either way.
            let titles = offset == 0 ? state.tasks.filter { !$0.done }.map(\.title)
                                     : expectedOpenTitles(for: state, on: DayKey(day, calendar: calendar))
            // A clear list earns silence.
            guard let copy = checkIn(openTitles: titles) else { return nil }
            return PlannedNotification(
                id: "nudge:\(DayKey(day, calendar: calendar).raw)",
                title: copy.title,
                body: copy.body,
                fireAt: fire)
        }
    }

    private static func expectedOpenTitles(for state: GameState, on day: DayKey) -> [String] {
        let canvas = state.tasks.filter { $0.kind == .canvas && !$0.done }.map(\.title)
        let dated = state.datedTasks.filter { $0.day == day }.map(\.title)
        let daily = state.templates.filter { $0.isActive && $0.retiredOn == nil }.map(\.title)
        return canvas + dated + daily
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

    /// A due reminder that would land at 11 PM or later moves back to 10 PM.
    private static func pullBeforeMidnight(_ date: Date, calendar: Calendar) -> Date {
        guard calendar.component(.hour, from: date) >= latestDueHour else { return date }
        return calendar.date(bySettingHour: latestDueHour - 1, minute: 0, second: 0, of: date) ?? date
    }

    // MARK: - The fourth kind: the end of a shift

    /// The one notification that is not a reminder.
    ///
    /// The other three are the app deciding to speak, so they all sit behind
    /// `remindersEnabled` and behind the quiet hours. This one is the student asking
    /// for a timer: they tapped Start and put the phone face down, and the whole
    /// promise of the tab is that they do not have to watch it. So it fires whether
    /// or not reminders are on, at the second the shift runs out, at whatever hour
    /// that is — and it survives `reschedule`, which replaces everything else.
    ///
    /// `nil` unless a shift is actually counting down. A paused shift has no end
    /// time, which is precisely why pausing takes it off the queue.
    static func shiftEnd(for shift: FocusShift, kinName: String,
                         now: Date = Date()) -> PlannedNotification? {
        guard let endsAt = shift.endsAt(at: now) else { return nil }
        let minutes = shift.plannedMinutes
        let lengths = FocusShift.lengths(inMinutes: minutes)
        return PlannedNotification(
            id: shiftEndID,
            title: "Shift over. \(minutes) coin\(minutes == 1 ? "" : "s") paid.",
            body: "\(kinName) swam \(lengths) length\(lengths == 1 ? "" : "s").",
            fireAt: endsAt)
    }

    static let shiftEndID = "shift-end"
}

/// Posts the plan to iOS. Local notifications only — no server, no push
/// certificate, and nothing here needs a paid developer account.
@MainActor
final class NotificationScheduler {
    static let shared = NotificationScheduler()
    private let center = UNUserNotificationCenter.current()

    /// Asked for only when the user turns reminders on themselves. No `.badge`: a red
    /// number on the icon is a scold, and nothing here ever sets one.
    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
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

    /// Nobody has ever been asked. The first Start checks this so it can explain
    /// itself once, in one line, instead of throwing the system prompt at a student
    /// who only wanted a timer.
    func isUndecided() async -> Bool {
        await center.notificationSettings().authorizationStatus == .notDetermined
    }

    /// Replaces every pending reminder with the current plan. Cheap enough to call
    /// on each change, which is what keeps a finished task from still buzzing.
    ///
    /// Everything *except* a running shift's own alarm. `removeAllPendingNotificationRequests`
    /// used to stand here, and it also cancelled the timer the student had asked for —
    /// checking off a task mid-shift would have silently killed the end of the shift.
    func reschedule(for state: GameState) async {
        let stale = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0 != NotificationPlanner.shiftEndID }
        center.removePendingNotificationRequests(withIdentifiers: stale)
        let plan = NotificationPlanner.plan(for: state)
        guard !plan.isEmpty, await isAuthorized() else { return }
        for item in plan {
            let content = UNMutableNotificationContent()
            content.title = item.title
            if let subtitle = item.subtitle { content.subtitle = subtitle }
            content.body = item.body
            content.sound = .default
            let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: item.fireAt)
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: item.id, content: content, trigger: trigger))
        }
    }

    // MARK: - The running shift

    /// Bumped by every cancel. `scheduleShiftEnd` suspends twice before it posts
    /// anything, and a clock-out landing in that gap would otherwise leave a
    /// "Shift over. 25 coins paid." queued for a shift that paid nothing.
    private var shiftEndGeneration = 0

    /// Books the end of the shift. Called on Start and again on Resume; the second
    /// call replaces the first, because a resumed shift ends later than the one that
    /// was paused.
    ///
    /// An interval trigger, not the calendar one the reminders use: a calendar
    /// trigger is only good to the minute, so a 15 started at 10:00:40 would have
    /// gone off at 10:15:00 — forty seconds before the coins were earned.
    ///
    /// Nothing here shows while the app is open. Prepkin sets no
    /// `UNUserNotificationCenterDelegate`, so iOS suppresses a foreground banner —
    /// which is what we want: a student watching the shift screen gets the report,
    /// not a note telling them what they can already see.
    func scheduleShiftEnd(_ item: PlannedNotification, from now: Date = Date()) async {
        cancelShiftEnd()
        let mine = shiftEndGeneration
        let seconds = item.fireAt.timeIntervalSince(now)
        guard seconds > 0, await isAuthorized(), mine == shiftEndGeneration else { return }
        let content = UNMutableNotificationContent()
        content.title = item.title
        content.body = item.body
        content.sound = .default
        // No badge, here or anywhere. A finished shift is not a pile of unread
        // things, and a red dot on the icon is the opposite of putting the phone down.
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        try? await center.add(UNNotificationRequest(identifier: item.id, content: content, trigger: trigger))
        guard mine == shiftEndGeneration else { return cancelShiftEnd() }
    }

    /// Pause and clock out both call this. So does the app on the way to the report,
    /// so a shift that ended while the screen was open cannot also buzz.
    func cancelShiftEnd() {
        shiftEndGeneration += 1
        center.removePendingNotificationRequests(withIdentifiers: [NotificationPlanner.shiftEndID])
        center.removeDeliveredNotifications(withIdentifiers: [NotificationPlanner.shiftEndID])
    }
}

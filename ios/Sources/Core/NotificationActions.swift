import Foundation
import UIKit
import UserNotifications

/// What a tap on a notification means, and the one button some of them carry.
///
/// Every notification that names a task carries "Done". Tapping it writes a mark
/// to the app group (`DoneMarks`) — it does not pay. The app pays on its next open,
/// once, through the ledger. A tap on the shift-end note opens Focus, which is
/// already showing the report by then. Every other tap simply opens the app.
enum NotificationActions {
    static let taskCategory = "prepkin.task"
    static let doneAction = "prepkin.done"
    static let taskIDKey = "taskID"

    /// Registered once at launch. `Done` is the only action; there is no "Later",
    /// because dismissing already means that.
    static func register(with center: UNUserNotificationCenter = .current()) {
        let done = UNNotificationAction(identifier: doneAction, title: "Done", options: [])
        let category = UNNotificationCategory(identifier: taskCategory, actions: [done],
                                              intentIdentifiers: [], options: [])
        center.setNotificationCategories([category])
    }

    /// Reads a response and leaves a done-mark when that is what was tapped.
    static func route(_ response: UNNotificationResponse) -> NotificationRoute {
        let content = response.notification.request.content
        let requestID = response.notification.request.identifier
        if response.actionIdentifier == doneAction,
           let taskID = content.userInfo[taskIDKey] as? String {
            DoneMarks.add(taskID)
            return .doneMarked(taskID)
        }
        if requestID == NotificationPlanner.shiftEndID { return .focusReport }
        return .home
    }
}

enum NotificationRoute: Equatable {
    /// A Done button was tapped; the mark is written and the app should pay it.
    case doneMarked(String)
    /// The shift-end note was tapped: open Focus, where the report is.
    case focusReport
    case home
}

/// The delegate iOS hands notification taps to. It only forwards: the App scene
/// watches `route` and does the work with the real `AppState`.
///
/// Setting a delegate has one side effect worth naming: with no `willPresent`
/// implemented, a notification that fires while the app is open is not shown,
/// which is what Focus relies on — a student watching the shift screen gets the
/// report, not a banner about what they can already see.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, ObservableObject {
    @Published var route: NotificationRoute?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        NotificationActions.register()
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let route = NotificationActions.route(response)
        await MainActor.run { self.route = route }
    }
}

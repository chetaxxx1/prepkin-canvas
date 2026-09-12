import AppIntents
import WidgetKit

/// The box on a medium-widget row. Tapping it runs here, in the widget's own
/// process, and does exactly one thing: leaves a done-mark in the app group —
/// the same mark the notification's Done button leaves. The app reads it on its
/// next open, pays through the ledger and clears it. No coins move here, so the
/// ledger stays in one place. WidgetKit redraws the widget when this returns,
/// and the provider draws the marked row ticked.
struct MarkDoneIntent: AppIntent {
    static var title: LocalizedStringResource = "Finish a task"
    static var description = IntentDescription("Ticks one task on the widget. Prepkin pays the coins the next time it opens.")

    @Parameter(title: "Task")
    var taskID: String

    init() {}
    init(taskID: String) { self.taskID = taskID }

    func perform() async throws -> some IntentResult {
        DoneMarks.add(taskID)
        return .result()
    }
}

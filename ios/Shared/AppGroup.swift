import Foundation

/// The folder the app, the widget and the Live Activity all see.
///
/// Two things live in it and nothing else: `widget.json`, the small snapshot the
/// home-screen widget draws from, and `done-marks.json`, the ids of tasks a student
/// finished from a notification or a widget box. The save file never goes here — a
/// schema change in the app must not be able to break the widget.
enum AppGroup {
    static let id = "group.com.prepkin.canvas"

    /// The shared container. Falls back to the app's own support folder when the
    /// group is not available — an unsigned test bundle, or a build without the
    /// entitlement — so nothing that writes here has to handle a missing folder.
    static var container: URL {
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id) {
            return url
        }
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PrepkinCanvas", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }
}

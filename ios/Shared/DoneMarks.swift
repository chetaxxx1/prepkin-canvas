import Foundation

/// A task finished from outside the app: the Done button on a notification, or a
/// box on the medium widget.
///
/// Neither of those processes may pay coins — the ledger lives in the app and only
/// the app writes it. So the tap leaves a mark here, in the app group, and the app
/// reads the marks on its next open, pays each one once (the ledger key makes a
/// second read harmless) and clears the file.
struct DoneMark: Codable, Equatable {
    let taskID: String
    let at: Date
}

enum DoneMarks {
    static let fileName = "done-marks.json"

    static func url(in directory: URL = AppGroup.container) -> URL {
        directory.appendingPathComponent(fileName)
    }

    static func load(in directory: URL = AppGroup.container) -> [DoneMark] {
        guard let data = try? Data(contentsOf: url(in: directory)) else { return [] }
        return (try? decoder.decode([DoneMark].self, from: data)) ?? []
    }

    /// Adds one mark. A second tap on the same task is not a second mark.
    static func add(_ taskID: String, at: Date = Date(), in directory: URL = AppGroup.container) {
        var marks = load(in: directory)
        guard !marks.contains(where: { $0.taskID == taskID }) else { return }
        marks.append(DoneMark(taskID: taskID, at: at))
        write(marks, in: directory)
    }

    static func clear(in directory: URL = AppGroup.container) {
        try? FileManager.default.removeItem(at: url(in: directory))
    }

    private static func write(_ marks: [DoneMark], in directory: URL) {
        guard let data = try? encoder.encode(marks) else { return }
        try? data.write(to: url(in: directory), options: .atomic)
    }

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}

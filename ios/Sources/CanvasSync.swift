import Foundation

/// One item from the Canvas LMS to-do feed.
struct CanvasItem: Codable, Equatable {
    let id: String
    let title: String
    let courseName: String
    let dueAt: Date?
}

/// The bridge to Canvas data. Real implementation (M2) will poll the pairing
/// bridge the Chrome extension pushes to. v1 uses the mock.
protocol CanvasSyncClient {
    func fetchTodo() async throws -> [CanvasItem]
}

struct MockCanvasClient: CanvasSyncClient {
    func fetchTodo() async throws -> [CanvasItem] {
        let cal = Calendar.current
        func due(_ days: Int, hour: Int) -> Date {
            cal.date(bySettingHour: hour, minute: 59, second: 0,
                     of: cal.date(byAdding: .day, value: days, to: Date())!)!
        }
        return [
            CanvasItem(id: "c-101", title: "Ch. 5 Problem Set", courseName: "AP Physics", dueAt: due(0, hour: 23)),
            CanvasItem(id: "c-102", title: "Essay outline", courseName: "English 11", dueAt: due(1, hour: 8)),
            CanvasItem(id: "c-103", title: "Unit 3 quiz", courseName: "APUSH", dueAt: due(2, hour: 15)),
        ]
    }
}

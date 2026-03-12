import Foundation
import SwiftData

@Model
final class TopMissionEntry {
    var widgetID: UUID = UUID()
    var task: String = ""
    var subtasksRaw: String = ""
    var updatedAt: Date = Date()

    init(widgetID: UUID,
         task: String,
         subtasksRaw: String = "",
         updatedAt: Date = Date()) {
        self.widgetID = widgetID
        self.task = task
        self.subtasksRaw = subtasksRaw
        self.updatedAt = updatedAt
    }
}

extension TopMissionEntry {
    var subtasksList: [String] {
        subtasksRaw
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

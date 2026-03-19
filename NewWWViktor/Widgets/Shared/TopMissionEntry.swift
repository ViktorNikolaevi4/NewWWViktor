import Foundation
import SwiftData

@Model
final class TopMissionEntry {
    var widgetID: UUID = UUID()
    var task: String = ""
    var isCompleted: Bool = false
    var deadlineAt: Date?
    var subtasksRaw: String = ""
    var subtasksStateRaw: String = ""
    var updatedAt: Date = Date()

    init(widgetID: UUID,
         task: String,
         isCompleted: Bool = false,
         deadlineAt: Date? = nil,
         subtasksRaw: String = "",
         subtasksStateRaw: String = "",
         updatedAt: Date = Date()) {
        self.widgetID = widgetID
        self.task = task
        self.isCompleted = isCompleted
        self.deadlineAt = deadlineAt
        self.subtasksRaw = subtasksRaw
        self.subtasksStateRaw = subtasksStateRaw
        self.updatedAt = updatedAt
    }
}

extension TopMissionEntry {
    var subtasksList: [String] {
        subtasks.map(\.title)
    }

    var subtasks: [TopMissionSubtask] {
        if let data = subtasksStateRaw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([TopMissionSubtask].self, from: data),
           !decoded.isEmpty {
            return decoded
        }

        return subtasksRaw
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { TopMissionSubtask(title: $0) }
    }

    func setSubtasks(_ subtasks: [TopMissionSubtask]) {
        let filtered = subtasks
            .map { TopMissionSubtask(id: $0.id,
                                     title: $0.title.trimmingCharacters(in: .whitespacesAndNewlines),
                                     isCompleted: $0.isCompleted) }
            .filter { !$0.title.isEmpty }

        subtasksRaw = filtered.map(\.title).joined(separator: "\n")

        if let data = try? JSONEncoder().encode(filtered),
           let encoded = String(data: data, encoding: .utf8) {
            subtasksStateRaw = encoded
        } else {
            subtasksStateRaw = ""
        }
    }
}

struct TopMissionSubtask: Codable, Equatable, Identifiable {
    var id: UUID
    var title: String
    var isCompleted: Bool

    init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}

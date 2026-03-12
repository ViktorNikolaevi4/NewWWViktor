import Foundation
import SwiftData

@Model
final class TopMissionEntry {
    var widgetID: UUID
    var task: String
    var updatedAt: Date

    init(widgetID: UUID,
         task: String,
         updatedAt: Date = Date()) {
        self.widgetID = widgetID
        self.task = task
        self.updatedAt = updatedAt
    }
}

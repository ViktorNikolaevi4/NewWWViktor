import Foundation
import SwiftData

@Model
final class EisenhowerTask {
    var title: String
    var quadrantRawValue: String
    var isDone: Bool
    var createdAt: Date

    init(title: String,
         quadrant: EisenhowerQuadrant,
         isDone: Bool = false,
         createdAt: Date = Date()) {
        self.title = title
        quadrantRawValue = quadrant.rawValue
        self.isDone = isDone
        self.createdAt = createdAt
    }

    var quadrant: EisenhowerQuadrant {
        get { EisenhowerQuadrant(rawValue: quadrantRawValue) ?? .importantNotUrgent }
        set { quadrantRawValue = newValue.rawValue }
    }
}

enum EisenhowerQuadrant: String, CaseIterable, Codable {
    case importantUrgent
    case importantNotUrgent
    case notImportantUrgent
    case notImportantNotUrgent
}

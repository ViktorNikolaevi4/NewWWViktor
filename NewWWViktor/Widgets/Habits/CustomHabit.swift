import Foundation
import SwiftData

@Model
final class CustomHabit {
    var id: UUID
    var title: String
    var createdAt: Date

    init(title: String, createdAt: Date = Date()) {
        self.id = UUID()
        self.title = title
        self.createdAt = createdAt
    }
}

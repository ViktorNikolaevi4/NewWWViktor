import Foundation
import SwiftData

@Model
final class HabitEntry {
    var widgetID: UUID
    var habitKindRawValue: String
    var customHabitID: UUID?
    var streakDays: Int
    var progressDays: Int
    var updatedAt: Date

    init(widgetID: UUID,
         habitKind: HabitKind = .drinkWater,
         customHabitID: UUID? = nil,
         streakDays: Int = 0,
         progressDays: Int = 0,
         updatedAt: Date = Date()) {
        self.widgetID = widgetID
        self.habitKindRawValue = habitKind.rawValue
        self.customHabitID = customHabitID
        self.streakDays = streakDays
        self.progressDays = progressDays
        self.updatedAt = updatedAt
    }

    var habitKind: HabitKind {
        get { HabitKind(rawValue: habitKindRawValue) ?? .drinkWater }
        set { habitKindRawValue = newValue.rawValue }
    }
}

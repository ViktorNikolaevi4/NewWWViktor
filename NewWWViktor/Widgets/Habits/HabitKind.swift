import Foundation

enum HabitKind: String, CaseIterable, Identifiable, Codable {
    case drinkWater
    case workout
    case reading
    case meditation
    case sleep

    var id: String { rawValue }

    var titleKey: LocalizationKey {
        switch self {
        case .drinkWater:
            return .widgetHabitsWater
        case .workout:
            return .widgetHabitsWorkout
        case .reading:
            return .widgetHabitsReading
        case .meditation:
            return .widgetHabitsMeditation
        case .sleep:
            return .widgetHabitsSleep
        }
    }
}

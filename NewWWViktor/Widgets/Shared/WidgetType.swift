import SwiftUI

enum WidgetType: String, Codable, CaseIterable, Identifiable {
    case clock
    case weather
    case pomodoro
    case battery
    case eisenhower

    var id: String { rawValue }

    var categoryLabelKey: LocalizationKey {
        switch self {
        case .clock: return .widgetCategoryLabel
        case .weather: return .widgetCategoryLabel
        case .pomodoro: return .widgetCategoryLabel
        case .battery: return .widgetCategoryLabel
        case .eisenhower: return .widgetCategoryLabel
        }
    }

    var detailTitleKey: LocalizationKey {
        switch self {
        case .clock: return .widgetClockDetailTitle
        case .weather: return .widgetWeatherDetailTitle
        case .pomodoro: return .widgetPomodoroDetailTitle
        case .battery: return .widgetBatteryDetailTitle
        case .eisenhower: return .widgetEisenhowerDetailTitle
        }
    }

    var detailDescriptionKey: LocalizationKey {
        switch self {
        case .clock: return .widgetClockDetailDescription
        case .weather: return .widgetWeatherDetailDescription
        case .pomodoro: return .widgetPomodoroDetailDescription
        case .battery: return .widgetBatteryDetailDescription
        case .eisenhower: return .widgetEisenhowerDetailDescription
        }
    }

    var detailLinkTitleKey: LocalizationKey? {
        switch self {
        case .clock: return nil
        case .weather: return nil
        case .pomodoro: return nil
        case .battery: return nil
        case .eisenhower: return nil
        }
    }

    var defaultSize: CGSize {
        switch self {
        case .clock:
            return WidgetSizeOption.medium.dimensions
        case .weather:
            return WidgetSizeOption.medium.dimensions
        case .pomodoro:
            return WidgetSizeOption.small.dimensions
        case .battery:
            return WidgetSizeOption.small.dimensions
        case .eisenhower:
            return WidgetSizeOption.small.dimensions
        }
    }

    var availableSizes: [WidgetSizeOption] {
        switch self {
        case .clock:
            return [.small, .medium]
        case .weather:
            return WidgetSizeOption.allCases
        case .pomodoro:
            return [.small, .medium]
        case .battery:
            return [.small, .medium, .large, .extraLarge]
        case .eisenhower:
            return [.small, .extraLarge]
        }
    }
}

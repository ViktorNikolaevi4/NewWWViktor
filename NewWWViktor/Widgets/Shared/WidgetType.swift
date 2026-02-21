import SwiftUI

enum WidgetType: String, Codable, CaseIterable, Identifiable {
    case clock
    case weather
    case pomodoro
    case battery
    case system
    case eisenhower
    case habits
    case crypto
    case links
    case clientsPayments
    case investment

    var id: String { rawValue }

    var categoryLabelKey: LocalizationKey {
        switch self {
        case .clock: return .widgetCategoryLabel
        case .weather: return .widgetCategoryLabel
        case .pomodoro: return .widgetCategoryLabel
        case .battery: return .widgetCategoryLabel
        case .system: return .widgetCategoryLabel
        case .eisenhower: return .widgetCategoryLabel
        case .habits: return .widgetCategoryLabel
        case .crypto: return .widgetCategoryLabel
        case .links: return .widgetCategoryLabel
        case .clientsPayments: return .widgetCategoryLabel
        case .investment: return .widgetCategoryLabel
        }
    }

    var detailTitleKey: LocalizationKey {
        switch self {
        case .clock: return .widgetClockDetailTitle
        case .weather: return .widgetWeatherDetailTitle
        case .pomodoro: return .widgetPomodoroDetailTitle
        case .battery: return .widgetBatteryDetailTitle
        case .system: return .widgetSystemDetailTitle
        case .eisenhower: return .widgetEisenhowerDetailTitle
        case .habits: return .widgetHabitsDetailTitle
        case .crypto: return .widgetCryptoDetailTitle
        case .links: return .widgetLinksDetailTitle
        case .clientsPayments: return .widgetClientsDetailTitle
        case .investment: return .widgetInvestmentDetailTitle
        }
    }

    var detailDescriptionKey: LocalizationKey {
        switch self {
        case .clock: return .widgetClockDetailDescription
        case .weather: return .widgetWeatherDetailDescription
        case .pomodoro: return .widgetPomodoroDetailDescription
        case .battery: return .widgetBatteryDetailDescription
        case .system: return .widgetSystemDetailDescription
        case .eisenhower: return .widgetEisenhowerDetailDescription
        case .habits: return .widgetHabitsDetailDescription
        case .crypto: return .widgetCryptoDetailDescription
        case .links: return .widgetLinksDetailDescription
        case .clientsPayments: return .widgetClientsDetailDescription
        case .investment: return .widgetInvestmentDetailDescription
        }
    }

    var detailLinkTitleKey: LocalizationKey? {
        switch self {
        case .clock: return nil
        case .weather: return nil
        case .pomodoro: return nil
        case .battery: return nil
        case .system: return nil
        case .eisenhower: return nil
        case .habits: return nil
        case .crypto: return nil
        case .links: return nil
        case .clientsPayments: return nil
        case .investment: return nil
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
        case .system:
            return WidgetSizeOption.small.dimensions
        case .eisenhower:
            return WidgetSizeOption.small.dimensions
        case .habits:
            return WidgetSizeOption.small.dimensions
        case .crypto:
            return WidgetSizeOption.small.dimensions
        case .links:
            return WidgetSizeOption.small.dimensions
        case .clientsPayments:
            return WidgetSizeOption.small.dimensions
        case .investment:
            return WidgetSizeOption.medium.dimensions
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
        case .system:
            return [.small, .medium]
        case .eisenhower:
            return [.small, .extraLarge]
        case .habits:
            return [.small]
        case .crypto:
            return [.small, .extraLarge]
        case .links:
            return [.small, .medium, .large]
        case .clientsPayments:
            return [.small]
        case .investment:
            return [.medium, .large]
        }
    }
}

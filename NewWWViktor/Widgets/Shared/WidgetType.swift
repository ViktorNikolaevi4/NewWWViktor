import SwiftUI

enum WidgetType: String, Codable, CaseIterable, Identifiable {
    case clock
    case weather

    var id: String { rawValue }

    var categoryLabelKey: LocalizationKey {
        switch self {
        case .clock: return .widgetCategoryLabel
        case .weather: return .widgetCategoryLabel
        }
    }

    var detailTitleKey: LocalizationKey {
        switch self {
        case .clock: return .widgetClockDetailTitle
        case .weather: return .widgetWeatherDetailTitle
        }
    }

    var detailDescriptionKey: LocalizationKey {
        switch self {
        case .clock: return .widgetClockDetailDescription
        case .weather: return .widgetWeatherDetailDescription
        }
    }

    var detailLinkTitleKey: LocalizationKey? {
        switch self {
        case .clock: return nil
        case .weather: return nil
        }
    }

    var defaultSize: CGSize {
        switch self {
        case .clock:
            return WidgetSizeOption.medium.dimensions
        case .weather:
            return WidgetSizeOption.medium.dimensions
        }
    }

    var availableSizes: [WidgetSizeOption] {
        switch self {
        case .clock:
            return [.small, .medium]
        case .weather:
            return WidgetSizeOption.allCases
        }
    }
}

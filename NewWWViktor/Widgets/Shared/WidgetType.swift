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
            // Similar to a medium widget: 2:1 ratio, feels native
            return CGSize(width: 320, height: 160)
        case .weather:
            return CGSize(width: 360, height: 190)
        }
    }
}

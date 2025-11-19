import SwiftUI

enum WidgetType: String, Codable, CaseIterable, Identifiable {
    case clock

    var id: String { rawValue }

    var categoryLabelKey: LocalizationKey {
        switch self {
        case .clock: return .widgetCategoryLabel
        }
    }

    var detailTitleKey: LocalizationKey {
        switch self {
        case .clock: return .widgetClockDetailTitle
        }
    }

    var detailDescriptionKey: LocalizationKey {
        switch self {
        case .clock: return .widgetClockDetailDescription
        }
    }

    var detailLinkTitleKey: LocalizationKey? {
        switch self {
        case .clock: return nil
        }
    }

    var defaultSize: CGSize {
        switch self {
        case .clock:
            // Similar to a medium widget: 2:1 ratio, feels native
            return CGSize(width: 320, height: 160)
        }
    }
}

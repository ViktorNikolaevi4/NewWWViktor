import SwiftUI

enum WidgetSizeOption: String, CaseIterable, Identifiable, Codable {
    case small
    case medium

    var id: String { rawValue }

    var title: String {
        switch self {
        case .small:
            return LocalizationManager.shared.text(.widgetSizeSmall)
        case .medium:
            return LocalizationManager.shared.text(.widgetSizeMedium)
        }
    }

    var subtitle: String {
        switch self {
        case .small:
            return LocalizationManager.shared.text(.widgetSizeSmallSubtitle)
        case .medium:
            return LocalizationManager.shared.text(.widgetSizeMediumSubtitle)
        }
    }

    var dimensions: CGSize {
        switch self {
        case .small:
            return CGSize(width: 170, height: 170)
        case .medium:
            return CGSize(width: 360, height: 170)
        }
    }

    var iconAssetName: String {
        switch self {
        case .small:
            return "widget size s"
        case .medium:
            return "widget size m"
        }
    }
}

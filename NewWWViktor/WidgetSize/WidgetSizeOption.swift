import SwiftUI

enum WidgetSizeOption: String, CaseIterable, Identifiable, Codable {
    case small
    case medium
    case large
    case extraLarge

    var id: String { rawValue }

    var title: String {
        switch self {
        case .small:
            return LocalizationManager.shared.text(.widgetSizeSmall)
        case .medium:
            return LocalizationManager.shared.text(.widgetSizeMedium)
        case .large:
            return LocalizationManager.shared.text(.widgetSizeLarge)
        case .extraLarge:
            return LocalizationManager.shared.text(.widgetSizeExtraLarge)
        }
    }

    var subtitle: String {
        switch self {
        case .small:
            return LocalizationManager.shared.text(.widgetSizeSmallSubtitle)
        case .medium:
            return LocalizationManager.shared.text(.widgetSizeMediumSubtitle)
        case .large:
            return LocalizationManager.shared.text(.widgetSizeLargeSubtitle)
        case .extraLarge:
            return LocalizationManager.shared.text(.widgetSizeExtraLargeSubtitle)
        }
    }

    var dimensions: CGSize {
        switch self {
        case .small:
            return CGSize(width: 170, height: 170)
        case .medium:
            return CGSize(width: 340, height: 170)
        case .large:
            return CGSize(width: 340, height: 340) // square-like L
        case .extraLarge:
            return CGSize(width: 340, height: 480)
        }
    }

    var iconAssetName: String {
        switch self {
        case .small:
            return "widget size s"
        case .medium:
            return "widget size m"
        case .large:
            return "widget size p1"
        case .extraLarge:
            return "widget size p2"
        }
    }
}

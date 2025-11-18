import SwiftUI

enum WidgetSizeOption: String, CaseIterable, Identifiable, Codable {
    case small
    case medium

    var id: String { rawValue }

    var title: String {
        switch self {
        case .small:
            return "Small"
        case .medium:
            return "Medium"
        }
    }

    var subtitle: String {
        switch self {
        case .small:
            return "Compact"
        case .medium:
            return "More content"
        }
    }

    var dimensions: CGSize {
        switch self {
        case .small:
            return CGSize(width: 170, height: 180)
        case .medium:
            return CGSize(width: 360, height: 190)
        }
    }
}

import SwiftUI

enum WidgetType: String, Codable, CaseIterable, Identifiable {
    case clock

    var id: String { rawValue }

    var title: String {
        switch self {
        case .clock: return "Clock"
        }
    }

    var subtitle: String {
        switch self {
        case .clock: return "Clean time, date & city widget"
        }
    }

    var defaultSize: CGSize {
        switch self {
        case .clock:
            // Близко к medium-виджету: 2:1, ощущается как системный
            return CGSize(width: 320, height: 160)
        }
    }
}

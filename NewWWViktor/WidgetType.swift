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

    var categoryLabel: String {
        switch self {
        case .clock: return "Widget"
        }
    }

    var heroTitle: String {
        switch self {
        case .clock: return "Moscow"
        }
    }

    var heroSubtitle: String {
        switch self {
        case .clock: return "Saturday, 15 November"
        }
    }

    var detailTitle: String {
        switch self {
        case .clock: return "Clock"
        }
    }

    var detailDescription: String {
        switch self {
        case .clock: return "Track local time for yourself, friends, and even rivals all in one widget."
        }
    }

    var detailLinkTitle: String {
        switch self {
        case .clock: return ""
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

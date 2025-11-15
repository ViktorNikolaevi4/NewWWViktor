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
        case .clock: return "Виджет"
        }
    }

    var heroTitle: String {
        switch self {
        case .clock: return "Moscow"
        }
    }

    var heroSubtitle: String {
        switch self {
        case .clock: return "Суббота, 15 ноября"
        }
    }

    var detailTitle: String {
        switch self {
        case .clock: return "Часы"
        }
    }

    var detailDescription: String {
        switch self {
        case .clock: return "Узнавайте местное время или время ваших близких, друзей и даже заклятых врагов. Всё на одном виджете."
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
            // Близко к medium-виджету: 2:1, ощущается как системный
            return CGSize(width: 320, height: 160)
        }
    }
}

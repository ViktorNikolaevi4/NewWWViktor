import SwiftUI

enum WidgetType: String, Codable, CaseIterable, Identifiable {
    case clock
    // TODO: weather, systemStats, photo, music...

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
            return CGSize(width: 160, height: 160)
        }
    }
}

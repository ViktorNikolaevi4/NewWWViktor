import SwiftUI

enum WidgetType: String, Codable, CaseIterable, Identifiable {
    case clock
    case notes
    // TODO: weather, systemStats, photo, browser, music...

    var id: String { rawValue }
    var title: String {
        switch self {
        case .clock: return "Clock"
        case .notes: return "Notes"
        }
    }

    var defaultSize: CGSize {
        switch self {
        case .clock: return CGSize(width: 160, height: 160)
        case .notes: return CGSize(width: 220, height: 180)
        }
    }
}

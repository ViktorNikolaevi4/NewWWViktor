import SwiftUI

struct BatteryWidgetMetrics {
    let sizeOption: WidgetSizeOption

    var ringSize: CGFloat {
        switch sizeOption {
        case .small:
            return 102
        case .medium:
            return 108
        case .large, .extraLarge:
            return 120
        }
    }

    var ringLineWidth: CGFloat {
        switch sizeOption {
        case .small:
            return 10
        case .medium:
            return 11
        case .large, .extraLarge:
            return 12
        }
    }

    var valueFontSize: CGFloat {
        switch sizeOption {
        case .small:
            return 26
        case .medium:
            return 22
        case .large, .extraLarge:
            return 24
        }
    }

    var titleFontSize: CGFloat {
        switch sizeOption {
        case .small:
            return 11
        case .medium, .large, .extraLarge:
            return 10
        }
    }

    var chartHeightLarge: CGFloat { 110 }
    var chartHeightExtraLarge: CGFloat { 120 }
    var chartCornerRadius: CGFloat { 12 }

    var layoutSpacingLarge: CGFloat { 16 }
    var layoutSpacingExtraLarge: CGFloat { 14 }

    var paddingLarge: EdgeInsets {
        EdgeInsets(top: 12, leading: 10, bottom: 12, trailing: 10)
    }

    var paddingExtraLarge: EdgeInsets {
        EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
    }
}

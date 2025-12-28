import SwiftUI

struct PomodoroWidgetStyle {
    let isMedium: Bool

    var outerPadding: CGFloat { isMedium ? 7 : 5 }
    var ringPadding: CGFloat { isMedium ? 2 : 1 }
    var controlsBottomPadding: CGFloat { isMedium ? 2 : 1 }
    var ringLineWidth: CGFloat { isMedium ? 10 : 8 }
    var labelFontSize: CGFloat { isMedium ? 12 : 11 }
    var timeFontSize: CGFloat { isMedium ? 26 : 20 }
    var mediumTimeFontSize: CGFloat { timeFontSize * 1.625 }
    var playIconSize: CGFloat { isMedium ? 16 : 12 }
    var playIconPadding: CGFloat { isMedium ? 10 : 6 }
    var controlIconSize: CGFloat { isMedium ? 14 : 13 }
    var layoutSpacing: CGFloat { isMedium ? 8 : 5 }
    var ringSize: CGFloat { isMedium ? 110 : 92 }

    func dotSize(totalRounds: Int) -> CGFloat {
        let count = max(1, min(PomodoroCalculator.Constants.maxRounds, totalRounds))
        let maxSize: CGFloat = isMedium ? 10 : 8
        let minSize: CGFloat = isMedium ? 5 : 4
        let base: CGFloat = isMedium ? 40 : 32
        return max(minSize, min(maxSize, base / CGFloat(count)))
    }

    func dotSpacing(totalRounds: Int) -> CGFloat {
        let count = max(1, min(PomodoroCalculator.Constants.maxRounds, totalRounds))
        let maxSpacing: CGFloat = isMedium ? 8 : 6
        let minSpacing: CGFloat = isMedium ? 3 : 2
        let base: CGFloat = isMedium ? 22 : 18
        return max(minSpacing, min(maxSpacing, base / CGFloat(count)))
    }
}

import SwiftUI

struct PomodoroRoundDotsView: View {
    let totalRounds: Int
    let completedRounds: Int
    let isFocusPhase: Bool
    let primaryColor: Color
    let secondaryColor: Color
    let dotSize: CGFloat
    let dotSpacing: CGFloat

    var body: some View {
        let count = max(1, min(PomodoroCalculator.Constants.maxRounds, totalRounds))
        HStack(spacing: dotSpacing) {
            ForEach(0..<count, id: \.self) { index in
                let isFilled = index < completedRounds || (isFocusPhase && index == completedRounds)
                Circle()
                    .fill(isFilled ? primaryColor : secondaryColor.opacity(0.4))
                    .frame(width: dotSize, height: dotSize)
            }
        }
    }
}

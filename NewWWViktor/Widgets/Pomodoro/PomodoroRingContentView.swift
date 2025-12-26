import SwiftUI

struct PomodoroRingContentView<PhaseTitle: View, CenterButton: View>: View {
    let phaseTitle: PhaseTitle
    let timeText: String
    let timeFontSize: CGFloat
    let centerButton: CenterButton

    var body: some View {
        VStack(spacing: 6) {
            phaseTitle

            Text(timeText)
                .font(.system(size: timeFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            centerButton
        }
    }
}

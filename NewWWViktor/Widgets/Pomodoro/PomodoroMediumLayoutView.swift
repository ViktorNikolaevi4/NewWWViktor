import SwiftUI

struct PomodoroMediumLayoutView<Ring: View, CenterButton: View, PhaseTitle: View, Controls: View>: View {
    let ringBase: Ring
    let centerButton: CenterButton
    let phaseTitle: PhaseTitle
    let timeText: String
    let controls: Controls
    let style: PomodoroWidgetStyle
    let isRunning: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ringBase
                .overlay(centerButton)
                .frame(width: style.ringSize, height: style.ringSize)

            VStack(alignment: .leading, spacing: 6) {
                VStack(alignment: .trailing, spacing: 14) {
                    phaseTitle
                    Text(timeText)
                        .font(.system(size: style.mediumTimeFontSize, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    controls
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(style.outerPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .animation(.easeInOut(duration: 0.2), value: isRunning)
    }
}

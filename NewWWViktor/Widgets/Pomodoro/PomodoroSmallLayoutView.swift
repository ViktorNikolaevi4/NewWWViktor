import SwiftUI

struct PomodoroSmallLayoutView<Ring: View, Content: View, Controls: View>: View {
    let ringBase: Ring
    let ringContent: Content
    let controls: Controls
    let style: PomodoroWidgetStyle
    let isRunning: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: style.layoutSpacing) {
            Spacer(minLength: 0)

            ringBase
                .overlay(ringContent)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(style.ringPadding)
                .animation(.easeInOut(duration: 0.2), value: isRunning)

            controls
                .padding(.bottom, style.controlsBottomPadding)
        }
        .padding(style.outerPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }
}

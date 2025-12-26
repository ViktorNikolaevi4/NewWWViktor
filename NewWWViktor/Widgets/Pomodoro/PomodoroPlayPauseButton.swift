import SwiftUI

struct PomodoroPlayPauseButton: View {
    let isRunning: Bool
    let primaryColor: Color
    let iconSize: CGFloat
    let iconPadding: CGFloat
    let onToggle: () -> Void
    let accessibilityLabel: String

    var body: some View {
        Button {
            onToggle()
        } label: {
            Image(systemName: isRunning ? "pause.fill" : "play.fill")
                .font(.system(size: iconSize, weight: .bold))
                .foregroundStyle(Color.white)
                .padding(iconPadding)
                .background(Circle().fill(primaryColor))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

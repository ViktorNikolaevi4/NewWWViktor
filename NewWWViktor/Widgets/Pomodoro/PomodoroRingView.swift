import SwiftUI

struct PomodoroRingView: View {
    let progress: Double
    let lineWidth: CGFloat
    let primaryColor: Color
    let secondaryColor: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(secondaryColor.opacity(0.25), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(primaryColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

import SwiftUI
import Foundation

struct ClockWidgetView: View {
    @State private var date = Date()

    var body: some View {
        VStack(spacing: 8) {
            Text(date, style: .time)
                .font(.system(size: 42, weight: .semibold, design: .rounded))
                .monospacedDigit()
            Text(date, style: .date)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .onAppear(perform: startTimer)
    }

    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            date = Date()
        }
    }
}

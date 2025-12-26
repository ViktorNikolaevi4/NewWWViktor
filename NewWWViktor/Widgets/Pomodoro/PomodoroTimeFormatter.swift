import Foundation

struct PomodoroTimeFormatter {
    func string(from remainingSeconds: TimeInterval) -> String {
        let totalSeconds = max(0, Int(remainingSeconds.rounded()))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

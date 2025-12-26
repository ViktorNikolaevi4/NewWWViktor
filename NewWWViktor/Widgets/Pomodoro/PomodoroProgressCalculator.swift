import Foundation

struct PomodoroProgressCalculator {
    func progress(duration: TimeInterval, remaining: TimeInterval) -> Double {
        guard duration > 0 else { return 0 }
        let elapsed = max(0, duration - remaining)
        return min(1, elapsed / duration)
    }
}

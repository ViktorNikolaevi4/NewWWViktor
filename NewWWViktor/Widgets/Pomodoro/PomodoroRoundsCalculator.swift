import Foundation

struct PomodoroRoundsCalculator {
    func completedRounds(phase: PomodoroPhase, round: Int, totalRounds: Int) -> Int {
        if phase == .focus {
            return max(0, round - 1)
        }
        return min(totalRounds, round)
    }
}

import Foundation

struct PomodoroCalculator {
    enum Constants {
        static let secondsPerMinute: Double = 60
        static let minutesStep = 5
        static let minMinutes = 5
        static let maxMinutes = 60
        static let minRounds = 1
        static let maxRounds = 10
    }

    func nextPhase(from phase: PomodoroPhase,
                   round: Int,
                   totalRounds: Int) -> (phase: PomodoroPhase, round: Int) {
        switch phase {
        case .focus:
            if round >= totalRounds {
                return (.longBreak, round)
            }
            return (.shortBreak, round)
        case .shortBreak:
            return (.focus, min(totalRounds, round + 1))
        case .longBreak:
            return (.focus, 1)
        }
    }

    func duration(for phase: PomodoroPhase,
                  focusMinutes: Int,
                  shortBreakMinutes: Int,
                  longBreakMinutes: Int) -> TimeInterval {
        switch phase {
        case .focus:
            return TimeInterval(focusMinutes) * Constants.secondsPerMinute
        case .shortBreak:
            return TimeInterval(shortBreakMinutes) * Constants.secondsPerMinute
        case .longBreak:
            return TimeInterval(longBreakMinutes) * Constants.secondsPerMinute
        }
    }

    func clampedMinutes(_ value: Int) -> Int {
        clamp(value, min: Constants.minMinutes, max: Constants.maxMinutes)
    }

    func clampedRounds(_ value: Int) -> Int {
        clamp(value, min: Constants.minRounds, max: Constants.maxRounds)
    }

    func normalizedShortBreakMinutes(_ value: Int) -> Int {
        if value <= 1 { return 1 }
        let clamped = clampedMinutes(value)
        let remainder = clamped % Constants.minutesStep
        if remainder == 0 {
            return clamped
        }
        return clamped + (Constants.minutesStep - remainder)
    }

    private func clamp(_ value: Int, min: Int, max: Int) -> Int {
        Swift.max(min, Swift.min(max, value))
    }
}

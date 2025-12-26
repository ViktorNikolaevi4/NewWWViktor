import Foundation

struct PomodoroCoordinator {
    let calculator: PomodoroCalculator
    let notifier: PomodoroNotifier

    func advancePhase(widget: WidgetInstance,
                      now: Date,
                      totalRounds: Int,
                      focusMinutes: Int,
                      shortBreakMinutes: Int,
                      longBreakMinutes: Int) -> WidgetInstance {
        var updated = widget
        let wasRunning = updated.pomodoroIsRunning
        let next = calculator.nextPhase(from: updated.pomodoroPhase,
                                        round: updated.pomodoroRound,
                                        totalRounds: totalRounds)
        updated.pomodoroPhase = next.phase
        updated.pomodoroRound = next.round
        let duration = calculator.duration(for: next.phase,
                                           focusMinutes: focusMinutes,
                                           shortBreakMinutes: shortBreakMinutes,
                                           longBreakMinutes: longBreakMinutes)

        if wasRunning {
            updated.pomodoroEndDate = now.addingTimeInterval(duration)
            updated.pomodoroRemaining = nil
        } else {
            updated.pomodoroEndDate = nil
            updated.pomodoroRemaining = duration
        }
        return updated
    }

    func handleTick(widget: WidgetInstance,
                    at date: Date,
                    totalRounds: Int,
                    focusMinutes: Int,
                    shortBreakMinutes: Int,
                    longBreakMinutes: Int) -> PomodoroTickResult {
        guard widget.pomodoroIsRunning,
              let endDate = widget.pomodoroEndDate,
              endDate <= date else {
            return PomodoroTickResult(updated: nil, effects: {})
        }

        var updated = widget
        let phase = updated.pomodoroPhase
        let next = calculator.nextPhase(from: updated.pomodoroPhase,
                                        round: updated.pomodoroRound,
                                        totalRounds: totalRounds)
        updated.pomodoroPhase = next.phase
        updated.pomodoroRound = next.round
        let duration = calculator.duration(for: next.phase,
                                           focusMinutes: focusMinutes,
                                           shortBreakMinutes: shortBreakMinutes,
                                           longBreakMinutes: longBreakMinutes)
        let effects = {
            notifier.playPhaseEndSound(soundName: updated.pomodoroSoundName)
            notifier.sendPhaseEndNotification(for: phase,
                                              isEnabled: updated.pomodoroNotificationsEnabled)
        }
        if updated.pomodoroAutoStart {
            updated.pomodoroIsRunning = true
            updated.pomodoroEndDate = date.addingTimeInterval(duration)
            updated.pomodoroRemaining = nil
        } else {
            updated.pomodoroIsRunning = false
            updated.pomodoroEndDate = nil
            updated.pomodoroRemaining = duration
        }
        let startEffects = {
            if updated.pomodoroAutoStart {
                notifier.sendPhaseStartNotification(for: next.phase,
                                                    isEnabled: updated.pomodoroNotificationsEnabled)
            }
        }
        return PomodoroTickResult(updated: updated, effects: {
            effects()
            startEffects()
        })
    }
}

struct PomodoroTickResult {
    let updated: WidgetInstance?
    let effects: () -> Void
}

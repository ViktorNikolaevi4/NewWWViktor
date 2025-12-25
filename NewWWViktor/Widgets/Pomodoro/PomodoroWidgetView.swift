import SwiftUI
#if os(macOS)
import AppKit
#endif

struct PomodoroWidgetView: View {
    let widget: WidgetInstance

    @EnvironmentObject private var manager: WidgetManager
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Spacer(minLength: 0)

            ZStack {
                Circle()
                    .stroke(secondaryColor.opacity(0.25), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(primaryColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 6) {
                    phaseTitleView

                    Text(timeText)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Button {
                        toggleRun()
                    } label: {
                        Image(systemName: widget.pomodoroIsRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.white)
                            .padding(6)
                            .background(Circle().fill(primaryColor))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(localization.text(widget.pomodoroIsRunning ? .widgetPomodoroPause : .widgetPomodoroStart))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(2)
            .animation(.easeInOut(duration: 0.2), value: widget.pomodoroIsRunning)

            controlsRow
                .padding(.bottom, 2)
        }
        .padding(6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .onChange(of: manager.sharedDate) { _, newDate in
            handleTick(at: newDate)
        }
    }
}

private extension PomodoroWidgetView {
    var progress: Double {
        let duration = phaseDuration
        guard duration > 0 else { return 0 }
        let remaining = remainingSeconds
        let elapsed = max(0, duration - remaining)
        return min(1, elapsed / duration)
    }

    var controlsRow: some View {
        HStack(spacing: 6) {
            Button {
                restartPhase()
            } label: {
                Image(systemName: "arrow.trianglehead.clockwise")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(secondaryColor)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(localization.text(.widgetPomodoroRestart))

            Spacer()

            HStack(spacing: dotSpacing) {
                let count = max(1, min(10, totalRounds))
                ForEach(0..<count, id: \.self) { index in
                    let completed = completedRounds
                    let isFilled = index < completed || (widget.pomodoroPhase == .focus && index == completed)
                    Circle()
                        .fill(isFilled ? primaryColor : secondaryColor.opacity(0.4))
                        .frame(width: dotSize, height: dotSize)
                }
            }

            Spacer()

            Button {
                advancePhase()
            } label: {
                Image(systemName: "playpause.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(secondaryColor)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(localization.text(.widgetPomodoroNext))
        }
    }

    var phaseLabel: String {
        switch widget.pomodoroPhase {
        case .focus:
            return localization.text(.widgetPomodoroFocusLabel)
        case .shortBreak:
            return localization.text(.widgetPomodoroShortBreakLabel)
        case .longBreak:
            return localization.text(.widgetPomodoroLongBreakLabel)
        }
    }

    @ViewBuilder
    var phaseTitleView: some View {
        if widget.pomodoroPhase == .shortBreak || widget.pomodoroPhase == .longBreak {
            let parts = phaseLabel.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
            let first = parts.first.map(String.init) ?? phaseLabel
            let second = parts.dropFirst().joined(separator: " ")
            VStack(spacing: 2) {
                Text(first)
                if !second.isEmpty {
                    Text(second)
                }
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(secondaryColor)
            .multilineTextAlignment(.center)
        } else {
            Text(phaseLabel)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(secondaryColor)
        }
    }

    var phaseDuration: TimeInterval {
        switch widget.pomodoroPhase {
        case .focus:
            return TimeInterval(focusMinutes * 60)
        case .shortBreak:
            return TimeInterval(shortBreakMinutes * 60)
        case .longBreak:
            return TimeInterval(longBreakMinutes * 60)
        }
    }

    var remainingSeconds: TimeInterval {
        if widget.pomodoroIsRunning, let endDate = widget.pomodoroEndDate {
            return max(0, endDate.timeIntervalSince(manager.sharedDate))
        }
        if let remaining = widget.pomodoroRemaining {
            return remaining
        }
        return phaseDuration
    }

    var timeText: String {
        let totalSeconds = max(0, Int(remainingSeconds.rounded()))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var completedRounds: Int {
        if widget.pomodoroPhase == .focus {
            return max(0, widget.pomodoroRound - 1)
        }
        return min(totalRounds, widget.pomodoroRound)
    }

    func toggleRun() {
        var updated = widget
        let now = manager.sharedDate

        if updated.pomodoroIsRunning {
            let remaining = max(0, (updated.pomodoroEndDate ?? now).timeIntervalSince(now))
            updated.pomodoroIsRunning = false
            updated.pomodoroEndDate = nil
            updated.pomodoroRemaining = remaining
        } else {
            let duration = updated.pomodoroRemaining ?? phaseDuration
            updated.pomodoroIsRunning = true
            updated.pomodoroEndDate = now.addingTimeInterval(duration)
            updated.pomodoroRemaining = nil
        }

        manager.update(updated)
    }

    func restartPhase() {
        var updated = widget
        let now = manager.sharedDate
        let duration = phaseDuration
        updated.pomodoroIsRunning = true
        updated.pomodoroEndDate = now.addingTimeInterval(duration)
        updated.pomodoroRemaining = nil
        manager.update(updated)
    }

    func advancePhase() {
        var updated = widget
        let now = manager.sharedDate
        let wasRunning = updated.pomodoroIsRunning
        let next = nextPhase(from: updated.pomodoroPhase,
                             round: updated.pomodoroRound,
                             totalRounds: totalRounds)
        updated.pomodoroPhase = next.phase
        updated.pomodoroRound = next.round
        let duration = durationForPhase(next.phase)

        if wasRunning {
            updated.pomodoroEndDate = now.addingTimeInterval(duration)
            updated.pomodoroRemaining = nil
        } else {
            updated.pomodoroEndDate = nil
            updated.pomodoroRemaining = duration
        }

        manager.update(updated)
    }

    func handleTick(at date: Date) {
        guard widget.pomodoroIsRunning,
              let endDate = widget.pomodoroEndDate,
              endDate <= date else { return }

        var updated = widget
        playPhaseEndSound()
        let next = nextPhase(from: updated.pomodoroPhase,
                             round: updated.pomodoroRound,
                             totalRounds: totalRounds)
        updated.pomodoroPhase = next.phase
        updated.pomodoroRound = next.round
        let duration = durationForPhase(next.phase)
        if updated.pomodoroAutoStart {
            updated.pomodoroIsRunning = true
            updated.pomodoroEndDate = date.addingTimeInterval(duration)
            updated.pomodoroRemaining = nil
        } else {
            updated.pomodoroIsRunning = false
            updated.pomodoroEndDate = nil
            updated.pomodoroRemaining = duration
        }
        manager.update(updated)
    }

    func nextPhase(from phase: PomodoroPhase, round: Int, totalRounds: Int) -> (phase: PomodoroPhase, round: Int) {
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

    func durationForPhase(_ phase: PomodoroPhase) -> TimeInterval {
        switch phase {
        case .focus:
            return TimeInterval(focusMinutes * 60)
        case .shortBreak:
            return TimeInterval(shortBreakMinutes * 60)
        case .longBreak:
            return TimeInterval(longBreakMinutes * 60)
        }
    }

    var focusMinutes: Int {
        clamp(widget.pomodoroFocusMinutes, min: 5, max: 60)
    }

    var shortBreakMinutes: Int {
        normalizeShortBreakMinutes(widget.pomodoroShortBreakMinutes)
    }

    var longBreakMinutes: Int {
        clamp(widget.pomodoroLongBreakMinutes, min: 5, max: 60)
    }

    var totalRounds: Int {
        clamp(widget.pomodoroTotalRounds, min: 1, max: 10)
    }

    func clamp(_ value: Int, min: Int, max: Int) -> Int {
        Swift.max(min, Swift.min(max, value))
    }

    func normalizeShortBreakMinutes(_ value: Int) -> Int {
        if value <= 1 { return 1 }
        let clamped = clamp(value, min: 5, max: 60)
        let remainder = clamped % 5
        if remainder == 0 {
            return clamped
        }
        return clamped + (5 - remainder)
    }

    var primaryColor: Color {
        let name = widget.mainColorName ?? manager.globalPrimaryColorName
        let intensity = widget.mainColorName == nil ? manager.globalPrimaryIntensity : widget.mainColorIntensity
        _ = manager.globalColorsVersion
        return WidgetPaletteColor.color(named: name,
                                        intensity: intensity,
                                        fallback: Color(red: 1.0, green: 0.84, blue: 0.25))
    }

    func playPhaseEndSound() {
#if os(macOS)
        let name = widget.pomodoroSoundName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        NSSound(named: NSSound.Name(name))?.play()
#endif
    }

    var dotSize: CGFloat {
        let count = max(1, min(10, totalRounds))
        return max(4, min(8, 32.0 / CGFloat(count)))
    }

    var dotSpacing: CGFloat {
        let count = max(1, min(10, totalRounds))
        return max(2, min(6, 18.0 / CGFloat(count)))
    }

    var secondaryColor: Color {
        let name = widget.secondaryColorName ?? manager.globalSecondaryColorName
        let intensity = widget.secondaryColorName == nil ? manager.globalSecondaryIntensity : widget.secondaryColorIntensity
        _ = manager.globalColorsVersion
        return WidgetPaletteColor.color(named: name,
                                        intensity: intensity,
                                        fallback: .secondary)
    }
}

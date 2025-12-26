import SwiftUI

struct PomodoroWidgetView: View {
    let widget: WidgetInstance

    @EnvironmentObject private var manager: WidgetManager
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        Group {
            if isMedium {
                mediumLayout
            } else {
                smallLayout
            }
        }
        .onChange(of: manager.sharedDate) { _, newDate in
            handleTick(at: newDate)
        }
    }
}

private extension PomodoroWidgetView {
    // MARK: - Layout
    var smallLayout: some View {
        PomodoroSmallLayoutView(
            ringBase: ringBase,
            ringContent: smallRingContent,
            controls: controlsRow,
            style: style,
            isRunning: widget.pomodoroIsRunning
        )
    }

    var mediumLayout: some View {
        PomodoroMediumLayoutView(
            ringBase: ringBase,
            centerButton: centerPlayButton,
            phaseTitle: PomodoroPhaseTitleView(text: phaseLabel,
                                               isBreak: isBreakPhase,
                                               alignment: .trailing,
                                               spacing: 3,
                                               fontSize: style.labelFontSize * 2,
                                               color: secondaryColor),
            timeText: timeText,
            controls: controlsRow,
            style: style,
            isRunning: widget.pomodoroIsRunning
        )
    }

    var ringBase: some View {
        PomodoroRingView(
            progress: progress,
            lineWidth: style.ringLineWidth,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor
        )
    }

    var smallRingContent: some View {
        PomodoroRingContentView(
            phaseTitle: PomodoroPhaseTitleView(text: phaseLabel,
                                               isBreak: isBreakPhase,
                                               alignment: .center,
                                               spacing: 2,
                                               fontSize: style.labelFontSize,
                                               color: secondaryColor),
            timeText: timeText,
            timeFontSize: style.timeFontSize,
            centerButton: centerPlayButton
        )
    }

    var centerPlayButton: some View {
        PomodoroPlayPauseButton(
            isRunning: widget.pomodoroIsRunning,
            primaryColor: primaryColor,
            iconSize: style.playIconSize,
            iconPadding: style.playIconPadding,
            onToggle: toggleRun,
            accessibilityLabel: localization.text(widget.pomodoroIsRunning ? .widgetPomodoroPause : .widgetPomodoroStart)
        )
    }

    // MARK: - Progress
    var progress: Double {
        progressCalculator.progress(duration: phaseDuration, remaining: remainingSeconds)
    }

    var controlsRow: some View {
        HStack(spacing: 6) {
            Button {
                restartPhase()
            } label: {
                Image(systemName: "arrow.trianglehead.clockwise")
                    .font(.system(size: style.controlIconSize, weight: .bold))
                    .foregroundStyle(secondaryColor)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(localization.text(.widgetPomodoroRestart))

            Spacer()

            PomodoroRoundDotsView(
                totalRounds: totalRounds,
                completedRounds: completedRounds,
                isFocusPhase: widget.pomodoroPhase == .focus,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                dotSize: style.dotSize(totalRounds: totalRounds),
                dotSpacing: style.dotSpacing(totalRounds: totalRounds)
            )

            Spacer()

            Button {
                advancePhase()
            } label: {
                Image(systemName: "playpause.fill")
                    .font(.system(size: style.controlIconSize - 1, weight: .bold))
                    .foregroundStyle(secondaryColor)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(localization.text(.widgetPomodoroNext))
        }
    }

    // MARK: - Labels
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

    var isBreakPhase: Bool {
        widget.pomodoroPhase == .shortBreak || widget.pomodoroPhase == .longBreak
    }

    // MARK: - Timing
    var phaseDuration: TimeInterval {
        coordinator.calculator.duration(for: widget.pomodoroPhase,
                                        focusMinutes: focusMinutes,
                                        shortBreakMinutes: shortBreakMinutes,
                                        longBreakMinutes: longBreakMinutes)
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
        timeFormatter.string(from: remainingSeconds)
    }

    var completedRounds: Int {
        roundsCalculator.completedRounds(phase: widget.pomodoroPhase,
                                         round: widget.pomodoroRound,
                                         totalRounds: totalRounds)
    }

    // MARK: - Actions
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

        updateWidget(updated)
    }

    func restartPhase() {
        var updated = widget
        let now = manager.sharedDate
        let duration = phaseDuration
        updated.pomodoroIsRunning = true
        updated.pomodoroEndDate = now.addingTimeInterval(duration)
        updated.pomodoroRemaining = nil
        updateWidget(updated)
    }

    func advancePhase() {
        var updated = widget
        let now = manager.sharedDate
        let transition = coordinator.advancePhase(
            widget: updated,
            now: now,
            totalRounds: totalRounds,
            focusMinutes: focusMinutes,
            shortBreakMinutes: shortBreakMinutes,
            longBreakMinutes: longBreakMinutes
        )
        updated = transition

        updateWidget(updated)
    }

    func handleTick(at date: Date) {
        guard widget.pomodoroIsRunning,
              let endDate = widget.pomodoroEndDate,
              endDate <= date else { return }

        let transition = coordinator.handleTick(
            widget: widget,
            at: date,
            totalRounds: totalRounds,
            focusMinutes: focusMinutes,
            shortBreakMinutes: shortBreakMinutes,
            longBreakMinutes: longBreakMinutes
        )
        guard var updated = transition.updated else { return }
        transition.effects()
        updateWidget(updated)
    }

    // MARK: - Config
    var focusMinutes: Int {
        coordinator.calculator.clampedMinutes(widget.pomodoroFocusMinutes)
    }

    var shortBreakMinutes: Int {
        coordinator.calculator.normalizedShortBreakMinutes(widget.pomodoroShortBreakMinutes)
    }

    var longBreakMinutes: Int {
        coordinator.calculator.clampedMinutes(widget.pomodoroLongBreakMinutes)
    }

    var totalRounds: Int {
        coordinator.calculator.clampedRounds(widget.pomodoroTotalRounds)
    }

    func updateWidget(_ updated: WidgetInstance) {
        manager.update(updated)
    }

    // MARK: - Colors
    var primaryColor: Color {
        colors.primaryColor
    }

    // MARK: - Sizing
    var isMedium: Bool {
        widget.sizeOption == .medium
    }

    var secondaryColor: Color {
        colors.secondaryColor
    }

    // MARK: - Helpers
    var style: PomodoroWidgetStyle {
        PomodoroWidgetStyle(isMedium: isMedium)
    }

    var colors: PomodoroWidgetColors {
        PomodoroWidgetColors(widget: widget, manager: manager)
    }

    var coordinator: PomodoroCoordinator {
        PomodoroCoordinator(calculator: PomodoroCalculator(),
                            notifier: PomodoroNotifier(localization: localization))
    }

    var timeFormatter: PomodoroTimeFormatter {
        PomodoroTimeFormatter()
    }

    var progressCalculator: PomodoroProgressCalculator {
        PomodoroProgressCalculator()
    }

    var roundsCalculator: PomodoroRoundsCalculator {
        PomodoroRoundsCalculator()
    }
}

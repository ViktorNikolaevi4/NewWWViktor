import SwiftUI
#if os(macOS)
import AppKit
import UserNotifications
#endif

struct PomodoroNotifier {
    let localization: LocalizationManager

    func playPhaseEndSound(soundName: String) {
#if os(macOS)
        let name = soundName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        NSSound(named: NSSound.Name(name))?.play()
#endif
    }

    func sendPhaseEndNotification(for phase: PomodoroPhase, isEnabled: Bool) {
#if os(macOS)
        guard isEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = localization.text(.widgetPomodoroDetailTitle)
        switch phase {
        case .focus:
            content.body = localization.text(.widgetPomodoroNotificationFocusComplete)
        case .shortBreak, .longBreak:
            content.body = localization.text(.widgetPomodoroNotificationBreakComplete)
        }
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: nil)
        UNUserNotificationCenter.current().add(request)
#endif
    }

    func sendPhaseStartNotification(for phase: PomodoroPhase, isEnabled: Bool) {
#if os(macOS)
        guard isEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = localization.text(.widgetPomodoroDetailTitle)
        switch phase {
        case .focus:
            content.body = localization.text(.widgetPomodoroNotificationFocusStart)
        case .shortBreak, .longBreak:
            content.body = localization.text(.widgetPomodoroNotificationBreakStart)
        }
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: nil)
        UNUserNotificationCenter.current().add(request)
#endif
    }
}

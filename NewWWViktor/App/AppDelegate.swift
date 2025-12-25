import AppKit
import UserNotifications

final class MiniWWAppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var widgetManager: WidgetManager?
    private var panelController: SidePanelWindowController?

    func configure(manager: WidgetManager, panelController: SidePanelWindowController) {
        self.widgetManager = manager
        self.panelController = panelController
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Panel now opens manually via the menu bar icon.
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        panelController?.showPanel()
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }
}

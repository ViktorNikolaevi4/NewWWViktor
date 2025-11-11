import AppKit

final class MiniWWAppDelegate: NSObject, NSApplicationDelegate {
    private var widgetManager: WidgetManager?
    private var panelController: SidePanelWindowController?

    func configure(manager: WidgetManager, panelController: SidePanelWindowController) {
        self.widgetManager = manager
        self.panelController = panelController
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Панель теперь открывается вручную через иконку MenuBarExtra.
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        panelController?.showPanel()
        return true
    }
}

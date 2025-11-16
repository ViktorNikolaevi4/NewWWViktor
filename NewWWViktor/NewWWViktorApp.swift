
import SwiftUI
import AppKit

@main
struct MiniWWApp: App {
    private let manager: WidgetManager
    private let settingsCoordinator: SettingsCoordinator
    private let panelController: SidePanelWindowController
    @NSApplicationDelegateAdaptor(MiniWWAppDelegate.self) private var appDelegate

    init() {
        let manager = WidgetManager()
        self.manager = manager
        let settingsCoordinator = SettingsCoordinator()
        self.settingsCoordinator = settingsCoordinator
        let controller = SidePanelWindowController(manager: manager,
                                                   settingsCoordinator: settingsCoordinator)
        self.panelController = controller
        manager.panelController = controller
        manager.settingsCoordinator = settingsCoordinator
        appDelegate.configure(manager: manager, panelController: controller)
    }

    var body: some Scene {
        MenuBarExtra("miniWW", systemImage: "square.grid.3x3") {
            PanelMenuTriggerView {
                panelController.togglePanel()
            }
        }
        .menuBarExtraStyle(.window)

        Settings {
            VStack(alignment: .leading, spacing: 8) {
                Text("miniWW is controlled from the floating side panel.")
                Text("Use the menu bar icon to toggle it.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(width: 300)
        }
    }
}

private struct PanelMenuTriggerView: View {
    let toggle: () -> Void

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onAppear {
                DispatchQueue.main.async {
                    toggle()
                    NSApplication.shared.sendAction(#selector(NSMenu.cancelTracking), to: nil, from: nil)
                }
            }
    }
}

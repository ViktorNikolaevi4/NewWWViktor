
import SwiftUI
import AppKit

@main
struct MiniWWApp: App {
    @StateObject private var appIconController: AppIconController
    @StateObject private var localizationManager: LocalizationManager
    private let manager: WidgetManager
    private let settingsCoordinator: SettingsCoordinator
    private let panelController: SidePanelWindowController
    private let statusItemController: StatusItemController
    @NSApplicationDelegateAdaptor(MiniWWAppDelegate.self) private var appDelegate

    init() {
        let localizationManager = LocalizationManager()
        _localizationManager = StateObject(wrappedValue: localizationManager)

        let manager = WidgetManager(localizationManager: localizationManager)
        self.manager = manager
        let settingsCoordinator = SettingsCoordinator()
        self.settingsCoordinator = settingsCoordinator
        let iconController = AppIconController()
        _appIconController = StateObject(wrappedValue: iconController)
        let controller = SidePanelWindowController(manager: manager,
                                                   settingsCoordinator: settingsCoordinator,
                                                   localizationManager: localizationManager)
        self.panelController = controller
        manager.panelController = controller
        manager.settingsCoordinator = settingsCoordinator
        settingsCoordinator.appIconController = iconController
        settingsCoordinator.localizationManager = localizationManager
        settingsCoordinator.widgetManager = manager
        self.statusItemController = StatusItemController(panelController: controller,
                                                         appIconController: iconController)
        appDelegate.configure(manager: manager, panelController: controller)
    }

    var body: some Scene {
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
        .environmentObject(localizationManager)
        .environmentObject(appIconController)
    }
}

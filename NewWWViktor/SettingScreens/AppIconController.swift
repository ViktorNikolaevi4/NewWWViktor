import AppKit
import Combine

/// Controls visibility of Dock and menu bar icons to match the selected mode.
final class AppIconController: ObservableObject {
    @Published private(set) var mode: AppIconMode {
        didSet {
            persistMode()
            applyActivationPolicy()
        }
    }

    var showsMenuBarIcon: Bool {
        mode != .dockOnly
    }

    var showsDockIcon: Bool {
        mode != .menuOnly
    }

    private static let defaultsKey = "miniww.appIconMode"

    init() {
        let saved = UserDefaults.standard.integer(forKey: Self.defaultsKey)
        self.mode = AppIconMode(rawValue: saved) ?? .menuAndDock
        // Apply after init so NSApp is configured.
        DispatchQueue.main.async { [weak self] in
            self?.applyActivationPolicy()
        }
    }

    func updateMode(_ newMode: AppIconMode) {
        guard newMode != mode else { return }
        mode = newMode
    }

    // MARK: - Helpers

    private func persistMode() {
        UserDefaults.standard.set(mode.rawValue, forKey: Self.defaultsKey)
    }

    private func applyActivationPolicy() {
        DispatchQueue.main.async {
            let policy: NSApplication.ActivationPolicy = self.showsDockIcon ? .regular : .accessory
            if NSApplication.shared.activationPolicy() != policy {
                NSApplication.shared.setActivationPolicy(policy)
            }
        }
    }
}

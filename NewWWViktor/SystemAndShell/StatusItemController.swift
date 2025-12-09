import AppKit
import Combine

/// Manages the menu bar icon visibility depending on the selected AppIconMode.
final class StatusItemController {
    private weak var panelController: SidePanelWindowController?
    private var statusItem: NSStatusItem?
    private var modeCancellable: AnyCancellable?

    init(panelController: SidePanelWindowController,
         appIconController: AppIconController) {
        self.panelController = panelController

        modeCancellable = appIconController.$mode
            .receive(on: RunLoop.main)
            .sink { [weak self] mode in
                guard let self else { return }
                if mode == .dockOnly {
                    self.removeStatusItem()
                } else {
                    self.ensureStatusItem()
                }
            }

        if appIconController.showsMenuBarIcon {
            ensureStatusItem()
        }
    }

    deinit {
        modeCancellable?.cancel()
    }

    private func ensureStatusItem() {
        guard statusItem == nil else { return }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "square.grid.3x3",
                                   accessibilityDescription: "MyWidgets")
            button.action = #selector(togglePanel)
            button.target = self
        }
        statusItem = item
    }

    private func removeStatusItem() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }

    @objc private func togglePanel() {
        panelController?.togglePanel()
    }
}

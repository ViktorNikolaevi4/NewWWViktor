import AppKit
import SwiftUI
import Combine

final class WidgetManager: ObservableObject {
    @Published var widgets: [WidgetInstance] = [] {
        didSet { persist() }
    }
    @Published var isPanelFullscreen: Bool = false
    weak var panelController: SidePanelWindowController?
    weak var settingsCoordinator: SettingsCoordinator?

    private var windows: [UUID: NSWindow] = [:]
    private var windowCloseObservers: [UUID: NSObjectProtocol] = [:]

    init() {
        load()
        widgets.forEach { attachWindow(for: $0) }
    }

    deinit {
        windowCloseObservers.values.forEach(NotificationCenter.default.removeObserver)
    }

    func addWidget(type: WidgetType, size: WidgetSizeOption = .medium) {
        var instance = WidgetInstance(type: type)
        instance.applySizeOption(size)
        // Можно раскидывать по сетке/стеку
        widgets.append(instance)
        attachWindow(for: instance)
    }

    func removeWidget(id: UUID) {
        widgets.removeAll { $0.id == id }
        if let window = windows[id] {
            window.close()
        } else if let observer = windowCloseObservers[id] {
            NotificationCenter.default.removeObserver(observer)
            windowCloseObservers[id] = nil
        }
    }

    func removeAllWidgets() {
        widgets.forEach { instance in
            if let window = windows[instance.id] {
                window.close()
            } else if let observer = windowCloseObservers[instance.id] {
                NotificationCenter.default.removeObserver(observer)
                windowCloseObservers[instance.id] = nil
            }
        }
        widgets.removeAll()
    }

    func window(for id: UUID) -> NSWindow? {
        windows[id]
    }

    func update(_ instance: WidgetInstance) {
        guard let idx = widgets.firstIndex(where: { $0.id == instance.id }) else { return }

        var updatedInstance = instance
        if let window = windows[instance.id] {
            let frame = window.frame
            updatedInstance.x = frame.origin.x
            updatedInstance.y = frame.origin.y
        }

        widgets[idx] = updatedInstance

        if let window = windows[instance.id] {
            let newFrame = NSRect(x: updatedInstance.x,
                                  y: updatedInstance.y,
                                  width: updatedInstance.width,
                                  height: updatedInstance.height)
            let shouldAnimate = window.frame.size != newFrame.size
            window.setFrame(newFrame,
                            display: true,
                            animate: shouldAnimate)
            // Use .normal when not pinned. If you want behind-all-windows, consider .desktopIcon.
            window.level = updatedInstance.isPinned ? .floating : .normal
            window.isMovableByWindowBackground = !updatedInstance.isPositionLocked
        }
    }

    // MARK: - Windows

    private func attachWindow(for instance: WidgetInstance) {
        let content = WidgetHostView(instanceID: instance.id)
            .environmentObject(self)

        let window = NSWindow(
            contentRect: NSRect(x: instance.x,
                                y: instance.y,
                                width: instance.width,
                                height: instance.height),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        // Use .normal when not pinned. If you want behind-all-windows, consider .desktopIcon.
        window.level = instance.isPinned ? .floating : .normal
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.animationBehavior = .none
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = !instance.isPositionLocked
        window.contentView = NSHostingView(rootView: content)
        window.orderFrontRegardless()

        windows[instance.id] = window

        let observer = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            if let existing = self.windowCloseObservers[instance.id] {
                NotificationCenter.default.removeObserver(existing)
                self.windowCloseObservers[instance.id] = nil
            }
            self.windows[instance.id] = nil
        }
        windowCloseObservers[instance.id] = observer
    }

    // MARK: - Persistence (ультра-просто)

    private let storageKey = "miniww.widgets"

    private func persist() {
        guard let data = try? JSONEncoder().encode(widgets) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let saved = try? JSONDecoder().decode([WidgetInstance].self, from: data)
        else { return }
        self.widgets = saved
    }

    // MARK: - Side panel helpers

    func togglePanelFullscreen() {
        isPanelFullscreen.toggle()
    }

    func showSidePanel() {
        panelController?.showPanel()
    }

    func showGeneralSettings() {
        settingsCoordinator?.show(.general)
    }
}

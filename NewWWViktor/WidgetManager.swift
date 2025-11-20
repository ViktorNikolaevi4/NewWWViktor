import AppKit
import SwiftUI
import Combine

private extension NSWindow.Level {
    // Keep widgets above desktop icons (so clicks aren’t captured by Finder) but below normal windows.
    static let desktopAboveIcons = NSWindow.Level(Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
}

// Panel that doesn’t activate the app when interacting, so Show Desktop не отменяется от кликов/перетаскиваний.
private final class WidgetPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

final class WidgetManager: ObservableObject {
    @Published var widgets: [WidgetInstance] = [] {
        didSet { persist() }
    }
    @Published var isPanelFullscreen: Bool = false
    @Published var areWidgetsHidden: Bool {
        didSet {
            UserDefaults.standard.set(areWidgetsHidden, forKey: hideWidgetsKey)
            updateWidgetVisibility()
        }
    }
    weak var panelController: SidePanelWindowController?
    weak var settingsCoordinator: SettingsCoordinator?
    weak var localizationManager: LocalizationManager?

    private var windows: [UUID: NSWindow] = [:]
    private var windowCloseObservers: [UUID: NSObjectProtocol] = [:]
    private let hideWidgetsKey = "miniww.widgets.hidden"

    init(localizationManager: LocalizationManager? = nil) {
        let hidden = UserDefaults.standard.object(forKey: hideWidgetsKey) as? Bool ?? false
        _areWidgetsHidden = Published(initialValue: hidden)
        self.localizationManager = localizationManager
        load()
        widgets.forEach { attachWindow(for: $0) }
    }

    deinit {
        windowCloseObservers.values.forEach(NotificationCenter.default.removeObserver)
    }

    func addWidget(type: WidgetType, size: WidgetSizeOption = .medium) {
        var instance = WidgetInstance(type: type)
        instance.applySizeOption(size)
        // Could be distributed via grid/stack layouts later
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
            // Keep pinned widgets above windows, and unpinned ones in the desktop layer so they survive "Show Desktop".
            window.level = updatedInstance.isPinned ? .floating : .desktopAboveIcons
            window.isMovableByWindowBackground = !updatedInstance.isPositionLocked
        }
    }

    // MARK: - Windows

    private func attachWindow(for instance: WidgetInstance) {
        let baseView = WidgetHostView(instanceID: instance.id)
            .environmentObject(self)

        let content: AnyView
        if let localizationManager {
            content = AnyView(baseView.environmentObject(localizationManager))
        } else {
            content = AnyView(baseView)
        }

        let window = WidgetPanel(
            contentRect: NSRect(x: instance.x,
                                y: instance.y,
                                width: instance.width,
                                height: instance.height),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.isFloatingPanel = false
        window.hidesOnDeactivate = false
        window.becomesKeyOnlyIfNeeded = true
        window.isOpaque = false
        window.backgroundColor = .clear
        // Keep pinned widgets above windows, and unpinned ones in the desktop layer so they survive "Show Desktop".
        window.level = instance.isPinned ? .floating : .desktopAboveIcons
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.animationBehavior = .none
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        window.isMovableByWindowBackground = !instance.isPositionLocked
        window.contentView = NSHostingView(rootView: content)
        window.orderFrontRegardless()
        applyVisibility(to: window)

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

    // MARK: - Persistence (very simple)

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

    private func updateWidgetVisibility() {
        windows.values.forEach { applyVisibility(to: $0) }
    }

    private func applyVisibility(to window: NSWindow) {
        window.ignoresMouseEvents = areWidgetsHidden
        if areWidgetsHidden {
            window.orderOut(nil)
        } else {
            window.orderFrontRegardless()
        }
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

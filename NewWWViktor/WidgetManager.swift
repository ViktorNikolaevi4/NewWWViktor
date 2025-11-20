import AppKit
import SwiftUI
import Combine

private extension NSWindow.Level {
    // Keep widgets above desktop icons (so clicks aren’t captured by Finder) but below normal windows.
    static let desktopAboveIcons = NSWindow.Level(Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
}

enum WidgetGridMode: Int, Codable {
    case macOS = 0
    case widgetWall = 1

    var spacing: CGFloat {
        switch self {
        case .macOS: return 24 // немного больше воздуха между виджетами
        case .widgetWall: return 16
        }
    }
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
    @Published var snapToGrid: Bool {
        didSet {
            UserDefaults.standard.set(snapToGrid, forKey: snapToGridKey)
        }
    }
    @Published var gridMode: WidgetGridMode {
        didSet {
            UserDefaults.standard.set(gridMode.rawValue, forKey: gridModeKey)
        }
    }
    weak var panelController: SidePanelWindowController?
    weak var settingsCoordinator: SettingsCoordinator?
    weak var localizationManager: LocalizationManager?

    private var windows: [UUID: NSWindow] = [:]
    private var windowCloseObservers: [UUID: NSObjectProtocol] = [:]
    private var mouseUpMonitor: Any?
    private let hideWidgetsKey = "miniww.widgets.hidden"
    private let snapToGridKey = "miniww.widgets.snap"
    private let gridModeKey = "miniww.widgets.gridmode"
    private let safeInset: CGFloat = 4 // чуть ближе к краям, но не вылезая за visibleFrame

    init(localizationManager: LocalizationManager? = nil) {
        let hidden = UserDefaults.standard.object(forKey: hideWidgetsKey) as? Bool ?? false
        let snapStored = UserDefaults.standard.object(forKey: snapToGridKey) as? Bool ?? true
        let gridStoredRaw = UserDefaults.standard.object(forKey: gridModeKey) as? Int
        let gridStored = WidgetGridMode(rawValue: gridStoredRaw ?? 0) ?? .macOS
        _areWidgetsHidden = Published(initialValue: hidden)
        _snapToGrid = Published(initialValue: snapStored)
        _gridMode = Published(initialValue: gridStored)
        self.localizationManager = localizationManager
        load()
        widgets.forEach { attachWindow(for: $0) }

        mouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] _ in
            self?.snapAllWidgetsToGrid()
        }
    }

    deinit {
        windowCloseObservers.values.forEach(NotificationCenter.default.removeObserver)
        if let monitor = mouseUpMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    func addWidget(type: WidgetType, size: WidgetSizeOption = .medium) {
        var instance = WidgetInstance(type: type)
        instance.applySizeOption(size)
        // Place near the grid with the first free slot.
        let origin = nextGridOrigin(for: instance)
        instance.x = origin.x
        instance.y = origin.y
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

    private func snapAllWidgetsToGrid() {
        guard snapToGrid else { return }

        for (id, window) in windows {
            guard let idx = widgets.firstIndex(where: { $0.id == id }) else { continue }
            var instance = widgets[idx]
            guard !instance.isPositionLocked else { continue }

            let frame = window.frame
            let snappedOrigin = snap(origin: frame.origin, spacing: gridMode.spacing)
            let clampedOrigin = clamp(origin: snappedOrigin, size: frame.size, screen: window.screen)
            if clampedOrigin != frame.origin {
                let newFrame = NSRect(origin: clampedOrigin, size: frame.size)
                window.setFrame(newFrame, display: true, animate: false)
                instance.x = clampedOrigin.x
                instance.y = clampedOrigin.y
                widgets[idx] = instance
            }
        }
    }

    private func snap(origin: CGPoint, spacing: CGFloat) -> CGPoint {
        let snapValue: (CGFloat) -> CGFloat = { value in
            let remainder = value.truncatingRemainder(dividingBy: spacing)
            let half = spacing / 2
            if remainder >= half {
                return value - remainder + spacing
            } else {
                return value - remainder
            }
        }
        return CGPoint(x: snapValue(origin.x), y: snapValue(origin.y))
    }

    private func clamp(origin: CGPoint, size: CGSize, screen: NSScreen?) -> CGPoint {
        let visible = screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? NSRect(origin: .zero, size: size)
        let insetFrame = visible.insetBy(dx: safeInset, dy: safeInset)
        let minX = insetFrame.minX
        let minY = insetFrame.minY
        let maxX = insetFrame.maxX - size.width
        let maxY = insetFrame.maxY - size.height
        let clampedX = max(minX, min(origin.x, maxX))
        let clampedY = max(minY, min(origin.y, maxY))
        return CGPoint(x: clampedX, y: clampedY)
    }

    // Find the first free spot in a grid-like scan, starting from top-left of visible screen.
    private func nextGridOrigin(for instance: WidgetInstance) -> CGPoint {
        let spacing = gridMode.spacing
        let size = CGSize(width: instance.width, height: instance.height)
        guard let screenFrame = NSScreen.main?.visibleFrame else {
            return CGPoint(x: safeInset, y: safeInset)
        }

        let startX = screenFrame.minX + safeInset
        let startY = screenFrame.maxY - size.height - safeInset
        let maxX = screenFrame.maxX - size.width - safeInset
        let minY = screenFrame.minY + safeInset

        let stepX = size.width + spacing
        let stepY = size.height + spacing

        let existingFrames = widgets.map {
            NSRect(x: $0.x, y: $0.y, width: $0.width, height: $0.height)
        }

        var y = startY
        while y >= minY {
            var x = startX
            while x <= maxX {
                let candidate = NSRect(x: x, y: y, width: size.width, height: size.height)
                if !existingFrames.contains(where: { $0.intersects(candidate) }) {
                    return CGPoint(x: x, y: y)
                }
                x += stepX
            }
            y -= stepY
        }

        // Fallback: clamp at start.
        return clamp(origin: CGPoint(x: startX, y: startY), size: size, screen: NSScreen.main)
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

import AppKit
import SwiftUI
import Combine

private extension NSWindow.Level {
    // Максимум в пределах desktop-слоя: выше иконок/других desktop-виджетов, но всё ещё ниже обычных окон приложений.
    static let desktopWidgetTop = NSWindow.Level(Int(CGWindowLevelForKey(.desktopIconWindow)) + 200)
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
    @Published private(set) var globalGradientColor1Name: String?
    @Published private(set) var globalGradientColor2Name: String?
    @Published private(set) var globalGradientColor1Opacity: Double = 1.0
    @Published private(set) var globalGradientColor2Opacity: Double = 1.0
    @Published private(set) var globalGradientColor1Position: Double = 0.0
    @Published private(set) var globalGradientColor2Position: Double = 1.0
    @Published private(set) var globalGradientType: BackgroundGradientType = .linear
    @Published private(set) var globalGradientAngle: Double = 0.0
    @Published private(set) var globalBackgroundStyle: BackgroundStyle = .photo
    @Published private(set) var globalBackgroundColorName: String?
    @Published private(set) var globalBackgroundIntensity: Double = 1.0
    #if os(macOS)
    @Published private(set) var globalBackgroundImage: NSImage?
    #endif
    @Published private(set) var globalColorsVersion: Int = 0
    weak var panelController: SidePanelWindowController?
    weak var settingsCoordinator: SettingsCoordinator?
    weak var localizationManager: LocalizationManager?
    @Published private(set) var globalBackgroundHidden: Bool = false

    private var windows: [UUID: NSWindow] = [:]
    private var windowCloseObservers: [UUID: NSObjectProtocol] = [:]
    private var mouseUpMonitor: Any?
    private var appearanceObserver: NSObjectProtocol?
    private let hideWidgetsKey = "miniww.widgets.hidden"
    private let snapToGridKey = "miniww.widgets.snap"
    private let gridModeKey = "miniww.widgets.gridmode"
    private let safeInset: CGFloat = 4 // чуть ближе к краям, но не вылезая за visibleFrame
    // Global appearance keys (shared with AppearanceSettingsDetailView)
    private let primaryColorKey = "appearance.primaryColorName"
    private let primaryIntensityKey = "appearance.primaryIntensity"
    private let secondaryColorKey = "appearance.secondaryColorName"
    private let secondaryIntensityKey = "appearance.secondaryIntensity"
    private let backgroundStyleKey = "appearance.backgroundStyle"
    private let backgroundColorKey = "appearance.backgroundColorName"
    private let backgroundIntensityKey = "appearance.backgroundColorIntensity"
    private let gradientColor1Key = "appearance.gradient.color1"
    private let gradientColor2Key = "appearance.gradient.color2"
    private let gradientColor1OpacityKey = "appearance.gradient.color1.opacity"
    private let gradientColor2OpacityKey = "appearance.gradient.color2.opacity"
    private let gradientColor1PositionKey = "appearance.gradient.color1.position"
    private let gradientColor2PositionKey = "appearance.gradient.color2.position"
    private let gradientTypeKey = "appearance.gradient.type"
    private let gradientAngleKey = "appearance.gradient.angle"
    private let backgroundHideKey = "appearance.background.hide"
    private let backgroundImageBookmarkKey = "appearance.backgroundImageBookmark"
    private let backgroundImagePathKey = "appearance.backgroundImagePath"
    private let backupsDirectoryName = "NewWWViktorBackups"
    private(set) var globalPrimaryColorName: String?
    private(set) var globalPrimaryIntensity: Double = 1.0
    private(set) var globalSecondaryColorName: String?
    private(set) var globalSecondaryIntensity: Double = 1.0
    @Published var sharedDate: Date = Date()
    @Published var locationProvider: LocationProvider = LocationProvider()
    private var appearanceObservers: [NSObjectProtocol] = []
    private var timerCancellable: AnyCancellable?

    init(localizationManager: LocalizationManager? = nil) {
        let hidden = UserDefaults.standard.object(forKey: hideWidgetsKey) as? Bool ?? false
        let snapStored = UserDefaults.standard.object(forKey: snapToGridKey) as? Bool ?? true
        let gridStoredRaw = UserDefaults.standard.object(forKey: gridModeKey) as? Int
        let gridStored = WidgetGridMode(rawValue: gridStoredRaw ?? 0) ?? .macOS
        _areWidgetsHidden = Published(initialValue: hidden)
        _snapToGrid = Published(initialValue: snapStored)
        _gridMode = Published(initialValue: gridStored)
        self.localizationManager = localizationManager
        loadGlobalColors()
        loadGlobalBackground()
        load()
        widgets.forEach { attachWindow(for: $0) }

        mouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] _ in
            self?.snapAllWidgetsToGrid()
        }

        installAppearanceObservers()
        startSharedTimer()

        let resetObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name("widgets.reset.appearance"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.resetAllWidgetAppearances()
        }
        appearanceObservers.append(resetObserver)
    }

    deinit {
        windowCloseObservers.values.forEach(NotificationCenter.default.removeObserver)
        if let monitor = mouseUpMonitor {
            NSEvent.removeMonitor(monitor)
        }
        appearanceObservers.forEach(NotificationCenter.default.removeObserver)
        if let cancellable = timerCancellable {
            cancellable.cancel()
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

    private func loadGlobalColors() {
        let defaults = UserDefaults.standard
        globalPrimaryColorName = defaults.string(forKey: primaryColorKey)
        globalSecondaryColorName = defaults.string(forKey: secondaryColorKey)
        globalPrimaryIntensity = defaults.object(forKey: primaryIntensityKey) as? Double ?? 1.0
        globalSecondaryIntensity = defaults.object(forKey: secondaryIntensityKey) as? Double ?? 1.0
        globalColorsVersion &+= 1
        #if os(macOS)
        refreshWidgetWindows()
        #endif
    }

    private func loadGlobalBackground() {
        let defaults = UserDefaults.standard
        let storedStyle = defaults.string(forKey: backgroundStyleKey) ?? BackgroundStyle.photo.rawValue
        globalBackgroundStyle = BackgroundStyle(rawValue: storedStyle) ?? .photo
        globalBackgroundColorName = defaults.string(forKey: backgroundColorKey)
        globalBackgroundIntensity = defaults.object(forKey: backgroundIntensityKey) as? Double ?? 1.0
        globalBackgroundHidden = defaults.object(forKey: backgroundHideKey) as? Bool ?? false
        globalGradientColor1Name = defaults.string(forKey: gradientColor1Key)
        globalGradientColor2Name = defaults.string(forKey: gradientColor2Key)
        globalGradientColor1Opacity = defaults.object(forKey: gradientColor1OpacityKey) as? Double ?? 1.0
        globalGradientColor2Opacity = defaults.object(forKey: gradientColor2OpacityKey) as? Double ?? 1.0
        globalGradientColor1Position = defaults.object(forKey: gradientColor1PositionKey) as? Double ?? 0.0
        globalGradientColor2Position = defaults.object(forKey: gradientColor2PositionKey) as? Double ?? 1.0
        if let storedType = defaults.string(forKey: gradientTypeKey),
           let type = BackgroundGradientType(rawValue: storedType) {
            globalGradientType = type
        }
        globalGradientAngle = defaults.object(forKey: gradientAngleKey) as? Double ?? 0.0
        #if os(macOS)
        loadGlobalBackgroundImage()
        refreshWidgetWindows()
        #endif
        globalColorsVersion &+= 1
    }

    #if os(macOS)
    private func loadGlobalBackgroundImage() {
        let defaults = UserDefaults.standard
        if let storedPath = defaults.string(forKey: backgroundImagePathKey) {
            let url = URL(fileURLWithPath: storedPath)
            if let data = try? Data(contentsOf: url) {
                globalBackgroundImage = NSImage(data: data)
                return
            }
        }

        guard let data = defaults.data(forKey: backgroundImageBookmarkKey) else {
            globalBackgroundImage = nil
            return
        }

        var stale = false
        if let url = try? URL(resolvingBookmarkData: data,
                              options: [.withSecurityScope],
                              relativeTo: nil,
                              bookmarkDataIsStale: &stale) {
            let accessed = url.startAccessingSecurityScopedResource()
            if let imageData = try? Data(contentsOf: url) {
                globalBackgroundImage = NSImage(data: imageData)
            } else {
                globalBackgroundImage = nil
            }
            if stale, let refreshed = try? url.bookmarkData(options: .withSecurityScope,
                                                            includingResourceValuesForKeys: nil,
                                                            relativeTo: nil) {
                defaults.set(refreshed, forKey: backgroundImageBookmarkKey)
            }
            if accessed {
                url.stopAccessingSecurityScopedResource()
            }
        } else {
            globalBackgroundImage = nil
        }
    }

    private func refreshWidgetWindows() {
        DispatchQueue.main.async {
            for window in self.windows.values {
                if let view = window.contentView {
                    view.needsDisplay = true
                    view.layoutSubtreeIfNeeded()
                }
                window.displayIfNeeded()
            }
        }
    }
    #endif

    private func installAppearanceObservers() {
        let colorObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name("appearance.colors.changed"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadGlobalColors()
        }

        let backgroundObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name("appearance.background.changed"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadGlobalBackground()
        }

        appearanceObservers = [colorObserver, backgroundObserver]
    }

    private func startSharedTimer() {
        let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        timerCancellable = timer.sink { [weak self] output in
            self?.sharedDate = output
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

    func resetAllWidgetAppearances() {
        widgets = widgets.map { widget in
            var w = widget
            w.mainColorName = nil
            w.mainColorIntensity = 1.0
            w.secondaryColorName = nil
            w.secondaryColorIntensity = 1.0
            w.backgroundStyle = nil
            w.backgroundColorName = nil
            w.backgroundIntensity = 1.0
            w.backgroundImagePath = nil
            w.gradientColor1Name = nil
            w.gradientColor2Name = nil
            w.gradientColor1Opacity = 1.0
            w.gradientColor2Opacity = 1.0
            w.gradientColor1Position = 0.0
            w.gradientColor2Position = 1.0
            w.gradientType = nil
            w.gradientAngle = nil
            return w
        }
        refreshWidgetWindows()
    }

    // MARK: - Backups (export/import)

    struct AppearanceSnapshot: Codable {
        var primaryColorName: String?
        var primaryIntensity: Double
        var secondaryColorName: String?
        var secondaryIntensity: Double
        var backgroundStyle: String?
        var backgroundColorName: String?
        var backgroundIntensity: Double
        var backgroundImageData: Data?
        var gradientColor1Name: String?
        var gradientColor2Name: String?
        var gradientColor1Opacity: Double
        var gradientColor2Opacity: Double
        var gradientColor1Position: Double
        var gradientColor2Position: Double
        var gradientType: String?
        var gradientAngle: Double
    }

    struct BackupSnapshot: Codable {
        var widgets: [WidgetInstance]
        var appearance: AppearanceSnapshot
        var createdAt: Date
    }

    func exportSnapshot() -> BackupSnapshot {
        let defaults = UserDefaults.standard
        let appearance = AppearanceSnapshot(
            primaryColorName: defaults.string(forKey: primaryColorKey),
            primaryIntensity: defaults.object(forKey: primaryIntensityKey) as? Double ?? 1.0,
            secondaryColorName: defaults.string(forKey: secondaryColorKey),
            secondaryIntensity: defaults.object(forKey: secondaryIntensityKey) as? Double ?? 1.0,
            backgroundStyle: defaults.string(forKey: backgroundStyleKey),
            backgroundColorName: defaults.string(forKey: backgroundColorKey),
            backgroundIntensity: defaults.object(forKey: backgroundIntensityKey) as? Double ?? 1.0,
            backgroundImageData: loadBackgroundImageData(),
            gradientColor1Name: defaults.string(forKey: gradientColor1Key),
            gradientColor2Name: defaults.string(forKey: gradientColor2Key),
            gradientColor1Opacity: defaults.object(forKey: gradientColor1OpacityKey) as? Double ?? 1.0,
            gradientColor2Opacity: defaults.object(forKey: gradientColor2OpacityKey) as? Double ?? 1.0,
            gradientColor1Position: defaults.object(forKey: gradientColor1PositionKey) as? Double ?? 0.0,
            gradientColor2Position: defaults.object(forKey: gradientColor2PositionKey) as? Double ?? 1.0,
            gradientType: defaults.string(forKey: gradientTypeKey),
            gradientAngle: defaults.object(forKey: gradientAngleKey) as? Double ?? 0.0
        )
        return BackupSnapshot(widgets: widgets, appearance: appearance, createdAt: Date())
    }

    func applySnapshot(_ snapshot: BackupSnapshot) {
        windows.values.forEach { $0.close() }
        windows.removeAll()
        windowCloseObservers.removeAll()

        widgets = snapshot.widgets
        widgets.forEach { attachWindow(for: $0) }
        persist()

        let defaults = UserDefaults.standard
        defaults.set(snapshot.appearance.primaryColorName, forKey: primaryColorKey)
        defaults.set(snapshot.appearance.primaryIntensity, forKey: primaryIntensityKey)
        defaults.set(snapshot.appearance.secondaryColorName, forKey: secondaryColorKey)
        defaults.set(snapshot.appearance.secondaryIntensity, forKey: secondaryIntensityKey)
        if let style = snapshot.appearance.backgroundStyle {
            defaults.set(style, forKey: backgroundStyleKey)
        }
        defaults.set(snapshot.appearance.backgroundColorName, forKey: backgroundColorKey)
        defaults.set(snapshot.appearance.backgroundIntensity, forKey: backgroundIntensityKey)
        defaults.set(snapshot.appearance.gradientColor1Name, forKey: gradientColor1Key)
        defaults.set(snapshot.appearance.gradientColor2Name, forKey: gradientColor2Key)
        defaults.set(snapshot.appearance.gradientColor1Opacity, forKey: gradientColor1OpacityKey)
        defaults.set(snapshot.appearance.gradientColor2Opacity, forKey: gradientColor2OpacityKey)
        defaults.set(snapshot.appearance.gradientColor1Position, forKey: gradientColor1PositionKey)
        defaults.set(snapshot.appearance.gradientColor2Position, forKey: gradientColor2PositionKey)
        if let type = snapshot.appearance.gradientType {
            defaults.set(type, forKey: gradientTypeKey)
        }
        defaults.set(snapshot.appearance.gradientAngle, forKey: gradientAngleKey)

        if let imageData = snapshot.appearance.backgroundImageData {
            saveRestoredBackgroundImage(data: imageData)
        }

        NotificationCenter.default.post(name: Notification.Name("appearance.colors.changed"), object: nil)
        NotificationCenter.default.post(name: Notification.Name("appearance.background.changed"), object: nil)
        refreshWidgetWindows()
    }

    private func loadBackgroundImageData() -> Data? {
        let defaults = UserDefaults.standard
        if let path = defaults.string(forKey: backgroundImagePathKey) {
            let url = URL(fileURLWithPath: path)
            return try? Data(contentsOf: url)
        }
        return nil
    }

    private func saveRestoredBackgroundImage(data: Data) {
        let dir = backupsDirectory()
        let filename = "restored-background-\(UUID().uuidString).png"
        let url = dir.appendingPathComponent(filename)
        do {
            try data.write(to: url)
            UserDefaults.standard.set(url.path, forKey: backgroundImagePathKey)
        } catch {
            print("Failed to write restored background image: \(error)")
        }
    }

    func backupsDirectory() -> URL {
        let fm = FileManager.default
        let base = try? fm.url(for: .applicationSupportDirectory,
                               in: .userDomainMask,
                               appropriateFor: nil,
                               create: true)
        let dir = base?.appendingPathComponent(backupsDirectoryName, isDirectory: true)
        if let dir = dir, !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir ?? URL(fileURLWithPath: NSTemporaryDirectory())
    }

    func window(for id: UUID) -> NSWindow? {
        windows[id]
    }

    func update(_ instance: WidgetInstance) {
        // Отложенный апдейт, чтобы не трогать @Published-поля прямо во время рендера SwiftUI (иначе warning "Publishing changes from within view updates").
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let idx = self.widgets.firstIndex(where: { $0.id == instance.id }) else { return }

            var updatedInstance = instance
            if let window = self.windows[instance.id] {
                let frame = window.frame
                updatedInstance.x = frame.origin.x
                updatedInstance.y = frame.origin.y
            }

            self.widgets[idx] = updatedInstance

            if let window = self.windows[instance.id] {
                let newFrame = NSRect(x: updatedInstance.x,
                                      y: updatedInstance.y,
                                      width: updatedInstance.width,
                                      height: updatedInstance.height)
                let shouldAnimate = window.frame.size != newFrame.size
                window.setFrame(newFrame,
                                display: true,
                                animate: shouldAnimate)
                // Закрепленные — над окнами, незакрепленные — в верхнем слое рабочего стола (statusBar), чтобы переживали «Показать рабочий стол» и перебивали чужие виджеты.
                window.level = updatedInstance.isPinned ? .floating : .desktopWidgetTop
                window.isMovableByWindowBackground = !updatedInstance.isPositionLocked
            }
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
        // Закрепленные — над окнами, незакрепленные — в верхнем слое рабочего стола (statusBar), чтобы переживали «Показать рабочий стол» и перебивали чужие виджеты.
        window.level = instance.isPinned ? .floating : .desktopWidgetTop
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.animationBehavior = .none
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        window.isMovableByWindowBackground = !instance.isPositionLocked
        window.contentView = NSHostingView(rootView: content)
        window.contentView?.wantsLayer = true  // Уже true для NSHostingView, но на всякий случай
        window.contentView?.layerContentsRedrawPolicy = .onSetNeedsDisplay
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

    func setGlobalBackgroundHidden(_ hidden: Bool) {
        globalBackgroundHidden = hidden
        UserDefaults.standard.set(hidden, forKey: backgroundHideKey)
        refreshWidgetWindows()
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

    func hideSidePanel() {
        panelController?.hidePanel()
    }

    func showGeneralSettings() {
        settingsCoordinator?.show(.general)
    }
}

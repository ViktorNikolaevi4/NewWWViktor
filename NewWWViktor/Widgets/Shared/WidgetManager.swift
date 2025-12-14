import AppKit
import SwiftUI
import Combine
import CoreLocation
import WeatherKit

struct WeatherSnapshot: Equatable {
    let city: String
    let temperatureCelsius: Int?
    let conditionDescription: String?
    let highCelsius: Int?
    let lowCelsius: Int?
    let symbolName: String?
    let lastUpdated: Date?

    static let placeholder = WeatherSnapshot(city: "Сочи",
                                             temperatureCelsius: nil,
                                             conditionDescription: nil,
                                             highCelsius: nil,
                                             lowCelsius: nil,
                                             symbolName: "cloud.sun.fill",
                                             lastUpdated: nil)
}

private extension Measurement where UnitType == UnitTemperature {
    var roundedCelsiusInt: Int {
        Int(converted(to: .celsius).value.rounded())
    }
}

private extension NSWindow.Level {
    // Максимум в пределах desktop-слоя: выше иконок/других desktop-виджетов, но всё ещё ниже обычных окон приложений.
    static let desktopWidgetTop = NSWindow.Level(Int(CGWindowLevelForKey(.desktopIconWindow)) + 200)
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
    @Published private(set) var weatherSnapshot: WeatherSnapshot = .placeholder

    private var windows: [UUID: NSWindow] = [:]
    private var windowCloseObservers: [UUID: NSObjectProtocol] = [:]
    private var appearanceObserver: NSObjectProtocol?
    private let hideWidgetsKey = "miniww.widgets.hidden"
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
    private var weatherTimerCancellable: AnyCancellable?
    private let defaultWeatherLocation = CLLocation(latitude: 43.5855, longitude: 39.7231)

    init(localizationManager: LocalizationManager? = nil) {
        let hidden = UserDefaults.standard.object(forKey: hideWidgetsKey) as? Bool ?? false
        _areWidgetsHidden = Published(initialValue: hidden)
        self.localizationManager = localizationManager
        loadGlobalColors()
        loadGlobalBackground()
        load()
        widgets.forEach { attachWindow(for: $0) }

        installAppearanceObservers()
        startSharedTimer()
        startWeatherUpdates()

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
        appearanceObservers.forEach(NotificationCenter.default.removeObserver)
        if let cancellable = timerCancellable {
            cancellable.cancel()
        }
        weatherTimerCancellable?.cancel()
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
        let colors = AppearanceStorage.loadColors()
        globalPrimaryColorName = colors.primaryName
        globalSecondaryColorName = colors.secondaryName
        globalPrimaryIntensity = colors.primaryIntensity
        globalSecondaryIntensity = colors.secondaryIntensity
        globalColorsVersion &+= 1
        #if os(macOS)
        refreshWidgetWindows()
        #endif
    }

    private func loadGlobalBackground() {
        let background = AppearanceStorage.loadBackground()
        globalBackgroundStyle = background.style
        globalBackgroundColorName = background.colorName
        globalBackgroundIntensity = background.intensity
        globalBackgroundHidden = background.hideBackground
        globalGradientColor1Name = background.gradientColor1Name
        globalGradientColor2Name = background.gradientColor2Name
        globalGradientColor1Opacity = background.gradientColor1Opacity
        globalGradientColor2Opacity = background.gradientColor2Opacity
        globalGradientColor1Position = background.gradientColor1Position
        globalGradientColor2Position = background.gradientColor2Position
        globalGradientType = background.gradientType
        globalGradientAngle = background.gradientAngle
        #if os(macOS)
        loadGlobalBackgroundImage()
        refreshWidgetWindows()
        #endif
        globalColorsVersion &+= 1
    }

    #if os(macOS)
    private func loadGlobalBackgroundImage() {
        guard let url = AppearanceStorage.loadBackgroundImageURL() else {
            globalBackgroundImage = nil
            return
        }
        if let data = try? Data(contentsOf: url) {
            globalBackgroundImage = NSImage(data: data)
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
            forName: AppearanceStorage.colorDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadGlobalColors()
        }

        let backgroundObserver = NotificationCenter.default.addObserver(
            forName: AppearanceStorage.backgroundDidChange,
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

    private func startWeatherUpdates() {
        refreshWeather()
        weatherTimerCancellable = Timer.publish(every: 3600, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshWeather()
            }
    }

    func refreshWeather() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            await fetchWeather()
        }
    }

    @MainActor
    private func fetchWeather() async {
        do {
            let report = try await WeatherService.shared.weather(for: defaultWeatherLocation)
            weatherSnapshot = WeatherSnapshot(
                city: "Сочи",
                temperatureCelsius: report.currentWeather.temperature.roundedCelsiusInt,
                conditionDescription: report.currentWeather.condition.description,
                highCelsius: report.dailyForecast.forecast.first?.highTemperature.roundedCelsiusInt,
                lowCelsius: report.dailyForecast.forecast.first?.lowTemperature.roundedCelsiusInt,
                symbolName: report.currentWeather.symbolName,
                lastUpdated: Date()
            )
        } catch {
            let stale = weatherSnapshot
            weatherSnapshot = WeatherSnapshot(
                city: stale.city,
                temperatureCelsius: stale.temperatureCelsius,
                conditionDescription: stale.conditionDescription,
                highCelsius: stale.highCelsius,
                lowCelsius: stale.lowCelsius,
                symbolName: stale.symbolName ?? "cloud.fill",
                lastUpdated: Date()
            )
        }
    }

    // Find the first free spot in a simple flowing layout, starting from top-left of visible screen.
    private func nextGridOrigin(for instance: WidgetInstance) -> CGPoint {
        let spacing: CGFloat = 16
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
        let clampedX = max(startX, min(screenFrame.maxX - size.width - safeInset, startX))
        let clampedY = max(minY, min(startY, screenFrame.maxY - size.height - safeInset))
        return CGPoint(x: clampedX, y: clampedY)
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

        NotificationCenter.default.post(name: AppearanceStorage.colorDidChange, object: nil)
        NotificationCenter.default.post(name: AppearanceStorage.backgroundDidChange, object: nil)
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

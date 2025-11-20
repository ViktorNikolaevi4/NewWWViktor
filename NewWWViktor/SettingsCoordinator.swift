import SwiftUI
import AppKit
import Combine

enum SettingsCategory: CaseIterable, Identifiable {
    case general
    case appearance
    case plan
    case backups
    case screens
    case support
    case about

    var id: String { String(describing: self) }

    var systemImage: String {
        switch self {
        case .general: return "gearshape"
        case .appearance: return "paintbrush"
        case .plan: return "calendar"
        case .backups: return "externaldrive"
        case .screens: return "macwindow"
        case .support: return "lifepreserver"
        case .about: return "info.circle"
        }
    }

    var titleKey: LocalizationKey {
        switch self {
        case .general: return .categoryGeneral
        case .appearance: return .categoryAppearance
        case .plan: return .categoryPlan
        case .backups: return .categoryBackups
        case .screens: return .categoryScreens
        case .support: return .categorySupport
        case .about: return .categoryAbout
        }
    }
}

final class SettingsCoordinator: ObservableObject {
    @Published var selectedCategory: SettingsCategory = .general

    private var window: NSWindow?
    private var hasPositionedWindow = false
    var appIconController: AppIconController?
    var localizationManager: LocalizationManager?
    var widgetManager: WidgetManager?

    func show(_ category: SettingsCategory) {
        selectedCategory = category
        if window == nil {
            createWindow()
        }
        guard let window else { return }

        if !window.isVisible {
            applyInitialWindowPositionIfNeeded(for: window)
        }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func createWindow() {
        guard let iconController = appIconController else {
            assertionFailure("AppIconController must be provided before showing settings.")
            return
        }

        guard let localizationManager = localizationManager else {
            assertionFailure("LocalizationManager must be provided before showing settings.")
            return
        }
        guard let widgetManager = widgetManager else {
            assertionFailure("WidgetManager must be provided before showing settings.")
            return
        }

        let content = SettingsWindowContent()
            .environmentObject(self)
            .environmentObject(iconController)
            .environmentObject(localizationManager)
            .environmentObject(widgetManager)

        let hosting = NSHostingController(rootView: content)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 540),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.contentViewController = hosting
        self.window = window
    }

    // Position the settings window near the lower-left edge only on the first presentation.
    private func applyInitialWindowPositionIfNeeded(for window: NSWindow) {
        guard !hasPositionedWindow else { return }
        guard let screen = window.screen ?? NSScreen.main ?? NSScreen.screens.first else { return }

        let padding: CGFloat = 72
        var frame = window.frame
        frame.origin = NSPoint(x: screen.visibleFrame.minX + padding,
                               y: screen.visibleFrame.minY + padding)
        window.setFrame(frame, display: false)
        hasPositionedWindow = true
    }
}

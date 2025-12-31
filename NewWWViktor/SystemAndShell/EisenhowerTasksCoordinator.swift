import SwiftUI
import AppKit
import SwiftData

final class EisenhowerTasksCoordinator {
    private let modelContainer: ModelContainer
    private let localizationManager: LocalizationManager
    private var window: NSWindow?
    private var hasPositionedWindow = false

    init(modelContainer: ModelContainer, localizationManager: LocalizationManager) {
        self.modelContainer = modelContainer
        self.localizationManager = localizationManager
    }

    func show() {
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
        let content = EisenhowerTasksPanelView()
            .environmentObject(localizationManager)
            .modelContainer(modelContainer)

        let hosting = NSHostingController(rootView: content)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 520),
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

    private func applyInitialWindowPositionIfNeeded(for window: NSWindow) {
        guard !hasPositionedWindow else { return }
        guard let screen = window.screen ?? NSScreen.main ?? NSScreen.screens.first else { return }
        let padding: CGFloat = 80
        var frame = window.frame
        frame.origin = NSPoint(x: screen.visibleFrame.minX + padding,
                               y: screen.visibleFrame.minY + padding)
        window.setFrame(frame, display: false)
        hasPositionedWindow = true
    }
}

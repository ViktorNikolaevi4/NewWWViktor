import SwiftUI
import AppKit
import SwiftData

final class EisenhowerTasksCoordinator {
    private let modelContainer: ModelContainer
    private let localizationManager: LocalizationManager
    private var window: NSPanel?
    private var lastAnchorWidgetID: UUID?

    init(modelContainer: ModelContainer, localizationManager: LocalizationManager) {
        self.modelContainer = modelContainer
        self.localizationManager = localizationManager
    }

    func show(near widgetWindow: NSWindow?, widget: WidgetInstance?) {
        if window == nil {
            createWindow()
        }
        guard let window else { return }
        applyPosition(for: window, widgetWindow: widgetWindow, widget: widget)
        window.orderFrontRegardless()
    }

    private func createWindow() {
        let content = EisenhowerTasksPanelView()
            .environmentObject(localizationManager)
            .modelContainer(modelContainer)

        let hosting = NSHostingController(rootView: content)

        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 520),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.becomesKeyOnlyIfNeeded = true
        window.hidesOnDeactivate = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle, .stationary]
        window.isMovableByWindowBackground = true
        window.contentViewController = hosting
        self.window = window
    }

    private func applyPosition(for window: NSWindow,
                               widgetWindow: NSWindow?,
                               widget: WidgetInstance?) {
        let padding: CGFloat = 20
        let panelSize = window.frame.size

        if let widget, lastAnchorWidgetID != widget.id || !window.isVisible {
            lastAnchorWidgetID = widget.id
            let origin = panelOrigin(widgetWindow: widgetWindow,
                                     widget: widget,
                                     panelSize: panelSize,
                                     spacing: padding)
            let frame = NSRect(origin: origin, size: panelSize)
            window.setFrame(frame, display: false)
        } else if !window.isVisible {
            let screen = window.screen ?? NSScreen.main ?? NSScreen.screens.first
            let screenFrame = screen?.visibleFrame ?? .zero
            let origin = CGPoint(x: screenFrame.minX + 80, y: screenFrame.minY + 80)
            let frame = NSRect(origin: origin, size: panelSize)
            window.setFrame(frame, display: false)
        }
    }

    private func panelOrigin(widgetWindow: NSWindow?,
                             widget: WidgetInstance,
                             panelSize: CGSize,
                             spacing: CGFloat) -> CGPoint {
        if let window = widgetWindow {
            let frame = window.frame
            let screenFrame = window.screen?.visibleFrame ?? frame
            let rightSpace = screenFrame.maxX - frame.maxX
            let minY = screenFrame.minY + spacing
            let maxY = screenFrame.maxY - panelSize.height - spacing
            var y = frame.midY - panelSize.height / 2
            y = min(max(y, minY), maxY)
            if rightSpace >= panelSize.width + spacing {
                return CGPoint(x: frame.maxX + spacing, y: y)
            } else {
                return CGPoint(x: frame.minX - panelSize.width - spacing, y: y)
            }
        }

        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let minY = screenFrame.minY + spacing
        let maxY = screenFrame.maxY - panelSize.height - spacing
        var y = widget.y + (widget.height - panelSize.height) / 2
        y = min(max(y, minY), maxY)
        return CGPoint(x: widget.x + widget.width + spacing, y: y)
    }
}

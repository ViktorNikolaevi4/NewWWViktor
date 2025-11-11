import AppKit
import SwiftUI
import QuartzCore

final class SidePanelWindowController {
    private var window: NSPanel?
    private let manager: WidgetManager
    private let panelSize = NSSize(width: 320, height: 360)
    private var screenChangeObserver: Any?

    init(manager: WidgetManager) {
        self.manager = manager
        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let window = self?.window else { return }
            self?.positionWindow(window)
        }
    }

    deinit {
        if let observer = screenChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func showPanel() {
        if window == nil {
            createPanel()
        }
        guard
            let window,
            let screen = NSScreen.main
        else { return }

        let startFrame = frame(for: screen, showing: false)
        let targetFrame = frame(for: screen, showing: true)

        if !window.isVisible {
            window.setFrame(startFrame, display: false)
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(targetFrame, display: true)
        }
    }

    func hidePanel() {
        guard
            let window,
            window.isVisible,
            let screen = NSScreen.main
        else {
            window?.orderOut(nil)
            return
        }

        let targetFrame = frame(for: screen, showing: false)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(targetFrame, display: false)
        } completionHandler: {
            window.orderOut(nil)
        }
    }

    func togglePanel() {
        if window?.isVisible == true {
            hidePanel()
        } else {
            showPanel()
        }
    }

    var isPanelVisible: Bool {
        window?.isVisible ?? false
    }

    private func createPanel() {
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: panelSize),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hidesOnDeactivate = false

        let hostingView = NSHostingView(
            rootView: SidePanelView().environmentObject(manager)
        )
        hostingView.frame = NSRect(origin: .zero, size: panelSize)
        panel.contentView = hostingView

        window = panel
    }

    private func positionWindow(_ window: NSWindow) {
        guard let screen = NSScreen.main else { return }
        let frame = frame(for: screen, showing: window.isVisible)
        window.setFrame(frame, display: true, animate: false)
    }

    private func frame(for screen: NSScreen, showing: Bool) -> NSRect {
        let visible = screen.visibleFrame
        let y = visible.minY + (visible.height - panelSize.height) / 2
        let x: CGFloat

        if showing {
            x = visible.maxX - panelSize.width - 12
        } else {
            x = visible.maxX + 20
        }

        return NSRect(x: x, y: y, width: panelSize.width, height: panelSize.height)
    }
}

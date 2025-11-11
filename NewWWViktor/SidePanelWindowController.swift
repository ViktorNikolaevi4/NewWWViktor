import AppKit
import SwiftUI
import QuartzCore

final class SidePanelWindowController {
    private var window: NSPanel?
    private let manager: WidgetManager

    // Ширина, близкая к системной панели (можешь подправить под вкус)
    private let panelWidth: CGFloat = 360

    private var screenChangeObserver: Any?

    init(manager: WidgetManager) {
        self.manager = manager

        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self, let window = self.window else { return }
            self.positionWindow(window)
        }
    }

    deinit {
        if let observer = screenChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Public API

    func togglePanel() {
        if window?.isVisible == true {
            hidePanel()
        } else {
            showPanel()
        }
    }

    func showPanel() {
        if window == nil {
            createPanel()
        }

        guard let window, let screen = NSScreen.main else { return }

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
        guard let window, window.isVisible, let screen = NSScreen.main else {
            window?.orderOut(nil)
            return
        }

        let targetFrame = frame(for: screen, showing: false)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.20
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(targetFrame, display: false)
        } completionHandler: {
            window.orderOut(nil)
        }
    }

    var isPanelVisible: Bool {
        window?.isVisible ?? false
    }

    // MARK: - Private

    private func createPanel() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }

        let initialFrame = frame(for: screen, showing: false)

        let panel = NSPanel(
            contentRect: initialFrame,
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = false      // фиксируем у правого края
        panel.isReleasedWhenClosed = false
        panel.hasShadow = true

        // Поверх обычных окон, как системная панель
        panel.level = .statusBar

        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary
        ]

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hidesOnDeactivate = false

        let hostingView = NSHostingView(
            rootView: SidePanelView()
                .environmentObject(manager)
        )
        hostingView.frame = NSRect(origin: .zero, size: initialFrame.size)
        panel.contentView = hostingView

        self.window = panel
    }

    private func positionWindow(_ window: NSWindow) {
        guard let screen = NSScreen.main else { return }
        let frame = frame(for: screen, showing: window.isVisible)
        window.setFrame(frame, display: true, animate: false)
        if let hosting = window.contentView as? NSHostingView<SidePanelView> {
            hosting.frame = NSRect(origin: .zero, size: frame.size)
        }
    }

    private func frame(for screen: NSScreen, showing: Bool) -> NSRect {
        let frame = screen.frame               // вместо visibleFrame
        let width = panelWidth
        let height = frame.height              // на всю высоту экрана
        let y = frame.minY

        let shownX = frame.maxX - width
        let hiddenX = frame.maxX + 20

        let x = showing ? shownX : hiddenX

        return NSRect(x: x, y: y, width: width, height: height)
    }

}

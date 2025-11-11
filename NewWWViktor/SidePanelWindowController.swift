import AppKit
import SwiftUI
import QuartzCore
import Combine

final class SidePanelWindowController {
    private var window: NSPanel?
    private let manager: WidgetManager
    private var cancellables = Set<AnyCancellable>()

    // Ширина, близкая к системной панели (можешь подправить под вкус)
    private let panelWidth: CGFloat = 360
    private let edgeInset: CGFloat = 16

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

        manager.$isPanelFullscreen
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updatePanelFrame(animated: true)
            }
            .store(in: &cancellables)
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
        updateHostingFrame(for: targetFrame)
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
        updateHostingFrame(for: frame)
    }

    private func frame(for screen: NSScreen, showing: Bool) -> NSRect {
        let visibleFrame = screen.visibleFrame
        let insetFrame = visibleFrame.insetBy(dx: edgeInset, dy: edgeInset)
        let isFullScreen = manager.isPanelFullscreen
        let availableWidth = max(insetFrame.width, 0)
        let width = isFullScreen ? availableWidth : min(panelWidth, availableWidth)
        let height = max(insetFrame.height, 0)
        let y = insetFrame.minY

        let shownX = isFullScreen ? insetFrame.minX : visibleFrame.maxX - width - edgeInset
        let hiddenX = visibleFrame.maxX + 20

        let x = showing ? shownX : hiddenX

        return NSRect(x: x, y: y, width: width, height: height)
    }

    private func updatePanelFrame(animated: Bool) {
        guard let window = window, let screen = NSScreen.main else { return }
        let targetFrame = frame(for: screen, showing: window.isVisible)

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.25
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                window.animator().setFrame(targetFrame, display: true)
            }
        } else {
            window.setFrame(targetFrame, display: true, animate: false)
        }

        updateHostingFrame(for: targetFrame)
    }

    private func updateHostingFrame(for frame: NSRect) {
        if let hosting = window?.contentView as? NSHostingView<SidePanelView> {
            hosting.frame = NSRect(origin: .zero, size: frame.size)
        }
    }

}

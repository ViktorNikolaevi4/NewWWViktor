import SwiftUI
import Combine
#if os(macOS)
import AppKit
import QuartzCore
#endif

struct WidgetHostView: View {
    @EnvironmentObject var manager: WidgetManager
    @EnvironmentObject var localization: LocalizationManager
    let instanceID: UUID
    @State private var isMenuVisible = false
    @State private var showSettingsPanel = false
#if os(macOS)
    @State private var settingsPanel: NSPanel?
    @State private var settingsPanelWidgetID: UUID?
    @State private var settingsPanelMonitors: [Any] = []
    @StateObject private var settingsPanelCoordinator = WidgetSettingsPanelCoordinator()
#endif

    var body: some View {
        if let instance = manager.widgets.first(where: { $0.id == instanceID }) {
            VStack(spacing: 0) {
                HStack(alignment: .bottom) {
                    Spacer()
#if os(macOS)
                    Button {
                        togglePanel(for: instance)
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 24, weight: .bold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .opacity(isMenuVisible ? 1 : 0)
                            .scaleEffect(isMenuVisible ? 1 : 0.6)
                    }
                    .buttonStyle(.plain)
                    .opacity(isMenuVisible ? 1 : 0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isMenuVisible)
#else
                    Button {
                        showSettingsPanel.toggle()
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 24, weight: .bold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .opacity(isMenuVisible ? 1 : 0)
                            .scaleEffect(isMenuVisible ? 1 : 0.6)
                    }
                    .buttonStyle(.plain)
                    .opacity(isMenuVisible ? 1 : 0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isMenuVisible)
                    .popover(isPresented: $showSettingsPanel, arrowEdge: .top) {
                        WidgetSettingsMenuView(
                            widget: instance,
                            onUpdate: { updated in
                                manager.update(updated)
                            },
                            onDelete: { id in
                                showSettingsPanel = false
                                DispatchQueue.main.async {
                                    manager.removeWidget(id: id)
                                }
                            }
                        )
                        .environmentObject(manager)
                        .environmentObject(localization)
                        .frame(width: 360, height: 520)
                        .onDisappear {
                            showSettingsPanel = false
                        }
                    }
#endif
                }
                .padding(.trailing, 4)
                .padding(.bottom, 1)

                widgetView(for: instance)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity,
                           maxHeight: .infinity,
                           alignment: .topLeading)
            }
            .id(manager.globalColorsVersion) // refresh on any appearance change
            .padding(EdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2))
            .contentShape(Rectangle())
            .onHover { hovering in
                withAnimation(.snappy(duration: 0.16, extraBounce: 0.0)) {
                    isMenuVisible = hovering
                }
            }
#if os(macOS)
            .simultaneousGesture(
                TapGesture().onEnded {
                    if settingsPanel != nil {
                        closeSettingsPanel()
                    }
                }
            )
            .gesture(
                TapGesture(count: 2).onEnded {
                    togglePanel(for: instance)
                }
            )
            .onDisappear {
                closeSettingsPanel()
            }
            .onChange(of: instance.width) { _, _ in
                repositionPanelIfNeeded(for: instance)
            }
            .onChange(of: instance.height) { _, _ in
                repositionPanelIfNeeded(for: instance)
            }
            .onChange(of: instance.x) { _, _ in
                repositionPanelIfNeeded(for: instance)
            }
            .onChange(of: instance.y) { _, _ in
                repositionPanelIfNeeded(for: instance)
            }
            .onReceive(manager.$globalColorsVersion) { _ in
                // Trigger view refresh when appearance changes (e.g., background image/palette)
            }
            .onReceive(manager.$widgets) { widgets in
                // Если открыта панель настроек для этого виджета, держим её около виджета при любых изменениях размеров/позиции.
                guard let updated = widgets.first(where: { $0.id == instance.id }) else { return }
                repositionPanelIfNeeded(for: updated)
                // Пересчёт через кадр — после того, как окно виджета применило новый frame (setFrame может быть анимирован).
                DispatchQueue.main.async {
                    repositionPanelIfNeeded(for: updated)
                }
            }
#endif
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func widgetView(for instance: WidgetInstance) -> some View {
        switch instance.type {
        case .clock:
            ClockWidgetView(widget: instance)
        case .weather:
            WeatherWidgetView(widget: instance)
        }
    }

#if os(macOS)
    private func repositionPanelIfNeeded(for instance: WidgetInstance) {
        guard let settingsPanel,
              settingsPanelWidgetID == instance.id else { return }
        let spacing: CGFloat = 20
        let size = settingsPanel.frame.size
        let origin = panelOrigin(for: instance,
                                 panelSize: size,
                                 spacing: spacing)
        let newFrame = NSRect(origin: origin, size: size)
        settingsPanel.setFrame(newFrame, display: true, animate: true)
    }

    private func togglePanel(for instance: WidgetInstance) {
        let currentID = settingsPanelWidgetID
        let isOpen = settingsPanel != nil

        if isOpen && currentID == instance.id {
            // Повторное нажатие по тому же виджету закрывает панель.
            closeSettingsPanel()
            return
        }

        // Закрываем открытую панель другого виджета и открываем новую.
        if isOpen {
            closeSettingsPanel()
        }
        showSettings(for: instance)
    }

    private func showSettings(for instance: WidgetInstance) {
        manager.hideSidePanel()
        let panel = createSettingsPanel(for: instance)
        preparePanelAppearance(panel)
        settingsPanel = panel
        settingsPanelWidgetID = instance.id
        panel.orderFrontRegardless()
        panel.makeKey()
        animatePanelAppearance(panel)
        installPanelMonitors(for: panel)
    }

    private func closeSettingsPanel(animated: Bool = true) {
        guard let panel = settingsPanel else { return }

        let complete: () -> Void = {
            panel.close()
            self.settingsPanel = nil
            self.settingsPanelWidgetID = nil
            self.removePanelMonitors()
        }

        if animated {
            animatePanelDismiss(panel, completion: complete)
        } else {
            complete()
        }
    }

    private func createSettingsPanel(for instance: WidgetInstance) -> NSPanel {
        let size = NSSize(width: 360, height: 520)
        let spacing: CGFloat = 20
        let origin = panelOrigin(for: instance, panelSize: size, spacing: spacing)
        let rect = NSRect(origin: origin, size: size)

        let panel = WidgetSettingsPanel(contentRect: rect,
                                        styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
                                        backing: .buffered,
                                        defer: false)
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle, .stationary]
        panel.animationBehavior = .none
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true

        let content = WidgetSettingsMenuView(
            widget: instance,
            onUpdate: { updated in
                manager.update(updated)
            },
            onDelete: { id in
                DispatchQueue.main.async {
                    closeSettingsPanel()
                    manager.removeWidget(id: id)
                }
            }
        )
        .environmentObject(manager)
        .environmentObject(localization)
        .frame(width: size.width, height: size.height)

        let hosting = NSHostingView(rootView: content)
        hosting.frame = NSRect(origin: .zero, size: size)
        hosting.wantsLayer = true
        hosting.layer?.cornerRadius = 36
        hosting.layer?.masksToBounds = true
        panel.contentView = hosting

        settingsPanelCoordinator.onClose = { [weak panel] in
            if panel === self.settingsPanel {
                self.settingsPanel = nil
                self.settingsPanelWidgetID = nil
                self.removePanelMonitors()
            }
        }
        panel.delegate = settingsPanelCoordinator
        return panel
    }

    private func preparePanelAppearance(_ panel: NSPanel) {
        panel.alphaValue = 0
        panel.contentView?.layer?.transform = initialPanelTransform
        panel.contentView?.layer?.opacity = 0
    }

    private func animatePanelAppearance(_ panel: NSPanel) {
        let duration: TimeInterval = 0.12
        let timing = CAMediaTimingFunction(name: .easeInEaseOut)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = timing
            panel.animator().alphaValue = 1
        }

        let transformAnim = CABasicAnimation(keyPath: "transform")
        transformAnim.fromValue = initialPanelTransform
        transformAnim.toValue = CATransform3DIdentity
        transformAnim.duration = duration
        transformAnim.timingFunction = timing

        let opacityAnim = CABasicAnimation(keyPath: "opacity")
        opacityAnim.fromValue = 0
        opacityAnim.toValue = 1
        opacityAnim.duration = duration
        opacityAnim.timingFunction = timing

        panel.contentView?.layer?.add(transformAnim, forKey: "transformIn")
        panel.contentView?.layer?.add(opacityAnim, forKey: "fadeIn")
        panel.contentView?.layer?.transform = CATransform3DIdentity
        panel.contentView?.layer?.opacity = 1
    }

    private func animatePanelDismiss(_ panel: NSPanel, completion: @escaping () -> Void) {
        let duration: TimeInterval = 0.10
        let timing = CAMediaTimingFunction(name: .easeInEaseOut)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = timing
            panel.animator().alphaValue = 0
        }

        let transformAnim = CABasicAnimation(keyPath: "transform")
        transformAnim.fromValue = panel.contentView?.layer?.presentation()?.transform ?? CATransform3DIdentity
        transformAnim.toValue = initialPanelTransform
        transformAnim.duration = duration
        transformAnim.timingFunction = timing

        let opacityAnim = CABasicAnimation(keyPath: "opacity")
        opacityAnim.fromValue = panel.contentView?.layer?.presentation()?.opacity ?? 1
        opacityAnim.toValue = 0
        opacityAnim.duration = duration
        opacityAnim.timingFunction = timing

        panel.contentView?.layer?.add(transformAnim, forKey: "transformOut")
        panel.contentView?.layer?.add(opacityAnim, forKey: "fadeOut")
        panel.contentView?.layer?.transform = initialPanelTransform
        panel.contentView?.layer?.opacity = 0

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            completion()
        }
    }

    private var initialPanelTransform: CATransform3D {
        let translate = CATransform3DMakeTranslation(-8, -12, 0)
        return CATransform3DScale(translate, 0.92, 0.92, 1)
    }

    private func panelOrigin(for instance: WidgetInstance,
                             panelSize: CGSize,
                             spacing: CGFloat) -> CGPoint {
        if let window = manager.window(for: instance.id) {
            let frame = window.frame
            let screenFrame = window.screen?.visibleFrame ?? window.frame
            let screenMaxX = screenFrame.maxX
            let rightSpace = screenMaxX - NSMaxX(frame)
            let minY = screenFrame.minY + spacing
            let maxY = screenFrame.maxY - panelSize.height - spacing
            var y = frame.midY - panelSize.height / 2
            y = min(max(y, minY), maxY)
            if rightSpace >= panelSize.width + spacing {
                return CGPoint(x: NSMaxX(frame) + spacing,
                               y: y)
            } else {
                return CGPoint(x: frame.minX - panelSize.width - spacing,
                               y: y)
            }
        }
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let minY = screenFrame.minY + spacing
        let maxY = screenFrame.maxY - panelSize.height - spacing
        var y = instance.y + (instance.height - panelSize.height) / 2
        y = min(max(y, minY), maxY)
        return CGPoint(x: instance.x + instance.width + spacing,
                       y: y)
    }

    private func installPanelMonitors(for panel: NSPanel) {
        removePanelMonitors()

        // Игнорируем клики в окно самого виджета: повторное нажатие на троеточие не будет закрывать и сразу открывать панель.
        let widgetWindowNumber = settingsPanelWidgetID.flatMap { manager.window(for: $0)?.windowNumber }

        if let local = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown], handler: { [weak panel] event in
            guard let panel else { return event }
            // Закрываем только если клик вне панели и не по окну виджета (для троеточия и своей области не закрываем).
            if event.windowNumber != panel.windowNumber && event.windowNumber != widgetWindowNumber {
                closeSettingsPanel()
            }
            return event
        }) {
            settingsPanelMonitors.append(local)
        }

        if let global = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown], handler: { [weak panel] event in
            guard let panel else { return }
            if event.windowNumber != panel.windowNumber && event.windowNumber != widgetWindowNumber {
                closeSettingsPanel()
            }
        }) {
            settingsPanelMonitors.append(global)
        }
    }

    private func removePanelMonitors() {
        settingsPanelMonitors.forEach { NSEvent.removeMonitor($0) }
        settingsPanelMonitors.removeAll()
    }
#endif
}

#if os(macOS)
private final class WidgetSettingsPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

private final class WidgetSettingsPanelCoordinator: NSObject, ObservableObject, NSWindowDelegate {
    let objectWillChange = PassthroughSubject<Void, Never>()
    var onClose: (() -> Void)?

    func windowWillClose(_ notification: Notification) {
        onClose?()
    }
}
#endif

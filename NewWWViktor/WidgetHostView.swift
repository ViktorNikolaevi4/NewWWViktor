import SwiftUI
import Combine
#if os(macOS)
import AppKit
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
                    .background(
                        RoundedRectangle(cornerRadius: WidgetStyle.cornerRadius, style: .continuous)
                            .fill(widgetBackgroundFill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: WidgetStyle.cornerRadius, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.10))
                    )
                    .clipShape(
                        RoundedRectangle(cornerRadius: WidgetStyle.cornerRadius, style: .continuous)
                    )
                    .shadow(color: .clear, radius: 0)
            }
            .padding(EdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2))
            .contentShape(Rectangle())
            .onHover { hovering in
                withAnimation(.snappy(duration: 0.16, extraBounce: 0.0)) {
                    isMenuVisible = hovering
                }
            }
#if os(macOS)
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
        }
    }

    private var widgetBackgroundFill: AnyShapeStyle {
        switch manager.globalBackgroundStyle {
        case .palette:
            let color = WidgetPaletteColor.color(
                named: manager.globalBackgroundColorName,
                intensity: manager.globalBackgroundIntensity,
                fallback: Color.white.opacity(0.14)
            )
            return AnyShapeStyle(color.opacity(0.96))
        case .solid:
            return AnyShapeStyle(Color.white.opacity(0.12))
        case .gradient:
            let gradient = LinearGradient(
                colors: [
                    Color.white.opacity(0.18),
                    Color.black.opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            return AnyShapeStyle(gradient)
        case .photo:
            return AnyShapeStyle(.regularMaterial)
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
        if settingsPanel != nil {
            closeSettingsPanel()
            if settingsPanelWidgetID == instance.id {
                settingsPanelWidgetID = nil
                return
            }
        }
        showSettings(for: instance)
    }

    private func showSettings(for instance: WidgetInstance) {
        let panel = createSettingsPanel(for: instance)
        settingsPanel = panel
        settingsPanelWidgetID = instance.id
        panel.orderFrontRegardless()
        panel.makeKey()
        installPanelMonitors(for: panel)
    }

    private func closeSettingsPanel() {
        settingsPanel?.close()
        settingsPanel = nil
        settingsPanelWidgetID = nil
        removePanelMonitors()
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

        if let local = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown], handler: { [weak panel] event in
            guard let panel else { return event }
            if event.window !== panel {
                panel.close()
            }
            return event
        }) {
            settingsPanelMonitors.append(local)
        }

        if let global = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown], handler: { [weak panel] event in
            guard let panel else { return }
            if event.windowNumber != panel.windowNumber {
                panel.close()
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

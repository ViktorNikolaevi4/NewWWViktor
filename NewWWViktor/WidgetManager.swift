import AppKit
import SwiftUI
import Combine

final class WidgetManager: ObservableObject {
    @Published var widgets: [WidgetInstance] = [] {
        didSet { persist() }
    }
    @Published var isPanelFullscreen: Bool = false

    private var windows: [UUID: NSWindow] = [:]

    init() {
        load()
        widgets.forEach { attachWindow(for: $0) }
    }

    func addWidget(type: WidgetType) {
        let instance = WidgetInstance(type: type)
        // Можно раскидывать по сетке/стеку
        widgets.append(instance)
        attachWindow(for: instance)
    }

    func removeWidget(id: UUID) {
        widgets.removeAll { $0.id == id }
        if let window = windows[id] {
            window.close()
            windows[id] = nil
        }
    }

    func removeAllWidgets() {
        widgets.forEach { instance in
            if let window = windows[instance.id] {
                window.close()
            }
        }
        windows.removeAll()
        widgets.removeAll()
    }

    func update(_ instance: WidgetInstance) {
        guard let idx = widgets.firstIndex(where: { $0.id == instance.id }) else { return }

        var updatedInstance = instance
        if let window = windows[instance.id] {
            let frame = window.frame
            updatedInstance.x = frame.origin.x
            updatedInstance.y = frame.origin.y
            updatedInstance.width = frame.width
            updatedInstance.height = frame.height
        }

        widgets[idx] = updatedInstance

        if let window = windows[instance.id] {
            window.setFrame(
                NSRect(x: updatedInstance.x,
                       y: updatedInstance.y,
                       width: updatedInstance.width,
                       height: updatedInstance.height),
                display: true
            )
            // Use .normal when not pinned. If you want behind-all-windows, consider .desktopIcon.
            window.level = updatedInstance.isPinned ? .floating : .normal
        }
    }

    // MARK: - Windows

    private func attachWindow(for instance: WidgetInstance) {
        let content = WidgetHostView(instanceID: instance.id)
            .environmentObject(self)

        let window = NSWindow(
            contentRect: NSRect(x: instance.x,
                                y: instance.y,
                                width: instance.width,
                                height: instance.height),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        // Use .normal when not pinned. If you want behind-all-windows, consider .desktopIcon.
        window.level = instance.isPinned ? .floating : .normal
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        window.contentView = NSHostingView(rootView: content)
        window.makeKeyAndOrderFront(nil)

        windows[instance.id] = window
    }

    // MARK: - Persistence (ультра-просто)

    private let storageKey = "miniww.widgets"

    private func persist() {
        guard let data = try? JSONEncoder().encode(widgets) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let saved = try? JSONDecoder().decode([WidgetInstance].self, from: data)
        else { return }
        self.widgets = saved
    }

    // MARK: - Side panel helpers

    func togglePanelFullscreen() {
        isPanelFullscreen.toggle()
    }
}

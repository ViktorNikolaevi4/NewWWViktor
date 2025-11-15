import SwiftUI
import AppKit
import Combine

enum SettingsCategory: String, CaseIterable, Identifiable {
    case general = "Основные"
    case appearance = "Оформление"
    case plan = "План"
    case backups = "Резервные копии"
    case screens = "Экраны"
    case support = "Поддержка"
    case about = "О нас"

    var id: String { rawValue }

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
}

final class SettingsCoordinator: ObservableObject {
    @Published var selectedCategory: SettingsCategory = .general

    private var window: NSWindow?

    func show(_ category: SettingsCategory) {
        selectedCategory = category
        if window == nil {
            createWindow()
        }
        guard let window else { return }

        if !window.isVisible {
            window.center()
        }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func createWindow() {
        let content = SettingsWindowContent()
            .environmentObject(self)

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
}

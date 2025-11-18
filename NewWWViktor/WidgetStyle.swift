import SwiftUI

enum WidgetStyle {
    static let cornerRadius: CGFloat = 26
}

 enum AppIconMode: Int, CaseIterable, Identifiable {
    case menuOnly      // menu bar only
    case dockOnly      // Dock only
    case menuAndDock   // show in both places

    var id: Int { rawValue }
}

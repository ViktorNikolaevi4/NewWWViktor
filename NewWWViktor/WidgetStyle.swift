import SwiftUI

enum WidgetStyle {
    static let cornerRadius: CGFloat = 26
}

 enum AppIconMode: Int, CaseIterable, Identifiable {
    case menuOnly      // только строка меню
    case dockOnly      // только Dock
    case menuAndDock   // и там, и там

    var id: Int { rawValue }
}

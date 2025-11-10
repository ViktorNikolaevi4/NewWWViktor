
import SwiftUI

@main
struct MiniWWApp: App {
    @StateObject private var manager = WidgetManager()

    var body: some Scene {
        MenuBarExtra("miniWW", systemImage: "square.grid.3x3") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Add widget:")
                    .font(.headline)
                ForEach(WidgetType.allCases) { type in
                    Button(type.title) {
                        manager.addWidget(type: type)
                    }
                }
                Divider()
                Button("Quit miniWW") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(8)
        }
        .menuBarExtraStyle(.window)
        .environmentObject(manager)
    }
}

import SwiftUI

struct WidgetHostView: View {
    @EnvironmentObject var manager: WidgetManager
    let instanceID: UUID

    var body: some View {
        if let instance = manager.widgets.first(where: { $0.id == instanceID }) {
            ZStack(alignment: .topTrailing) {
                widgetView(for: instance)
                    .background(.ultraThinMaterial) // или кастомный
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                // Маленькая кнопка настроек / удаления
                Menu {
                    Button("Pin on Top", action: {
                        var updated = instance
                        updated.isPinned.toggle()
                        manager.update(updated)
                    })
                    Button(role: .destructive, action: {
                        manager.removeWidget(id: instance.id)
                    }) {
                        Text("Remove")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .padding(6)
                }
            }
            .padding(6)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func widgetView(for instance: WidgetInstance) -> some View {
        switch instance.type {
        case .clock:
            ClockWidgetView()
        case .notes:
            NotesWidgetView()
        }
    }
}

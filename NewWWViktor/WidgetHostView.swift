import SwiftUI

struct WidgetHostView: View {
    @EnvironmentObject var manager: WidgetManager
    let instanceID: UUID
    @State private var isMenuVisible = false

    var body: some View {
        if let instance = manager.widgets.first(where: { $0.id == instanceID }) {
            VStack(spacing: -12) {
                HStack {
                    Spacer()
                    Menu {
                        Button(instance.isPinned ? "Unpin from Top" : "Pin on Top") {
                            var updated = instance
                            updated.isPinned.toggle()
                            manager.update(updated)
                        }
                        Button(role: .destructive) {
                            manager.removeWidget(id: instance.id)
                        } label: {
                            Text("Remove")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 13, weight: .semibold))
                            .padding(6)
                            .background(.regularMaterial)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                            .opacity(isMenuVisible ? 1 : 0)
                    }
                    .buttonStyle(.plain)
                    .opacity(isMenuVisible ? 1 : 0)
                }
                .padding(.trailing, 4)

                widgetView(for: instance)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity,
                           maxHeight: .infinity,
                           alignment: .topLeading)
                    .background(
                        RoundedRectangle(cornerRadius: WidgetStyle.cornerRadius, style: .continuous)
                            .fill(.regularMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: WidgetStyle.cornerRadius, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.10))
                    )
                    .clipShape(
                        RoundedRectangle(cornerRadius: WidgetStyle.cornerRadius, style: .continuous)
                    )
                    .shadow(color: .black.opacity(0.10), radius: 18, x: 0, y: 10)
            }
            .padding(EdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2))
            .contentShape(Rectangle())
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isMenuVisible = hovering
                }
            }
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func widgetView(for instance: WidgetInstance) -> some View {
        switch instance.type {
        case .clock:
            ClockWidgetView()
        }
    }
}

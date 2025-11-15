import SwiftUI

struct WidgetHostView: View {
    @EnvironmentObject var manager: WidgetManager
    let instanceID: UUID
    @State private var isMenuVisible = false
    @State private var showSettingsPanel = false

    var body: some View {
        if let instance = manager.widgets.first(where: { $0.id == instanceID }) {
            VStack(spacing: 0) {
                HStack(alignment: .bottom) {
                    Spacer()
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
                        WidgetSettingsMenuView()
                            .frame(width: 360)
                            .onDisappear {
                                showSettingsPanel = false
                            }
                    }
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
                withAnimation(.snappy(duration: 0.16, extraBounce: 0.0)) {
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

import SwiftUI
import AppKit

struct SidePanelView: View {
    @EnvironmentObject var manager: WidgetManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Шапка
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("miniWW")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Choose a widget to add")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Image(systemName: "power")
                }
                .buttonStyle(.plain)
                .help("Quit miniWW")
            }

            // Список превью (как WidgetWall)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(WidgetType.allCases) { type in
                        WidgetPreviewCard(type: type) {
                            manager.addWidget(type: type)
                        }
                    }
                }
                .padding(.top, 4)
            }

            Divider()
                .padding(.top, 4)

            Button {
                manager.removeAllWidgets()
            } label: {
                Label("Clear all widgets", systemImage: "trash")
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.borderless)
            .foregroundColor(.secondary)
        }
        .padding(.top, 20)
        .padding(.horizontal, 14)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity,
               maxHeight: .infinity,
               alignment: .topLeading)
        .background(.ultraThinMaterial)
        .ignoresSafeArea()
    }
}

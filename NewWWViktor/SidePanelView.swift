import SwiftUI
import AppKit

struct SidePanelView: View {
    @EnvironmentObject var manager: WidgetManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("miniWW")
                        .font(.headline)
                    Text("Add widget")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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

            // Widgets list
            VStack(alignment: .leading, spacing: 8) {
                ForEach(WidgetType.allCases) { type in
                    Button {
                        manager.addWidget(type: type)
                    } label: {
                        HStack {
                            Text(type.title)
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.tint)
                        }
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()

            Button {
                manager.removeAllWidgets()
            } label: {
                Label("Clear all widgets", systemImage: "trash")
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.top, 24)
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.ultraThinMaterial)   // как системная панель
        .ignoresSafeArea()
    }
}

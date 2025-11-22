import SwiftUI
import AppKit

struct SidePanelView: View {
    @EnvironmentObject var manager: WidgetManager
    @EnvironmentObject var settingsCoordinator: SettingsCoordinator
    @EnvironmentObject var localization: LocalizationManager
    private let cardMaxWidth: CGFloat = 368
    @State private var showSettingsPopover = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(localization.text(.panelChooseWidget))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    manager.togglePanelFullscreen()
                } label: {
                    Image(systemName: manager.isPanelFullscreen
                          ? "arrow.down.right.and.arrow.up.left"
                          : "arrow.up.left.and.arrow.down.right")
                }
                .buttonStyle(.plain)
                .help(manager.isPanelFullscreen ? "Shrink side panel" : "Expand to full screen")

                Button {
                    showSettingsPopover.toggle()
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.plain)
                .help("Open settings")
                .popover(isPresented: $showSettingsPopover, arrowEdge: .top) {
                    SettingsPopoverView { selection in
                        handleSettingsSelection(selection)
                    }
                    .environmentObject(localization)
                }

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Image(systemName: "power")
                }
                .buttonStyle(.plain)
                .help("Quit miniWW")
            }

            // Widget preview list (WidgetWall style)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(WidgetType.allCases) { type in
                        WidgetPreviewCard(type: type) { size in
                            manager.addWidget(type: type, size: size)
                        }
                        .frame(maxWidth: cardMaxWidth, alignment: .leading)
                    }
                }
                .padding(.top, 4)
                .frame(maxWidth: .infinity, alignment: .center)
        }

            Divider()
                .padding(.top, 4)

            Button {
                manager.removeAllWidgets()
            } label: {
                Label(localization.text(.panelClearWidgets), systemImage: "trash")
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.borderless)
            .foregroundColor(.secondary)
        }
        .padding(.top, 20)
        .padding(.horizontal, 18)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity,
               maxHeight: .infinity,
               alignment: .topLeading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .ignoresSafeArea()
        .environment(\.colorScheme, .dark) // keep panel visuals consistent regardless of system theme
    }
}

private extension SidePanelView {
    func handleSettingsSelection(_ selection: String) {
        showSettingsPopover = false
        let category = SettingsCategoryID(rawValue: selection)?.category
        if let category {
            settingsCoordinator.show(category)
        }
    }
}

private enum SettingsCategoryID: String {
    case general
    case appearance
    case plan
    case backups
    case support
    case about

    var category: SettingsCategory {
        switch self {
        case .general: return .general
        case .appearance: return .appearance
        case .plan: return .plan
        case .backups: return .backups
        case .support: return .support
        case .about: return .about
        }
    }
}

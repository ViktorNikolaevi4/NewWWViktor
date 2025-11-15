import SwiftUI

struct SettingsWindowContent: View {
    @EnvironmentObject var settings: SettingsCoordinator

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.05))
                )
                .padding(12)
                .overlay(
                    content
                        .padding(24)
                )
        }
        .frame(minWidth: 760, minHeight: 540)
    }

    private var content: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
                .overlay(Color.white.opacity(0.08))
                .padding(.vertical, -24)
                .frame(width: 1)
                .padding(.horizontal, 24)
            detail
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(SettingsCategory.allCases) { category in
                sidebarRow(for: category)
            }

            Spacer()

            HStack(spacing: 8) {
                Image(systemName: "rectangle.grid.2x2")
                    .foregroundColor(.secondary)
                Text("WidgetWall")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Spacer()
                Text("3.14")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 12)
        }
        .frame(width: 180)
    }

    @ViewBuilder
    private func sidebarRow(for category: SettingsCategory) -> some View {
        let isSelected = settings.selectedCategory == category
        Button {
            settings.selectedCategory = category
        } label: {
            HStack(spacing: 12) {
                Image(systemName: category.systemImage)
                    .font(.system(size: 14, weight: .semibold))
                Text(category.rawValue)
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.orange.opacity(0.15) : Color.clear)
            )
            .foregroundColor(isSelected ? Color.orange : Color.primary)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var detail: some View {
        switch settings.selectedCategory {
        case .general:
            GeneralSettingsDetailView()
        default:
            placeholderDetail(title: settings.selectedCategory.rawValue)
        }
    }

    private func placeholderDetail(title: String) -> some View {
        VStack {
            Spacer()
            Text(title)
                .font(.title3.weight(.semibold))
            Text("Контент появится позже")
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

private struct GeneralSettingsDetailView: View {
    @State private var openAtLogin = true
    @State private var showMenuIcon = true
    @State private var duplicateMonitors = false
    @State private var duplicateSpaces = true
    @State private var hideWidgets = false
    @State private var pinWidgets = true
    @State private var gridSize = 0
    @State private var snapToGrid = true
    @State private var focusOnHover = true
    @State private var scrollBarsAutomatic = true

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            ScrollView {
                VStack(spacing: 22) {
                    toggleSection(title: "Открывать при входе в систему (рекомендуется)",
                                  isOn: $openAtLogin)

                    section(title: "Иконка приложения") {
                        Picker("", selection: $showMenuIcon) {
                            Text("Показывать в строке меню").tag(true)
                            Text("Скрыть").tag(false)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 220)
                    }

                    section(title: "Язык") {
                        HStack {
                            Text("Запросы или отзывы о языке?")
                                .foregroundColor(.secondary)
                            Spacer()
                            Link("Отправь сюда!", destination: URL(string: "https://example.com")!)
                        }
                    }

                    toggleSection(title: "Дублировать на всех мониторах",
                                  isOn: $duplicateMonitors)

                    toggleSection(title: "Дублировать на всех пространствах",
                                  isOn: $duplicateSpaces)

                    toggleSection(title: "Скрыть виджеты",
                                  isOn: $hideWidgets)

                    toggleSection(title: "Закрепить виджеты на рабочем столе",
                                  isOn: $pinWidgets)

                    section(title: "Размер сетки") {
                        Picker("", selection: $gridSize) {
                            Text("macOS").tag(0)
                            Text("WidgetWall").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 260)
                    }

                    toggleSection(title: "Привязать к сетке",
                                  isOn: $snapToGrid)

                    toggleSection(title: "Фокус при наведении",
                                  isOn: $focusOnHover)

                    section(title: "Показать системные полосы прокрутки") {
                        Picker("", selection: $scrollBarsAutomatic) {
                            Text("Автоматический").tag(true)
                            Text("Всегда").tag(false)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 200)
                    }

                    section(title: "Уведомления") {
                        Button("Управление уведомлениями") {}
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                    }

                    section(title: "Сброс") {
                        Button("Сбросить все настройки") {}
                            .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.bottom, 12)
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Основные")
                .font(.title3.weight(.semibold))
            Text("Управляйте поведением miniWW и настройте рабочее пространство.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline.weight(.semibold))
            HStack {
                content()
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.05))
                )
        )
    }

    private func toggleSection(title: String, isOn: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline.weight(.semibold))
                Spacer()
                Toggle("", isOn: isOn)
                    .toggleStyle(SwitchToggleStyle(tint: .orange))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.05))
                )
        )
    }
}

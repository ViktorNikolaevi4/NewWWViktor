import SwiftUI

struct WidgetSettingsMenuView: View {
    let widget: WidgetInstance
    let onUpdate: (WidgetInstance) -> Void

    @State private var workingWidget: WidgetInstance
    @State private var showLocationPicker = false
    @State private var showWeather = false
    @State private var isTwelveHour = true
    @State private var isPinnedTop = false
    @State private var lockPosition = false
    @State private var snapToGrid = true

    init(widget: WidgetInstance, onUpdate: @escaping (WidgetInstance) -> Void) {
        self.widget = widget
        self.onUpdate = onUpdate
        _workingWidget = State(initialValue: widget)
    }

    var body: some View {
        ZStack {
            panelContent
                .disabled(showLocationPicker)
                .blur(radius: showLocationPicker ? 3 : 0)
                .opacity(showLocationPicker ? 0.4 : 1)

            if showLocationPicker {
                WidgetLocationPickerView(isPresented: $showLocationPicker,
                                         selection: $workingWidget.location) { newLocation in
                    apply(location: newLocation)
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.88), value: showLocationPicker)
        .frame(width: 360, height: 520)
        .onChange(of: widget) { newValue in
            workingWidget = newValue
        }
        .onChange(of: workingWidget.showsDate) { _ in
            onUpdate(workingWidget)
        }
        .onChange(of: workingWidget.showsLocation) { _ in
            onUpdate(workingWidget)
        }
    }

    private func apply(location: WidgetLocation) {
        workingWidget.location = location
        onUpdate(workingWidget)
    }

    private var panelContent: some View {
        VStack(spacing: 16) {
            handle

            ScrollView {
                VStack(spacing: 12) {
                    generalSection
                    appearanceSection
                    behaviorSection
                    managementSection
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 14)
        .frame(maxHeight: 520)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(LinearGradient(colors: [Color.white.opacity(0.25), Color.black.opacity(0.15)],
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing))
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 30, x: 0, y: 30)
        .frame(minHeight: 400)
    }

    private var handle: some View {
        Capsule()
            .fill(Color.white.opacity(0.4))
            .frame(width: 38, height: 5)
            .padding(.top, 4)
    }

    private var generalSection: some View {
        WidgetSettingsGroup(title: "Позиция") {
            WidgetSettingsRowButton(title: "Позиция") {
                showLocationPicker = true
            } content: {
                ValuePill(text: workingWidget.location.displayName,
                          icon: workingWidget.location.iconName)
            }

            WidgetSettingsRow(title: "Название") {
                ValuePill(text: workingWidget.location.city ?? "—")
            }

            ToggleRow(title: "Показывать дату", isOn: $workingWidget.showsDate)
            ToggleRow(title: "Показывать местоположение", isOn: $workingWidget.showsLocation)
            ToggleRow(title: "Показывать погоду", isOn: $showWeather)

            WidgetSettingsRow(title: "Время") {
                SegmentedPill(options: ["12ч", "24ч"], selected: $isTwelveHour)
            }
        }
    }

    private var appearanceSection: some View {
        WidgetSettingsGroup(title: "Цвета") {
            WidgetSettingsRow(title: "Основной цвет") {
                ValuePill(text: "Глобальный", icon: "paintbrush")
            }
            WidgetSettingsRow(title: "Вторичный цвет") {
                ValuePill(text: "Глобальный", icon: "eyedropper")
            }
            WidgetSettingsRow(title: "Фон") {
                ValuePill(text: "Глобальный", icon: "circle.lefthalf.filled")
            }
        }
    }

    private var behaviorSection: some View {
        WidgetSettingsGroup(title: "Поведение") {
            WidgetSettingsRow(title: "Размер") {
                HStack(spacing: 8) {
                    IconButton(systemName: "rectangle.portrait", isSelected: true)
                    IconButton(systemName: "rectangle", isSelected: false)
                }
            }
            ToggleRow(title: "Закрепить сверху", isOn: $isPinnedTop)
            ToggleRow(title: "Зафиксировать положение", isOn: $lockPosition)
            ToggleRow(title: "Привязать к сетке", isOn: $snapToGrid)
        }
    }

    private var managementSection: some View {
        WidgetSettingsGroup(title: "Действия") {
            WidgetSettingsRow(title: "Добавить виджеты") {
                IconButton(systemName: "plus", isSelected: true)
            }
            WidgetSettingsRow(title: "Основные настройки") {
                IconButton(systemName: "gearshape", isSelected: true)
            }
            WidgetSettingsButton(title: "Удалить", role: .destructive) { }
        }
    }
}

// MARK: - Building Blocks

private struct WidgetSettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.7))

            VStack(spacing: 1) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.08))
            )
        }
    }
}

private struct WidgetSettingsRow<Content: View>: View {
    let title: String
    @ViewBuilder var trailing: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.trailing = content()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
            trailing
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.15))
    }
}

private struct WidgetSettingsRowButton<Content: View>: View {
    let title: String
    let action: () -> Void
    @ViewBuilder var trailing: Content

    init(title: String, action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.title = title
        self.action = action
        self.trailing = content()
    }

    var body: some View {
        Button(action: action) {
            WidgetSettingsRow(title: title) {
                trailing
            }
        }
        .buttonStyle(.plain)
    }
}

private struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        WidgetSettingsRow(title: title) {
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: Color.green.opacity(0.8)))
                .labelsHidden()
        }
    }
}

private struct ValuePill: View {
    let text: String
    var icon: String?

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
            }
            Text(text)
        }
        .font(.system(size: 13, weight: .medium))
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.14))
        .clipShape(Capsule())
    }
}

private struct SegmentedPill: View {
    let options: [String]
    @Binding var selected: Bool

    var body: some View {
        HStack(spacing: 0) {
            segment(title: options.first ?? "", active: selected, toggleValue: true)
            segment(title: options.last ?? "", active: !selected, toggleValue: false)
        }
        .background(Color.black.opacity(0.25))
        .clipShape(Capsule())
    }

    private func segment(title: String, active: Bool, toggleValue: Bool) -> some View {
        Button {
            selected = toggleValue
        } label: {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(active ? .black : .white.opacity(0.7))
                .padding(.vertical, 6)
                .padding(.horizontal, 18)
                .background(active ? Color.white : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

private struct IconButton: View {
    let systemName: String
    var isSelected: Bool

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(isSelected ? .black : .white.opacity(0.8))
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.white : Color.black.opacity(0.25))
            )
    }
}

private struct WidgetSettingsButton: View {
    enum Role {
        case normal
        case destructive
    }

    let title: String
    var role: Role = .normal
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Image(systemName: role == .destructive ? "trash" : "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(role == .destructive ? Color.red.opacity(0.15) : Color.black.opacity(0.15))
            .foregroundColor(role == .destructive ? .red : .white)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Location Picker

private struct WidgetLocationPickerView: View {
    @Binding var isPresented: Bool
    @Binding var selection: WidgetLocation
    let onSelect: (WidgetLocation) -> Void

    @State private var searchText = ""
    @StateObject private var searchService = LocationSearchService()

    var body: some View {
        VStack(spacing: 12) {
            pickerHeader
            searchField

            ScrollView {
                VStack(spacing: 10) {
                    LocationOptionRow(title: "Текущее местоположение",
                                      subtitle: nil,
                                      icon: "location.fill",
                                      isSelected: selection.mode == .current) {
                        select(.current)
                    }

                    if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        searchPlaceholder
                    } else if searchService.isSearching {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .padding(.top, 30)
                    } else if searchService.results.isEmpty {
                        Text("Ничего не найдено")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 20)
                    } else {
                        ForEach(searchService.results) { result in
                            LocationOptionRow(title: result.title,
                                              subtitle: result.subtitle,
                                              icon: "mappin.and.ellipse",
                                              isSelected: isResultSelected(result)) {
                                select(result.widgetLocation)
                            }
                        }
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .padding(18)
        .frame(width: 320, height: 440)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.12))
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 25, x: 0, y: 20)
        .onChange(of: searchText) { newValue in
            searchService.update(query: newValue)
        }
    }

    private var pickerHeader: some View {
        HStack {
            Button {
                isPresented = false
            } label: {
                Label("Назад", systemImage: "chevron.left")
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.plain)
            .foregroundColor(.white.opacity(0.9))

            Spacer()

            Text("Позиция")
                .font(.headline.weight(.semibold))
                .foregroundColor(.white)

            Spacer()

            Spacer()
                .frame(width: 60)
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.6))

            TextField("Поиск города...", text: $searchText)
                .textFieldStyle(.plain)
                .foregroundColor(.white)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var searchPlaceholder: some View {
        Text("Введите название города, чтобы изменить зону.")
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white.opacity(0.65))
            .multilineTextAlignment(.center)
            .padding(.top, 24)
            .padding(.horizontal, 8)
    }

    private func isResultSelected(_ result: LocationSearchResult) -> Bool {
        selection.mode == .custom &&
        selection.city == result.title &&
        selection.region == result.subtitle
    }

    private func select(_ location: WidgetLocation) {
        selection = location
        onSelect(location)
        isPresented = false
    }
}

private struct LocationOptionRow: View {
    let title: String
    let subtitle: String?
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.yellow)
                }
            }
            .foregroundColor(.white)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(Color.black.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

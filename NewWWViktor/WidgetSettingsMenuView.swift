import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct WidgetSettingsMenuView: View {
    let widget: WidgetInstance
    let onUpdate: (WidgetInstance) -> Void

    @State private var workingWidget: WidgetInstance
    @State private var showLocationPicker = false
    @State private var showColorPicker = false
    @State private var showWeather = false
    @State private var isPinnedTop = false
    @State private var lockPosition = false
    @State private var snapToGrid = true

    init(widget: WidgetInstance, onUpdate: @escaping (WidgetInstance) -> Void) {
        self.widget = widget
        self.onUpdate = onUpdate
        _workingWidget = State(initialValue: widget)
    }

    var body: some View {
        let isOverlayPresented = showLocationPicker || showColorPicker

        return ZStack {
            panelContent
                .disabled(isOverlayPresented)
                .blur(radius: isOverlayPresented ? 3 : 0)
                .opacity(isOverlayPresented ? 0.4 : 1)

            if showLocationPicker {
                WidgetLocationPickerView(isPresented: $showLocationPicker,
                                         selection: $workingWidget.location) { newLocation in
                    apply(location: newLocation)
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }

            if showColorPicker {
                WidgetColorPickerView(isPresented: $showColorPicker,
                                      selection: $workingWidget.mainColorName,
                                      intensity: $workingWidget.mainColorIntensity) {
                    onUpdate(workingWidget)
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.88), value: showLocationPicker)
        .animation(.spring(response: 0.32, dampingFraction: 0.88), value: showColorPicker)
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
        .onChange(of: workingWidget.prefersTwelveHour) { _ in
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
                SegmentedPill(options: ["12ч", "24ч"], selected: $workingWidget.prefersTwelveHour)
            }
        }
    }

    private var appearanceSection: some View {
        WidgetSettingsGroup(title: "Цвета") {
            WidgetSettingsRowButton(title: "Основной цвет") {
                showColorPicker = true
            } content: {
                ColorChip(colorName: workingWidget.mainColorName,
                          intensity: workingWidget.mainColorIntensity)
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

// MARK: - Color Picker

private struct ColorChip: View {
    let colorName: String?
    var intensity: Double = 1.0

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(displayColor)
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                )
            Text(colorTitle)
                .font(.system(size: 13, weight: .medium))
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 10)
        .background(Color.white.opacity(0.14))
        .clipShape(Capsule())
    }

    private var displayColor: Color {
        WidgetPaletteColor.color(named: colorName, intensity: intensity, fallback: .primary)
    }

    private var colorTitle: String {
        colorName.map { $0 } ?? "Глобальный"
    }
}

private struct WidgetColorPickerView: View {
    enum Tab: String, CaseIterable {
        case palette = "Палитра"
        case selected = "Выбранный"
    }

    @Binding var isPresented: Bool
    @Binding var selection: String?
    @Binding var intensity: Double
    let onChange: () -> Void

    @State private var tab: Tab = .palette
    @State private var customColorHex: String = "#FFFFFFFF"

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)
    private let palette = PaletteColorOption.defaultPalette

    var body: some View {
        VStack(spacing: 16) {
            header

            Picker("", selection: $tab) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Text(tab.rawValue)
                }
            }
            .pickerStyle(.segmented)

            if tab == .palette {
                paletteGrid
            } else {
                ScrollView {
                    selectedSection
                        .padding(.bottom, 8)
                }
                .frame(maxHeight: .infinity)
            }

            intensitySection

            Button {
                select(nil)
            } label: {
                HStack {
                    Image(systemName: selection == nil ? "checkmark.circle.fill" : "circle")
                    Text("Глобальный")
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(Color.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .frame(width: 340, height: 460)
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
        .onAppear {
            syncCustomColorHex(with: selection)
        }
        .onChange(of: selection) { newValue in
            syncCustomColorHex(with: newValue)
        }
    }

    private var header: some View {
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

            Text("Основной цвет")
                .font(.headline.weight(.semibold))
                .foregroundColor(.white)

            Spacer()

            Spacer()
                .frame(width: 60)
        }
    }

    private var paletteGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(palette) { option in
                    Button {
                        select(option.assetName)
                    } label: {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(option.assetName))
                            .frame(height: 32)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.white.opacity(selection == option.assetName ? 1 : 0.2),
                                            lineWidth: selection == option.assetName ? 3 : 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var selectedSection: some View {
        VStack(spacing: 14) {
            if let selection {
                ColorChip(colorName: selection, intensity: intensity)
            } else {
                Text("Цвет не выбран.\nИспользуйте палитру ниже, чтобы выбрать цвет.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 4)
            }

            colorWheel

            Button("Очистить") {
                select(nil)
            }
            .buttonStyle(.plain)
            .foregroundColor(.white.opacity(selection == nil ? 0.4 : 0.9))
            .disabled(selection == nil)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 10)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var intensitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Яркость")
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.7))

            Slider(value: $intensity, in: 0...1.0) {
                Text("Яркость")
            }
            .accentColor(.white)
            .onChange(of: intensity) { _ in
                onChange()
            }
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(colors: [
                            WidgetPaletteColor.color(named: selection, intensity: 0.0, fallback: .black),
                            WidgetPaletteColor.color(named: selection, intensity: 1.0, fallback: .primary)
                        ], startPoint: .leading, endPoint: .trailing)
                    )
                    .opacity(0.35)
            )
        }
    }

    private var colorWheel: some View {
        ColorWheelControl(color: customColorBinding)
            .frame(height: 180)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var customColorBinding: Binding<Color> {
        Binding(
            get: {
                HexColor.color(from: customColorHex)
                ?? WidgetPaletteColor.color(named: selection, intensity: 1.0, fallback: .white)
            },
            set: { newColor in
                guard let hex = HexColor.hexString(from: newColor) else { return }
                customColorHex = hex
                selection = hex
                onChange()
            }
        )
    }

    private func select(_ colorName: String?) {
        selection = colorName
        onChange()
        if colorName == nil {
            isPresented = false
        }
    }

    private func syncCustomColorHex(with newValue: String?) {
        guard let newValue else {
            customColorHex = "#FFFFFFFF"
            return
        }

        if let normalized = HexColor.normalizedHex(from: newValue) {
            customColorHex = normalized
        } else if let resolved = HexColor.hexStringForNamedColor(newValue) {
            customColorHex = resolved
        }
    }
}

private struct PaletteColorOption: Identifiable {
    let id = UUID()
    let assetName: String

    static let defaultPalette: [PaletteColorOption] = [
        "PaletteYellow", "PaletteYellow2", "PaletteYellow3", "PaletteYellow4",
        "PaletteGreen", "PaletteGreen2", "PaletteGreen3", "PaletteGreen4",
        "PaletteCyan", "PaletteCyan2", "PaletteCyan3", "PaletteCyan4",
        "PaletteTeal", "PaletteTeal2", "PaletteTeal3", "PaletteTeal4",
        "PalettePink", "PalettePink2", "PalettePink3", "PalettePink4",
        "PaletteRed", "PaletteRed2", "PaletteRed3", "PaletteRed4",
        "PaletteGrey", "PaletteGrey2", "PaletteGrey3", "PaletteGrey4",
        "PaletteBlack", "PaletteWhite", "AppYellow"
    ].map { PaletteColorOption(assetName: $0) }
}

// MARK: - Color Wheel

private struct ColorWheelControl: View {
    @Binding var color: Color
    @State private var hsb = HSBColor(hue: 0, saturation: 0, brightness: 1, alpha: 1)

    private static let hueGradient: [Color] = [
        .red, .yellow, .green, .cyan, .blue, .purple, .red
    ]

    var body: some View {
        GeometryReader { proxy in
            let diameter = min(proxy.size.width, proxy.size.height)
            let radius = diameter / 2
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let indicator = indicatorPosition(center: center, radius: radius)

            ZStack {
                Circle()
                    .fill(
                        AngularGradient(gradient: Gradient(colors: Self.hueGradient),
                                        center: .center)
                    )
                    .overlay(
                        Circle()
                            .fill(
                                RadialGradient(gradient: Gradient(colors: [.white, .clear]),
                                               center: .center,
                                               startRadius: 0,
                                               endRadius: radius)
                            )
                    )
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                updateColor(at: value.location, center: center, radius: radius)
                            }
                            .onEnded { value in
                                updateColor(at: value.location, center: center, radius: radius)
                            }
                    )

                Circle()
                    .strokeBorder(Color.white, lineWidth: 2)
                    .background(Circle().fill(color))
                    .shadow(color: .black.opacity(0.4), radius: 2)
                    .frame(width: 18, height: 18)
                    .position(indicator)
            }
            .onAppear {
                hsb = HSBColor(color: color)
            }
            .onChange(of: color) { newValue in
                hsb = HSBColor(color: newValue)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func indicatorPosition(center: CGPoint, radius: CGFloat) -> CGPoint {
        let angle = 2 * .pi * CGFloat(hsb.hue)
        let distance = CGFloat(hsb.saturation) * radius
        return CGPoint(
            x: center.x + distance * cos(angle),
            y: center.y + distance * sin(angle)
        )
    }

    private func updateColor(at point: CGPoint, center: CGPoint, radius: CGFloat) {
        let dx = Double(point.x - center.x)
        let dy = Double(point.y - center.y)
        var hue = atan2(dy, dx) / (2 * .pi)
        if hue < 0 { hue += 1 }
        let distance = min(max(Double(hypot(dx, dy)), 0), Double(radius))
        let saturation = distance / Double(radius)

        hsb = HSBColor(hue: hue, saturation: saturation, brightness: hsb.brightness, alpha: 1)
        color = hsb.color
    }
}

private struct HSBColor {
    var hue: Double
    var saturation: Double
    var brightness: Double
    var alpha: Double

    var color: Color {
        Color(hue: hue, saturation: saturation, brightness: brightness, opacity: alpha)
    }

    init(hue: Double, saturation: Double, brightness: Double, alpha: Double) {
        self.hue = hue
        self.saturation = saturation
        self.brightness = brightness
        self.alpha = alpha
    }

    init(color: Color) {
#if os(macOS)
        let native = NSColor(color).usingColorSpace(.sRGB)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        native?.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
#else
        let native = UIColor(color)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        native.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
#endif
        self.hue = Double(hue)
        self.saturation = Double(saturation)
        self.brightness = Double(brightness)
        self.alpha = Double(alpha)
    }
}

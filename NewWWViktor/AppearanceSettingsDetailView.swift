import SwiftUI

struct AppearanceSettingsDetailView: View {
    @State private var selectedTheme: ThemeOption = .system
    @State private var lightModePreview = true
    @State private var darkModePreview = true
    @State private var primaryColor: ColorAccent = .system
    @State private var secondaryColor: ColorAccent = .system
    @State private var backgroundStyle: BackgroundStyle = .photo
    @State private var imageSource: ImageSource = .photos
    @State private var blurBackground = true

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            ScrollView {
                VStack(spacing: 22) {
                    section(title: "Цветовая тема") {
                        VStack(alignment: .leading, spacing: 14) {
                            Picker("", selection: $selectedTheme) {
                                ForEach(ThemeOption.allCases) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                            .pickerStyle(.segmented)

                            modeToggleRow(title: "Светлый режим",
                                          description: "Используйте светлую палитру",
                                          isOn: $lightModePreview)

                            modeToggleRow(title: "Темный режим",
                                          description: "Включен",
                                          isOn: $darkModePreview)
                        }
                    }

                    section(title: "Цвета") {
                        VStack(spacing: 12) {
                            colorPickerRow(title: "Основной цвет",
                                           selection: $primaryColor)
                            colorPickerRow(title: "Вторичный цвет",
                                           selection: $secondaryColor)
                        }
                    }

                    section(title: "Фон") {
                        VStack(alignment: .leading, spacing: 16) {
                            Picker("", selection: $backgroundStyle) {
                                ForEach(BackgroundStyle.allCases) { style in
                                    Label(style.label, systemImage: style.systemImage)
                                        .labelStyle(.iconOnly)
                                        .tag(style)
                                }
                            }
                            .pickerStyle(.segmented)

                            Picker("Источник изображения", selection: $imageSource) {
                                ForEach(ImageSource.allCases) { source in
                                    Text(source.rawValue).tag(source)
                                }
                            }
                            .frame(width: 220)

                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Фото")
                                        .font(.headline.weight(.semibold))
                                    Text("Выберите изображение для виджета")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button("Обзор") {}
                                    .buttonStyle(.borderedProminent)
                                    .tint(.orange)
                            }

                            Toggle("Размытие фона", isOn: $blurBackground)
                                .toggleStyle(SwitchToggleStyle(tint: .orange))
                        }
                    }

                    section(title: "Сброс внешнего вида") {
                        Button("Сбросить внешний вид") {}
                            .frame(maxWidth: .infinity)
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
            Text("Оформление")
                .font(.title3.weight(.semibold))
            Text("Настройте внешний вид miniWW под себя.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline.weight(.semibold))
            content()
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

    private func modeToggleRow(title: String, description: String, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline.weight(.semibold))
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .orange))
        }
    }

    private func colorPickerRow(title: String, selection: Binding<ColorAccent>) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.headline.weight(.semibold))
            Spacer()
            Picker("", selection: selection) {
                ForEach(ColorAccent.allCases) { accent in
                    Text(accent.rawValue).tag(accent)
                }
            }
            .frame(width: 180)
        }
    }
}

enum ThemeOption: String, CaseIterable, Identifiable {
    case system = "Системная"
    case dark = "Темная"
    case light = "Светлая"

    var id: String { rawValue }
}

enum ColorAccent: String, CaseIterable, Identifiable {
    case system = "Системная"
    case custom = "Пользовательская"
    case orange = "Оранжевый"
    case purple = "Фиолетовый"

    var id: String { rawValue }
}

enum BackgroundStyle: String, CaseIterable, Identifiable {
    case solid
    case gradient
    case photo

    var id: String { rawValue }

    var label: String {
        switch self {
        case .solid: return "Цвет"
        case .gradient: return "Градиент"
        case .photo: return "Фото"
        }
    }

    var systemImage: String {
        switch self {
        case .solid: return "square.fill"
        case .gradient: return "square.split.2x1"
        case .photo: return "photo"
        }
    }
}

enum ImageSource: String, CaseIterable, Identifiable {
    case photos = "Фото"
    case files = "Файлы"
    case widgets = "Виджеты"

    var id: String { rawValue }
}

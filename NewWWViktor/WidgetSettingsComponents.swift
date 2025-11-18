import SwiftUI

struct WidgetSettingsGroup<Content: View>: View {
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

struct WidgetSettingsRow<Content: View>: View {
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

struct WidgetSettingsRowButton<Content: View>: View {
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

struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        WidgetSettingsRow(title: title) {
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: isOn ? Color.yellow : Color.gray.opacity(0.4)))
                .labelsHidden()
        }
    }
}

struct ValuePill: View {
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

struct SegmentedPill: View {
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

struct IconButton: View {
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

struct WidgetSettingsButton: View {
    enum Role {
        case normal
        case destructive
    }

    let title: String
    var role: Role = .normal
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(role == .destructive ? Color.red.opacity(0.2) : Color.white.opacity(0.12))
                .foregroundColor(role == .destructive ? .red : .white)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct ColorChip: View {
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
        colorName.map { $0 } ?? "Global"
    }
}

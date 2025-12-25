import SwiftUI

struct PomodoroWidgetView: View {
    let widget: WidgetInstance

    @EnvironmentObject private var manager: WidgetManager
    @EnvironmentObject private var localization: LocalizationManager
    @State private var isRunning = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Spacer(minLength: 0)

            ZStack {
                Circle()
                    .stroke(secondaryColor.opacity(0.25), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(primaryColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 6) {
                    Text(localization.text(.widgetPomodoroFocusLabel))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(secondaryColor)

                    Text(localization.text(.widgetPomodoroTimeDefault))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Button {
                        isRunning.toggle()
                    } label: {
                        Image(systemName: isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.white)
                            .padding(6)
                            .background(Circle().fill(primaryColor))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(localization.text(isRunning ? .widgetPomodoroPause : .widgetPomodoroStart))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(2)
            .animation(.easeInOut(duration: 0.2), value: isRunning)

            controlsRow
                .padding(.bottom, 2)
        }
        .padding(6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }
}

private extension PomodoroWidgetView {
    var progress: Double {
        isRunning ? 0.35 : 0.05
    }

    var controlsRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.trianglehead.clockwise")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(secondaryColor)

            Spacer()

            HStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(index == 0 ? primaryColor : secondaryColor.opacity(0.4))
                        .frame(width: 8, height: 8)
                }
            }

            Spacer()

            Image(systemName: "playpause.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(secondaryColor)
        }
    }

    var primaryColor: Color {
        let name = widget.mainColorName ?? manager.globalPrimaryColorName
        let intensity = widget.mainColorName == nil ? manager.globalPrimaryIntensity : widget.mainColorIntensity
        _ = manager.globalColorsVersion
        return WidgetPaletteColor.color(named: name,
                                        intensity: intensity,
                                        fallback: Color(red: 1.0, green: 0.84, blue: 0.25))
    }

    var secondaryColor: Color {
        let name = widget.secondaryColorName ?? manager.globalSecondaryColorName
        let intensity = widget.secondaryColorName == nil ? manager.globalSecondaryIntensity : widget.secondaryColorIntensity
        _ = manager.globalColorsVersion
        return WidgetPaletteColor.color(named: name,
                                        intensity: intensity,
                                        fallback: .secondary)
    }
}

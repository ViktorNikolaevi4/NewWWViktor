import SwiftUI
import SwiftData

struct EisenhowerWidgetView: View {
    let widget: WidgetInstance

    @EnvironmentObject private var localization: LocalizationManager
    @Query(filter: #Predicate<EisenhowerTask> { !$0.isDone },
           sort: \EisenhowerTask.createdAt,
           order: .reverse)
    private var tasks: [EisenhowerTask]

    private let gridSpacing: CGFloat = 6
    private let cellCornerRadius: CGFloat = 14

    var body: some View {
        Group {
            if widget.sizeOption == .extraLarge {
                extraLargeLayout
            } else {
                smallLayout
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var smallLayout: some View {
        matrixGrid
            .padding(6)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var extraLargeLayout: some View {
        VStack(alignment: .leading, spacing: 12) {
            matrixGrid
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if !recentTasks.isEmpty {
                VStack(spacing: 8) {
                    ForEach(recentTasks) { task in
                        taskRow(task)
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var matrixGrid: some View {
        VStack(spacing: gridSpacing) {
            HStack(spacing: gridSpacing) {
                quadrantCell(.importantUrgent)
                quadrantCell(.importantNotUrgent)
            }
            HStack(spacing: gridSpacing) {
                quadrantCell(.notImportantUrgent)
                quadrantCell(.notImportantNotUrgent)
            }
        }
    }

    private func quadrantCell(_ quadrant: EisenhowerQuadrant) -> some View {
        let count = tasks.filter { $0.quadrant == quadrant }.count
        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: cellCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: cellCornerRadius, style: .continuous)
                        .stroke(quadrantColor(quadrant).opacity(0.7), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(quadrantColor(quadrant))
                        .frame(width: 8, height: 8)
                    Text(quadrantLabel(quadrant))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }

                Text("\(count)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func taskRow(_ task: EisenhowerTask) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(quadrantColor(task.quadrant))
                .frame(width: 6, height: 6)
            Text(task.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }

    private func quadrantLabel(_ quadrant: EisenhowerQuadrant) -> String {
        switch quadrant {
        case .importantUrgent:
            return localization.text(.widgetEisenhowerImportantUrgent)
        case .importantNotUrgent:
            return localization.text(.widgetEisenhowerImportantNotUrgent)
        case .notImportantUrgent:
            return localization.text(.widgetEisenhowerNotImportantUrgent)
        case .notImportantNotUrgent:
            return localization.text(.widgetEisenhowerNotImportantNotUrgent)
        }
    }

    private func quadrantColor(_ quadrant: EisenhowerQuadrant) -> Color {
        switch quadrant {
        case .importantUrgent:
            return Color.red.opacity(0.9)
        case .importantNotUrgent:
            return Color.yellow.opacity(0.9)
        case .notImportantUrgent:
            return Color.blue.opacity(0.9)
        case .notImportantNotUrgent:
            return Color.gray.opacity(0.7)
        }
    }

    private var recentTasks: [EisenhowerTask] {
        Array(tasks.prefix(6))
    }

    private var accessibilityLabel: String {
        let urgent = tasks.filter { $0.quadrant == .importantUrgent }.count
        let important = tasks.filter { $0.quadrant == .importantNotUrgent }.count
        let delegate = tasks.filter { $0.quadrant == .notImportantUrgent }.count
        let eliminate = tasks.filter { $0.quadrant == .notImportantNotUrgent }.count
        return "\(urgent), \(important), \(delegate), \(eliminate)"
    }
}

import SwiftUI
import AppKit

struct SidePanelView: View {
    @EnvironmentObject var manager: WidgetManager // Менеджер виджетов, общается с AppKit-частью

    var body: some View {
        VStack(alignment: .leading, spacing: 16) { // Основной вертикальный стек панели
            HStack { // Шапка с названием и кнопкой выключения
                VStack(alignment: .leading, spacing: 2) { // Текстовый блок “miniWW / Add widget”
                    Text("miniWW")
                        .font(.headline)
                    Text("Add widget")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer() // Отталкиваем кнопку выключения вправо

                Button { // Кнопка выхода из приложения
                    NSApplication.shared.terminate(nil)
                } label: {
                    Image(systemName: "power")
                }
                .buttonStyle(.plain)
                .help("Quit miniWW")
            }

            VStack(alignment: .leading, spacing: 8) { // Список доступных виджетов
                ForEach(WidgetType.allCases) { type in // Для каждого типа рисуем кнопку
                    Button {
                        manager.addWidget(type: type) // Добавляем выбранный виджет
                    } label: {
                        HStack {
                            Text(type.title)
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.tint)
                        }
                        .padding(.vertical, 6)
                        .contentShape(Rectangle()) // Расширяем зону нажатия до всей строки
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider() // Разделяем список и блок действий

            Button { // Кнопка для массового удаления
                manager.removeAllWidgets()
            } label: {
                Label("Clear all widgets", systemImage: "trash")
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
        }
        .padding(20) // Внутренние отступы панели
        .frame(width: 280) // Фиксируем ширину, чтобы NSPanel совпадал
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial) // Полупрозрачный фон, похожий на виджеты macOS
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.1)) // Тонкий обвод для отделения от фона
        )
    }
}

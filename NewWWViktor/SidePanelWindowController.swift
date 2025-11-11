import AppKit // Импортируем AppKit для работы с окнами macOS
import SwiftUI // Подтягиваем SwiftUI, потому что панель хостит SwiftUI-вью
import QuartzCore // Нужен для CAMediaTimingFunction внутри анимаций

final class SidePanelWindowController { // Контроллер отвечает за жизненный цикл боковой панели
    private var window: NSPanel? // Держим ссылку на NSPanel, чтобы управлять им
    private let manager: WidgetManager // Общий менеджер виджетов, передаётся в SwiftUI-вью
    private let panelSize = NSSize(width: 320, height: 360) // Фиксированный размер панели
    private var screenChangeObserver: Any? // Обсервер для реакции на смену монитора/размеров

    init(manager: WidgetManager) { // Инициализатор принимает менеджер
        self.manager = manager // Сохраняем менеджер
        screenChangeObserver = NotificationCenter.default.addObserver( // Подписываемся на смену экрана
            forName: NSApplication.didChangeScreenParametersNotification, // Нужное уведомление
            object: nil, // От любого источника
            queue: .main // Обрабатываем в главной очереди
        ) { [weak self] _ in // Захватываем self слабо, чтобы избежать retain cycle
            guard let window = self?.window else { return } // Если окно есть — пересчитаем позицию
            self?.positionWindow(window) // Обновляем фрейм под новые параметры экрана
        }
    }

    deinit { // Очищаем ресурсы при уничтожении контроллера
        if let observer = screenChangeObserver { // Если обсервер есть
            NotificationCenter.default.removeObserver(observer) // Отписываемся
        }
    }

    func showPanel() { // Показывает панель с анимацией выезда
        if window == nil { // Если окно ещё не создано
            createPanel() // Создаём его
        }
        guard // Проверяем, что есть окно и экран
            let window,
            let screen = NSScreen.main
        else { return } // Иначе ничего не делаем

        let startFrame = frame(for: screen, showing: false) // Фрейм, с которого стартует анимация (за экраном)
        let targetFrame = frame(for: screen, showing: true) // Целевой фрейм (видимое состояние)

        if !window.isVisible { // Если окно ещё не показано
            window.setFrame(startFrame, display: false) // Ставим стартовый фрейм мгновенно
            window.makeKeyAndOrderFront(nil) // Показываем окно
            NSApp.activate(ignoringOtherApps: true) // Активируем приложение, чтобы окно было в фокусе
        }

        NSAnimationContext.runAnimationGroup { context in // Запускаем анимацию перемещения
            context.duration = 0.25 // Длительность выезда
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut) // Плавное ускорение/замедление
            window.animator().setFrame(targetFrame, display: true) // Анимируем установку целевого фрейма
        }
    }

    func hidePanel() { // Прячет панель с обратной анимацией
        guard // Проверяем, что окно видно и есть экран
            let window,
            window.isVisible,
            let screen = NSScreen.main
        else {
            window?.orderOut(nil) // Если условий нет, просто скрываем окно
            return
        }

        let targetFrame = frame(for: screen, showing: false) // Фрейм с положением за экраном

        NSAnimationContext.runAnimationGroup { context in // Анимация закрытия
            context.duration = 0.2 // Чуть быстрее прячем
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut) // Та же плавность
            window.animator().setFrame(targetFrame, display: false) // Анимируем уезд панели
        } completionHandler: {
            window.orderOut(nil) // После завершения полностью скрываем окно
        }
    }

    func togglePanel() { // Переключатель для показа/скрытия
        if window?.isVisible == true { // Если окно видно
            hidePanel() // Прячем
        } else {
            showPanel() // Иначе показываем
        }
    }

    var isPanelVisible: Bool { // Вспомогательное свойство для проверки состояния
        window?.isVisible ?? false // true, если окно есть и видно
    }

    private func createPanel() { // Создание NSPanel и настройка внешнего вида
        let panel = NSPanel( // Инициализируем панель
            contentRect: NSRect(origin: .zero, size: panelSize), // Начальный прямоугольник
            styleMask: [.titled, .closable, .fullSizeContentView], // Стиль с прозрачным заголовком
            backing: .buffered, // Тип отображения
            defer: false // Создаём сразу
        )
        panel.titleVisibility = .hidden // Скрываем заголовок
        panel.titlebarAppearsTransparent = true // Делаем заголовок прозрачным
        panel.isMovableByWindowBackground = true // Позволяем таскать за фон
        panel.isReleasedWhenClosed = false // Не отпускаем память автоматически
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true // Скрываем кнопку минимизации
        panel.standardWindowButton(.zoomButton)?.isHidden = true // И кнопку увеличения
        panel.standardWindowButton(.closeButton)?.isHidden = true // Прячем красный “крестик”
        panel.level = .floating // Держим окно поверх обычных окон
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary] // Показываем на всех рабочих столах
        panel.isOpaque = false // Окно не непрозрачное
        panel.backgroundColor = .clear // Фон полностью прозрачный
        panel.hidesOnDeactivate = false // Не скрываем при потере фокуса

        let hostingView = NSHostingView( // Оборачиваем SwiftUI-вью в NSHostingView
            rootView: SidePanelView().environmentObject(manager) // Передаём менеджер через Environment
        )
        hostingView.frame = NSRect(origin: .zero, size: panelSize) // Задаём размер хостинга
        panel.contentView = hostingView // Вкладываем SwiftUI-вью в панель

        window = panel // Сохраняем ссылку на панель
    }

    private func positionWindow(_ window: NSWindow) { // Пересчитываем позицию при смене экрана
        guard let screen = NSScreen.main else { return } // Если экрана нет — ничего не делаем
        let frame = frame(for: screen, showing: window.isVisible) // Получаем корректный фрейм
        window.setFrame(frame, display: true, animate: false) // Устанавливаем без анимации
    }

    private func frame(for screen: NSScreen, showing: Bool) -> NSRect { // Считает фрейм для показанного/спрятанного состояния
        let visible = screen.visibleFrame // Рабочая область экрана без дока и меню
        let y = visible.minY + (visible.height - panelSize.height) / 2 // Центрируем окно по вертикали
        let x: CGFloat // Вычислим X отдельно

        if showing { // Когда окно должно быть видно
            x = visible.maxX - panelSize.width - 12 // Прижимаем к правому краю с небольшим отступом
        } else {
            x = visible.maxX + 20 // Увозим окно чуть за предел экрана
        }

        return NSRect(x: x, y: y, width: panelSize.width, height: panelSize.height) // Возвращаем итоговый прямоугольник
    }
}

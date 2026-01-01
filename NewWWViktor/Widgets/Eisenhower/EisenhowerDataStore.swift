import SwiftData

enum EisenhowerDataStore {
    static let sharedContainer: ModelContainer = {
        do {
            return try ModelContainer(for: EisenhowerTask.self, HabitEntry.self)
        } catch {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            return try! ModelContainer(for: EisenhowerTask.self, HabitEntry.self, configurations: configuration)
        }
    }()

    static let previewContainer: ModelContainer = {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: EisenhowerTask.self, HabitEntry.self, configurations: configuration)
        let context = container.mainContext
        let tasks = [
            EisenhowerTask(title: "Call client", quadrant: .importantUrgent),
            EisenhowerTask(title: "Plan sprint", quadrant: .importantNotUrgent),
            EisenhowerTask(title: "Reply inbox", quadrant: .notImportantUrgent),
            EisenhowerTask(title: "Archive", quadrant: .notImportantNotUrgent)
        ]
        tasks.forEach { context.insert($0) }
        return container
    }()
}

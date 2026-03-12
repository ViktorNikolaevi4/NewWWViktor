import SwiftData
import Foundation

enum EisenhowerDataStore {
    static let sharedContainer: ModelContainer = {
        let persistentConfiguration = ModelConfiguration("WidgetsData")
        do {
            return try ModelContainer(for: EisenhowerTask.self,
                                      HabitEntry.self,
                                      CustomHabit.self,
                                      ClientPaymentEntry.self,
                                      TopMissionEntry.self,
                                      configurations: persistentConfiguration)
        } catch {
            print("SwiftData persistent container init failed. Falling back to in-memory store: \(error)")
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            return try! ModelContainer(for: EisenhowerTask.self,
                                       HabitEntry.self,
                                       CustomHabit.self,
                                       ClientPaymentEntry.self,
                                       TopMissionEntry.self,
                                       configurations: configuration)
        }
    }()

    static let previewContainer: ModelContainer = {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: EisenhowerTask.self,
                                            HabitEntry.self,
                                            CustomHabit.self,
                                            ClientPaymentEntry.self,
                                            TopMissionEntry.self,
                                            configurations: configuration)
        let context = container.mainContext
        let tasks = [
            EisenhowerTask(title: "Call client", quadrant: .importantUrgent),
            EisenhowerTask(title: "Plan sprint", quadrant: .importantNotUrgent),
            EisenhowerTask(title: "Reply inbox", quadrant: .notImportantUrgent),
            EisenhowerTask(title: "Archive", quadrant: .notImportantNotUrgent)
        ]
        tasks.forEach { context.insert($0) }
        let sampleClients = [
            ClientPaymentEntry(widgetID: UUID(), name: "Client A", payDay: 12, visitsCount: nil),
            ClientPaymentEntry(widgetID: UUID(), name: "Client B", payDay: nil, visitsCount: 5)
        ]
        sampleClients.forEach { context.insert($0) }
        return container
    }()
}

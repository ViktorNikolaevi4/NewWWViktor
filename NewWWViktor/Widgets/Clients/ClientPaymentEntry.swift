import Foundation
import SwiftData

@Model
final class ClientPaymentEntry {
    var widgetID: UUID
    var name: String
    var payDay: Int?
    var visitsCount: Int?
    var isPaid: Bool
    var amount: Double?
    var createdAt: Date
    var updatedAt: Date

    init(widgetID: UUID,
         name: String,
         payDay: Int? = nil,
         visitsCount: Int? = nil,
         isPaid: Bool = false,
         amount: Double? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.widgetID = widgetID
        self.name = name
        self.payDay = payDay
        self.visitsCount = visitsCount
        self.isPaid = isPaid
        self.amount = amount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

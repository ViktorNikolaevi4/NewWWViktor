import SwiftUI
import SwiftData

struct ClientsPaymentsWidgetView: View {
    let widget: WidgetInstance

    @EnvironmentObject private var localization: LocalizationManager
    @Query private var clients: [ClientPaymentEntry]

    private var overdueCount: Int {
        let today = Calendar.current.component(.day, from: Date())
        return clients.filter { client in
            guard !client.isPaid, let payDay = client.payDay else { return false }
            return payDay < today
        }.count
    }

    private var unpaidCount: Int {
        clients.filter { !$0.isPaid }.count
    }

    private var paidCount: Int {
        clients.filter { $0.isPaid }.count
    }

    private var paidAmountText: String? {
        let paidAmounts = clients
            .filter { $0.isPaid }
            .compactMap { $0.amount }
        guard !paidAmounts.isEmpty else { return nil }
        let total = paidAmounts.reduce(0, +)
        let formatted = numberFormatter.string(from: NSNumber(value: total)) ?? "\(total)"
        return String(format: localization.text(.widgetClientsAmountFormat), formatted)
    }
    private var totalAmount: String {
        let total = clients
            .filter { $0.isPaid }
            .compactMap { $0.amount }
            .reduce(0, +)
        let formatted = numberFormatter.string(from: NSNumber(value: total)) ?? "\(total)"
        return String(format: localization.text(.widgetClientsAmountFormat), formatted)
    }

    init(widget: WidgetInstance) {
        self.widget = widget
        _clients = Query(filter: #Predicate<ClientPaymentEntry> { $0.widgetID == widget.id })
    }

    var body: some View {
        Group {
            if widget.sizeOption == .small {
                smallLayout
            } else {
                listLayout
            }
        }
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 10) {
            summaryContent
            Spacer(minLength: 0)
        }
        .padding(12)
    }

    private var listLayout: some View {
        VStack(alignment: .leading, spacing: 12) {
            summaryContent

            Divider()
                .background(Color.white.opacity(0.1))

            if sortedClients.isEmpty {
                Text(localization.text(.widgetClientsEmpty))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(sortedClients) { client in
                        clientRow(client)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
    }

    private var summaryContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(overdueLabel)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(totalAmount)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.primary)

            Text(unpaidLabel)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(paidLabel)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }

    private func clientRow(_ client: ClientPaymentEntry) -> some View {
        HStack(spacing: 8) {
            Text(client.name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary)

            Spacer(minLength: 0)

            if let detail = detailText(for: client) {
                Text(detail)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var sortedClients: [ClientPaymentEntry] {
        clients.sorted { lhs, rhs in
            switch (lhs.payDay, rhs.payDay) {
            case let (.some(l), .some(r)) where l != r:
                return l < r
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            default:
                return lhs.createdAt < rhs.createdAt
            }
        }
    }

    private func detailText(for client: ClientPaymentEntry) -> String? {
        let payDayText = client.payDay.map { String(format: localization.text(.widgetClientsPayDayFormat), $0) }
        let visitsText = client.visitsCount.map { String(format: localization.text(.widgetClientsVisitsFormat), $0) }
        switch (payDayText, visitsText) {
        case (nil, nil):
            return nil
        case let (.some(pay), nil):
            return pay
        case let (nil, .some(visits)):
            return visits
        case let (.some(pay), .some(visits)):
            return "\(pay) · \(visits)"
        }
    }

    private var overdueLabel: String {
        String(format: localization.text(.widgetClientsOverdueFormat), overdueCount)
    }

    private var unpaidLabel: String {
        String(format: localization.text(.widgetClientsUnpaidFormat), unpaidCount)
    }

    private var paidLabel: String {
        let base = String(format: localization.text(.widgetClientsPaidFormat), paidCount)
        guard let paidAmountText else { return base }
        return "\(base) · \(paidAmountText)"
    }

    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }
}

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
    private var collectedAmount: String {
        let total = clients
            .filter { $0.isPaid }
            .compactMap { $0.amount }
            .reduce(0, +)
        let formatted = numberFormatter.string(from: NSNumber(value: total)) ?? "\(total)"
        return String(format: localization.text(.widgetClientsAmountFormat), formatted)
    }

    private var expectedAmount: String {
        let total = clients
            .compactMap { $0.amount }
            .reduce(0, +)
        let formatted = numberFormatter.string(from: NSNumber(value: total)) ?? "\(total)"
        return String(format: localization.text(.widgetClientsAmountFormat), formatted)
    }

    private var expectedAmountValue: Double {
        clients
            .compactMap { $0.amount }
            .reduce(0, +)
    }

    private var collectedAmountValue: Double {
        clients
            .filter { $0.isPaid }
            .compactMap { $0.amount }
            .reduce(0, +)
    }

    private var collectionProgress: Double {
        guard expectedAmountValue > 0 else { return 0 }
        return min(max(collectedAmountValue / expectedAmountValue, 0), 1)
    }

    init(widget: WidgetInstance) {
        self.widget = widget
        _clients = Query(filter: #Predicate<ClientPaymentEntry> { $0.widgetID == widget.id })
    }

    var body: some View {
        Group {
            if widget.sizeOption == .small {
                smallLayout
            } else if widget.sizeOption == .medium {
                mediumLayout
            } else if widget.sizeOption == .large {
                largeLayout
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

            clientsListContent

            Spacer(minLength: 0)
        }
        .padding(12)
    }

    private var largeLayout: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                amountCard(title: localization.text(.widgetClientsExpectedAmountTitle),
                           amount: expectedAmount)
                amountCard(title: localization.text(.widgetClientsCollectedAmountTitle),
                           amount: collectedAmount)
            }

            ProgressView(value: collectionProgress)
                .progressViewStyle(.linear)
                .tint(.blue.opacity(0.8))

            Divider()
                .background(Color.white.opacity(0.1))

            clientsListContent
            Spacer(minLength: 0)
        }
        .padding(12)
    }

    private var clientsListContent: some View {
        Group {
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
        }
    }

    private func amountCard(title: String, amount: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(amount)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var mediumLayout: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 10) {
                statRow(color: .red, text: overdueLabel)

                Spacer(minLength: 0)

                statRow(color: .yellow, text: todayDueLabel)

                Spacer(minLength: 0)

                statRow(color: .green, text: paidShortLabel)

                if let paidAmountText {
                    Text(paidAmountText)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 13)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .background(Color.white.opacity(0.1))

            VStack(alignment: .leading, spacing: 7) {
                Text(localization.text(.widgetClientsNextTitle))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.primary)

                if upcomingClients.isEmpty {
                    Text(localization.text(.widgetClientsEmpty))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(upcomingClients.prefix(3))) { client in
                        VStack(alignment: .leading, spacing: 1) {
                            HStack(spacing: 6) {
                                Text(client.name)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)

                                Spacer(minLength: 0)

                                if let amountText = amountText(for: client) {
                                    Text(amountText)
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(.primary)
                                }
                            }

                            Text(relativePayDayText(for: client))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private func statRow(color: Color, text: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)

            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
    }

    private var summaryContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(overdueLabel)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(collectedAmount)
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

    private var todayDay: Int {
        Calendar.current.component(.day, from: Date())
    }

    private var daysInCurrentMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: Date())?.count ?? 31
    }

    private var todayDueCount: Int {
        clients.filter { !$0.isPaid && $0.payDay == todayDay }.count
    }

    private var upcomingClients: [ClientPaymentEntry] {
        clients
            .filter { !$0.isPaid && $0.payDay != nil && ($0.payDay ?? 0) >= todayDay }
            .sorted { lhs, rhs in
                let lDistance = nextDueDistance(for: lhs) ?? Int.max
                let rDistance = nextDueDistance(for: rhs) ?? Int.max
                if lDistance != rDistance { return lDistance < rDistance }
                return lhs.createdAt < rhs.createdAt
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

    private func nextDueDistance(for client: ClientPaymentEntry) -> Int? {
        guard let payDay = client.payDay else { return nil }
        if payDay >= todayDay {
            return payDay - todayDay
        }
        return payDay + daysInCurrentMonth - todayDay
    }

    private func relativePayDayText(for client: ClientPaymentEntry) -> String {
        guard let distance = nextDueDistance(for: client), let payDay = client.payDay else {
            return localization.text(.widgetPlaceholderDash)
        }

        if distance == 0 {
            return localization.text(.widgetClientsTodayTitle)
        }
        if distance == 1 {
            return localization.text(.widgetClientsTomorrowTitle)
        }
        return String(format: localization.text(.widgetClientsPayDayFormat), payDay)
    }

    private func amountText(for client: ClientPaymentEntry) -> String? {
        guard let amount = client.amount else { return nil }
        let formatted = numberFormatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
        return String(format: localization.text(.widgetClientsAmountFormat), formatted)
    }

    private var overdueLabel: String {
        String(format: localization.text(.widgetClientsOverdueFormat), overdueCount)
    }

    private var todayDueLabel: String {
        String(format: localization.text(.widgetClientsTodayFormat), todayDueCount)
    }

    private var paidShortLabel: String {
        String(format: localization.text(.widgetClientsPaidShortFormat), paidCount)
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

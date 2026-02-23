import SwiftUI
import SwiftData

struct ManageClientsView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    @Query private var clients: [ClientPaymentEntry]

    @State private var searchText = ""
    @State private var nameText = ""
    @State private var payDayText = ""
    @State private var visitsText = ""
    @State private var amountText = ""

    private let widgetID: UUID

    init(widgetID: UUID, isPresented: Binding<Bool>) {
        self.widgetID = widgetID
        self._isPresented = isPresented
        _clients = Query(filter: #Predicate<ClientPaymentEntry> { $0.widgetID == widgetID })
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black.opacity(0.82))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.08))
                )
                .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 10)

            VStack(spacing: 12) {
                header
                addForm
                searchField
                listContent
            }
            .padding(16)
        }
        .frame(width: 360, height: 420)
    }

    private var header: some View {
        HStack {
            Text(localization.text(.widgetClientsManageTitle))
                .font(.system(size: 16, weight: .semibold))
            Spacer()
            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .padding(6)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.12))
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var addForm: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                TextField(localization.text(.widgetClientsNamePlaceholder), text: $nameText)
                    .textFieldStyle(.roundedBorder)

                TextField(localization.text(.widgetClientsPayDayPlaceholder), text: $payDayText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)

                TextField(localization.text(.widgetClientsVisitsPlaceholder), text: $visitsText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 90)

                TextField(localization.text(.widgetClientsAmountPlaceholder), text: $amountText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 90)
            }

            HStack {
                Spacer()
                Button(localization.text(.widgetClientsAddAction)) {
                    addClient()
                }
                .buttonStyle(.plain)
                .disabled(!canAddClient)
            }
        }
    }

    private var searchField: some View {
        TextField(localization.text(.widgetClientsManageSearch), text: $searchText)
            .textFieldStyle(.roundedBorder)
    }

    private var listContent: some View {
        Group {
            if filteredClients.isEmpty {
                Text(localization.text(.widgetClientsManageEmpty))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredClients) { client in
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(client.name)
                                if let detail = clientDetailText(for: client) {
                                    Text(detail)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if let amountText = amountText(for: client) {
                                Text(amountText)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                            Toggle(localization.text(.widgetClientsPaidToggle),
                                   isOn: paidBinding(for: client))
                                .labelsHidden()
                            Button(role: .destructive) {
                                modelContext.delete(client)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.plain)
                        }
                        .listRowBackground(Color.clear)
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
    }

    private var filteredClients: [ClientPaymentEntry] {
        let trimmed = searchText.trimmed
        let sorted = clients.sorted { $0.createdAt < $1.createdAt }
        guard !trimmed.isEmpty else { return sorted }
        return sorted.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
    }

    private var canAddClient: Bool {
        !nameText.trimmed.isEmpty && (payDayValue != nil || visitsValue != nil || amountValue != nil)
    }

    private var payDayValue: Int? {
        guard let value = Int(payDayText.trimmed), (1...31).contains(value) else { return nil }
        return value
    }

    private var visitsValue: Int? {
        guard let value = Int(visitsText.trimmed), value >= 0 else { return nil }
        return value
    }

    private var amountValue: Double? {
        let trimmed = amountText.trimmed.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(trimmed), value >= 0 else { return nil }
        return value
    }

    private func addClient() {
        let name = nameText.trimmed
        guard !name.isEmpty else { return }
        let entry = ClientPaymentEntry(widgetID: widgetID,
                                       name: name,
                                       payDay: payDayValue,
                                       visitsCount: visitsValue,
                                       amount: amountValue)
        modelContext.insert(entry)
        resetForm()
    }

    private func resetForm() {
        nameText = ""
        payDayText = ""
        visitsText = ""
        amountText = ""
    }

    private func paidBinding(for client: ClientPaymentEntry) -> Binding<Bool> {
        Binding(
            get: { client.isPaid },
            set: { newValue in
                client.isPaid = newValue
                client.updatedAt = Date()
            }
        )
    }

    private func clientDetailText(for client: ClientPaymentEntry) -> String? {
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

    private func amountText(for client: ClientPaymentEntry) -> String? {
        guard let amount = client.amount else { return nil }
        let formatted = numberFormatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
        return String(format: localization.text(.widgetClientsAmountFormat), formatted)
    }

    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

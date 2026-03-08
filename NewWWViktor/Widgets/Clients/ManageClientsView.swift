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
    @State private var showAddClient = false
    @State private var showEditClient = false
    @State private var editingClient: ClientPaymentEntry?

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
                addButton
                searchField
                listContent
            }
            .padding(16)
        }
        .frame(width: 360, height: 420)
        .sheet(isPresented: $showAddClient) {
            addClientSheet
        }
        .sheet(isPresented: $showEditClient) {
            editClientSheet
        }
    }

    private var header: some View {
        HStack {
            Text(localization.text(.widgetClientsManageTitle))
                .font(.system(size: 16, weight: .semibold))
            Text("\(clients.count)")
                .font(.system(size: 11, weight: .bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.14))
                )
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

    private var addButton: some View {
        HStack {
            Button {
                showAddClient = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text(localization.text(.widgetClientsAddAction))
                }
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }

    private var addClientSheet: some View {
        VStack(spacing: 16) {
            HStack {
                Text(localization.text(.widgetClientsAddAction))
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Button {
                    showAddClient = false
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

            VStack(spacing: 10) {
                TextField(localization.text(.widgetClientsNamePlaceholder), text: $nameText)
                    .textFieldStyle(.roundedBorder)

                HStack(spacing: 8) {
                    TextField(localization.text(.widgetClientsPayDayPlaceholder), text: $payDayText)
                        .textFieldStyle(.roundedBorder)

                    TextField(localization.text(.widgetClientsVisitsPlaceholder), text: $visitsText)
                        .textFieldStyle(.roundedBorder)
                }

                TextField(localization.text(.widgetClientsAmountPlaceholder), text: $amountText)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Button(localization.text(.widgetClientsAddAction)) {
                    addClient()
                    showAddClient = false
                }
                .buttonStyle(.plain)
                .disabled(!canSaveClient)

                Spacer()

                Button(localization.text(.widgetEisenhowerCancel)) {
                    showAddClient = false
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .frame(width: 360)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.9))
        )
        .onAppear(perform: resetForm)
    }

    private var editClientSheet: some View {
        VStack(spacing: 16) {
            HStack {
                Text(localization.text(.widgetClientsEditAction))
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Button {
                    showEditClient = false
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

            VStack(spacing: 10) {
                TextField(localization.text(.widgetClientsNamePlaceholder), text: $nameText)
                    .textFieldStyle(.roundedBorder)

                HStack(spacing: 8) {
                    TextField(localization.text(.widgetClientsPayDayPlaceholder), text: $payDayText)
                        .textFieldStyle(.roundedBorder)

                    TextField(localization.text(.widgetClientsVisitsPlaceholder), text: $visitsText)
                        .textFieldStyle(.roundedBorder)
                }

                TextField(localization.text(.widgetClientsAmountPlaceholder), text: $amountText)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Button(localization.text(.widgetEisenhowerSave)) {
                    saveEditedClient()
                    showEditClient = false
                }
                .buttonStyle(.plain)
                .disabled(!canSaveClient)

                Spacer()

                Button(localization.text(.widgetEisenhowerCancel)) {
                    showEditClient = false
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .frame(width: 360)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.9))
        )
        .onDisappear {
            editingClient = nil
            resetForm()
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
                            Button {
                                beginEditing(client)
                            } label: {
                                Image(systemName: "pencil")
                            }
                            .buttonStyle(.plain)
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
                        .contentShape(Rectangle())
                        .onTapGesture {
                            beginEditing(client)
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

    private var canSaveClient: Bool {
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

    private func beginEditing(_ client: ClientPaymentEntry) {
        editingClient = client
        nameText = client.name
        payDayText = client.payDay.map(String.init) ?? ""
        visitsText = client.visitsCount.map(String.init) ?? ""
        if let amount = client.amount {
            amountText = plainAmountString(amount)
        } else {
            amountText = ""
        }
        showEditClient = true
    }

    private func saveEditedClient() {
        guard let client = editingClient else { return }
        let name = nameText.trimmed
        guard !name.isEmpty else { return }
        client.name = name
        client.payDay = payDayValue
        client.visitsCount = visitsValue
        client.amount = amountValue
        client.updatedAt = Date()
        resetForm()
        editingClient = nil
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

    private func plainAmountString(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        }
        return String(value)
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
